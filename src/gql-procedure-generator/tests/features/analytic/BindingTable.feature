# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Binding Table

  Scenario: Output Table
    # empty table definition
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {vid INT64, current_score DOUBLE}
        FOR i IN result_table
        RETURN i.vid, i.current_score
      }
      """
    Then the result should be, in any order:
      | i.vid | i.current_score |
    # append constant value
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {intVal INT64, doubleVal DOUBLE, strVal STRING}
        MATCH (s1:Person)
        PER NODE (s1) {
          EXPORT 1, 2.0, "some string" INTO result_table
        }
        FOR i IN result_table
        RETURN i.intVal, i.doubleVal, i.strVal
      }
      """
    Then the result should be, in any order:
      | i.intVal | i.doubleVal | i.strVal      |
      | 1        | 2.0         | "some string" |
      | 1        | 2.0         | "some string" |
      | 1        | 2.0         | "some string" |
      | 1        | 2.0         | "some string" |
    # append agg value
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
      TABLE result_table TYPED TABLE {vid INT64, current_score DOUBLE}
      NODE VALUE current_score SumAgg<DOUBLE> = 0.0

      MATCH (s1:Person)
      PER NODE (s1) {
        SET s1.@current_score += 1.0
      }
      PER NODE (s1) {
        EXPORT s1.id, s1.@current_score INTO result_table
      }

      FOR i IN result_table
        RETURN i.vid, i.current_score
      }
      """
    Then the result should be, in any order:
      | i.vid | i.current_score |
      | 1     | 1.0             |
      | 3     | 1.0             |
      | 4     | 1.0             |
      | 2     | 1.0             |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT}
        VALUE iter = 0
        WHILE iter < 3 THEN {
          SET iter = iter + 1
          MATCH (a@Person{id:1})
          PER NODE (a) {
            EXPORT a.id INTO result_table
          }
        }
        FOR r IN result_table
        RETURN r.id
      }
      """
    Then the result should be, in any order:
      | r.id |
      | 1    |
      | 1    |
      | 1    |
    # mismatched type
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {intVal INT64, doubleVal DOUBLE, strVal STRING}
        MATCH (s1:Person)
        PER NODE (s1) {
          EXPORT 1, 2.0, 100 INTO result_table
        }
        RETURN 1
      }
      """
    Then an Error should be raised: "Type mismatch in table column 2 (0-indexed), column type: STRING vs input type: INT32."

  Scenario: Distributed Table
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT, active BOOL, score DOUBLE, name STRING} PARTITION BY DEFAULT

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, a.id % 2 = 0, 3.14, "hello" INTO result_table
        }
        PER PARTITION (result_table_part) OF result_table {
          FOR r IN result_table_part
          RETURN r.id as id, r.active as active, r.score as score, r.name as name
        }
      }
      """
    Then the result should be, in any order:
      | id | active | score | name    |
      | 4  | true   | 3.14  | "hello" |
      | 2  | true   | 3.14  | "hello" |
      | 3  | false  | 3.14  | "hello" |
      | 1  | false  | 3.14  | "hello" |
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT, active BOOL, score DOUBLE, name STRING} PARTITION BY DEFAULT

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, a.id % 2 = 0, 3.14, "hello" INTO result_table
        }

        PER PARTITION (result_table_part) OF result_table {
          SET result_table_part.clear()
        }

        PER PARTITION (result_table_part) OF result_table {
          FOR r IN result_table_part
          RETURN r.id as id, r.active as active, r.score as score, r.name as name
        }
      }
      """
    Then the result should be, in any order:
      | id | active | score | name |

  Scenario: Unsupported
    When executing graph query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT} PARTITION BY DEFAULT
        RETURN size(result_table)
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: PARTITION BY is not supported for binding table in graphd service"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT} PARTITION BY SRC
        RETURN size(result_table)
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: Partition method `SRC` is not supported for binding table"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT} = (1) PARTITION BY DEFAULT
        RETURN size(result_table)
      }
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Initial value is not supported for distributed table"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT} PARTITION BY DEFAULT
        RETURN size(result_table)
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: size function is not supported for distributed table"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT} PARTITION BY DEFAULT
        FOR i IN range(1,10) EXPORT i INTO result_table
      }
      """
    Then an Error should be raised: "[NS249]: Invalid export statement: Distributed table `result_table` can only be exported within a MATCH COMPUTE statement"

  Scenario: Import from distributed table
    And drop the graph type "import_dist_table_gt"
    And drop the graph "#import_dist_table_g"
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_dist_table_gt AS {
        NODE Person (
          LABEL Person {
            id INT64 PRIMARY KEY,
            name STRING
          }
        ),
        EDGE Knows (Person)-[:Knows{
          id INT,
          MULTIEDGE KEY()
        }]->(Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_dist_table_g1 TYPED import_dist_table_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_dist_table_g2 TYPED import_dist_table_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_dist_table_g3 TYPED import_dist_table_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_dist_table_g4 TYPED import_dist_table_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    # Test matrix: query_concurrency {1,10} x PRIMARY_KEY_AS_NODE_ID {false,true}
    # Each case uses a fresh empty temp graph.
    # Case 1: concurrency=1, PRIMARY_KEY_AS_NODE_ID=false
    When executing analytic query:
      """
      /*+ set_var(query_concurrency=1) */
      {
        TABLE persons TYPED TABLE {id INT64, name STRING} PARTITION BY DEFAULT
        TABLE edges TYPED TABLE {src_id INT64, dst_id INT64, id INT} PARTITION BY DEFAULT
        USE #analytic_ldbc {
          MATCH (v@Place)
          PER NODE (v) {
            EXPORT v.id AS id, v.name AS name INTO persons
          }
        }

        USE #analytic_ldbc {
          MATCH (v@Place)-[e]->(u@Place)
          PER PATH {
            EXPORT v.id AS src_id, v.id AS id, u.id AS dst_id INTO edges
          }
        }

        USE #import_dist_table_g1
        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name }) FROM persons,
          EDGE (id:src_id)-[e@Knows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #import_dist_table_g1 SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 6         |
      | "Edge Total" | "Edge"       | 3         |
    When executing analytic query:
      """
      USE #import_dist_table_g1 {
        TABLE result_table TYPED TABLE {id INT, name STRING}
        MATCH (v)
        PER NODE (v) {
          EXPORT v.id AS id, v.name AS name INTO result_table
        }
        FOR r IN result_table
        RETURN r.id AS id, r.name AS name
      }
      """
    Then the result should be, in any order:
      | id | name        |
      | 6  | "Shenzhen"  |
      | 5  | "Chengdu"   |
      | 3  | "Hangzhou"  |
      | 4  | "Chongqing" |
      | 2  | "Shanghai"  |
      | 1  | "Beijing"   |
    # Case 2: concurrency=1, PRIMARY_KEY_AS_NODE_ID=true
    When executing analytic query:
      """
      /*+ set_var(query_concurrency=1) */
      {
        TABLE persons TYPED TABLE {id INT64, name STRING} PARTITION BY DEFAULT
        TABLE edges TYPED TABLE {src_id INT64, dst_id INT64, id INT} PARTITION BY DEFAULT
        USE #analytic_ldbc {
          MATCH (v@Place)
          PER NODE (v) {
            EXPORT v.id AS id, v.name AS name INTO persons
          }
        }

        USE #analytic_ldbc {
          MATCH (v@Place)-[e]->(u@Place)
          PER PATH {
            EXPORT v.id AS src_id, v.id AS id, u.id AS dst_id INTO edges
          }
        }

        USE #import_dist_table_g3
        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name }) FROM persons,
          EDGE (id:src_id)-[e@Knows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #import_dist_table_g3 SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 6         |
      | "Edge Total" | "Edge"       | 3         |
    # Case 3: concurrency=10, PRIMARY_KEY_AS_NODE_ID=false
    When executing analytic query:
      """
      /*+ set_var(query_concurrency=10) */
      {
        TABLE persons TYPED TABLE {id INT64, name STRING} PARTITION BY DEFAULT
        TABLE edges TYPED TABLE {src_id INT64, dst_id INT64, id INT} PARTITION BY DEFAULT
        USE #analytic_ldbc {
          MATCH (v@Place)
          PER NODE (v) {
            EXPORT v.id AS id, v.name AS name INTO persons
          }
        }

        USE #analytic_ldbc {
          MATCH (v@Place)-[e]->(u@Place)
          PER PATH {
            EXPORT v.id AS src_id, v.id AS id, u.id AS dst_id INTO edges
          }
        }

        USE #import_dist_table_g2
        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name }) FROM persons,
          EDGE (id:src_id)-[e@Knows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #import_dist_table_g2 SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 6         |
      | "Edge Total" | "Edge"       | 3         |
    # Case 4: concurrency=10, PRIMARY_KEY_AS_NODE_ID=true
    When executing analytic query:
      """
      /*+ set_var(query_concurrency=10) */
      {
        TABLE persons TYPED TABLE {id INT64, name STRING} PARTITION BY DEFAULT
        TABLE edges TYPED TABLE {src_id INT64, dst_id INT64, id INT} PARTITION BY DEFAULT
        USE #analytic_ldbc {
          MATCH (v@Place)
          PER NODE (v) {
            EXPORT v.id AS id, v.name AS name INTO persons
          }
        }

        USE #analytic_ldbc {
          MATCH (v@Place)-[e]->(u@Place)
          PER PATH {
            EXPORT v.id AS src_id, v.id AS id, u.id AS dst_id INTO edges
          }
        }

        USE #import_dist_table_g4
        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name }) FROM persons,
          EDGE (id:src_id)-[e@Knows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #import_dist_table_g4 SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 6         |
      | "Edge Total" | "Edge"       | 3         |
    And drop the graph "#import_dist_table_g1"
    And drop the graph "#import_dist_table_g2"
    And drop the graph "#import_dist_table_g3"
    And drop the graph "#import_dist_table_g4"
    And drop the graph type "import_dist_table_gt"

  Scenario: duplicate field name
    When executing query:
      """
      TABLE nodes TYPED TABLE {id INT32, date_col STRING, id INT32} =
          {id:1,date_col:"114",id:2},
          {id:2,date_col:"514",id:2},
          {id:3,date_col:"15",id:2},
          {id:4,date_col:"810",id:2}
      FOR r IN nodes
      return r.id
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Duplicate field name `id` in table"

  Scenario: Error cases
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT, name STRING} PARTITION BY DEFAULT
        TABLE t1 {id, name} = (11, "new3"), (21, "new4")
        PER PARTITION (x) OF t {
          FOR r IN x
          CALL show_functions("ALL") RETURN name
        }
      }
      """
    Then an Error should be raised: "[NS253]: Invalid PER PARTITION statement: Procedure `dbms.show_functions` is not allowed in PER PARTITION body"
