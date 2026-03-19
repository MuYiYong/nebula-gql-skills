# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Insert on MemGraph

  Scenario: InsertCast
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_insert_cast_type AS {
        NODE n (LABEL n {id INT PRIMARY KEY, u8 UINT8, f FLOAT, d DOUBLE, l LIST<FLOAT>})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #insert_cast TYPED mem_insert_cast_type
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id, u8, f, l} = (1, 2, 1, [1, 2])
      USE #insert_cast
      FOR r IN t
      INSERT (@n {id: r.id, u8: cast(r.u8 as UINT8), f: r.f, l: cast(r.l as LIST<FLOAT>)})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      TABLE t {id, u8, f, l} = (2, 2, 1, [1.5, 2.5])
      USE #insert_cast
      FOR r IN t
      INSERT (@n {id: r.id, u8: cast(r.u8 as UINT8), f: r.f, l: r.l})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    And drop the graph "#insert_cast"
    And drop the graph type "mem_insert_cast_type"

  Scenario: InsertInValidData
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_nba_insert_in_valid_data AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT, likeness FLOAT64}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #insert_test_graph TYPED mem_graph_type_nba_insert_in_valid_data
      """
    Then the execution should be successful
    When executing query:
      """
      USE #insert_test_graph INSERT
        (@node_type_player{id:11, name:"Tim", score: 87.0, gender: true, rate: 7.32}),
        (@node_type_player{id:12, name:"Jerry", score: 95.0, gender: false, rate: 4.01})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_test_graph INSERT (@node_type_player{id:"11", name:"Tim", score: 87.0, gender: true, rate: 7.32})
      """
    Then an Error should be raised: "[NS208]: The type of `\"11\"(STRING)` cannot be assigned to `id(INT64)`"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_test_graph INSERT (@node_type_player{id:13, name:123, score: 87.0, gender: true, rate: 7.32})
      """
    Then an Error should be raised: "[NS208]: The type of `123(INT32)` cannot be assigned to `name(STRING)`"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_test_graph INSERT (@node_type_player{id:13, name:"Tim", score: "87.0", gender: true, rate: 7.32})
      """
    Then an Error should be raised: "[NS208]: The type of `\"87.0\"(STRING)` cannot be assigned to `score(FLOAT)`"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_test_graph INSERT (@node_type_player{id:13, name:"Tim", score: 87.0, gender: "true", rate: 7.32})
      """
    Then an Error should be raised: "[NS208]: The type of `\"true\"(STRING)` cannot be assigned to `gender(BOOL)`"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_test_graph INSERT (@node_type_player{id:13, name:"Tim", score: 87.0, gender: true, rate: "7.32"})
      """
    Then an Error should be raised: "[NS208]: The type of `\"7.32\"(STRING)` cannot be assigned to `rate(DOUBLE)`"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    And drop the graph "#insert_test_graph"
    And drop the graph type "mem_graph_type_nba_insert_in_valid_data"

  Scenario: InsertMultiPkData
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_fifa AS {
        NODE node_type_fifa_player (LABEL player {id INT, name STRING, score FLOAT, gender bool, rate DOUBLE, PRIMARY KEY (id,name)}),
        EDGE edge_type_fifa_follow (node_type_fifa_player)-[LABEL follow {followness INT, likeness FLOAT64}]->(node_type_fifa_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #fifa TYPED mem_graph_type_fifa
      """
    Then the execution should be successful
    When executing query:
      """
      USE #fifa
      INSERT
        (@node_type_fifa_player{id:1, name:"Tim", score: 87.0, gender: true, rate: 7.32}),
        (@node_type_fifa_player{id:2, name:"Jerry", score: 95.0, gender: false, rate: 4.01}),
        (@node_type_fifa_player{id:3, name:"Kyle", score: 100, gender: true, rate: 9.99})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 3     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #fifa
      MATCH (a:player{id:1, name:"Tim"}),(b:player{id:2, name:"Jerry"}),(c:player{id:3, name:"Kyle"})
      INSERT
        (a)-[@edge_type_fifa_follow{followness:90, likeness: 66.8}]->(b),
        (b)-[@edge_type_fifa_follow{followness:100, likeness: 93.35}]->(c)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE #fifa MATCH (v:player) RETURN v.id, v.name, v.score, v.gender, v.rate
      """
    Then the result should be, in any order:
      | v.id | v.name  | v.score | v.gender | v.rate |
      | 1    | "Tim"   | 87.0    | true     | 7.32   |
      | 2    | "Jerry" | 95.0    | false    | 4.01   |
      | 3    | "Kyle"  | 100.0   | true     | 9.99   |
    When executing query:
      """
      USE #fifa MATCH ()-[e:follow]->() RETURN e.followness, e.likeness
      """
    Then the result should be, in any order:
      | e.followness | e.likeness |
      | 90           | 66.8       |
      | 100          | 93.35      |
    When executing query:
      """
      USE #fifa
      MATCH (a:player{id:1, name:"Tim"}),(b:player{id:2, name:"Jerry"}),(c:player{id:3, name:"Kyle"})
      INSERT
        (a)-[@edge_type_fifa_follow{followness:90, likeness: 66.8}]->(b),
        (b)-[@edge_type_fifa_follow{followness:100, likeness: 93.35}]->(c)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    And drop the graph "#fifa"
    And drop the graph type "mem_graph_type_fifa"

  Scenario: InsertListData
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_with_list AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, years LIST<INT>}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {comments LIST<STRING>}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_with_list TYPED mem_graph_type_with_list
      """
    Then the execution should be successful
    # LIST[] crashs the graphd: VarlenSerializer.cpp:166 Unknown type kind: NULL
    When executing query:
      """
      USE #graph_with_list INSERT
        (@node_type_player{id:1, years: LIST[1999, 2000, 2004]}),
        (@node_type_player{id:2, years: LIST[2008, 2012, 2020]}),
        (@node_type_player{id:3, years: LIST[]})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 3     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_with_list
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2}),(c@node_type_player{id:3})
      INSERT
        (a)-[@edge_type_follow{comments: LIST["wow", "orz"]}]->(b),
        (b)-[@edge_type_follow{comments: LIST[""]}]->(c),
        (c)-[@edge_type_follow{comments: LIST[]}]->(a)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE #graph_with_list MATCH (v:player) RETURN v.id, v.years
      """
    Then the result should be, in any order:
      | v.id | v.years                |
      | 1    | LIST[1999, 2000, 2004] |
      | 2    | LIST[2008, 2012, 2020] |
      | 3    | LIST[]                 |
    When executing query:
      """
      USE #graph_with_list MATCH ()-[e:follow]->() RETURN e.comments
      """
    Then the result should be, in any order:
      | e.comments         |
      | LIST["wow", "orz"] |
      | LIST[""]           |
      | LIST[]             |
    And drop the graph "#graph_with_list"
    And drop the graph type "mem_graph_type_with_list"

  Scenario: InsertDataGQL
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_insert_gql AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score DOUBLE, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT, likeness DOUBLE}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #nba_insert TYPED mem_graph_type_insert_gql
      """
    Then the execution should be successful
    When executing query:
      """
      USE #nba_insert
      INSERT (:player{id:1,name:"player_1",score:1.0,gender:true,rate:0.5}), (:player{id:2,name:"player_2",score:2.0,gender:true,rate:1.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #nba_insert
      MATCH (a) return a
      """
    Then the result should be, in any order:
      | a                                                       |
      | ({gender:true,id:1,name:"player_1",rate:0.5,score:1.0}) |
      | ({gender:true,id:2,name:"player_2",rate:1.0,score:2.0}) |
    When executing query:
      """
      USE #nba_insert
      MATCH (u:player{id:1}),(v:player{id:2})
      INSERT (u)-[e:follow{followness:1, likeness:v.rate + 0.5}]->(v)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #nba_insert
      MATCH (a)-[r]->(b) return r
      """
    Then the result should be, in any order:
      | r                             |
      | [{followness:1,likeness:1.5}] |
    When executing query:
      """
      USE #nba_insert
      MATCH (a{id:1})
      INSERT (a)-[r:follow{followness:2, likeness:a.rate + 1.0}]->(b:player{id:3,name:"player_3",score:3.0,gender:true,rate:1.5})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #nba_insert
      MATCH (a{id:3})<-[r]-()
      RETURN a,r
      """
    Then the result should be, in any order:
      | a                                                       | r                             |
      | ({gender:true,id:3,name:"player_3",rate:1.5,score:3.0}) | [{followness:2,likeness:1.5}] |
    When executing query:
      """
      USE #nba_insert
      INSERT (:player{id:4,name:"player_4",score:4.0,gender:true,rate:2.0})-[:follow{followness:2, likeness:1.5}]->(:player{id:5,name:"player_5",score:5.0,gender:true,rate:2.5})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #nba_insert
      MATCH (a) where a.id>3 return a
      """
    Then the result should be, in any order:
      | a                                                       |
      | ({gender:true,id:5,name:"player_5",rate:2.5,score:5.0}) |
      | ({gender:true,id:4,name:"player_4",rate:2.0,score:4.0}) |
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player{id:4})-[b:follow]->(c:player) return a.id,b,c.id
      """
    Then the result should be, in any order:
      | a.id | b                             | c.id |
      | 4    | [{followness:2,likeness:1.5}] | 5    |
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player)
      INSERT (a)-[:follow{followness:2, likeness:1.5}]->(:player{id:5+a.id,name:"player_insert",score:10.0,gender:true,rate:5.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 5     |
      | "num_affected_edges" | 5     |
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player{name:"player_insert"})
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                              |
      | ({gender:true,id:6,name:"player_insert",rate:5.0,score:10.0})  |
      | ({gender:true,id:10,name:"player_insert",rate:5.0,score:10.0}) |
      | ({gender:true,id:7,name:"player_insert",rate:5.0,score:10.0})  |
      | ({gender:true,id:8,name:"player_insert",rate:5.0,score:10.0})  |
      | ({gender:true,id:9,name:"player_insert",rate:5.0,score:10.0})  |
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player{name:"player_insert"})<-[r]-(b)
      RETURN r
      """
    Then the result should be, in any order:
      | r                             |
      | [{followness:2,likeness:1.5}] |
      | [{followness:2,likeness:1.5}] |
      | [{followness:2,likeness:1.5}] |
      | [{followness:2,likeness:1.5}] |
      | [{followness:2,likeness:1.5}] |
    When executing query:
      """
      USE #nba_insert
      MATCH (a{id:1}),(b{id:2})
      INSERT (a)-[:follow{followness:2, likeness:1.5}]->(:player{id:11,name:"player_11",score:11.0,gender:true,rate:5.5}), (b)-[:follow{followness:2, likeness:1.5}]->(:player{id:12,name:"player_12",score:12.0,gender:true,rate:6.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE #nba_insert
      MATCH p=(a)-[b]->(c) where c.id>=11
      RETURN p
      """
    Then the result should be, in any order:
      | p                                                                                                                                                       |
      | PATH [({gender:true,id:2,name:"player_2",rate:1.0,score:2.0}),[{followness:2,likeness:1.5}],({gender:true,id:12,name:"player_12",rate:6.0,score:12.0})] |
      | PATH [({gender:true,id:1,name:"player_1",rate:0.5,score:1.0}),[{followness:2,likeness:1.5}],({gender:true,id:11,name:"player_11",rate:5.5,score:11.0})] |
    When executing query:
      """
      USE #nba_insert
      INSERT (:player{gender:true,id:20,name:"player_insert",rate:5.0,score:10.0}),(:player{gender:true,id:20,name:"player_insert",rate:5.0,score:10.0})
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #nba_insert
      INSERT (:player{gender:true,id:20,name:"player_insert",rate:5.0,score:10.0}),(:player{gender:true,id:20,name:"player_insert",rate:5.0,score:10.0})
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #nba_insert
      INSERT (:player{gender:true,id:10,name:"player_insert",rate:5.0,score:10.0})
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #nba_insert
      INSERT
        (:player{gender:true,id:10,name:"player_insert",rate:5.0,score:10.0}),
        (:player{gender:true,id:10,name:"player_insert",rate:5,score:10.0})
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation"
    When executing query:
      """
      USE #nba_insert
      INSERT (:player{gender:true,gender:false,id:10,rate:5,score:10.0})
      """
    Then an Error should be raised: "[42N08]: Invalid syntax, duplicate property: `gender`"
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player{id:5})
      INSERT (:player{gender:true,id:a.id,name:"player_insert",rate:5.0,score:10.0})
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player)
      INSERT (a:player)-[r:follow{followness:2,likeness:1.5}]->(b:player{gender:true,id:a.id+20,name:"player_insert",rate:5.0,score:10.0})
      """
    Then an Error should be raised: "[42N19]: Invalid syntax, cannot insert bound node `a`"
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player)-[r]->(b)
      INSERT (a)-[r]->(b)
      """
    Then an Error should be raised: "[42N22]: Invalid syntax, redefined variable: `r`"
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player)-[r]->(b)
      INSERT (a)-[e:follow{followness:2,likeness:1.5}]->(e:player{gender:true,id:a.id+20,name:"player_insert",rate:5.0,score:10.0})
      """
    Then an Error should be raised: "[42N22]: Invalid syntax, redefined variable: `e`"
    When executing query:
      """
      USE #nba_insert
      INSERT (a:player{gender:true,id:20,name:"player_insert",rate:5.0,score:10.0})-[a:follow{followness:2,likeness:1.5}]->(b:player{gender:true,id:21,name:"player_insert",rate:5.0,score:10.0})
      """
    Then an Error should be raised: "[42N22]: Invalid syntax, redefined variable: `a`"
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player)-[r]->(b)
      INSERT (a)-[e:follow{followness:2,likeness:1.5}]->(c:player{gender:true,id:a.id+20,name:"player_insert",rate:5.0,score:10.0}),
      (e:player{gender:true,id:a.id+22,name:"player_insert",rate:5.0,score:10.0})
      """
    Then an Error should be raised: "[42N17]: Invalid syntax, type of Variable `e` is not Node"
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player)
      INSERT (b:player{gender:a.gender,id:a.id+20,name:a.name,rate:a.rate,score:a.score}),(a)-[r{followness:2,likeness:1.5}]->(c:player{gender:a.gender,id:a.id+15,name:a.name,rate:a.rate,score:a.score})
      """
    Then an Error should be raised: "[NC009]: Element type matching `-[r{followness:2,likeness:1.5}]->` not found"
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player)
      INSERT (b:player{gender:a.gender,id:a.id+20,name:a.name,rate:a.rate,score:a.score}),(a)-[r:follow{followness:2,likeness:1.5}]->(c:player{gender:a.gender,id:a.id+40,name:a.name,rate:a.rate,score:a.score})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 24    |
      | "num_affected_edges" | 12    |
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player)
      WHERE a.id>20
      RETURN a.id
      """
    Then the result should be, in any order:
      | a.id |
      | 21   |
      | 22   |
      | 23   |
      | 24   |
      | 25   |
      | 26   |
      | 27   |
      | 28   |
      | 29   |
      | 30   |
      | 31   |
      | 32   |
      | 41   |
      | 42   |
      | 43   |
      | 44   |
      | 45   |
      | 46   |
      | 47   |
      | 48   |
      | 49   |
      | 50   |
      | 51   |
      | 52   |
    When executing query:
      """
      USE #nba_insert
      MATCH (a:player)-[r]->(b:player)
      WHERE b.id > 20
      RETURN a.id,r,b.id
      """
    Then the result should be, in any order:
      | a.id | r                             | b.id |
      | 1    | [{followness:2,likeness:1.5}] | 41   |
      | 2    | [{followness:2,likeness:1.5}] | 42   |
      | 3    | [{followness:2,likeness:1.5}] | 43   |
      | 4    | [{followness:2,likeness:1.5}] | 44   |
      | 5    | [{followness:2,likeness:1.5}] | 45   |
      | 6    | [{followness:2,likeness:1.5}] | 46   |
      | 7    | [{followness:2,likeness:1.5}] | 47   |
      | 8    | [{followness:2,likeness:1.5}] | 48   |
      | 9    | [{followness:2,likeness:1.5}] | 49   |
      | 10   | [{followness:2,likeness:1.5}] | 50   |
      | 11   | [{followness:2,likeness:1.5}] | 51   |
      | 12   | [{followness:2,likeness:1.5}] | 52   |
    When executing query:
      """
      USE #nba_insert
      MATCH (a{id:1})
      INSERT (a)-[r:follow{followness:2, likeness:a.rate + 1.0}]->(b:player{id:60,name:"player_60",score:60.0,gender:true,rate:30.0}), (b)-[:follow{followness:2, likeness:a.rate + 60}]->(a)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE #nba_insert
      MATCH (b:player{id:60})
      RETURN b
      """
    Then the result should be, in any order:
      | b                                                           |
      | ({gender:true,id:60,name:"player_60",rate:30.0,score:60.0}) |
    When executing query:
      """
      USE #nba_insert
      MATCH (a{id:1})-[r]->(b{id:60})
      RETURN a.id,r,b.id
      """
    Then the result should be, in any order:
      | a.id | r                             | b.id |
      | 1    | [{followness:2,likeness:1.5}] | 60   |
    When executing query:
      """
      USE #nba_insert
      MATCH (a{id:1})<-[r]-(b{id:60})
      RETURN a.id,r,b.id
      """
    Then the result should be, in any order:
      | a.id | r                              | b.id |
      | 1    | [{followness:2,likeness:60.5}] | 60   |
    And drop the graph "#nba_insert"
    And drop the graph type "mem_graph_type_insert_gql"

  Scenario: InsertMultipleLabelData
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_insert_multiple_label AS {
        NODE node_type_person (LABELS person_label_1&person_label_2 {firstName STRING, lastName STRING, gender bool, PRIMARY KEY(firstName,lastName)}),
        EDGE KNOWS (node_type_person)-[:knows_label_1&knows_label_2]->(node_type_person)
        }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #insert_multiple_label TYPED mem_graph_type_insert_multiple_label
      """
    Then the execution should be successful
    When executing query:
      """
      USE #insert_multiple_label
      INSERT (:person_label_1&person_label_2{firstName:"firstName_1", lastName:"lastName_1", gender:true})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_multiple_label
      INSERT (:person_label_1&person_label_2{firstName:"firstName_1", lastName:"lastName_2", gender:true})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_multiple_label
      INSERT (:person_label_1&person_label_2{firstName:"firstName_2", lastName:"lastName_1", gender:true})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_multiple_label
      INSERT (:person_label_1&person_label_2{firstName:"firstName_1", lastName:"lastName_1", gender:true})
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_multiple_label
      INSERT (:person_label_1{firstName:"firstName_2", lastName:"lastName_2", gender:true})
      """
    Then an Error should be raised: "[NC009]: Element type matching `(:person_label_1{firstName:\"firstName_2\",lastName:\"lastName_2\",gender:true})` not found"
    When executing query:
      """
      USE #insert_multiple_label
      MATCH (a:person_label_1)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                             |
      | ({firstName:"firstName_1",gender:true,lastName:"lastName_1"}) |
      | ({firstName:"firstName_2",gender:true,lastName:"lastName_1"}) |
      | ({firstName:"firstName_1",gender:true,lastName:"lastName_2"}) |
    When executing query:
      """
      USE #insert_multiple_label
      MATCH (a:person_label_2)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                             |
      | ({firstName:"firstName_1",gender:true,lastName:"lastName_1"}) |
      | ({firstName:"firstName_2",gender:true,lastName:"lastName_1"}) |
      | ({firstName:"firstName_1",gender:true,lastName:"lastName_2"}) |
    When executing query:
      """
      USE #insert_multiple_label
      MATCH (a:person_label_2{firstName:"firstName_1",lastName:"lastName_1"})
      INSERT (a)-[:knows_label_1&knows_label_2]->(:person_label_1&person_label_2{firstName:"firstName_3",lastName:a.lastName, gender:false})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #insert_multiple_label
      MATCH (a:person_label_2)-[r:knows_label_1]->(b:person_label_1)
      RETURN a,r,b
      """
    Then the result should be, in any order:
      | a                                                             | r    | b                                                              |
      | ({firstName:"firstName_1",gender:true,lastName:"lastName_1"}) | [{}] | ({firstName:"firstName_3",gender:false,lastName:"lastName_1"}) |
    When executing query:
      """
      USE #insert_multiple_label
      MATCH (a{firstName:"firstName_1",lastName:"lastName_1"}),(b{firstName:"firstName_1",lastName:"lastName_2"})
      INSERT (a)-[r:knows_label_1]->(b)
      """
    Then an Error should be raised: "[NC009]: Element type matching `-[r:knows_label_1]->` not found"
    When executing query:
      """
      USE #insert_multiple_label
      MATCH (a{firstName:"firstName_1",lastName:"lastName_1"}),(b{firstName:"firstName_1",lastName:"lastName_2"})
      INSERT (a)-[r:knows_label_1&knows_label_2]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #insert_multiple_label
      MATCH (a)-[r]->(b)
      RETURN a,r,b
      """
    Then the result should be, in any order:
      | a                                                             | r    | b                                                              |
      | ({firstName:"firstName_1",gender:true,lastName:"lastName_1"}) | [{}] | ({firstName:"firstName_3",gender:false,lastName:"lastName_1"}) |
      | ({firstName:"firstName_1",gender:true,lastName:"lastName_1"}) | [{}] | ({firstName:"firstName_1",gender:true,lastName:"lastName_2"})  |
    And drop the graph "#insert_multiple_label"
    And drop the graph type "mem_graph_type_insert_multiple_label"

  Scenario: InsertMultiEdges
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_no_multi_edge AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT, likeness FLOAT64}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #no_multi_edge TYPED mem_graph_type_no_multi_edge
      """
    Then the execution should be successful
    When executing query:
      """
      USE #no_multi_edge INSERT
        (@node_type_player{id:1, name:"Tim", score: 87.0, gender: true, rate: 7.32}),
        (@node_type_player{id:2, name:"Jerry", score: 95.0, gender: false, rate: 4.01}),
        (@node_type_player{id:3, name:"Kyle", score: 100, gender: true, rate: 9.99}),
        (@node_type_player{id:4, name:"", score: 0, gender: true, rate: 1.23})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #no_multi_edge
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2}),(c@node_type_player{id:3})
      INSERT
        (a)-[@edge_type_follow{followness:90, likeness: 66.8}]->(b),
        (b)-[@edge_type_follow{followness:100, likeness: 93.35}]->(c)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE #no_multi_edge
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2})
      INSERT
        (a)-[@edge_type_follow{followness:90, likeness: 66.8}]->(b)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #no_multi_edge
      MATCH (a@node_type_player{id:2}),(b@node_type_player{id:3})
      INSERT
        (a)-[@edge_type_follow{followness:100, likeness: 93.35}]->(b)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #no_multi_edge
      MATCH (a@node_type_player{id:3}),(b@node_type_player{id:4})
      INSERT
        (a)-[@edge_type_follow{followness:90, likeness: 66.8}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    And drop the graph "#no_multi_edge"
    And drop the graph type "mem_graph_type_no_multi_edge"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_multi_edge_auto AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT, likeness FLOAT64, MULTIEDGE KEY()}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #multi_edge_auto TYPED mem_graph_type_multi_edge_auto
      """
    Then the execution should be successful
    When executing query:
      """
      USE #multi_edge_auto INSERT
        (@node_type_player{id:1, name:"Tim", score: 87.0, gender: true, rate: 7.32}),
        (@node_type_player{id:2, name:"Jerry", score: 95.0, gender: false, rate: 4.01}),
        (@node_type_player{id:3, name:"Kyle", score: 100, gender: true, rate: 9.99}),
        (@node_type_player{id:4, name:"", score: 0, gender: true, rate: 1.23})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #multi_edge_auto
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2}),(c@node_type_player{id:3})
      INSERT
        (a)-[@edge_type_follow{followness:90, likeness: 66.8}]->(b),
        (b)-[@edge_type_follow{followness:100, likeness: 93.35}]->(c)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE #multi_edge_auto
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2}),(c@node_type_player{id:3})
      INSERT
        (a)-[@edge_type_follow{followness:90, likeness: 66.8}]->(b),
        (a)-[@edge_type_follow{followness:90, likeness: 66.8}]->(b),
        (a)-[@edge_type_follow{followness:90, likeness: 66.8}]->(b),
        (b)-[@edge_type_follow{followness:100, likeness: 93.35}]->(c),
        (b)-[@edge_type_follow{followness:100, likeness: 93.35}]->(c)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 5     |
    And drop the graph "#multi_edge_auto"
    And drop the graph type "mem_graph_type_multi_edge_auto"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_multi_edge_inside_prop AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT MULTIEDGE KEY, age INT, likeness FLOAT64}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #multi_edge_inside_prop TYPED mem_graph_type_multi_edge_inside_prop
      """
    Then the execution should be successful
    When executing query:
      """
      USE #multi_edge_inside_prop INSERT
        (@node_type_player{id:1, name:"Tim", score: 87.0, gender: true, rate: 7.32}),
        (@node_type_player{id:2, name:"Jerry", score: 95.0, gender: false, rate: 4.01}),
        (@node_type_player{id:3, name:"Kyle", score: 100, gender: true, rate: 9.99}),
        (@node_type_player{id:4, name:"", score: 0, gender: true, rate: 1.23})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #multi_edge_inside_prop
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2}),(c@node_type_player{id:3})
      INSERT
        (a)-[@edge_type_follow{followness:90, age:18, likeness: 66.8}]->(b),
        (b)-[@edge_type_follow{followness:100, age:20, likeness: 93.35}]->(c)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE #multi_edge_inside_prop
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2})
      INSERT
        (a)-[@edge_type_follow{followness:90, age:20, likeness: 82.04}]->(b)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #multi_edge_inside_prop
      MATCH (a@node_type_player{id:2}),(b@node_type_player{id:3})
      INSERT
        (a)-[@edge_type_follow{followness:100, age:10, likeness: 53.08}]->(b)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #multi_edge_inside_prop
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2})
      INSERT
        (a)-[@edge_type_follow{followness:88, age:18, likeness: 66.8}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #multi_edge_inside_prop
      MATCH (a@node_type_player{id:2}),(b@node_type_player{id:3})
      INSERT
        (a)-[@edge_type_follow{followness:104, age:20, likeness: 93.35}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #multi_edge_inside_prop MATCH (v)-[e]->() return v.id, e.followness, e.age, e.likeness
      """
    Then the result should be, in any order:
      | v.id | e.followness | e.age | e.likeness |
      | 2    | 100          | 20    | 93.35      |
      | 2    | 104          | 20    | 93.35      |
      | 1    | 88           | 18    | 66.8       |
      | 1    | 90           | 18    | 66.8       |
    When executing query:
      """
      USE #multi_edge_inside_prop MATCH (v)-[e]->() where e.followness = 104 return v.id, e.followness, e.age, e.likeness
      """
    Then the result should be, in any order:
      | v.id | e.followness | e.age | e.likeness |
      | 2    | 104          | 20    | 93.35      |
    When executing query:
      """
      USE #multi_edge_inside_prop
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2})
      INSERT
        (a)-[@edge_type_follow{followness:null, age:20, likeness: 82.04}]->(b)
      """
    Then an Error should be raised: "[ND008]: Property `followness` of type `edge_type_follow` is not nullable"
    When executing query:
      """
      USE #multi_edge_inside_prop
      MATCH (u:player{id:1}),(v:player{id:2})
      INSERT (u)-[e:follow{followness:null, age:20, likeness:v.rate + 0.5}]->(v)
      """
    Then an Error should be raised: "[ND008]: Property `followness` of type `edge_type_follow` is not nullable"
    And drop the graph "#multi_edge_inside_prop"
    And drop the graph type "mem_graph_type_multi_edge_inside_prop"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_multi_edge_props AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score FLOAT, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT, likeness FLOAT64, MULTIEDGE KEY(followness, age)}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #multi_edge_props TYPED mem_graph_type_multi_edge_props
      """
    Then the execution should be successful
    When executing query:
      """
      USE #multi_edge_props INSERT
        (@node_type_player{id:1, name:"Tim", score: 87.0, gender: true, rate: 7.32}),
        (@node_type_player{id:2, name:"Jerry", score: 95.0, gender: false, rate: 4.01}),
        (@node_type_player{id:3, name:"Kyle", score: 100, gender: true, rate: 9.99}),
        (@node_type_player{id:4, name:"", score: 0, gender: true, rate: 1.23})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #multi_edge_props
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2}),(c@node_type_player{id:3})
      INSERT
        (a)-[@edge_type_follow{followness:90, age:18, likeness: 66.8}]->(b),
        (b)-[@edge_type_follow{followness:100, age:20, likeness: 93.35}]->(c)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE #multi_edge_props
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2})
      INSERT
        (a)-[@edge_type_follow{followness:90, age:18, likeness: 82.04}]->(b)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #multi_edge_props
      MATCH (a@node_type_player{id:2}),(b@node_type_player{id:3})
      INSERT
        (a)-[@edge_type_follow{followness:100, age:20, likeness: 53.08}]->(b)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #multi_edge_props
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2})
      INSERT
        (a)-[@edge_type_follow{followness:88, age:18, likeness: 66.8}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #multi_edge_props
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2})
      INSERT
        (a)-[@edge_type_follow{followness:90, age:19, likeness: 66.8}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #multi_edge_props MATCH (v)-[e]->() return v.id, e.followness, e.age, e.likeness
      """
    Then the result should be, in any order:
      | v.id | e.followness | e.age | e.likeness |
      | 2    | 100          | 20    | 93.35      |
      | 1    | 88           | 18    | 66.8       |
      | 1    | 90           | 19    | 66.8       |
      | 1    | 90           | 18    | 66.8       |
    When executing query:
      """
      USE #multi_edge_props
      MATCH (a@node_type_player{id:1}),(b@node_type_player{id:2})
      INSERT
        (a)-[@edge_type_follow{followness:null, age:20, likeness: 82.04}]->(b)
      """
    Then an Error should be raised: "[ND008]: Property `followness` of type `edge_type_follow` is not nullable"
    When executing query:
      """
      USE #multi_edge_props
      MATCH (u:player{id:1}),(v:player{id:2})
      INSERT (u)-[e:follow{followness:90, age:null, likeness:v.rate + 0.5d}]->(v)
      """
    Then an Error should be raised: "[ND008]: Property `age` of type `edge_type_follow` is not nullable"
    And drop the graph "#multi_edge_props"
    And drop the graph type "mem_graph_type_multi_edge_props"

  Scenario: InsertOrIgnore
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_insert_ignore AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score DOUBLE, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT, likeness DOUBLE}]->(node_type_player),
        EDGE edge_type_follow_1 (node_type_player)-[LABEL follow_1 {followness INT,likeness DOUBLE, MULTIEDGE KEY()}]->(node_type_player),
        EDGE edge_type_follow_2 (node_type_player)-[LABEL follow_2 {followness INT,likeness DOUBLE, MULTIEDGE KEY(followness)}]->(node_type_player),
        EDGE edge_type_follow_3 (node_type_player)-[LABEL follow_3 {followness INT,likeness DOUBLE, status INT, MULTIEDGE KEY(followness, likeness)}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_insert_ignore TYPED mem_graph_type_insert_ignore
      """
    Then the execution should be successful
    When executing query:
      """
      USE #graph_insert_ignore
      INSERT (:player{id:1,name:"player_1",score:1.0,gender:true,rate:0.5})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_insert_ignore
      INSERT OR IGNORE (:player{id:1,name:"player_1",score:2.0,gender:true,rate:1.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a:player{id:1})
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                       |
      | ({gender:true,id:1,name:"player_1",rate:0.5,score:1.0}) |
    When executing query:
      """
      USE #graph_insert_ignore
      INSERT OR IGNORE (:player{id:2,name:"player_2",score:2.0,gender:true,rate:1.0}),
      (:player{id:2,name:"player_ignored ",score:2.0,gender:true,rate:1.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                       |
      | ({gender:true,id:1,name:"player_1",rate:0.5,score:1.0}) |
      | ({gender:true,id:2,name:"player_2",rate:1.0,score:2.0}) |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a{id:1}),(b{id:2})
      INSERT (a)-[:follow{followness:1, likeness:2.0}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a{id:1}),(b{id:2})
      INSERT OR IGNORE (a)-[:follow{followness:3, likeness:1.5}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a)-[e]-(b)
      RETURN a.id,e,b.id
      """
    Then the result should be, in any order:
      | a.id | e                             | b.id |
      | 2    | [{followness:1,likeness:2.0}] | 1    |
      | 1    | [{followness:1,likeness:2.0}] | 2    |
    When executing query:
      """
      USE #graph_insert_ignore
      FOR i in  range(1,5)
      INSERT OR IGNORE (:player{id:i,name:"player_ignored",score:i*1.0,gender:true,rate:i*0.5})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 3     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                             |
      | ({gender:true,id:1,name:"player_1",rate:0.5,score:1.0})       |
      | ({gender:true,id:3,name:"player_ignored",rate:1.5,score:3.0}) |
      | ({gender:true,id:2,name:"player_2",rate:1.0,score:2.0})       |
      | ({gender:true,id:4,name:"player_ignored",rate:2.0,score:4.0}) |
      | ({gender:true,id:5,name:"player_ignored",rate:2.5,score:5.0}) |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a{id:3}), (b{id:4})
      INSERT OR IGNORE (a)-[:follow{followness:0, likeness:0.0}]->(b),(a)-[:follow{followness:1, likeness:1.5}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a{id:3})-[e]->(b)
      RETURN a.id,e,b.id
      """
    Then the result should be, in any order:
      | a.id | e                             | b.id |
      | 3    | [{followness:0,likeness:0.0}] | 4    |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a{id:1}),(b{id:2})
      INSERT OR IGNORE
      (a)-[:follow_1{followness:1, likeness:1}]->(b),
      (a)-[:follow_1{followness:2, likeness:2}]->(b),
      (a)-[:follow_1{followness:3, likeness:3}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a{id:1})-[e:follow_1]->(b{id:2})
      RETURN e.followness,e.likeness
      """
    Then the result should be, in any order:
      | e.followness | e.likeness |
      | 1            | 1.0        |
      | 2            | 2.0        |
      | 3            | 3.0        |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a{id:1}),(b{id:2})
      INSERT OR IGNORE
      (a)-[:follow_2{followness:1, likeness:1}]->(b),
      (a)-[:follow_2{followness:1, likeness:2}]->(b),
      (a)-[:follow_2{followness:1, likeness:3}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a{id:1})-[e:follow_2]->(b{id:2})
      RETURN e.followness,e.likeness
      """
    Then the result should be, in any order:
      | e.followness | e.likeness |
      | 1            | 1.0        |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a{id:1}),(b{id:2})
      INSERT OR IGNORE
      (a)-[:follow_3{followness:1, likeness:1, status:1}]->(b),
      (a)-[:follow_3{followness:1, likeness:1, status:2}]->(b),
      (a)-[:follow_3{followness:1, likeness:1, status:3}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_ignore
      MATCH (a{id:1})-[e:follow_3]->(b{id:2})
      RETURN e.followness,e.likeness, e.status
      """
    Then the result should be, in any order:
      | e.followness | e.likeness | e.status |
      | 1            | 1.0        | 1        |
    And drop the graph "#graph_insert_ignore"
    And drop the graph type "mem_graph_type_insert_ignore"

  Scenario: InsertOrReplace
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_insert_replace AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score DOUBLE, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT, likeness DOUBLE}]->(node_type_player),
        EDGE edge_type_follow_1 (node_type_player)-[LABEL follow_1 {followness INT,likeness DOUBLE, MULTIEDGE KEY()}]->(node_type_player),
        EDGE edge_type_follow_2 (node_type_player)-[LABEL follow_2 {followness INT,likeness DOUBLE, MULTIEDGE KEY(followness)}]->(node_type_player),
        EDGE edge_type_follow_3 (node_type_player)-[LABEL follow_3 {followness INT,likeness DOUBLE, status INT, MULTIEDGE KEY(followness, likeness)}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_insert_replace TYPED mem_graph_type_insert_replace
      """
    Then the execution should be successful
    When executing query:
      """
      USE #graph_insert_replace
      INSERT (:player{id:1,name:"player_1",score:1.0,gender:true,rate:0.5})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_insert_replace
      INSERT OR REPLACE (:player{id:1,name:"player_1",score:2.0,gender:true,rate:1.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a:player{id:1})
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                       |
      | ({gender:true,id:1,name:"player_1",rate:1.0,score:2.0}) |
    When executing query:
      """
      USE #graph_insert_replace
      INSERT OR REPLACE (:player{id:2,name:"player_2",score:2.0,gender:true,rate:1.0}),
      (:player{id:2,name:"player_replace",score:2.0,gender:true,rate:1.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a:player)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                             |
      | ({gender:true,id:1,name:"player_1",rate:1.0,score:2.0})       |
      | ({gender:true,id:2,name:"player_replace",rate:1.0,score:2.0}) |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a{id:1}),(b{id:2})
      INSERT (a)-[:follow{followness:1, likeness:2.0}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a{id:1}),(b{id:2})
      INSERT OR REPLACE (a)-[:follow{followness:3, likeness:1.5}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a)-[e]-(b)
      RETURN a.id,e,b.id
      """
    Then the result should be, in any order:
      | a.id | e                             | b.id |
      | 2    | [{followness:3,likeness:1.5}] | 1    |
      | 1    | [{followness:3,likeness:1.5}] | 2    |
    When executing query:
      """
      USE #graph_insert_replace
      FOR i in  range(1,5)
      INSERT OR REPLACE (:player{id:i,name:"player_replace",score:i*1.0,gender:true,rate:i*0.5})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 5     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                             |
      | ({gender:true,id:2,name:"player_replace",rate:1.0,score:2.0}) |
      | ({gender:true,id:1,name:"player_replace",rate:0.5,score:1.0}) |
      | ({gender:true,id:3,name:"player_replace",rate:1.5,score:3.0}) |
      | ({gender:true,id:5,name:"player_replace",rate:2.5,score:5.0}) |
      | ({gender:true,id:4,name:"player_replace",rate:2.0,score:4.0}) |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a{id:3}), (b{id:4})
      INSERT OR REPLACE (a)-[:follow{followness:0, likeness:0.0}]->(b),(a)-[:follow{followness:1, likeness:1.5}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a{id:3})-[e]->(b)
      RETURN a.id,e,b.id
      """
    Then the result should be, in any order:
      | a.id | e                             | b.id |
      | 3    | [{followness:1,likeness:1.5}] | 4    |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a{id:1}),(b{id:2})
      INSERT OR REPLACE
      (a)-[:follow_1{followness:1, likeness:1}]->(b),
      (a)-[:follow_1{followness:2, likeness:2}]->(b),
      (a)-[:follow_1{followness:3, likeness:3}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a{id:1})-[e:follow_1]->(b{id:2})
      RETURN e.followness,e.likeness
      """
    Then the result should be, in any order:
      | e.followness | e.likeness |
      | 1            | 1.0        |
      | 2            | 2.0        |
      | 3            | 3.0        |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a{id:1}),(b{id:2})
      INSERT OR REPLACE
      (a)-[:follow_2{followness:1, likeness:1}]->(b),
      (a)-[:follow_2{followness:1, likeness:2}]->(b),
      (a)-[:follow_2{followness:1, likeness:3}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a{id:1})-[e:follow_2]->(b{id:2})
      RETURN e.followness,e.likeness
      """
    Then the result should be, in any order:
      | e.followness | e.likeness |
      | 1            | 3.0        |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a{id:1}),(b{id:2})
      INSERT OR REPLACE
      (a)-[:follow_3{followness:1, likeness:1, status:1}]->(b),
      (a)-[:follow_3{followness:1, likeness:1, status:2}]->(b),
      (a)-[:follow_3{followness:1, likeness:1, status:3}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_replace
      MATCH (a{id:1})-[e:follow_3]->(b{id:2})
      RETURN e.followness,e.likeness, e.status
      """
    Then the result should be, in any order:
      | e.followness | e.likeness | e.status |
      | 1            | 1.0        | 3        |
    And drop the graph "#graph_insert_replace"
    And drop the graph type "mem_graph_type_insert_replace"

  Scenario: GQLInsertEdgesWithRank
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_rank AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY}),
        EDGE edge_type_follow_1 (node_type_player)-[LABEL follow_1 {followness INT}]->(node_type_player),
        EDGE edge_type_follow_2 (node_type_player)-[LABEL follow_2 {followness INT, MULTIEDGE KEY()}]->(node_type_player),
        EDGE edge_type_follow_3 (node_type_player)-[LABEL follow_3 {followness INT, age INT, MULTIEDGE KEY(followness, age)}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_rank TYPED mem_graph_type_rank
      """
    Then the execution should be successful
    When executing query:
      """
      USE #graph_rank
      FOR i in  range(1,5)
      INSERT (a:player{id:i})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 5     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a),(b)
      WHERE a.id + 1 = b.id
      INSERT (a)-[:follow_1{followness:a.id}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 4     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1}),(b{id:2})
      INSERT (a)-[:follow_1{followness:a.id}]->(b)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1}),(b{id:3})
      INSERT (a)-[:follow_1{followness:a.id}]->(b),(a)-[:follow_1{followness:a.id}]->(b)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1}),(b{id:3})
      INSERT (a)-[:follow_1{followness:a.id}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1}),(b{id:2})
      INSERT (a)-[:follow_2{followness:a.id}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1}),(b{id:2})
      INSERT (a)-[:follow_2{followness:a.id}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1})-[r:follow_2]->(b{id:2})
      RETURN a.id,r,b.id
      """
    Then the result should be, in any order:
      | a.id | r                | b.id |
      | 1    | [{followness:1}] | 2    |
      | 1    | [{followness:1}] | 2    |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:2}),(b{id:3})
      INSERT (a)-[:follow_2{followness:1}]->(b),
      (a)-[:follow_2{followness:1}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:2})-[r:follow_2]->(b{id:3})
      RETURN a.id,r,b.id
      """
    Then the result should be, in any order:
      | a.id | r                | b.id |
      | 2    | [{followness:1}] | 3    |
      | 2    | [{followness:1}] | 3    |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1}),(b{id:2})
      INSERT (a)-[:follow_3{followness:a.id,age:b.id}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1}),(b{id:2})
      INSERT (a)-[:follow_3{followness:a.id,age:b.id}]->(b)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1}),(b{id:2})
      INSERT (a)-[:follow_3{followness:a.id,age:b.id+1}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1}),(b{id:2})
      INSERT (a)-[:follow_3{followness:a.id,age:b.id+2}]->(b),
      (a)-[:follow_3{followness:a.id,age:b.id+2}]->(b)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1})
      INSERT (b:player{id:6})-[e:follow_3{followness:a.id,age:2}]->(a)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1})
      INSERT (b:player{id:7})-[e:follow_3{followness:a.id,age:2}]->(a),
      (b)-[e1:follow_3{followness:a.id,age:2}]->(a)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1})
      INSERT OR REPLACE (b:player{id:7})-[e:follow_3{followness:a.id,age:2}]->(a),
      (b)-[e1:follow_3{followness:a.id,age:2}]->(a)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:1})
      INSERT (b:player{id:8})-[e:follow_2{followness:a.id}]->(a),
      (b)-[e1:follow_2{followness:a.id}]->(a)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:8})-[e:follow_2]->(b)
      RETURN a.id, e, b.id
      """
    Then the result should be, in any order:
      | a.id | e                | b.id |
      | 8    | [{followness:1}] | 1    |
      | 8    | [{followness:1}] | 1    |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:8})
      INSERT (b:player{id:9})-[e:follow_1{followness:a.id}]->(a),
      (b)-[e1:follow_1{followness:a.id}]->(a)
      """
    Then an Error should be raised: "[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:8})
      INSERT (b:player{id:9})-[e:follow_1{followness:a.id}]->(a)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_rank
      MATCH (a{id:9})-[e:follow_1]->(b)
      RETURN a.id, e, b.id
      """
    Then the result should be, in any order:
      | a.id | e                | b.id |
      | 9    | [{followness:8}] | 8    |
    When executing query:
      """
      USE #graph_rank
      MATCH (a),(b)
      WHERE  a.id + 3 = b.id
      INSERT (a)-[:follow_1{followness:a.id}]->(b),
      (a)-[:follow_2{followness:a.id}]->(b),
      (a)-[:follow_3{followness:a.id, age:b.id}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 18    |
    And drop the graph "#graph_rank"
    And drop the graph type "mem_mem_graph_type_rank"

  Scenario: GQLInsertTemporalType
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_test_temporal_type AS {
        NODE person (LABEL player {id INT PRIMARY KEY, p1 LOCAL TIME, p2 ZONED TIME, p3 LOCAL DATETIME, p4 ZONED DATETIME, p5 DATE})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_temporal TYPED mem_test_temporal_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE #test_temporal
      INSERT (a:player{id:0, p1:local_time("23:23:23", "%H:%M:%S"),
      p2:zoned_time("23:23:23 +0300", "%H:%M:%S %z"),
      p3:local_datetime("2022-02-02T23:23:23", "%Y-%m-%dT%H:%M:%S"),
      p4:zoned_datetime("2022-02-02T23:23:23 -0300", "%Y-%m-%dT%H:%M:%S %z"),
      p5:date("2022-02-02", "%Y-%m-%d")})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #test_temporal
      MATCH (a)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                                                                                                                                                          |
      | ({p2: ZONED TIME "20:23:23.000000", p4: ZONED DATETIME "2022-02-03T02:23:23.000000", p5: DATE "2022-02-02", id: 0, p1: TIME "23:23:23.000000", p3: DATETIME "2022-02-02T23:23:23.000000"}) |
    And drop the graph "#test_temporal"
    And drop the graph type "mem_test_temporal_type"
    And close the current session

  Scenario: LimitEdgeDirection
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_limit_edge_direction_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY}),
        EDGE directed_follow (node_type_player)-[LABEL follow {followness INT, likeness DOUBLE  NOT NULL}]->(node_type_player),
        EDGE undirected_follow (node_type_player)~[LABEL follow {followness INT}]~(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #limit_edge_direction TYPED mem_limit_edge_direction_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE #limit_edge_direction
      INSERT (:player{id:1}),(:player{id:2})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #limit_edge_direction
      MATCH (x:player{id:1}),(y:player{id:2})
      INSERT (x)-[:follow{followness:1, likeness:1.0}]->(y)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #limit_edge_direction
      MATCH (x:player{id:1}),(y:player{id:2})
      INSERT (x)~[:follow{followness:1, likeness:1.0}]~(y)
      """
    Then an Error should be raised: "[ND004]: Property `likeness` of type `undirected_follow` not found"
    When executing query:
      """
      USE #limit_edge_direction
      MATCH (x:player{id:1}),(y:player{id:2})
      INSERT (x)~[:follow{followness:1}]~(y)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #limit_edge_direction
      MATCH (x:player{id:1}),(y:player{id:2})
      INSERT (x)-[:follow{followness:1}]->(y)
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `likeness` of type `directed_follow` not found"
    When executing query:
      """
      USE #limit_edge_direction
      MATCH (x:player{id:1}),(y:player{id:2})
      INSERT (x)<-[:follow{followness:1}]-(y)
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `likeness` of type `directed_follow` not found"
    And drop the graph "#limit_edge_direction"
    And drop the graph type "mem_limit_edge_direction_type"

  @skip
  # GG24
  Scenario: InferElementType
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_infer_element_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, prop_1 INT8, prop_2 INT16}),
        NODE node_type_team (LABEL team {id INT PRIMARY KEY}),
        NODE node_type_infer_failed_1 (LABEL label_1 {id INT PRIMARY KEY, prop_1 INT8}),
        NODE node_type_infer_failed_2 (LABEL label_1 {id INT PRIMARY KEY, prop_1 INT16}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT32, likeness FLOAT32}]->(node_type_player),
        EDGE edge_type_infer_failed_1 (node_type_player)-[LABEL elabel_1 {followness INT8, likeness FLOAT32}]->(node_type_player),
        EDGE edge_type_infer_failed_2 (node_type_player)-[LABEL elabel_1 {followness INT16, likeness FLOAT32}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS #infer_element TYPED mem_infer_element_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE #infer_element
      INSERT (:player{id:1, prop_1:1, prop_2:1}),
      (:player{id:2, prop_1:2, prop_2:2})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #infer_element
      INSERT (:player{id:2,prop_1:10000,prop_2:10000})
      """
    Then an Error should be raised: "[22003]: Numeric value out of range: `10000`, type: `INT8`"
    When executing query:
      """
      USE #infer_element
      INSERT (:player{id:2,prop_1:"10x",prop_2:10000})
      """
    Then an Error should be raised: "[NS208]: The type of `\"10x\"(STRING)` cannot be assigned to `prop_1(INT8)`"
    When executing query:
      """
      USE #infer_element
      INSERT (:player{id:2,prop_1:List[1,2,3],prop_2:10000})
      """
    Then an Error should be raised: "[NS208]: The type of `LIST[1, 2, 3](LIST<INT64>)` cannot be assigned to `prop_1(INT8)`"
    When executing query:
      """
      USE #infer_element
      INSERT (:label_1{id:1, prop_1:1})
      """
    Then an Error should be raised: "[NR212]: Type inference for `(:label_1{id:1,prop_1:1})` failed, multiple types inferred: `node_type_infer_failed_2`, `node_type_infer_failed_1`"
    When executing query:
      """
      USE #infer_element
      INSERT (x TYPED node_type_infer_failed_1{id:1, prop_1:1})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #infer_element
      INSERT (x@node_type_infer_failed{id:1, prop_1:1})
      """
    Then an Error should be raised: "[NC003]: Node type not found: `node_type_infer_failed`"
    When executing query:
      """
      USE #infer_element
      MATCH (a:player{id:1}),(b:player{id:2})
      INSERT (a)-[:follow{followness:1,likeness:1.0}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #infer_element
      MATCH (a:player{id:1}),(b:team{id:2})
      INSERT (a)-[:follow{followness:1,likeness:1.0}]->(b)
      """
    Then an Error should be raised: "[NR213]: Endpoint node types of edge type `edge_type_follow` mismatch"
    When executing query:
      """
      USE #infer_element
      MATCH (a:player{id:1}),(b:player{id:2})
      INSERT (a)-[:elabel_1{followness:1,likeness:1.0}]->(b)
      """
    Then an Error should be raised:"Type inference for `-[:elabel_1{followness:1,likeness:1}]->` failed, multiple types inferred: `edge_type_infer_failed_2`, `edge_type_infer_failed_1`"
    When executing query:
      """
      USE #infer_element
      MATCH (a:player{id:1}),(b:player{id:2})
      INSERT (a)-[e TYPED edge_type_infer_failed_1{followness:1,likeness:1.0}]->(b)
      """
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #infer_element
      MATCH (a:player{id:1}),(b:player{id:2})
      INSERT (a)-[@edge_type_infer_failed{followness:1,likeness:1.0}]->(b)
      """
    Then an Error should be raised:"[NC004]: Edge type not found: `edge_type_infer_failed`"
    And drop the graph "#infer_element"
    And drop the graph type "mem_infer_element_type"

  Scenario: InsertNullValue
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_insert_null_type AS {
        NODE Person (LABELS Person {pid INT PRIMARY KEY, score INT NOT NULL}),
        EDGE Follow (Person)-[LABELS Follow {followness DOUBLE NOT NULL}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #insert_null TYPED mem_insert_null_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE #insert_null
      INSERT (:Person{pid:1,score:null})
      """
    Then an Error should be raised:"[ND008]: Property `score` of type `Person` is not nullable"
    When executing query:
      """
      USE #insert_null
      INSERT (:Person{pid:null,score:1})
      """
    Then an Error should be raised:"[ND008]: Property `pid` of type `Person` is not nullable"
    When executing query:
      """
      USE #insert_null
      INSERT (:Person{pid:1,score:1})-[:Follow{followness:null}]->(:Person{pid:2,score:2})
      """
    Then an Error should be raised:"[ND008]: Property `followness` of type `Follow` is not nullable"
    When executing query:
      """
      USE #insert_null
      INSERT (:Person{pid:1,score:1})-[:Follow{followness:1}]->(:Person{pid:2,score:2})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    And drop the graph "#insert_null"
    And drop the graph type "mem_insert_null_type"

  Scenario: InsertEdgeAfterNode
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_test_insert_edge_type AS {
        NODE Post(LABELS Post&Message {id INT64 PRIMARY KEY}),
        NODE Comment (LABELS Comment&Message {id INT64 PRIMARY KEY}),
        EDGE COMMENT_REPLY_OF_POST (Comment)-[:REPLY_OF]->(Post)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_insert_edge TYPED mem_test_insert_edge_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE #test_insert_edge
      INSERT
      (p_1:Post&Message{id:1001}),
      (c_1:Comment&Message{id:2001}),
      (c_1)-[:REPLY_OF]->(p_1)
      """
    Then the execution should be successful
    And drop the graph "#test_insert_edge"
    And drop the graph type "mem_test_insert_edge_type"

  Scenario: InsertDefaultValueConflict
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_insert_default_value_type AS {
        NODE node_type_person (LABELS Person {pid INT PRIMARY KEY, score INT NOT NULL}),
        NODE node_type_person_default (LABELS Person {pid INT PRIMARY KEY, score INT NOT NULL, default_prop1 INT DEFAULT 10}),
        EDGE edge_type_follow (node_type_person)-[LABEL follow {followness INT32}]->(node_type_person),
        EDGE edge_type_follow_default  (node_type_person)-[LABEL follow {followness INT32,default_prop1 INT DEFAULT 10}]->(node_type_person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #insert_default_value TYPED mem_insert_default_value_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE #insert_default_value
      INSERT
      (:Person{pid:1,score:1})
      """
    Then an Error should be raised:"[NR209]: Type inference for `(:Person{pid:1,score:1})` failed, multiple types inferred: `node_type_person_default`, `node_type_person`"
    When executing query:
      """
      USE #insert_default_value
      INSERT
      (TYPED node_type_person{pid:1,score:1}),(TYPED node_type_person{pid:2,score:2})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_default_value
      INSERT
      (TYPED node_type_person{pid:3,score:3})-[:follow{followness:1}]->(TYPED node_type_person{pid:4,score:2})
      """
    Then an Error should be raised:"[NR209]: Type inference for `-[:follow{followness:1}]->` failed, multiple types inferred: `edge_type_follow_default`, `edge_type_follow`"
    When executing query:
      """
      USE #insert_default_value
      INSERT
      (TYPED node_type_person{pid:3,score:3})-[TYPED edge_type_follow_default{followness:1}]->(TYPED node_type_person{pid:4,score:2})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #insert_default_value
      MATCH (n)
      RETURN n
      """
    Then the result should be, in any order:
      | n                 |
      | ({pid:2,score:2}) |
      | ({pid:1,score:1}) |
      | ({pid:3,score:3}) |
      | ({pid:4,score:2}) |
    When executing query:
      """
      USE #insert_default_value
      MATCH (n)-[e]->(m)
      RETURN e
      """
    Then the result should be, in any order:
      | e                                 |
      | [{default_prop1:10,followness:1}] |
    And drop the graph "#insert_default_value"
    And drop the graph type "mem_insert_default_value_type"

  Scenario: InsertZonedTime
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_pk_zoned_time_type AS {
      NODE person_zoned_time (LABELS person_zoned_time&Person { No int,  name string, p_zoned_time zoned time primary key }),
      EDGE TEST_EDGE (person_zoned_time)-[:TEST_EDGE{prop1 string,prop2 int, MULTIEDGE KEY(prop1,prop2)}]->(person_zoned_time)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #pk_zoned_time TYPED mem_pk_zoned_time_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE #pk_zoned_time insert
      (a@person_zoned_time{No:1, name:"user_01", p_zoned_time:zoned_time("05:13:27.0890Z", "%H:%M:%S%z")}),
      (b@person_zoned_time{No:2, name:"user_02", p_zoned_time:zoned_time("05:23:37.0890 -0200") }),
      (a)-[@TEST_EDGE{prop1: "1", prop2: 1}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #pk_zoned_time
      MATCH (a)-[e]->(b)
      RETURN a.p_zoned_time, e.prop1, b.p_zoned_time
      """
    Then the result should be, in any order:
      | a.p_zoned_time               | e.prop1 | b.p_zoned_time               |
      | ZONED TIME "05:13:27.089000" | "1"     | ZONED TIME "07:23:37.089000" |
    And drop the graph "#pk_zoned_time"
    And drop the graph type "mem_pk_zoned_time_type"
    And close the current session

  Scenario: InsertUndirectedEdge
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_insert_undirected_edge_type AS {
        NODE Person (LABELS Person {id INT64 PRIMARY KEY}),
        EDGE Follow (Person)~[:Follow{prop INT}]~(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #insert_undirected_edge TYPED mem_insert_undirected_edge_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE #insert_undirected_edge
      INSERT (x:Person{id:1}),(y:Person{id:2}), (x)~[:Follow{prop:1}]~(y), (y)~[:Follow{prop:2}]~(x)
      """
    Then an Error should be raised:"[NR206]: Insert edge failed, multi-edge key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_undirected_edge
      INSERT (x:Person{id:1})~[:Follow{prop:1}]~(y:Person{id:2})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #insert_undirected_edge
      MATCH (y:Person{id:2}),(x:Person{id:1})
      INSERT (y)~[:Follow{prop:2}]~(x)
      """
    Then an Error should be raised:"[NR206]: Insert edge failed, multi-edge key constraint violation"
    When executing query:
      """
      USE #insert_undirected_edge
      MATCH (x:Person{id:1}),(y:Person{id:2})
      INSERT (x)~[:Follow{prop:2}]~(y)
      """
    Then an Error should be raised:"[NR206]: Insert edge failed, multi-edge key constraint violation"
    When executing query:
      """
      USE #insert_undirected_edge
      MATCH (y:Person{id:2}),(x:Person{id:1})
      INSERT OR IGNORE (y)~[:Follow{prop:2}]~(x)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #insert_undirected_edge
      MATCH (y:Person{id:2}),(x:Person{id:1})
      INSERT OR REPLACE (y)~[:Follow{prop:2}]~(x)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #insert_undirected_edge
      MATCH (x)~[e]~(y)
      RETURN x.id, e.prop, y.id
      """
    Then the result should be, in any order:
      | x.id | e.prop | y.id |
      | 2    | 2      | 1    |
      | 1    | 2      | 2    |
    And drop the graph "#insert_undirected_edge"
    And drop the graph type "mem_insert_undirected_edge_type"

  Scenario: NotInCurrentGraph
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #ldbc_insert TYPED ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc
      MATCH (a@Person{id:1})
      RETURN a
      NEXT
      USE #ldbc_insert
      INSERT (a)-[r:FOLLOWS{}]->(b@Person{id:2})
      """
    Then an Error should be raised:
      """
      [NR212]: `(289107795020611588@Person)` of graph `ldbc` is not in current working graph
      """
    And drop the graph "#ldbc_insert"

  Scenario: InsertNullList
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_insert_list_type AS {
        NODE node_type_1 (LABEL label1 {id INT PRIMARY KEY, prop_list_int LIST<INT>}),
        NODE node_type_2 (LABEL label2 {id INT PRIMARY KEY, prop_list_bool LIST<BOOL>})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #insert_list TYPED mem_insert_list_type
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id,prop_list_int, prop_list_bool} =
      (1, LIST[null], LIST[null]),
      (2, LIST[1,2,null],LIST[true,false,unknown,null]),
      (3, LIST[1,2,3], LIST[true,false])
      USE #insert_list
      FOR r IN t
      INSERT
      (a:label1{id:r.id,prop_list_int:r.prop_list_int}),
      (b:label2{id:r.id,prop_list_bool:r.prop_list_bool})
      """
    Then the execution should be successful
    When executing query:
      """
      USE #insert_list
      MATCH (a:label1)
      RETURN a.id, a.prop_list_int
      """
    Then the result should be, in any order:
      | a.id | a.prop_list_int |
      | 3    | LIST[1,2,3]     |
      | 2    | LIST[1,2,null]  |
      | 1    | LIST[null]      |
    When executing query:
      """
      USE #insert_list
      MATCH (a:label2)
      RETURN a.id, a.prop_list_bool
      """
    Then the result should be, in any order:
      | a.id | a.prop_list_bool           |
      | 1    | LIST[null]                 |
      | 2    | LIST[true,false,null,null] |
      | 3    | LIST[true,false]           |
    And drop the graph "#insert_list"
    And drop the graph type "mem_insert_list_type"

  Scenario: CallQueryInsert
    When executing query:
      """
      CALL show_all_indexes()
      FILTER graph_name='ldbc'
      INSERT (@Person{id:1})
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"

  Scenario: AffectedElements
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_insert_count_type AS {
        NODE node_type_1 (LABEL label1 {id INT PRIMARY KEY}),
        EDGE edge_type_1 (node_type_1)-[LABEL elabel]->(node_type_1)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #insert_count TYPED mem_insert_count_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE #insert_count
      FOR i IN range(1,10000)
      INSERT OR REPLACE (@node_type_1{id:1})-[@edge_type_1]->(@node_type_1{id:2})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    And drop the graph "#insert_count"
    And drop the graph type "mem_insert_count_type"

  Scenario: InsertOrUpdate:
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_insert_update AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, score DOUBLE, gender bool, rate DOUBLE}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT, likeness DOUBLE}]->(node_type_player),
        EDGE edge_type_follow_1 (node_type_player)-[LABEL follow_1 {followness INT,likeness DOUBLE, MULTIEDGE KEY()}]->(node_type_player),
        EDGE edge_type_follow_2 (node_type_player)-[LABEL follow_2 {followness INT,likeness DOUBLE, status INT, MULTIEDGE KEY(followness)}]->(node_type_player),
        EDGE edge_type_follow_3 (node_type_player)-[LABEL follow_3 {followness INT,likeness DOUBLE, status INT, status_1 INT, MULTIEDGE KEY(followness, likeness)}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_insert_update TYPED mem_graph_type_insert_update
      """
    Then the execution should be successful
    When executing query:
      """
      USE #graph_insert_update
      INSERT OR UPDATE (:player{id:1,name:"player_1",gender:true}), (:player{id:1,name:"player_2",score:2.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                        |
      | ({gender:true,id:1,name:"player_2",rate:null,score:2.0}) |
    When executing query:
      """
      USE #graph_insert_update
      INSERT OR UPDATE (:player{id:1,name:"player_3",gender:false})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                         |
      | ({gender:false,id:1,name:"player_3",rate:null,score:2.0}) |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1})
      INSERT OR UPDATE
      (a)-[:follow{followness:1}]->(b:player{id:2}),
      (a)-[:follow{likeness:1.0}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1})-[e:follow]->(b:player{id:2})
      RETURN e
      """
    Then the result should be, in any order:
      | e                             |
      | [{followness:1,likeness:1.0}] |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1}),(b:player{id:2})
      INSERT OR UPDATE
      (a)-[:follow{followness:2}]->(b),
      (a)-[:follow_1{followness:2}]->(b),
      (a)-[:follow_1{followness:2}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1})-[e:follow]->(b:player{id:2})
      RETURN e
      """
    Then the result should be, in any order:
      | e                             |
      | [{followness:2,likeness:1.0}] |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1})-[e:follow_1]->(b:player{id:2})
      RETURN e
      """
    Then the result should be, in any order:
      | e                              |
      | [{followness:2,likeness:null}] |
      | [{followness:2,likeness:null}] |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1}),(b:player{id:2})
      INSERT OR UPDATE
      (a)-[:follow_2{followness:3,status:1}]->(b),
      (a)-[:follow_2{followness:3,likeness:23}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1})-[e:follow_2]->(b:player{id:2})
      RETURN e
      """
    Then the result should be, in any order:
      | e                                       |
      | [{followness:3,likeness:23.0,status:1}] |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1}),(b:player{id:2})
      INSERT OR UPDATE
      (a)-[:follow_2{followness:10,status:2}]->(b),
      (a)-[:follow_2{followness:3,status:23}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1})-[e:follow_2]->(b:player{id:2})
      RETURN e
      """
    Then the result should be, in any order:
      | e                                        |
      | [{followness:3,likeness:23.0,status:23}] |
      | [{followness:10,likeness:null,status:2}] |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1}),(b:player{id:2})
      INSERT OR UPDATE
      (a)-[:follow_3{followness:1,likeness:2,status:2}]->(b),
      (a)-[:follow_3{followness:1,likeness:2,status_1:3}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1})-[e:follow_3]->(b:player{id:2})
      RETURN e
      """
    Then the result should be, in any order:
      | e                                                 |
      | [{followness:1,likeness:2.0,status:2,status_1:3}] |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1}),(b:player{id:2})
      INSERT OR UPDATE
      (a)-[:follow_3{followness:1,likeness:2,status:4}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #graph_insert_update
      MATCH (a:player{id:1})-[e:follow_3]->(b:player{id:2})
      RETURN e
      """
    Then the result should be, in any order:
      | e                                                 |
      | [{followness:1,likeness:2.0,status:4,status_1:3}] |
    And drop the graph "#graph_insert_update"
    And drop the graph type "mem_graph_type_insert_update"

  Scenario: MultiPkConflict
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_conflict AS {
        NODE player (LABEL player {id INT, name STRING, score FLOAT, gender bool, rate DOUBLE, PRIMARY KEY (id,name)})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_conflict TYPED mem_graph_type_conflict
      """
    Then the execution should be successful
    When executing query:
      """
      USE #graph_conflict
      INSERT OR IGNORE
      (:player{id:1,name:"1",score:1.0}),
      (:player{id:1,name:"1",gender:true,rate:1.0}),
      (:player{id:1,name:"2",gender:true,rate:1.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_conflict
      MATCH (a:player)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                 |
      | ({gender:null,id:1,name:"1",rate:null,score:1.0}) |
      | ({gender:true,id:1,name:"2",rate:1.0,score:null}) |
    When executing query:
      """
      USE #graph_conflict
      INSERT OR IGNORE
      (:player{id:1,name:"2",gender:true,rate:1.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_conflict
      INSERT OR REPLACE
      (:player{id:1,name:"1",score:1.0}),
      (:player{id:1,name:"1",gender:true,rate:3.0}),
      (:player{id:1,name:"2",gender:false,rate:2.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_conflict
      MATCH (a:player)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                  |
      | ({gender:false,id:1,name:"2",rate:2.0,score:null}) |
      | ({gender:true,id:1,name:"1",rate:3.0,score:null})  |
    When executing query:
      """
      USE #graph_conflict
      INSERT OR REPLACE
      (:player{id:1,name:"2",gender:true,rate:1.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_conflict
      MATCH (a:player{name:"2"})
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                 |
      | ({gender:true,id:1,name:"2",rate:1.0,score:null}) |
    When executing query:
      """
      USE #graph_conflict
      INSERT OR UPDATE
      (:player{id:1,name:"1",score:1.0}),
      (:player{id:1,name:"1",gender:true,rate:3.0}),
      (:player{id:1,name:"2",gender:false,rate:2.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_conflict
      MATCH (a:player)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                  |
      | ({gender:false,id:1,name:"2",rate:2.0,score:null}) |
      | ({gender:true,id:1,name:"1",rate:3.0,score:1.0})   |
    When executing query:
      """
      USE #graph_conflict
      INSERT OR UPDATE
      (:player{id:1,name:"2",rate:10.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_conflict
      MATCH (a:player{name:"2"})
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                   |
      | ({gender:false,id:1,name:"2",rate:10.0,score:null}) |
    And drop the graph "#graph_conflict"
    And drop the graph type "mem_graph_type_conflict"

  @skip
  # Question: Does altering a catalog graph type affect the type of an already created temporary graph?
  Scenario: AlterInsert
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_alter_insert AS {
        NODE player (LABEL player {id INT PRIMARY KEY, name STRING})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_alter_insert TYPED mem_graph_type_alter_insert
      """
    Then the execution should be successful
    When executing query:
      """
      USE #graph_alter_insert
      INSERT (a:player{id:1,name:"player_1"})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      ALTER GRAPH TYPE mem_graph_type_alter_insert {
        ALTER NODE TYPE player
        ADD PROPERTIES {age INT, gender BOOL}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #graph_alter_insert
      INSERT (a:player{id:2,name:"player_2",age:10,gender:false})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_alter_insert
      MATCH (a:player)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                             |
      | ({age:10,gender:false,id:2,name:"player_2"})  |
      | ({age:null,gender:null,id:1,name:"player_1"}) |
    When executing query:
      """
      ALTER GRAPH TYPE graph_type_alter_insert {
        ALTER NODE TYPE player
        DROP PROPERTIES {name,age}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #graph_alter_insert
      INSERT (a:player{id:3,gender:false})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #graph_alter_insert
      MATCH (a:player)
      RETURN a
      """
    Then the result should be, in any order:
      | a                     |
      | ({gender:false,id:2}) |
      | ({gender:false,id:3}) |
      | ({gender:null,id:1})  |
    And drop the graph "#graph_alter_insert"
    And drop the graph type "mem_graph_type_alter_insert"

  @skip
  Scenario: InsertReturnIdMapping
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mem_graph_type_id_mapping_test AS {
        NODE Person (LABEL Person {id INT, PRIMARY KEY (id)}),
        NODE Item (LABEL Item {category_id INT, item_id INT, PRIMARY KEY(category_id, item_id)}),
        EDGE Purchase (Person)-[LABEL Purchase{}]->(Item)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_id_mapping TYPED mem_graph_type_id_mapping_test
      """
    When executing query:
      """
      /*+ SET_VAR(insert_return_id_mapping = true) */
      TABLE t {id} = (1),(2),(3),(4)
      USE #graph_id_mapping
      FOR r IN t
      INSERT (a@Person{id:r.id})
      """
    Then the result should be, in any order:
      | a        |
      | ({id:1}) |
      | ({id:2}) |
      | ({id:3}) |
      | ({id:4}) |
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      /*+ SET_VAR(insert_return_id_mapping = true) */
      TABLE t {c_id, i_id} = (1,1),(2,1),(3,1),(4,1)
      USE #graph_id_mapping
      FOR r IN t
      INSERT (a@Item{category_id:r.c_id, item_id:r.i_id})
      """
    Then the result should be, in any order:
      | a                           |
      | ({category_id:1,item_id:1}) |
      | ({category_id:2,item_id:1}) |
      | ({category_id:3,item_id:1}) |
      | ({category_id:4,item_id:1}) |
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      TABLE t {src, dst} =
      (288263370090479617, 288592712477704193),
      (288449535447924737, 288743083577704449),
      (288321876134985729, 288670949601968129),
      (288472492048121857, 288610334728519681)
      USE #graph_id_mapping
      FOR r IN t
      LET x = CONSTRUCT_NODE@Person(r.src),  y = CONSTRUCT_NODE@Item(r.dst)
      INSERT (x)-[@Purchase{}]->(y)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 4     |
    When executing query:
      """
      /*+ SET_VAR(insert_return_id_mapping = true) */
      TABLE t {person_id, c_id, i_id} =
       (5, 5, 1),
       (6, 6, 1)
      USE #graph_id_mapping
      FOR r IN t
      INSERT OR REPLACE (a@Person{id:r.person_id}), (b@Item{category_id:r.c_id,item_id:r.i_id})
      """
    Then the result should be, in any order:
      | a        | b                           |
      | ({id:5}) | ({category_id:5,item_id:1}) |
      | ({id:6}) | ({category_id:6,item_id:1}) |
    When executing query:
      """
      TABLE t {src, dst} =
      (288415253018968065, 288595654530301953),
      (288232351836667905, 288541619546750977)
      USE #graph_id_mapping
      FOR r IN t
      LET x = CONSTRUCT_NODE@Person(r.src),  y = CONSTRUCT_NODE@Item(r.dst)
      INSERT (x)-[@Purchase{}]->(y)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE #graph_id_mapping
      MATCH (a)-[e@Purchase]->(b)
      RETURN a.id, b.category_id, b.item_id
      """
    Then the result should be, in any order:
      | a.id | b.category_id | b.item_id |
      | 2    | 2             | 1         |
      | 3    | 3             | 1         |
      | 4    | 4             | 1         |
      | 6    | 6             | 1         |
      | 5    | 5             | 1         |
      | 1    | 1             | 1         |
    When executing query:
      """
      RETURN CONSTRUCT_NODE@Person(1)
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    When executing query:
      """
      USE #graph_id_mapping
      RETURN CONSTRUCT_NODE@Person(1)
      """
    Then an Error should be raised: "[NR025]: Invalid element id for type NODE<(Person)>{}: `1`"
    And drop the graph "#graph_id_mapping"
    And drop the graph type "mem_graph_type_id_mapping_test"
