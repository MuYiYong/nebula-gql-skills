# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: BindingTable GraphVariable Import

  Scenario: Import binding table into graph variable on graphd
    And drop the graph type "bt_graph_var_import_gt"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS bt_graph_var_import_gt AS {
        NODE Person (
          LABEL Person {
            id INT PRIMARY KEY,
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
    When executing query:
      """
      GRAPH g_bt_import TYPED bt_graph_var_import_gt
      USE g_bt_import {
        TABLE persons TYPED TABLE {id INT, name STRING} =
          {id: 1, name: "Alice"},
          {id: 2, name: "Bob"}

        TABLE edges TYPED TABLE {src_id INT, dst_id INT, id INT} =
          {src_id: 1, dst_id: 2, id: 10}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name }) FROM persons,
          EDGE (id:src_id)-[e@Knows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }

        MATCH (p@Person)-[e@Knows]->(q@Person)
        RETURN p.id, p.name, q.id, q.name, e.id
        ORDER BY e.id
      }
      """
    Then the result should be, in order:
      | p.id | p.name  | q.id | q.name | e.id |
      | 1    | "Alice" | 2    | "Bob"  | 10   |
    And drop the graph type "bt_graph_var_import_gt"
