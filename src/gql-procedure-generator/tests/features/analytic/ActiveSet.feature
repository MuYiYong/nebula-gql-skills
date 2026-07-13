# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Active Set Test

  Scenario: Define ActiveSet Variable
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set ACTIVE_SET
        RETURN 1
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set :: ACTIVE_SET
        RETURN 1
      }
      """
    Then the execution should be successful

  Scenario: Use ActiveSet Variable
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set :: ACTIVE_SET
        VALUE ids ListAgg<INT64>

        SET active_set = [1]

        MATCH (v)-(t)
        WHERE v IN active_set
        PER PATH {
          SET @ids += t.id
        }
        PER NODE(v) {
          SET @ids += v.id
        }
        FINALLY {
          SET active_set = t
        }

        RETURN @ids
      }
      """
    Then an Error should be raised:
      """
      [NR027]: Node with element id `1` does not exist
      """
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set :: ACTIVE_SET
        VALUE ids ListAgg<INT64>

        MATCH (s@Place) WHERE s.id = 5
        FINALLY {
            SET active_set = s
        }

        MATCH (v)-(t)
        WHERE v IN active_set
        PER PATH {
          SET @ids += t.id
        }
        PER NODE(v) {
          SET @ids += v.id
        }
        FINALLY {
          SET active_set = t
        }
        RETURN @ids
      }
      """
    Then the result should be, in any order:
      | @ids       |
      | LIST [2,5] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE start_set :: ACTIVE_SET
        VALUE reverse_set :: ACTIVE_SET
        NODE VALUE is_src OrAgg = false
        NODE VALUE is_dst OrAgg = false
        NODE VALUE is_not_dst OrAgg = false
        TABLE result_table TYPED TABLE{node_id INT64, is_src BOOL, is_dst BOOL, is_not_dst BOOL}

        MATCH (s@Person) WHERE s.id = 1
        FINALLY {
            SET start_set = s
        }

        MATCH (s)-[]->(t)
        WHERE s IN start_set
        PER NODE (s) {
          SET s.@is_src = true
        }
        PER NODE (t) {
          SET t.@is_dst = true
        }

        MATCH (s1) WHERE s1.@is_dst = false
        FINALLY {
          SET reverse_set = s1
        }

        MATCH (s2)
        WHERE s2 IN reverse_set
        PER NODE (s2) {
          SET s2.@is_not_dst = true
        }

        MATCH(s3)
        PER NODE (s3) {
          EXPORT s3.id, s3.@is_src, s3.@is_dst, s3.@is_not_dst INTO result_table
        }

        FOR r in result_table
        RETURN r.node_id,r.is_src,r.is_dst,r.is_not_dst
      }
      """
    Then the result should be, in any order:
      | r.node_id | r.is_src | r.is_dst | r.is_not_dst |
      | 6         | false    | false    | true         |
      | 5         | false    | false    | true         |
      | 4         | false    | false    | true         |
      | 3         | false    | false    | true         |
      | 2         | false    | false    | true         |
      | 1         | false    | true     | false        |
      | 4         | false    | false    | true         |
      | 3         | false    | false    | true         |
      | 2         | false    | false    | true         |
      | 1         | false    | false    | true         |
      | 4         | false    | false    | true         |
      | 3         | false    | false    | true         |
      | 2         | false    | false    | true         |
      | 1         | false    | true     | false        |
      | 4         | false    | false    | true         |
      | 3         | false    | false    | true         |
      | 2         | false    | true     | false        |
      | 1         | true     | true     | false        |
      | 4         | false    | false    | true         |
      | 3         | false    | false    | true         |
      | 2         | false    | false    | true         |
      | 1         | false    | true     | false        |
      | 4         | false    | false    | true         |
      | 3         | false    | false    | true         |
      | 2         | false    | false    | true         |
      | 1         | false    | true     | false        |
      | 4         | false    | false    | true         |
      | 3         | false    | false    | true         |
      | 2         | false    | false    | true         |
      | 1         | false    | true     | false        |
      | 4         | false    | false    | true         |
      | 3         | false    | false    | true         |
      | 2         | false    | false    | true         |
      | 1         | false    | false    | true         |

  Scenario: Union ActiveSet
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set ACTIVE_SET
        VALUE ids ListAgg<INT>
        VALUE cur_iter = 0

        MATCH (s@Person) WHERE s.id = 1
        FINALLY {
            SET active_set = s
        }

        WHILE cur_iter < 2 THEN {
          MATCH (s WHERE s IN active_set)-[:FOLLOWS]->(t)
          FINALLY {
            SET active_set |= t
          }

          SET cur_iter = cur_iter + 1
        }
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          SET @ids += s.id
        }

        FOR r IN @ids
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 3 |
      | 1 |
      | 4 |
      | 2 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set_1 ACTIVE_SET
        VALUE active_set_2 ACTIVE_SET
        VALUE ids ListAgg<INT>
        VALUE cur_iter = 0

        MATCH (a@Person)
        WHERE a.id = 1
        FINALLY {
          SET active_set_1 = a
        }

        WHILE cur_iter < 2 THEN {
          MATCH (a)-[:FOLLOWS]->(t)
          WHERE a IN active_set_1
          FINALLY {
            SET active_set_2 |= t
          }

          SET cur_iter = cur_iter + 1

          MATCH (a)
          WHERE a IN active_set_2
          FINALLY {
          SET active_set_1 = a
        }
        }

        MATCH (a)
        WHERE a IN active_set_2
        PER NODE (a) {
          SET @ids += a.id
        }

        FOR r IN @ids
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 3 |
      | 4 |
      | 2 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set_1 ACTIVE_SET
        VALUE active_set_2 ACTIVE_SET
        VALUE ids ListAgg<INT>

        MATCH (a@Person)
        WHERE a.id = 1
        FINALLY {
          SET active_set_1 = a
        }

        MATCH (a@Person)
        WHERE a.id <> 1
        FINALLY {
          SET active_set_2 |= a
        }

        MATCH (a@Person)
        WHERE a IN active_set_1
        FINALLY {
          SET active_set_2 |= a
        }

        MATCH (a@Person)
        WHERE a IN active_set_2
        PER NODE (a) {
          SET @ids += a.id
        }

        FOR r IN @ids
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 3 |
      | 1 |
      | 4 |
      | 2 |

  Scenario: Except ActiveSet
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
       VALUE active_set ACTIVE_SET
       VALUE ids ListAgg<INT>

       MATCH (s1@Person) WHERE s1.id in [1,2,3,4,5]
       FINALLY {
           SET active_set |= s1
       }
       MATCH (s2@Person) WHERE s2.id in [1,3,5,7]
       FINALLY {
           SET active_set -= s2
       }
       MATCH (s)
       WHERE s IN active_set
       PER NODE (s) {
         SET @ids += s.id
       }

       FOR r IN @ids
       RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 4 |
      | 2 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
       VALUE active_set ACTIVE_SET
       VALUE ids ListAgg<INT>

       MATCH (s1@Person)-[:FOLLOWS]->() WHERE s1.id in [1,2,3]
       FINALLY {
           SET active_set |= s1
       }
       MATCH (s2@Person)-[:FOLLOWS]->() WHERE s2.id in [1]
       FINALLY {
           SET active_set -= s2
       }
       MATCH (s)
       WHERE s IN active_set
       PER NODE (s) {
         SET @ids += s.id
       }

       FOR r IN @ids
       RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 3 |
      | 2 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set_1 ACTIVE_SET
        VALUE active_set_2 ACTIVE_SET
        VALUE ids ListAgg<INT>
        VALUE cur_iter = 0

        MATCH (a@Person)
        WHERE a.id = 1
        FINALLY {
          SET active_set_1 = a
        }
        MATCH (a@Person)
        WHERE a.id IN [1,2,5,7]
        FINALLY {
          SET active_set_2 |= a
        }

        MATCH (b)-[:FOLLOWS]->(c)
          WHERE b IN active_set_1
          FINALLY {
            SET active_set_2 -= b
          }

        MATCH (c)
        WHERE c IN active_set_2
        PER NODE (c) {
          SET @ids += c.id
        }
        FOR r IN @ids
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 2 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set_1 ACTIVE_SET
        VALUE active_set_2 ACTIVE_SET
        VALUE ids1 ListAgg<INT>
        VALUE cur_iter = 0

        MATCH (a@Person)
        WHERE a.id IN [3,4]
        FINALLY {
          SET active_set_1 = a
        }

        WHILE cur_iter < 1 THEN {
          MATCH (a)-[:FOLLOWS]->(t)
          WHERE a IN active_set_1
          FINALLY {
            SET active_set_1 |= t
            SET active_set_2 = t
          }

          SET cur_iter = cur_iter + 1

          MATCH (a)-[:FOLLOWS]->(t)
          WHERE a IN active_set_2 and a.id > 1
          FINALLY {
          SET active_set_1 -= t
          SET active_set_2 -= a
        }
        }

        MATCH (a)
        WHERE a IN active_set_1
        PER NODE (a) {
          SET @ids1 += a.id
        }
        MATCH (a)
        WHERE a IN active_set_2
        PER NODE (a) {
          SET @ids1 += a.id
        }

        FOR i IN @ids1
        RETURN i
      }
      """
    Then the result should be, in any order:
      | i |
      | 2 |
      | 1 |
      | 1 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set_1 ACTIVE_SET
        VALUE active_set_2 ACTIVE_SET
        VALUE ids1 ListAgg<INT>
        VALUE ids2 ListAgg<INT>
        VALUE cur_iter = 0

        MATCH (a@Person)
        WHERE a.id IN [3,4]
        FINALLY {
          SET active_set_1 = a
        }

        WHILE cur_iter < 2 THEN {
          MATCH (a)-[:FOLLOWS]->(t)
          WHERE a IN active_set_1
          FINALLY {
            SET active_set_1 |= t
            SET active_set_2 = t
          }

          SET cur_iter = cur_iter + 1

          MATCH (a)-[:FOLLOWS]->(t)
          WHERE a IN active_set_2 and a.id > 1
          FINALLY {
          SET active_set_1 -= t
          SET active_set_2 -= a
        }
        }

        MATCH (a)
        WHERE a IN active_set_1
        PER NODE (a) {
          SET @ids1 += a.id
        }
        MATCH (a)
        WHERE a IN active_set_2
        PER NODE (a) {
          SET @ids2 += a.id
        }

        RETURN @ids1 AS id1, @ids2 AS id2
      }
      """
    Then the result should be, in any order:
      | id1    | id2     |
      | LIST[] | LIST[4] |

  Scenario: Set ActiveSet
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set :: ACTIVE_SET
        VALUE ids ListAgg<INT>
        MATCH (a@Person)
        PER NODE (a) {
          SET @ids += element_id(a)
        }
        SET active_set = @ids
        SET @ids.clear()

        MATCH (a)
        WHERE a IN active_set
        PER NODE (a) {
          SET @ids += a.id
        }

        FOR id IN @ids
        RETURN id
      }
      """
    Then the result should be, in any order:
      | id |
      | 4  |
      | 2  |
      | 1  |
      | 3  |

  Scenario: Invalid ActiveSet Variable Used
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set :: ACTIVE_SET
        VALUE ids ListAgg<INT64>

        MATCH (v)-(t)
        WHERE s IN active_set
        PER PATH {
          SET @ids += element_id(t)
        }
        FINALLY {
          SET active_set = t
        }

        RETURN @ids
      }
      """
    Then an Error should be raised:
      """
      [42N54]: Invalid syntax, invalid node variable reference: `s`
      """
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (v)-(t)
        WHERE v IN active_set
        FINALLY {
          SET active_set = t
        }
        RETURN @ids
      }
      """
    Then an Error should be raised:
      """
      [42N18]: Invalid syntax, variable `active_set` not defined
      """
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set = 1
        MATCH (v)-(t)
        WHERE v IN active_set
        FINALLY {
          SET active_set = t
        }
        FINISH
      }
      """
    Then an Error should be raised:
      """
      [NR002]: Undefined function: `in(NODE, INT32)`
      """
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set :: ACTIVE_SET
        VALUE ids ListAgg<INT64>

        MATCH (v)-(t)
        WHERE t IN active_set
        PER PATH {
          SET @ids += element_id(t)
        }
        FINALLY {
          SET active_set = t
        }

        RETURN @ids
      }
      """
    Then an Error should be raised:
      """
      [NT000]: The active set filter in the MATCH COMPUTE statement can only be used for the first node pattern `v` for now
      """

  Scenario: ActiveSet and index
    When executing graph query:
      """
      USE #analytic_ldbc {
        VALUE count SumAgg<INT> = 0

        MATCH (v:Person{id:1})-(t)
        PER PATH {
          SET @count += 1
        }

        RETURN @count
      }
      """
    Then the result should be, in any order:
      | @count |
      | 14     |
    When executing graph query:
      """
      USE #analytic_ldbc {
        VALUE active_set ACTIVE_SET
        VALUE count SumAgg<INT> = 0

        MATCH (v:Person{id:1})-(t)
        WHERE v IN active_set
        PER PATH {
          SET @count += 1
        }

        RETURN @count
      }
      """
    Then the result should be, in any order:
      | @count |
      | 0      |
    When executing graph query:
      """
      USE #analytic_ldbc {
        VALUE active_set ACTIVE_SET
        VALUE count SumAgg<INT> = 0

        MATCH (a:Person{id:1})
        FINALLY { SET active_set = a }

        MATCH (a:Person)-[e]-(b)
        WHERE a.id < 3 AND a IN active_set
        PER PATH {
          SET @count += 1
        }

        RETURN @count
      }
      """
    Then the result should be, in any order:
      | @count |
      | 14     |

  Scenario: multiple update ActiveSet
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
      VALUE active_set0 ACTIVE_SET
      VALUE active_set1 ACTIVE_SET
      VALUE active_set2 ACTIVE_SET
      VALUE x MinAgg<INT> = 100
      TABLE result TYPED TABLE {id INT64}

      MATCH (s)-[]->()
      FINALLY {
          SET active_set0 = s
      }

      MATCH (s)
      WHERE s IN active_set0
      FINALLY {
         SET active_set0 = s
         SET active_set1 = s
         SET active_set2 = s
      }

      MATCH (s)-[]-(t)
      where s in active_set2
      PER PATH {
        SET @x += s.id
      }
      PER NODE (s) {
          SET @x += s.id
      }
      PER NODE (s) {
          SET @x += s.id
      }
      FINALLY {
          SET active_set0 = s
          SET active_set1 = s
      }

      MATCH (s)
      WHERE s in active_set1
      PER NODE (s) {
          export s.id into result
      }

      FOR i IN result
      RETURN i.id AS vid, @x
      ORDER BY vid
      }
      """
    Then the result should be, in any order:
      | vid | @x |
      | 1   | 1  |
      | 1   | 1  |
      | 1   | 1  |
      | 1   | 1  |
      | 1   | 1  |
      | 1   | 1  |
      | 1   | 1  |
      | 1   | 1  |
      | 2   | 1  |
      | 2   | 1  |
      | 2   | 1  |
      | 2   | 1  |
      | 2   | 1  |
      | 2   | 1  |
      | 2   | 1  |
      | 2   | 1  |
      | 3   | 1  |
      | 3   | 1  |
      | 3   | 1  |
      | 3   | 1  |
      | 3   | 1  |
      | 3   | 1  |
      | 3   | 1  |
      | 3   | 1  |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set0 ACTIVE_SET
        VALUE active_set1 ACTIVE_SET
        VALUE active_set2 ACTIVE_SET
        VALUE active_set3 ACTIVE_SET
        NODE VALUE in_set0 OrAgg = false
        NODE VALUE in_set1 OrAgg = false
        NODE VALUE in_set2 OrAgg = false
        NODE VALUE in_set3 OrAgg = false
        NODE VALUE visit_count SumAgg<INT> = 0
        TABLE result TYPED TABLE {node_id INT64, visit_count INT64, in_set0 BOOL, in_set1 BOOL, in_set2 BOOL, in_set3 BOOL}

        MATCH (s@Person)
        FINALLY {
          SET active_set0 = s
        }

        MATCH (s)-[]-(t)
        WHERE s IN active_set0
        PER NODE (s) {
          SET s.@visit_count += 1
        }
        PER NODE (t) {
          SET t.@visit_count += 1
        }
        FINALLY {
          SET active_set1 = t
          SET active_set2 = t
          SET active_set3 = t
        }

        MATCH (s)-[]-(t)
        WHERE s IN active_set1
        PER NODE (s) {
          SET s.@visit_count += 1
        }
        PER NODE (t) {
          SET t.@visit_count += 1
        }
        FINALLY {
          SET active_set0 = s
          SET active_set3 |= t
        }

        MATCH (s)-[]-(t)
        WHERE s IN active_set2
        PER NODE (s) {
          SET s.@visit_count += 1
        }
        PER NODE (t) {
          SET t.@visit_count += 1
        }
        FINALLY {
          SET active_set0 |= t
          SET active_set3 = s
        }

        MATCH (s)
        WHERE s.@visit_count > 0
        FINALLY {
          SET active_set1 = s
          SET active_set2 = s
          SET active_set0 = s
          SET active_set3 = s
        }

        MATCH (s)
        WHERE s IN active_set0
        PER NODE (s) {
          SET s.@in_set0 = true
        }

        MATCH (s)
        WHERE s IN active_set1
        PER NODE (s) {
          SET s.@in_set1 = true
        }

        MATCH (s)
        WHERE s IN active_set2
        PER NODE (s) {
          SET s.@in_set2 = true
        }

        MATCH (s)
        WHERE s IN active_set3
        PER NODE (s) {
          SET s.@in_set3 = true
        }

        MATCH (v)
        PER NODE (v) {
          EXPORT v.id,
                v.@visit_count,
                v.@in_set0,
                v.@in_set1,
                v.@in_set2,
                v.@in_set3
          INTO result
        }

        FOR r IN result
        FILTER r.visit_count > 0
        RETURN r.node_id as node_id,
              r.visit_count as visit_count,
              r.in_set0 as in_set0,
              r.in_set1 as in_set1,
              r.in_set2 as in_set2,
              r.in_set3 as in_set3
        ORDER BY r.node_id
      }
      """
    Then the result should be, in any order:
      | node_id | visit_count | in_set0 | in_set1 | in_set2 | in_set3 |
      | 1       | 5           | true    | true    | true    | true    |
      | 1       | 5           | true    | true    | true    | true    |
      | 1       | 5           | true    | true    | true    | true    |
      | 1       | 5           | true    | true    | true    | true    |
      | 1       | 5           | true    | true    | true    | true    |
      | 1       | 2           | true    | true    | true    | true    |
      | 1       | 6           | true    | true    | true    | true    |
      | 1       | 5           | true    | true    | true    | true    |
      | 2       | 6           | true    | true    | true    | true    |
      | 2       | 5           | true    | true    | true    | true    |
      | 2       | 5           | true    | true    | true    | true    |
      | 2       | 5           | true    | true    | true    | true    |
      | 2       | 2           | true    | true    | true    | true    |
      | 2       | 5           | true    | true    | true    | true    |
      | 2       | 5           | true    | true    | true    | true    |
      | 2       | 5           | true    | true    | true    | true    |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 2           | true    | true    | true    | true    |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 6           | true    | true    | true    | true    |
      | 4       | 6           | true    | true    | true    | true    |
      | 4       | 2           | true    | true    | true    | true    |
      | 5       | 2           | true    | true    | true    | true    |
      | 6       | 2           | true    | true    | true    | true    |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set0 ACTIVE_SET
        VALUE active_set1 ACTIVE_SET
        VALUE active_set2 ACTIVE_SET
        VALUE active_set3 ACTIVE_SET
        NODE VALUE in_set0 OrAgg = false
        NODE VALUE in_set1 OrAgg = false
        NODE VALUE in_set2 OrAgg = false
        NODE VALUE in_set3 OrAgg = false
        NODE VALUE visit_count SumAgg<INT> = 0
        TABLE result TYPED TABLE {node_id INT64, visit_count INT64, in_set0 BOOL, in_set1 BOOL, in_set2 BOOL, in_set3 BOOL}

        MATCH (s@Person)
        FINALLY {
          SET active_set0 = s
        }

        MATCH (s)-[]-(t)
        WHERE s IN active_set0
        PER NODE (s) {
          SET s.@visit_count += 1
        }
        PER NODE (t) {
          SET t.@visit_count += 1
        }
        FINALLY {
          SET active_set1 = t
          SET active_set2 = t
          SET active_set3 = t
        }

        MATCH (s)-[]-(t)
        WHERE s IN active_set1
        PER NODE (s) {
          SET s.@visit_count += 1
        }
        PER NODE (t) {
          SET t.@visit_count += 1
        }
        FINALLY {
          SET active_set0 = s
          SET active_set3 |= t
        }

        MATCH (s)-[]-(t)
        WHERE s IN active_set2
        PER NODE (s) {
          SET s.@visit_count += 1
        }
        PER NODE (t) {
          SET t.@visit_count += 1
        }
        FINALLY {
          SET active_set0 |= t
          SET active_set3 = s
        }

        MATCH (s)
        WHERE s IN active_set0
        PER NODE (s) {
          SET s.@in_set0 = true
        }

        MATCH (s)
        WHERE s IN active_set1
        PER NODE (s) {
          SET s.@in_set1 = true
        }

        MATCH (s)
        WHERE s IN active_set2
        PER NODE (s) {
          SET s.@in_set2 = true
        }

        MATCH (s)
        WHERE s IN active_set3
        PER NODE (s) {
          SET s.@in_set3 = true
        }

        MATCH (v)
        PER NODE (v) {
          EXPORT v.id,
                v.@visit_count,
                v.@in_set0,
                v.@in_set1,
                v.@in_set2,
                v.@in_set3
          INTO result
        }

        FOR r IN result
        FILTER r.visit_count > 0
        RETURN r.node_id as node_id,
              r.visit_count as visit_count,
              r.in_set0 as in_set0,
              r.in_set1 as in_set1,
              r.in_set2 as in_set2,
              r.in_set3 as in_set3
        ORDER BY r.node_id
      }
      """
    Then the result should be, in any order:
      | node_id | visit_count | in_set0 | in_set1 | in_set2 | in_set3 |
      | 1       | 2           | true    | false   | false   | false   |
      | 1       | 5           | true    | true    | true    | true    |
      | 1       | 5           | true    | true    | true    | true    |
      | 1       | 5           | true    | true    | true    | true    |
      | 1       | 5           | true    | true    | true    | true    |
      | 1       | 6           | true    | true    | true    | true    |
      | 1       | 5           | true    | true    | true    | true    |
      | 1       | 5           | true    | true    | true    | true    |
      | 2       | 6           | true    | true    | true    | true    |
      | 2       | 5           | true    | true    | true    | true    |
      | 2       | 5           | true    | true    | true    | true    |
      | 2       | 2           | true    | false   | false   | false   |
      | 2       | 5           | true    | true    | true    | true    |
      | 2       | 5           | true    | true    | true    | true    |
      | 2       | 5           | true    | true    | true    | true    |
      | 2       | 5           | true    | true    | true    | true    |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 2           | true    | false   | false   | false   |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 5           | true    | true    | true    | true    |
      | 3       | 6           | true    | true    | true    | true    |
      | 4       | 6           | true    | true    | true    | true    |
      | 4       | 2           | true    | false   | false   | false   |
      | 5       | 2           | true    | false   | false   | false   |
      | 6       | 2           | true    | false   | false   | false   |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set0 ACTIVE_SET
        VALUE active_set1 ACTIVE_SET
        MATCH (s)-[]-(t)
          PER NODE (s) {
            SET s.@visit_count += 1
          }
          PER NODE (t) {
            SET t.@visit_count += 1
          }
          FINALLY {
            SET active_set0 |= t
            SET active_set0 = s
          }
      }
      """
    Then an Error should be raised: "[NS238]: Invalid match compute block: Duplicate active set operation `active_set0 =` in FINALLY clause"
