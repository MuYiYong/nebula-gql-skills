# Copyright (c) 2025 vesoft inc. All rights reserved.
@yc
Feature: Dry Run Temporary graph

  Scenario: Dry Run Subgraph
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_gt_tempoary_graph_pbd AS {
      NODE person (LABEL person {id INT PRIMARY KEY}),
      NODE dog (LABEL dog {id INT PRIMARY KEY}),
      EDGE bought (person)-[LABEL bought]->(dog)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH IF NOT EXISTS dry_run_g_tempoary_graph_pbd TYPED dry_run_gt_tempoary_graph_pbd
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE dry_run_g_tempoary_graph_pbd
      INSERT (@person {id:1}), (@person {id: 2}), (@dog {id: 3}), (@dog {id: 4})
      """
    Then the execution should be successful
    When executing query:
      """
      USE dry_run_g_tempoary_graph_pbd MATCH (p) return p.id
      """
    Then the result should be, in any order:
      | p.id |
    When executing query:
      """
      USE dry_run_g_tempoary_graph_pbd
      INSERT (@person {id:1}), (@person {id: 2}), (@dog {id: 3}), (@dog {id: 4})
      """
    Then the execution should be successful
    When executing query:
      """
      USE dry_run_g_tempoary_graph_pbd
      MATCH (p:person {id:1}), (d3:dog {id:3}), (d4:dog {id:4})
      INSERT (p)-[@bought]->(d3), (p)-[@bought]->(d4)
      """
    Then the execution should be successful
    When executing query:
      """
      USE dry_run_g_tempoary_graph_pbd MATCH (u)-[]->(v) return u.id, v.id
      """
    Then the result should be, in any order:
      | u.id | v.id |
      | 1    | 3    |
      | 1    | 4    |
    # without properties
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_p_tempoary_graph_pbd AS COPY OF dry_run_g_tempoary_graph_pbd OPTIONS {without_properties: true, immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #dry_run_p_tempoary_graph_pbd SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
    And drop the graph "#dry_run_p_tempoary_graph_pbd"
    When executing query:
      """
      CREATE TEMPORARY GRAPH #dry_run_p_tempoary_graph_pbd AS COPY OF dry_run_g_tempoary_graph_pbd OPTIONS {without_properties: true, immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #dry_run_p_tempoary_graph_pbd SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 4         |
      | "Edge Total" | "Edge"       | 2         |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_p_tempoary_graph_pbd
      MATCH ()-[]->()
      RETURN count(*) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 0   |
    When executing query:
      """
      USE #dry_run_p_tempoary_graph_pbd
      MATCH ()-[]->()
      RETURN count(*) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 2   |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_p_tempoary_graph_pbd
      MATCH (v {id:1})
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
    When executing query:
      """
      USE #dry_run_p_tempoary_graph_pbd
      MATCH (v {id:1})
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    And drop the graph "#dry_run_p_tempoary_graph_pbd"
    # all nodes
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_p_tempoary_graph_pbd AS COPY OF
      GRAPH { USE dry_run_g_tempoary_graph_pbd MATCH (v) RETURN v } OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #dry_run_p_tempoary_graph_pbd
      MATCH ()
      RETURN count(*) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 0   |
    And drop the graph "#dry_run_p_tempoary_graph_pbd"
    # all dogs
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_p_tempoary_graph_pbd AS COPY OF
      GRAPH { USE dry_run_g_tempoary_graph_pbd MATCH (d:dog) RETURN d } OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #dry_run_p_tempoary_graph_pbd
      MATCH ()
      RETURN count(*) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 0   |
    And drop the graph "#dry_run_p_tempoary_graph_pbd"
    # all person 1 related
    When executing query:
      """
      CREATE TEMPORARY GRAPH #dry_run_p_tempoary_graph_pbd AS COPY OF
      GRAPH { USE dry_run_g_tempoary_graph_pbd MATCH (p:person {id:1})-[b]->(d) RETURN p, b, d }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_p_tempoary_graph_pbd
      MATCH (v)
      RETURN v.id AS id
      """
    Then the result should be, in any order:
      | id |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_p_tempoary_graph_pbd
      MATCH ()-[]->(d)
      RETURN d.id AS id
      """
    Then the result should be, in any order:
      | id |
    And drop the graph "#dry_run_p_tempoary_graph_pbd"
    And drop the graph "dry_run_g_tempoary_graph_pbd"
    And drop the graph type "dry_run_gt_tempoary_graph_pbd"

  Scenario: Mutable Subgraph
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_gt_mutable_temp_graph_pbd AS {
      NODE person (LABEL person {id INT PRIMARY KEY, name string, age int}),
      NODE dog (LABEL dog {id INT PRIMARY KEY, name string}),
      EDGE bought (person)-[LABEL bought {year:: int}]->(dog)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH IF NOT EXISTS dry_run_g_mutable_temp_graph_pbd TYPED dry_run_gt_mutable_temp_graph_pbd
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE dry_run_g_mutable_temp_graph_pbd
      INSERT (@person {id:1, name: "alice", age: 20}), (@person {id: 2, name: "bob", age: 21}), (@dog {id: 3, name: "dog1"}), (@dog {id: 4, name: "dog2"})
      """
    Then the execution should be successful
    When executing query:
      """
      USE dry_run_g_mutable_temp_graph_pbd MATCH (p) return p.id
      """
    Then the result should be, in any order:
      | p.id |
    When executing query:
      """
      USE dry_run_g_mutable_temp_graph_pbd
      INSERT (@person {id:1, name: "alice", age: 20}), (@person {id: 2, name: "bob", age: 21}), (@dog {id: 3, name: "dog1"}), (@dog {id: 4, name: "dog2"})
      """
    Then the execution should be successful
    When executing query:
      """
      USE dry_run_g_mutable_temp_graph_pbd MATCH (p) return count(p) AS num
      """
    Then the result should be, in any order:
      | num |
      | 4   |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE dry_run_g_mutable_temp_graph_pbd MATCH (p) return count(p) AS num
      """
    Then the result should be, in any order:
      | num |
      | 0   |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE dry_run_g_mutable_temp_graph_pbd
      MATCH (p:person {id:1}), (d3:dog {id:3}), (d4:dog {id:4})
      INSERT (p)-[@bought {year: 2023}]->(d3), (p)-[@bought {year: 2024}]->(d4)
      """
    Then the execution should be successful
    When executing query:
      """
      USE dry_run_g_mutable_temp_graph_pbd MATCH (u)-[e]->(v) return count(e) AS num
      """
    Then the result should be, in any order:
      | num |
      | 0   |
    When executing query:
      """
      USE dry_run_g_mutable_temp_graph_pbd
      MATCH (p:person {id:1}), (d3:dog {id:3}), (d4:dog {id:4})
      INSERT (p)-[@bought {year: 2023}]->(d3), (p)-[@bought {year: 2024}]->(d4)
      """
    Then the execution should be successful
    When executing query:
      """
      USE dry_run_g_mutable_temp_graph_pbd MATCH (u)-[e]->(v) return count(e) AS num
      """
    Then the result should be, in any order:
      | num |
      | 2   |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE dry_run_g_mutable_temp_graph_pbd MATCH (u)-[e]->(v) return count(e) AS num
      """
    Then the result should be, in any order:
      | num |
      | 0   |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_p_mutable_temp_graph_pbd AS COPY OF dry_run_g_mutable_temp_graph_pbd
      """
    Then the execution should be successful
    When executing query:
      """
      USE #dry_run_p_mutable_temp_graph_pbd SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
      | "person"     | "Node"       | 0         |
      | "dog"        | "Node"       | 0         |
      | "bought"     | "Edge"       | 0         |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_p_mutable_temp_graph_pbd AS COPY OF dry_run_g_mutable_temp_graph_pbd
      """
    Then an Error should be raised: "[NR122]: Temporary graph already existed"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_p_mutable_temp_graph_pbd AS COPY OF dry_run_g_mutable_temp_graph_pbd
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_mut_graph_without_properties AS COPY OF dry_run_g_mutable_temp_graph_pbd OPTIONS {without_properties: true}
      """
    Then the execution should be successful
    # When without_properties is set, PK properties remain
    When executing query:
      """
      USE #dry_run_mut_graph_without_properties
      MATCH (v) RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_p_mutable_temp_graph_pbd
      INSERT (a@person {id:5, name: "charlie", age: 22}), (b@dog {id:5, name: "dog3"}), (a)-[@bought {year: 2025}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_p_mutable_temp_graph_pbd SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
      | "person"     | "Node"       | 0         |
      | "dog"        | "Node"       | 0         |
      | "bought"     | "Edge"       | 0         |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_p_mutable_temp_graph_pbd
      MATCH (v)-[e]->(v2) return v.id, v.name, v.age, e.year, v2.id, v2.name
      """
    Then the result should be, in any order:
      | v.id | v.name | v.age | e.year | v2.id | v2.name |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_p_mutable_temp_graph_pbd
      MATCH (v)-[e]->(v2)
      SET v.age = v.age + 10, e.year = e.year + 20
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_p_mutable_temp_graph_pbd
      MATCH (v)-[e]->(v2)
      RETURN v.id, v.name, v.age, e.year, v2.id, v2.name
      """
    Then the result should be, in any order:
      | v.id | v.name | v.age | e.year | v2.id | v2.name |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_p_mutable_temp_graph_pbd
      INSERT (p@person {id:6, name: "david", age: 23}), (d@dog {id:6, name: "dog4"})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_p_mutable_temp_graph_pbd
      MATCH (a)-[e]->(b)
      DELETE a, e, b
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_mut_subquery_graph AS COPY OF
      GRAPH { USE dry_run_g_mutable_temp_graph_pbd MATCH (p:person {id:1})-[b]->(d) RETURN p, b, d }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_subquery_graph
      MATCH (v)
      RETURN v.id AS id
      """
    Then the result should be, in any order:
      | id |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_subquery_graph
      INSERT (v1@person {id:11, name: "alice11", age: 20}), (v2@person {id: 12, name: "bob12", age: 21}), (d1@dog {id: 13, name: "dog13"}),
      (v1)-[e:bought {year: 2023}]->(d1)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_subquery_graph
      MATCH (v)-[e]->(v2)
      RETURN v.id, v2.id, e.year
      """
    Then the result should be, in any order:
      | v.id | v2.id | e.year |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_mut_empty_graph TYPED dry_run_gt_mutable_temp_graph_pbd
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_empty_graph
      INSERT (v1@person {id:1, name: "alice", age: 20}), (v2@person {id: 2, name: "bob", age: 21}), (d1@dog {id: 3, name: "dog1"}),
      (v1)-[e:bought {year: 2023}]->(d1)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_empty_graph
      MATCH (p)-[e]->(d)
      RETURN p.id, d.id, e.year
      """
    Then the result should be, in any order:
      | p.id | d.id | e.year |
    And drop the graph "#dry_run_mut_empty_graph"
    And drop the graph "#dry_run_mut_subquery_graph"
    And drop the graph "#dry_run_p_mutable_temp_graph_pbd"
    And drop the graph "dry_run_g_mutable_temp_graph_pbd"
    And drop the graph type "dry_run_gt_mutable_temp_graph_pbd"

  Scenario: Mutable temporary graph indexes
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_gt_temp_index_test AS {
      NODE person (LABEL person {id INT PRIMARY KEY, age INT, name STRING}),
      EDGE knows (person)-[LABEL knows {weight INT}]->(person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH IF NOT EXISTS dry_run_g_temp_index_test TYPED dry_run_gt_temp_index_test
      """
    Then the execution should be successful
    # Insert test data into disk graph
    When executing query:
      """
      USE dry_run_g_temp_index_test
      INSERT (p1@person {id:1, age:25, name:"Alice"}),
      (p2@person {id:2, age:30, name:"Bob"}),
      (p3@person {id:3, age:25, name:"Charlie"}),
      (p4@person {id:4, age:35, name:"David"}),
      (p1)-[@knows {weight:80}]->(p2),
      (p2)-[@knows {weight:90}]->(p3),
      (p3)-[@knows {weight:85}]->(p4)
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE dry_run_g_temp_index_test CREATE INDEX IF NOT EXISTS person_name_idx ON NODE person(id)
      """
    Then the execution should be successful
    # Create mutable temporary graph from disk graph - should inherit primary key index automatically
    When executing query:
      """
      CREATE TEMPORARY GRAPH #dry_run_temp_index_graph AS COPY OF dry_run_g_temp_index_test
      """
    Then the execution should be successful
    # Note: Only primary key index of original graph is automatically inherited by temporary graph while `SHOW INDEXES` only show non-primary key indexes, so the result is empty
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph SHOW INDEXES
      """
    Then the result should be, in any order:
      | name | state | index_type | schema | graph_name | entity_type | element_type | properties |
    # Create indexes directly on the temporary graph
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph CREATE INDEX IF NOT EXISTS person_age_idx ON NODE person(age)
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph CREATE INDEX IF NOT EXISTS person_non_exist_prop_idx ON NODE person(non_exist_prop)
      """
    Then an Error should be raised: "[NC006]: Property `non_exist_prop` of type `person` not found"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph CREATE INDEX IF NOT EXISTS person_age_name_idx ON NODE person(age, name)
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph CREATE INDEX IF NOT EXISTS knows_weight_idx ON EDGE knows(weight)
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph SHOW INDEXES
      """
    Then the result should be, in any order:
      | name                  | state   | index_type | schema        | graph_name                  | entity_type | element_type | properties                  |
      | "person_age_idx"      | "Valid" | "Normal"   | "/tmp_schema" | "#dry_run_temp_index_graph" | "Node"      | "person"     | LIST ["age ASC"]            |
      | "person_age_name_idx" | "Valid" | "Normal"   | "/tmp_schema" | "#dry_run_temp_index_graph" | "Node"      | "person"     | LIST ["age ASC","name ASC"] |
      | "knows_weight_idx"    | "Valid" | "Normal"   | "/tmp_schema" | "#dry_run_temp_index_graph" | "Edge"      | "knows"      | LIST ["weight ASC"]         |
    # Test primary key index query (should work automatically)
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph
      MATCH (p:person {id:2})
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name | p.age |
    And the plan should contain "IndexScan"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph
      MATCH (p:person) WHERE p.age = 25
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name | p.age |
    And the plan should contain "IndexScan"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph
      MATCH (p:person) WHERE p.age = 25 AND p.name = "Alice"
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name | p.age |
    And the plan should contain "IndexScan"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph
      MATCH (p1:person)-[k:knows WHERE k.weight = 90]->(p2:person)
      RETURN p1.name, p2.name, k.weight
      """
    Then the result should be, in any order:
      | p1.name | p2.name | k.weight |
    And the plan should contain "IndexScan"
    # Insert more data to test index updates
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph
      INSERT (p5@person {id:5, age:28, name:"Eve"}),
      (p6@person {id:6, age:25, name:"Frank"}),
      (p5)-[@knows {weight:95}]->(p6)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    # Test index still works after insertion
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph
      MATCH (p:person) WHERE p.age = 25
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name | p.age |
    And the plan should contain "IndexScan"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph
      MATCH (p1:person)-[k:knows]->(p2:person) WHERE k.weight = 95
      RETURN p1.name, p2.name, k.weight
      """
    Then the result should be, in any order:
      | p1.name | p2.name | k.weight |
    And the plan should contain "IndexScan"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph
      MATCH (p:person) WHERE p.age >= 25 AND p.age <= 30
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name | p.age |
    And the plan should contain "IndexScan"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph
      MATCH (p1:person)-[k:knows]->(p2:person) WHERE k.weight >= 85 AND k.weight <= 95
      RETURN p1.name, p2.name, k.weight
      """
    Then the result should be, in any order:
      | p1.name | p2.name | k.weight |
    And the plan should contain "IndexScan"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph
      MATCH (p:person/*+ index(person_age_idx) */) WHERE p.age = 25
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name | p.age |
    # drop and recreate same index name should succeed
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph DROP INDEX person_age_idx
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph CREATE INDEX person_age_idx ON NODE person(age)
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_temp_index_graph
      MATCH (p:person/*+ index(person_age_name_idx) */) WHERE p.age = 25
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name | p.age |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_empty_temp_index TYPED dry_run_gt_temp_index_test
      """
    Then the execution should be successful
    # Create indexes on empty temporary graph
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_empty_temp_index CREATE INDEX IF NOT EXISTS empty_person_age_idx ON NODE person(age)
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_empty_temp_index CREATE INDEX IF NOT EXISTS empty_knows_weight_idx ON EDGE knows(weight)
      """
    Then the execution should be successful
    # Insert data into empty temporary graph
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_empty_temp_index
      INSERT (p1@person {id:1, age:20, name:"Alice"}),
      (p2@person {id:2, age:25, name:"Bob"}),
      (p1)-[@knows {weight:70}]->(p2)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    # Test indexes work on empty graph after data insertion
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_empty_temp_index
      MATCH (p:person) WHERE p.age = 20
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name | p.age |
    And the plan should contain "IndexScan"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_empty_temp_index
      MATCH (p1:person)-[k:knows]->(p2:person) WHERE k.weight = 70
      RETURN p1.name, p2.name, k.weight
      """
    Then the result should be, in any order:
      | p1.name | p2.name | k.weight |
    And the plan should contain "IndexScan"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_analytic_ldbc_immutable AS COPY OF ldbc OPTIONS {immutable:true}
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_analytic_ldbc_immutable CREATE INDEX IF NOT EXISTS dist_graph_person_last_name_idx ON NODE Person(lastName)
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Create index is not supported for immutable temporary graph"
    And drop the graph "#dry_run_analytic_ldbc_immutable"
    And drop the graph "#dry_run_empty_temp_index"
    And drop the graph "#dry_run_temp_index_graph"
    And drop the graph "dry_run_g_temp_index_test"
    And drop the graph type "dry_run_gt_temp_index_test"

  Scenario: Unsupported
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_const_ldbc_mem AS COPY OF ldbc OPTIONS {immutable: true}
      """
    Then the execution should be successful
    # insert
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_const_ldbc_mem
      INSERT (@Person {id:11})
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: insert on immutable temporary graph"
    # set
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_const_ldbc_mem
      MATCH (v:Person)
      SET v.id = v.id+5
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: set on immutable temporary graph"
    # delete
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_const_ldbc_mem
      MATCH (a:Person{id:1})
      DELETE a
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: delete on immutable temporary graph"
    And drop the graph "#dry_run_const_ldbc_mem"

  Scenario: Temp of temp
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_temp_of_temp AS COPY OF #analytic_ldbc OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_temp_of_temp_sub AS COPY OF
      GRAPH { USE #dry_run_temp_of_temp MATCH (v) RETURN v } OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                        | graph_type  | schema        | owner  | extra               |
      | "#dry_run_temp_of_temp"     | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
      | "#dry_run_temp_of_temp_sub" | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
    And drop the graph "#dry_run_temp_of_temp_sub"
    And drop the graph "#dry_run_temp_of_temp"

  Scenario: DDL on empty temp graph
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_temp_graph_type_ddl AS {
      NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
      EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_empty_temp_graph TYPED dry_run_temp_graph_type_ddl OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                        | graph_type                    | schema        | owner  | extra               |
      | "#dry_run_empty_temp_graph" | "dry_run_temp_graph_type_ddl" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_empty_temp_graph SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_empty_temp_graph IMPORT INTO GRAPH
      {
      NODE (v@player{id:id, name:name}) FROM DATAFILE {
      FORMAT:"csv",
      PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.v",
      delimiter: " "
      },
      EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
      FORMAT:"csv",
      PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.e",
      delimiter: " "
      }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_empty_temp_graph SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
    And drop the graph "#dry_run_empty_temp_graph"
    And drop the graph type "dry_run_temp_graph_type_ddl"

  Scenario: Import into mutable temporary graph from CSV
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_mut_graph_type_csv AS {
      NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
      EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_mut_graph_csv TYPED dry_run_mut_graph_type_csv
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_graph_csv IMPORT INTO GRAPH
      {
      NODE (v@player{id:id, name:name}) FROM DATAFILE {
      FORMAT:"csv",
      PATH:"file://${TEST_DIR}/dataset/external_source/empty_graph_csv_comma/empty_graph_csv_comma.v",
      delimiter: " "
      },
      EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
      FORMAT:"csv",
      PATH:"file://${TEST_DIR}/dataset/external_source/empty_graph_csv_comma/empty_graph_csv_comma.e",
      delimiter: " "
      }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_graph_csv SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
      | "player"     | "Node"       | 0         |
      | "follow"     | "Edge"       | 0         |
    # Create non-PK indexes on the empty mutable temp graph, they must persist across IMPORT
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_graph_csv CREATE INDEX IF NOT EXISTS player_name_idx ON NODE player(name)
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_graph_csv CREATE INDEX IF NOT EXISTS follow_score_idx ON EDGE follow(score)
      """
    Then the execution should be successful
    # Verify indexes exist before import
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_graph_csv SHOW INDEXES
      """
    Then the result should be, in any order:
      | name               | state   | index_type | schema        | graph_name               | entity_type | element_type | properties         |
      | "player_name_idx"  | "Valid" | "Normal"   | "/tmp_schema" | "#dry_run_mut_graph_csv" | "Node"      | "player"     | LIST ["name ASC"]  |
      | "follow_score_idx" | "Valid" | "Normal"   | "/tmp_schema" | "#dry_run_mut_graph_csv" | "Edge"      | "follow"     | LIST ["score ASC"] |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_graph_csv IMPORT INTO GRAPH
      {
      NODE (v@player{id:id, name:name}) FROM DATAFILE {
      FORMAT:"csv",
      PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.v",
      delimiter: " "
      },
      EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
      FORMAT:"csv",
      PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.e",
      delimiter: " "
      }
      }
      """
    Then the execution should be successful
    # Verify indexes still exist after import
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_graph_csv SHOW INDEXES
      """
    Then the result should be, in any order:
      | name               | state   | index_type | schema        | graph_name               | entity_type | element_type | properties         |
      | "player_name_idx"  | "Valid" | "Normal"   | "/tmp_schema" | "#dry_run_mut_graph_csv" | "Node"      | "player"     | LIST ["name ASC"]  |
      | "follow_score_idx" | "Valid" | "Normal"   | "/tmp_schema" | "#dry_run_mut_graph_csv" | "Edge"      | "follow"     | LIST ["score ASC"] |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_graph_csv SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
      | "player"     | "Node"       | 0         |
      | "follow"     | "Edge"       | 0         |
    And drop the graph "#dry_run_mut_graph_csv"
    And drop the graph type "dry_run_mut_graph_type_csv"
    # Import into mutable temporary graph with wrong delimiter
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_mut_graph_type_csv_err AS {
      NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
      EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_mut_graph_csv_wrong_delimiter TYPED dry_run_mut_graph_type_csv_err
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_graph_csv_wrong_delimiter IMPORT INTO GRAPH
      {
      NODE (v@player{id:id, name:name}) FROM DATAFILE {
      FORMAT:"csv",
      PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v",
      delimiter: " ",
      include_columns: ["id","name"]
      },
      EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
      FORMAT:"csv",
      PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
      }
      }
      """
    Then the execution should be successful
    # NOTE: dry run can not detect data error
    # Then an Error should be raised: "error: Key error: Column 'id' in include_columns does not exist in CSV file"
    And drop the graph "#dry_run_mut_graph_csv_wrong_delimiter"
    And drop the graph type "dry_run_mut_graph_type_csv_err"

  Scenario: Invalid options for temporary graph
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_gt_temp_graph_opts AS {
      NODE person (LABEL person {id INT PRIMARY KEY})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH IF NOT EXISTS dry_run_g_temp_graph_opts TYPED dry_run_gt_temp_graph_opts
      """
    Then the execution should be successful
    # PRIMARY_KEY_AS_NODE_ID on non-CSR (mutable, single-machine)
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_opt_err_pk AS COPY OF dry_run_g_temp_graph_opts OPTIONS { primary_key_as_node_id: true }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: PRIMARY_KEY_AS_NODE_ID"
    # WITHOUT_PROPERTIES with subquery projection
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_opt_err_drop_prop_sub AS COPY OF GRAPH { USE dry_run_g_temp_graph_opts MATCH (v) RETURN v } OPTIONS { without_properties: true }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: WITHOUT_PROPERTIES is only allowed with full graph projection"
    # WITHOUT_PROPERTIES with empty projection
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_opt_err_drop_prop_empty TYPED dry_run_gt_temp_graph_opts OPTIONS { without_properties: true }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: WITHOUT_PROPERTIES is only allowed with full graph projection"
    And drop the graph "dry_run_g_temp_graph_opts"
    And drop the graph type "dry_run_gt_temp_graph_opts"

  Scenario: Mutable graph computing with local id map rebuild
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_gt_mut_computing AS {
      NODE person (LABEL person {id INT PRIMARY KEY, name STRING, age INT}),
      NODE company (LABEL company {id INT PRIMARY KEY, name STRING}),
      EDGE works_at (person)-[LABEL works_at {since INT}]->(company),
      EDGE knows (person)-[LABEL knows {weight DOUBLE}]->(person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_mut_computing_graph TYPED dry_run_gt_mut_computing
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE PROCEDURE IF NOT EXISTS graph_stats() RETURNS (edges INT, persons INT) AS {
      VALUE total_edges SumAgg<INT> = 0
      VALUE total_persons SumAgg<INT> = 0

      // Count all edges and path information
      MATCH (p:person)-[e]->(target)
      PER PATH {
      SET @total_edges += 1
      }

      // Count all person nodes
      MATCH (person_node:person)
      PER NODE (person_node) {
      SET @total_persons += 1
      }

      RETURN @total_edges AS edges, @total_persons AS persons
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE PROCEDURE IF NOT EXISTS person_degrees() RETURNS (person_id INT, degree INT) AS {
      NODE VALUE out_degree SumAgg<INT> = 0
      TABLE result_table TYPED TABLE {person_id INT, degree INT}

      MATCH (p:person)-[e]->(target)
      PER PATH {
      SET p.@out_degree += 1
      }

      MATCH (result_person:person)
      PER NODE (result_person) {
      EXPORT result_person.id, result_person.@out_degree INTO result_table
      }

      FOR r IN result_table
      RETURN r.person_id, r.degree
      }
      """
    Then the execution should be successful
    # Insert initial data
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_computing_graph
      INSERT (p1@person {id:1, name: "alice", age: 25}),
      (p2@person {id:2, name: "bob", age: 30}),
      (c1@company {id:101, name: "tech_corp"}),
      (p1)-[@works_at {since: 2020}]->(c1),
      (p1)-[@knows {weight: 0.8}]->(p2)
      """
    Then the execution should be successful
    # First run of graph computing - initial state
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_computing_graph
      CALL graph_stats() RETURN *
      """
    Then the result should be, in any order:
      | edges | persons |
      | 0     | 0       |
    # Insert more data
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_computing_graph
      MATCH (p1:person {id:1}), (p2:person {id:2})
      INSERT (p3@person {id:3, name: "charlie", age: 28}),
      (c2@company {id:102, name: "startup"}),
      (p2)-[@works_at {since: 2021}]->(c2),
      (p2)-[@knows {weight: 0.9}]->(p3),
      (p3)-[@knows {weight: 0.7}]->(p1)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    # Second run of same graph computing - after data insertion
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_computing_graph
      CALL graph_stats() RETURN *
      """
    Then the result should be, in any order:
      | edges | persons |
      | 0     | 0       |
    # Check out-degree statistics for each person
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_computing_graph
      CALL person_degrees() RETURN person_id, degree
      """
    Then the result should be, in any order:
      | person_id | degree |
    # Delete some data
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_computing_graph
      MATCH (p:person {id:3})-[e]->(target)
      DELETE e
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    # Third run of same graph computing - after edge deletion
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_computing_graph
      CALL graph_stats() RETURN *
      """
    Then the result should be, in any order:
      | edges | persons |
      | 0     | 0       |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_mut_computing_graph
      CALL person_degrees() RETURN person_id, degree
      """
    Then the result should be, in any order:
      | person_id | degree |
    And drop the graph "#dry_run_mut_computing_graph"
    And drop the graph type "dry_run_gt_mut_computing"

  # Conflict actions on mutable temporary graph
  Scenario: Mem insert conflict actions on ldbc
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_ldbc_mem_conflict AS COPY OF ldbc
      """
    Then the execution should be successful
    # 1) First insertion: no conflicts
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_ldbc_mem_conflict
      INSERT (p1@Person {id: 7000, firstName: "Alice"}),
      (p2@Person {id: 7001, firstName: "Bob"}),
      (p1)-[@KNOWS {creationDate: local_datetime("2025-01-01T00:00:00", "%Y-%m-%dT%H:%M:%S") }]->(p2)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    # 2) Re-run with default, since it is try run, no error happens
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_ldbc_mem_conflict
      INSERT (p1@Person {id: 7000, firstName: "Alice"}),
      (p2@Person {id: 7001, firstName: "Bob"}),
      (p1)-[@KNOWS {creationDate: local_datetime("2025-01-01T00:00:00", "%Y-%m-%dT%H:%M:%S") }]->(p2)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    # 3) OR IGNORE: no data changes
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_ldbc_mem_conflict
      INSERT OR IGNORE (p1@Person {id: 7000, firstName: "Alice"}),
      (p2@Person {id: 7001, firstName: "Bob"}),
      (p1)-[@KNOWS {creationDate: local_datetime("2025-02-01T00:00:00", "%Y-%m-%dT%H:%M:%S") }]->(p2)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    # verify unchanged
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_ldbc_mem_conflict
      MATCH (a:Person)-[k:KNOWS]->(b:Person)
      WHERE a.id = 7000 AND b.id = 7001
      RETURN a.id, a.firstName, k.creationDate, b.id, b.firstName
      """
    Then the result should be, in any order:
      | a.id | a.firstName | k.creationDate | b.id | b.firstName |
    # 4) OR REPLACE: overwrite all properties
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_ldbc_mem_conflict
      INSERT OR REPLACE (p1@Person {id: 7000, firstName: "Alice_r"}),
      (p2@Person {id: 7001, firstName: "Bob_r"}),
      (p1)-[@KNOWS {creationDate: local_datetime("2025-03-01T00:00:00", "%Y-%m-%dT%H:%M:%S") }]->(p2)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_ldbc_mem_conflict
      MATCH (a:Person)-[k:KNOWS]->(b:Person)
      WHERE a.id = 7000 AND b.id = 7001
      RETURN a.firstName, k.creationDate, b.firstName
      """
    Then the result should be, in any order:
      | a.firstName | k.creationDate | b.firstName |
    # 5) OR UPDATE: update only specified properties
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_ldbc_mem_conflict
      MATCH (p2:Person {id: 7001})
      INSERT OR UPDATE (p1@Person {id: 7000, firstName: "Alice_u"}),
      (p1)-[@KNOWS {creationDate: local_datetime("2025-04-01T00:00:00", "%Y-%m-%dT%H:%M:%S") }]->(p2)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_ldbc_mem_conflict
      MATCH (a:Person)-[k:KNOWS]->(b:Person)
      WHERE a.id = 7000 AND b.id = 7001
      RETURN a.firstName, k.creationDate, b.firstName
      """
    Then the result should be, in any order:
      | a.firstName | k.creationDate | b.firstName |
    And drop the graph "#dry_run_ldbc_mem_conflict"

  Scenario: temp graph property type validation
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_complex_prop_graph AS {
      NODE T (LABEL T {
      id INT PRIMARY KEY,
      l LIST<INT>,
      deci DECIMAL(20, 2),
      vec VECTOR<3, FLOAT>,
      geog GEOGRAPHY(POINT)
      })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH IF NOT EXISTS dry_run_g_csr_complex_prop TYPED dry_run_complex_prop_graph
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE dry_run_g_csr_complex_prop
      INSERT (@T {id:1,
      l: LIST [1,2,3],
      deci: CAST(123.45 AS DECIMAL(20,2)),
      vec: VECTOR<3,float>([1,2,3]),
      geog: ST_GEOGFROMTEXT("POINT(1 1)")})
      """
    Then the execution should be successful
    # csr graph support all of the property types
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_csr_prop_ok AS COPY OF dry_run_g_csr_complex_prop OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_csr_prop_ok
      MATCH (v:T)
      RETURN v.id AS id, v.l AS l, v.vec AS vec, ST_ASTEXT(v.geog) AS geog_text
      """
    Then the result should be, in any order:
      | id | l | vec | geog_text |
    And drop the graph "#dry_run_csr_prop_ok"
    # mut graph doesn't support some complex property types
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_mut_typed_fail TYPED dry_run_complex_prop_graph
      """
    Then an Error should be raised: "[NT502]: Unsupported property type `GEOGRAPHY(Point)` for mutable temporary graph property `geog`"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH #dry_run_mut_subq_fail AS COPY OF
      GRAPH { USE dry_run_g_csr_complex_prop MATCH (v:T) RETURN v }
      """
    Then an Error should be raised: "[NT502]: Unsupported property type `GEOGRAPHY(Point)` for mutable temporary graph property `geog`"
    And drop the graph "dry_run_g_csr_complex_prop"
    And drop the graph type "dry_run_complex_prop_graph"

  Scenario: Import null value into mutable temporary graph from CSV
    And drop the graph "#dry_run_test_import_default_null"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_test_import_default_null AS {
      NODE person ({
      id int64 PRIMARY KEY,
      age int8 DEFAULT 18,
      name string
      })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_test_import_default_null TYPED dry_run_test_import_default_null
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      FILE f1  {
      id int64,
      name string
      }  = DATAFILE {PATH:'file://${TEST_DIR}/test_import_default_dir',  FORMAT:'CSV'}
      FOR i IN RANGE(1,10)
      EXPORT
      i AS id,
      NULL AS name
      INTO f1
      """
    Then the execution should be successful
    Then the path "file://${TEST_DIR}/test_import_default_dir" should not be a "directory" path
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_test_import_default_null IMPORT INTO GRAPH {
      NODE (v@person{id:id, name:name})
      FROM DATAFILE {
      PATH:'file://${TEST_DIR}/test_import_default_dir',
      FORMAT:'CSV'
      }
      }
      """
    Then an Error should be raised: "[AN000]: Analytic error: File not found for path"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_test_import_default_null SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
      | "person"     | "Node"       | 0         |
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_test_import_default_null
      MATCH (v)
      RETURN v.id, v.age, v.name
      """
    Then the result should be, in any order:
      | v.id | v.age | v.name |
    And drop the graph "#dry_run_test_import_default_null"
    And drop the graph type "dry_run_test_import_default_null"

  @non_tls
  Scenario: Avoid different graph in Nebula import
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_cluster_diff_237 TYPED ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH IF NOT EXISTS dry_run_ldbc_copy_graph TYPED ldbc_type
      """
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_cluster_diff_237 IMPORT INTO GRAPH {
      NODE (v@Person{id:id}) FROM NEBULA {
      FORMAT:"nebula",
      PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
      },
      NODE (d@Place{id:id}) FROM NEBULA {
      FORMAT:"nebula",
      PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=dry_run_ldbc_copy_graph&node_type=Place"
      }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: The graph in the Nebula import list is different"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_cluster_diff_237 IMPORT INTO GRAPH {
      NODE (v@Person{id:id}) FROM NEBULA {
      FORMAT:"nebula",
      PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
      },
      NODE (d@Place{id:id}) FROM NEBULA {
      FORMAT:"nebula",
      PATH:"nebula://root:NebulaGraph01@192.168.0.2/10020?graph=dry_run_ldbc_copy_graph&node_type=Place"
      }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: The graph in the Nebula import list is different"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_cluster_diff_237 IMPORT INTO GRAPH {
      NODE (v@Person{id:id}) FROM NEBULA {
      FORMAT:"nebula",
      PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
      },
      NODE (d@Place{id:id}) FROM NEBULA {
      FORMAT:"nebula",
      PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=other_schema/ldbc&node_type=Place"
      }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: The graph in the Nebula import list is different"
    And drop the graph "#dry_run_cluster_diff_237"
    And drop the graph "dry_run_ldbc_copy_graph"

  Scenario: Import datafile with format Nebula:
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_sf01_from_error TYPED ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_sf01_from_error IMPORT INTO GRAPH {
      NODE(v@Person{id:id}) FROM DATAFILE {
      FORMAT:"nebula",
      PATH:"nebula://root:NebulaGraph01@192.168.8.5:10010?graph=sf0_1&tls_enable=false&node_type=Person"
      }
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: Invalid format, `nebula` is a DATABASE, expected: FILE"
    And drop the graph "#dry_run_sf01_from_error"

  Scenario: Mixed read write
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE OR REPLACE PROCEDURE test_mut_graph_insert() RETURNS () AS {
      INSERT (a@Person{id:6})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_ldbc_mixed_test AS COPY OF ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_ldbc_mixed_test {
      VALUE s = 1
      VALUE l ListAgg<STRING>
      MATCH (a:Person)
      PER NODE (a) {
      LOG_INFO(a)
      }
      CALL test_mut_graph_insert() FINISH
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_ldbc_mixed_test SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name        | element_type | total_num |
      | "Node Total"      | "Node"       | 0         |
      | "Edge Total"      | "Edge"       | 0         |
      | "Place"           | "Node"       | 0         |
      | "Forum"           | "Node"       | 0         |
      | "Comment"         | "Node"       | 0         |
      | "Person"          | "Node"       | 0         |
      | "Tag"             | "Node"       | 0         |
      | "Post"            | "Node"       | 0         |
      | "TagClass"        | "Node"       | 0         |
      | "Organisation"    | "Node"       | 0         |
      | "HAS_INTEREST"    | "Edge"       | 0         |
      | "WORK_AT"         | "Edge"       | 0         |
      | "IS_LOCATED_IN_1" | "Edge"       | 0         |
      | "IS_LOCATED_IN_2" | "Edge"       | 0         |
      | "IS_LOCATED_IN_3" | "Edge"       | 0         |
      | "IS_LOCATED_IN_4" | "Edge"       | 0         |
      | "IS_PART_OF"      | "Edge"       | 0         |
      | "HAS_TYPE"        | "Edge"       | 0         |
      | "REPLY_OF_1"      | "Edge"       | 0         |
      | "REPLY_OF_2"      | "Edge"       | 0         |
      | "KNOWS"           | "Edge"       | 0         |
      | "FOLLOWS"         | "Edge"       | 0         |
      | "CONTAINER_OF"    | "Edge"       | 0         |
      | "HAS_MEMBER"      | "Edge"       | 0         |
      | "HAS_MODERATOR"   | "Edge"       | 0         |
      | "STUDY_AT"        | "Edge"       | 0         |
      | "IS_SUBCLASS_OF"  | "Edge"       | 0         |
      | "HAS_TAG_1"       | "Edge"       | 0         |
      | "HAS_TAG_2"       | "Edge"       | 0         |
      | "HAS_TAG_3"       | "Edge"       | 0         |
      | "HAS_CREATOR_1"   | "Edge"       | 0         |
      | "HAS_CREATOR_2"   | "Edge"       | 0         |
      | "LIKES_1"         | "Edge"       | 0         |
      | "LIKES_2"         | "Edge"       | 0         |
    And drop the procedure "test_mut_graph_insert"
    And drop the graph "#dry_run_ldbc_mixed_test"

  Scenario: Import permission requires owner or admin
    And drop the graph "#dry_run_dist_import_permission_root"
    And drop the graph "#dry_run_dist_import_permission_non_root"
    And drop the user "dry_run_user_import_permission"
    # root user create temporary graph
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_dist_import_permission_root TYPED ldbc_type
      """
    Then the execution should be successful
    # Import as non-owner user
    And create a new user session with username "dry_run_user_import_permission" and password "NebulaGraph01"
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      GRANT CREATE GRAPH ON SCHEMA /default_schema TO USER dry_run_user_import_permission
      """
    Then the execution should be successful
    And action "CREATE_GRAPH" on "SCHEMA" for user "dry_run_user_import_permission" should be granted
    And switch to a new session with username "dry_run_user_import_permission" and password "NebulaGraph01"
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_dist_import_permission_root IMPORT INTO GRAPH
      {
      GRAPH FROM NEBULA{
      PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
      }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Only the owner or admin can import temporary graph `#dry_run_dist_import_permission_root`"
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_dist_import_permission_non_root TYPED ldbc_type
      """
    Then the execution should be successful
    # Import as admin
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_dist_import_permission_non_root IMPORT INTO GRAPH
      {
      GRAPH FROM NEBULA{
      PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
      }
      }
      """
    Then the execution should be successful
    # check if the owner is unchanged
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      CALL show_graphs() FILTER name = '#dry_run_dist_import_permission_non_root' RETURN graph_type, name, owner
      """
    Then the result should be, in any order:
      | graph_type  | name                                       | owner                            |
      | "ldbc_type" | "#dry_run_dist_import_permission_non_root" | "dry_run_user_import_permission" |
    And drop the graph "#dry_run_dist_import_permission_non_root"
    And drop the graph "#dry_run_dist_import_permission_root"
    And close current session and drop the user "dry_run_user_import_permission"

  Scenario: Import graph from statement
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_tmp_import_test_format TYPED ldbc_type
      """
    Then the execution should be successful
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_tmp_import_test_format IMPORT INTO GRAPH {
      GRAPH FROM DATAFILE {
      PATH:'file:///tmp/knife_test/export/test_import_vector.csv',
      FORMAT:'CSV'
      }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: GRAPH FROM only supports NEBULA"
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_tmp_import_test_format IMPORT INTO GRAPH {
      GRAPH FROM DATAFILE {
      FORMAT: "NEBULA",
      PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
      }
      }
      """
    Then an Error should be raised: "Invalid format, `NEBULA` is a DATABASE, expected: FILE"
    And drop the graph "#dry_run_tmp_import_test_format"

  @sf01
  Scenario: export and import sf01 data to csv/parquet/orc
    And drop the graph "#dry_run_import_export_multiple_format_file_g"
    And drop the graph type "dry_run_import_export_multiple_format_file_gt"
    # Export from sf01
    When executing graph query:
      """
      FILE f_csv {id int, content string, creationDate string}
      = DATAFILE {PATH:"file://${TEST_DIR}/dataset/temp_dry_run_test_files/sf01_post_csv",  FORMAT:'csv'}
      FILE f_parquet {id int, content string, creationDate string}
      = DATAFILE {PATH:"file://${TEST_DIR}/dataset/temp_dry_run_test_files/sf01_post_parquet",  FORMAT:'parquet'}
      FILE f_orc  {id int, content string, creationDate string}
      = DATAFILE {PATH:"file://${TEST_DIR}/dataset/temp_dry_run_test_files/sf01_post_orc",  FORMAT:'orc'}
      USE sf01 MATCH (v:Post) EXPORT
      v.id as id,
      v.content as content,
      cast(v.creationDate as string) as creationDate
      INTO f_csv
      USE sf01 MATCH (v:Post) EXPORT
      v.id as id,
      v.content as content,
      cast(v.creationDate as string) as creationDate
      INTO f_parquet
      USE sf01 MATCH (v:Post) EXPORT
      v.id as id,
      v.content as content,
      cast(v.creationDate as string) as creationDate
      INTO f_orc
      """
    Then the execution should be successful
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_import_export_multiple_format_file_gt AS {
      node post_csv (label  post{id int, content string, creationDate local datetime, length int, primary key(id,content,creationDate)}),
      node post_parquet (label  post{id int, content string, creationDate local datetime, length int, primary key(id,content,creationDate)}),
      node post_orc (label  post{id int, content string, creationDate local datetime, length int, primary key(id,content,creationDate)})
      }
      """
    Then the execution should be successful
    # Load from exported files
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH if not exists #dry_run_import_export_multiple_format_file_g typed dry_run_import_export_multiple_format_file_gt
      """
    Then the execution should be successful
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_import_export_multiple_format_file_g IMPORT INTO GRAPH {
      NODE (v@post_csv{id:id, content:content, creationDate:creationDate} )  FROM DATAFILE {
      PATH:"file://${TEST_DIR}/dataset/temp_dry_run_test_files/sf01_post_csv",
      FORMAT:'csv',
      delimiter: ","
      },
      NODE (v@post_parquet{id:id, content:content, creationDate:creationDate} ) FROM DATAFILE {
      PATH:"file://${TEST_DIR}/dataset/temp_dry_run_test_files/sf01_post_parquet",
      FORMAT:'parquet'
      },
      NODE (v@post_orc{id:id, content:content, creationDate:creationDate} )  FROM DATAFILE {
      PATH:"file://${TEST_DIR}/dataset/temp_dry_run_test_files/sf01_post_orc",
      FORMAT:"orc"
      }
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:false}
      """
    Then the execution should be successful
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      show stats  #dry_run_import_export_multiple_format_file_g
      """
    Then the result should be, in any order:
      | entry_name     | element_type | total_num |
      | "Node Total"   | "Node"       | 0         |
      | "Edge Total"   | "Edge"       | 0         |
      | "post_csv"     | "Node"       | 0         |
      | "post_parquet" | "Node"       | 0         |
      | "post_orc"     | "Node"       | 0         |
    And drop the graph "#dry_run_import_export_multiple_format_file_g"
    And drop the graph type "dry_run_import_export_multiple_format_file_gt"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_dry_run_test_files/sf01_post_csv"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_dry_run_test_files/sf01_post_parquet"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_dry_run_test_files/sf01_post_orc"
