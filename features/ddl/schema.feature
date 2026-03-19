# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: schema

  Scenario: create and drop schema
    When executing query:
      """
      CREATE SCHEMA /some/regular/path
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /some/regular/path
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE SCHEMA /some/regular/path/x
      """
    Then an Error should be raised: "[NR103]: Invalid schema path: The schema `/some/regular/path/x` conflicts with existing schema `/some/regular/path`"
    When executing raw query:
      """
      SHOW SCHEMAS
      """
    Then the result should contain:
      | path                 | owner  |
      | "/default_schema"    | "root" |
      | "/some/regular/path" | "root" |
    When executing query:
      """
      CREATE SCHEMA /some/regular/path
      """
    Then an Error should be raised: "[NC101]: Catalog schema already exists: `/some/regular/path`"
    When executing query:
      """
      CREATE SCHEMA /path/shouldnot/ends/with_slash/
      """
    Then an Error should be raised: "[42001]: syntax error near `/`"
    When executing query:
      """
      CREATE SCHEMA /path/shouldnot/have/ /in/the/path
      """
    Then an Error should be raised: "42001]: syntax error near `/`"
    # The following query will create a schema with path `/path/shouldnot/have`
    # Note: The `//in/the/path` part is parsed as a comment in the parser
    When executing query:
      """
      CREATE SCHEMA /path/shouldnot/have//in/the/path
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE SCHEMA /path/shouldnot/have/./in/the/path
      """
    Then an Error should be raised: "[42001]: syntax error near `.`"
    When executing query:
      """
      CREATE SCHEMA /path/shouldnot/have/../in/the/path
      """
    Then an Error should be raised: "[42001]: syntax error near `..`"
    When executing query:
      """
      CREATE SCHEMA ./path
      """
    Then an Error should be raised: "[42001]: syntax error near `/`"
    # ../path is a legal schema path
    When executing query:
      """
      CREATE SCHEMA ../path2
      """
    Then the execution should be successful
    When executing query:
      """
      DROP SCHEMA /some/regular/path
      """
    Then the execution should be successful
    When executing raw query:
      """
      SHOW SCHEMAS
      """
    Then the result should contain:
      | path              | owner  |
      | "/default_schema" | "root" |
    When executing query:
      """
      DROP SCHEMA /some/regular/path
      """
    Then an Error should be raised: "[NC002]: Catalog schema not found: `/some/regular/path`"
    When executing query:
      """
      DROP SCHEMA IF EXISTS /some/regular/path
      """
    Then the execution should be successful

  Scenario: drop a not empty schema
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /another/schema2
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /another/schema2
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS another_ldbc_type AS {
        NODE TYPE node_type ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow {day INT}]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP SCHEMA /another/schema2
      """
    Then an Error should be raised: "[NR101]: Can not drop schema `/another/schema2` while still having graph types or graph"
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS another_ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      DROP SCHEMA IF EXISTS /another/schema2
      """
    Then the execution should be successful
    And close the current session

  Scenario: drop current schema
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /yet/another/`schema`
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /yet/another/`schema`
      """
    Then the execution should be successful
    When executing query:
      """
      DROP SCHEMA IF EXISTS /yet/another/"schema"
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW SERVICES
      """
    Then the execution should be successful
    And close the current session

  Scenario: export schema
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS export_type AS {
        NODE player (LABEL player {id INT PRIMARY KEY, age INT, v1 VECTOR<3, float>}),
        EDGE follow (player)-[LABEL follow {s1 STRING, v2 VECTOR<3, float>}]->(player)
      }
      """
    Then the execution should be successful
    And graph type "export_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS export_test TYPED export_type
      """
    Then the execution should be successful
    And graph "export_test" should be ready to use
    When executing query:
      """
      USE export_test CREATE INDEX IF NOT EXISTS i_player_age ON NODE player(age)
      """
    Then the execution should be successful
    When executing query:
      """
      USE export_test CREATE INDEX IF NOT EXISTS i_follow_s1 ON EDGE follow(s1)
      """
    Then the execution should be successful
    When executing query:
      """
      USE export_test CREATE VECTOR INDEX IF NOT EXISTS i_ann_player_v1 ON NODE player::v1 OPTIONS {dim: 3}
      """
    Then the execution should be successful
    When executing query:
      """
      USE export_test CREATE VECTOR INDEX IF NOT EXISTS i_ann_follow_v2 ON EDGE follow::v2 OPTIONS {dim: 3}
      """
    Then the execution should be successful
    When executing query:
      """
      EXPORT SCHEMA
      """
    Then the result should contain:
      | entity            | statement                                                                                                                                                                                                                                                                                                                          |
      | "GraphType"       | "CREATE GRAPH TYPE IF NOT EXISTS `export_type` AS {\n  NODE TYPE `player` (LABEL `player`{`id` INT64 NOT NULL, `age` INT64 DEFAULT NULL, `v1` VECTOR<3, FLOAT> DEFAULT NULL, PRIMARY KEY (`id`)}),\n  EDGE TYPE `follow` (`player`)-[LABEL `follow`{`s1` STRING DEFAULT NULL, `v2` VECTOR<3, FLOAT> DEFAULT NULL}]->(`player`)\n}" |
      | "Graph"           | "CREATE GRAPH IF NOT EXISTS `export_test` TYPED `export_type`"                                                                                                                                                                                                                                                                     |
      | "NodeIndex"       | "USE `export_test` CREATE INDEX IF NOT EXISTS `i_player_age` ON NODE `player`(age)"                                                                                                                                                                                                                                                |
      | "EdgeIndex"       | "USE `export_test` CREATE INDEX IF NOT EXISTS `i_follow_s1` ON EDGE `follow`(s1)"                                                                                                                                                                                                                                                  |
      | "NodeVectorIndex" | "USE `export_test` CREATE VECTOR INDEX IF NOT EXISTS `i_ann_player_v1` ON NODE `player`::v1 OPTIONS {dim: 3, type: IVF, metric: L2}"                                                                                                                                                                                               |
      | "EdgeVectorIndex" | "USE `export_test` CREATE VECTOR INDEX IF NOT EXISTS `i_ann_follow_v2` ON EDGE `follow`::v2 OPTIONS {dim: 3, type: IVF, metric: L2}"                                                                                                                                                                                               |
    When executing query:
      """
      EXPORT SCHEMA /default_schema
      """
    Then the result should contain:
      | entity            | statement                                                                                                                                                                                                                                                                                                                          |
      | "GraphType"       | "CREATE GRAPH TYPE IF NOT EXISTS `export_type` AS {\n  NODE TYPE `player` (LABEL `player`{`id` INT64 NOT NULL, `age` INT64 DEFAULT NULL, `v1` VECTOR<3, FLOAT> DEFAULT NULL, PRIMARY KEY (`id`)}),\n  EDGE TYPE `follow` (`player`)-[LABEL `follow`{`s1` STRING DEFAULT NULL, `v2` VECTOR<3, FLOAT> DEFAULT NULL}]->(`player`)\n}" |
      | "Graph"           | "CREATE GRAPH IF NOT EXISTS `export_test` TYPED `export_type`"                                                                                                                                                                                                                                                                     |
      | "NodeIndex"       | "USE `export_test` CREATE INDEX IF NOT EXISTS `i_player_age` ON NODE `player`(age)"                                                                                                                                                                                                                                                |
      | "EdgeIndex"       | "USE `export_test` CREATE INDEX IF NOT EXISTS `i_follow_s1` ON EDGE `follow`(s1)"                                                                                                                                                                                                                                                  |
      | "NodeVectorIndex" | "USE `export_test` CREATE VECTOR INDEX IF NOT EXISTS `i_ann_player_v1` ON NODE `player`::v1 OPTIONS {dim: 3, type: IVF, metric: L2}"                                                                                                                                                                                               |
      | "EdgeVectorIndex" | "USE `export_test` CREATE VECTOR INDEX IF NOT EXISTS `i_ann_follow_v2` ON EDGE `follow`::v2 OPTIONS {dim: 3, type: IVF, metric: L2}"                                                                                                                                                                                               |
    When executing query:
      """
      CALL export_schema("/default_schema") RETURN *
      """
    Then the result should contain:
      | entity            | statement                                                                                                                                                                                                                                                                                                                          |
      | "GraphType"       | "CREATE GRAPH TYPE IF NOT EXISTS `export_type` AS {\n  NODE TYPE `player` (LABEL `player`{`id` INT64 NOT NULL, `age` INT64 DEFAULT NULL, `v1` VECTOR<3, FLOAT> DEFAULT NULL, PRIMARY KEY (`id`)}),\n  EDGE TYPE `follow` (`player`)-[LABEL `follow`{`s1` STRING DEFAULT NULL, `v2` VECTOR<3, FLOAT> DEFAULT NULL}]->(`player`)\n}" |
      | "Graph"           | "CREATE GRAPH IF NOT EXISTS `export_test` TYPED `export_type`"                                                                                                                                                                                                                                                                     |
      | "NodeIndex"       | "USE `export_test` CREATE INDEX IF NOT EXISTS `i_player_age` ON NODE `player`(age)"                                                                                                                                                                                                                                                |
      | "EdgeIndex"       | "USE `export_test` CREATE INDEX IF NOT EXISTS `i_follow_s1` ON EDGE `follow`(s1)"                                                                                                                                                                                                                                                  |
      | "NodeVectorIndex" | "USE `export_test` CREATE VECTOR INDEX IF NOT EXISTS `i_ann_player_v1` ON NODE `player`::v1 OPTIONS {dim: 3, type: IVF, metric: L2}"                                                                                                                                                                                               |
      | "EdgeVectorIndex" | "USE `export_test` CREATE VECTOR INDEX IF NOT EXISTS `i_ann_follow_v2` ON EDGE `follow`::v2 OPTIONS {dim: 3, type: IVF, metric: L2}"                                                                                                                                                                                               |
    And drop the graph "export_test"
    And drop the graph type "export_type"

  Scenario: create preserved schemas
    When executing query:
      """
      CREATE SCHEMA /default_schema
      """
    Then an Error should be raised: "[NR105]: Schema path with prefix `/default_schema` is not allowed"
    When executing query:
      """
      CREATE SCHEMA /default_schema/test
      """
    Then an Error should be raised: "[NR105]: Schema path with prefix `/default_schema` is not allowed"
    When executing query:
      """
      CREATE SCHEMA /tmp_schema
      """
    Then an Error should be raised: "[NS000]: Semantic error: The schema `/tmp_schema` is reserved and cannot be used"
    When executing query:
      """
      CREATE SCHEMA /tmp_schema/test
      """
    Then an Error should be raised: "[NS000]: Semantic error: The schema `/tmp_schema` is reserved and cannot be used"

  Scenario: drop preserved schemas
    When executing query:
      """
      DROP SCHEMA /default_schema
      """
    Then an Error should be raised: "[NR105]: Schema path with prefix `/default_schema` is not allowed"
    When executing query:
      """
      DROP SCHEMA /tmp_schema
      """
    Then an Error should be raised: "[NS000]: Semantic error: The schema `/tmp_schema` is reserved and cannot be used"

  Scenario: schema path and object name
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA /schema_test_1024/x
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE SCHEMA /schema_test_1024/y
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /schema_test_1024/x
      """
    Then the execution should be successful
    When executing query:
      """
      USE /default_schema/ldbc MATCH (v) RETURN count(v) AS c
      NEXT
      USE #analytic_ldbc MATCH (v) RETURN count(v) + c AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 68  |
    When executing query:
      """
      CREATE GRAPH ldbc_x TYPED /default_schema/ldbc_type
      """
    Then an Error should be raised: "[NS000]: Semantic error: Graph type `ldbc_type` must be in the same schema `/schema_test_1024/x` as graph `ldbc_x`"
    When executing query:
      """
      CREATE GRAPH TYPE session_test_graph_type AS {
        NODE Target ({id INT, name STRING, PRIMARY key(id)}),
        EDGE Depend (Target) -[{}]-> (Target)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH session_test_graph TYPED session_test_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /schema_test_1024/y
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH /schema_test_1024/x/session_test_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE /schema_test_1024/y/../x/session_test_graph_type
      """
    Then an Error should be raised: "[42001]: syntax error near `..`"
    When executing query:
      """
      DROP GRAPH TYPE ../x/session_test_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMP GRAPH /schema_test_1024/#ldbc AS COPY OF /default_schema/ldbc
      """
    Then an Error should be raised: "[42001]: syntax error near `/`"
    When executing query:
      """
      USE /default_schema/ldbc CREATE INDEX /schema_test_1024/index_1 ON NODE Person(lastName)
      """
    Then an Error should be raised: "[42001]: syntax error near `/`"
    When executing query:
      """
      USE /default_schema/ldbc DROP INDEX /schema_test_1024/index_1
      """
    Then an Error should be raised: "[42001]: syntax error near `/`"
    When executing query:
      """
      RENAME GRAPH /default_schema/ldbc TO /schema_test_1024/x/ldbc
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Cannot change graph's schema"
    When executing query:
      """
      RENAME GRAPH TYPE /default_schema/ldbc_type TO /schema_test_1024/x/ldbc_type
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Cannot change graph type's schema"
    And close the current session

  Scenario: vesoft/nebula-ng#9090
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA /test_schema_9090/a/b/c/d
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE SCHEMA ""
      """
    Then an Error should be raised: "[42001]: empty identifier near `\"\"`"
    When executing query:
      """
      CREATE SCHEMA /test_schema_9090/a/b
      """
    Then an Error should be raised: "[NR103]: Invalid schema path: The schema `/test_schema_9090/a/b` conflicts with existing schema `/test_schema_9090/a/b/c/d`"
    When executing query:
      """
      SESSION SET SCHEMA /test_schema_9090/a/b/c/d
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA ../d
      """
    Then the execution should be successful
    When executing query:
      """
      EXPORT SCHEMA ../d
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE SCHEMA ..
      """
    Then an Error should be raised: "[NR103]: Invalid schema path: schema path must not end with '/': `/test_schema_9090/a/b/c/`"
    When executing query:
      """
      CREATE SCHEMA ../..
      """
    Then an Error should be raised: "[NR103]: Invalid schema path: schema path must not end with '/': `/test_schema_9090/a/b/`"
    When executing query:
      """
      CREATE SCHEMA ../d/x
      """
    Then an Error should be raised: "[NR103]: Invalid schema path: The schema `/test_schema_9090/a/b/c/d/x` conflicts with existing schema `/test_schema_9090/a/b/c/d`"
    When executing query:
      """
      CREATE SCHEMA ../../x
      """
    Then the execution should be successful
    When executing query:
      """
      DROP SCHEMA ../../x
      """
    Then the execution should be successful
    When executing query:
      """
      DROP SCHEMA /test_schema_9090/a/b/c/d
      """
    Then the execution should be successful
    And close the current session
