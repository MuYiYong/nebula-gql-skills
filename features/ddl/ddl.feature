# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: ddl

  Scenario: show create graph or graph type
    When executing query:
      """
      SHOW CREATE GRAPH ldbc
      """
    Then the result should be, in any order:
      | graph_name | create_graph_statement                                |
      | "ldbc"     | "CREATE GRAPH IF NOT EXISTS `ldbc` TYPED `ldbc_type`" |
    When executing query:
      """
      SHOW CREATE GRAPH #analytic_ldbc
      """
    Then the result should be, in any order:
      | graph_name       | create_graph_statement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
      | "#analytic_ldbc" | "CREATE TEMPORARY GRAPH IF NOT EXISTS `#analytic_ldbc` TYPED {\n  NODE TYPE `Place` (LABELS `City`&`Continent`&`Country`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, `kind` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Forum` (LABEL `Forum`{`id` INT64 NOT NULL, `title` STRING DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Comment` (LABELS `Comment`&`Message`{`id` INT64 NOT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `content` STRING DEFAULT NULL, `extent` INT8 DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Person` (LABEL `Person`{`id` INT64 NOT NULL, `firstName` STRING DEFAULT NULL, `lastName` STRING DEFAULT NULL, `gender` STRING DEFAULT NULL, `birthday` DATE DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `vec` VECTOR<3, FLOAT> DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Tag` (LABEL `Tag`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Post` (LABELS `Message`&`Post`{`id` INT64 NOT NULL, `imageFile` STRING DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `content` STRING DEFAULT NULL, `extent` INT8 DEFAULT NULL, `language` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `TagClass` (LABEL `TagClass`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Organisation` (LABELS `Company`&`University`{`id` INT64 NOT NULL, `kind` STRING DEFAULT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  EDGE TYPE `HAS_INTEREST` (`Person`)-[LABEL `HAS_INTEREST`{}]->(`Tag`),\n  EDGE TYPE `WORK_AT` (`Person`)-[LABEL `WORK_AT`{`workFrom` INT64 DEFAULT NULL}]->(`Organisation`),\n  EDGE TYPE `IS_LOCATED_IN_1` (`Person`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_2` (`Comment`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_3` (`Post`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_4` (`Organisation`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_PART_OF` (`Place`)-[LABEL `IS_PART_OF`{}]->(`Place`),\n  EDGE TYPE `HAS_TYPE` (`Tag`)-[LABEL `HAS_TYPE`{}]->(`TagClass`),\n  EDGE TYPE `REPLY_OF_1` (`Comment`)-[LABEL `REPLY_OF`{}]->(`Post`),\n  EDGE TYPE `REPLY_OF_2` (`Comment`)-[LABEL `REPLY_OF`{}]->(`Comment`),\n  EDGE TYPE `KNOWS` (`Person`)-[LABEL `KNOWS`{`creationDate` LOCAL DATETIME DEFAULT NULL, `vec` VECTOR<3, FLOAT> DEFAULT NULL}]->(`Person`),\n  EDGE TYPE `FOLLOWS` (`Person`)-[LABEL `FOLLOWS`{`src` INT64 DEFAULT NULL, `dst` INT64 DEFAULT NULL}]->(`Person`),\n  EDGE TYPE `CONTAINER_OF` (`Forum`)-[LABEL `CONTAINER_OF`{}]->(`Post`),\n  EDGE TYPE `HAS_MEMBER` (`Forum`)-[LABEL `HAS_MEMBER`{}]->(`Person`),\n  EDGE TYPE `HAS_MODERATOR` (`Forum`)-[LABEL `HAS_MODERATOR`{}]->(`Person`),\n  EDGE TYPE `STUDY_AT` (`Person`)-[LABEL `STUDY_AT`{`classYear` INT64 DEFAULT NULL}]->(`Organisation`),\n  EDGE TYPE `IS_SUBCLASS_OF` (`TagClass`)-[LABEL `IS_SUBCLASS_OF`{}]->(`TagClass`),\n  EDGE TYPE `HAS_TAG_1` (`Forum`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_TAG_2` (`Post`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_TAG_3` (`Comment`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_CREATOR_1` (`Post`)-[LABEL `HAS_CREATOR`{}]->(`Person`),\n  EDGE TYPE `HAS_CREATOR_2` (`Comment`)-[LABEL `HAS_CREATOR`{}]->(`Person`),\n  EDGE TYPE `LIKES_1` (`Person`)-[LABEL `LIKES`{`creationDate` LOCAL DATETIME DEFAULT NULL}]->(`Post`),\n  EDGE TYPE `LIKES_2` (`Person`)-[LABEL `LIKES`{`creationDate` LOCAL DATETIME DEFAULT NULL}]->(`Comment`)\n} OPTIONS {immutable: false}" |
    When executing analytic query:
      """
      SHOW CREATE GRAPH #analytic_ldbc
      """
    Then the result should be, in any order:
      | graph_name       | create_graph_statement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
      | "#analytic_ldbc" | "CREATE TEMPORARY GRAPH IF NOT EXISTS `#analytic_ldbc` TYPED {\n  NODE TYPE `Place` (LABELS `City`&`Continent`&`Country`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, `kind` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Forum` (LABEL `Forum`{`id` INT64 NOT NULL, `title` STRING DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Comment` (LABELS `Comment`&`Message`{`id` INT64 NOT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `content` STRING DEFAULT NULL, `extent` INT8 DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Person` (LABEL `Person`{`id` INT64 NOT NULL, `firstName` STRING DEFAULT NULL, `lastName` STRING DEFAULT NULL, `gender` STRING DEFAULT NULL, `birthday` DATE DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `vec` VECTOR<3, FLOAT> DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Tag` (LABEL `Tag`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Post` (LABELS `Message`&`Post`{`id` INT64 NOT NULL, `imageFile` STRING DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `content` STRING DEFAULT NULL, `extent` INT8 DEFAULT NULL, `language` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `TagClass` (LABEL `TagClass`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Organisation` (LABELS `Company`&`University`{`id` INT64 NOT NULL, `kind` STRING DEFAULT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  EDGE TYPE `HAS_INTEREST` (`Person`)-[LABEL `HAS_INTEREST`{}]->(`Tag`),\n  EDGE TYPE `WORK_AT` (`Person`)-[LABEL `WORK_AT`{`workFrom` INT64 DEFAULT NULL}]->(`Organisation`),\n  EDGE TYPE `IS_LOCATED_IN_1` (`Person`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_2` (`Comment`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_3` (`Post`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_4` (`Organisation`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_PART_OF` (`Place`)-[LABEL `IS_PART_OF`{}]->(`Place`),\n  EDGE TYPE `HAS_TYPE` (`Tag`)-[LABEL `HAS_TYPE`{}]->(`TagClass`),\n  EDGE TYPE `REPLY_OF_1` (`Comment`)-[LABEL `REPLY_OF`{}]->(`Post`),\n  EDGE TYPE `REPLY_OF_2` (`Comment`)-[LABEL `REPLY_OF`{}]->(`Comment`),\n  EDGE TYPE `KNOWS` (`Person`)-[LABEL `KNOWS`{`creationDate` LOCAL DATETIME DEFAULT NULL, `vec` VECTOR<3, FLOAT> DEFAULT NULL}]->(`Person`),\n  EDGE TYPE `FOLLOWS` (`Person`)-[LABEL `FOLLOWS`{`src` INT64 DEFAULT NULL, `dst` INT64 DEFAULT NULL}]->(`Person`),\n  EDGE TYPE `CONTAINER_OF` (`Forum`)-[LABEL `CONTAINER_OF`{}]->(`Post`),\n  EDGE TYPE `HAS_MEMBER` (`Forum`)-[LABEL `HAS_MEMBER`{}]->(`Person`),\n  EDGE TYPE `HAS_MODERATOR` (`Forum`)-[LABEL `HAS_MODERATOR`{}]->(`Person`),\n  EDGE TYPE `STUDY_AT` (`Person`)-[LABEL `STUDY_AT`{`classYear` INT64 DEFAULT NULL}]->(`Organisation`),\n  EDGE TYPE `IS_SUBCLASS_OF` (`TagClass`)-[LABEL `IS_SUBCLASS_OF`{}]->(`TagClass`),\n  EDGE TYPE `HAS_TAG_1` (`Forum`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_TAG_2` (`Post`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_TAG_3` (`Comment`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_CREATOR_1` (`Post`)-[LABEL `HAS_CREATOR`{}]->(`Person`),\n  EDGE TYPE `HAS_CREATOR_2` (`Comment`)-[LABEL `HAS_CREATOR`{}]->(`Person`),\n  EDGE TYPE `LIKES_1` (`Person`)-[LABEL `LIKES`{`creationDate` LOCAL DATETIME DEFAULT NULL}]->(`Post`),\n  EDGE TYPE `LIKES_2` (`Person`)-[LABEL `LIKES`{`creationDate` LOCAL DATETIME DEFAULT NULL}]->(`Comment`)\n} PARTITION BY SRC OPTIONS {immutable: true}" |
    When executing query:
      """
      SHOW CREATE GRAPH TYPE ldbc_type
      """
    Then the result should be, in any order:
      | graph_type_name | create_graph_type_statement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
      | "ldbc_type"     | "CREATE GRAPH TYPE IF NOT EXISTS `ldbc_type` AS {\n  NODE TYPE `Place` (LABELS `City`&`Continent`&`Country`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, `kind` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Forum` (LABEL `Forum`{`id` INT64 NOT NULL, `title` STRING DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Comment` (LABELS `Comment`&`Message`{`id` INT64 NOT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `content` STRING DEFAULT NULL, `extent` INT8 DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Person` (LABEL `Person`{`id` INT64 NOT NULL, `firstName` STRING DEFAULT NULL, `lastName` STRING DEFAULT NULL, `gender` STRING DEFAULT NULL, `birthday` DATE DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `vec` VECTOR<3, FLOAT> DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Tag` (LABEL `Tag`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Post` (LABELS `Message`&`Post`{`id` INT64 NOT NULL, `imageFile` STRING DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `content` STRING DEFAULT NULL, `extent` INT8 DEFAULT NULL, `language` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `TagClass` (LABEL `TagClass`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Organisation` (LABELS `Company`&`University`{`id` INT64 NOT NULL, `kind` STRING DEFAULT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  EDGE TYPE `HAS_INTEREST` (`Person`)-[LABEL `HAS_INTEREST`{}]->(`Tag`),\n  EDGE TYPE `WORK_AT` (`Person`)-[LABEL `WORK_AT`{`workFrom` INT64 DEFAULT NULL}]->(`Organisation`),\n  EDGE TYPE `IS_LOCATED_IN_1` (`Person`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_2` (`Comment`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_3` (`Post`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_4` (`Organisation`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_PART_OF` (`Place`)-[LABEL `IS_PART_OF`{}]->(`Place`),\n  EDGE TYPE `HAS_TYPE` (`Tag`)-[LABEL `HAS_TYPE`{}]->(`TagClass`),\n  EDGE TYPE `REPLY_OF_1` (`Comment`)-[LABEL `REPLY_OF`{}]->(`Post`),\n  EDGE TYPE `REPLY_OF_2` (`Comment`)-[LABEL `REPLY_OF`{}]->(`Comment`),\n  EDGE TYPE `KNOWS` (`Person`)-[LABEL `KNOWS`{`creationDate` LOCAL DATETIME DEFAULT NULL, `vec` VECTOR<3, FLOAT> DEFAULT NULL}]->(`Person`),\n  EDGE TYPE `FOLLOWS` (`Person`)-[LABEL `FOLLOWS`{`src` INT64 DEFAULT NULL, `dst` INT64 DEFAULT NULL}]->(`Person`),\n  EDGE TYPE `CONTAINER_OF` (`Forum`)-[LABEL `CONTAINER_OF`{}]->(`Post`),\n  EDGE TYPE `HAS_MEMBER` (`Forum`)-[LABEL `HAS_MEMBER`{}]->(`Person`),\n  EDGE TYPE `HAS_MODERATOR` (`Forum`)-[LABEL `HAS_MODERATOR`{}]->(`Person`),\n  EDGE TYPE `STUDY_AT` (`Person`)-[LABEL `STUDY_AT`{`classYear` INT64 DEFAULT NULL}]->(`Organisation`),\n  EDGE TYPE `IS_SUBCLASS_OF` (`TagClass`)-[LABEL `IS_SUBCLASS_OF`{}]->(`TagClass`),\n  EDGE TYPE `HAS_TAG_1` (`Forum`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_TAG_2` (`Post`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_TAG_3` (`Comment`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_CREATOR_1` (`Post`)-[LABEL `HAS_CREATOR`{}]->(`Person`),\n  EDGE TYPE `HAS_CREATOR_2` (`Comment`)-[LABEL `HAS_CREATOR`{}]->(`Person`),\n  EDGE TYPE `LIKES_1` (`Person`)-[LABEL `LIKES`{`creationDate` LOCAL DATETIME DEFAULT NULL}]->(`Post`),\n  EDGE TYPE `LIKES_2` (`Person`)-[LABEL `LIKES`{`creationDate` LOCAL DATETIME DEFAULT NULL}]->(`Comment`)\n}" |
    When executing query:
      """
      SHOW CREATE GRAPH xxx
      """
    Then an Error should be raised: "[01G03]: Graph `xxx` not found in schema `/default_schema`"
    When executing query:
      """
      SHOW CREATE GRAPH TYPE xxx_type
      """
    Then an Error should be raised: "[01G04]: Graph type not found: `xxx_type`"

  Scenario: create graph type drop graph and drop graph type
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type AS {
        NODE TYPE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, vec1 VECTOR<3, float>, vec2 VECTOR<128, float>}),
        EDGE TYPE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT, vec VECTOR<128, float>}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type2 {
        NODE TYPE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, PRIMARY KEY (id)}),
        EDGE TYPE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[42N38]: Invalid syntax, multiple PRIMARY KEY options for NODE TYPE `node_type_player` are not allowed"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type3 AS {
        NODE TYPE node_type_player( LABEL player {id INT, name STRING, PRIMARY KEY (id2)}),
        EDGE TYPE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[42N03]: Invalid syntax, PRIMARY KEY `id2` not found in properties list"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type4 AS {
        NODE TYPE node_type_player( LABEL player {id INT, vec VECTOR<3, float>, PRIMARY KEY (vec)}),
        EDGE TYPE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[NT005]: Unsupported primary key type of `vec` in node type `node_type_player`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type4 AS {
        NODE TYPE node_type_player( LABEL player {id INT, vec VECTOR<3, float> PRIMARY KEY}),
        EDGE TYPE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[NT005]: Unsupported primary key type of `vec` in node type `node_type_player`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type4 AS {
        NODE TYPE node_type_player( LABEL player {id INT, vec LIST<VECTOR<3, float>> PRIMARY KEY}),
        EDGE TYPE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[42N41]: Invalid syntax, nested VECTOR type property `vec` of `node_type_player` is not allowed"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type4 AS {
        NODE TYPE node_type_player( LABEL player {id INT, PRIMARY KEY (id)}),
        EDGE TYPE edge_type_follow (node_type_player)-[LABEL follow {followness INT, vec VECTOR<3, float> MULTIEDGE KEY}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[NT014]: Unsupported multiple edge key of `vec` in edge type `edge_type_follow`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type4 AS {
        NODE TYPE node_type_player( LABEL player {id INT, PRIMARY KEY (id)}),
        EDGE TYPE edge_type_follow (node_type_player)-[LABEL follow {followness INT, vec VECTOR<3, float>, MULTIEDGE KEY (vec)}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[NT014]: Unsupported multiple edge key of `vec` in edge type `edge_type_follow`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type4 AS {
        NODE TYPE node_type_player( LABEL player {id INT, PRIMARY KEY (id)}),
        EDGE TYPE edge_type_follow (node_type_player)-[LABEL follow {followness INT, vec LIST<VECTOR<3, float>>}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[42N41]: Invalid syntax, nested VECTOR type property `vec` of `edge_type_follow` is not allowed"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type AS {
        NODE TYPE node_type_player(LABEL player {id INT, name STRING, PRIMARY KEY(id)})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type AS {
        NODE TYPE node_type_player(LABEL player {id INT PRIMARY KEY, name STRING})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_empty_graph_type AS {}
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE ddl_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS ddl_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE ddl_test_type
      """
    Then an Error should be raised: "[01G04]: Graph type not found: `ddl_test_type`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ddl_test_type AS {
        NODE TYPE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH ddl_test TYPED ddl_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ddl_test TYPED ddl_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ddl_test :: ddl_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ddl_test ddl_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS ddl_test_type
      """
    Then an Error should be raised: "[NR102]: Can not drop graph type `ddl_test_type` that is referenced by graph `ddl_test`"
    When executing query:
      """
      DROP GRAPH IF EXISTS ddl_test
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS ddl_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH ddl_test
      """
    Then an Error should be raised: "[01G03]: Graph `ddl_test` not found in schema `/default_schema`"
    When executing query:
      """
      DROP GRAPH IF EXISTS ddl_test
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE delimited_identifier_test AS {
        NODE TYPE `uint` (:player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type1 (`uint`)-[:follow{followness INT}]->(`uint`),
        NODE TYPE `match` (IS player {id INT, age double, PRIMARY KEY (id)})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE delimited_identifier_test
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS graph_insert_null_datatype as {
        NODE TYPE Place ({id INT,intprop4 INT64,bprpo boolean, name STRING,fprop4 double,dprop1 date,dprop2 local datetime})
      }
      """
    Then an Error should be raised: "[NT002]: Unsupported, node type without primary key: `Place`"
    And drop the graph type "ddl_empty_graph_type"

  Scenario: show create statement
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS to_show_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, prop_1 INT8, prop_2 INT16}),
        NODE node_type_team (LABEL team {id INT, name STRING, PRIMARY KEY(id, name)}),
        EDGE edge_type_follow_1 (node_type_player)-[LABEL follow_1 {followness INT MULTIEDGE KEY, age INT}]->(node_type_player),
        EDGE edge_type_follow_2 (node_type_player)-[LABEL follow_2 {followness INT, age INT, MULTIEDGE KEY()}]->(node_type_player),
        EDGE edge_type_follow_3 (node_type_player)-[LABEL follow_3 {followness INT, age INT, MULTIEDGE KEY(followness, age)}]->(node_type_player),
        EDGE edge_type_follow_4 (node_type_player)-[{MULTIEDGE KEY()}]->(node_type_player),
        EDGE edge_type_follow_5 (node_type_player)-[{}]->(node_type_player),
        EDGE edge_type_follow_6 (node_type_player)<-[{}]-(node_type_team),
        EDGE edge_type_follow_7 (node_type_player)~[{}]~(node_type_team)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CREATE GRAPH TYPE to_show_type
      """
    Then the result should be, in any order:
      | graph_type_name | create_graph_type_statement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
      | "to_show_type"  | "CREATE GRAPH TYPE IF NOT EXISTS `to_show_type` AS {\n  NODE TYPE `node_type_player` (LABEL `player`{`id` INT64 NOT NULL, `prop_1` INT8 DEFAULT NULL, `prop_2` INT16 DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `node_type_team` (LABEL `team`{`id` INT64 NOT NULL, `name` STRING NOT NULL, PRIMARY KEY (`id`,`name`)}),\n  EDGE TYPE `edge_type_follow_1` (`node_type_player`)-[LABEL `follow_1`{`followness` INT64 NOT NULL, `age` INT64 DEFAULT NULL, MULTIEDGE KEY(`followness`)}]->(`node_type_player`),\n  EDGE TYPE `edge_type_follow_2` (`node_type_player`)-[LABEL `follow_2`{`followness` INT64 DEFAULT NULL, `age` INT64 DEFAULT NULL, MULTIEDGE KEY()}]->(`node_type_player`),\n  EDGE TYPE `edge_type_follow_3` (`node_type_player`)-[LABEL `follow_3`{`followness` INT64 NOT NULL, `age` INT64 NOT NULL, MULTIEDGE KEY(`followness`,`age`)}]->(`node_type_player`),\n  EDGE TYPE `edge_type_follow_4` (`node_type_player`)-[{MULTIEDGE KEY()}]->(`node_type_player`),\n  EDGE TYPE `edge_type_follow_5` (`node_type_player`)-[{}]->(`node_type_player`),\n  EDGE TYPE `edge_type_follow_6` (`node_type_team`)-[{}]->(`node_type_player`),\n  EDGE TYPE `edge_type_follow_7` (`node_type_player`)~[{}]~(`node_type_team`)\n}" |
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS to_show_type_1 AS {
        NODE node_type_1 (LABEL label_1 {
          id              INT             PRIMARY KEY,
          prop_string     STRING          DEFAULT "unknown",
          prop_list       LIST<STRING>    DEFAULT LIST ["aaa@bbb.com", "ccc@ddd.org"],
          prop_set        SET<STRING>     DEFAULT SET {"eee@fff.com", "ggg@hhh.org"},
          prop_map        MAP<STRING,STRING> DEFAULT MAP {"name":"Bob"}
        }),
        NODE node_type_2 (LABEL label_2 {
          id              INT             PRIMARY KEY,
          prop_date_1     DATE            DEFAULT DATE(),
          prop_date_2     DATE            DEFAULT DATE "2000-01-01",
          prop_date_3     DATE            DEFAULT DATE("2000-01-01")
        }),
        NODE node_type_3 (LABEL label_3 {
          id              INT             PRIMARY KEY,
          prop_ltime_1    LOCAL TIME      DEFAULT LOCAL_TIME(),
          prop_ltime_2    LOCAL TIME      DEFAULT TIME "05:06:07.0890",
          prop_ltime_3    LOCAL TIME      DEFAULT LOCAL_TIME("05:06:07.0890")
        }),
        NODE node_type_4 (LABEL label_4 {
          id              INT             PRIMARY KEY,
          prop_ztime_1    ZONED TIME      DEFAULT ZONED_TIME(),
          prop_ztime_2    ZONED TIME      DEFAULT TIME "10:25:00+0800",
          prop_ztime_3    ZONED TIME      DEFAULT ZONED_TIME("10:25:00+0800")
        }),
        NODE node_type_5 (LABEL label_5 {
          id              INT             PRIMARY KEY,
          prop_ldtime_1   LOCAL DATETIME  DEFAULT LOCAL_DATETIME(),
          prop_ldtime_2   LOCAL DATETIME  DEFAULT DATETIME "2012-03-04T05:06:07.0890",
          prop_ldtime_3   LOCAL DATETIME  DEFAULT LOCAL_DATETIME("2012-03-04T05:06:07.0890")
        }),
        NODE node_type_6 (LABEL label_6 {
          id              INT             PRIMARY KEY,
          prop_zdtime_1   ZONED DATETIME  DEFAULT ZONED_DATETIME(),
          prop_zdtime_2   ZONED DATETIME  DEFAULT DATETIME "2012-03-04T05:06:07 -0200",
          prop_zdtime_3   ZONED DATETIME  DEFAULT ZONED_DATETIME("2012-03-04T05:06:07 -0200")
        })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CREATE GRAPH TYPE to_show_type_1
      """
    Then the result should be, in any order:
      | graph_type_name  | create_graph_type_statement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
      | "to_show_type_1" | "CREATE GRAPH TYPE IF NOT EXISTS `to_show_type_1` AS {\n  NODE TYPE `node_type_1` (LABEL `label_1`{`id` INT64 NOT NULL, `prop_string` STRING DEFAULT \"unknown\", `prop_list` LIST<STRING> DEFAULT LIST[\"aaa@bbb.com\", \"ccc@ddd.org\"], `prop_set` SET<STRING> DEFAULT SET{\"eee@fff.com\", \"ggg@hhh.org\"}, `prop_map` MAP<STRING,STRING> DEFAULT MAP{\"name\": \"Bob\"}, PRIMARY KEY (`id`)}),\n  NODE TYPE `node_type_2` (LABEL `label_2`{`id` INT64 NOT NULL, `prop_date_1` DATE DEFAULT date(), `prop_date_2` DATE DEFAULT DATE \"2000-01-01\", `prop_date_3` DATE DEFAULT date(\"2000-01-01\", \"%Y-%m-%d\"), PRIMARY KEY (`id`)}),\n  NODE TYPE `node_type_3` (LABEL `label_3`{`id` INT64 NOT NULL, `prop_ltime_1` LOCAL TIME DEFAULT local_time(), `prop_ltime_2` LOCAL TIME DEFAULT TIME \"05:06:07.089000\", `prop_ltime_3` LOCAL TIME DEFAULT local_time(\"05:06:07.0890\", \"%H:%M:%S\"), PRIMARY KEY (`id`)}),\n  NODE TYPE `node_type_4` (LABEL `label_4`{`id` INT64 NOT NULL, `prop_ztime_1` ZONED TIME DEFAULT zoned_time(), `prop_ztime_2` ZONED TIME DEFAULT TIME \"02:25:00.000000Z\", `prop_ztime_3` ZONED TIME DEFAULT zoned_time(\"10:25:00+0800\", \"%H:%M:%S %z\"), PRIMARY KEY (`id`)}),\n  NODE TYPE `node_type_5` (LABEL `label_5`{`id` INT64 NOT NULL, `prop_ldtime_1` LOCAL DATETIME DEFAULT local_datetime(), `prop_ldtime_2` LOCAL DATETIME DEFAULT DATETIME \"2012-03-04T05:06:07.089000\", `prop_ldtime_3` LOCAL DATETIME DEFAULT local_datetime(\"2012-03-04T05:06:07.0890\", \"%Y-%m-%dT%H:%M:%S\"), PRIMARY KEY (`id`)}),\n  NODE TYPE `node_type_6` (LABEL `label_6`{`id` INT64 NOT NULL, `prop_zdtime_1` ZONED DATETIME DEFAULT zoned_datetime(), `prop_zdtime_2` ZONED DATETIME DEFAULT DATETIME \"2012-03-04T07:06:07.000000\", `prop_zdtime_3` ZONED DATETIME DEFAULT zoned_datetime(\"2012-03-04T05:06:07 -0200\", \"%Y-%m-%dT%H:%M:%S %z\"), PRIMARY KEY (`id`)})\n}" |
    And drop the graph type "to_show_type"
    And drop the graph type "to_show_type_1"

  Scenario: nullable or not nullable property
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS not_nullable_property_gt AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING NOT NULL, age INT}),
        EDGE TYPE follow (player)-[LABEL follow {followness INT NOT NULL}]->(player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS not_nullable_property_graph TYPED not_nullable_property_gt
      """
    Then the execution should be successful
    And graph "not_nullable_property_graph" should be ready to use
    When executing query:
      """
      USE not_nullable_property_graph INSERT (@player{id: 1, name: "Tim", age: 18}), (@player{id: 2, name: "Jack", age: NULL}), (@player{id: 3, name: "Lee", age: 20})
      """
    Then the execution should be successful
    When executing query:
      """
      USE not_nullable_property_graph INSERT (@player{id: NULL, name: "Tim", age: 22})
      """
    Then an Error should be raised: "[ND008]: Property `id` of type `player` is not nullable"
    When executing query:
      """
      USE not_nullable_property_graph INSERT (@player{id: 4, name: NULL, age: 25})
      """
    Then an Error should be raised: "[ND008]: Property `name` of type `player` is not nullable"
    When executing query:
      """
      USE not_nullable_property_graph
      MATCH (a@player{id:1}),(b@player{id:2})
      INSERT (a)-[@follow{followness: 90}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE not_nullable_property_graph
      MATCH (a@player{id:1}),(b@player{id:2})
      INSERT (a)-[@follow{followness: NULL}]->(b)
      """
    Then an Error should be raised: "[ND008]: Property `followness` of type `follow` is not nullable"
    And drop the graph "not_nullable_property_graph"
    And drop the graph type "not_nullable_property_gt"

  Scenario: at most one ddl statement
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS at_most_one_statement_type AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING NOT NULL, age INT}),
        EDGE TYPE follow (player)-[LABEL follow {followness INT NOT NULL}]->(player)
      }
      NEXT
      CREATE GRAPH  IF NOT EXISTS at_most_one_statement TYPED at_most_one_statement_type
      """
    Then an Error should be raised: "[NT017]: Only one DDL statement is supported in a procedure"
    When executing query:
      """
      CREATE GRAPH at_most_one_ddl TYPED at_most_one_ddl_type
      CREATE SCHEMA /at_most/one_ddl
      """
    Then an Error should be raised: "[NT017]: Only one DDL statement is supported in a procedure"
    When executing query:
      """
      CREATE GRAPH at_most_one_ddl TYPED at_most_one_ddl_type
      IF true THEN {
        CREATE SCHEMA /at_most/one_ddl
      }
      """
    Then an Error should be raised: "[NT017]: Only one DDL statement is supported in a procedure"
    When executing query:
      """
      CREATE PROCEDURE ddl_proc() {
        CREATE SCHEMA /proc/one_ddl
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL ddl_proc() FINISH
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE ddl_proc2() {
        CREATE GRAPH at_most_one_ddl TYPED at_most_one_ddl_type
        CREATE SCHEMA /at_most/one_ddl
      }
      """
    Then an Error should be raised: "[NT017]: Only one DDL statement is supported in a procedure"
    When executing query:
      """
      VALUE i int = 0
      IF i = 0 THEN {
        CREATE GRAPH TYPE IF NOT EXISTS proc_syntax_if_type_a AS {
          NODE TYPE Person ( LABEL Person { id INT PRIMARY KEY, name STRING } )
        }
        CREATE GRAPH IF NOT EXISTS proc_syntax_if_graph_a TYPED proc_syntax_if_type_a
      } ELSE {
        USE proc_syntax_if_graph_a INSERT OR REPLACE (p1@Person{ id:11, name:"_name1" })
      }
      """
    Then an Error should be raised: "[NT017]: Only one DDL statement is supported in a procedure"
    When executing query:
      """
      VALUE i int = 1
      IF i = 0 THEN {
        USE proc_syntax_if_graph_b INSERT OR REPLACE (p1@Person{ id:11, name:"_name1" })
      } ELSE {
        CREATE GRAPH TYPE IF NOT EXISTS proc_syntax_if_type_b AS {
          NODE TYPE Person ( LABEL Person { id INT PRIMARY KEY, name STRING } )
        }
        CREATE GRAPH IF NOT EXISTS proc_syntax_if_graph_b TYPED proc_syntax_if_type_b
      }
      """
    Then an Error should be raised: "[NT017]: Only one DDL statement is supported in a procedure"

  Scenario: duplicate properties
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS expect_fail as {
          NODE TYPE Place ( : label1 {id INT PRIMARY KEY, id STRING})
      }
      """
    Then an Error should be raised: "[42N26]: Invalid syntax, duplicate property names in `Place`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS expect_fail as {
          NODE TYPE Place ( : label1 {id INT PRIMARY KEY, name1 STRING}),
          EDGE TYPE BELONGS (Place)-[:BELONGS {name INT, name STRING}]->(Place)
      }
      """
    Then an Error should be raised: "[42N26]: Invalid syntax, duplicate property names in `BELONGS`"

  Scenario: duplicate pk index properties
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS expect_fail as {
          NODE TYPE Place ( : label1 {id INT, name STRING, primary key (id, id)})
      }
      """
    Then an Error should be raised: "[42N27]: Invalid syntax, duplicate index property names in `Place`"

  Scenario: conflict property type
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS graph_type_nba AS {
        NODE TYPE node_type_player ( LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE}),
        EDGE TYPE edge_type_follow (node_type_player)-[ LABEL follow {name INT, likeness FLOAT64}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[NR111]: Properties with the same name must have the same type. `edge_type_follow.name`: `INT64`, `node_type_player.name`: `STRING`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS graph_type_nba AS {
        NODE TYPE node_type_player ( LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE}),
        NODE TYPE node_type_player2 ( LABEL player2 {id INT PRIMARY KEY, name INT, score FLOAT, gender bool, rate DOUBLE}),
        EDGE TYPE edge_type_follow (node_type_player)-[ LABEL follow {followness INT, likeness FLOAT64}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[NR111]: Properties with the same name must have the same type. `node_type_player2.name`: `INT64`, `node_type_player.name`: `STRING`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS graph_type_nba AS {
        NODE TYPE node_type_player ( LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE}),
        EDGE TYPE edge_type_follow (node_type_player)-[ LABEL follow {followness INT, likeness FLOAT64}]->(node_type_player),
        EDGE TYPE edge_type_follow2 (node_type_player)-[ LABEL follow2 {followness DOUBLE, likeness FLOAT64}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[NR111]: Properties with the same name must have the same type. `edge_type_follow2.followness`: `DOUBLE`, `edge_type_follow.followness`: `INT64`"

  Scenario: conflict property type
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS graph_type_nba AS {
        NODE TYPE node_type_player ( LABEL player {id INT PRIMARY KEY, name STRING, info RECORD {father STRING, mother STRING, age INT}}),
      }
      """
    Then an Error should be raised: "[NT000]: RECORD property is not supported yet"

  Scenario: create graph type failed
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS redefined AS {
        NODE TYPE node_type_player ( LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE}),
        NODE TYPE node_type_player ( LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE})
      }
      """
    Then an Error should be raised: "[NR112]: Element type name `node_type_player` cannot be defined multiple times"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS redefined AS {
        NODE TYPE node_type_1 ( LABEL label {id INT PRIMARY KEY}),
        EDGE TYPE edge_type_2  (node_type_2)-[LABEL elabel]->(node_type_2)
       }
      """
    Then an Error should be raised: "[NC003]: Node type not found: `node_type_2`"

  Scenario: reserved property name
    When executing query:
      """
      CREATE GRAPH TYPE test AS {
        NODE TYPE n1 (LABEL n1{_id string primary key}),
        EDGE TYPE e1 (n1)-[LABEL e1]->(n1)
      }
      """
    Then an Error should be raised: "[NT015]: Property name `_id` of `n1` is reserved"
    When executing query:
      """
      CREATE GRAPH TYPE test AS {
        NODE TYPE n1 (LABEL n1{id string primary key}),
        EDGE TYPE e1 (n1)-[LABEL e1 {_src INT}]->(n1)
      }
      """
    Then an Error should be raised: "[NT015]: Property name `_src` of `e1` is reserved"

  Scenario: alter graph type
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS alter_graph_type AS {
        NODE TYPE node_type_1 (LABELS label1&label2 {prop1 INT PRIMARY KEY, prop2 INT, prop3 DOUBLE, prop4 STRING, prop5 DOUBLE, prop6 INT, prop7 DOUBLE}),
        EDGE TYPE edge_type_1 (node_type_1)-[LABELS elabel1&elabel2 {eprop1 INT, eprop2 INT, eprop3 DOUBLE, eprop4 STRING, eprop5 DOUBLE, eprop6 INT, eprop7 DOUBLE}]->(node_type_1)
      }
      """
    Then the execution should be successful
    And graph type "alter_graph_type" should be ready to use
    When executing query:
      """
      ALTER GRAPH TYPE alter_graph_type {
        ALTER NODE TYPE node_type_1
        ADD PROPERTIES {prop8 INT, prop9 INT}
        DROP PROPERTIES {prop2,prop3}
        RENAME PROPERTIES {prop4 TO rename_prop4, prop5 TO rename_prop5}
        ADD LABELS label3&label4
        DROP LABELS label1&label2,
        ALTER EDGE TYPE edge_type_1
        ADD PROPERTIES {eprop8 INT, eprop9 INT}
        DROP PROPERTIES {eprop2, eprop3}
        RENAME PROPERTIES {eprop4 TO rename_eprop4, eprop5 TO rename_eprop5}
        ADD LABELS elabel3&elabel4
        DROP LABELS elabel1&elabel2
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DESC NODE TYPE node_type_1 OF alter_graph_type
      """
    Then the result should be, in any order:
      | property_name  | data_type | primary_key | nullable | default |
      | "prop1"        | "INT64"   | "Y"         | false    | ""      |
      | "rename_prop4" | "STRING"  | ""          | true     | "NULL"  |
      | "rename_prop5" | "DOUBLE"  | ""          | true     | "NULL"  |
      | "prop6"        | "INT64"   | ""          | true     | "NULL"  |
      | "prop7"        | "DOUBLE"  | ""          | true     | "NULL"  |
      | "prop8"        | "INT64"   | ""          | true     | "NULL"  |
      | "prop9"        | "INT64"   | ""          | true     | "NULL"  |
    When executing query:
      """
      DESC EDGE TYPE edge_type_1 OF alter_graph_type
      """
    Then the result should be, in any order:
      | property_name   | data_type | multi_edge_key | nullable | default |
      | "eprop1"        | "INT64"   | ""             | true     | "NULL"  |
      | "rename_eprop4" | "STRING"  | ""             | true     | "NULL"  |
      | "rename_eprop5" | "DOUBLE"  | ""             | true     | "NULL"  |
      | "eprop6"        | "INT64"   | ""             | true     | "NULL"  |
      | "eprop7"        | "DOUBLE"  | ""             | true     | "NULL"  |
      | "eprop8"        | "INT64"   | ""             | true     | "NULL"  |
      | "eprop9"        | "INT64"   | ""             | true     | "NULL"  |
    When executing query:
      """
      ALTER GRAPH TYPE alter_graph_type {
        ADD NODE TYPE node_type_2 (LABELS label3&label4 {prop1 INT PRIMARY KEY}),
        ADD EDGE TYPE edge_type_2 (node_type_2)-[LABELS elabel1&elabel2 {eprop1 INT}]->(node_type_2)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DESC GRAPH TYPE alter_graph_type
      """
    Then the result should be, in any order:
      | entity_type | type_name     | type_pattern                                 | labels                    | primary_key/multiedge_key | properties                                                                         |
      | "Node"      | "node_type_1" | "(node_type_1)"                              | LIST["label3","label4"]   | LIST["prop1"]             | LIST["prop1","rename_prop4","rename_prop5","prop6","prop7","prop8","prop9"]        |
      | "Node"      | "node_type_2" | "(node_type_2)"                              | LIST["label3","label4"]   | LIST["prop1"]             | LIST["prop1"]                                                                      |
      | "Edge"      | "edge_type_1" | "(node_type_1)-[edge_type_1]->(node_type_1)" | LIST["elabel3","elabel4"] | "Unique"                  | LIST["eprop1","rename_eprop4","rename_eprop5","eprop6","eprop7","eprop8","eprop9"] |
      | "Edge"      | "edge_type_2" | "(node_type_2)-[edge_type_2]->(node_type_2)" | LIST["elabel1","elabel2"] | "Unique"                  | LIST["eprop1"]                                                                     |
    When executing query:
      """
      ALTER GRAPH TYPE alter_graph_type {
        RENAME NODE TYPE node_type_2 TO node_type_3,
        RENAME EDGE TYPE edge_type_2 TO edge_type_3
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DESC GRAPH TYPE alter_graph_type
      """
    Then the result should be, in any order:
      | entity_type | type_name     | type_pattern                                 | labels                    | primary_key/multiedge_key | properties                                                                         |
      | "Node"      | "node_type_1" | "(node_type_1)"                              | LIST["label3","label4"]   | LIST["prop1"]             | LIST["prop1","rename_prop4","rename_prop5","prop6","prop7","prop8","prop9"]        |
      | "Node"      | "node_type_3" | "(node_type_3)"                              | LIST["label3","label4"]   | LIST["prop1"]             | LIST["prop1"]                                                                      |
      | "Edge"      | "edge_type_1" | "(node_type_1)-[edge_type_1]->(node_type_1)" | LIST["elabel3","elabel4"] | "Unique"                  | LIST["eprop1","rename_eprop4","rename_eprop5","eprop6","eprop7","eprop8","eprop9"] |
      | "Edge"      | "edge_type_3" | "(node_type_3)-[edge_type_3]->(node_type_3)" | LIST["elabel1","elabel2"] | "Unique"                  | LIST["eprop1"]                                                                     |
    When executing query:
      """
      ALTER GRAPH TYPE alter_graph_type {
       DROP EDGE TYPE edge_type_3
      }
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE alter_graph_type {
       DROP NODE TYPE node_type_3
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DESC GRAPH TYPE alter_graph_type
      """
    Then the result should be, in any order:
      | entity_type | type_name     | type_pattern                                 | labels                    | primary_key/multiedge_key | properties                                                                         |
      | "Node"      | "node_type_1" | "(node_type_1)"                              | LIST["label3","label4"]   | LIST["prop1"]             | LIST["prop1","rename_prop4","rename_prop5","prop6","prop7","prop8","prop9"]        |
      | "Edge"      | "edge_type_1" | "(node_type_1)-[edge_type_1]->(node_type_1)" | LIST["elabel3","elabel4"] | "Unique"                  | LIST["eprop1","rename_eprop4","rename_eprop5","eprop6","eprop7","eprop8","eprop9"] |
    When executing query:
      """
      RENAME GRAPH TYPE alter_graph_type TO alter_graph_type_new
      """
    Then the execution should be successful
    When executing query:
      """
      DESC GRAPH TYPE alter_graph_type_new
      """
    Then the result should be, in any order:
      | entity_type | type_name     | type_pattern                                 | labels                    | primary_key/multiedge_key | properties                                                                         |
      | "Node"      | "node_type_1" | "(node_type_1)"                              | LIST["label3","label4"]   | LIST["prop1"]             | LIST["prop1","rename_prop4","rename_prop5","prop6","prop7","prop8","prop9"]        |
      | "Edge"      | "edge_type_1" | "(node_type_1)-[edge_type_1]->(node_type_1)" | LIST["elabel3","elabel4"] | "Unique"                  | LIST["eprop1","rename_eprop4","rename_eprop5","eprop6","eprop7","eprop8","eprop9"] |
    When executing query:
      """
      DESC GRAPH TYPE alter_graph_type
      """
    Then an Error should be raised: "[01G04]: Graph type not found: `alter_graph_type`"
    And drop the graph type "alter_graph_type_new"

  Scenario: alter graph type error
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS alter_failed AS {
        NODE TYPE node_type_1 (LABELS label {prop1 INT PRIMARY KEY})
      }
      """
    Then the execution should be successful
    And graph type "alter_failed" should be ready to use
    When executing query:
      """
      ALTER GRAPH TYPE alter_failed {
        ADD NODE TYPE element_type_2 (LABEL label {prop1 INT PRIMARY KEY}),
        ADD EDGE TYPE element_type_2 (node_type_1)-[LABEL elabel]->(node_type_1)
      }
      """
    Then an Error should be raised: "[42N29]: Invalid syntax, `element_type_2` cannot occur more than once in an alter graph type statement"
    When executing query:
      """
      ALTER GRAPH TYPE alter_failed {
        ALTER NODE TYPE node_type_1 ADD PROPERTIES {prop2 INT} DROP PROPERTIES {prop2}
      }
      """
    Then an Error should be raised: "[42N29]: Invalid syntax, `node_type_1.prop2` cannot occur more than once in an alter graph type statement"
    When executing query:
      """
      ALTER GRAPH TYPE alter_failed {
        ALTER NODE TYPE node_type_1 ADD PROPERTIES {prop2 INT PRIMARY KEY}
      }
      """
    Then an Error should be raised: "[42N30]: Invalid syntax, adding PRIMARY KEY or MULTI EDGE KEY `(prop2)` is not allowed"
    When executing query:
      """
      ALTER GRAPH TYPE alter_failed {
        ALTER EDGE TYPE edge_type_1 ADD PROPERTIES {prop2 INT MULTIEDGE KEY}
      }
      """
    Then an Error should be raised: "[42N30]: Invalid syntax, adding PRIMARY KEY or MULTI EDGE KEY `(prop2)` is not allowed"
    When executing query:
      """
      ALTER GRAPH TYPE alter_failed {
         ALTER NODE TYPE node_type_1 ADD PROPERTIES {prop2 INT NOT NULL}
      }
      """
    Then an Error should be raised: "[42N31]: Invalid syntax, add not nullable property node_type_1.prop2 without default value is not allowed"
    When executing query:
      """
      ALTER GRAPH TYPE alter_failed {
        ALTER NODE TYPE node_type_1 ADD LABELS label1 DROP LABELS label1
      }
      """
    Then an Error should be raised: "[42N29]: Invalid syntax, `node_type_1.label1` cannot occur more than once in an alter graph type statement"
    And drop the graph type "alter_failed"

  Scenario: alter graph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS alter_graph_type_rename AS {
        NODE TYPE node_type_1 (LABELS label {prop1 INT PRIMARY KEY})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS rename_graph TYPED alter_graph_type_rename
      """
    Then the execution should be successful
    And graph "rename_graph" should be ready to use
    When executing query:
      """
      RENAME GRAPH rename_graph TO rename_graph_new
      """
    Then the execution should be successful
    When executing query:
      """
      DESC GRAPH rename_graph_new
      """
    Then the result should be, in any order:
      | graph_name         | graph_type_name           |
      | "rename_graph_new" | "alter_graph_type_rename" |
    When executing query:
      """
      DESC GRAPH rename_graph
      """
    Then an Error should be raised: "[01G03]: Graph `rename_graph` not found in schema `/default_schema`"
    And drop the graph "rename_graph_new"
    And drop the graph type "alter_graph_type_rename"

  Scenario: if exists and if not exists alter graph type
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS alter_exists_type AS {
        NODE TYPE node_type_1 (LABEL label {prop1 INT PRIMARY KEY}),
        EDGE TYPE edge_type_1 (node_type_1)-[LABEL elabel {eprop1 INT}]->(node_type_1)
      }
      """
    Then the execution should be successful
    And graph type "alter_exists_type" should be ready to use
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ADD NODE TYPE node_type_1 (LABEL label {prop1 INT PRIMARY KEY})
      }
      """
    Then an Error should be raised: "[NC103]: Node type already exist: `node_type_1`"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ADD EDGE TYPE edge_type_1 (node_type_1)-[LABEL elabel {eprop1 INT}]->(node_type_1)
      }
      """
    Then an Error should be raised: "[NC102]: Edge type already exist: `edge_type_1`"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ADD NODE TYPE IF NOT EXISTS node_type_1 (LABEL label {prop1 INT PRIMARY KEY}),
        ADD EDGE TYPE IF NOT EXISTS edge_type_1 (node_type_1)-[LABEL elabel {eprop1 INT}]->(node_type_1)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        DROP NODE TYPE node_type_2
      }
      """
    Then an Error should be raised: "[NC003]: Node type not found: `node_type_2`"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        DROP EDGE TYPE edge_type_2
      }
      """
    Then an Error should be raised: "[NC004]: Edge type not found: `edge_type_2`"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        DROP NODE TYPE IF EXISTS node_type_2,
        DROP EDGE TYPE IF EXISTS edge_type_2
      }
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER NODE TYPE node_type_1 ADD PROPERTIES {prop1 INT}
      }
      """
    Then an Error should be raised: "[NC106]: Property `node_type_1.prop1` already exists"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER EDGE TYPE edge_type_1 ADD PROPERTIES {eprop1 INT}
      }
      """
    Then an Error should be raised: "[NC106]: Property `edge_type_1.eprop1` already exists"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER NODE TYPE node_type_1 ADD PROPERTIES IF NOT EXISTS {prop1 INT},
        ALTER EDGE TYPE edge_type_1 ADD PROPERTIES IF NOT EXISTS {eprop1 INT}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER NODE TYPE node_type_1 DROP PROPERTIES {prop2}
      }
      """
    Then an Error should be raised: "[NC006]: Property `prop2` of type `node_type_1` not found"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER EDGE TYPE edge_type_1 DROP PROPERTIES {eprop2}
      }
      """
    Then an Error should be raised: "[NC006]: Property `eprop2` of type `edge_type_1` not found"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER NODE TYPE node_type_1 DROP PROPERTIES IF EXISTS {prop2},
        ALTER EDGE TYPE edge_type_1 DROP PROPERTIES IF EXISTS {eprop2}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER NODE TYPE node_type_1 ADD LABELS label
      }
      """
    Then an Error should be raised: "[NC109]: Label already exist: `node_type_1.label`"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER EDGE TYPE edge_type_1 ADD LABELS elabel
      }
      """
    Then an Error should be raised: "[NC109]: Label already exist: `edge_type_1.elabel`"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER NODE TYPE node_type_1 ADD LABELS IF NOT EXISTS label,
        ALTER EDGE TYPE edge_type_1 ADD LABELS IF NOT EXISTS elabel
      }
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER NODE TYPE node_type_1 DROP LABELS label1
      }
      """
    Then an Error should be raised: "[NC011]: Label not found: `node_type_1.label1`"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER EDGE TYPE edge_type_1 DROP LABELS elabel1
      }
      """
    Then an Error should be raised: "[NC011]: Label not found: `edge_type_1.elabel1`"
    When executing query:
      """
      ALTER GRAPH TYPE alter_exists_type {
        ALTER NODE TYPE node_type_1 DROP LABELS IF EXISTS label1,
        ALTER EDGE TYPE edge_type_1 DROP LABELS IF EXISTS elabel1
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DESC GRAPH TYPE alter_exists_type
      """
    Then the result should be, in any order:
      | entity_type | type_name     | type_pattern                                 | labels         | primary_key/multiedge_key | properties     |
      | "Node"      | "node_type_1" | "(node_type_1)"                              | LIST["label"]  | LIST["prop1"]             | LIST["prop1"]  |
      | "Edge"      | "edge_type_1" | "(node_type_1)-[edge_type_1]->(node_type_1)" | LIST["elabel"] | "Unique"                  | LIST["eprop1"] |
    And drop the graph type "alter_exists_type"

  Scenario: primary key default value
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS pk_default_type as {
        NODE node_type_1 (label person{id int ,name string primary key}),
        NODE node_type_2 (label person{id int ,name string, primary key(name)}),
        EDGE edge_type_1 (node_type_1)-[label follow{followness INT MULTIEDGE KEY}]->(node_type_1),
        EDGE edge_type_2 (node_type_1)-[label follow{followness INT,MULTIEDGE KEY(followness)}]->(node_type_1)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS pk_default TYPED pk_default_type
      """
    Then the execution should be successful
    And graph "pk_default" should be ready to use
    When executing query:
      """
      DESC NODE TYPE node_type_1 OF pk_default_type
      """
    Then the result should be, in any order:
      | property_name | data_type | primary_key | nullable | default |
      | "id"          | "INT64"   | ""          | true     | "NULL"  |
      | "name"        | "STRING"  | "Y"         | false    | ""      |
    When executing query:
      """
      DESC NODE TYPE node_type_2 OF pk_default_type
      """
    Then the result should be, in any order:
      | property_name | data_type | primary_key | nullable | default |
      | "id"          | "INT64"   | ""          | true     | "NULL"  |
      | "name"        | "STRING"  | "Y"         | false    | ""      |
    When executing query:
      """
      DESC EDGE TYPE edge_type_1 OF pk_default_type
      """
    Then the result should be, in any order:
      | property_name | data_type | multi_edge_key | nullable | default |
      | "followness"  | "INT64"   | "Y"            | false    | ""      |
    When executing query:
      """
      DESC EDGE TYPE edge_type_2 OF pk_default_type
      """
    Then the result should be, in any order:
      | property_name | data_type | multi_edge_key | nullable | default |
      | "followness"  | "INT64"   | "Y"            | false    | ""      |
    When executing query:
      """
      USE pk_default
      INSERT (@node_type_1{id:1})
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `name` of type `node_type_1` not found"
    When executing query:
      """
      USE pk_default
      INSERT (@node_type_2{id:1})
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `name` of type `node_type_2` not found"
    When executing query:
      """
      USE pk_default
      INSERT (@node_type_1{id:1, name:"name_1"})-[@edge_type_1{}]->(@node_type_1{id:1,name:"name_2"})
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `followness` of type `edge_type_1` not found"
    When executing query:
      """
      USE pk_default
      INSERT (@node_type_1{id:1, name:"name_1"})-[@edge_type_2{}]->(@node_type_1{id:1,name:"name_2"})
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `followness` of type `edge_type_2` not found"
    And drop the graph "pk_default"
    And drop the graph type "pk_default_type"

  Scenario: complex graph name
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS 中文图数据库Type as {
      node Person1( LABELS Person_Label&Person1 {id INT PRIMARY KEY,  age INT64})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS 中文图数据库 TYPED 中文图数据库Type
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS 中文_图数据库 TYPED 中文图数据库Type
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH 圖資料庫 TYPED ldbc_type
      """
    Then the execution should be successful
    And drop the graph "中文图数据库"
    And drop the graph "中文_图数据库"
    And drop the graph "圖資料庫"
    And drop the graph type "中文图数据库Type"

  Scenario: invalid graph name
    When executing query:
      """
      CREATE GRAPH `` TYPED ldbc_type
      """
    Then an Error should be raised: "[42001]: empty identifier"
    When executing query:
      """
      CREATE GRAPH 😀 TYPED ldbc_type
      """
    Then an Error should be raised: "[42001]: illegal (start) character: `😀`"
    When executing query:
      """
      CREATE GRAPH 这个字符串真的很长的这个字符串真的很长的这个字符串真的很长的这个字符串真的很长的这个字符串真的很长的这个字符串真的很长的这个字符这个字符串真的很长的这个字符串真的很长的这个字符串真的很长的这个字符串真的很长的这个字符串真的很长的这个字符串真的很长的这个字符串 TYPED ldbc_type
      """
    Then an Error should be raised: "[42001]: identifier exceeds max length 127"
    When executing query:
      """
      CREATE GRAPH abc😀 TYPED ldbc_type
      """
    Then an Error should be raised: "[42001]: illegal (continue) character: `😀`"
    When executing query:
      """
      CREATE GRAPH 图数据库⛁⛁⛁ TYPED ldbc_type
      """
    Then an Error should be raised: "[42001]: illegal (continue) character: `⛁`"

  Scenario: invalid ddl syntax
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_graph_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING MULTIEDGE KEY, score FLOAT, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT MULTIEDGE KEY, age INT, likeness FLOAT64}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[42N39]: Invalid syntax, option MULTIEDGE KEY cannot used for NODE TYPE `node_type_player`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_graph_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT MULTIEDGE KEY, age INT PRIMARY KEY, likeness FLOAT64}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[42N39]: Invalid syntax, option PRIMARY KEY cannot used for EDGE TYPE `edge_type_follow`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_graph_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE, MULTIEDGE KEY()}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT , age INT, likeness FLOAT64, MULTIEDGE KEY()}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[42N39]: Invalid syntax, option MULTIEDGE KEY cannot used for NODE TYPE `node_type_player`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_graph_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT , age INT, likeness FLOAT64, PRIMARY KEY(age)}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[42N39]: Invalid syntax, option PRIMARY KEY cannot used for EDGE TYPE `edge_type_follow`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_graph_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE})
      }
      """
    Then an Error should be raised: "[42N38]: Invalid syntax, multiple PRIMARY KEY options for PROPERTY TYPE `id` are not allowed"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_graph_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING DEFAULT "xxx" DEFAULT "yyy", score FLOAT, gender bool, rate DOUBLE})
      }
      """
    Then an Error should be raised: "[42N38]: Invalid syntax, multiple DEFAULT VALUE options for PROPERTY TYPE `name` are not allowed"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_graph_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING NOT NULL NULL, score FLOAT, gender bool, rate DOUBLE})
      }
      """
    Then an Error should be raised: "[42N38]: Invalid syntax, multiple NULL/NOT NULL options for PROPERTY TYPE `name` are not allowed"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_graph_type AS {
        NODE person (LABEL person{id int, like_person list<string> PRIMARY KEY})
      }
      """
    Then an Error should be raised: "[NT005]: Unsupported primary key type of `like_person` in node type `person`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_graph_type AS {
        NODE person (LABEL person{id int NULL PRIMARY KEY})
      }
      """
    Then an Error should be raised: "[NT012]: Primary key must be not nullable, node type: `person`, property name: `id`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_graph_type AS {
        NODE person (LABEL person{id int PRIMARY KEY}),
        EDGE follow (person)-[LABEL follow{degree int NULL MULTIEDGE KEY}]->(person)
      }
      """
    Then an Error should be raised: "[NT013]: Multiedge key must be not nullable, edge type: `follow`, property name: `degree`"

  Scenario: edge type without properties
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS edge_type_without_properties AS {
        NODE node_type_1 (LABEL label1 {id INT PRIMARY KEY}),
        EDGE edge_type_1 (node_type_1)-[{}]->(node_type_1),
        EDGE edge_type_2 (node_type_1)-[{MULTIEDGE KEY()}]->(node_type_1)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DESC GRAPH TYPE edge_type_without_properties
      """
    Then the result should be, in any order:
      | entity_type | type_name     | type_pattern                                 | labels          | primary_key/multiedge_key | properties  |
      | "Node"      | "node_type_1" | "(node_type_1)"                              | LIST ["label1"] | LIST ["id"]               | LIST ["id"] |
      | "Edge"      | "edge_type_1" | "(node_type_1)-[edge_type_1]->(node_type_1)" | LIST []         | "Unique"                  | LIST []     |
      | "Edge"      | "edge_type_2" | "(node_type_1)-[edge_type_2]->(node_type_1)" | LIST []         | "Auto"                    | LIST []     |
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_edge_type TYPED edge_type_without_properties
      """
    Then the execution should be successful
    And graph "test_edge_type" should be ready to use
    When executing query:
      """
      USE test_edge_type
      INSERT (a@node_type_1{id:1}),(b@node_type_1{id:2}),
      (a)-[@edge_type_1{}]->(b),
      (a)-[@edge_type_2{}]->(b),
      (a)-[@edge_type_2{}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_edge_type
      MATCH (a)-[e@edge_type_1]->(b)
      return a.id,e,b.id
      """
    Then the result should be, in any order:
      | a.id | e    | b.id |
      | 1    | [{}] | 2    |
    When executing query:
      """
      USE test_edge_type
      MATCH (a)-[e@edge_type_2]->(b)
      return a.id,e,b.id
      """
    Then the result should be, in any order:
      | a.id | e    | b.id |
      | 1    | [{}] | 2    |
      | 1    | [{}] | 2    |
    And drop the graph "test_edge_type"
    And drop the graph type "edge_type_without_properties"

  Scenario: constraint violation
    When executing query:
      """
      ALTER GRAPH TYPE ldbc_type {
        ALTER NODE TYPE Forum
        ADD PROPERTIES {name INT}
      }
      """
    Then an Error should be raised:"[NR111]: Properties with the same name must have the same type. `Forum.name`: `INT64`, `Place.name`: `STRING`"
    When executing query:
      """
      ALTER GRAPH TYPE ldbc_type {
        ADD NODE WORK_AT (:test{id INT PRIMARY KEY})
      }
      """
    Then an Error should be raised:"[NR112]: Element type name `WORK_AT` cannot be defined multiple times"
    When executing query:
      """
      ALTER GRAPH TYPE ldbc_type {
        ADD EDGE Post (Person)-[:test]->(Person)
      }
      """
    Then an Error should be raised:"[NR112]: Element type name `Post` cannot be defined multiple times"
    When executing query:
      """
      ALTER GRAPH TYPE ldbc_type {
        RENAME EDGE KNOWS to Person
      }
      """
    Then an Error should be raised:"[NR112]: Element type name `Person` cannot be defined multiple times"
    When executing query:
      """
      ALTER GRAPH TYPE ldbc_type {
        RENAME NODE Person to KNOWS
      }
      """
    Then an Error should be raised:"[NR112]: Element type name `KNOWS` cannot be defined multiple times"

  Scenario: modify properties
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS modify_properties_type AS {
        NODE TYPE node_type_1 (LABELS label1 {prop1 INT PRIMARY KEY, prop2 INT32, prop3 INT NULL}),
        EDGE TYPE edge_type_1 (node_type_1)-[LABELS elabel1 {eprop1 INT MULTIEDGE KEY,eprop2 INT32}]->(node_type_1)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS modify_properties TYPED modify_properties_type
      """
    Then the execution should be successful
    And graph "modify_properties" should be ready to use
    When executing query:
      """
      ALTER GRAPH TYPE modify_properties_type {
        ALTER NODE node_type_1
        MODIFY PROPERTIES {prop1 DOUBLE}
      }
      """
    Then an Error should be raised: "[NT006]: Modifying the primary key is not supported, node type: `node_type_1`, property name: `prop1`"
    When executing query:
      """
      ALTER GRAPH TYPE modify_properties_type {
        ALTER EDGE edge_type_1
        MODIFY PROPERTIES {eprop1 DOUBLE}
      }
      """
    Then an Error should be raised: "[NT007]: Modifying the multiedge key is not supported, edge type: `edge_type_1`, property name: `eprop1`"
    When executing query:
      """
      ALTER GRAPH TYPE modify_properties_type {
        ALTER NODE node_type_1
        MODIFY PROPERTIES {prop2 INT8}
      }
      """
    Then an Error should be raised: "[NR113]: Property `prop2` of element type `node_type_1` cannot be modified from `INT32` to `INT8`"
    When executing query:
      """
      ALTER GRAPH TYPE modify_properties_type {
        ALTER NODE node_type_1
        MODIFY PROPERTIES {prop3 INT NOT NULL}
      }
      """
    Then an Error should be raised: "[NT009]: Modifying the property from nullable to non-nullable is not supported, element type: `node_type_1`, property name: `prop3`"
    When executing query:
      """
      USE modify_properties CREATE INDEX IF NOT EXISTS i1 ON NODE node_type_1(prop2)
      """
    Then the execution should be successful
    When executing query:
      """
      USE modify_properties
      INSERT (a@node_type_1{prop1:1,prop2:1,prop3:1})
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE modify_properties_type {
        ALTER NODE node_type_1
        MODIFY PROPERTIES {prop2 INT, prop3 DOUBLE}
      }
      """
    Then an Error should be raised: "[NT008]: Modifying property used by index is not supported, element type: `node_type_1`, property name: `prop2`"
    When executing query:
      """
      ALTER GRAPH TYPE modify_properties_type {
        ALTER NODE node_type_1
        MODIFY PROPERTIES {prop3 DOUBLE}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE modify_properties
      MATCH (a)
      return a.prop1,a.prop2,a.prop3
      """
    Then the result should be, in any order:
      | a.prop1 | a.prop2 | a.prop3 |
      | 1       | 1       | 1.0     |
    When executing query:
      """
      ALTER GRAPH TYPE modify_properties_type {
        ALTER NODE node_type_1
        ADD PROPERTIES {prop4 INT DEFAULT 1}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE modify_properties
      MATCH (a)
      return a.prop1,a.prop2,a.prop3,a.prop4
      """
    Then the result should be, in any order:
      | a.prop1 | a.prop2 | a.prop3 | a.prop4 |
      | 1       | 1       | 1.0     | 1       |
    When executing query:
      """
      ALTER GRAPH TYPE modify_properties_type {
        ALTER NODE node_type_1
        MODIFY PROPERTIES {prop4 INT DEFAULT 2}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE modify_properties
      INSERT (a@node_type_1{prop1:2,prop2:1,prop3:1})
      """
    Then the execution should be successful
    When executing query:
      """
      USE modify_properties
      MATCH (a)
      return a.prop1,a.prop2,a.prop3,a.prop4
      """
    Then the result should be, in any order:
      | a.prop1 | a.prop2 | a.prop3 | a.prop4 |
      | 1       | 1       | 1.0     | 1       |
      | 2       | 1       | 1.0     | 2       |
    And drop the graph "modify_properties"
    And drop the graph type "modify_properties_type"

  Scenario: graph with anonymous graph type
    # Create a graph with an anonymous graph type
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS graph_with_anon_type TYPED {
        NODE TYPE node_type_player (LABEL player {id INT PRIMARY KEY}),
        EDGE TYPE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CREATE GRAPH graph_with_anon_type
      """
    Then the result should be, in any order:
      | graph_name             | create_graph_statement                                                                                                                                                                                                                                                                                           |
      | "graph_with_anon_type" | "CREATE GRAPH IF NOT EXISTS `graph_with_anon_type` TYPED {\n  NODE TYPE `node_type_player` (LABEL `player`{`id` INT64 NOT NULL, PRIMARY KEY (`id`)}),\n  EDGE TYPE `edge_type_follow` (`node_type_player`)-[LABEL `follow`{`followness` INT64 DEFAULT NULL, `age` INT64 DEFAULT NULL}]->(`node_type_player`)\n}" |
    # Drop
    When executing query:
      """
      DROP GRAPH graph_with_anon_type
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH graph_with_anon_type
      """
    Then an Error should be raised: "[01G03]: Graph `graph_with_anon_type` not found in schema `/default_schema`"
    # The anonymous graph type should be dropped automatically according to GQL 12.5 <dropgraphstatement>
    When executing query:
      """
      SHOW CREATE GRAPH TYPE "#anon_graph_type0"
      """
    Then an Error should be raised: "[01G04]: Graph type not found: `#anon_graph_type0`"
    # 2 graphs with the same anonymous graph type
    # Fix https://github.com/vesoft-inc/nebula-ng/issues/8866
    When executing query:
      """
      CREATE GRAPH graph_with_anon_type_01 TYPED { NODE TYPE Person(labels Person {id INT PRIMARY KEY , name STRING})  }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH graph_with_anon_type_02 TYPED { NODE TYPE Person(labels Person {id INT PRIMARY KEY , name STRING})  }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH graph_with_anon_type_01
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH graph_with_anon_type_02
      """
    Then the execution should be successful
