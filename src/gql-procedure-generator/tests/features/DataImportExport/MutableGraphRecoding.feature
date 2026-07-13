# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Mutable Graph Recoding

  Scenario: multi-type CSV data
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mut_multi_type_graph_type AS {
        NODE TYPE user (LABEL user {id_str STRING PRIMARY KEY, name STRING, age INT, email STRING, score DOUBLE}),
        NODE TYPE nproduct (LABEL nproduct {id INT PRIMARY KEY, name STRING, category STRING, price DOUBLE, stock INT}),
        // composite primary key
        NODE TYPE company (LABEL company {id_str STRING, name STRING, industry STRING, employee_count INT,  PRIMARY KEY(id_str, name)}),
        NODE TYPE order_node (LABEL order_node {id INT PRIMARY KEY, status STRING, total_amount DOUBLE, order_time INT}),
        EDGE TYPE purchase (user)-[LABEL purchase {quantity INT, purchase_time INT, rating INT, MULTIEDGE KEY()}]->(nproduct),
        EDGE TYPE work_for (user)-[LABEL work_for {position STRING, start_date INT, salary INT, MULTIEDGE KEY()}]->(company),
        EDGE TYPE contains (order_node)-[LABEL contains {quantity INT, unit_price DOUBLE, MULTIEDGE KEY()}]->(nproduct),
        EDGE TYPE friend (user)-[LABEL friend {since INT, intimacy INT, MULTIEDGE KEY()}]->(user)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mut_multi_type_users TYPED mut_multi_type_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 2) */
      USE #mut_multi_type_users IMPORT INTO GRAPH
      {
        NODE (v@user{id_str:user_id, name:name, age:age, email:email, score:score}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/user.csv",
          FORMAT: "csv",
          delimiter: ","
        }
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:false}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_multi_type_users SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 20        |
      | "Edge Total" | "Edge"       | 0         |
      | "user"       | "Node"       | 20        |
      | "nproduct"   | "Node"       | 0         |
      | "company"    | "Node"       | 0         |
      | "order_node" | "Node"       | 0         |
      | "purchase"   | "Edge"       | 0         |
      | "work_for"   | "Edge"       | 0         |
      | "contains"   | "Edge"       | 0         |
      | "friend"     | "Edge"       | 0         |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mut_multi_type_companies TYPED mut_multi_type_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 2) */
      USE #mut_multi_type_companies IMPORT INTO GRAPH
      {
        NODE (v@company{id_str:f.company_id, industry:f.industry, employee_count:f.employee_count}) FROM DATAFILE f {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/company.csv",
          FORMAT: "csv",
          delimiter: ","
        }
      }
      """
    Then an Error should be raised: "[NR125]: Invalid graph data source: Primary key `name` of type `company` must be mapped"
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 2) */
      USE #mut_multi_type_companies IMPORT INTO GRAPH
      {
        NODE (v@company{id_str:f.company_id, name:f.name, industry:f.industry, employee_count:f.employee_count}) FROM DATAFILE f {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/company.csv",
          FORMAT: "csv",
          delimiter: ","
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_multi_type_companies SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 15        |
      | "Edge Total" | "Edge"       | 0         |
      | "user"       | "Node"       | 0         |
      | "nproduct"   | "Node"       | 0         |
      | "company"    | "Node"       | 15        |
      | "order_node" | "Node"       | 0         |
      | "purchase"   | "Edge"       | 0         |
      | "work_for"   | "Edge"       | 0         |
      | "contains"   | "Edge"       | 0         |
      | "friend"     | "Edge"       | 0         |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mut_multi_type_products TYPED mut_multi_type_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 2) */
      USE #mut_multi_type_products IMPORT INTO GRAPH
      {
        NODE (v@nproduct{id:product_id, name:name, category:category, price:price, stock:stock}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/product.csv",
          FORMAT: "csv",
          delimiter: ","
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_multi_type_products SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 20        |
      | "Edge Total" | "Edge"       | 0         |
      | "user"       | "Node"       | 0         |
      | "nproduct"   | "Node"       | 20        |
      | "company"    | "Node"       | 0         |
      | "order_node" | "Node"       | 0         |
      | "purchase"   | "Edge"       | 0         |
      | "work_for"   | "Edge"       | 0         |
      | "contains"   | "Edge"       | 0         |
      | "friend"     | "Edge"       | 0         |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mut_multi_type_complete TYPED mut_multi_type_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #mut_multi_type_complete IMPORT INTO GRAPH
      {
        NODE (v@user{id_str:user_id, name:name, age:age, email:email, score:score}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/user.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        NODE (v@nproduct{id:product_id, name:name, category:category, price:price, stock:stock}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/product.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        NODE (v@company{id_str:company_id, name:name, industry:industry, employee_count:employee_count}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/company.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        NODE (v@order_node{id:order_id, status:status, total_amount:total_amount, order_time:order_time}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/order.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        EDGE (id_str:src_id)-[e@purchase{quantity:quantity, purchase_time:purchase_time, rating:rating}]->(id:dst_id) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/edge/purchase.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        EDGE (id_str:src_id)-[e@work_for{position:position, start_date:start_date, salary:salary}]->(id_str:f.dst_id, name:f.company_name) FROM DATAFILE f{
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/edge/work_for.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        EDGE (id:src_id)-[e@contains{quantity:quantity, unit_price:unit_price}]->(id:dst_id) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/edge/contains.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        EDGE (id_str:src_id)-[e@friend{since:since, intimacy:intimacy}]->(id_str:dst_id) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/edge/friend.csv",
          FORMAT: "csv",
          delimiter: ","
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_multi_type_complete SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 75        |
      | "Edge Total" | "Edge"       | 83        |
      | "user"       | "Node"       | 20        |
      | "nproduct"   | "Node"       | 20        |
      | "company"    | "Node"       | 15        |
      | "order_node" | "Node"       | 20        |
      | "purchase"   | "Edge"       | 25        |
      | "work_for"   | "Edge"       | 15        |
      | "contains"   | "Edge"       | 23        |
      | "friend"     | "Edge"       | 20        |
    When executing query:
      """
      USE #mut_multi_type_complete {
        TABLE user_test TYPED TABLE {id_str STRING, name STRING, age INT, email STRING, score DOUBLE}
        MATCH(v:user)
        PER NODE (v){
          EXPORT v.id_str,v.name,v.age,v.email,v.score INTO user_test
        }
        FOR r IN user_test
        RETURN r.id_str,r.name,r.age,r.email,r.score
      }
      """
    Then the result should be, in any order:
      | r.id_str      | r.name            | r.age | r.email                | r.score |
      | "user_abc123" | "Alice Johnson"   | 28    | "alice@example.com"    | 85.6    |
      | "user_def456" | "Bob Smith"       | 34    | "bob@example.com"      | 92.3    |
      | "user_ghi789" | "Charlie Brown"   | 25    | "charlie@example.com"  | 76.8    |
      | "user_jkl012" | "Diana Prince"    | 31    | "diana@example.com"    | 88.9    |
      | "user_mno345" | "Edward King"     | 29    | "edward@example.com"   | 91.2    |
      | "user_pqr678" | "Fiona White"     | 27    | "fiona@example.com"    | 73.4    |
      | "user_stu901" | "George Miller"   | 33    | "george@example.com"   | 87.5    |
      | "user_vwx234" | "Helen Davis"     | 26    | "helen@example.com"    | 89.7    |
      | "user_yz567"  | "Ian Wilson"      | 30    | "ian@example.com"      | 82.1    |
      | "user_abc890" | "Jane Foster"     | 32    | "jane@example.com"     | 90.8    |
      | "user_def123" | "Kevin Clark"     | 28    | "kevin@example.com"    | 86.3    |
      | "user_ghi456" | "Laura Thompson"  | 35    | "laura@example.com"    | 94.2    |
      | "user_jkl789" | "Michael Lee"     | 24    | "michael@example.com"  | 79.5    |
      | "user_mno012" | "Nancy Rodriguez" | 29    | "nancy@example.com"    | 88.1    |
      | "user_pqr345" | "Oliver Martinez" | 31    | "oliver@example.com"   | 91.6    |
      | "user_stu678" | "Patricia Garcia" | 27    | "patricia@example.com" | 75.9    |
      | "user_vwx901" | "Quinn Anderson"  | 33    | "quinn@example.com"    | 89.4    |
      | "user_yz234"  | "Rachel Taylor"   | 26    | "rachel@example.com"   | 87.8    |
      | "user_abc567" | "Samuel Thomas"   | 30    | "samuel@example.com"   | 83.2    |
      | "user_def890" | "Tina Jackson"    | 32    | "tina@example.com"     | 92.5    |
    When executing query:
      """
      USE #mut_multi_type_complete {
        TABLE purchase_test TYPED TABLE {user_id STRING, product_id INT, quantity INT, purchase_time INT, rating INT}
        MATCH(v)-[e:purchase]->(u)
        PER PATH {
          EXPORT v.id_str, u.id, e.quantity, e.purchase_time, e.rating INTO purchase_test
        }
        FOR r IN purchase_test
        RETURN r.user_id,r.product_id,r.quantity,r.purchase_time,r.rating
      }
      """
    Then the result should be, in any order:
      | r.user_id     | r.product_id | r.quantity | r.purchase_time | r.rating |
      | "user_abc123" | 100001       | 1          | 1641081600      | 5        |
      | "user_abc123" | 100003       | 1          | 1642809600      | 4        |
      | "user_def456" | 100002       | 2          | 1641168000      | 5        |
      | "user_def456" | 100007       | 1          | 1642896000      | 5        |
      | "user_ghi789" | 100003       | 1          | 1641254400      | 4        |
      | "user_ghi789" | 100012       | 1          | 1642982400      | 4        |
      | "user_jkl012" | 100004       | 1          | 1641340800      | 5        |
      | "user_jkl012" | 100016       | 3          | 1643068800      | 5        |
      | "user_mno345" | 100005       | 1          | 1641427200      | 4        |
      | "user_mno345" | 100002       | 1          | 1643155200      | 5        |
      | "user_pqr678" | 100006       | 3          | 1641513600      | 4        |
      | "user_stu901" | 100007       | 1          | 1641600000      | 5        |
      | "user_vwx234" | 100008       | 1          | 1641686400      | 4        |
      | "user_yz567"  | 100009       | 1          | 1641772800      | 5        |
      | "user_abc890" | 100010       | 1          | 1641859200      | 4        |
      | "user_def123" | 100011       | 1          | 1641945600      | 5        |
      | "user_ghi456" | 100012       | 1          | 1642032000      | 4        |
      | "user_jkl789" | 100013       | 1          | 1642118400      | 5        |
      | "user_mno012" | 100014       | 1          | 1642204800      | 4        |
      | "user_pqr345" | 100015       | 2          | 1642291200      | 4        |
      | "user_stu678" | 100016       | 2          | 1642377600      | 5        |
      | "user_vwx901" | 100017       | 1          | 1642464000      | 5        |
      | "user_yz234"  | 100018       | 1          | 1642550400      | 4        |
      | "user_abc567" | 100019       | 1          | 1642636800      | 5        |
      | "user_def890" | 100020       | 1          | 1642723200      | 4        |
    And drop the graph "#mut_multi_type_users"
    And drop the graph "#mut_multi_type_companies"
    And drop the graph "#mut_multi_type_products"
    And drop the graph "#mut_multi_type_complete"
    And drop the graph type "mut_multi_type_graph_type"

  Scenario: invalid data test
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mut_invalid_data_test AS {
        NODE TYPE nproduct (LABEL nproduct {id INT PRIMARY KEY, name STRING, category STRING, price DOUBLE, stock INT}),
        NODE TYPE order_node (LABEL order_node {id INT PRIMARY KEY, status STRING, total_amount DOUBLE, order_time INT}),
        EDGE TYPE contains (order_node)-[LABEL contains {quantity INT, unit_price DOUBLE, MULTIEDGE KEY()}]->(nproduct)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dangling_contains TYPED mut_invalid_data_test
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #dangling_contains IMPORT INTO GRAPH
      {
        NODE (v@nproduct{id:product_id, name:name, category:category, price:price, stock:stock}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/product.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        NODE (v@order_node{id:order_id, status:status, total_amount:total_amount, order_time:order_time}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/order.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        EDGE (id:src_id)-[e@contains{quantity:quantity, unit_price:unit_price}]->(id:dst_id) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/edge/dangling_contains.csv",
          FORMAT: "csv",
          delimiter: ","
        }
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      """
    Then an Error should be raised: "[NR124]: Failed to build temporary graph: There're dangling edges"
    And drop the graph "#dangling_contains"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mut_dangling_contains_new TYPED mut_invalid_data_test
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #mut_dangling_contains_new IMPORT INTO GRAPH
      {
        NODE (v@nproduct{id:product_id, name:name, category:category, price:price, stock:stock}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/product.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        NODE (v@order_node{id:order_id, status:status, total_amount:total_amount, order_time:order_time}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/order.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        EDGE (id:src_id)-[e@contains{quantity:quantity, unit_price:unit_price}]->(id:dst_id) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/edge/dangling_contains.csv",
          FORMAT: "csv",
          delimiter: ","
        }
      }
      """
    Then an Error should be raised: "[NR124]: Failed to build temporary graph: There're dangling edges"
    When executing query:
      """
      USE #mut_dangling_contains_new SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
      | "nproduct"   | "Node"       | 0         |
      | "order_node" | "Node"       | 0         |
      | "contains"   | "Edge"       | 0         |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mut_null_pk_order TYPED mut_invalid_data_test
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #mut_null_pk_order IMPORT INTO GRAPH
      {
        NODE (v@nproduct{id:product_id, name:name, category:category, price:price, stock:stock}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/product.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        NODE (v@order_node{id:order_id, status:status, total_amount:total_amount, order_time:order_time}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/null_pk_order.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        EDGE (id:src_id)-[e@contains{quantity:quantity, unit_price:unit_price}]->(id:dst_id) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/edge/contains.csv",
          FORMAT: "csv",
          delimiter: ","
        }
      }
      """
    Then an Error should be raised: "Property `id` of type `order_node` is not nullable"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mut_null_pk_contains TYPED mut_invalid_data_test
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #mut_null_pk_contains IMPORT INTO GRAPH
      {
        NODE (v@nproduct{id:product_id, name:name, category:category, price:price, stock:stock}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/product.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        NODE (v@order_node{id:order_id, status:status, total_amount:total_amount, order_time:order_time}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/order.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        EDGE (id:src_id)-[e@contains{quantity:quantity, unit_price:unit_price}]->(id:dst_id) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/edge/null_pk_contains.csv",
          FORMAT: "csv",
          delimiter: ","
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_null_pk_contains SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 40        |
      | "Edge Total" | "Edge"       | 17        |
      | "nproduct"   | "Node"       | 20        |
      | "order_node" | "Node"       | 20        |
      | "contains"   | "Edge"       | 17        |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mut_null_pk_contains_1 TYPED mut_invalid_data_test
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #mut_null_pk_contains_1 IMPORT INTO GRAPH
      {
        NODE (v@nproduct{id:product_id, name:name, category:category, price:price, stock:stock}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/product.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        NODE (v@order_node{id:order_id, status:status, total_amount:total_amount, order_time:order_time}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/node/order.csv",
          FORMAT: "csv",
          delimiter: ","
        },
        EDGE (id:src_id)-[e@contains{quantity:quantity, unit_price:unit_price}]->(id:dst_id) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/external_source/multi_type/edge/null_pk_contains.csv",
          FORMAT: "csv",
          delimiter: ","
        }
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_null_pk_contains_1 SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 40        |
      | "Edge Total" | "Edge"       | 17        |
      | "nproduct"   | "Node"       | 20        |
      | "order_node" | "Node"       | 20        |
      | "contains"   | "Edge"       | 17        |
    And drop the graph "#mut_dangling_contains_new"
    And drop the graph "#mut_null_pk_order"
    And drop the graph "#mut_null_pk_contains"
    And drop the graph "#mut_null_pk_contains_1"
    And drop the graph type "mut_invalid_data_test"
