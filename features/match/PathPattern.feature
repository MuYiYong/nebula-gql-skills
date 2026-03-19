# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Path Pattern

  Scenario: Shortest PATH
    When executing query:
      """
      USE ldbc
      MATCH  SHORTEST 1 PATH (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      USE ldbc
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 1                  |
    When executing query:
      """
      PARAMETERS $n=1
      USE ldbc
      MATCH  SHORTEST $n PATH (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      USE ldbc
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 1                  |
    When executing query:
      """
      PARAMETERS $n="a"
      USE ldbc
      MATCH  SHORTEST $n PATH (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      USE ldbc
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then an Error should be raised: "[NS214]: Invalid type NUMBER OF PATHS expression type: `STRING`, expect `unsigned integer`"
    When executing query:
      """
      USE ldbc
      MATCH  ANY 1 TRAIL (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      USE ldbc
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the execution should be successful

  # shortest group search is not supported. The following test case may be not correct.
  @skip
  Scenario: Shortest Group
    When executing query:
      """
      USE ldbc
      MATCH  SHORTEST 1 PATH GROUPS (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 1                  |
    When executing query:
      """
      PARAMETERS $n=2
      USE ldbc
      MATCH  SHORTEST $n PATH GROUPS (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 1                  |
    When executing query:
      """
      PARAMETERS $n="nebula"
      USE ldbc
      MATCH  SHORTEST $n PATH GROUPS (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then an Error should be raised: "[NS215]: Invalid type NUMBER OF GROUPS expression type: `STRING`, expect `unsigned integer`"

  Scenario: Consecutive quantified path
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS social_network_graph_type AS {
        NODE Person (LABEL PERSON {id INT64 PRIMARY KEY}),
        EDGE FOLLOW (Person)-[:FOLLOW{sinceyear INT}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS social_network_graph typed social_network_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE social_network_graph
      INSERT (a:PERSON{id:1})-[:FOLLOW{sinceyear:1999}]->(b:PERSON{id:2}),
      (b)-[:FOLLOW{sinceyear:2001}]->(c:PERSON{id:3}),
        (c)-[:FOLLOW{sinceyear:2002}]->(d:PERSON{id:4}),
        (d)-[:FOLLOW{sinceyear:2003}]->(e:PERSON{id:5}),
        (b)-[:FOLLOW{sinceyear:2004}]->(a),
        (e)-[:FOLLOW{sinceyear:2005}]->(b),
        (b)-[:FOLLOW{sinceyear:2006}]->(e)
      """
    Then the execution should be successful
    When executing query:
      """
      USE social_network_graph
      MATCH p = (v:PERSON{id:1})-[e]->{1, 2}(v1)-[e1]->{1, 2}(v2)
      RETURN TRANSFORM(NODES(p), x -> x.id) AS id
      """
    Then the result should be, in any order:
      | id              |
      | LIST[1,2,1]     |
      | LIST[1,2,1,2,1] |
      | LIST[1,2,5,2,1] |
      | LIST[1,2,3]     |
      | LIST[1,2,1,2,3] |
      | LIST[1,2,5,2,3] |
      | LIST[1,2,3,4]   |
      | LIST[1,2,3,4]   |
      | LIST[1,2,5]     |
      | LIST[1,2,3,4,5] |
      | LIST[1,2,1,2,5] |
      | LIST[1,2,5,2,5] |
      | LIST[1,2,1,2]   |
      | LIST[1,2,5,2]   |
      | LIST[1,2,1,2]   |
      | LIST[1,2,5,2]   |
    When executing query:
      """
      USE social_network_graph
      MATCH p = (v:PERSON{id:1})-[e]->{2}()-[e1]-{1, 2}(v)
      RETURN DISTINCT TRANSFORM(NODES(p), x -> x.id) AS id
      """
    Then the result should be, in any order:
      | id              |
      | LIST[1,2,3,2,1] |
      | LIST[1,2,1,2,1] |
      | LIST[1,2,5,2,1] |
    When executing query:
      """
      USE social_network_graph
      MATCH p = TRAIL (v:PERSON{id:1})-[e]->{2}()-[e1]-{1, 2}(v)
      RETURN DISTINCT TRANSFORM(NODES(p), x -> x.id) AS id
      """
    Then the result should be, in any order:
      | id              |
      | LIST[1,2,5,2,1] |
    When executing query:
      """
      USE social_network_graph
      MATCH p = () ((v:PERSON{id:1})->(v2)<-(v1)){1, 2} ()
      RETURN TRANSFORM(NODES(p), x -> x.id) AS id
      """
    Then the result should be, in any order:
      | id              |
      | LIST[1,2,5]     |
      | LIST[1,2,1,2,5] |
      | LIST[1,2,1]     |
      | LIST[1,2,1,2,1] |
    When executing query:
      """
      USE social_network_graph
      MATCH p = () ((v:PERSON{id:1})-(v2)-(v1)){1} () ((v3:PERSON{id:1})-()-(v4)){1, 2} ()
      RETURN DISTINCT TRANSFORM(NODES(p), x -> x.id) AS id
      """
    Then the result should be, in any order:
      | id                  |
      | LIST[1,2,1,2,1]     |
      | LIST[1,2,1,2,1,2,1] |
      | LIST[1,2,1,2,3]     |
      | LIST[1,2,1,2,1,2,3] |
      | LIST[1,2,1,2,5]     |
      | LIST[1,2,1,2,1,2,5] |
    When executing query:
      """
      USE social_network_graph
      MATCH p = TRAIL () ((v:PERSON{id:1})-(v2)-(v1)){1} () ((v3:PERSON{id:1})-()-(v4)){1, 2} ()
      RETURN DISTINCT TRANSFORM(NODES(p), x -> x.id) AS id
      """
    Then the result should be, in any order:
      | id              |
      | LIST[1,2,1,2,1] |
      | LIST[1,2,1,2,3] |
      | LIST[1,2,1,2,5] |
    When executing query:
      """
      USE social_network_graph
      MATCH p = () ((v:PERSON{id:1})-(v2)-(v1)){1} ()-[e]->{1, 3}(v3)
      RETURN DISTINCT TRANSFORM(NODES(p), x -> x.id) AS id
      """
    Then the result should be, in any order:
      | id                |
      | LIST[1,2,5,2,1]   |
      | LIST[1,2,1,2,1]   |
      | LIST[1,2,5,2,3]   |
      | LIST[1,2,1,2,3]   |
      | LIST[1,2,5,2,5]   |
      | LIST[1,2,1,2,5]   |
      | LIST[1,2,3,4,5]   |
      | LIST[1,2,5,2]     |
      | LIST[1,2,1,2]     |
      | LIST[1,2,5,2,1,2] |
      | LIST[1,2,1,2,1,2] |
      | LIST[1,2,5,2,5,2] |
      | LIST[1,2,1,2,5,2] |
      | LIST[1,2,3,4,5,2] |
      | LIST[1,2,3,4]     |
      | LIST[1,2,5,2,3,4] |
      | LIST[1,2,1,2,3,4] |
    And drop the graph "social_network_graph"
    And drop the graph type "social_network_graph_type"
