# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Jaccard

  Scenario: Jaccard
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS jaccard_graph_type AS {
          NODE User  (LABEL User {id INT PRIMARY KEY, name STRING}),
          NODE Movie (LABEL Movie {id INT PRIMARY KEY, title STRING}),
          EDGE Likes  (User)-[LABEL Likes {}]->(Movie)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS jaccard_graph_disk TYPED jaccard_graph_type
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE persons {id, name} =
      {id:1, name:"Alice"},
      {id:2, name:"Bob"},
      {id:3, name:"Charlie"},
      {id:4, name:"David"},
      {id:5, name:"Eve"}
      USE jaccard_graph_disk
      FOR r IN persons
      INSERT (@User{id:r.id, name:r.name})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE movies {id, title} =
      {id:1, title: "The Shawshank Redemption"},
      {id:2, title: "The Dark Knight"},
      {id:3, title: "12 Angry Men"},
      {id:4, title: "The Lord of the Rings: The Return of the King"},
      {id:5, title: "Schindler's List"}
      USE jaccard_graph_disk
      FOR r IN movies
      INSERT (@Movie{id:r.id, title:r.title})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE edges {userID, movieId} =
      (1,1),
      (1,2),
      (2,2),
      (2,3),
      (3,2),
      (3,3),
      (3,4),
      (4,3),
      (4,4),
      (5,5)
      USE jaccard_graph_disk
      FOR r IN edges
      MATCH (a@User) WHERE a.id = r.userID
      MATCH (b@Movie) WHERE b.id = r.movieId
      INSERT (a)-[@Likes{}]->(b)
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #jaccard_graph_memory AS COPY OF jaccard_graph_disk
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #jaccard_graph_memory TYPED jaccard_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #jaccard_graph_memory IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=jaccard_graph_disk&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS jaccard_ss(user_id INT64) RETURNS (id INT64, similarity DOUBLE) AS {
        VALUE      source_edges    SumAgg<INT64> = 0
        VALUE      topk_similarity TopKAgg<5, similarity DOUBLE DESC, id INT DESC>
        NODE VALUE target_edges    SumAgg<INT64> = 0
        NODE VALUE intersection    SumAgg<INT64> = 0
        VALUE      v_set           ACTIVE_SET

        MATCH (u:User)-[e:Likes]->(m:Movie)
        PER PATH {
          SET u.@target_edges += 1
        }

        MATCH (u:User)-[:Likes]->(m:Movie) WHERE u.id = 2
        PER NODE (u){
            SET @source_edges += u.@target_edges
        }
        FINALLY {
          SET v_set = m
        }

        MATCH(m:Movie)<-[:Likes]-(t:User) WHERE t.id <> 2 AND m IN v_set
        PER PATH {
            SET t.@intersection += 1
        }
        PER NODE (t){
          VALUE union_size = t.@target_edges + @source_edges - t.@intersection
          if union_size <> 0 THEN {
             VALUE similarity = CAST(t.@intersection as DOUBLE) / union_size
             SET @topk_similarity += RECORD{similarity:similarity,id:t.id}
          }
        }

        FOR r IN @topk_similarity
          RETURN r.id, round(r.similarity,5)
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #jaccard_graph_memory CALL jaccard_ss(2) RETURN *
      """
    Then the result should be, in any order:
      | id | similarity |
      | 3  | 0.66667    |
      | 4  | 0.33333    |
      | 1  | 0.33333    |
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS jaccard_batch(num_of_batch INT64) RETURNS (source INT64, target INT64, similarity DOUBLE) AS {
        VALUE      batch            INT32         = 0
        VALUE      x                INT32         = 0
        VALUE      y                INT32         = 0
        VALUE      source_edges     MapAgg<INT64, SumAgg<INT64>>
        VALUE      source           ACTIVE_SET
        VALUE      neighbor         ACTIVE_SET
        VALUE      topk_similarity  MapAgg<INT64, TopKAgg<2, similarity DOUBLE DESC, target_id INT DESC>>
        TABLE      result_table     {source_id INT64, target_id INT64, similarity DOUBLE}
        NODE VALUE out_edges        SumAgg<INT64> = 0
        NODE VALUE intersection_map MapAgg<INT64, SumAgg<INT64>>

        MATCH (s:User)-[e:Likes]->(t:Movie)
        PER PATH {
          SET s.@out_edges += 1
        }

        WHILE batch < num_of_batch THEN {
          LOG_INFO("batch: ", batch)
          MATCH (s:User) WHERE (s.id % num_of_batch = batch)
          PER NODE (s){
            SET @source_edges += TUPLE(s.id, s.@out_edges)
          }
          FINALLY {
          SET source = s
        }

          // From each source user, collect the intersection map of each user
          MATCH (s:User)-[:Likes]->(t:Movie) WHERE s IN source
          PER PATH {
            SET t.@intersection_map += TUPLE(s.id, 1)
          }
          FINALLY {
            SET neighbor = t
          }

          // From each movie, propagate the intersection map to each target user
          MATCH (t:Movie)<-[:Likes]-(target:User) WHERE t IN neighbor
          PER PATH {
            SET target.@intersection_map += t.@intersection_map
          }
          // For each target user, calculate the Jaccard similarity with each source user
          PER NODE (target)  {
            VALUE iter = 0
            VALUE inter_map = target.@intersection_map
            WHILE iter < length(inter_map) THEN {
                VALUE item = inter_map[iter]
                VALUE source_id = item._0
                VALUE intersection = item._1
                if (target.id <> source_id) THEN {
                    VALUE union_size = target.@out_edges + @source_edges.get(source_id) - intersection
                    if (union_size <> 0) THEN {
                        VALUE similarity = CAST(intersection AS DOUBLE) / union_size
                        SET @topk_similarity += TUPLE(source_id, RECORD{similarity:similarity, target_id:target.id})
                    }
                }
                SET iter = iter+1
            }
            // Free temp data
            SET target.@intersection_map.clear()
          }
          PER NODE (t) {
            // Free temp data
            SET t.@intersection_map.clear()
          }

          MATCH (s:User) WHERE s IN source
          PER NODE (s) {
             if @topk_similarity.contains_key(s.id) THEN {
                VALUE topk = @topk_similarity.get(s.id)
                VALUE j = 0
                WHILE j < length(topk) THEN {
                    VALUE item = topk[j]
                    VALUE target_id = item.target_id
                    VALUE similarity = item.similarity
                    EXPORT s.id, target_id, similarity INTO result_table
                    SET j = j + 1
                }
             }
          }

          SET @topk_similarity.clear()
          SET @source_edges.clear()

          // Forward Next Batch
          SET batch = batch + 1
        }

        FOR r IN result_table
           return r.source_id, r.target_id, r.similarity
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #jaccard_graph_memory CALL jaccard_batch(2) RETURN *
      """
    Then the result should be, in any order:
      | similarity         | source | target |
      | 0.6666666666666666 | 4      | 3      |
      | 0.3333333333333333 | 4      | 2      |
      | 0.6666666666666666 | 2      | 3      |
      | 0.3333333333333333 | 2      | 4      |
      | 0.3333333333333333 | 1      | 2      |
      | 0.25               | 1      | 3      |
      | 0.6666666666666666 | 3      | 4      |
      | 0.6666666666666666 | 3      | 2      |
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE jaccard_batch_opt(num_of_batch INT64, min_intersection INT64) RETURNS (source INT64, target INT64, similarity DOUBLE) AS {
        VALUE      batch            INT32         = 0
        VALUE      x                INT32         = 0
        VALUE      y                INT32         = 0
        VALUE      source_edges     MapAgg<INT64, SumAgg<INT64>>
        VALUE      source           ACTIVE_SET
        VALUE      neighbor         ACTIVE_SET
        TABLE      result_table     {source_id INT64, target_id INT64, similarity DOUBLE}
        NODE VALUE out_edges        SumAgg<INT64> = 0
        NODE VALUE intersection_map MapAgg<INT64, SumAgg<INT64>>
        NODE VALUE topk_similarity  TopKAgg<2, similarity DOUBLE DESC, target_id INT DESC>

        MATCH (s:User)-[e:Likes]->(t:Movie)
        PER PATH {
          SET s.@out_edges += 1
        }

        WHILE batch < num_of_batch THEN {
          LOG_INFO("batch: ", batch)
          MATCH (s:User) WHERE (element_id(s) % num_of_batch = batch)
          PER NODE (s){
            SET @source_edges += TUPLE(element_id(s), s.@out_edges)
          }
          FINALLY {
            SET source = s
          }

          // From each source user, collect the intersection map of each user
          MATCH (s:User)-[:Likes]->(t:Movie) WHERE s IN source
          PER PATH {
            SET t.@intersection_map += TUPLE(element_id(s), 1)
          }
          FINALLY {
            SET neighbor = t
          }

          // From each movie, propagate the intersection map to each target user
          MATCH (t:Movie)<-[:Likes]-(target:User) WHERE t IN neighbor
          PER PATH {
            SET target.@intersection_map += t.@intersection_map
          }
          // For each target user, calculate the Jaccard similarity with each source user
          PER NODE (target)  {
            VALUE iter = 0
            VALUE inter_map = target.@intersection_map
            WHILE iter < length(inter_map) THEN {
                VALUE item = inter_map[iter]
                VALUE source_node_id = item._0
                VALUE intersection = item._1
                if element_id(target) <> source_node_id AND intersection >= min_intersection THEN {
                    VALUE union_size = target.@out_edges + @source_edges.get(source_node_id) - intersection
                    if (union_size <> 0) THEN {
                        VALUE similarity = CAST(intersection AS DOUBLE) / union_size
                        SET NODE(source_node_id).@topk_similarity += RECORD{similarity:similarity, target_id:target.id}
                    }
                }
                SET iter = iter+1
            }
            // Free temp data
            SET target.@intersection_map.clear()
          }
          PER NODE (t) {
            // Free temp data
            SET t.@intersection_map.clear()
          }

          MATCH (s:User) WHERE s IN source
          PER NODE (s) {
            VALUE topk = s.@topk_similarity
            VALUE j = 0
            WHILE j < length(topk) THEN {
                VALUE item = topk[j]
                VALUE target_id = item.target_id
                VALUE similarity = item.similarity
                EXPORT s.id, target_id, similarity INTO result_table
                SET j = j + 1
            }
            SET s.@topk_similarity.clear()
          }
          SET @source_edges.clear()

          // Forward Next Batch
          SET batch = batch + 1
        }

        FOR r IN result_table
           return r.source_id, r.target_id, r.similarity
      }
      """
    When executing graph analytic query:
      """
      USE #jaccard_graph_memory CALL jaccard_batch_opt(2, 0) RETURN *
      """
    Then the result should be, in any order:
      | similarity         | source | target |
      | 0.6666666666666666 | 4      | 3      |
      | 0.3333333333333333 | 4      | 2      |
      | 0.6666666666666666 | 2      | 3      |
      | 0.3333333333333333 | 2      | 4      |
      | 0.3333333333333333 | 1      | 2      |
      | 0.25               | 1      | 3      |
      | 0.6666666666666666 | 3      | 4      |
      | 0.6666666666666666 | 3      | 2      |
    When executing graph analytic query:
      """
      USE #jaccard_graph_memory CALL jaccard_batch_opt(2, 2) RETURN *
      """
    Then the result should be, in any order:
      | similarity         | source | target |
      | 0.6666666666666666 | 4      | 3      |
      | 0.6666666666666666 | 2      | 3      |
      | 0.6666666666666666 | 3      | 4      |
      | 0.6666666666666666 | 3      | 2      |
    And drop the graph "#jaccard_graph_memory"
    And drop the graph "jaccard_graph_disk"
    And drop the graph type "jaccard_graph_type"
    And drop the procedure "jaccard_ss"
    And drop the procedure "jaccard_batch"
