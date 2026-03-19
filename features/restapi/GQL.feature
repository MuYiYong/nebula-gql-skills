# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: restapi - GQL

  Scenario: GQL
    And create a http client with username "root" and password "NebulaGraph01"
    When request the rest api "POST /gql" with:
      """
      {
        "payload": {
          "gql": "PROFILE RETURN 1 AS a"
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
            {"a": 1}
          ]
        },
        "summary":{
          "explainType":"profile",
          "planInfo":{
            "batches": 0,
            "children": [
              {
                "batches": 0,
                "children": [
                  {
                    "batches": 0,
                    "children": [],
                    "details": "UNIT",
                    "name": "[P0]Values",
                    "rows": 1
                  }
                ],
                "details": "1 AS a",
                "name": "[P0]Project",
                "rows": 1
              }
            ],
            "details": "1 AS a",
            "name": "[P0]CallbackSink",
            "rows": 1
          },
          "queryStats":{
            "numAffectedEdges":0,
            "numAffectedNodes":0
          }
        }
      }
      """
    When request the rest api "POST /gql" with:
      """
      {
        "payload": {
          "gql": "USE ldbc MATCH (v) RETURN count(v) AS cnt GROUP BY ()"
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
            {"cnt": 34}
          ]
        }
      }
      """
    When request the rest api "POST /gql" with:
      """
      {
        "payload": {
          "gql": "RETURN DATE \"2025-10-27\" AS a, DATETIME \"2024-05-14T11:47:30\" AS b, DURATION \"P1D\" AS c, TIME \"11:47:30\" AS d, TIME \"11:47:30Z\" AS e"
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {
          "headers": ["a", "b", "c", "d", "e"],
          "tables": [
            {
              "a": "2025-10-27",
              "b": "2024-05-14T11:47:30.000000",
              "c": "P1DT0H0M0.000000S",
              "d": "11:47:30.000000",
              "e": "11:47:30.000000 +0000"
            }
          ]
        }
      }
      """
    When request the rest api "POST /gql" with:
      """
      {
        "payload": {
          "gql": "RETURN 1 AS z, 2 AS x, 3 AS y"
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "message": "",
        "data": {
          "headers": ["z", "x", "y"],
          "tables": [
            {
              "z": 1,
              "x": 2,
              "y": 3
            }
          ]
        }
      }
      """
    When request the rest api "POST /gql" with:
      """
      {
        "payload": {
          "gql": "USE ldbc MATCH (v)-[e:KNOWS]-(u) RETURN e LIMIT 1"
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code":"00000",
        "message":"",
        "cursor":"",
        "data": {
          "headers": ["e"],
          "tables": [
            {
              "e":{
                "graph":"ldbc",
                "isDirected":true,
                "kind":"edge",
                "labels":["KNOWS"],
                "properties":{
                  "creationDate":"2021-01-01T10:00:40.213000"
                },
                "rank":0,
                "type":"KNOWS"
              }
            }
          ]
        },
        "summary":{
          "explainType":"",
          "queryStats":{
            "numAffectedEdges":0,
            "numAffectedNodes":0
          }
        }
      }
      """
    When request the rest api "POST /gql" with:
      """
      {
        "payload": {
          "gql": "USE ldbc {\n      MATCH (p:Person{id : 24189255811707}), (friend:Person{firstName : \"Jun\"})\n        WHERE p<>friend\n      MATCH path = ANY SHORTEST PATH (p:Person{id: 24189255811707})<-[:KNOWS]->{1,3}(friend:Person)\n      RETURN min(length(path)) AS distance, friend GROUP BY friend\n      NEXT\n      ORDER BY\n          distance ASC,\n          friend.lastName ASC,\n          friend.id ASC\n      LIMIT 20\n      MATCH (friend:Person)-[:IS_LOCATED_IN]->(friendCity:City)\n      OPTIONAL MATCH (friend:Person)-[studyAt:STUDY_AT]->(uni:University)-[:IS_LOCATED_IN]->(uniCity:City)\n      RETURN collect(\n        CASE\n          WHEN NOT uni.name IS NULL THEN RECORD {uniName:uni.name, studyAtClassYear:studyAt.classYear,\n            uniCityName:uniCity.name}\n        END\n        ) AS unis, friend, friendCity, distance GROUP BY friend, friendCity, distance\n      NEXT\n      OPTIONAL MATCH (friend:Person)-[workAt:WORK_AT]->(company:Company)-[:IS_LOCATED_IN]->(companyCountry:Country)\n      ORDER BY\n          company.name ASC,\n          workAt.workFrom ASC,\n          companyCountry.name ASC\n      RETURN collect(\n        CASE\n          WHEN NOT company.name is null THEN RECORD {companyName:company.name, workAtWorkFrom:workAt.workFrom,\n            companyCountryName:companyCountry.name}\n        END\n        ) AS companies, friend, unis, friendCity, distance GROUP BY friend, unis, friendCity, distance\n      NEXT\n      ORDER BY\n          distance ASC,\n          friend.lastName ASC,\n          friend.id ASC\n      LIMIT 20\n      RETURN\n          friend.id AS friendId,\n          friend.lastName AS friendLastName,\n          distance AS distanceFromPerson,\n          friend.birthday AS friendBirthday,\n          friend.creationDate AS friendCreationDate,\n          friend.gender AS friendGender,\n          friend.browserUsed AS friendBrowserUsed,\n          friend.locationIP AS friendLocationIp,\n          friendCity.name AS friendCityName,\n          unis AS friendUniversities,\n          companies AS friendCompanies\n      }"
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "00000",
        "data": {}
      }
      """
    When request the rest api "POST /gql" with:
      """
      {
        "headers": [
          "X-Request-Timeout: 1"
        ],
        "payload": {
          "gql": "USE ldbc MATCH (v)-[e]-(v2) RETURN v,e,v2"
        }
      }
      """
    Then the http response should contain:
      """
      {
        "code": "NX003"
      }
      """
    And wait "1" seconds
    And close the http client
