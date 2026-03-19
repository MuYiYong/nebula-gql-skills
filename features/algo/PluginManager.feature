# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Plugin Manager

  # FIXME(Aiee) Seperate the plugin management and the plugin test. When running concurrently,
  # the algo plugin may be drop in the middle of the test
  Scenario: test plugin management
    # test built-in plugin
    When executing query:
      """
      CREATE PLUGIN dbms
      """
    Then an Error should be raised: "[NR131]: Create plugin failed: `builtin plugin `dbms` can not be created`"
    When executing query:
      """
      DROP PLUGIN dbms
      """
    Then an Error should be raised: "[NR132]: Drop plugin failed: `builtin plugin `dbms` can not be dropped`"
    # create
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PLUGIN algo
      """
    Then an Error should be raised: "[NC110]: Plugin already exist: `algo`"
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    # BFS
    # Scenario: test algo bfs
    And retry until the plugin "algo" is ready
    # can not test dynamic port in tck, so return the plugin status column explicitly
    When executing query:
      """
      CALL show_plugins() FILTER name='algo' RETURN name, plugin_type, author, description, license, version, api_version
      """
    Then the result should be, in any order:
      | name   | plugin_type | author       | description                      | license       | version | api_version |
      | "algo" | "PROCEDURE" | "vesoft-inc" | "nebula's default algorithm set" | "PROPRIETARY" | "5.0"   | "5.0"       |
    When executing query:
      """
      SHOW PLUGINS
      """
    Then the result should contain:
      | name                | plugin_type   | author       | description                                | license       | version | api_version | plugin_status                           |
      | "dbms"              | "PROCEDURE"   | "vesoft-inc" | "nebula's default dbms procedures"         | "PROPRIETARY" | "5.0"   | "5.0"       | "Valid:1, Invalid:0, BuiltIn:[G:1]"     |
      | "plugin_manager"    | "PROCEDURE"   | "vesoft-inc" | "nebula's procedure manager"               | "PROPRIETARY" | "5.0"   | "5.0"       | "Valid:1, Invalid:0, BuiltIn:[G:1]"     |
      | "localfs"           | "FILE_SYSTEM" | "vesoft-inc" | "local fs plugin"                          | "PROPRIETARY" | "5.0"   | "5.0"       | "Valid:4, Invalid:0, BuiltIn:[G:1,S:3]" |
      | "file_audit"        | "AUDIT"       | "vesoft-inc" | "nebula's default file based audit plugin" | "PROPRIETARY" | "5.0"   | "5.0"       | "Valid:4, Invalid:0, BuiltIn:[G:1,S:3]" |
      | "csv_connector"     | "CONNECTOR"   | "vesoft-inc" | "csv connector plugin"                     | "PROPRIETARY" | "5.0"   | "5.0"       | "Valid:4, Invalid:0, BuiltIn:[G:1,S:3]" |
      | "parquet_connector" | "CONNECTOR"   | "vesoft-inc" | "parquet connector plugin"                 | "PROPRIETARY" | "5.0"   | "5.0"       | "Valid:1, Invalid:0, BuiltIn:[G:1]"     |
      | "algo"              | "PROCEDURE"   | "vesoft-inc" | "nebula's default algorithm set"           | "PROPRIETARY" | "5.0"   | "5.0"       | "Valid:4, Invalid:0"                    |
      | "log_rotate"        | "LOG_ROTATE"  | "vesoft-inc" | "nebula's log rotator"                     | "PROPRIETARY" | "5.0"   | "5.0"       | "Valid:4, Invalid:0, BuiltIn:[G:1,S:3]" |
      | "s3fs"              | "FILE_SYSTEM" | "vesoft-inc" | "s3 fs plugin"                             | "PROPRIETARY" | "5.0"   | "5.0"       | "Valid:1, Invalid:0, BuiltIn:[G:1]"     |
      | "gcsfs"             | "FILE_SYSTEM" | "vesoft-inc" | "gcs fs plugin"                            | "PROPRIETARY" | "5.0"   | "5.0"       | "Valid:1, Invalid:0, BuiltIn:[G:1]"     |
    When executing query:
      """
      SHOW PLUGIN algo
      """
    Then the result should be, in any order:
      | service | plugin_status |
      | /.+/    | "Valid"       |
      | /.+/    | "Valid"       |
      | /.+/    | "Valid"       |
      | /.+/    | "Valid"       |
    When executing query:
      """
      CREATE TEMPORARY GRAPH #plugin_test_ldbc_projection AS COPY OF ldbc OPTIONS {immutable: true, without_properties: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc
      MATCH (v:Person{firstName: 'Tim'})
      RETURN element_id(v) AS src
      NEXT
      USE ldbc
      CALL algo.bfs('#plugin_test_ldbc_projection', src)
      RETURN distance
      ORDER BY distance DESC
      LIMIT 30
      """
    Then the result should be, in any order:
      | distance |
      | 4        |
      | 4        |
      | 3        |
      | 3        |
      | 3        |
      | 3        |
      | 3        |
      | 3        |
      | 3        |
      | 2        |
      | 2        |
      | 2        |
      | 2        |
      | 2        |
      | 2        |
      | 2        |
      | 2        |
      | 1        |
      | 1        |
      | 1        |
      | 1        |
      | 1        |
      | 1        |
      | 1        |
      | 0        |
      | -1       |
      | -1       |
      | -1       |
      | -1       |
      | -1       |
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (v) RETURN v }
      USE ldbc
      MATCH (v:Person{firstName: 'Tim'})
      RETURN g AS gx, element_id(v) AS src
      NEXT
      USE ldbc
      CALL algo.bfs(gx, src)
      RETURN max(distance) as m GROUP BY ()
      """
    Then the result should be, in any order:
      | m |
      | 0 |
    When executing query:
      """
      GRAPH g = GRAPH{
      USE ldbc
      MATCH (s:Person)
      OPTIONAL MATCH (s:Person)-[e:KNOWS]->(t:Person)
      RETURN s, e, t
      }
      USE ldbc
      MATCH (src:Person{firstName:"Tim"}), (dst:Person{firstName:"Sophie"})
      RETURN g AS gx, element_id(src) AS src_id, element_id(dst) AS dst_id
      NEXT
      USE ldbc
      CALL algo.bfs(gx, src_id)
      FILTER node_id = dst_id
      RETURN distance
      """
    Then the result should be, in any order:
      | distance |
      | -1       |
    # BFS using graph variable
    When executing query:
      """
      USE ldbc MATCH (v:Person{firstName: 'Tim'})
      RETURN element_id(v) AS src
      NEXT
      USE ldbc
      CALL algo.bfs('#plugin_test_ldbc_projection', src)
      RETURN distance
      ORDER BY distance DESC
      LIMIT 5
      """
    Then the result should be, in any order:
      | distance |
      | 4        |
      | 4        |
      | 3        |
      | 3        |
      | 3        |
    # Scenario: test graph stats procedure
    And retry until the plugin "algo" is ready
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (v) RETURN v } RETURN g AS gx
      NEXT
      CALL algo.graph_stats(gx)
      return total_node_number
      """
    # The result is the same as USE ldbc MATCH (v) RETURN COUNT (DISTINCT v) AS cnt GROUP BY ()
    Then the result should be, in any order:
      | total_node_number |
      | 34                |
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (v) RETURN v } RETURN g AS gx
      NEXT
      CALL algo.graph_stats(gx)
      RETURN total_edge_number, total_node_number
      """
    # No edge was used when creating the graph variable, so the total_edge_number is 0
    Then the result should be, in any order:
      | total_edge_number | total_node_number |
      | 0                 | 34                |
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (v)-[e]-(v2) RETURN v,e,v2 } RETURN g AS gx
      NEXT
      CALL algo.graph_stats(gx)
      RETURN total_edge_number, total_node_number
      """
    Then the result should be, in any order:
      | total_edge_number | total_node_number |
      | 74                | 28                |
    When executing query:
      """
      CALL algo.dijkstra("#analytic_ldbc", 1, "KNOWS") return *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `dijkstra`: the graph `#analytic_ldbc` is not an immutable temporary graph"
    And drop the graph "#plugin_test_ldbc_projection"
