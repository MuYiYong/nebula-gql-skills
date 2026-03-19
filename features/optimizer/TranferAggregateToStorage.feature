# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: TranferAggregatorToStorageRule

  Scenario: basic
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v)
      RETURN count(*) AS c
      """
    Then the result should be, in any order:
      | c  |
      | 34 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v)
      RETURN count(v.id) AS c
      """
    Then the result should be, in any order:
      | c  |
      | 34 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v)
      RETURN sum(v.id) AS c
      """
    Then the result should be, in any order:
      | c  |
      | 91 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v)
      RETURN min(v.id) AS c
      """
    Then the result should be, in any order:
      | c |
      | 1 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v)
      RETURN max(v.id) AS c
      """
    Then the result should be, in any order:
      | c |
      | 6 |
    When executing query:
      """
       /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v)
      RETURN avg(v.id) AS c
      """
    Then the result should be, in any order:
      | c                 |
      | 2.676470588235294 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v)
      RETURN bitand(v.id) AS c
      """
    Then the result should be, in any order:
      | c |
      | 0 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v)
      RETURN bitor(v.id) AS c
      """
    Then the result should be, in any order:
      | c |
      | 7 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v)
      RETURN bitxor(v.id) AS c
      """
    Then the result should be, in any order:
      | c |
      | 3 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v)
      RETURN stddev_pop(v.id) AS c
      """
    Then the result should be, in any order:
      | c                  |
      | 1.2997870467049617 |

  Scenario: transfer project
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_computation_to_storage=on") */
      USE ldbc
      MATCH (v)
      LET id = v.id
      RETURN avg(v.id) AS c group by id
      """
    Then the result should be, in any order:
      | c   |
      | 5.0 |
      | 6.0 |
      | 4.0 |
      | 2.0 |
      | 3.0 |
      | 1.0 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_computation_to_storage=on") */
      USE ldbc
      MATCH (v)
      LET id = v.id
      RETURN count(*) AS c group by id
      """
    Then the result should be, in any order:
      | c |
      | 1 |
      | 1 |
      | 8 |
      | 8 |
      | 8 |
      | 8 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_computation_to_storage=on") */
      USE ldbc
      MATCH (v)
      LET id = v.id
      RETURN sum(v.id) AS c, id group by id order by id
      """
    Then the result should be, in any order:
      | c  | id |
      | 8  | 1  |
      | 16 | 2  |
      | 24 | 3  |
      | 32 | 4  |
      | 5  | 5  |
      | 6  | 6  |

  Scenario: transfer multi aggregate
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v)
      RETURN count(v.id) AS c, sum(v.id) AS s, avg(v.id) AS a, stddev_pop(v.id) as std, count(*) as co
      """
    Then the result should be, in any order:
      | c  | s  | a                 | std                | co |
      | 34 | 91 | 2.676470588235294 | 1.2997870467049617 | 34 |

  Scenario: transfer, partial and single:
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1)
      SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      use ldbc
      match (v)-[e]->()
      let id = v.id
      return count(e) as c, id group by id
      """
    Then the result should be, in any order:
      | c  | id |
      | 25 | 2  |
      | 25 | 3  |
      | 24 | 1  |
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10)
      SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      use ldbc
      match (v)-[e]->()
      let id = v.id
      return count(e) as c, id group by id
      """
    Then the result should be, in any order:
      | c  | id |
      | 25 | 2  |
      | 25 | 3  |
      | 24 | 1  |
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1)
      SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      use ldbc
      match (v)-[e]->()
      let id = v.id
      return count(e) as c, id group by id
      """
    Then the result should be, in any order:
      | c  | id |
      | 25 | 2  |
      | 25 | 3  |
      | 24 | 1  |
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10)
      SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      use ldbc
      match (v)-[e]->()
      let id = v.id
      return count(e) as c, id group by id
      """
    Then the result should be, in any order:
      | c  | id |
      | 25 | 2  |
      | 25 | 3  |
      | 24 | 1  |

  Scenario: test any_value with parallel and pushdown
    # Test any_value with single thread (no merge)
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1) */
      USE ldbc
      MATCH (v:Person)
      RETURN DISTINCT v.id in [1, 2, 3, 4] as val
      """
    Then the result should be, in any order:
      | val  |
      | true |
    # Test any_value with multiple threads (merge)
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10) */
      USE ldbc
      MATCH (v:Person)
      RETURN DISTINCT v.id in [1, 2, 3, 4] as val
      """
    Then the result should be, in any order:
      | val  |
      | true |
    # Test any_value with pushdown
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v:Person)
       RETURN DISTINCT any_value(v.id) in [1, 2, 3, 4] as val
      """
    Then the result should be, in any order:
      | val  |
      | true |
    # Test any_value with group by and parallel
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10) */
      USE ldbc
      MATCH (v:Person)
      LET gender = v.gender
      RETURN any_value(v.id) IN
        CASE WHEN gender = "male" THEN LIST[1, 2, 3] ELSE LIST[4] END
        AS val, gender
      GROUP BY gender
      """
    Then the result should be, in any order:
      | val  | gender   |
      | true | "male"   |
      | true | "female" |

  Scenario: test collect with parallel and pushdown
    # Test collect with single thread
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1) */
      USE ldbc
      MATCH (v:Person)
      ORDER BY v.id
      RETURN collect(v.id) AS ids
      """
    Then the result should be, in any order:
      | ids           |
      | LIST[1,2,3,4] |
    # Test collect with multiple threads (merge)
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10) */
      USE ldbc {
        MATCH (v:Person)
        RETURN collect(v.id) AS cnt
        NEXT
        FOR i in cnt
        RETURN i
      }
      """
    Then the result should be, in any order:
      | i |
      | 4 |
      | 3 |
      | 2 |
      | 1 |
    # Test collect with pushdown
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc {
        MATCH (v:Person)
        RETURN collect(v.id) AS cnt
        NEXT
        FOR i in cnt
        RETURN i
      }
      """
    Then the result should be, in any order:
      | i |
      | 4 |
      | 3 |
      | 2 |
      | 1 |
    # Test collect with group by and parallel
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10)
         SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off")  */
      USE ldbc
      MATCH (v:Person)
      LET gender = v.gender
      RETURN size(collect(v.id)) AS cnt, gender
      GROUP BY gender
      """
    Then the result should be, in any order:
      | cnt | gender   |
      | 1   | "female" |
      | 3   | "male"   |

  Scenario: test stddev_samp with parallel and pushdown
    # Test stddev_samp with single thread
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1)
      SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on")  */
      USE ldbc
      MATCH (v:Person)
      RETURN stddev_samp(v.id) AS std
      """
    Then the result should be, in any order:
      | std                |
      | 1.2909944487358056 |
    # Test stddev_samp with multiple threads (merge)
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      USE ldbc
      MATCH (v:Person)
      RETURN stddev_samp(v.id) AS std
      """
    Then the result should be, in any order:
      | std                |
      | 1.2909944487358056 |
    # Test stddev_samp with group by and parallel
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1)
        SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v:Person)
      LET gender = v.gender
      RETURN stddev_samp(v.id) AS std, gender
      GROUP BY gender
      """
    Then the result should be, in any order:
      | std  | gender   |
      | null | "female" |
      | 1.0  | "male"   |
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10)
        SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      USE ldbc
      MATCH (v:Person)
      LET gender = v.gender
      RETURN stddev_samp(v.id) AS std, gender
      GROUP BY gender
      """
    Then the result should be, in any order:
      | std  | gender   |
      | null | "female" |
      | 1.0  | "male"   |

  Scenario: test percentile_cont with parallel and transfer
    # Test percentile_cont with single thread
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      use ldbc
      match (v)
      RETURN percentile_cont(v.id, 0.3) AS p
      """
    Then the result should be, in any order:
      | p    |
      | 2.0M |
    # Test percentile_cont with multiple threads (merge)
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      use ldbc
      match (v)
      RETURN percentile_cont(v.id, 0.3) AS p
      """
    Then the result should be, in any order:
      | p    |
      | 2.0M |
    # distinct
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      use ldbc
      match (v)
      RETURN percentile_cont(distinct v.id, 0.3) AS p
      """
    Then the result should be, in any order:
      | p    |
      | 2.5M |
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      use ldbc
      match (v)
      RETURN percentile_cont(distinct v.id, 0.3) AS p
      """
    Then the result should be, in any order:
      | p    |
      | 2.5M |

  Scenario: test percentile_disc with parallel
    # Test percentile_disc with single thread
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      use ldbc
      match (v)
      RETURN percentile_disc(v.id, 0.5) AS p
      """
    Then the result should be, in any order:
      | p    |
      | 3.0M |
    # Test percentile_disc with multiple threads (merge)
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      use ldbc
      match (v)
      RETURN percentile_disc(v.id, 0.5) AS p
      """
    Then the result should be, in any order:
      | p    |
      | 3.0M |
    # distinct
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      use ldbc
      match (v)
      RETURN percentile_disc(distinct v.id, 0.5) AS p
      """
    Then the result should be, in any order:
      | p    |
      | 3.0M |
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      use ldbc
      match (v)
      RETURN percentile_disc(distinct v.id, 0.5) AS p
      """
    Then the result should be, in any order:
      | p    |
      | 3.0M |

  Scenario: test mixed aggregates with parallel and pushdown
    # Test multiple aggregates together with single thread
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      USE ldbc
      MATCH (v:Person)
      RETURN count(v.id) AS cnt,
             sum(v.id) AS s,
             avg(v.id) AS a,
             min(v.id) AS mi,
             max(v.id) AS ma,
             stddev_pop(v.id) AS std_p,
             stddev_samp(v.id) AS std_s,
             size(collect(v.id)) AS collect_cnt
      """
    Then the result should be, in any order:
      | cnt | s  | a   | mi | ma | std_p             | std_s              | collect_cnt |
      | 4   | 10 | 2.5 | 1  | 4  | 1.118033988749895 | 1.2909944487358056 | 4           |
    # Test multiple aggregates together with multiple threads (merge)
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      USE ldbc
      MATCH (v:Person)
      RETURN count(v.id) AS cnt,
             sum(v.id) AS s,
             avg(v.id) AS a,
             min(v.id) AS mi,
             max(v.id) AS ma,
             stddev_pop(v.id) AS std_p,
             stddev_samp(v.id) AS std_s,
             size(collect(v.id)) AS collect_cnt
      """
    Then the result should be, in any order:
      | cnt | s  | a   | mi | ma | std_p             | std_s              | collect_cnt |
      | 4   | 10 | 2.5 | 1  | 4  | 1.118033988749895 | 1.2909944487358056 | 4           |
    # Test multiple aggregates together with pushdown
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v:Person)
      RETURN count(v.id) AS cnt,
             sum(v.id) AS s,
             avg(v.id) AS a,
             min(v.id) AS mi,
             max(v.id) AS ma,
             stddev_pop(v.id) AS std_p,
             stddev_samp(v.id) AS std_s,
             size(collect(v.id)) AS collect_cnt
      """
    Then the result should be, in any order:
      | cnt | s  | a   | mi | ma | std_p             | std_s              | collect_cnt |
      | 4   | 10 | 2.5 | 1  | 4  | 1.118033988749895 | 1.2909944487358056 | 4           |

  Scenario: test edge aggregate with parallel and pushdown
    # Test edge aggregate with single thread
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      USE ldbc
      MATCH (v:Person)-[e:KNOWS]->()
      LET id = v.id
      RETURN count(e) AS c, id GROUP BY id
      """
    Then the result should be, in any order:
      | c | id |
      | 1 | 2  |
      | 1 | 1  |
      | 1 | 3  |
    # Test edge aggregate with multiple threads (merge)
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10)
          SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=off") */
      USE ldbc
      MATCH (v:Person)-[e:KNOWS]->()
      LET id = v.id
      RETURN count(e) AS c, id GROUP BY id
      """
    Then the result should be, in any order:
      | c | id |
      | 1 | 2  |
      | 1 | 1  |
      | 1 | 3  |
    # Test edge aggregate with pushdown
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v:Person)-[e:KNOWS]->()
      LET id = v.id
      RETURN count(e) AS c, id GROUP BY id
      """
    Then the result should be, in any order:
      | c | id |
      | 1 | 2  |
      | 1 | 3  |
      | 1 | 1  |

  Scenario: test empty result with parallel and pushdown
    # Test empty with parallel
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 10) */
      USE ldbc
      MATCH (v:Person)
      WHERE false
      RETURN count(v.id) AS c,
             sum(v.id) AS s,
             stddev_pop(v.id) AS std,
             any_value(v.id) AS any_val,
             size(collect(v.id)) AS collect_cnt
      """
    Then the result should be, in any order:
      | c | s    | std  | any_val | collect_cnt |
      | 0 | NULL | NULL | NULL    | 0           |
    # Test empty with pushdown
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "transfer_aggregate_to_storage=on") */
      USE ldbc
      MATCH (v:Person)
      WHERE false
      RETURN count(v.id) AS c,
             sum(v.id) AS s,
             stddev_pop(v.id) AS std,
             any_value(v.id) AS any_val
      """
    Then the result should be, in any order:
      | c | s    | std  | any_val |
      | 0 | NULL | NULL | NULL    |
