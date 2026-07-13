# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: nebula exec

  @non_tls
  Scenario: DML operations test
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "CREATE GRAPH IF NOT EXISTS ldbc_remote_test TYPED ldbc_type") FINISH
      """
    Then the execution should be successful
    # Insert nodes
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_remote_test
      INSERT
        (t1@Tag{id:101, name:'Database', url:'http://example.com/tag/database'}),
        (p1@Person{id:1, firstName:'Alice', lastName:'Smith', gender:'female', birthday:date('1990-01-01')}),
        (p2@Person{id:2, firstName:'Bob', lastName:'Johnson', gender:'male', birthday:date('1985-05-15')})
      ")
      FINISH
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_remote_test
      MATCH (p@Person)
      RETURN p.id, p.firstName, p.lastName, p.gender
      ORDER BY p.id
      """
    Then the result should be, in any order:
      | p.id | p.firstName | p.lastName | p.gender |
      | 1    | "Alice"     | "Smith"    | "female" |
      | 2    | "Bob"       | "Johnson"  | "male"   |
    When executing query:
      """
      USE ldbc_remote_test
      MATCH (t@Tag)
      WHERE t.id = 101
      RETURN t.id, t.name, t.url
      """
    Then the result should be, in any order:
      | t.id | t.name     | t.url                             |
      | 101  | "Database" | "http://example.com/tag/database" |
    # Insert edges
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_remote_test
      MATCH (p1@Person{id:1})
      MATCH (p2@Person{id:2})
      INSERT (p1)-[k@KNOWS{creationDate:local_datetime('2020-01-01T10:00:00')}]->(p2)
      ")
      FINISH
      """
    Then the execution should be successful
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_remote_test
      MATCH (p1@Person{id:1})
      MATCH (t1@Tag{id:101})
      INSERT (p1)-[hi@HAS_INTEREST{}]->(t1)
      ")
      FINISH
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_remote_test
      MATCH (p1@Person)-[k@KNOWS]->(p2@Person)
      RETURN p1.id, p2.id, k.creationDate
      """
    Then the result should be, in any order:
      | p1.id | p2.id | k.creationDate                 |
      | 1     | 2     | DATETIME "2020-01-01T10:00:00" |
    When executing query:
      """
      USE ldbc_remote_test
      MATCH (p@Person)-[hi@HAS_INTEREST]->(t@Tag)
      RETURN p.id, t.id
      """
    Then the result should be, in any order:
      | p.id | t.id |
      | 1    | 101  |
    # Set node properties
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_remote_test
      MATCH (p@Person) WHERE p.id = 1 SET p.locationIP = '192.168.1.1', p.browserUsed = 'Chrome'")
      FINISH
      """
    Then the execution should be successful
    # Verify node properties were set
    When executing query:
      """
      USE ldbc_remote_test
      MATCH (p@Person)
      WHERE p.id = 1
      RETURN p.locationIP, p.browserUsed
      """
    Then the result should be, in any order:
      | p.locationIP  | p.browserUsed |
      | "192.168.1.1" | "Chrome"      |
    # Set edge properties
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_remote_test
      MATCH (p1@Person)-[k@KNOWS]->(p2@Person)
      SET k.creationDate = local_datetime('2021-06-15T14:30:00')
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify edge properties were set
    When executing query:
      """
      USE ldbc_remote_test
      MATCH (p1@Person)-[k@KNOWS]->(p2@Person)
      WHERE p1.id = 1 AND p2.id = 2
      RETURN k.creationDate
      """
    Then the result should be, in any order:
      | k.creationDate                 |
      | DATETIME "2021-06-15T14:30:00" |
    # Delete edges
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_remote_test
      MATCH (p1@Person)-[hi@HAS_INTEREST]->(t@Tag)
      WHERE p1.id = 1 AND t.id = 101
      DELETE hi
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify edge was deleted
    When executing query:
      """
      USE ldbc_remote_test
      MATCH (p1@Person)-[hi@HAS_INTEREST]->(t@Tag)
      WHERE p1.id = 1 AND t.id = 101
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    # Delete nodes
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_remote_test
      MATCH (t@Tag)
      WHERE t.id = 101
      DELETE t
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify Tag node was deleted
    When executing query:
      """
      USE ldbc_remote_test
      MATCH (t@Tag)
      WHERE t.id = 101
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_remote_test
      MATCH (p@Person) WHERE p.id IN [1, 2]
      DETACH DELETE p
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify Person nodes were deleted
    When executing query:
      """
      USE ldbc_remote_test
      MATCH (p@Person)
      WHERE p.id IN [1, 2]
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    # Drop remote graph
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "DROP GRAPH IF EXISTS ldbc_remote_test")
      FINISH
      """
    Then the execution should be successful

  @non_tls
  Scenario: Negative case - Basic errors
    When executing query:
      """
      CALL nebula_exec("invalid_connection_string", "USE ldbc_remote_test")
      FINISH
      """
    Then an Error should be raised: "Parse uri failed: invalid_connection_string error: Invalid: URI has empty scheme: 'invalid_connection_string'"
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "INVALID QUERY SYNTAX")
      FINISH
      """
    Then an Error should be raised: "syntax error near `INVALID`"
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@255.255.255.255:26692", "USE ldbc_remote_test") FINISH
      """
    Then an Error should be raised: "RPC failed, failed to connect to all addresses"

  @non_tls
  Scenario: Negative case - URI errors
    # Missing username
    When executing query:
      """
      CALL nebula_exec("nebula://@${TCK_GRAPH_ADDRESS}", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "User `(empty)` not exist in current service group"
    # Missing password
    When executing query:
      """
      CALL nebula_exec("nebula://root@${TCK_GRAPH_ADDRESS}", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "Authenticate error: invalid username or password"
    # Invalid username
    When executing query:
      """
      CALL nebula_exec("nebula://root1:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "Authenticate error: invalid username or password"
    # Missing host
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@:26692", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "RPC failed, DNS resolution failed"
    # Missing port
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@127.0.0.1", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "RPC failed, failed to connect to all addresses"
    # Invalid port number
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@127.0.0.1:invalid_port", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "Parse uri failed: nebula://root:NebulaGraph01@127.0.0.1:invalid_port error: Invalid: Cannot parse URI"

  @non_tls
  Scenario: Negative case - Invalid URI parameters
    # Unknown parameter
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?unknown_param=value", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "Unknown URI parameter: `unknown_param`"
    # Invalid tls_enable value (not true/false)
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=yes", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "Invalid tls_enable parameter value: `yes`, expected `true` or `false`"
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=1", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "Invalid tls_enable parameter value: `1`, expected `true` or `false`"

  @tls
  Scenario: DML operations with TLS enabled
    # Create remote graph with TLS
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com",
      "CREATE GRAPH IF NOT EXISTS ldbc_remote_tls_test TYPED ldbc_type") FINISH
      """
    Then the execution should be successful
    # Insert nodes with TLS
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com", "
      USE ldbc_remote_tls_test
      INSERT
      (p1@Person{id:20, firstName:'Eve', lastName:'Davis', gender:'female', birthday:date('1988-04-25')}),
      (p2@Person{id:21, firstName:'Frank', lastName:'Miller', gender:'male', birthday:date('1991-09-10')})
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify nodes
    When executing query:
      """
      USE ldbc_remote_tls_test
      MATCH (p@Person)
      WHERE p.id IN [20, 21]
      RETURN p.id, p.firstName, p.lastName
      ORDER BY p.id
      """
    Then the result should be, in any order:
      | p.id | p.firstName | p.lastName |
      | 20   | "Eve"       | "Davis"    |
      | 21   | "Frank"     | "Miller"   |
    # Insert edge with TLS
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com", "
      USE ldbc_remote_tls_test
      MATCH (p1@Person{id:20})
      MATCH (p2@Person{id:21})
      INSERT (p1)-[k@KNOWS{creationDate:local_datetime('2023-01-20T11:00:00')}]->(p2)
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify edge
    When executing query:
      """
      USE ldbc_remote_tls_test
      MATCH (p1@Person{id:20})-[k@KNOWS]->(p2@Person{id:21})
      RETURN p1.id, p2.id, k.creationDate
      """
    Then the result should be, in any order:
      | p1.id | p2.id | k.creationDate                 |
      | 20    | 21    | DATETIME "2023-01-20T11:00:00" |
    # Update with TLS
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com", "
      USE ldbc_remote_tls_test
      MATCH (p@Person) WHERE p.id = 20
      SET p.locationIP = '172.16.0.1'
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify update
    When executing query:
      """
      USE ldbc_remote_tls_test
      MATCH (p@Person) WHERE p.id = 20
      RETURN p.locationIP
      """
    Then the result should be, in any order:
      | p.locationIP |
      | "172.16.0.1" |
    # Delete with TLS
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com", "
      USE ldbc_remote_tls_test
      MATCH (p@Person) WHERE p.id IN [20, 21]
      DETACH DELETE p
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify deletion
    When executing query:
      """
      USE ldbc_remote_tls_test
      MATCH (p@Person) WHERE p.id IN [20, 21]
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    # Drop graph with TLS
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}", "DROP GRAPH IF EXISTS ldbc_remote_tls_test")
      FINISH
      """
    Then the execution should be successful

  @tls
  Scenario: Negative case - TLS configuration errors
    # TLS enabled but missing ca parameter
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_cert=/path/to/cert&tls_key=/path/to/key", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "Missing required tls_ca parameter when TLS is enabled"
    # TLS enabled but missing cert parameter
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=/path/to/ca&tls_key=/path/to/key", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "Missing required tls_cert parameter when TLS is enabled"
    # TLS enabled but missing key parameter
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=/path/to/ca&tls_cert=/path/to/cert", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "Missing required tls_key parameter when TLS is enabled"
    When executing query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=invalid.server.com", "SHOW GRAPHS")
      FINISH
      """
    Then an Error should be raised: "UNAUTHENTICATED: Hostname Verification Check failed."
