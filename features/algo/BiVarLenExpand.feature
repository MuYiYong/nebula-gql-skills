# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: BiVarLenExpand

  @sf01
  Scenario: Multiple sources with concurrency
    And use graph "sf01"
    When executing query:
      """
      /*+ set_var(query_concurrency = 1)*/
      MATCH path = acyclic (p:Person WHERE p.id IN [4398046511870,21990232556482,19791209300572])<-[e:KNOWS]->{1,4}(p2:Person WHERE p2.id IN [4398046511870,21990232556482,19791209300572])
      RETURN count(e)
      """
    Then the result should be, in any order:
      | count(e) |
      | 3070     |
    When executing query:
      """
      /*+ set_var(query_concurrency = 1)*/
      MATCH path = acyclic (p:Person WHERE p.id IN [4398046511870,21990232556482,19791209300572])<-[e:KNOWS]->{1,5}(p2:Person WHERE p2.id IN [4398046511870,21990232556482,19791209300572])
      RETURN count(e)
      """
    Then the result should be, in any order:
      | count(e) |
      | 110408   |
    When executing query:
      """
      /*+ set_var(query_concurrency = 8)*/
      MATCH path = acyclic (p:Person WHERE p.id IN [4398046511870,21990232556482,19791209300572])<-[e:KNOWS]->{1,5}(p2:Person WHERE p2.id IN [4398046511870,21990232556482,19791209300572])
      RETURN count(e)
      """
    Then the result should be, in any order:
      | count(e) |
      | 110408   |
    When executing query:
      """
      /*+ set_var(query_concurrency = 16)*/
      MATCH path = acyclic (p:Person WHERE p.id IN [4398046511870,21990232556482,19791209300572])<-[e:KNOWS]->{1,5}(p2:Person WHERE p2.id IN [4398046511870,21990232556482,19791209300572])
      RETURN count(e)
      """
    Then the result should be, in any order:
      | count(e) |
      | 110408   |
    When executing query:
      """
      /*+ set_var(query_concurrency = 32)*/
      MATCH path = acyclic (p:Person WHERE p.id IN [4398046511870,21990232556482,19791209300572])<-[e:KNOWS]->{1,5}(p2:Person WHERE p2.id IN [4398046511870,21990232556482,19791209300572])
      RETURN count(e)
      """
    Then the result should be, in any order:
      | count(e) |
      | 110408   |

  @sf01
  Scenario: Outputs path count
    And use graph "sf01"
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = walk (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,3}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 583      |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = simple (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,3}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 583      |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = acyclic (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,3}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 583      |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = trail (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,3}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 583      |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = walk (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,4}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 22184    |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = simple (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,4}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 19606    |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = acyclic (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,4}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 19606    |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = trail (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,4}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 19606    |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = walk (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,5}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 841179   |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = simple (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,5}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 716973   |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = acyclic (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,5}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 716973   |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = trail (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,5}(friend:Person{firstName : "Jun"})
      RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 732365   |

  @sf01
  Scenario: Outputs distinct edge count across paths
    And use graph "sf01"
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = walk (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,3}(friend:Person{firstName : "Jun"})
      RETURN e
      NEXT
      FOR i IN e
      RETURN count(DISTINCT i) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 464 |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = simple (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,3}(friend:Person{firstName : "Jun"})
      RETURN e
      NEXT
      FOR i IN e
      RETURN count(DISTINCT i) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 464 |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = acyclic (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,3}(friend:Person{firstName : "Jun"})
      RETURN e
      NEXT
      FOR i IN e
      RETURN count(DISTINCT i) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 464 |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = trail (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,3}(friend:Person{firstName : "Jun"})
      RETURN e
      NEXT
      FOR i IN e
      RETURN count(DISTINCT i) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 464 |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = walk (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,4}(friend:Person{firstName : "Jun"})
      RETURN e
      NEXT
      FOR i IN e
      RETURN count(DISTINCT i) AS cnt
      """
    Then the result should be, in any order:
      | cnt  |
      | 4172 |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = simple (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,4}(friend:Person{firstName : "Jun"})
      RETURN e
      NEXT
      FOR i IN e
      RETURN count(DISTINCT i) AS cnt
      """
    Then the result should be, in any order:
      | cnt  |
      | 4160 |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = acyclic (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,4}(friend:Person{firstName : "Jun"})
      RETURN e
      NEXT
      FOR i IN e
      RETURN count(DISTINCT i) AS cnt
      """
    Then the result should be, in any order:
      | cnt  |
      | 4160 |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = trail (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,4}(friend:Person{firstName : "Jun"})
      RETURN e
      NEXT
      FOR i IN e
      RETURN count(DISTINCT i) AS cnt
      """
    Then the result should be, in any order:
      | cnt  |
      | 4160 |
    When executing query:
      """
      /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      MATCH path = walk (p:Person{id: 24189255811707})<-[e:KNOWS]->{1,5}(friend:Person{firstName : "Jun"})
      RETURN e
      NEXT
      FOR i IN e
      RETURN DISTINCT i
      """
    Then the execution should be successful

  Scenario: type info
    When executing query:
      """
      use ldbc {
      OPTIONAL MATCH
      p0 = (v0:Comment{id: 32})<-[e0:LIKES]-{1, 2}(v1:Person{id:123312})
      LET x = 1,
      var1 = VALUE {
          ORDER BY
              (length(p0) > 1) ASC
          RETURN
              v0 AS ri5
          LIMIT 1
      }

      return x, v0, v1
      }
      """
    Then the result should be, in any order:
      | x | v0   | v1   |
      | 1 | null | null |
