# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Geographic Index Operations

  Scenario: Test spatial index cleanup when dropping geography properties and types
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS geo_test_type AS {
        NODE TYPE geo_node1 ( label location1 { id int, location Geography(Point), primary key(id) }),
        NODE TYPE geo_node2 ( label location2 { id int, location Geography(Point), primary key(id) }),
        EDGE TYPE geo_edge1 (geo_node1)-[label route1 { path Geography(LineString) }]->(geo_node1),
        EDGE TYPE geo_edge2 (geo_node2)-[label route2 { path Geography(LineString) }]->(geo_node2)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH geo_test_graph TYPED geo_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo_test_graph CREATE SPATIAL INDEX IF NOT EXISTS geo_node1_idx ON NODE geo_node1(location, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo_test_graph CREATE SPATIAL INDEX IF NOT EXISTS geo_node2_idx ON NODE geo_node2(location, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo_test_graph CREATE SPATIAL INDEX IF NOT EXISTS geo_edge1_idx ON EDGE geo_edge1(path, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo_test_graph CREATE SPATIAL INDEX IF NOT EXISTS geo_edge2_idx ON EDGE geo_edge2(path, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE geo_test_type {
        ALTER NODE TYPE geo_node1
        DROP PROPERTIES {location}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE geo_test_type {
        ALTER EDGE TYPE geo_edge1
        DROP PROPERTIES {path}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE geo_test_type {
        DROP EDGE TYPE geo_edge2
      }
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE geo_test_type {
        DROP NODE TYPE geo_node2
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS geo_test_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE geo_test_type
      """
    Then the execution should be successful
