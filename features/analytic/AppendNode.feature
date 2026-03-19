# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: AppendNode

  Scenario: AppendNode
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result TYPED TABLE {src_id INT64, dst_id INT64}
        MATCH (a)-[e:FOLLOWS]->(b)
        WHERE a.id + e.dst > 4
        PER PATH {
          EXPORT a.id, b.id INTO result
        }

        FOR r IN result
        RETURN r.src_id, r.dst_id
      }
      """
    Then the result should be, in any order:
      | r.src_id | r.dst_id |
      | 2        | 3        |
      | 2        | 4        |
      | 3        | 2        |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result TYPED TABLE {src_id INT64, dst_id INT64}
        MATCH (a)-[e:FOLLOWS]->(b WHERE b.id > 2)
        WHERE a.id + e.dst > 4
        PER PATH {
          EXPORT a.id, b.id INTO result
        }

        FOR r IN result
        RETURN r.src_id, r.dst_id
      }
      """
    Then the result should be, in any order:
      | r.src_id | r.dst_id |
      | 2        | 3        |
      | 2        | 4        |
    When executing analytic query:
      """
      USE #analytic_ldbc {
          TABLE t1 TYPED TABLE {mx int, id int} = {mx:1, id:99}
          NODE VALUE max maxagg<int> = 999
          VALUE i int = 0
          MATCH (v@Person) PER NODE(v) {SET v.@max += v.id EXPORT v.@max, v.id INTO  t1}
          FOR r IN t1 RETURN r.mx, r.id
      }
      """
    Then the result should be, in any order:
      | r.mx | r.id |
      | 1    | 99   |
      | 999  | 2    |
      | 999  | 4    |
      | 999  | 3    |
      | 999  | 1    |
