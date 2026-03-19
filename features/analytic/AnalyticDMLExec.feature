# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Analytic DML execution on GraphD

  @non_tls
  Scenario: DML operations via AnalyticD to GraphD
    # Create remote graph on GraphD via nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "CREATE GRAPH IF NOT EXISTS ldbc_analytic_remote_test TYPED ldbc_type") FINISH
      """
    Then the execution should be successful
    # Insert nodes via AnalyticD using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_analytic_remote_test
      INSERT
        (t1@Tag{id:101, name:'Database', url:'http://example.com/tag/database'}),
        (p1@Person{id:1, firstName:'Alice', lastName:'Smith', gender:'female', birthday:date('1990-01-01')}),
        (p2@Person{id:2, firstName:'Bob', lastName:'Johnson', gender:'male', birthday:date('1985-05-15')})
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify nodes on GraphD
    When executing query:
      """
      USE ldbc_analytic_remote_test
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
      USE ldbc_analytic_remote_test
      MATCH (t@Tag)
      WHERE t.id = 101
      RETURN t.id, t.name, t.url
      """
    Then the result should be, in any order:
      | t.id | t.name     | t.url                             |
      | 101  | "Database" | "http://example.com/tag/database" |
    # Insert edges via AnalyticD using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_analytic_remote_test
      MATCH (p1@Person{id:1})
      MATCH (p2@Person{id:2})
      INSERT (p1)-[k@KNOWS{creationDate:local_datetime('2020-01-01T10:00:00')}]->(p2)
      ")
      FINISH
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_analytic_remote_test
      MATCH (p1@Person{id:1})
      MATCH (t1@Tag{id:101})
      INSERT (p1)-[hi@HAS_INTEREST{}]->(t1)
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify edges on GraphD
    When executing query:
      """
      USE ldbc_analytic_remote_test
      MATCH (p1@Person)-[k@KNOWS]->(p2@Person)
      RETURN p1.id, p2.id, k.creationDate
      """
    Then the result should be, in any order:
      | p1.id | p2.id | k.creationDate                 |
      | 1     | 2     | DATETIME "2020-01-01T10:00:00" |
    When executing query:
      """
      USE ldbc_analytic_remote_test
      MATCH (p@Person)-[hi@HAS_INTEREST]->(t@Tag)
      RETURN p.id, t.id
      """
    Then the result should be, in any order:
      | p.id | t.id |
      | 1    | 101  |
    # Set node properties via AnalyticD using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_analytic_remote_test
      MATCH (p@Person) WHERE p.id = 1
      SET p.locationIP = '192.168.1.1', p.browserUsed = 'Chrome'
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify node properties on GraphD
    When executing query:
      """
      USE ldbc_analytic_remote_test
      MATCH (p@Person)
      WHERE p.id = 1
      RETURN p.locationIP, p.browserUsed
      """
    Then the result should be, in any order:
      | p.locationIP  | p.browserUsed |
      | "192.168.1.1" | "Chrome"      |
    # Set edge properties via AnalyticD using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_analytic_remote_test
      MATCH (p1@Person)-[k@KNOWS]->(p2@Person)
      SET k.creationDate = local_datetime('2021-06-15T14:30:00')
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify edge properties on GraphD
    When executing query:
      """
      USE ldbc_analytic_remote_test
      MATCH (p1@Person)-[k@KNOWS]->(p2@Person)
      WHERE p1.id = 1 AND p2.id = 2
      RETURN k.creationDate
      """
    Then the result should be, in any order:
      | k.creationDate                 |
      | DATETIME "2021-06-15T14:30:00" |
    # Delete edges via AnalyticD using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_analytic_remote_test
      MATCH (p1@Person)-[hi@HAS_INTEREST]->(t@Tag)
      WHERE p1.id = 1 AND t.id = 101
      DELETE hi
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify edge was deleted on GraphD
    When executing query:
      """
      USE ldbc_analytic_remote_test
      MATCH (p1@Person)-[hi@HAS_INTEREST]->(t@Tag)
      WHERE p1.id = 1 AND t.id = 101
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    # Delete nodes via AnalyticD using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_analytic_remote_test
      MATCH (t@Tag)
      WHERE t.id = 101
      DELETE t
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify Tag node was deleted on GraphD
    When executing query:
      """
      USE ldbc_analytic_remote_test
      MATCH (t@Tag)
      WHERE t.id = 101
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    # Delete Person nodes with DETACH via AnalyticD using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "
      USE ldbc_analytic_remote_test
      MATCH (p@Person) WHERE p.id IN [1, 2]
      DETACH DELETE p
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify Person nodes were deleted on GraphD
    When executing query:
      """
      USE ldbc_analytic_remote_test
      MATCH (p@Person)
      WHERE p.id IN [1, 2]
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    # Drop remote graph using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "DROP GRAPH IF EXISTS ldbc_analytic_remote_test")
      FINISH
      """
    Then the execution should be successful

  @non_tls
  Scenario: Negative case - Invalid queries via AnalyticD
    # Create test graph using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "CREATE GRAPH IF NOT EXISTS ldbc_analytic_error_test TYPED ldbc_type") FINISH
      """
    Then the execution should be successful
    # Invalid syntax
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "INVALID QUERY SYNTAX")
      FINISH
      """
    Then an Error should be raised: "syntax error near `INVALID`"
    # Invalid connection string
    When executing analytic query:
      """
      CALL nebula_exec("invalid_connection_string", "USE ldbc_analytic_error_test")
      FINISH
      """
    Then an Error should be raised: "Parse uri failed: invalid_connection_string error: Invalid: URI has empty scheme: 'invalid_connection_string'"
    # Connection to non-existent host
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@255.255.255.255:26692", "USE ldbc_analytic_error_test") FINISH
      """
    Then an Error should be raised: "RPC failed, failed to connect to all addresses"
    # Drop test graph using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "DROP GRAPH IF EXISTS ldbc_analytic_error_test")
      FINISH
      """
    Then the execution should be successful

  @tls
  Scenario: DML operations with TLS enabled
    # Create remote graph with TLS using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com", "CREATE GRAPH IF NOT EXISTS ldbc_analytic_tls_test TYPED ldbc_type") FINISH
      """
    Then the execution should be successful
    # Insert data via AnalyticD with TLS using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com", "
      USE ldbc_analytic_tls_test
      INSERT
        (p1@Person{id:10, firstName:'Charlie', lastName:'Brown', gender:'male', birthday:date('1995-03-20')}),
        (p2@Person{id:11, firstName:'Diana', lastName:'Prince', gender:'female', birthday:date('1992-07-12')})
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify with GraphD query using TLS
    When executing query:
      """
      USE ldbc_analytic_tls_test
      MATCH (p@Person)
      WHERE p.id IN [10, 11]
      RETURN p.id, p.firstName, p.lastName
      ORDER BY p.id
      """
    Then the result should be, in any order:
      | p.id | p.firstName | p.lastName |
      | 10   | "Charlie"   | "Brown"    |
      | 11   | "Diana"     | "Prince"   |
    # Insert edge with TLS using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com", "
      USE ldbc_analytic_tls_test
      MATCH (p1@Person{id:10})
      MATCH (p2@Person{id:11})
      INSERT (p1)-[k@KNOWS{creationDate:local_datetime('2022-03-15T09:30:00')}]->(p2)
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify edge with GraphD TLS connection
    When executing query:
      """
      USE ldbc_analytic_tls_test
      MATCH (p1@Person{id:10})-[k@KNOWS]->(p2@Person{id:11})
      RETURN p1.id, p2.id, k.creationDate
      """
    Then the result should be, in any order:
      | p1.id | p2.id | k.creationDate                 |
      | 10    | 11    | DATETIME "2022-03-15T09:30:00" |
    # Update via AnalyticD with TLS using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com", "
      USE ldbc_analytic_tls_test
      MATCH (p@Person) WHERE p.id = 10
      SET p.locationIP = '10.0.0.1'
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify update on GraphD with TLS
    When executing query:
      """
      USE ldbc_analytic_tls_test
      MATCH (p@Person) WHERE p.id = 10
      RETURN p.locationIP
      """
    Then the result should be, in any order:
      | p.locationIP |
      | "10.0.0.1"   |
    # Delete with TLS using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com", "
      USE ldbc_analytic_tls_test
      MATCH (p@Person) WHERE p.id IN [10, 11]
      DETACH DELETE p
      ")
      FINISH
      """
    Then the execution should be successful
    # Verify deletion on GraphD
    When executing query:
      """
      USE ldbc_analytic_tls_test
      MATCH (p@Person) WHERE p.id IN [10, 11]
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    # Drop graph using nebula_exec
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com", "DROP GRAPH IF EXISTS ldbc_analytic_tls_test")
      FINISH
      """
    Then the execution should be successful

  @non_tls
  Scenario: Comprehensive batch DML operations
    # Create remote graph for comprehensive batch operations
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "CREATE GRAPH IF NOT EXISTS ldbc_analytic_batch_test TYPED ldbc_type") FINISH
      """
    Then the execution should be successful
    # Batch INSERT Person nodes
    When executing analytic query:
      """
      VALUE fmt_person_query = "
        TABLE t TYPED TABLE {id INT, firstName STRING, lastName STRING, gender STRING} = %s
        USE ldbc_analytic_batch_test
        FOR r IN t
        INSERT OR REPLACE (@Person{id:r.id, firstName:r.firstName, lastName:r.lastName, gender:r.gender, birthday:date('1990-01-01')})"

      TABLE persons {id INT, firstName STRING, lastName STRING, gender STRING}

      FOR i in range(1, 50)
      EXPORT i, "Person_" || cast(i as STRING), "Last_" || cast(i as STRING), CASE WHEN i % 2 = 0 THEN "male" ELSE "female" END INTO persons

      FOR split IN table_split(persons, CAST(20 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_person_query, to_literal(split))) FINISH
      """
    Then the execution should be successful
    # Verify batch inserted Person nodes
    When executing query:
      """
      USE ldbc_analytic_batch_test
      MATCH (p@Person)
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 50  |
    When executing query:
      """
      USE ldbc_analytic_batch_test
      MATCH (p@Person)
      WHERE p.id IN [1, 25, 50]
      RETURN p.id, p.firstName, p.lastName, p.gender
      """
    Then the result should be, in any order:
      | p.id | p.firstName | p.lastName | p.gender |
      | 1    | "Person_1"  | "Last_1"   | "female" |
      | 25   | "Person_25" | "Last_25"  | "female" |
      | 50   | "Person_50" | "Last_50"  | "male"   |
    # Batch INSERT Tag nodes
    When executing analytic query:
      """
      VALUE fmt_tag_query = "
        TABLE t TYPED TABLE {id INT, name STRING, url STRING} = %s
        USE ldbc_analytic_batch_test
        FOR r IN t
        INSERT OR REPLACE (@Tag{id:r.id, name:r.name, url:r.url})"

      TABLE tags {id INT, name STRING, url STRING}

      FOR i in range(1, 30)
      EXPORT i, "Tag_" || cast(i as STRING), "http://example.com/tag/" || cast(i as STRING) INTO tags

      FOR split IN table_split(tags, CAST(15 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_tag_query, to_literal(split))) FINISH
      """
    Then the execution should be successful
    # Verify batch inserted Tag nodes
    When executing query:
      """
      USE ldbc_analytic_batch_test
      MATCH (t@Tag)
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 30  |
    When executing query:
      """
      USE ldbc_analytic_batch_test
      MATCH (t@Tag)
      WHERE t.id IN [1, 15, 30]
      RETURN t.id, t.name, t.url
      """
    Then the result should be, in any order:
      | t.id | t.name   | t.url                       |
      | 1    | "Tag_1"  | "http://example.com/tag/1"  |
      | 30   | "Tag_30" | "http://example.com/tag/30" |
      | 15   | "Tag_15" | "http://example.com/tag/15" |
    # Batch INSERT KNOWS edges
    When executing analytic query:
      """
      VALUE fmt_knows_query = "
        TABLE t TYPED TABLE {src_id INT, dst_id INT} = %s
        USE ldbc_analytic_batch_test
        FOR r IN t
        MATCH (p1@Person{id:r.src_id})
        MATCH (p2@Person{id:r.dst_id})
        INSERT OR REPLACE (p1)-[k@KNOWS{creationDate:local_datetime('2023-01-01T00:00:00')}]->(p2)"

      TABLE knows_edges {src_id INT, dst_id INT}

      FOR i in range(1, 25)
      EXPORT i, i + 1 INTO knows_edges

      FOR split IN table_split(knows_edges, CAST(10 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_knows_query, to_literal(split))) FINISH
      """
    Then the execution should be successful
    # Batch INSERT HAS_INTEREST edges
    When executing analytic query:
      """
      VALUE fmt_interest_query = "
        TABLE t TYPED TABLE {person_id INT, tag_id INT} = %s
        USE ldbc_analytic_batch_test
        FOR r IN t
        MATCH (p@Person{id:r.person_id})
        MATCH (tag@Tag{id:r.tag_id})
        INSERT OR REPLACE (p)-[hi@HAS_INTEREST{}]->(tag)"

      TABLE interest_edges {person_id INT, tag_id INT}

      FOR i in range(1, 20)
      EXPORT i, (i % 30) + 1 INTO interest_edges

      FOR split IN table_split(interest_edges, CAST(10 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_interest_query, to_literal(split))) FINISH
      """
    Then the execution should be successful
    # Verify batch inserted edges
    When executing query:
      """
      USE ldbc_analytic_batch_test
      MATCH ()-[k@KNOWS]->()
      RETURN count(*) AS knows_count
      """
    Then the result should be, in any order:
      | knows_count |
      | 25          |
    When executing query:
      """
      USE ldbc_analytic_batch_test
      MATCH ()-[hi@HAS_INTEREST]->()
      RETURN count(*) AS interest_count
      """
    Then the result should be, in any order:
      | interest_count |
      | 20             |
    # Batch SET UPDATE node properties
    When executing analytic query:
      """
      VALUE fmt_node_update = "
        TABLE t TYPED TABLE {id INT, locationIP STRING, browserUsed STRING} = %s
        USE ldbc_analytic_batch_test
        FOR r IN t
        MATCH (p@Person{id:r.id})
        SET p.locationIP = r.locationIP, p.browserUsed = r.browserUsed"

      TABLE node_updates {id INT, locationIP STRING, browserUsed STRING}

      FOR i in range(1, 20)
      EXPORT i, "192.168.1." || cast(i as STRING), CASE WHEN i % 2 = 0 THEN "Chrome" ELSE "Firefox" END INTO node_updates

      FOR split IN table_split(node_updates, CAST(10 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_node_update, to_literal(split))) FINISH
      """
    Then the execution should be successful
    # Verify batch node property updates
    When executing query:
      """
      USE ldbc_analytic_batch_test
      MATCH (p@Person)
      WHERE p.id IN [1, 10, 19]
      RETURN p.id, p.locationIP, p.browserUsed
      """
    Then the result should be, in any order:
      | p.id | p.locationIP   | p.browserUsed |
      | 1    | "192.168.1.1"  | "Firefox"     |
      | 10   | "192.168.1.10" | "Chrome"      |
      | 19   | "192.168.1.19" | "Firefox"     |
    # Batch SET UPDATE edge properties using table_split
    When executing analytic query:
      """
      VALUE fmt_edge_update = "
        TABLE t TYPED TABLE {src_id INT, dst_id INT, creation_date STRING} = %s
        USE ldbc_analytic_batch_test
        FOR r IN t
        MATCH (p1@Person{id:r.src_id})-[k@KNOWS]->(p2@Person{id:r.dst_id})
        SET k.creationDate = local_datetime(r.creation_date)"

      TABLE edge_updates {src_id INT, dst_id INT, creation_date STRING}

      FOR i in range(1, 15)
      EXPORT i, i + 1, '2024-01-' || cast(i as STRING) || 'T12:00:00' INTO edge_updates

      FOR split IN table_split(edge_updates, CAST(8 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_edge_update, to_literal(split))) FINISH
      """
    Then the execution should be successful
    # Verify batch edge property updates
    When executing query:
      """
      USE ldbc_analytic_batch_test
      MATCH (p1@Person)-[k@KNOWS]->(p2@Person)
      WHERE p1.id IN [1, 7, 14] AND p2.id = p1.id + 1
      RETURN p1.id, p2.id, k.creationDate
      """
    Then the result should be, in any order:
      | p1.id | p2.id | k.creationDate                 |
      | 1     | 2     | DATETIME "2024-01-01T12:00:00" |
      | 7     | 8     | DATETIME "2024-01-07T12:00:00" |
      | 14    | 15    | DATETIME "2024-01-14T12:00:00" |
    # Batch DELETE edges using table_split
    When executing analytic query:
      """
      VALUE fmt_delete_edge = "
        TABLE t TYPED TABLE {person_id INT, tag_id INT} = %s
        USE ldbc_analytic_batch_test
        FOR r IN t
        MATCH (p@Person{id:r.person_id})-[hi@HAS_INTEREST]->(tag@Tag{id:r.tag_id})
        DELETE hi"

      TABLE edges_to_delete {person_id INT, tag_id INT}

      FOR i in range(1, 10)
      EXPORT i, (i % 30) + 1 INTO edges_to_delete

      FOR split IN table_split(edges_to_delete, CAST(5 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_delete_edge, to_literal(split))) FINISH
      """
    Then the execution should be successful
    # Verify batch edge deletions
    When executing query:
      """
      USE ldbc_analytic_batch_test
      MATCH ()-[hi@HAS_INTEREST]->()
      RETURN count(*) AS remaining_interest
      """
    Then the result should be, in any order:
      | remaining_interest |
      | 10                 |
    # Batch DELETE nodes using table_split
    When executing analytic query:
      """
      VALUE fmt_delete_tag = "
        TABLE t TYPED TABLE {id INT} = %s
        USE ldbc_analytic_batch_test
        FOR r IN t
        MATCH (tag@Tag{id:r.id})
        DELETE tag"

      TABLE tags_to_delete {id INT}

      FOR i in range(2, 11)
      EXPORT i INTO tags_to_delete

      FOR split IN table_split(tags_to_delete, CAST(5 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_delete_tag, to_literal(split))) FINISH
      """
    Then the execution should be successful
    # Verify batch node deletions
    When executing query:
      """
      USE ldbc_analytic_batch_test
      MATCH (t@Tag)
      RETURN count(*) AS remaining_tags
      """
    Then the result should be, in any order:
      | remaining_tags |
      | 20             |
    # Batch DETACH DELETE nodes using table_split
    When executing analytic query:
      """
      VALUE fmt_detach_delete = "
        TABLE t TYPED TABLE {id INT} = %s
        USE ldbc_analytic_batch_test
        FOR r IN t
        MATCH (p@Person{id:r.id})
        DETACH DELETE p"

      TABLE persons_to_delete {id INT}

      FOR i in range(41, 50)
      EXPORT i INTO persons_to_delete

      FOR split IN table_split(persons_to_delete, CAST(5 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_detach_delete, to_literal(split))) FINISH
      """
    Then the execution should be successful
    # Verify batch DETACH DELETE
    When executing query:
      """
      USE ldbc_analytic_batch_test
      MATCH (p@Person)
      RETURN count(*) AS remaining_persons
      """
    Then the result should be, in any order:
      | remaining_persons |
      | 40                |
    # Drop graph
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "DROP GRAPH IF EXISTS ldbc_analytic_batch_test") FINISH
      """
    Then the execution should be successful

  @non_tls
  Scenario: DML operations using distributed table with nebula_exec
    # Create remote graph
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ldbc_analytic_distributed_test TYPED ldbc_type
      """
    Then the execution should be successful
    And graph "ldbc_analytic_distributed_test" should be ready to use
    # Import data to remote graph to create a large dataset
    When executing query:
      """
      TABLE persons {id INT, firstName STRING, lastName STRING, gender STRING, birthday DATE}

      FOR i in range(1, 30)
      EXPORT i, "Person" || CAST(i as STRING), "Last" || CAST(i as STRING),
             CASE WHEN i % 2 = 0 THEN "female" ELSE "male" END,
             date("1990-01-01", "%Y-%m-%d") + duration({days: i - 1})
      INTO persons

      USE ldbc_analytic_distributed_test
      FOR p IN persons
      INSERT OR REPLACE (@Person{id:p.id, firstName:p.firstName, lastName:p.lastName, gender:p.gender, birthday:p.birthday})
      """
    Then the execution should be successful
    # Insert Tag nodes into remote graph
    When executing query:
      """
      TABLE tags {id INT, name STRING, url STRING}

      FOR i in range(101, 120)
      EXPORT i, "Tag" || CAST(i as STRING), "http://tag" || CAST(i as STRING) || ".com"
      INTO tags

      USE ldbc_analytic_distributed_test
      FOR t IN tags
      INSERT OR REPLACE (@Tag{id:t.id, name:t.name, url:t.url})
      """
    Then the execution should be successful
    # Insert KNOWS edges into remote graph
    When executing query:
      """
      TABLE knows_edges {src INT, dst INT}

      FOR i in range(1, 9)
      EXPORT i, i + 1 INTO knows_edges

      FOR i in range(11, 15)
      EXPORT i, i + 1 INTO knows_edges

      USE ldbc_analytic_distributed_test
      FOR e IN knows_edges
      MATCH (p1@Person{id:e.src})
      MATCH (p2@Person{id:e.dst})
      INSERT OR REPLACE (p1)-[@KNOWS{creationDate:local_datetime('2024-01-01T10:00:00')}]->(p2)
      """
    Then the execution should be successful
    # Insert HAS_INTEREST edges into remote graph
    When executing query:
      """
      TABLE interest_edges {person_id INT, tag_id INT}

      FOR i in range(1, 12)
      EXPORT i, 100 + i INTO interest_edges

      USE ldbc_analytic_distributed_test
      FOR e IN interest_edges
      MATCH (p@Person{id:e.person_id})
      MATCH (t@Tag{id:e.tag_id})
      INSERT OR REPLACE (p)-[@HAS_INTEREST{}]->(t)
      """
    Then the execution should be successful
    # Create temporary graph and import data from remote graph
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #ldbc_analytic_distributed_test TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #ldbc_analytic_distributed_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc_analytic_distributed_test"
        }
      }
      """
    Then the execution should be successful
    # Batch INSERT new Person nodes using distributed table + nebula_exec
    When executing analytic query:
      """
      USE #ldbc_analytic_distributed_test {
      TABLE new_person_data {id INT, firstName STRING, lastName STRING, gender STRING} PARTITION BY DEFAULT
      VALUE fmt_insert_person = "
        TABLE t TYPED TABLE {id INT, firstName STRING, lastName STRING, gender STRING} = %s
        USE ldbc_analytic_distributed_test
        FOR r IN t
        INSERT OR REPLACE (@Person{id:r.id, firstName:r.firstName, lastName:r.lastName, gender:r.gender, birthday:date('2000-01-01')})"

      MATCH (p@Person)
      PER NODE (p) {
        EXPORT p.id + 100, "NewPerson" || CAST(p.id as STRING), "NewLast" || CAST(p.id as STRING), p.gender INTO new_person_data
      }

      FOR split IN table_split(new_person_data, CAST(4 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_insert_person, to_literal(split))) FINISH
      }
      """
    Then the execution should be successful
    # Verify newly inserted Person nodes
    When executing query:
      """
      USE ldbc_analytic_distributed_test
      MATCH (p@Person)
      WHERE p.id > 100
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 30  |
    # Batch INSERT new edges using distributed table + nebula_exec
    When executing analytic query:
      """
      USE #ldbc_analytic_distributed_test {
      TABLE new_interest_data {person_id INT, tag_id INT} PARTITION BY DEFAULT
      VALUE fmt_insert_edge = "
        TABLE t TYPED TABLE {person_id INT, tag_id INT} = %s
        USE ldbc_analytic_distributed_test
        FOR r IN t
        MATCH (p@Person{id:r.person_id})
        MATCH (tag@Tag{id:r.tag_id})
        INSERT OR REPLACE (p)-[@HAS_INTEREST{}]->(tag)"

      MATCH (p@Person)-[@HAS_INTEREST]->(t@Tag)
      PER PATH {
        EXPORT p.id + 100, t.id INTO new_interest_data
      }

      FOR split IN table_split(new_interest_data, CAST(2 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_insert_edge, to_literal(split))) FINISH
      }
      """
    Then the execution should be successful
    # Verify newly inserted edges
    When executing query:
      """
      USE ldbc_analytic_distributed_test
      MATCH (p@Person)-[@HAS_INTEREST]->(t@Tag)
      WHERE p.id > 100
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 12  |
    When executing analytic query:
      """
      USE #ldbc_analytic_distributed_test {
      TABLE update_data {id INT, locationIP STRING, browserUsed STRING} PARTITION BY DEFAULT
      VALUE fmt_update_query = "
        TABLE t TYPED TABLE {id INT, locationIP STRING, browserUsed STRING} = %s
        USE ldbc_analytic_distributed_test
        FOR r IN t
        MATCH (p@Person{id:r.id})
        SET p.locationIP = r.locationIP, p.browserUsed = r.browserUsed"

      MATCH (p@Person)
      PER NODE (p) {
        EXPORT p.id, "10.0.0." || CAST(p.id as STRING), CASE WHEN p.id % 3 = 0 THEN "Chrome" ELSE "Firefox" END INTO update_data
      }

      FOR split IN table_split(update_data, CAST(4 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_update_query, to_literal(split))) FINISH
      }
      """
    Then the execution should be successful
    # Verify Person node property updates
    When executing query:
      """
      USE ldbc_analytic_distributed_test
      MATCH (p@Person)
      WHERE p.id IN [1, 3, 9]
      RETURN p.id, p.locationIP, p.browserUsed
      """
    Then the result should be, in any order:
      | p.id | p.locationIP | p.browserUsed |
      | 1    | "10.0.0.1"   | "Firefox"     |
      | 3    | "10.0.0.3"   | "Chrome"      |
      | 9    | "10.0.0.9"   | "Chrome"      |
    # Batch SET UPDATE KNOWS edge properties using distributed table
    When executing analytic query:
      """
      USE #ldbc_analytic_distributed_test {
      TABLE edge_update_data {src_id INT, dst_id INT} PARTITION BY DEFAULT
      VALUE fmt_edge_update = "
        TABLE t TYPED TABLE {src_id INT, dst_id INT} = %s
        USE ldbc_analytic_distributed_test
        FOR r IN t
        MATCH (p1@Person{id:r.src_id})-[k@KNOWS]->(p2@Person{id:r.dst_id})
        SET k.creationDate = local_datetime('2025-06-15T14:30:00')"

      MATCH (p1@Person)-[@KNOWS]->(p2@Person)
      PER PATH {
        EXPORT p1.id, p2.id INTO edge_update_data
      }

      FOR split IN table_split(edge_update_data, CAST(3 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_edge_update, to_literal(split))) FINISH
      }
      """
    Then the execution should be successful
    # Verify edge property updates (sample verification)
    When executing query:
      """
      USE ldbc_analytic_distributed_test
      MATCH (p1@Person)-[k@KNOWS]->(p2@Person)
      WHERE k.creationDate = local_datetime('2025-06-15T14:30:00')
      RETURN count(*) AS updated_count
      """
    Then the result should be, in any order:
      | updated_count |
      | 14            |
    # Batch DELETE HAS_INTEREST edges using distributed table
    When executing analytic query:
      """
      USE #ldbc_analytic_distributed_test {
      TABLE delete_edge_data {person_id INT, tag_id INT} PARTITION BY DEFAULT
      VALUE fmt_delete_edge = "
        TABLE t TYPED TABLE {person_id INT, tag_id INT} = %s
        USE ldbc_analytic_distributed_test
        FOR r IN t
        MATCH (p@Person{id:r.person_id})-[hi@HAS_INTEREST]->(tag@Tag{id:r.tag_id})
        DELETE hi"

      MATCH (p@Person)-[@HAS_INTEREST]->(tag@Tag)
      PER PATH {
        EXPORT p.id, tag.id INTO delete_edge_data
      }

      FOR split IN table_split(delete_edge_data, CAST(3 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_delete_edge, to_literal(split))) FINISH
      }
      """
    Then the execution should be successful
    # Verify edge deletions
    When executing query:
      """
      USE ldbc_analytic_distributed_test
      MATCH ()-[hi@HAS_INTEREST]->()
      RETURN count(*) AS remaining_interest
      """
    Then the result should be, in any order:
      | remaining_interest |
      | 12                 |
    # Batch DETACH DELETE Person nodes using distributed table
    When executing analytic query:
      """
      USE #ldbc_analytic_distributed_test {
      TABLE detach_delete_data {id INT} PARTITION BY DEFAULT
      VALUE fmt_detach_delete = "
        TABLE t TYPED TABLE {id INT} = %s
        USE ldbc_analytic_distributed_test
        FOR r IN t
        MATCH (p@Person{id:r.id})
        DETACH DELETE p"

      MATCH (p@Person)
      PER NODE (p) {
        EXPORT p.id INTO detach_delete_data
      }

      FOR split IN table_split(detach_delete_data, CAST(7 as UINT))
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_detach_delete, to_literal(split))) FINISH
      }
      """
    Then the execution should be successful
    # Verify Person node deletions
    When executing query:
      """
      USE ldbc_analytic_distributed_test
      MATCH (p@Person)
      RETURN count(*) AS remaining_persons
      """
    Then the result should be, in any order:
      | remaining_persons |
      | 30                |
    # Drop graph
    When executing analytic query:
      """
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", "DROP GRAPH IF EXISTS ldbc_analytic_distributed_test") FINISH
      """
    Then the execution should be successful
    And drop the graph "#ldbc_analytic_distributed_test"

  @non_tls
  Scenario: DML operations with empty table
    # Try to insert nodes from empty table using to_literal
    When executing analytic query:
      """
      TABLE empty_persons TYPED TABLE {id INT, firstName STRING, lastName STRING, gender STRING}
      VALUE fmt_insert = "
        TABLE t TYPED TABLE {id INT, firstName STRING, lastName STRING, gender STRING} = %s
        USE ldbc
        FOR r IN t
        INSERT (p@Person{id:r.id, firstName:r.firstName, lastName:r.lastName, gender:r.gender})"
      CALL nebula_exec("nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}", fmt(fmt_insert, to_literal(empty_persons))) FINISH
      """
    Then the execution should be successful
    # Verify no additional nodes were inserted
    When executing query:
      """
      USE ldbc
      MATCH (p@Person)
      RETURN count(*) AS person_count
      """
    Then the result should be, in any order:
      | person_count |
      | 4            |
