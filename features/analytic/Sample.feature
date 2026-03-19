# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Sample

  Scenario: Sampling on TEMPORARY GRAPH
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS sample_gt AS {
      NODE Person (LABEL Person {id INT64 PRIMARY KEY, vec VECTOR<3,float> default null}),
      EDGE KNOWS (Person)-[:KNOWS]->(Person)}
      """
    Then the execution should be successful
    And graph type "sample_gt" should be ready to use
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS sample_graph sample_gt
      """
    Then the execution should be successful
    And graph "sample_graph" should be ready to use
    When executing graph query:
      """
      USE sample_graph
      FOR i IN range(1,10)
      INSERT (a@Person{id:i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE t {src, dst} =
      (1,2),
      (2,3),(2,4),
      (3,4),(3,5),(3,6),
      (4,5),(4,6),(4,7),(4,8),
      (5,6),(5,7),(5,8),(5,9),(5,10)
      USE sample_graph
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)-[:KNOWS]->(b)
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_tmp_dst1d TYPED sample_gt PARTITION BY DST
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_tmp_dst1d IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=sample_graph&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_tmp_dst1d {
        VALUE sample1 SumAgg<INT64> = 0

        MATCH (s:Person)-[e:KNOWS SAMPLE RIGHT 1]->(t:Person)
        PER PATH {
          SET @sample1 += 1
        }
        RETURN @sample1
      }
      """
    Then an Error should be raised: "[NS235]: Invalid sample: sampling is not supported for distributed temporary graph with partition method: DST"
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_tmp_src1d TYPED sample_gt PARTITION BY SRC
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_tmp_src1d IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=sample_graph&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_tmp_src1d {
        VALUE sample1 SumAgg<INT64> = 0
        VALUE sample2 SumAgg<INT64> = 0
        VALUE sample20Percent SumAgg<INT64> = 0
        VALUE sample50Percent SumAgg<INT64> = 0
        VALUE sample100Percent SumAgg<INT64> = 0

        MATCH (s:Person)-[e:KNOWS SAMPLE RIGHT 1]->(t:Person)
        PER PATH {
          SET @sample1 += 1
        }
        MATCH (s:Person)-[e:KNOWS SAMPLE RIGHT 2]->(t:Person)
        PER PATH {
          SET @sample2 += 1
        }
        MATCH (s:Person)-[e:KNOWS SAMPLE RIGHT RANDOM 50%]->(t:Person)
        PER PATH {
          SET @sample50Percent += 1
        }
        MATCH (s:Person)-[e:KNOWS SAMPLE RIGHT RANDOM 20%]->(t:Person)
        PER PATH {
          SET @sample20Percent += 1
        }
        MATCH (s:Person)-[e:KNOWS SAMPLE RIGHT RANDOM 100%]->(t:Person)
        PER PATH {
          SET @sample100Percent += 1
        }
        RETURN @sample1, @sample2, @sample20Percent, @sample50Percent, @sample100Percent
      }
      """
    Then the result should be, in any order:
      | @sample1 | @sample2 | @sample20Percent | @sample50Percent | @sample100Percent |
      | 5        | 9        | 5                | 9                | 15                |
    When executing analytic query:
      """
      USE #dist_tmp_src1d {
        VALUE sample1 SumAgg<INT64> = 0
        MATCH (s:Person)<-[e:KNOWS SAMPLE RIGHT 1]-(t:Person)
        PER PATH {
          SET @sample1 += 1
        }
        RETURN @sample1
      }
      """
    Then an Error should be raised: "[NS235]: Invalid sample: sampling pointing left edge is not supported in distributed temporary graph"
    When executing analytic query:
      """
      USE #dist_tmp_src1d {
        VALUE sample1 SumAgg<INT64> = 0
        MATCH (s:Person SAMPLE RIGHT 3)<-[e:KNOWS SAMPLE RIGHT 1]-(t:Person)
        PER PATH {
          SET @sample1 += 1
        }
        RETURN @sample1
      }
      """
    Then an Error should be raised: "[NS235]: Invalid sample: sample on node is not supported"
    And drop the graph "#sample_dist_graph"
    And drop the graph "sample_graph"

  Scenario: Sample not supported yet.
    When executing graph query:
      """
      USE ldbc
      MATCH (v1:Person SAMPLE RIGHT 1)-[e:KNOWS]->(v2:Person{firstName: v1.firstName})
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then an Error should be raised: "[NS235]: Invalid sample: sample on node is not supported"
