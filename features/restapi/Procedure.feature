# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: restapi - procedure

  Scenario: procedures operation
    And create a http client with username "root" and password "NebulaGraph01"
    When request the rest api "GET /procedures" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {
          "tables": [
            {
              "comment": "show procedure by procedure name",
              "module": "dbms.so",
              "name": "show_procedure",
              "null_case": "",
              "owner": "",
              "parameters": "procedure_name:STRING",
              "proc_type": "CPP",
              "return_fields": "proc_type:STRING, module:STRING, schema:STRING, owner:STRING, name:STRING, parameters:STRING, return_fields:STRING, null_case:STRING, comment:STRING",
              "schema": ""
            }
          ]
        }
      }
      """
    When request the rest api "GET /procedures/show_procedure" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {
          "tables": [
            {
              "comment": "show procedure by procedure name",
              "module": "dbms.so",
              "name": "show_procedure",
              "null_case": "",
              "owner": "",
              "parameters": "procedure_name:STRING",
              "proc_type": "CPP",
              "return_fields": "proc_type:STRING, module:STRING, schema:STRING, owner:STRING, name:STRING, parameters:STRING, return_fields:STRING, null_case:STRING, comment:STRING",
              "schema": ""
            }
          ]
        }
      }
      """
    When request the rest api "POST /procedures/show_procedure/call" with:
      """
      {
        "payload": {
          "params": [
            "show_current_session"
          ],
          "returns": [
            "name"
          ]
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {
          "tables": [
            {
              "name": "show_current_session"
            }
          ]
        }
      }
      """
    When request the rest api "DELETE /procedures/show_procedure" with: ""
    Then the http response should contain:
      """
      {
        "code": "01G12",
        "message": "Procedure not found: `show_procedure()`"
      }
      """
    And close the http client
