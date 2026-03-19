# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: built in procedures

  Scenario: show procedures
    When executing query:
      """
      CALL show_procedures()
      FILTER name='show_procedures'
      RETURN module, name, parameters, return_fields, comment
      """
    Then the result should be, in any order:
      | module    | name              | parameters | return_fields                                                                                                                                          | comment                      |
      | "dbms.so" | "show_procedures" | ""         | "proc_type:STRING, module:STRING, schema:STRING, owner:STRING, name:STRING, parameters:STRING, return_fields:STRING, null_case:STRING, comment:STRING" | "show all loaded procedures" |

  Scenario: show graphs
    When executing query:
      """
      CALL show_graphs() YIELD `name` AS gn
      FILTER gn='ldbc'
      RETURN count(gn) AS c GROUP BY ()
      """
    Then the result should be, in any order:
      | c |
      | 1 |
    When executing query:
      """
      CALL show_graphs("")
      RETURN *
      """
    Then an Error should be raised: "[01G04]: Graph type not found: ``"

  Scenario: show graph types
    When executing query:
      """
      CALL show_graph_types() YIELD `graph_type` AS gtn
      FILTER gtn='ldbc_type'
      RETURN count(gtn) AS c GROUP BY ()
      """
    Then the result should be, in any order:
      | c |
      | 1 |

  Scenario: describe graph
    When executing query:
      """
      CALL describe_graph('ldbc')
      RETURN *
      """
    Then the result should be, in any order:
      | graph_name | graph_type_name |
      | "ldbc"     | "ldbc_type"     |
    When executing query:
      """
      $graph_name="ldbc"
      CALL describe_graph($graph_name)
      RETURN *
      """
    Then the result should be, in any order:
      | graph_name | graph_type_name |
      | "ldbc"     | "ldbc_type"     |
    When executing query:
      """
      CALL describe_graph('_not_exist_graph_name_')
      RETURN *
      """
    Then an Error should be raised: "[01G03]: Graph `_not_exist_graph_name_` not found in schema `/default_schema`"
    When executing query:
      """
      CALL show_graphs() YIELD `name` AS gn
      FILTER gn='ldbc'
      CALL describe_graph(gn) YIELD `graph_type_name` AS gtn
      RETURN gn, gtn
      """
    Then the result should be, in any order:
      | gn     | gtn         |
      | "ldbc" | "ldbc_type" |

  Scenario: show create graph
    When executing query:
      """
      CALL show_create_graph("ldbc") RETURN graph_name, create_graph_statement
      """
    Then the result should be, in any order:
      | graph_name | create_graph_statement                                |
      | "ldbc"     | "CREATE GRAPH IF NOT EXISTS `ldbc` TYPED `ldbc_type`" |

  Scenario: show create graph type
    When executing query:
      """
      CALL show_create_graph_type("ldbc_type") RETURN graph_type_name, create_graph_type_statement
      """
    Then the result should be, in any order:
      | graph_type_name | create_graph_type_statement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
      | "ldbc_type"     | "CREATE GRAPH TYPE IF NOT EXISTS `ldbc_type` AS {\n  NODE TYPE `Place` (LABELS `City`&`Continent`&`Country`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, `kind` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Forum` (LABEL `Forum`{`id` INT64 NOT NULL, `title` STRING DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Comment` (LABELS `Comment`&`Message`{`id` INT64 NOT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `content` STRING DEFAULT NULL, `extent` INT8 DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Person` (LABEL `Person`{`id` INT64 NOT NULL, `firstName` STRING DEFAULT NULL, `lastName` STRING DEFAULT NULL, `gender` STRING DEFAULT NULL, `birthday` DATE DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `vec` VECTOR<3, FLOAT> DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Tag` (LABEL `Tag`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Post` (LABELS `Message`&`Post`{`id` INT64 NOT NULL, `imageFile` STRING DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `content` STRING DEFAULT NULL, `extent` INT8 DEFAULT NULL, `language` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `TagClass` (LABEL `TagClass`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Organisation` (LABELS `Company`&`University`{`id` INT64 NOT NULL, `kind` STRING DEFAULT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),\n  EDGE TYPE `HAS_INTEREST` (`Person`)-[LABEL `HAS_INTEREST`{}]->(`Tag`),\n  EDGE TYPE `WORK_AT` (`Person`)-[LABEL `WORK_AT`{`workFrom` INT64 DEFAULT NULL}]->(`Organisation`),\n  EDGE TYPE `IS_LOCATED_IN_1` (`Person`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_2` (`Comment`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_3` (`Post`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_LOCATED_IN_4` (`Organisation`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),\n  EDGE TYPE `IS_PART_OF` (`Place`)-[LABEL `IS_PART_OF`{}]->(`Place`),\n  EDGE TYPE `HAS_TYPE` (`Tag`)-[LABEL `HAS_TYPE`{}]->(`TagClass`),\n  EDGE TYPE `REPLY_OF_1` (`Comment`)-[LABEL `REPLY_OF`{}]->(`Post`),\n  EDGE TYPE `REPLY_OF_2` (`Comment`)-[LABEL `REPLY_OF`{}]->(`Comment`),\n  EDGE TYPE `KNOWS` (`Person`)-[LABEL `KNOWS`{`creationDate` LOCAL DATETIME DEFAULT NULL, `vec` VECTOR<3, FLOAT> DEFAULT NULL}]->(`Person`),\n  EDGE TYPE `FOLLOWS` (`Person`)-[LABEL `FOLLOWS`{`src` INT64 DEFAULT NULL, `dst` INT64 DEFAULT NULL}]->(`Person`),\n  EDGE TYPE `CONTAINER_OF` (`Forum`)-[LABEL `CONTAINER_OF`{}]->(`Post`),\n  EDGE TYPE `HAS_MEMBER` (`Forum`)-[LABEL `HAS_MEMBER`{}]->(`Person`),\n  EDGE TYPE `HAS_MODERATOR` (`Forum`)-[LABEL `HAS_MODERATOR`{}]->(`Person`),\n  EDGE TYPE `STUDY_AT` (`Person`)-[LABEL `STUDY_AT`{`classYear` INT64 DEFAULT NULL}]->(`Organisation`),\n  EDGE TYPE `IS_SUBCLASS_OF` (`TagClass`)-[LABEL `IS_SUBCLASS_OF`{}]->(`TagClass`),\n  EDGE TYPE `HAS_TAG_1` (`Forum`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_TAG_2` (`Post`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_TAG_3` (`Comment`)-[LABEL `HAS_TAG`{}]->(`Tag`),\n  EDGE TYPE `HAS_CREATOR_1` (`Post`)-[LABEL `HAS_CREATOR`{}]->(`Person`),\n  EDGE TYPE `HAS_CREATOR_2` (`Comment`)-[LABEL `HAS_CREATOR`{}]->(`Person`),\n  EDGE TYPE `LIKES_1` (`Person`)-[LABEL `LIKES`{`creationDate` LOCAL DATETIME DEFAULT NULL}]->(`Post`),\n  EDGE TYPE `LIKES_2` (`Person`)-[LABEL `LIKES`{`creationDate` LOCAL DATETIME DEFAULT NULL}]->(`Comment`)\n}" |

  Scenario: show indexes
    When executing query:
      """
      CALL show_all_indexes()
      FILTER graph_name='ldbc'
      RETURN name, state, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name | state | index_type | graph_name | entity_type | element_type | properties |
    When executing query:
      """
      CALL show_indexes('ldbc')
      RETURN name, state, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name | state | index_type | graph_name | entity_type | element_type | properties |
    When executing query:
      """
      CALL show_indexes(123) RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `show_indexes`: argument `123` is of type `INT32` instead of the expected `STRING`"
    When executing query:
      """
      USE 1234 SHOW INDEXES
      """
    Then an Error should be raised: "[42001]: syntax error near `1234`"
    When executing query:
      """
      CALL show_all_indexes() RETURN graph_name, name NEXT FILTER graph_name='ldbc' RETURN name
      """
    Then the result should be, in any order:
      | name |
    When executing query:
      """
      SHOW INDEXES NEXT RETURN *
      """
    Then an Error should be raised: "[42001]: syntax error near `NEXT`"
    When executing query:
      """
      USE ldbc SHOW INDEXES
      """
    Then the result should be, in any order:
      | name | state | index_type | schema | graph_name | entity_type | element_type | properties |
    When executing query:
      """
      USE not_exists_graph SHOW INDEXES
      """
    Then an Error should be raised: "[01G03]: Graph `not_exists_graph` not found in schema `/default_schema`"

  Scenario: show functions
    When executing query:
      """
      CALL show_functions("ALL") FILTER name='avg' RETURN name, signature, function_type
      """
    Then the result should be, in any order:
      | name  | signature                 | function_type |
      | "avg" | "avg(DECIMAL) -> DECIMAL" | "[aggregate]" |
      | "avg" | "avg(DOUBLE) -> DOUBLE"   | "[aggregate]" |
      | "avg" | "avg(FLOAT) -> DOUBLE"    | "[aggregate]" |
      | "avg" | "avg(UINT64) -> DOUBLE"   | "[aggregate]" |
      | "avg" | "avg(UINT32) -> DOUBLE"   | "[aggregate]" |
      | "avg" | "avg(UINT16) -> DOUBLE"   | "[aggregate]" |
      | "avg" | "avg(UINT8) -> DOUBLE"    | "[aggregate]" |
      | "avg" | "avg(INT64) -> DOUBLE"    | "[aggregate]" |
      | "avg" | "avg(INT32) -> DOUBLE"    | "[aggregate]" |
      | "avg" | "avg(INT16) -> DOUBLE"    | "[aggregate]" |
      | "avg" | "avg(INT8) -> DOUBLE"     | "[aggregate]" |

  Scenario: show leaders
    When executing query:
      """
      CALL show_leaders()
      RETURN host_address, leader_count
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW LEADERS
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_leaders()
      RETURN sum(leader_count) as leader_count GROUP BY()
      """
    Then the result should contain:
      | leader_count |
      | 11           |

  Scenario: balance leader and balance data
    When executing query:
      """
      CALL balance_leader() FINISH
      """
    Then the execution should be successful
    And wait "10" seconds
    When executing query:
      """
      BALANCE LEADER
      """
    Then the execution should be successful
    And wait "10" seconds
    When executing query:
      """
      CALL balance_data() FINISH
      """
    Then the execution should be successful
    When executing query:
      """
      BALANCE DATA
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cancel_balance_data() FINISH
      """
    Then the execution should be successful
    When executing query:
      """
      CANCEL BALANCE DATA
      """
    Then the execution should be successful

  Scenario: show services
    When executing query:
      """
      CALL show_services_storage()
      RETURN host, port, status, leader_count, part_count, version
      """
    Then the result should be, in any order:
      | host        | port | status   | leader_count | part_count | version |
      | "127.0.0.1" | /.+/ | "ONLINE" | /.+/         | 11         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | /.+/         | 11         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | /.+/         | 11         | /.+/    |
    When executing query:
      """
      SHOW SERVICES STORAGE
      """
    Then the result should be, in any order:
      | host        | port | status   | leader_count | part_count | version |
      | "127.0.0.1" | /.+/ | "ONLINE" | /.+/         | 11         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | /.+/         | 11         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | /.+/         | 11         | /.+/    |
    When executing query:
      """
      CALL show_services() RETURN host, port, status, service_type, git_info_sha, version
      """
    Then the result should be, in any order:
      | host        | port | status   | service_type | git_info_sha | version |
      | "127.0.0.1" | /.+/ | "ONLINE" | "STORAGE"    | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "STORAGE"    | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "STORAGE"    | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "GRAPH"      | /.+/         | /.+/    |
    When executing query:
      """
      CALL show_services('All') RETURN host, port, status, service_type, git_info_sha, version
      """
    Then the result should be, in any order:
      | host        | port | status   | service_type | git_info_sha | version |
      | "127.0.0.1" | /.+/ | "ONLINE" | "STORAGE"    | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "STORAGE"    | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "STORAGE"    | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "GRAPH"      | /.+/         | /.+/    |
    When executing query:
      """
      SHOW SERVICES
      """
    Then the result should be, in any order:
      | host        | port | status   | service_type | git_info_sha | version |
      | "127.0.0.1" | /.+/ | "ONLINE" | "STORAGE"    | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "STORAGE"    | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "STORAGE"    | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "GRAPH"      | /.+/         | /.+/    |
    When executing query:
      """
      CALL show_services('graph') RETURN host, port, status, service_type, git_info_sha, version
      """
    Then the result should be, in any order:
      | host        | port | status   | service_type | git_info_sha | version |
      | "127.0.0.1" | /.+/ | "ONLINE" | "GRAPH"      | /.+/         | /.+/    |
    When executing query:
      """
      SHOW SERVICES GRAPH
      """
    Then the result should be, in any order:
      | host        | port | status   | service_type | git_info_sha | version |
      | "127.0.0.1" | /.+/ | "ONLINE" | "GRAPH"      | /.+/         | /.+/    |
    When executing analytic query:
      """
      SHOW SERVICES ANALYTIC
      """
    Then the result should be, in any order:
      | host        | port | status   | service_type | git_info_sha | version |
      | "127.0.0.1" | /.+/ | "ONLINE" | "ANALYTIC"   | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "ANALYTIC"   | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "ANALYTIC"   | /.+/         | /.+/    |
    When executing query:
      """
      CALL show_services('META') RETURN host, port, status, service_type, git_info_sha, version
      """
    Then the result should be, in any order:
      | host        | port | status   | service_type | git_info_sha | version |
      | "127.0.0.1" | /.+/ | "ONLINE" | "META"       | /.+/         | /.+/    |
    When executing query:
      """
      SHOW SERVICES META
      """
    Then the result should be, in any order:
      | host        | port | status   | service_type | git_info_sha | version |
      | "127.0.0.1" | /.+/ | "ONLINE" | "META"       | /.+/         | /.+/    |
    When executing query:
      """
      CALL show_services('invalid_service_type') RETURN host, port, status, service_type, git_info_sha, version
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `show_services`: invalid service type: invalid_service_type, only allowed: graph/meta/all"
    When executing analytic query:
      """
      SHOW SERVICES
      """
    Then the result should be, in any order:
      | host        | port | status   | service_type | git_info_sha | version |
      | "127.0.0.1" | /.+/ | "ONLINE" | "ANALYTIC"   | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "ANALYTIC"   | /.+/         | /.+/    |
      | "127.0.0.1" | /.+/ | "ONLINE" | "ANALYTIC"   | /.+/         | /.+/    |

  Scenario: show services
    When executing query:
      """
      CALL show_partitions()
      RETURN partition_id, leader, peer
      LIMIT 0
      """
    # Since the result is not stable, LIMIT 0 to skip result
    Then the result should be, in any order:
      | partition_id | leader | peer |
    When executing query:
      """
      CALL show_partitions()
      RETURN partition_id
      """
    Then the result should be, in any order:
      | partition_id |
      | 0            |
      | 1            |
      | 2            |
      | 3            |
      | 4            |
      | 5            |
      | 6            |
      | 7            |
      | 8            |
      | 9            |
      | 10           |
    When executing query:
      """
      SHOW PARTITIONS
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_partitions_verbose()
      RETURN partition_id, conf_version
      """
    Then the result should be, in any order:
      | partition_id | conf_version |
      | 0            | 0            |
      | 1            | 0            |
      | 2            | 0            |
      | 3            | 0            |
      | 4            | 0            |
      | 5            | 0            |
      | 6            | 0            |
      | 7            | 0            |
      | 8            | 0            |
      | 9            | 0            |
      | 10           | 0            |
    When executing query:
      """
      SHOW PARTITIONS VERBOSE
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PARTITIONS VERBOSE 0
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PARTITIONS VERBOSE 1
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_peers() FILTER state = "LEADER" RETURN COUNT(partition_id) as leader_count GROUP BY()
      """
    Then the result should be, in any order:
      | leader_count |
      | 11           |
    When executing query:
      """
      CALL show_peers() FILTER state = "FOLLOWER" RETURN COUNT(partition_id) as follower_count GROUP BY()
      """
    Then the result should be, in any order:
      | follower_count |
      | 22             |
    When executing query:
      """
      SHOW PEERS
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PEERS LEADER
      """
    Then the execution should be successful

  Scenario: commands must be standalone
    # Mixing a command with a GQL statement is not allowed
    When executing query:
      """
      BALANCE LEADER
      NEXT
      RETURN 1 AS a
      """
    Then an Error should be raised: "[42001]: syntax error near `NEXT`"
    When executing query:
      """
      BALANCE LEADER
      UNION ALL
      RETURN 1 AS a
      """
    Then an Error should be raised: "[42001]: syntax error near `UNION`"
    When executing query:
      """
      SHOW GRAPHS
      RETURN 1 AS a
      """
    Then an Error should be raised: "[42N57]: Commands can only appear as top-level command statements without mixing"
    # Command cannot appear together with variable definition block
    When executing query:
      """
      VALUE a = 1
      SHOW SERVICES
      """
    Then an Error should be raised: "[42N57]: Commands can only appear as top-level command statements without mixing"
    # Commands not allowed in procedure body
    When executing query:
      """
      CREATE PROCEDURE proc_cmd_only() RETURNS () {
        BALANCE LEADER
      }
      """
    Then an Error should be raised: "[42N57]: Commands can only appear as top-level command statements without mixing"
    When executing query:
      """
      CREATE PROCEDURE proc_cmd_mixed() RETURNS (ret int) {
        SHOW SERVICES
        RETURN 1 AS ret
      }
      """
    Then an Error should be raised: "[42N57]: Commands can only appear as top-level command statements without mixing"
    When executing query:
      """
      CREATE PROCEDURE proc_cmd_with_var() RETURNS () {
        VALUE a = 1
        BALANCE LEADER
      }
      """
    Then an Error should be raised: "[42N57]: Commands can only appear as top-level command statements without mixing"
    When executing query:
      """
      BALANCE LEADER
      RETURN 1 AS a
      """
    Then an Error should be raised: "[42N57]: Commands can only appear as top-level command statements without mixing"
