# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Analytic Variable

  Scenario: Implicit Cast
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE x INT8 = 1
        RETURN x
      }
      """
    Then the result should be, in any order:
      | x |
      | 1 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE x INT8 = "1"
        RETURN x
      }
      """
    Then an Error should be raised: "[NS208]: The type of `\"1\"(STRING)` cannot be assigned to `x(INT8)`"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE x INT8 = 1
        SET x = 2
        RETURN x
      }
      """
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE x INT8 = 1
        SET x = "2"
        RETURN x
      }
      """
    Then an Error should be raised: "[NS208]: The type of `\"2\"(STRING)` cannot be assigned to `x(INT8)`"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set ACTIVE_SET

        SET active_set = LIST["STRING"]
      }
      """
    Then an Error should be raised: "The type of `LIST[\"STRING\"](LIST<STRING>)` cannot be assigned to `active_set(ActiveSet)`"

  Scenario: Variable Definition
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE test SumAgg<INT> = 0
        VALUE test :: ACTIVE_SET
        FINISH
      }
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `test`"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE test :: ACTIVE_SET
        FILE test {id INT64} = DATAFILE {FORMAT:"csv", PATH:"test"}
        FINISH
      }
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `test`"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE test :: ACTIVE_SET
        RETURN test
      }
      """
    Then an Error should be raised: "[NS231]: Invalid variable access: `test:ActiveSet` cannot be referenced by binding variable expressions"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE test SumAgg<INT> = 0
        RETURN test
      }
      """
    Then an Error should be raised: "[NS231]: Invalid variable access: `test:Aggregator` cannot be referenced by binding variable expressions"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        FILE test {id INT64} = DATAFILE {FORMAT:"csv", PATH:"test"}
        RETURN test
      }
      """
    Then an Error should be raised: "[NS231]: Invalid variable access: `test:File` cannot be referenced by binding variable expressions"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        IF true THEN {
          NODE VALUE test SumAgg<INT> = 0
          FINISH
        }
      }
      """
    Then an Error should be raised: "[NS242]: Invalid variable definition: `test:Aggregator` can only be defined in the global scope"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        IF true THEN {
          FILE test {id INT64} = DATAFILE {FORMAT:"csv", PATH:"test"}
          FINISH
        }
      }
      """
    Then an Error should be raised: "[NS242]: Invalid variable definition: `test:File` can only be defined in the global scope"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        IF true THEN {
          VALUE test :: ACTIVE_SET
          FINISH
        }
      }
      """
    Then an Error should be raised: "[NS242]: Invalid variable definition: `test:ActiveSet` can only be defined in the global scope"
