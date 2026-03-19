# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: describe

  Scenario: describe graph or graph type or node type or edge type
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS desc_graph_type AS {
        NODE person (LABEL PERSON {id INT PRIMARY KEY, name STRING NOT NULL, gender STRING}),
        EDGE directed_follow (person)-[LABEL follow {followness INT, likeness DOUBLE}]->(person),
        EDGE friends (person)~[LABEL follow {intimacy DOUBLE}]~(person),
        EDGE uniq_edge (person)-[LABEL follow {p1 INT}]->(person),
        EDGE auto_edge (person)-[LABEL follow {p2 INT, MULTIEDGE KEY()}]->(person),
        EDGE single_prop_edge (person)-[LABEL follow {p3 INT, MULTIEDGE KEY(p3)}]->(person),
        EDGE multi_prop_edge (person)-[LABEL follow {p4 INT, p5 INT, MULTIEDGE KEY(p4, p5)}]->(person)
      }
      """
    Then the execution should be successful
    And graph type "desc_graph_type" should be ready to use
    When executing query:
      """
      DESC GRAPH TYPE desc_graph_type
      """
    Then the result should be, in any order:
      | entity_type | type_name          | type_pattern                            | labels          | primary_key/multiedge_key | properties                      |
      | "Node"      | "person"           | "(person)"                              | LIST ["PERSON"] | LIST ["id"]               | LIST ["id", "name", "gender"]   |
      | "Edge"      | "directed_follow"  | "(person)-[directed_follow]->(person)"  | LIST ["follow"] | "Unique"                  | LIST ["followness", "likeness"] |
      | "Edge"      | "friends"          | "(person)~[friends]~(person)"           | LIST ["follow"] | "Unique"                  | LIST ["intimacy"]               |
      | "Edge"      | "uniq_edge"        | "(person)-[uniq_edge]->(person)"        | LIST ["follow"] | "Unique"                  | LIST ["p1"]                     |
      | "Edge"      | "auto_edge"        | "(person)-[auto_edge]->(person)"        | LIST ["follow"] | "Auto"                    | LIST ["p2"]                     |
      | "Edge"      | "single_prop_edge" | "(person)-[single_prop_edge]->(person)" | LIST ["follow"] | LIST ["p3"]               | LIST ["p3"]                     |
      | "Edge"      | "multi_prop_edge"  | "(person)-[multi_prop_edge]->(person)"  | LIST ["follow"] | LIST ["p4", "p5"]         | LIST ["p4", "p5"]               |
    When executing query:
      """
      DESCRIBE GRAPH xxx
      """
    Then an Error should be raised: "[01G03]: Graph `xxx` not found in schema `/default_schema`"
    When executing query:
      """
      DESCRIBE GRAPH TYPE xxx_type
      """
    Then an Error should be raised: "[01G04]: Graph type not found: `xxx_type`"
    When executing query:
      """
      DESC NODE TYPE person OF desc_graph_type
      """
    Then the result should be, in any order:
      | property_name | data_type | primary_key | nullable | default |
      | "id"          | "INT64"   | "Y"         | false    | ""      |
      | "name"        | "STRING"  | ""          | false    | ""      |
      | "gender"      | "STRING"  | ""          | true     | "NULL"  |
    When executing query:
      """
      DESC NODE TYPE xxx OF desc_graph_type
      """
    Then an Error should be raised: "[NC003]: Node type not found: `xxx`"
    When executing query:
      """
      DESC EDGE TYPE friends OF desc_graph_type
      """
    Then the result should be, in any order:
      | property_name | data_type | multi_edge_key | nullable | default |
      | "intimacy"    | "DOUBLE"  | ""             | true     | "NULL"  |
    When executing query:
      """
      DESC EDGE TYPE xxx of ldbc_type
      """
    Then an Error should be raised: "[NC004]: Edge type not found: `xxx`"
    And drop the graph type "desc_graph_type"

  Scenario: temp graph
    When executing query:
      """
      DESC GRAPH #analytic_ldbc
      """
    Then the result should be, in any order:
      | graph_name       | graph_type_name |
      | "#analytic_ldbc" | "ldbc_type"     |
