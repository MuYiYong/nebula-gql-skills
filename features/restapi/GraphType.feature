# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: restapi - graph type

  Scenario: graph types operation
    And create a http client with username "root" and password "NebulaGraph01"
    # list all graph types
    When request the rest api "GET /graphtypes" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {
          "tables": [
            {
              "schema": "/default_schema",
              "graph_type": "ldbc_type",
              "owner": "root"
            }
          ]
        }
      }
      """
    # create graph type
    When request the rest api "POST /graphtypes" with:
      """
      {
        "payload": {
          "name": "http_test_graph_type",
          "ifNotExists": true,
          "nodeTypes": [
            {
              "name": "Person",
              "labels": [
                "Person"
              ],
              "props": [
                {
                  "name": "id",
                  "type": "int",
                  "primaryKey": true
                },
                {
                  "name": "name",
                  "type": "string",
                  "notNull": false
                },
                {
                  "name": "age",
                  "type": "int",
                  "nullable": true
                }
              ]
            },
            {
              "name": "City",
              "labels": [
                "City"
              ],
              "props": [
                {
                  "name": "zipcode",
                  "type": "string",
                  "notNull": false
                },
                {
                  "name": "name",
                  "type": "string",
                  "notNull": false
                }
              ],
              "primaryKey": [
                "zipcode",
                "name"
              ]
            }
          ],
          "edgeTypes": [
            {
              "name": "LIVES_IN",
              "direction": "PointingLeft",
              "srcNodeType": "Person",
              "dstNodeType": "City",
              "labels": [
                "LIVES"
              ],
              "props": [
                {
                  "name": "start_time",
                  "type": "LOCAL DATETIME",
                  "notNull": true
                }
              ],
              "multiEdgeKey": [
                "start_time"
              ]
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # check the graph type again
    When request the rest api "GET /graphtypes/http_test_graph_type" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {
          "tables": [
            {
              "entity_type": "Node",
              "type_name": "Person",
              "type_pattern": "(Person)",
              "labels": ["Person"],
              "primary_key/multiedge_key": ["id"],
              "properties": ["id","name","age"]
            },
            {
              "entity_type": "Node",
              "type_name": "City",
              "type_pattern": "(City)",
              "labels": ["City"],
              "primary_key/multiedge_key": ["zipcode","name"],
              "properties": ["zipcode","name"]
            },
            {
              "entity_type": "Edge",
              "type_name": "LIVES_IN",
              "type_pattern": "(City)-[LIVES_IN]->(Person)",
              "labels": ["LIVES"],
              "primary_key/multiedge_key": ["start_time"],
              "properties": ["start_time"]
            }
          ]
        }
      }
      """
    # alter graph type: add node types
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "addNodeTypes": [
            {
              "ifNotExists": true,
              "name": "Country",
              "labels": [
                "Country"
              ],
              "props": [
                {
                  "name": "code",
                  "type": "string",
                  "primaryKey": true
                },
                {
                  "name": "name",
                  "type": "string"
                }
              ]
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: drop node types
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "dropNodeTypes": [
            {
              "name": "Country",
              "ifExists": false
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: add edge types
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "addEdgeTypes": [
            {
              "name": "HAS_PERSON",
              "direction": "PointingLeft",
              "srcNodeType": "City",
              "dstNodeType": "Person",
              "labels": [
                "HAS_PERSON"
              ],
              "props": [
                {
                  "name": "start_time",
                  "type": "LOCAL DATETIME",
                  "multiEdgeKey": true
                }
              ],
              "ifNotExists": false
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: drop edge types
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "dropEdgeTypes": [
            {
              "name": "HAS_PERSON",
              "ifExists": false
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: rename node types
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "renameNodeTypes": [
            {
              "oldName": "Person",
              "newName": "People"
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: rename edge types
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "renameEdgeTypes": [
            {
              "oldName": "LIVES_IN",
              "newName": "LIVES"
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter node types/add labels
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "alterNodeTypes": [
            {
              "name": "People",
              "addLabels": {
                "ifNotExists": false,
                "labels": [
                  "People"
                ]
              }
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter node types/drop labels
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "alterNodeTypes": [
            {
              "name": "People",
              "dropLabels": {
                "ifExists": false,
                "labels": [
                  "Person"
                ]
              }
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter node types/add properties
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "alterNodeTypes": [
            {
              "name": "People",
              "addProperties": {
                "ifNotExists": false,
                "props": [
                  {
                    "name": "phone",
                    "type": "string",
                    "default": ""
                  }
                ]
              }
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter node types/rename properties
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "alterNodeTypes": [
            {
              "name": "People",
              "renameProperties": [
                {
                  "oldName": "phone",
                  "newName": "phone_number"
                }
              ]
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter node types/modify properties
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "alterNodeTypes": [
            {
              "name": "People",
              "modifyProperties": [
                {
                  "name": "phone_number",
                  "type": "string",
                  "default": "911"
                }
              ]
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter node types/drop properties
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "alterNodeTypes": [
            {
              "name": "People",
              "dropProperties": {
                "ifExists": false,
                "props": [
                  "phone_number"
                ]
              }
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter edge types/add labels
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "alterEdgeTypes": [
            {
              "name": "LIVES",
              "addLabels": {
                "ifNotExists": false,
                "labels": [
                  "NEW_LIVES"
                ]
              }
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter edge types/drop labels
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload":{
          "alterEdgeTypes": [
            {
              "name": "LIVES",
              "dropLabels": {
                "ifExists": false,
                "labels": [
                  "NEW_LIVES"
                ]
              }
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter edge types/add properties
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "alterEdgeTypes": [
            {
              "name": "LIVES",
              "addProperties": {
                "ifNotExists": false,
                "props": [
                  {
                    "name": "end_time",
                    "type": "DATE",
                    "nullable": true
                  }
                ]
              }
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter edge types/rename properties
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "alterEdgeTypes": [
            {
              "name": "LIVES",
              "renameProperties": [
                {
                  "oldName": "end_time",
                  "newName": "end_date"
                }
              ]
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter edge types/modify properties
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "alterEdgeTypes": [
            {
              "name": "LIVES",
              "modifyProperties": [
                {
                  "name": "end_date",
                  "type": "DATE",
                  "nullable": false
                }
              ]
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    # alter graph type: alter edge types/drop properties
    When request the rest api "PATCH /graphtypes/http_test_graph_type" with:
      """
      {
        "payload": {
          "alterEdgeTypes": [
            {
              "name": "LIVES",
              "dropProperties": {
                "ifExists": false,
                "props": [
                  "end_date"
                ]
              }
            }
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    When request the rest api "DELETE /graphtypes/http_test_graph_type" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    When request the rest api "GET /graphtypes/http_test_graph_type" with: ""
    Then the http response should contain:
      """
      {
        "code": "01G04",
        "message": "Graph type not found: `http_test_graph_type`"
      }
      """
    And close the http client
