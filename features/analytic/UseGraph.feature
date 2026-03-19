# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: UseGraph

  Scenario: without temp graph
    When executing graph analytic query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING} FOR i IN t RETURN i
      """
    Then the result should be, in any order:
      | i |
    When executing graph analytic query:
      """
      TABLE t {prop1 INT8, prop2 FLOAT, prop3 STRING} FOR i IN t RETURN i
      """
    Then the result should be, in any order:
      | i |
    When executing graph analytic query:
      """
      VALUE x SumAgg<INT> = 0
      SET @x = 1
      RETURN @x
      """
    Then the result should be, in any order:
      | @x |
      | 1  |
    When executing graph analytic query:
      """
      VALUE test_set ACTIVE_SET
      RETURN 1
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    When executing graph query:
      """
      USE ldbc {
        VALUE test_set ACTIVE_SET
        RETURN 1
      }
      """
    Then an Error should be raised: "[NR123]: Temporary graph not found: `ldbc`"
    When executing graph analytic query:
      """
      NODE VALUE x SumAgg<INT> = 0
      RETURN 1
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    When executing graph query:
      """
      USE ldbc {
        NODE VALUE x SumAgg<INT> = 0
        RETURN 1
      }
      """
    Then an Error should be raised: "[NR123]: Temporary graph not found: `ldbc`"
    When executing graph analytic query:
      """
      MATCH (x)
      PER NODE (x) {
        LOG_INFO(x)
      }
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    When executing graph query:
      """
      USE ldbc {
        MATCH (x)
        PER NODE (x) {
          LOG_INFO(x)
        }
      }
      """
    Then an Error should be raised: "[NR123]: Temporary graph not found: `ldbc`"

  Scenario: update physical graph
    When executing query:
      """
      CREATE GRAPH ldbc_analytic_test TYPED ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE #analytic_ldbc {
        TABLE t {id INT}

        MATCH (x@Person)
        PER NODE (x) {
          EXPORT x.id INTO t
        }

        USE ldbc_analytic_test
        FOR r IN t
        INSERT (@Person{id:r.id})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_analytic_test
      MATCH (a@Person)
      RETURN a.id
      """
    Then the result should be, in any order:
      | a.id |
      | 2    |
      | 1    |
      | 4    |
      | 3    |
    When executing query:
      """
      USE #analytic_ldbc {
        TABLE t {id INT, firstName STRING}

        MATCH (x@Person)
        PER NODE (x) {
          EXPORT x.id, x.firstName INTO t
        }

        USE ldbc_analytic_test
        FOR r IN t
        MATCH (a@Person{id:r.id})
        SET a.firstName = r.firstName
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_analytic_test
      MATCH (a@Person)
      RETURN a.id,a.firstName
      """
    Then the result should be, in any order:
      | a.id | a.firstName |
      | 2    | "Tim"       |
      | 4    | "Sophie"    |
      | 1    | "Kyle"      |
      | 3    | "Ming"      |
    And drop the graph "ldbc_analytic_test"

  Scenario: unsupported multi graphs
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH #analytic_ldbc_1 AS COPY OF ldbc
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #analytic_ldbc_1 TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #analytic_ldbc_1 IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE sum_node SumAgg<INT> = 0
          USE #analytic_ldbc_1 {
            MATCH(a:Person)
            PER NODE (a) {
              SET a.@sum_node += 1
            }
          }
      }
      """
    Then an Error should be raised: "[NT000]: ActiveSet, Node Aggregator, and Match Compute Statement should use the same graph. Previous graph: `#analytic_ldbc`, next graph: `#analytic_ldbc_1`"
    And drop the graph "#analytic_ldbc_1"
