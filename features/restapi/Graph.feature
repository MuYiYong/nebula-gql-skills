# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: restapi - graph

  Scenario: graph operation
    And create a http client with username "root" and password "NebulaGraph01"
    When request the rest api "POST /graphs" with:
      """
      {
        "payload": {
          "name": "http_test_ve_graph",
          "graphType": "ldbc_type",
          "ifNotExists": true
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {}
      }
      """
    When request the rest api "GET /graphs/http_test_ve_graph" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {
          "tables": [
            {
              "graph_name": "http_test_ve_graph",
              "graph_type_name": "ldbc_type"
            }
          ]
        }
      }
      """
    When request the rest api "GET /graphs/http_test_ve_graph/nodes" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {}
      }
      """
    When request the rest api "GET /graphs/http_test_ve_graph/edges" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {}
      }
      """
    When request the rest api "POST /graphs/http_test_ve_graph/nodes" with:
      """
      {
        "payload": {
          "onConflict": "replace",
          "nodes": [
            {"nodeType": "Person", "props": {"id": 1, "firstName": "p1"}},
            {"nodeType": "Person", "props": {"id": 2, "firstName": "p2"}}
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {},
        "summary": {
          "queryStats": {
            "numAffectedNodes": 2,
            "numAffectedEdges": 0,
            "outputPaths": [],
            "numExportedRecords": 0
          }
        }
      }
      """
    When request the rest api "GET /graphs/http_test_ve_graph/nodes/1" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {}
      }
      """
    When request the rest api "GET /graphs/http_test_ve_graph/nodes?property=id&value=1" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {
          "headers": ["v"],
          "tables": [
            {
              "v": {
                "kind": "node",
                "type": "Person",
                "graph": "http_test_ve_graph",
                "labels": [
                  "Person"
                ],
                "properties": {
                  "id": 1,
                  "firstName": "p1"
                }
              }
            }
          ]
        }
      }
      """
    When request the rest api "GET /graphs/http_test_ve_graph/nodes" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {
          "headers": ["v"],
          "tables": [
            {
              "v": {
                "kind": "node",
                "type": "Person",
                "graph": "http_test_ve_graph",
                "labels": [
                  "Person"
                ],
                "properties": {
                  "id": 1,
                  "firstName": "p1"
                }
              }
            },
            {
              "v": {
                "kind": "node",
                "type": "Person",
                "graph": "http_test_ve_graph",
                "labels": [
                  "Person"
                ],
                "properties": {
                  "id": 2,
                  "firstName": "p2"
                }
              }
            }
          ]
        }
      }
      """
    When request the rest api "POST /graphs/http_test_ve_graph/edges" with:
      """
      {
        "payload": {
          "onConflict": "replace",
          "srcType": "Person",
          "dstType": "Person",
          "edgeType": "FOLLOWS",
          "isDirected": true,
          "edges": [
            {
              "srcId": 1,
              "dstId": 2,
              "props": {
                "src": 1,
                "dst": 2
              }
            }
          ]
        }
      }
      """
    # fail to insert edges since the src/dst node ids
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {},
        "summary": {
          "queryStats": {
            "numAffectedNodes": 0,
            "numAffectedEdges": 0,
            "outputPaths": [],
            "numExportedRecords": 0
          }
        }
      }
      """
    # Use primary key
    When request the rest api "POST /graphs/http_test_ve_graph/edges" with:
      """
      {
        "payload": {
          "onConflict": "replace",
          "srcType": "Person",
          "dstType": "Person",
          "edgeType": "FOLLOWS",
          "isDirected": true,
          "edges": [
            {
              "srcKey": { "id": 1 },
              "dstKey": { "id": 2 },
              "props": {
                "src": 1,
                "dst": 2
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
        "message": "",
        "data": {},
        "summary": {
          "queryStats": {
            "numAffectedNodes": 0,
            "numAffectedEdges": 1
          }
        }
      }
      """
    # test mixed usage of key and id
    When request the rest api "POST /graphs/http_test_ve_graph/edges" with:
      """
      {
        "payload": {
          "onConflict": "replace",
          "srcType": "Person",
          "dstType": "Person",
          "edgeType": "FOLLOWS",
          "isDirected": true,
          "edges": [
            {
              "srcKey": { "id": 1 },
              "dstId": 2,
              "props": {
                "src": 1,
                "dst": 2
              }
            }
          ]
        }
      }
      """
    Then an http error should be raised: "Bad Request"
    When request the rest api "GET /graphs/http_test_ve_graph/edges?edgeType=FOLLOWS&srcId=1&dstId=2" with: ""
    # not easy to test according to the internal id of src/dst nodes
    # "data": [
    # {
    # "e": {
    # "kind": "edge",
    # "graph": "http_test_ve_graph",
    # "type": "FOLLOWS",
    # "labels": [
    # "FOLLOWS"
    # ],
    # "properties": {
    # "src": 1,
    # "src": 2
    # }
    # }
    # }
    # ]
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {}
      }
      """
    When request the rest api "PATCH /graphs/http_test_ve_graph/nodes/1" with:
      """
      {
        "payload": {
          "nodeType": "Person",
          "props": {
            "firstName": "p10"
          }
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {},
        "summary": {
          "queryStats": {
            "numAffectedNodes": 0,
            "numAffectedEdges": 0,
            "outputPaths": [],
            "numExportedRecords": 0
          }
        }
      }
      """
    When request the rest api "GET /graphs/http_test_ve_graph/nodes/1" with: ""
    # not easy to test according to the internal node id
    # "data": [
    # {
    # "kind": "node",
    # "type": "Person",
    # "graph": "http_test_ve_graph",
    # "labels": [
    # "Person"
    # ],
    # "properties": {
    # "id": 1,
    # "name": "p10"
    # }
    # }
    # ]
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {}
      }
      """
    When request the rest api "PATCH /graphs/http_test_ve_graph/edges" with:
      """
      {
        "payload": {
          "edgeType": "FOLLOWS",
          "srcId": 1,
          "dstId": 2,
          "props": {
            "src": 2,
            "dst": 1
          }
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {},
        "summary": {
          "queryStats": {
            "numAffectedNodes": 0,
            "numAffectedEdges": 0,
            "outputPaths": [],
            "numExportedRecords": 0
          }
        }
      }
      """
    When request the rest api "PATCH /graphs/http_test_ve_graph/edges" with:
      """
      {
        "payload": {
          "edgeType": "FOLLOWS",
          "srcKey": { "id": 1 },
          "dstKey": { "id": 2 },
          "props": {
            "src": 1,
            "dst": 2
          }
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {},
        "summary": {
          "queryStats": {
            "numAffectedNodes": 0,
            "numAffectedEdges": 1
          }
        }
      }
      """
    When request the rest api "PATCH /graphs/http_test_ve_graph/edges" with:
      """
      {
        "payload": {
          "edgeType": "FOLLOWS",
          "srcId": 1,
          "dstKey": { "id": 2 },
          "props": {
            "src": 2,
            "dst": 1
          }
        }
      }
      """
    Then an http error should be raised: "Bad Request"
    When request the rest api "GET /graphs/http_test_ve_graph/edges?edgeType=FOLLOWS&srcId=1&dstId=2" with: ""
    # not easy to test according to the internal id of src/dst nodes
    # "data": [
    # { "e": {
    # "kind": "edge",
    # "graph": "http_test_ve_graph",
    # "type": "FOLLOWS",
    # "labels": [
    # "FOLLOWS"
    # ],
    # "properties": {
    # "src": 2,
    # "src": 1
    # }
    # }
    # }
    # ]
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {}
      }
      """
    When request the rest api "DELETE /graphs/http_test_ve_graph/edges?edgeType=FOLLOWS&srcId=1&dstId=2" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {},
        "summary": {
          "queryStats": {
            "numAffectedNodes": 0,
            "numAffectedEdges": 0,
            "outputPaths": [],
            "numExportedRecords": 0
          }
        }
      }
      """
    When request the rest api "GET /graphs/http_test_ve_graph/edges" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {}
      }
      """
    When request the rest api "DELETE /graphs/http_test_ve_graph/nodes/1" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {},
        "summary": {
          "queryStats": {
            "numAffectedNodes": 0,
            "numAffectedEdges": 0,
            "outputPaths": [],
            "numExportedRecords": 0
          }
        }
      }
      """
    When request the rest api "DELETE /graphs/http_test_ve_graph/nodes/2" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {},
        "summary": {
          "queryStats": {
            "numAffectedNodes": 0,
            "numAffectedEdges": 0,
            "outputPaths": [],
            "numExportedRecords": 0
          }
        }
      }
      """
    When request the rest api "GET /graphs/http_test_ve_graph/nodes" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {}
      }
      """
    When request the rest api "DELETE /graphs/http_test_ve_graph" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {}
      }
      """
    When request the rest api "GET /graphs" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": ""
      }
      """
    And close the http client
