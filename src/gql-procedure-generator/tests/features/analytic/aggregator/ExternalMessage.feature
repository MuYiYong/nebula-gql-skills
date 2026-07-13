@aggregator
Feature: ExternalMessage

  Scenario: sum agg
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency=4 ) */
      USE #analytic_ldbc {
        NODE VALUE in_edge SumAgg<INT64> = 0
        NODE VALUE list_agg ListAgg<INT64>
        TABLE result_table TYPED TABLE {id INT64, in_edge INT64}
        MATCH (a)-[e]->(b@Person)
        PER PATH {
          SET a.@list_agg += element_id(b)
        }
        PER NODE (a) {
          VALUE neighbor_ids = a.@list_agg
          VALUE i = 0
          VALUE length = length(neighbor_ids)
          WHILE i < length THEN {
            VALUE nid = neighbor_ids[i]
            SET NODE(nid).@in_edge += 1
            SET i = i + 1
          }
        }
        MATCH (b@Person)
        PER NODE (b) {
          EXPORT b.id, b.@in_edge INTO result_table
        }

        FOR r IN result_table
        RETURN r.id, r.in_edge
      }
      """
    Then the result should be, in any order:
      | r.id | r.in_edge |
      | 3    | 6         |
      | 2    | 7         |
      | 4    | 1         |
      | 1    | 6         |

  Scenario: max min agg
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency=4 ) */
      USE #analytic_ldbc {
        NODE VALUE max_neighbor_id MaxAgg<INT64> = 0
        NODE VALUE min_neighbor_id MinAgg<INT64> = 99999999
        NODE VALUE list_agg ListAgg<RECORD{node_id INT64, id INT64}>
        TABLE result_table TYPED TABLE {id INT64, max_neighbor_id  INT64, min_neighbor_id  INT64}
        MATCH (a)-[e]-(b@Person)
        PER PATH {
          SET a.@list_agg += RECORD{node_id:element_id(b),id:a.id}
        }
        PER NODE (a) {
          VALUE neighbors = a.@list_agg
          VALUE i = 0
          VALUE length = length(neighbors)
          WHILE i < length THEN {
            VALUE neighbor = neighbors[i]
            VALUE nid = neighbor.node_id
            VALUE id = neighbor.id
            // LOG_INFO("id == ",neighbor.id)
            SET NODE(nid).@max_neighbor_id += id
            SET NODE(nid).@min_neighbor_id += id
            SET i = i + 1
          }
        }
        MATCH (b@Person)
        PER NODE (b) {
          EXPORT b.id, b.@max_neighbor_id, b.@min_neighbor_id INTO result_table
        }

        FOR r IN result_table
        RETURN r.id, r.max_neighbor_id, r.min_neighbor_id
      }
      """
    Then the result should be, in any order:
      | r.id | r.max_neighbor_id | r.min_neighbor_id |
      | 3    | 3                 | 1                 |
      | 2    | 4                 | 1                 |
      | 4    | 2                 | 2                 |
      | 1    | 3                 | 1                 |

  Scenario: list agg
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency=4 ) */
      USE #analytic_ldbc {
        NODE VALUE in_neighbors ListAgg<INT64>
        NODE VALUE list_agg ListAgg<RECORD{node_id INT64}>
        TABLE result_table TYPED TABLE {id INT64, neighbor_node_id  INT64}
        MATCH (a)-[e@FOLLOWS]->(b@Person)
        PER PATH {
          SET a.@list_agg += RECORD{node_id:element_id(b)}
        }
        PER NODE (a) {
          VALUE neighbors = a.@list_agg
          VALUE i = 0
          VALUE length = length(neighbors)
          WHILE i < length THEN {
            VALUE neighbor = neighbors[i]
            VALUE nid = neighbor.node_id
            SET NODE(nid).@in_neighbors += a.id
            SET i = i + 1
          }
        }
        MATCH (b@Person)
        PER NODE (b) {
          VALUE neighbors = b.@in_neighbors
          VALUE i = 0
          VALUE length = length(neighbors)
          WHILE i < length THEN {
            EXPORT b.id, neighbors[i] INTO result_table
            SET i = i + 1
          }
          LOG_INFO("id == ",b.id, " neighbors == ",neighbors)
        }
        FOR r IN result_table
        RETURN r.id, r.neighbor_node_id
      }
      """
    Then the result should be, in any order:
      | r.id | r.neighbor_node_id |
      | 3    | 2                  |
      | 2    | 3                  |
      | 2    | 1                  |
      | 4    | 2                  |
      | 1    | 3                  |

  Scenario: topk agg
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency=4 ) */
      USE #analytic_ldbc {
        NODE VALUE topk_nei TopKAgg<3,node_id INT DESC>
        NODE VALUE copy_topk_nei TopKAgg<3,node_id INT DESC>
        NODE VALUE list_agg ListAgg<RECORD{node_id INT64}>
        TABLE result_table TYPED TABLE {id INT64, topk_nei LIST<INT64>,copy_topk_nei LIST<INT64>}
        MATCH (a)<-[e]-(b@Person)
        PER PATH {
          SET a.@list_agg += RECORD{node_id:element_id(b)}
        }
        PER NODE (a) {
          VALUE neighbors = a.@list_agg
          VALUE i = 0
          VALUE length = length(neighbors)
          WHILE i < length THEN {
            VALUE neighbor = neighbors[i]
            VALUE nid = neighbor.node_id
            SET NODE(nid).@topk_nei += RECORD{node_id:a.id}
            SET i = i + 1
          }
        }
        MATCH (b@Person)
        PER NODE (b) {
          VALUE copy_id = element_id(b)
          SET NODE(copy_id).@copy_topk_nei += b.@topk_nei
        }
        PER NODE (b) {
          EXPORT b.id, transform(b.@topk_nei, x -> x.node_id),transform(b.@copy_topk_nei, x -> x.node_id) INTO result_table
        }
        FOR r IN result_table
        RETURN r.id, r.topk_nei,r.copy_topk_nei
      }
      """
    Then the result should be, in any order:
      | r.id | r.topk_nei   | r.copy_topk_nei |
      | 3    | LIST [3,3,3] | LIST [3,3,3]    |
      | 2    | LIST [4,3,2] | LIST [4,3,2]    |
      | 4    | LIST []      | LIST []         |
      | 1    | LIST [2,1,1] | LIST [2,1,1]    |

  Scenario: map agg
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency=4 ) */
      USE #analytic_ldbc {
        NODE VALUE map_count  MapAgg<INT,SumAgg<INT>>
        NODE VALUE double_map MapAgg<INT,SumAgg<INT>>
        NODE VALUE list_agg ListAgg<RECORD{node_id INT64}>
        TABLE result_table TYPED TABLE {id INT64, neighbor INT64, count INT64}
        VALUE cur_iter = 0
        WHILE cur_iter < 3 THEN {
          MATCH (a)<-[e@FOLLOWS]-(b@Person)
          PER PATH {
            SET a.@list_agg += RECORD{node_id:element_id(b)}
          }
          SET cur_iter = cur_iter + 1
        }

        MATCH (a)
        PER NODE (a) {
          VALUE neighbors = a.@list_agg
          VALUE i = 0
          VALUE length = length(neighbors)
          WHILE i < length THEN {
            VALUE neighbor = neighbors[i]
            VALUE nid = neighbor.node_id
            SET NODE(nid).@map_count += TUPLE(a.id, 1)
            SET i = i + 1
          }
        }

        MATCH (b@Person)
        PER NODE (b) {
          VALUE copy_id = element_id(b)
          SET NODE(copy_id).@double_map += b.@map_count
          SET NODE(copy_id).@double_map += b.@map_count
        }
        PER NODE (b) {
          VALUE l = b.@double_map
          VALUE i = 0
          WHILE i < length(l) THEN  {
            VALUE t = l[i]
            EXPORT b.id, t._0, t._1 INTO result_table
            SET i = i + 1
          }
        }
        FOR r IN result_table
        RETURN r.id, r.neighbor,r.count
      }
      """
    Then the result should be, in any order:
      | r.id | r.neighbor | r.count |
      | 3    | 1          | 6       |
      | 2    | 4          | 6       |
      | 3    | 2          | 6       |
      | 2    | 3          | 6       |
      | 1    | 2          | 6       |

  Scenario: invalid message
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE sum_agg SumAgg<INT64> = 0
        MATCH (a)
        PER NODE (a) {
          VALUE invalid_node_id INT64 = 1
          SET NODE(invalid_node_id).@sum_agg += 1
        }
      }
      """
    Then an Error should be raised: "[NR027]: Node with element id `1` does not exist"

  Scenario: unsupported
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE sum_agg SumAgg<INT> = 0
        VALUE x = 1
        SET NODE(x).@sum_agg += 1
      }
      """
    Then an Error should be raised: "Node Aggregator `sum_agg` is only accessible within a MATCH COMPUTE statement"
