# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Graph Variable Clear

  Scenario: Clear graph variable on graphd
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v)
      RETURN v.id, v.firstName
      """
    Then the result should be, in any order:
      | v.id | v.firstName |
      | 2    | "Tim"       |
      | 3    | "Ming"      |
      | 4    | "Sophie"    |
      | 1    | "Kyle"      |
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      SET g.clear()
      USE g
      MATCH (v)
      RETURN v.id, v.firstName
      """
    Then the result should be, in any order:
      | v.id | v.firstName |

  Scenario: Clear then binding table import on graphd
    And drop the graph type "bt_graph_var_clear_gt"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS bt_graph_var_clear_gt AS {
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
      GRAPH g_bt_clear TYPED bt_graph_var_clear_gt
      USE g_bt_clear {
        TABLE persons TYPED TABLE {id INT, name STRING} =
          {id: 1, name: "Alice"},
          {id: 2, name: "Bob"}

        TABLE edges TYPED TABLE {src_id INT, dst_id INT, id INT} =
          {src_id: 1, dst_id: 2, id: 10}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name }) FROM persons,
          EDGE (id:src_id)-[e@Knows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }

        SET g_bt_clear.clear()

        MATCH (p@Person)-[e@Knows]->(q@Person)
        RETURN p.id, p.name, q.id, q.name, e.id
        ORDER BY e.id
      }
      """
    Then the result should be, in order:
      | p.id | p.name | q.id | q.name | e.id |
    When executing query:
      """
      GRAPH g_bt_clear TYPED bt_graph_var_clear_gt
      USE g_bt_clear {
        TABLE persons TYPED TABLE {id INT, name STRING} =
          {id: 1, name: "Alice"},
          {id: 2, name: "Bob"}

        TABLE edges TYPED TABLE {src_id INT, dst_id INT, id INT} =
          {src_id: 1, dst_id: 2, id: 10}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name }) FROM persons,
          EDGE (id:src_id)-[e@Knows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }

        SET g_bt_clear.clear()

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
    When executing query:
      """
      GRAPH g_bt_clear TYPED bt_graph_var_clear_gt
      USE g_bt_clear {
        TABLE persons TYPED TABLE {id INT, name STRING} =
          {id: 1, name: "Alice"},
          {id: 2, name: "Bob"}

        TABLE edges TYPED TABLE {src_id INT, dst_id INT, id INT} =
          {src_id: 1, dst_id: 2, id: 10}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name }) FROM persons,
          EDGE (id:src_id)-[e@Knows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name }) FROM persons,
          EDGE (id:src_id)-[e@Knows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }

        MATCH (p@Person)-[e@Knows]->(q@Person)
        RETURN p.id, p.name, q.id, q.name, e.id
        ORDER BY e.id
      }
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: Import to non-empty graph"
    And drop the graph type "bt_graph_var_clear_gt"
