# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Graph Service Data Import

  @non_tls
  Scenario: Import non-equivalent graph type
    # Test case 1: Create initial compatible graph types
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS remote_base_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE FRIENDS (Person)-[LABEL FRIENDS {since DATE, MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS remote_base_graph TYPED remote_base_gt
      """
    Then the execution should be successful
    And graph "remote_base_graph" should be ready to use
    When executing query:
      """
      TABLE persons {id, name, age} =
        {id:1, name:"Alice", age:25},
        {id:2, name:"Bob", age:30}
      USE remote_base_graph
      FOR p IN persons
      INSERT OR REPLACE (@Person{id:p.id, name:p.name, age:p.age})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE friendships {src, dst, since} =
        {src:1, dst:2, since:date("2020-01-01", "%Y-%m-%d")}
      USE remote_base_graph
      FOR f IN friendships
        MATCH (a@Person{id:f.src})
        MATCH (b@Person{id:f.dst})
        INSERT OR REPLACE (a)-[@FRIENDS{since:f.since}]->(b)
      """
    Then the execution should be successful
    # Create one base local graph type for all ALTER tests
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_test_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE FRIENDS (Person)-[LABEL FRIENDS {since DATE, MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    # Test case 2: ALTER to make property types incompatible
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        ALTER NODE TYPE Person
        DROP PROPERTIES {age}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        ALTER NODE TYPE Person
        ADD PROPERTIES {age STRING}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #type_mismatch_test TYPED local_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #type_mismatch_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_base_graph"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Property `age` of Node type `Person` data type mismatch: remote=INT64, local=STRING"
    And drop the graph "#type_mismatch_test"
    # Test case 3: ALTER to add extra properties
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        ALTER NODE TYPE Person
        DROP PROPERTIES {age}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        ALTER NODE TYPE Person
        ADD PROPERTIES {age INT, email STRING, phone STRING}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #extra_props_test TYPED local_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #extra_props_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_base_graph"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Property count of Node type `Person` mismatch: remote=3, local=5"
    And drop the graph "#extra_props_test"
    # Test case 4: ALTER to add new node types
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        ALTER NODE TYPE Person
        DROP PROPERTIES {email, phone},
        ADD NODE TYPE Company (LABEL Company {id INT PRIMARY KEY, name STRING, industry STRING}),
        ADD EDGE TYPE WORKS_AT (Person)-[LABEL WORKS_AT {since DATE, MULTIEDGE KEY()}]->(Company)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #extra_nodes_test TYPED local_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #extra_nodes_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_base_graph"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Node type count mismatch: remote=1, local=2"
    And drop the graph "#extra_nodes_test"
    # Test case 5: ALTER to rename properties
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        DROP NODE TYPE Company,
        DROP EDGE TYPE WORKS_AT,
        ALTER NODE TYPE Person
        RENAME PROPERTIES {name TO full_name, age TO years_old},
        ALTER EDGE TYPE FRIENDS
        RENAME PROPERTIES {since TO created_date}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #renamed_props_test TYPED local_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #renamed_props_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_base_graph"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Property `full_name` of Node type `Person` not found in remote graph"
    And drop the graph "#renamed_props_test"
    # Test case 6: ALTER to modify property nullability
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        ALTER NODE TYPE Person
        RENAME PROPERTIES {years_old TO age}
        DROP PROPERTIES {full_name},
        ALTER EDGE TYPE FRIENDS
        RENAME PROPERTIES {created_date TO since}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        ALTER NODE TYPE Person
        ADD PROPERTIES {name STRING NOT NULL DEFAULT "x"}
      }
      """
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #nullable_test TYPED local_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #nullable_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_base_graph"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Property `name` of Node type `Person` nullable mismatch: remote=true, local=false"
    And drop the graph "#nullable_test"
    # Test case 7: ALTER to test edge type not found in remote
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        ALTER NODE TYPE Person
        DROP PROPERTIES {name},
        ADD EDGE TYPE LIKES (Person)-[LABEL LIKES {rating INT, MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        ALTER NODE TYPE Person
        ADD PROPERTIES {name STRING}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #edge_not_found_test TYPED local_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #edge_not_found_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_base_graph"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Edge type count mismatch: remote=1, local=2"
    And drop the graph "#edge_not_found_test"
    # Test case 8: ALTER to test default value mismatch
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        DROP EDGE TYPE LIKES,
        ALTER NODE TYPE Person
        DROP PROPERTIES {name}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      ALTER GRAPH TYPE local_test_gt {
        ALTER NODE TYPE Person
        ADD PROPERTIES {name STRING DEFAULT "unknown"}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #default_value_test TYPED local_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #default_value_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_base_graph"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Property `name` of Node type `Person` defaultValue mismatch: remote=NULL, local=\"unknown\""
    And drop the graph "#default_value_test"
    # Cleanup
    And drop the graph "remote_base_graph"
    And drop the graph type "remote_base_gt"
    And drop the graph type "local_test_gt"

  @non_tls
  Scenario: Import graph type with primary key mismatch
    # Test case 1: Create remote graph with composite primary key
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS remote_pk_gt AS {
        NODE TYPE Person (LABEL Person {id INT, name STRING, age INT, PRIMARY KEY(id, name)}),
        EDGE TYPE FRIENDS (Person)-[LABEL FRIENDS {since DATE, MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS remote_pk_graph TYPED remote_pk_gt
      """
    Then the execution should be successful
    And graph "remote_pk_graph" should be ready to use
    # Test case 2: Create local graph type with different primary key
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_pk_test_gt AS {
        NODE TYPE Person (LABEL Person {id INT NOT NULL, name STRING PRIMARY KEY, age INT}),
        EDGE TYPE FRIENDS (Person)-[LABEL FRIENDS {since DATE, MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #pk_mismatch_test TYPED local_pk_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #pk_mismatch_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_pk_graph"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Node type `Person` primary key mismatch: remote=id,name, local=name"
    And drop the graph "#pk_mismatch_test"
    # Cleanup
    And drop the graph "remote_pk_graph"
    And drop the graph type "remote_pk_gt"
    And drop the graph type "local_pk_test_gt"

  @non_tls
  Scenario: Import graph type with multiedge key mismatch
    # Test case 1: Create remote graph with no multiedge key
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS remote_me_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE FRIENDS (Person)-[LABEL FRIENDS {since DATE}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS remote_me_graph TYPED remote_me_gt
      """
    Then the execution should be successful
    And graph "remote_me_graph" should be ready to use
    # Test case 2: Create local graph type with multiedge key
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_me_test_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE FRIENDS (Person)-[LABEL FRIENDS {since DATE, MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #multiedge_key_test TYPED local_me_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #multiedge_key_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_me_graph"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Edge type `FRIENDS` multiedge key mismatch: remote=Unique, local=Auto"
    And drop the graph "#multiedge_key_test"
    # Test case 3: Create remote graph with specific multiedge key properties
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS remote_me_props_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE FRIENDS (Person)-[LABEL FRIENDS {since DATE NOT NULL, weight INT NOT NULL, MULTIEDGE KEY(since)}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS remote_me_props_graph TYPED remote_me_props_gt
      """
    Then the execution should be successful
    And graph "remote_me_props_graph" should be ready to use
    # Test case 4: Create local graph type with different multiedge key properties
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_me_props_test_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE FRIENDS (Person)-[LABEL FRIENDS {since DATE NOT NULL, weight INT NOT NULL, MULTIEDGE KEY(weight)}]->(Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #multiedge_key_props_test TYPED local_me_props_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #multiedge_key_props_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_me_props_graph"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Edge type `FRIENDS` multiedge key mismatch: remote=since, local=weight"
    And drop the graph "#multiedge_key_props_test"
    # Cleanup
    And drop the graph "remote_me_graph"
    And drop the graph type "remote_me_gt"
    And drop the graph "remote_me_props_graph"
    And drop the graph type "remote_me_props_gt"
    And drop the graph type "local_me_test_gt"
    And drop the graph type "local_me_props_test_gt"

  @non_tls
  Scenario: Import graph type with edge type pattern mismatch
    # Test case 1: Create remote graph with Person to Company edge
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS remote_edge_pattern_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        NODE TYPE Company (LABEL Company {id INT PRIMARY KEY, name STRING, industry STRING}),
        EDGE TYPE WORKS_AT (Person)-[LABEL WORKS_AT {since DATE, position STRING, MULTIEDGE KEY()}]->(Company)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS remote_edge_pattern_graph TYPED remote_edge_pattern_gt
      """
    Then the execution should be successful
    And graph "remote_edge_pattern_graph" should be ready to use
    # Test case 2: Create local graph type with different source node type (Company to Person)
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_edge_src_diff_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        NODE TYPE Company (LABEL Company {id INT PRIMARY KEY, name STRING, industry STRING}),
        EDGE TYPE WORKS_AT (Company)-[LABEL WORKS_AT {since DATE, position STRING, MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #edge_src_diff_test TYPED local_edge_src_diff_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #edge_src_diff_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_edge_pattern_graph"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Edge type `WORKS_AT` type pattern mismatch: remote=(Person)-[WORKS_AT]->(Company), local=(Company)-[WORKS_AT]->(Person)"
    And drop the graph "#edge_src_diff_test"
    # Cleanup
    And drop the graph "remote_edge_pattern_graph"
    And drop the graph type "remote_edge_pattern_gt"
    And drop the graph type "local_edge_src_diff_gt"

  @non_tls
  Scenario: Insert conflicts
    # Create a comprehensive graph with different key types in one graph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS comprehensive_key_types_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        NODE TYPE Company (LABEL Company {company_id STRING, company_name STRING, PRIMARY KEY(company_id, company_name)}),
        NODE TYPE Item (LABEL Item {product_uuid STRING PRIMARY KEY, title STRING, price DOUBLE}),
        EDGE TYPE WORKS_AT (Person)-[LABEL WORKS_AT {since DATE, position STRING, MULTIEDGE KEY()}]->(Company),
        EDGE TYPE KNOWS (Person)-[LABEL KNOWS {since DATE, location STRING, MULTIEDGE KEY(since, location)}]->(Person),
        EDGE TYPE BUYS (Person)-[LABEL BUYS {quantity INT, purchase_date DATE}]->(Item),
        EDGE TYPE SELLS (Company)-[LABEL SELLS {price DOUBLE, available_date DATE, MULTIEDGE KEY(available_date)}]->(Item)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS comprehensive_key_types_graph TYPED comprehensive_key_types_gt
      """
    Then the execution should be successful
    And graph "comprehensive_key_types_graph" should be ready to use
    When executing query:
      """
      USE comprehensive_key_types_graph
      INSERT
        (p1@Person{id:1, name:"Alice", age:28}),
        (p2@Person{id:2, name:"Bob", age:32}),
        (c@Company{company_id:"C001", company_name:"TechCorp"}),
        (i@Item{product_uuid:"P001", title:"Laptop Pro", price:1299.99}),
        (p1)-[@WORKS_AT{since:date("2022-01-15", "%Y-%m-%d"), position:"Software Engineer"}]->(c),
        (p1)-[@KNOWS{since:date("2019-05-15", "%Y-%m-%d"), location:"San Francisco"}]->(p2),
        (p1)-[@BUYS{quantity:1, purchase_date:date("2023-06-15", "%Y-%m-%d")}]->(i),
        (c)-[@SELLS{price:1299.99, available_date:date("2023-01-01", "%Y-%m-%d")}]->(i)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 4     |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #temp_comprehensive_key_types_graph TYPED comprehensive_key_types_gt
      """
    Then the execution should be successful
    When executing query:
      """
      USE #temp_comprehensive_key_types_graph IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=comprehensive_key_types_graph"
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #temp_comprehensive_key_types_graph SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 4         |
      | "Edge Total" | "Edge"       | 4         |
      | "Person"     | "Node"       | 2         |
      | "Company"    | "Node"       | 1         |
      | "Item"       | "Node"       | 1         |
      | "WORKS_AT"   | "Edge"       | 1         |
      | "KNOWS"      | "Edge"       | 1         |
      | "BUYS"       | "Edge"       | 1         |
      | "SELLS"      | "Edge"       | 1         |
    When executing query:
      """
      USE #temp_comprehensive_key_types_graph
      INSERT (p@Person{id:1, name:"Alice Duplicate", age:30})
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation"
    When executing query:
      """
      USE #temp_comprehensive_key_types_graph
      MATCH (p@Person{id:1}), (i@Item{product_uuid:"P001"})
      INSERT (p)-[@BUYS{quantity:2, purchase_date:date("2023-07-01", "%Y-%m-%d")}]->(i)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    When executing query:
      """
      USE #temp_comprehensive_key_types_graph
      MATCH (p1@Person{id:1}), (p2@Person{id:2})
      INSERT (p1)-[@KNOWS{since:date("2019-05-15", "%Y-%m-%d"), location:"San Francisco"}]->(p2)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    When executing query:
      """
      USE #temp_comprehensive_key_types_graph
      MATCH (c@Company{company_id:"C001", company_name:"TechCorp"}), (i@Item{product_uuid:"P001"})
      INSERT (c)-[@SELLS{price:999.99, available_date:date("2023-01-01", "%Y-%m-%d")}]->(i)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    When executing query:
      """
      USE #temp_comprehensive_key_types_graph
      MATCH (p@Person{id:2}), (c@Company{company_id:"C001", company_name:"TechCorp"})
      INSERT (p)-[@WORKS_AT{since:date("2023-01-01", "%Y-%m-%d"), position:"Data Analyst"}]->(c)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    And drop the graph "#temp_comprehensive_key_types_graph"
    And drop the graph "comprehensive_key_types_graph"
    And drop the graph type "comprehensive_key_types_gt"

  @non_tls
  Scenario: Cast NULL default value
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_cast_null_gt AS {
              NODE City (LABELS City&Place {id INT64 PRIMARY KEY, name STRING, url STRING DEFAULT NULL})}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH test_cast_null_g test_cast_null_gt
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_cast_null_g
      INSERT (a@City{id:1})
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_cast_null_gt AS {
              NODE City (LABELS City&Place {id INT64 PRIMARY KEY, name STRING DEFAULT NULL, url STRING})}
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMP GRAPH #test_cast_null_g TYPED test_cast_null_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_cast_null_g IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=test_cast_null_g"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_cast_null_g SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 1         |
      | "Edge Total" | "Edge"       | 0         |
    And drop the graph "#test_cast_null_g"
    And drop the graph "test_cast_null_g"
    And drop the graph type "test_cast_null_gt"

  Scenario: Import procedure
    When executing analytic query:
      """
      CREATE TEMP GRAPH #test_import_proc TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE proc_import_if_g (p STRING) {
        FILE file01{f0 INT, f1 DOUBLE} = DATAFILE {
          FORMAT:"csv",
          PATH:p,
          AUTOGENERATE_COLUMN_NAMES: true,
          DELIMITER:" "
        }
        USE #test_import_proc IMPORT INTO GRAPH {
          NODE (v@Person{id:f0}) FROM file01
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CALL proc_import_if_g("file://${TEST_DIR}/dataset/external_source/csv_source/node") FINISH
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_import_proc SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 12        |
      | "Edge Total" | "Edge"       | 0         |
    And drop the procedure "proc_import_if_g"
    And drop the graph "#test_import_proc"

  Scenario: Unmapped properties with default value
    And drop the graph "unmapped_prop_with_default_value_g"
    And drop the graph "#unmapped_prop_with_default_value_g"
    And drop the graph type "unmapped_prop_with_default_value_gt"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS unmapped_prop_with_default_value_gt AS {
        NODE person ({
          id int64 PRIMARY KEY,
          name string DEFAULT "test",
          birthday date
        })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS unmapped_prop_with_default_value_g TYPED unmapped_prop_with_default_value_gt
      """
    Then the execution should be successful
    And graph "unmapped_prop_with_default_value_g" should be ready to use
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #unmapped_prop_with_default_value_g TYPED unmapped_prop_with_default_value_gt
      """
    Then the execution should be successful
    When executing query:
      """
      USE unmapped_prop_with_default_value_g
      INSERT (@person{id: 1})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    # Only id is mapped, name has default value
    When executing query:
      """
      USE #unmapped_prop_with_default_value_g
      IMPORT INTO GRAPH {
        NODE (@person{id: id})
        FROM NEBULA {
          format: "nebula",
          path: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=unmapped_prop_with_default_value_g&node_type=person&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #unmapped_prop_with_default_value_g
      MATCH (v)
      RETURN v.id, v.name, v.birthday
      """
    Then the result should be, in any order:
      | v.id | v.name | v.birthday |
      | 1    | "test" | null       |
    And drop the graph "unmapped_prop_with_default_value_g"
    And drop the graph "#unmapped_prop_with_default_value_g"
    And drop the graph type "unmapped_prop_with_default_value_gt"

  Scenario: NOT NULL constraint
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS not_null_constraint_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING NOT NULL, age INT NOT NULL}),
        EDGE TYPE KNOWS (Person)-[LABEL KNOWS {weight DOUBLE NOT NULL, MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #not_null_constraint_test TYPED not_null_constraint_gt
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      FILE nf {id INT, name STRING, age INT} = DATAFILE {
        FORMAT:"csv",
        PATH:"file://${TEST_DIR}/dataset/external_source/not_null_constraint/null_value_node.csv"
      }
      USE #not_null_constraint_test IMPORT INTO GRAPH
      {
        NODE (v@Person{id:nf.id, name:nf.name, age:nf.age}) FROM nf
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      """
    Then an Error should be raised: "Property `name` of type `Person` is not nullable"
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      FILE nf {id INT, name STRING, age INT} = DATAFILE {
        FORMAT:"csv",
        PATH:"file://${TEST_DIR}/dataset/external_source/not_null_constraint/null_value_node.csv"
      }
      USE #not_null_constraint_test IMPORT INTO GRAPH
      {
        NODE (v@Person{id:nf.id, name:nf.name, age:nf.age}) FROM nf
      }
      """
    Then an Error should be raised: "Property `name` of type `Person` is not nullable"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #not_null_edge_test TYPED not_null_constraint_gt
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      FILE nf {id INT, name STRING, age INT} = DATAFILE {
        FORMAT:"csv",
        PATH:"file://${TEST_DIR}/dataset/external_source/not_null_constraint/valid_node.csv"
      }
      FILE ef {src_id INT, dst_id INT, weight DOUBLE} = DATAFILE {
        FORMAT:"csv",
        PATH:"file://${TEST_DIR}/dataset/external_source/not_null_constraint/null_value_edge.csv"
      }
      USE #not_null_edge_test IMPORT INTO GRAPH
      {
        NODE (v@Person{id:nf.id, name:nf.name, age:nf.age}) FROM nf,
        EDGE (id:ef.src_id)-[e@KNOWS{weight:ef.weight}]->(id:ef.dst_id) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      """
    Then an Error should be raised: "Property `weight` of type `KNOWS` is not nullable"
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      FILE nf {id INT, name STRING, age INT} = DATAFILE {
        FORMAT:"csv",
        PATH:"file://${TEST_DIR}/dataset/external_source/not_null_constraint/valid_node.csv"
      }
      FILE ef {src_id INT, dst_id INT, weight DOUBLE} = DATAFILE {
        FORMAT:"csv",
        PATH:"file://${TEST_DIR}/dataset/external_source/not_null_constraint/null_value_edge.csv"
      }
      USE #not_null_edge_test IMPORT INTO GRAPH
      {
        NODE (v@Person{id:nf.id, name:nf.name, age:nf.age}) FROM nf,
        EDGE (id:ef.src_id)-[e@KNOWS{weight:ef.weight}]->(id:ef.dst_id) FROM ef
      }
      """
    Then an Error should be raised: "Property `weight` of type `KNOWS` is not nullable"
    And drop the graph "#not_null_constraint_test"
    And drop the graph "#not_null_edge_test"
    And drop the graph type "not_null_constraint_gt"

  @non_tls
  Scenario: Unsupported options
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #unsupported_nebula_recoding TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #unsupported_nebula_recoding
      IMPORT INTO GRAPH {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc"
        }
      }
      OPTIONS {PRIMARY_KEY_AS_NODE_ID:false}
      """
    Then an Error should be raised: "The PRIMARY_KEY_AS_NODE_ID option is not supported when importing from a Nebula source"

  Scenario: More negative cases
    When executing query:
      """
      USE #analytic_ldbc IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc"
        },
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc"
        }
      }
      """
    Then an Error should be raised: "Only one source graph is allowed when importing a graph"
    When executing query:
      """
      FILE file01{f0 INT, f1 DOUBLE} = DATAFILE {
        FORMAT:"csv",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/node",
        AUTOGENERATE_COLUMN_NAMES: true,
        DELIMITER:" "
      }
      USE #analytic_ldbc IMPORT INTO GRAPH {
        NODE (v@Person{id:f.f0}) FROM file01
      }
      """
    Then an Error should be raised: "Variable `f` is not found in the source"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS negative_import_case_gt AS {
        NODE TYPE Person ({id INT PRIMARY KEY, name STRING NOT NULL}),
        EDGE TYPE KNOWS (Person)-[{MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #negative_import_case_g TYPED negative_import_case_gt
      """
    Then the execution should be successful
    When executing query:
      """
      FILE file01{f0 INT, f1 DOUBLE} = DATAFILE {
        FORMAT:"csv",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/node",
        AUTOGENERATE_COLUMN_NAMES: true,
        DELIMITER:" "
      }
      USE #negative_import_case_g IMPORT INTO GRAPH {
        NODE (v@Person{id:f0}) FROM file01
      }
      """
    Then an Error should be raised: "Property `name` of type `Person` has no default value"
    When executing query:
      """
      FILE file01{f0 INT, f1 DOUBLE} = DATAFILE {
        FORMAT:"csv",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/node",
        AUTOGENERATE_COLUMN_NAMES: true,
        DELIMITER:" "
      }
      FILE file02{f0 INT, f1 INT, f2 INT} = DATAFILE {
        FORMAT:"csv",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/edge",
        AUTOGENERATE_COLUMN_NAMES: true,
        DELIMITER:" "
      }
      USE #negative_import_case_g IMPORT INTO GRAPH {
        NODE (v@Person{id:f0,name:f1}) FROM file01,
        EDGE (id:f0,name:f1)-[@KNOWS{}]->(id:f0,name:f1) FROM file02
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Type mismatch, column `f1`, expect: STRING, got: DOUBLE"
    And drop the graph "#negative_import_case_g"
    And drop the graph type "negative_import_case_gt"

  Scenario: Check dangling edge types
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dangling_edge_type_test_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY}),
        NODE TYPE Company (LABEL Company {id INT PRIMARY KEY}),
        EDGE TYPE WORK_AT (Person)-[LABELS WORK_AT {MULTIEDGE KEY()}]->(Company)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dangling_edge_type_test_g TYPED dangling_edge_type_test_gt
      """
    Then the execution should be successful
    When executing query:
      """
      FILE edge_file{f0 INT, f1 INT, f2 INT} = DATAFILE {
        FORMAT:"csv",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/edge",
        AUTOGENERATE_COLUMN_NAMES: true,
        DELIMITER:" "
      }
      USE #dangling_edge_type_test_g IMPORT INTO GRAPH {
        EDGE (id:f0)-[e@WORK_AT{}]->(id:f1) FROM edge_file
      }
      """
    Then an Error should be raised: "Edge type `WORK_AT` references missing source node type `Person`"
    When executing query:
      """
      FILE node_file{f0 INT, f1 DOUBLE} = DATAFILE {
        FORMAT:"csv",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/node",
        AUTOGENERATE_COLUMN_NAMES: true,
        DELIMITER:" "
      }
      FILE edge_file{f0 INT, f1 INT, f2 INT} = DATAFILE {
        FORMAT:"csv",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/edge",
        AUTOGENERATE_COLUMN_NAMES: true,
        DELIMITER:" "
      }
      USE #dangling_edge_type_test_g IMPORT INTO GRAPH {
        NODE (c@Person{id:f0}) FROM node_file,
        EDGE (id:f0)-[e@WORK_AT{}]->(id:f1) FROM edge_file
      }
      """
    Then an Error should be raised: "Edge type `WORK_AT` references missing destination node type `Company`"
    And drop the graph "#dangling_edge_type_test_g"
    And drop the graph type "dangling_edge_type_test_gt"

  Scenario: Invalid embedded node ID
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_embedded_node_id_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY}),
        EDGE TYPE KNOWS (Person)-[LABEL KNOWS {MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #invalid_embedded_node_id TYPED invalid_embedded_node_id_gt
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency=4) */
      FILE node_file{f0 INT, f1 DOUBLE} = DATAFILE {
        FORMAT:"csv",
        PATH: "file://${TEST_DIR}/dataset/external_source/invalid_embedded_node_id/node.csv",
        AUTOGENERATE_COLUMN_NAMES: true,
        DELIMITER:" "
      }
      FILE edge_file{f0 INT, f1 INT, f2 INT} = DATAFILE {
        FORMAT:"csv",
        PATH: "file://${TEST_DIR}/dataset/external_source/invalid_embedded_node_id/valid_edge.csv",
        AUTOGENERATE_COLUMN_NAMES: true,
        DELIMITER:" "
      }
      USE #invalid_embedded_node_id IMPORT INTO GRAPH {
        NODE (c@Person{id:f0}) FROM node_file,
        EDGE (id:f0)-[e@KNOWS{}]->(id:f1) FROM edge_file
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      """
    Then an Error should be raised: "Invalid node ID input: -1. Primary key value must not exceed 6 bytes when PRIMARY_KEY_AS_NODE_ID is enabled"
    When executing query:
      """
      /*+ SET_VAR(query_concurrency=4) */
      FILE node_file{f0 INT, f1 DOUBLE} = DATAFILE {
        FORMAT:"csv",
        PATH: "file://${TEST_DIR}/dataset/external_source/invalid_embedded_node_id/valid_node.csv",
        AUTOGENERATE_COLUMN_NAMES: true,
        DELIMITER:" "
      }
      FILE edge_file{f0 INT, f1 INT, f2 INT} = DATAFILE {
        FORMAT:"csv",
        PATH: "file://${TEST_DIR}/dataset/external_source/invalid_embedded_node_id/edge.csv",
        AUTOGENERATE_COLUMN_NAMES: true,
        DELIMITER:" "
      }
      USE #invalid_embedded_node_id IMPORT INTO GRAPH {
        NODE (c@Person{id:f0}) FROM node_file,
        EDGE (id:f0)-[e@KNOWS{}]->(id:f1) FROM edge_file
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      """
    Then an Error should be raised: "Invalid node ID input: -2. Primary key value must not exceed 6 bytes when PRIMARY_KEY_AS_NODE_ID is enabled"
    And drop the graph "#invalid_embedded_node_id"
    And drop the graph type "invalid_embedded_node_id_gt"

  # Fix https://github.com/vesoft-inc/nebula-ng/issues/9302
  # Fix https://github.com/vesoft-inc/nebula-ng/issues/9303
  # The 2nd column tests string and integer in string format
  # The 3rd column tests zoned time in string format and null values
  Scenario: Mixed string, int, zoned time types and null values in analytic import
    And drop the graph "#a_test_import_string_int_mixed_g"
    And drop the graph type "a_test_import_string_int_mixed_gt"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/temp_string_int_mixed_nodes.csv"
    When executing graph query:
      """
      FILE f1 {id INT64, _string STRING, _zoned_time STRING} = DATAFILE {
        FORMAT: "csv",
        PATH: "file://${TEST_DIR}/dataset/temp_test_files/temp_string_int_mixed_nodes.csv"
      }
      BINDING TABLE table_v TYPED TABLE {id INT64, _string STRING, _zoned_time STRING} =
        {id: 1, _string: null, _zoned_time: null},
        {id: 2, _string: "10", _zoned_time: "11:11:11Z"},
        {id: 3, _string: "10.0", _zoned_time: "12:12:12Z"}
      FOR t IN table_v
      EXPORT t.id AS id, t._string AS _string, t._zoned_time AS _zoned_time INTO f1
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS a_test_import_string_int_mixed_gt AS {
        NODE TYPE Person (LABEL Person {
              id INT64 PRIMARY KEY,
              _string STRING,
              _zoned_time ZONED TIME
            }
          )
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #a_test_import_string_int_mixed_g TYPED a_test_import_string_int_mixed_gt
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #a_test_import_string_int_mixed_g IMPORT INTO GRAPH {
        NODE (v@Person{id: id, _string: _string, _zoned_time: _zoned_time}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/temp_test_files/temp_string_int_mixed_nodes.csv",
          FORMAT: "CSV"
        }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #a_test_import_string_int_mixed_g SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 3         |
      | "Edge Total" | "Edge"       | 0         |
    And drop the graph "#a_test_import_string_int_mixed_g"
    And drop the graph type "a_test_import_string_int_mixed_gt"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/temp_string_int_mixed_nodes.csv"

  Scenario: Choose encoding method
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS encoding_test_complex_gt AS {
        NODE TYPE PersonInt8 (LABEL PersonInt8 {id_int8 INT8 PRIMARY KEY, name STRING}),
        NODE TYPE PersonInt32 (LABEL PersonInt32 {id_int32 INT32 PRIMARY KEY, name STRING}),
        NODE TYPE PersonUInt16 (LABEL PersonUInt16 {id_uint16 UINT16 PRIMARY KEY, name STRING}),
        NODE TYPE PersonInt64 (LABEL PersonInt64 {id_int64 INT64 PRIMARY KEY, name STRING}),
        EDGE TYPE KNOWS (PersonInt32)-[LABEL KNOWS {weight DOUBLE, MULTIEDGE KEY()}]->(PersonInt32)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #encoding_test_complex TYPED encoding_test_complex_gt
      """
    Then the execution should be successful
    When executing query:
      """
      FILE int8_file{id INT8, name STRING} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/int8_nodes.csv"
      }
      FILE int32_file{id INT32, name STRING} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/int32_nodes.csv"
      }
      FILE uint16_file{id UINT16, name STRING} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/uint16_nodes.csv"
      }
      FILE int64_file{id INT64, name STRING} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/int64_nodes.csv"
      }
      FILE edge_file{src INT32, dst INT32, weight DOUBLE} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/edges.csv"
      }
      USE #encoding_test_complex IMPORT INTO GRAPH {
        NODE (v@PersonInt8{id_int8:int8_file.id, name:int8_file.name}) FROM int8_file,
        NODE (v@PersonInt32{id_int32:int32_file.id, name:int32_file.name}) FROM int32_file,
        NODE (v@PersonUInt16{id_uint16:uint16_file.id, name:uint16_file.name}) FROM uint16_file,
        NODE (v@PersonInt64{id_int64:int64_file.id, name:int64_file.name}) FROM int64_file,
        EDGE (id_int32:edge_file.src)-[e@KNOWS{weight:edge_file.weight}]->(id_int32:edge_file.dst) FROM edge_file
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #encoding_test_complex SHOW STATS
      """
    Then the result should contain:
      | entry_name     | element_type | total_num |
      | "Node Total"   | "Node"       | 13        |
      | "Edge Total"   | "Edge"       | 2         |
      | "PersonInt8"   | "Node"       | 3         |
      | "PersonInt32"  | "Node"       | 3         |
      | "PersonUInt16" | "Node"       | 3         |
      | "PersonInt64"  | "Node"       | 4         |
      | "KNOWS"        | "Edge"       | 2         |
    And drop the graph "#encoding_test_complex"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #encoding_test_complex TYPED encoding_test_complex_gt
      """
    Then the execution should be successful
    When executing query:
      """
      FILE int8_file{id INT8, name STRING} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/int8_nodes.csv"
      }
      FILE int32_file{id INT32, name STRING} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/int32_nodes.csv"
      }
      FILE uint16_file{id UINT16, name STRING} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/uint16_nodes.csv"
      }
      FILE int64_file{id INT64, name STRING} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/int64_nodes.csv"
      }
      FILE edge_file{src INT32, dst INT32, weight DOUBLE} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/edges.csv"
      }
      USE #encoding_test_complex IMPORT INTO GRAPH {
        NODE (v@PersonInt8{id_int8:int8_file.id, name:int8_file.name}) FROM int8_file,
        NODE (v@PersonInt32{id_int32:int32_file.id, name:int32_file.name}) FROM int32_file,
        NODE (v@PersonUInt16{id_uint16:uint16_file.id, name:uint16_file.name}) FROM uint16_file,
        NODE (v@PersonInt64{id_int64:int64_file.id, name:int64_file.name}) FROM int64_file,
        EDGE (id_int32:edge_file.src)-[e@KNOWS{weight:edge_file.weight}]->(id_int32:edge_file.dst) FROM edge_file
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      """
    Then an Error should be raised: "Invalid node ID input: 9223372036854775807. Primary key value must not exceed 6 bytes when PRIMARY_KEY_AS_NODE_ID is enabled"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #encoding_test_without_int64 TYPED encoding_test_complex_gt
      """
    Then the execution should be successful
    When executing query:
      """
      FILE int8_file{id INT8, name STRING} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/int8_nodes.csv"
      }
      FILE int32_file{id INT32, name STRING} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/int32_nodes.csv"
      }
      FILE uint16_file{id UINT16, name STRING} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/uint16_nodes.csv"
      }
      FILE edge_file{src INT32, dst INT32, weight DOUBLE} = DATAFILE {
        FORMAT: "CSV",
        PATH: "file://${TEST_DIR}/dataset/external_source/csv_source/encoding_test/edges.csv"
      }
      USE #encoding_test_without_int64  IMPORT INTO GRAPH  {
        NODE (v@PersonInt8{id_int8:int8_file.id, name:int8_file.name}) FROM int8_file,
        NODE (v@PersonInt32{id_int32:int32_file.id, name:int32_file.name}) FROM int32_file,
        NODE (v@PersonUInt16{id_uint16:uint16_file.id, name:uint16_file.name}) FROM uint16_file,
        EDGE (id_int32:edge_file.src)-[e@KNOWS{weight:edge_file.weight}]->(id_int32:edge_file.dst) FROM edge_file
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:false}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #encoding_test_without_int64 SHOW STATS
      """
    Then the result should contain:
      | entry_name     | element_type | total_num |
      | "Node Total"   | "Node"       | 9         |
      | "Edge Total"   | "Edge"       | 2         |
      | "PersonInt8"   | "Node"       | 3         |
      | "PersonInt32"  | "Node"       | 3         |
      | "PersonUInt16" | "Node"       | 3         |
      | "PersonInt64"  | "Node"       | 0         |
      | "KNOWS"        | "Edge"       | 2         |
    And drop the graph "#encoding_test_complex"
    And drop the graph "#encoding_test_without_int64"
    And drop the graph type "encoding_test_complex_gt"

  Scenario: Import into non-empty temporary graph
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_while TYPED ldbc_type
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_while TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    # This test should ideally cover both graphd and analytic.
    # However, there is an existing issue (#10109),
    # so for now it is only applied to analytic and will be fixed later.
    When executing analytic query:
      """
      VALUE a INT = 0
      FILE f {id INT, name STRING} = DATAFILE {
        FORMAT:"csv",
        PATH:"file://${TEST_DIR}/dataset/external_source/mini_ldbc_graph/mini_ldbc_graph.v"
      }
      WHILE a < 2 THEN {
        SET a = a + 1
        USE #import_while IMPORT INTO GRAPH {
          NODE (v@Place{id:id, name:name}) FROM f
        }
      }
      """
    Then an Error should be raised: "Unsupported temporary graph operation: Import to non-empty graph"
    And drop the graph "#import_while"
