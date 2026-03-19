# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: While Statement

  Scenario: basic
    And use graph "ldbc"
    When executing query:
      """
      VALUE a = 1
      WHILE a < 10 THEN {
        SET a = a + 1
      }
      RETURN a
      """
    Then the result should be, in any order:
      | a  |
      | 10 |
    When executing query:
      """
      VALUE a = 1
      WHILE a < 10 THEN {
        SET a = a + 4
      }
      RETURN a
      """
    Then the result should be, in any order:
      | a  |
      | 13 |
    When executing query:
      """
      VALUE a = 1
      WHILE a < 1 THEN {
        SET a = a + 1
      }
      RETURN a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      VALUE a = 1
      WHILE a < 10 THEN {
        VALUE b = 4
        SET a = a + b
      }
      RETURN a
      """
    Then the result should be, in any order:
      | a  |
      | 13 |
    When executing query:
      """
      VALUE i = 0
      WHILE i < 3 THEN {
        SET i = i + 1
      }
      RETURN i
      """
    Then the result should be, in any order:
      | i |
      | 3 |
    When executing query:
      """
      VALUE i = 0
      VALUE j = 0
      VALUE count = 0
      WHILE i < 3 THEN {
       WHILE j < 3 THEN {
           IF i = 1 AND j = 1 THEN {
               SET j = j + 1
               CONTINUE
           }
           IF i = 2 AND j = 1 THEN {
               BREAK
           }
           SET count = count + 1
           SET j = j + 1
       }
       SET j = 0
       SET i = i + 1
      }
      RETURN count
      """
    Then the result should be, in any order:
      | count |
      | 6     |
    When executing query:
      """
      value i = 0
      value a::int64 = 3
      while i < 2 then {
          set a = value {use ldbc match (v:Person)-[e]->(v2:Person) where v.id = a return count(v2) }
          set i = i + 1
      }
      return i, a
      """
    Then the result should be, in any order:
      | i | a |
      | 2 | 3 |
    When executing query:
      """
      VALUE cur_iter = 0
      VALUE res = 0
      WHILE cur_iter < 10000 THEN {
        SET res = res + cur_iter
        SET cur_iter = cur_iter + 1
      }
      RETURN res
      """
    Then the result should be, in any order:
      | res      |
      | 49995000 |
    When executing query:
      """
      VALUE cur_iter = 0
      VALUE res = 0
      WHILE cur_iter < 10000 THEN {
        SET res = res + cur_iter
        IF cur_iter = 5000 THEN {
          BREAK
        }
        SET cur_iter = cur_iter + 1
      }
      RETURN res
      """
    Then the result should be, in any order:
      | res      |
      | 12502500 |

  Scenario: while with dml
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_while_with_dml AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, name STRING})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_while_with_dml TYPED test_while_with_dml
      """
    Then the execution should be successful
    And graph "test_while_with_dml" should be ready to use
    # Use while loop to insert 5 Person nodes with id from 1 to 5
    When executing query:
      """
      value i int = 0
      while i < 5 then {
        set i = i+1
        use test_while_with_dml insert(v@Person{id:i})
      }
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 5     |
      | "num_affected_edges" | 0     |
    # Query all Person nodes, name should be null
    When executing query:
      """
      USE test_while_with_dml
      MATCH (v:Person) RETURN v.id, v.name
      """
    Then the result should be, in any order:
      | v.id | v.name |
      | 1    | null   |
      | 2    | null   |
      | 3    | null   |
      | 4    | null   |
      | 5    | null   |
    # Use while loop to update all Person nodes' name to "_name"
    When executing query:
      """
      value i int = 0
      value str string = "_name"
      while i < 5 then {
        set i = i+1
        use test_while_with_dml match(v@Person{id:i}) set v.name = str
      }
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 5     |
      | "num_affected_edges" | 0     |
    # Query all Person nodes, name should be "_name"
    When executing query:
      """
      USE test_while_with_dml
      MATCH (v:Person) RETURN v.id, v.name
      """
    Then the result should be, in any order:
      | v.id | v.name  |
      | 1    | "_name" |
      | 2    | "_name" |
      | 3    | "_name" |
      | 4    | "_name" |
      | 5    | "_name" |
    # Use while loop to delete all nodes
    When executing query:
      """
      value i int = 0
      while i < 5 then {
        set i = i+1
        use test_while_with_dml match(v@Person{id:i}) delete v
      }
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 5     |
      | "num_affected_edges" | 0     |
    # Query all nodes, should be empty
    When executing query:
      """
      USE test_while_with_dml
      MATCH (v:Person) RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    And drop the graph "test_while_with_dml"
    And drop the graph type "test_while_with_dml"
