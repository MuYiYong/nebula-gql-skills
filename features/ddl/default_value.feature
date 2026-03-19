# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: default value

  Scenario: default value literal
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS default_value_test_type AS {
        NODE node_type_player (LABEL player {
          id INT PRIMARY KEY,
          name           STRING          DEFAULT "unknown",
          birth_day      DATE            DEFAULT DATE "2000-01-01",
          birth_time     LOCAL TIME      DEFAULT TIME "23:23:23.000000",
          birth_datetime LOCAL DATETIME  DEFAULT DATETIME "2000-01-01T23:23:23.000000",
          health         DOUBLE          DEFAULT 1.0,
          score          DOUBLE          NOT NULL,
          emails         LIST<STRING>    DEFAULT LIST ["aaa@bbb.com", "ccc@ddd.org"]
        }),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {
          followness INT    DEFAULT 100,
          likeness   DOUBLE NOT NULL
         }]->(node_type_player)
      }
      """
    Then the execution should be successful
    And graph type "default_value_test_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS default_value_test TYPED default_value_test_type
      """
    Then the execution should be successful
    And graph "default_value_test" should be ready to use
    When executing query:
      """
      USE default_value_test
      INSERT
      (TYPED node_type_player {id:1,name:"player_1", health:0.5}),
      (TYPED node_type_player{id:2,name:"player_2",birth_day:DATE "1999-12-12"})
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `score` of type `node_type_player` not found"
    When executing query:
      """
      USE default_value_test
      INSERT
      (TYPED node_type_player {id:1,name:"player_1", health:0.5, score:0.1}),
      (TYPED node_type_player{id:2,name:"player_2",birth_day:DATE "1999-12-12", score:0.2, emails: LIST["nebula@vesoft.com"]})
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match (v) return v.birth_day, v.health, v.score, v.emails
      """
    Then the result should be, in any order:
      | v.birth_day       | v.health | v.score | v.emails                            |
      | DATE '1999-12-12' | 1.0      | 0.2     | LIST ["nebula@vesoft.com"]          |
      | DATE '2000-01-01' | 0.5      | 0.1     | LIST ["aaa@bbb.com", "ccc@ddd.org"] |
    When executing query:
      """
      ALTER GRAPH TYPE default_value_test_type {
        ALTER NODE TYPE node_type_player ADD PROPERTIES {
          vec1 VECTOR<3,float> not null default VECTOR<3,float>([1,2,3]),
          vec2 VECTOR<2,float>  default null
        }
      }
      """
    Then an Error should be raised: "[NT018]: Non-null default value for vector property is not allowed, element type: `node_type_player`, property name: `vec1`"
    When executing query:
      """
      ALTER GRAPH TYPE default_value_test_type {
        ALTER NODE TYPE node_type_player ADD PROPERTIES {
          vec1 VECTOR<3,float> not null,
          vec2 VECTOR<2,float>  default null
        }
      }
      """
    Then an Error should be raised: "[42N31]: Invalid syntax, add not nullable property node_type_player.vec1 without default value is not allowed"
    When executing query:
      """
      ALTER GRAPH TYPE default_value_test_type {
        ALTER NODE TYPE node_type_player ADD PROPERTIES {
          vec1 VECTOR<3,float>,
          vec2 VECTOR<2,float>  default null
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match (v) return v.birth_day, v.health, v.score, v.emails, v.vec1, v.vec2
      """
    Then the result should be, in any order:
      | v.birth_day       | v.health | v.score | v.emails                            | v.vec1 | v.vec2 |
      | DATE '1999-12-12' | 1.0      | 0.2     | LIST ["nebula@vesoft.com"]          | null   | null   |
      | DATE '2000-01-01' | 0.5      | 0.1     | LIST ["aaa@bbb.com", "ccc@ddd.org"] | null   | null   |
    When executing query:
      """
      ALTER GRAPH TYPE default_value_test_type {
        ALTER NODE TYPE node_type_player MODIFY PROPERTIES {
          vec1 VECTOR<4,float> default null,
          vec2 VECTOR<1,float>  default null
        }
      }
      """
    Then an Error should be raised: "[NR113]: Property `vec1` of element type `node_type_player` cannot be modified from `VECTOR<3, FLOAT>` to `VECTOR<4, FLOAT>`"
    When executing query:
      """
      ALTER GRAPH TYPE default_value_test_type {
        ALTER NODE TYPE node_type_player MODIFY PROPERTIES {
          vec1 VECTOR<3,float> default null,
          vec2 VECTOR<2,float>
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match (v) return v.birth_day, v.health, v.score, v.emails, v.vec1, v.vec2
      """
    Then the result should be, in any order:
      | v.birth_day       | v.health | v.score | v.emails                            | v.vec1 | v.vec2 |
      | DATE '1999-12-12' | 1.0      | 0.2     | LIST ["nebula@vesoft.com"]          | null   | null   |
      | DATE '2000-01-01' | 0.5      | 0.1     | LIST ["aaa@bbb.com", "ccc@ddd.org"] | null   | null   |
    When executing query:
      """
      USE default_value_test
      INSERT (TYPED node_type_player {id:3,name:"player_1", health:0.5, score:0.1})
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match (v) return v.birth_day, v.health, v.score, v.emails, v.vec1, v.vec2
      """
    Then the result should be, in any order:
      | v.birth_day       | v.health | v.score | v.emails                            | v.vec1 | v.vec2 |
      | DATE '1999-12-12' | 1.0      | 0.2     | LIST ["nebula@vesoft.com"]          | null   | null   |
      | DATE '2000-01-01' | 0.5      | 0.1     | LIST ["aaa@bbb.com", "ccc@ddd.org"] | null   | null   |
      | DATE '2000-01-01' | 0.5      | 0.1     | LIST ["aaa@bbb.com", "ccc@ddd.org"] | null   | null   |
    When executing query:
      """
      ALTER GRAPH TYPE default_value_test_type {
        ALTER NODE TYPE node_type_player ADD PROPERTIES {
          vec3 VECTOR<4,float>
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match (v) return v.birth_day, v.health, v.score, v.emails, v.vec1, v.vec2,v.vec3
      """
    Then the result should be, in any order:
      | v.birth_day       | v.health | v.score | v.emails                            | v.vec1 | v.vec2 | v.vec3 |
      | DATE '1999-12-12' | 1.0      | 0.2     | LIST ["nebula@vesoft.com"]          | null   | null   | null   |
      | DATE '2000-01-01' | 0.5      | 0.1     | LIST ["aaa@bbb.com", "ccc@ddd.org"] | null   | null   | null   |
      | DATE '2000-01-01' | 0.5      | 0.1     | LIST ["aaa@bbb.com", "ccc@ddd.org"] | null   | null   | null   |
    When executing query:
      """
      USE default_value_test
      INSERT (TYPED node_type_player {id:4, score:1})
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match (v) return v.birth_day, v.health, v.score, v.emails, v.vec1, v.vec2,v.vec3
      """
    Then the result should be, in any order:
      | v.birth_day       | v.health | v.score | v.emails                            | v.vec1 | v.vec2 | v.vec3 |
      | DATE '1999-12-12' | 1.0      | 0.2     | LIST ["nebula@vesoft.com"]          | null   | null   | null   |
      | DATE '2000-01-01' | 0.5      | 0.1     | LIST ["aaa@bbb.com", "ccc@ddd.org"] | null   | null   | null   |
      | DATE '2000-01-01' | 0.5      | 0.1     | LIST ["aaa@bbb.com", "ccc@ddd.org"] | null   | null   | null   |
      | DATE '2000-01-01' | 1.0      | 1.0     | LIST ["aaa@bbb.com", "ccc@ddd.org"] | null   | null   | null   |
    When executing query:
      """
      USE default_value_test
      MATCH (x:player {id:1}),(y:player{id:2})
      INSERT (x)-[e TYPED edge_type_follow {followness:1}]->(y)
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `likeness` of type `edge_type_follow` not found"
    When executing query:
      """
      USE default_value_test
      MATCH (x:player {id:1}),(y:player{id:2})
      INSERT (x)-[e TYPED edge_type_follow {followness:1, likeness:0.22}]->(y)
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match ()-[e]->() return e.followness, e.likeness
      """
    Then the result should be, in any order:
      | e.followness | e.likeness |
      | 1            | 0.22       |
    When executing query:
      """
      ALTER GRAPH TYPE default_value_test_type {
        ALTER EDGE TYPE edge_type_follow ADD PROPERTIES {
          vec1 VECTOR<3,float> ,
          vec2 VECTOR<2,float>  default null
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match ()-[e]->() return e.followness, e.likeness, e.vec1, e.vec2
      """
    Then the result should be, in any order:
      | e.followness | e.likeness | e.vec1 | e.vec2 |
      | 1            | 0.22       | null   | null   |
    When executing query:
      """
      USE default_value_test
      MATCH (x:player {id:1}),(y:player{id:2})
      INSERT (y)-[e TYPED edge_type_follow {likeness:0.99}]->(x)
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match ()-[e]->() return e.followness, e.likeness, e.vec1, e.vec2
      """
    Then the result should be, in any order:
      | e.followness | e.likeness | e.vec1 | e.vec2 |
      | 100          | 0.99       | null   | null   |
      | 1            | 0.22       | null   | null   |
    When executing query:
      """
      ALTER GRAPH TYPE default_value_test_type {
        ALTER EDGE TYPE edge_type_follow MODIFY PROPERTIES {
          vec1 VECTOR<3,float>  default null,
          vec2 VECTOR<2,float>
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match ()-[e]->() return e.followness, e.likeness, e.vec1, e.vec2
      """
    Then the result should be, in any order:
      | e.followness | e.likeness | e.vec1 | e.vec2 |
      | 100          | 0.99       | null   | null   |
      | 1            | 0.22       | null   | null   |
    When executing query:
      """
      USE default_value_test
      MATCH (x:player {id:1}),(y:player{id:3})
      INSERT (y)-[e TYPED edge_type_follow {likeness:0.11}]->(x)
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match ()-[e]->() return e.followness, e.likeness, e.vec1, e.vec2
      """
    Then the result should be, in any order:
      | e.followness | e.likeness | e.vec1 | e.vec2 |
      | 100          | 0.99       | null   | null   |
      | 1            | 0.22       | null   | null   |
      | 100          | 0.11       | null   | null   |
    When executing query:
      """
      ALTER GRAPH TYPE default_value_test_type {
        ALTER EDGE TYPE edge_type_follow ADD PROPERTIES {
          vec3 VECTOR<4,float>  default null,
          vec4 VECTOR<4,float>
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match ()-[e]->() return e.followness, e.likeness, e.vec1, e.vec2, e.vec3, e.vec4
      """
    Then the result should be, in any order:
      | e.followness | e.likeness | e.vec1 | e.vec2 | e.vec3 | e.vec4 |
      | 100          | 0.99       | null   | null   | null   | null   |
      | 100          | 0.11       | null   | null   | null   | null   |
      | 1            | 0.22       | null   | null   | null   | null   |
    When executing query:
      """
      USE default_value_test
      MATCH (x:player {id:2}),(y:player{id:3})
      INSERT (y)-[e TYPED edge_type_follow {likeness:0.12, followness:98, vec4:VECTOR<4,float>([1,2,3,4])}]->(x)
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match ()-[e]->() return e.followness, e.likeness, e.vec1, e.vec2, e.vec3, e.vec4
      """
    Then the result should be, in any order:
      | e.followness | e.likeness | e.vec1 | e.vec2 | e.vec3 | e.vec4                   |
      | 100          | 0.99       | null   | null   | null   | null                     |
      | 1            | 0.22       | null   | null   | null   | null                     |
      | 100          | 0.11       | null   | null   | null   | null                     |
      | 98           | 0.12       | null   | null   | null   | VECTOR [1.0,2.0,3.0,4.0] |
    When executing query:
      """
      ALTER GRAPH TYPE default_value_test_type {
        ALTER NODE TYPE node_type_player ADD PROPERTIES {
          address SET<STRING> not null default SET{"123 Main St", "456 Oak Ave"},
          contact MAP<INT, STRING> not null default MAP{1:"123456", 2:"888888"}
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match (v) return v.birth_day, v.health, v.score, v.address, v.contact
      """
    Then the result should be, in any order:
      | v.birth_day       | v.health | v.score | v.address                         | v.contact                   |
      | DATE '1999-12-12' | 1.0      | 0.2     | SET{"123 Main St", "456 Oak Ave"} | MAP{1:"123456", 2:"888888"} |
      | DATE '2000-01-01' | 0.5      | 0.1     | SET{"123 Main St", "456 Oak Ave"} | MAP{1:"123456", 2:"888888"} |
      | DATE '2000-01-01' | 0.5      | 0.1     | SET{"123 Main St", "456 Oak Ave"} | MAP{1:"123456", 2:"888888"} |
      | DATE '2000-01-01' | 1.0      | 1.0     | SET{"123 Main St", "456 Oak Ave"} | MAP{1:"123456", 2:"888888"} |
    When executing query:
      """
      USE default_value_test
      INSERT (TYPED node_type_player {id:5,name:"player_1",score:2,address:set{"Bath Road 8th"},contact:map{3:null}})
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_test match (v) return v.score, v.address, v.contact
      """
    Then the result should be, in any order:
      | v.score | v.address                         | v.contact                   |
      | 1.0     | SET{"123 Main St", "456 Oak Ave"} | MAP{1:"123456", 2:"888888"} |
      | 0.2     | SET{"123 Main St", "456 Oak Ave"} | MAP{1:"123456", 2:"888888"} |
      | 0.1     | SET{"123 Main St", "456 Oak Ave"} | MAP{1:"123456", 2:"888888"} |
      | 0.1     | SET{"123 Main St", "456 Oak Ave"} | MAP{1:"123456", 2:"888888"} |
      | 2.0     | SET{"Bath Road 8th"}              | MAP{3:null}                 |
    And drop the graph "default_value_test"
    And drop the graph type "default_value_test_type"

  Scenario: default nullable
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS default_null_type AS {
        NODE node_type_player (LABEL player {
          id INT PRIMARY KEY,
          name           STRING          DEFAULT "unknown",
          birth_day      DATE            DEFAULT DATE "2000-01-01",
          birth_time     LOCAL TIME,
          birth_datetime LOCAL DATETIME
        }),
        EDGE edge_type_follow  (node_type_player)-[LABEL follow {
          followness INT    DEFAULT 100,
          likeness   DOUBLE
         }]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS default_null TYPED default_null_type
      """
    Then the execution should be successful
    And graph "default_null" should be ready to use
    When executing query:
      """
      USE default_null
      FOR i in LIST[1,2,3]
      INSERT (TYPED node_type_player {id:i})
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_null
      MATCH (a:player)
      RETURN a.id, a.name, a.birth_day, a.birth_time, a.birth_datetime
      """
    Then the result should be, in any order:
      | a.id | a.name    | a.birth_day       | a.birth_time | a.birth_datetime |
      | 2    | "unknown" | DATE '2000-01-01' | null         | null             |
      | 3    | "unknown" | DATE '2000-01-01' | null         | null             |
      | 1    | "unknown" | DATE '2000-01-01' | null         | null             |
    When executing query:
      """
      USE default_null
      MATCH (a:player),(b:player)
      WHERE a.id < b.id
      INSERT (a)-[TYPED edge_type_follow{likeness:1}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_null
      MATCH (a)-[e:follow]->(b)
      RETURN a.id,e.followness,e.likeness,b.id
      """
    Then the result should be, in any order:
      | a.id | e.followness | e.likeness | b.id |
      | 1    | 100          | 1.0        | 2    |
      | 2    | 100          | 1.0        | 3    |
      | 1    | 100          | 1.0        | 3    |
    And drop the graph "default_null"
    And drop the graph type "default_null_type"

  Scenario: default value implicit cast
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS default_value_cast_type AS {
        NODE node_type_player (LABEL player {
          id INT PRIMARY KEY,
          propInt32 INT8  DEFAULT "1",
          propFloat FLOAT DEFAULT 1.0
        })
      }
      """
    Then an Error should be raised: "[NS208]: The type of `\"1\"(STRING)` cannot be assigned to `node_type_player.propInt32(INT8)`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS default_value_cast_type AS {
        NODE node_type_player (LABEL player {
          id INT PRIMARY KEY,
          propInt32 INT8  NOT NULL  DEFAULT NULL,
          propFloat FLOAT           DEFAULT 1.0
        })
      }
      """
    Then an Error should be raised: "[ND008]: Property `propInt32` of type `node_type_player` is not nullable"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS default_value_cast_type AS {
        NODE node_type_player (LABEL player {
          id INT PRIMARY KEY,
          propInt32 INT8  DEFAULT 1,
          propFloat FLOAT DEFAULT 1.0
        })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS default_value_cast TYPED default_value_cast_type
      """
    Then the execution should be successful
    And graph "default_value_cast" should be ready to use
    When executing query:
      """
      USE default_value_cast
      INSERT (a:player{id:1})
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_cast
      MATCH (a)
      RETURN a.propInt32, a.propFloat
      """
    Then the result should be, in any order:
      | a.propInt32 | a.propFloat |
      | 1           | 1.0         |
    And drop the graph "default_value_cast"
    And drop the graph type "default_value_cast_type"

  Scenario: deafault value const expression
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS default_value_expression_type AS {
        NODE node_type_player (LABEL player {
          id INT PRIMARY KEY,
          propInt32   INT32   DEFAULT 1 + 2,
          propFloat   DOUBLE   DEFAULT 1 + 2.0,
          propString  STRING  DEFAULT "xxx"||"yyy"
        })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS default_value_expression TYPED default_value_expression_type
      """
    Then the execution should be successful
    And graph "default_value_expression" should be ready to use
    When executing query:
      """
      USE default_value_expression
      INSERT (a:player{id:1})
      """
    Then the execution should be successful
    When executing query:
      """
      USE default_value_expression
      MATCH (a{id:1})
      RETURN a.propInt32,a.propFloat,a.propString
      """
    Then the result should be, in any order:
      | a.propInt32 | a.propFloat | a.propString |
      | 3           | 3.0         | "xxxyyy"     |
    And drop the graph "default_value_expression"
    And drop the graph type "default_value_expression_type"

  Scenario: alter default value
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS alter_default_value_gt AS {
        NODE TYPE `Entity` ({
          id INT,
          test_list LIST<STRING>  NOT NULL DEFAULT LIST[],
          primary key (id)
        }),
        EDGE TYPE Connect (Entity)-[{
          degree INT NOT NULL DEFAULT 1
        }]->(Entity)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH alter_default_value_g alter_default_value_gt
      """
    Then the execution should be successful
    When executing query:
      """
      USE alter_default_value_g
      INSERT (a@Entity{id:1})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE alter_default_value_g
      MATCH (a@Entity{id:1})
      INSERT (a)-[@Connect]->(a)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      ALTER GRAPH TYPE alter_default_value_gt {
        ALTER NODE TYPE Entity MODIFY PROPERTIES {test_list LIST<STRING> NOT NULL}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE alter_default_value_g
      INSERT (a@Entity{id:1})
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `test_list` of type `Entity` not found"
    When executing query:
      """
      USE alter_default_value_g
      INSERT (a@Entity{id:2, test_list:["TEST"]})
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE alter_default_value_gt {
        ALTER EDGE TYPE Connect MODIFY PROPERTIES {degree INT NOT NULL}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE alter_default_value_g
      MATCH (a@Entity{id:1})
      MATCH (b@Entity{id:2})
      INSERT (a)-[@Connect]->(b)
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `degree` of type `Connect` not found"
    When executing query:
      """
      USE alter_default_value_g
      MATCH (a@Entity{id:1})
      MATCH (b@Entity{id:2})
      INSERT (a)-[@Connect{degree:2}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE alter_default_value_g
      MATCH (a)
      RETURN a
      """
    Then the result should be, in any order:
      | a                               |
      | ({id:2,test_list:LIST["TEST"]}) |
      | ({id:1,test_list:LIST[]})       |
    When executing query:
      """
      USE alter_default_value_g
      MATCH (a)-[e@Connect]->(b)
      RETURN a.id, e, b.id
      """
    Then the result should be, in any order:
      | a.id | e            | b.id |
      | 1    | [{degree:1}] | 1    |
      | 1    | [{degree:2}] | 2    |
    When executing query:
      """
      SHOW CREATE GRAPH TYPE alter_default_value_gt
      """
    Then the result should be, in any order:
      | graph_type_name          | create_graph_type_statement                                                                                                                                                                                                                        |
      | "alter_default_value_gt" | "CREATE GRAPH TYPE IF NOT EXISTS `alter_default_value_gt` AS {\n  NODE TYPE `Entity` ({`id` INT64 NOT NULL, `test_list` LIST<STRING> NOT NULL, PRIMARY KEY (`id`)}),\n  EDGE TYPE `Connect` (`Entity`)-[{`degree` INT64 NOT NULL}]->(`Entity`)\n}" |
    When executing query:
      """
      ALTER GRAPH TYPE alter_default_value_gt {
        ADD NODE TYPE Entity_1 ({
          id INT,
          test_int INT  NOT NULL,
          primary key (id)
        })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE alter_default_value_g
      INSERT (a@Entity_1{id:1})
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `test_int` of type `Entity_1` not found"
    When executing query:
      """
      ALTER GRAPH TYPE alter_default_value_gt {
        ALTER NODE TYPE Entity_1 MODIFY PROPERTIES {test_int INT NOT NULL DEFAULT 1}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE alter_default_value_g
      INSERT (a@Entity_1{id:1})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE alter_default_value_g
      MATCH (a@Entity_1)
      RETURN a
      """
    Then the result should be, in any order:
      | a                   |
      | ({id:1,test_int:1}) |
    When executing query:
      """
      ALTER GRAPH TYPE alter_default_value_gt {
        ADD EDGE TYPE Connect_1 (Entity)-[{
          degree INT NOT NULL
        }]->(Entity)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE alter_default_value_g
      MATCH (a@Entity{id:1})
      MATCH (b@Entity{id:2})
      INSERT (a)-[@Connect_1]->(b)
      """
    Then an Error should be raised: "[NR211]: Insert failed, property `degree` of type `Connect_1` not found"
    When executing query:
      """
      ALTER GRAPH TYPE alter_default_value_gt {
        ALTER EDGE TYPE Connect_1 MODIFY PROPERTIES {degree INT NOT NULL DEFAULT 1}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE alter_default_value_g
      MATCH (a@Entity{id:1})
      MATCH (b@Entity{id:2})
      INSERT (a)-[@Connect_1]->(b)
      """
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE alter_default_value_g
      MATCH (a)-[e@Connect_1]->(b)
      RETURN a.id, e, b.id
      """
    Then the result should be, in any order:
      | a.id | e            | b.id |
      | 1    | [{degree:1}] | 2    |
    When executing query:
      """
      SHOW CREATE GRAPH TYPE alter_default_value_gt
      """
    Then the result should be, in any order:
      | graph_type_name          | create_graph_type_statement                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
      | "alter_default_value_gt" | "CREATE GRAPH TYPE IF NOT EXISTS `alter_default_value_gt` AS {\n  NODE TYPE `Entity` ({`id` INT64 NOT NULL, `test_list` LIST<STRING> NOT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `Entity_1` ({`id` INT64 NOT NULL, `test_int` INT64 NOT NULL DEFAULT CAST(1 AS INT64), PRIMARY KEY (`id`)}),\n  EDGE TYPE `Connect` (`Entity`)-[{`degree` INT64 NOT NULL}]->(`Entity`),\n  EDGE TYPE `Connect_1` (`Entity`)-[{`degree` INT64 NOT NULL DEFAULT CAST(1 AS INT64)}]->(`Entity`)\n}" |
    And drop the graph "alter_default_value_g"
    And drop the graph type "alter_default_value_gt"

  Scenario: unsupported default value
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS default_value_expression_type AS {
        NODE node_type_player (LABEL player {
          id INT PRIMARY KEY DEFAULT 1
        })
      }
      """
    Then an Error should be raised: "[NT010]: Defining default value on primary key is not supported, node type: `node_type_player`, property name: `id`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS default_value_expression_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY}),
        EDGE follow (node_type_player)-[:follow{degree INT DEFAULT 1 MULTIEDGE KEY}]->(node_type_player)
      }
      """
    Then an Error should be raised: "[NT011]: Defining default value on multiedge key is not supported, edge type: `follow`, property name: `degree`"
