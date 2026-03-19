# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: BindingTableImport

  Scenario: Import from binding table with PRIMARY_KEY_AS_NODE_ID enabled
    And drop the graph type "import_binding_table_pk_as_id_gt"
    And drop the graph "#import_binding_table_pk_as_id_g"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_binding_table_pk_as_id_gt AS {
        NODE Person (
          LABEL Person {
            id INT PRIMARY KEY,
            date_col STRING
          }
        ),
        EDGE Likes (Person)-[:Likes
        {
          id INT,
          MULTIEDGE KEY()
        }]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_binding_table_pk_as_id_g TYPED import_binding_table_pk_as_id_gt
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ set_var(query_concurrency=10) */
      USE #import_binding_table_pk_as_id_g {
        TABLE nodes TYPED TABLE {id INT, date_col STRING} =
          {id: 1, date_col: "xixi"},
          {id: 3, date_col: "xixi"},
          {id: 4, date_col: "xixi"},
          {id: 5, date_col: "xixi"}

        TABLE edges TYPED TABLE {src_id INT, dst_id INT, id INT} =
          {src_id: 1, dst_id: 3, id: 1},
          {src_id: 4, dst_id: 5, id: 2}

        IMPORT INTO GRAPH {
          NODE (v@Person{ id: id, date_col: date_col }) FROM nodes,
          EDGE (id:src_id)-[e@Likes{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #import_binding_table_pk_as_id_g SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 4         |
      | "Edge Total" | "Edge"       | 2         |
    # verify imported nodes
    When executing query:
      """
      USE #import_binding_table_pk_as_id_g {
        MATCH (v@Person)
        return v.id, v.date_col
      }
      """
    Then the result should be, in any order:
      | v.id | v.date_col |
      | 1    | "xixi"     |
      | 3    | "xixi"     |
      | 4    | "xixi"     |
      | 5    | "xixi"     |
    # verify imported edges
    When executing query:
      """
      USE #import_binding_table_pk_as_id_g {
        MATCH (v1@Person)-[e:Likes]->(v2@Person)
        RETURN v1.id, v2.id, e.id
      }
      """
    Then the result should be, in any order:
      | v1.id | v2.id | e.id |
      | 1     | 3     | 1    |
      | 4     | 5     | 2    |
    And drop the graph "#import_binding_table_pk_as_id_g"
    And drop the graph type "import_binding_table_pk_as_id_gt"

  Scenario: Import from binding table with PRIMARY_KEY_AS_NODE_ID enabled various property types, multiple edges, different concurrency
    And drop the graph type "import_binding_table_types_multi_edges_gt"
    And drop the graph "#import_binding_table_types_multi_edges_g"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_binding_table_types_multi_edges_gt AS {
        NODE Person (
          LABEL Person {
            id INT64 PRIMARY KEY,
            name STRING,
            age INT,
            active BOOL,
            score DOUBLE,
            created_date DATE,
            local_t LOCAL TIME,
            zoned_t ZONED TIME,
            local_dt LOCAL DATETIME,
            zoned_dt ZONED DATETIME
          }
        ),
        NODE Tag (
          LABEL Tag {
            id INT64 PRIMARY KEY,
            tag STRING
          }
        ),
        EDGE Likes (Person)-[:Likes{
          id INT,
          since DATE,
          weight DOUBLE,
          MULTIEDGE KEY()
        }]->(Person),
        EDGE HasTag (Person)-[:HasTag{
          id INT,
          tag_time ZONED DATETIME,
          MULTIEDGE KEY()
        }]->(Tag)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_binding_table_types_multi_edges_g TYPED import_binding_table_types_multi_edges_gt
      """
    Then the execution should be successful
    # concurrency = 1
    When executing query:
      """
      /*+ set_var(query_concurrency=1) */
      USE #import_binding_table_types_multi_edges_g {
        TABLE persons TYPED TABLE {
          id INT64,
          name STRING,
          age INT,
          active BOOL,
          score DOUBLE,
          created_date DATE,
          local_t LOCAL TIME,
          zoned_t ZONED TIME,
          local_dt LOCAL DATETIME,
          zoned_dt ZONED DATETIME
        } =
          {id: 1, name: "Alice", age: 18, active: true, score: 1.5, created_date: date("2020-02-29"), local_t: local_time("23:59:59"), zoned_t: zoned_time("07:59:59Z"), local_dt: local_datetime("2020-02-29T23:59:59"), zoned_dt: zoned_datetime("2020-03-01T07:59:59Z")},
          {id: 2, name: "Bob", age: 20, active: false, score: 3.14, created_date: date("1990-01-01"), local_t: local_time("01:02:03"), zoned_t: zoned_time("01:02:03Z"), local_dt: local_datetime("1990-01-01T01:02:03"), zoned_dt: zoned_datetime("1990-01-01T01:02:03Z")}

        TABLE tags TYPED TABLE {id INT64, tag1 STRING} =
          {id: 101, tag1: "t1"},
          {id: 102, tag1: "t2"}

        TABLE likes TYPED TABLE {src_id INT64, dst_id INT64, id INT, since DATE, weight DOUBLE} =
          {src_id: 1, dst_id: 2, id: 11, since: date("2020-02-29"), weight: 0.5},
          {src_id: 2, dst_id: 1, id: 12, since: date("1990-01-01"), weight: 2.0}

        TABLE has_tag TYPED TABLE {src_id INT64, dst_id INT64, id INT, tag_time ZONED DATETIME} =
          {src_id: 1, dst_id: 101, id: 21, tag_time: zoned_datetime("2020-02-29T23:59:59Z")},
          {src_id: 2, dst_id: 102, id: 22, tag_time: zoned_datetime("1990-01-01T01:02:03Z")}

        IMPORT INTO GRAPH {
          NODE (p@Person{
            id: id,
            name: name,
            age: age,
            active: active,
            score: score,
            created_date: created_date,
            local_t: local_t,
            zoned_t: zoned_t,
            local_dt: local_dt,
            zoned_dt: zoned_dt
          }) FROM persons,
          NODE (t@Tag{ id: id, tag: tag1 }) FROM tags,
          EDGE (id:src_id)-[e@Likes{ id: id, since: since, weight: weight }]->(id:dst_id) FROM likes,
          EDGE (id:src_id)-[e2@HasTag{ id: id, tag_time: tag_time }]->(id:dst_id) FROM has_tag
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #import_binding_table_types_multi_edges_g SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 4         |
      | "Edge Total" | "Edge"       | 4         |
    # verify imported nodes (type conversions for temporal strings)
    When executing query:
      """
      USE #import_binding_table_types_multi_edges_g {
        MATCH (p@Person)
        RETURN p.id, p.name, p.age, p.active, p.score, p.created_date, p.local_t, p.zoned_t, p.local_dt, p.zoned_dt
        ORDER BY p.id
      }
      """
    Then the result should be, in order:
      | p.id | p.name  | p.age | p.active | p.score | p.created_date    | p.local_t              | p.zoned_t                    | p.local_dt                            | p.zoned_dt                                  |
      | 1    | "Alice" | 18    | true     | 1.5     | DATE "2020-02-29" | TIME "23:59:59.000000" | ZONED TIME "07:59:59.000000" | DATETIME "2020-02-29T23:59:59.000000" | ZONED DATETIME "2020-03-01T07:59:59.000000" |
      | 2    | "Bob"   | 20    | false    | 3.14    | DATE "1990-01-01" | TIME "01:02:03.000000" | ZONED TIME "01:02:03.000000" | DATETIME "1990-01-01T01:02:03.000000" | ZONED DATETIME "1990-01-01T01:02:03.000000" |
    When executing query:
      """
      USE #import_binding_table_types_multi_edges_g {
        MATCH (t@Tag)
        RETURN t.id, t.tag
        ORDER BY t.id
      }
      """
    Then the result should be, in order:
      | t.id | t.tag |
      | 101  | "t1"  |
      | 102  | "t2"  |
    # verify imported edges
    When executing query:
      """
      USE #import_binding_table_types_multi_edges_g {
        MATCH (p1@Person)-[e:Likes]->(p2@Person)
        RETURN p1.id, p2.id, e.id, e.since, e.weight
        ORDER BY e.id
      }
      """
    Then the result should be, in order:
      | p1.id | p2.id | e.id | e.since           | e.weight |
      | 1     | 2     | 11   | DATE "2020-02-29" | 0.5      |
      | 2     | 1     | 12   | DATE "1990-01-01" | 2        |
    When executing query:
      """
      USE #import_binding_table_types_multi_edges_g {
        MATCH (p@Person)-[e:HasTag]->(t@Tag)
        RETURN p.id, t.id, e.id, e.tag_time
        ORDER BY e.id
      }
      """
    Then the result should be, in order:
      | p.id | t.id | e.id | e.tag_time                                  |
      | 1    | 101  | 21   | ZONED DATETIME "2020-02-29T23:59:59.000000" |
      | 2    | 102  | 22   | ZONED DATETIME "1990-01-01T01:02:03.000000" |
    And drop the graph "#import_binding_table_types_multi_edges_g"
    And drop the graph type "import_binding_table_types_multi_edges_gt"

  Scenario: Import from binding table with should fail on incompatible types
    And drop the graph type "import_binding_table_incompatible_types_gt"
    And drop the graph "#import_binding_table_incompatible_types_g"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_binding_table_incompatible_types_gt AS {
        NODE Person (
          LABEL Person {
            id INT64 PRIMARY KEY,
            age INT,
            active BOOL,
            created_date DATE,
            local_t LOCAL TIME,
            zoned_t ZONED TIME,
            local_dt LOCAL DATETIME,
            zoned_dt ZONED DATETIME
          }
        )
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_binding_table_incompatible_types_g TYPED import_binding_table_incompatible_types_gt
      """
    Then the execution should be successful
    # incompatible: STRING -> INT, STRING -> BOOL, invalid temporal formats
    When executing query:
      """
      /*+ set_var(query_concurrency=10) */
      USE #import_binding_table_incompatible_types_g {
        TABLE persons_bad TYPED TABLE {
          id INT64,
          age STRING,
          active STRING,
          created_date STRING,
          local_t STRING,
          zoned_t STRING,
          local_dt STRING,
          zoned_dt STRING
        } =
          {id: 1, age: "not_an_int", active: "not_a_bool", created_date: "2020-13-40", local_t: "25:61:61", zoned_t: "11:11:11", local_dt: "2020-02-30T00:00:00", zoned_dt: "2020-02-29T23:59:59"}

        IMPORT INTO GRAPH {
          NODE (p@Person{
            id: id,
            age: age,
            active: active,
            created_date: created_date,
            local_t: local_t,
            zoned_t: zoned_t,
            local_dt: local_dt,
            zoned_dt: zoned_dt
          }) FROM persons_bad
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Type mismatch, column `age`, expect: INT64, got: STRING"
    # check column not exists
    When executing query:
      """
      /*+ set_var(query_concurrency=10) */
      USE #import_binding_table_incompatible_types_g {
        TABLE persons_bad TYPED TABLE {
          id INT64,
          age STRING,
          active STRING,
          created_date STRING,
          local_t STRING,
          zoned_t STRING,
          local_dt STRING,
          zoned_dt STRING
        } =
          {id: 1, age: "not_an_int", active: "not_a_bool", created_date: "2020-13-40", local_t: "25:61:61", zoned_t: "11:11:11", local_dt: "2020-02-30T00:00:00", zoned_dt: "2020-02-29T23:59:59"}

        IMPORT INTO GRAPH {
          NODE (p@Person{
            id: x,
            age: age,
            active: active,
            created_date: created_date,
            local_t: local_t,
            zoned_t: zoned_t,
            local_dt: local_dt,
            zoned_dt: zoned_dt
          }) FROM persons_bad
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Column `x` not found in `persons_bad`"
    And drop the graph "#import_binding_table_incompatible_types_g"
    And drop the graph type "import_binding_table_incompatible_types_gt"

  Scenario: Import from binding table test default values and NOT NULL constraints
    And drop the graph type "import_binding_table_default_notnull_gt"
    And drop the graph "#import_binding_table_default_notnull_g"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_binding_table_default_notnull_gt AS {
        NODE Person (
          LABEL Person {
            id INT64 PRIMARY KEY,
            name STRING NOT NULL,
            age INT DEFAULT 18,
            score DOUBLE DEFAULT 0.0,
            active BOOL DEFAULT true
          }
        ),
        EDGE Knows (Person)-[:Knows{
          id INT,
          since DATE DEFAULT DATE "2020-01-01",
          weight DOUBLE NOT NULL,
          MULTIEDGE KEY()
        }]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_binding_table_default_notnull_g TYPED import_binding_table_default_notnull_gt
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_binding_table_default_notnull_g_edge TYPED import_binding_table_default_notnull_gt
      """
    Then the execution should be successful
    # import with default values
    When executing query:
      """
      /*+ set_var(query_concurrency=1) */
      USE #import_binding_table_default_notnull_g {
        TABLE persons TYPED TABLE {id INT64, name STRING, age INT} =
          {id: 1, name: "Alice", age: 20},
          {id: 2, name: "Bob", age: 25}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name, age: age }) FROM persons
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #import_binding_table_default_notnull_g {
        MATCH (p@Person)
        RETURN p.id, p.name, p.age, p.score, p.active
        ORDER BY p.id
      }
      """
    Then the result should be, in order:
      | p.id | p.name  | p.age | p.score | p.active |
      | 1    | "Alice" | 20    | 0.0     | true     |
      | 2    | "Bob"   | 25    | 0.0     | true     |
    # Test NOT NULL constraint violation: missing required field
    When executing query:
      """
      /*+ set_var(query_concurrency=1) */
      USE #import_binding_table_default_notnull_g {
        TABLE persons_bad TYPED TABLE {id INT64, age INT, name STRING} =
          {id: 4, age: 30, name: null}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, age: age, name: name }) FROM persons_bad
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then an Error should be raised: "[ND008]: Property `name` of type `Person` is not nullable"
    When executing query:
      """
      /*+ set_var(query_concurrency=10) */
      USE #import_binding_table_default_notnull_g_edge {
        TABLE edges TYPED TABLE {src_id INT64, dst_id INT64, id INT, weight DOUBLE} =
          {src_id: 1, dst_id: 2, id: 1, weight: 0.5}

        IMPORT INTO GRAPH {
          EDGE (id:src_id)-[e@Knows{ id: id, weight: weight }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Edge type `Knows` references missing source node type `Person`"
    # Test edge NOT NULL constraint violation
    When executing query:
      """
      /*+ set_var(query_concurrency=1) */
      USE #import_binding_table_default_notnull_g_edge {
        TABLE edges_bad TYPED TABLE {src_id INT64, dst_id INT64, id INT, since DATE} =
          {src_id: 2, dst_id: 3, id: 2, since: date("2021-01-01")}
        TABLE nodes TYPED TABLE {id INT64, age INT, name STRING} =
          {id: 2, age: 30, name: "HuaLi" }, {id: 3, age: 25, name: "LiHua"}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, age: age, name: name }) FROM nodes,
          EDGE (id:src_id)-[e@Knows{ id: id, since: since }]->(id:dst_id) FROM edges_bad
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then an Error should be raised: "[NR125]: Invalid graph data source: Property `weight` of type `Knows` has no default value"
    When executing query:
      """
      /*+ set_var(query_concurrency=1) */
      USE #import_binding_table_default_notnull_g_edge {
        TABLE edges_bad TYPED TABLE {src_id INT64, dst_id INT64, id INT, since DATE, weight DOUBLE} =
          {src_id: 2, dst_id: 3, id: 2, since: date("2021-01-01"), weight: null}
        TABLE nodes TYPED TABLE {id INT64, age INT, name STRING} =
          {id: 2, age: 30, name: "HuaLi" }, {id: 3, age: 25, name: "LiHua"}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, age: age, name: name }) FROM nodes,
          EDGE (id:src_id)-[e@Knows{ id: id, since: since, weight: weight }]->(id:dst_id) FROM edges_bad
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then an Error should be raised: "[ND008]: Property `weight` of type `Knows` is not nullable"
    And drop the graph "#import_binding_table_default_notnull_g"
    And drop the graph "#import_binding_table_default_notnull_g_edge"
    And drop the graph type "import_binding_table_default_notnull_gt"

  Scenario: Import from binding table test extra columns in table
    And drop the graph type "import_binding_table_extra_cols_gt"
    And drop the graph "#import_binding_table_extra_cols_g"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_binding_table_extra_cols_gt AS {
        NODE Person (
          LABEL Person {
            id INT64 PRIMARY KEY,
            name STRING
          }
        ),
        EDGE Follows (Person)-[:Follows{
          id INT,
          MULTIEDGE KEY()
        }]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_binding_table_extra_cols_g TYPED import_binding_table_extra_cols_gt
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_binding_table_extra_cols_g1 TYPED import_binding_table_extra_cols_gt
      """
    Then the execution should be successful
    # Test with concurrency=1: table has more columns than needed
    When executing query:
      """
      /*+ set_var(query_concurrency=1) */
      USE #import_binding_table_extra_cols_g {
        TABLE persons TYPED TABLE {id INT64, name STRING, age INT, city STRING, extra1 BOOL, extra2 DOUBLE} =
          {id: 1, name: "Alice", age: 20, city: "NYC", extra1: true, extra2: 1.5},
          {id: 2, name: "Bob", age: 25, city: "LA", extra1: false, extra2: 2.5}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name }) FROM persons
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #import_binding_table_extra_cols_g {
        MATCH (p@Person)
        RETURN p.id, p.name
        ORDER BY p.id
      }
      """
    Then the result should be, in order:
      | p.id | p.name  |
      | 1    | "Alice" |
      | 2    | "Bob"   |
    # Test edges with extra columns
    When executing query:
      """
      /*+ set_var(query_concurrency=10) */
      USE #import_binding_table_extra_cols_g1 {
        TABLE edges TYPED TABLE {
          src_id INT64,
          dst_id INT64,
          id INT,
          weight DOUBLE,
          t STRING,
          extra_col1 BOOL,
          extra_col2 INT
        } =
          {src_id: 1, dst_id: 2, id: 1, weight: 0.5, t: "2020-01-01", extra_col1: true, extra_col2: 100},
          {src_id: 2, dst_id: 3, id: 2, weight: 1.0, t: "2021-01-01", extra_col1: false, extra_col2: 200}
        TABLE nodes TYPED TABLE {id INT64, name STRING, age INT, city STRING, extra1 BOOL, extra2 DOUBLE} =
          {id: 1, name: "Alice", age: 20, city: "NYC", extra1: true, extra2: 1.5},
          {id: 2, name: "Bob", age: 25, city: "LA", extra1: false, extra2: 2.5},
          {id: 3, name: "Bob", age: 25, city: "LA", extra1: false, extra2: 2.5}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id, name: name }) FROM nodes,
          EDGE (id:src_id)-[e@Follows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #import_binding_table_extra_cols_g1 {
        MATCH (p1@Person)-[e:Follows]->(p2@Person)
        RETURN p1.id, e.id, p2.id
        ORDER BY e.id
      }
      """
    Then the result should be, in order:
      | p1.id | e.id | p2.id |
      | 1     | 1    | 2     |
      | 2     | 2    | 3     |
    And drop the graph "#import_binding_table_extra_cols_g"
    And drop the graph "#import_binding_table_extra_cols_g1"
    And drop the graph type "import_binding_table_extra_cols_gt"

  Scenario: Import from binding table with PRIMARY_KEY_AS_NODE_ID disabled
    And drop the graph type "import_binding_table_pk_not_as_id_gt"
    And drop the graph "#import_binding_table_pk_not_as_id_g"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_binding_table_pk_not_as_id_gt AS {
        NODE Person (
          LABEL Person {
            id INT PRIMARY KEY,
            name STRING
          }
        ),
        EDGE Likes (Person)-[:Likes{
          id INT,
          MULTIEDGE KEY()
        }]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_binding_table_pk_not_as_id_g TYPED import_binding_table_pk_not_as_id_gt
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ set_var(query_concurrency=4) */
      USE #import_binding_table_pk_not_as_id_g {
        TABLE nodes TYPED TABLE {id INT, name STRING} =
          {id: 1, name: "a"},
          {id: 2, name: "b"},
          {id: 3, name: "c"}

        TABLE edges TYPED TABLE {src_id INT, dst_id INT, id INT} =
          {src_id: 1, dst_id: 2, id: 10},
          {src_id: 2, dst_id: 3, id: 11}

        IMPORT INTO GRAPH {
          NODE (v@Person{ id: id, name: name }) FROM nodes,
          EDGE (id:src_id)-[e@Likes{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #import_binding_table_pk_not_as_id_g SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 3         |
      | "Edge Total" | "Edge"       | 2         |
    And drop the graph "#import_binding_table_pk_not_as_id_g"
    And drop the graph type "import_binding_table_pk_not_as_id_gt"

  Scenario: Import from binding table with PRIMARY_KEY_AS_NODE_ID disabled should fail on missing nodes
    And drop the graph type "import_binding_table_pk_not_as_id_fail_gt"
    And drop the graph "#import_binding_table_pk_not_as_id_fail_g"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_binding_table_pk_not_as_id_fail_gt AS {
        NODE Person (
          LABEL Person {
            id INT PRIMARY KEY
          }
        ),
        EDGE Likes (Person)-[:Likes{
          id INT,
          MULTIEDGE KEY()
        }]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_binding_table_pk_not_as_id_fail_g TYPED import_binding_table_pk_not_as_id_fail_gt
      """
    Then the execution should be successful
    When executing query:
      """
      USE #import_binding_table_pk_not_as_id_fail_g {
        TABLE nodes TYPED TABLE {id INT} =
          {id: 1}

        TABLE edges TYPED TABLE {src_id INT, dst_id INT, id INT} =
          {src_id: 1, dst_id: 2, id: 1}

        IMPORT INTO GRAPH {
          NODE (v@Person{ id: id }) FROM nodes,
          EDGE (id:src_id)-[e@Likes{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then an Error should be raised: "[NR124]: Failed to build temporary graph: There're dangling edges, src pk: |1| found, dst pk: |2| not found "
    And drop the graph "#import_binding_table_pk_not_as_id_fail_g"
    And drop the graph type "import_binding_table_pk_not_as_id_fail_gt"

  Scenario: Import from binding table into immutable graph with composite primary key
    And drop the graph type "import_composite_pk_gt"
    And drop the graph "#import_immutable_composite_pk_g"
    And drop the graph "#import_mutable_composite_pk_g"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_composite_pk_gt AS {
        NODE Person (LABEL Employee {id INT, name STRING, PRIMARY KEY(id, name)}),
        EDGE WorksFor (Person)-[:WorksFor{
          id INT,
          since DATE,
          MULTIEDGE KEY()
        }]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_immutable_composite_pk_g TYPED import_composite_pk_gt OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_mutable_composite_pk_g TYPED import_composite_pk_gt
      """
    Then the execution should be successful
    # Import mutable graph nodes and edges with composite primary key
    When executing query:
      """
      /*+ set_var(query_concurrency=4) */
      USE #import_mutable_composite_pk_g {
        TABLE persons TYPED TABLE {id INT, name STRING} =
          {id: 1, name: "Alice"},
          {id: 2, name: "Bob"},
          {id: 3, name: "Charlie"}

        TABLE works_for TYPED TABLE {emp_id INT, emp_name STRING, e_id INT, since DATE, boss_id INT, boss_name STRING} =
          {emp_id: 1, emp_name: "Alice", e_id: 1, since: date("2020-01-01"), boss_id: 2, boss_name: "Bob"},
          {emp_id: 2, emp_name: "Bob", e_id: 2, since: date("2019-05-15"), boss_id: 3, boss_name: "Charlie"}

        IMPORT INTO GRAPH {
          NODE (e@Person{ id: id, name: name }) FROM persons,
          EDGE (id:emp_id, name: emp_name)-[ef@WorksFor{ id: e_id, since: since }]->(id:boss_id, name:boss_name) FROM works_for
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then the execution should be successful
    # Verify imported data
    When executing query:
      """
      USE #import_mutable_composite_pk_g SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 3         |
      | "Edge Total" | "Edge"       | 2         |
    When executing query:
      """
      USE #import_mutable_composite_pk_g {
        MATCH (e@Person)
        RETURN e.id, e.name
        ORDER BY e.id
      }
      """
    Then the result should be, in order:
      | e.id | e.name    |
      | 1    | "Alice"   |
      | 2    | "Bob"     |
      | 3    | "Charlie" |
    When executing query:
      """
      USE #import_mutable_composite_pk_g {
        MATCH (e@Person)-[ef:WorksFor]->(p@Person)
        RETURN e.id, e.name, p.id, ef.since
        ORDER BY ef.id
      }
      """
    Then the result should be, in order:
      | e.id | e.name  | p.id | ef.since          |
      | 1    | "Alice" | 2    | DATE "2020-01-01" |
      | 2    | "Bob"   | 3    | DATE "2019-05-15" |
    # Import immutable graph nodes and edges with composite primary key
    When executing query:
      """
      /*+ set_var(query_concurrency=4) */
      USE #import_immutable_composite_pk_g {
        TABLE persons TYPED TABLE {id INT, name STRING} =
          {id: 1, name: "Alice"},
          {id: 2, name: "Bob"},
          {id: 3, name: "Charlie"}

        TABLE works_for TYPED TABLE {emp_id INT, emp_name STRING, e_id INT, since DATE, boss_id INT, boss_name STRING} =
          {emp_id: 1, emp_name: "Alice", e_id: 1, since: date("2020-01-01"), boss_id: 2, boss_name: "Bob"},
          {emp_id: 2, emp_name: "Bob", e_id: 2, since: date("2019-05-15"), boss_id: 3, boss_name: "Charlie"}

        IMPORT INTO GRAPH {
          NODE (e@Person{ id: id, name: name }) FROM persons,
          EDGE (id:emp_id, name: emp_name)-[ef@WorksFor{ id: e_id, since: since }]->(id:boss_id, name:boss_name) FROM works_for
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then the execution should be successful
    # Verify imported data
    When executing query:
      """
      USE #import_immutable_composite_pk_g SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 3         |
      | "Edge Total" | "Edge"       | 2         |
    When executing query:
      """
      USE #import_immutable_composite_pk_g {
        MATCH (e@Person)
        RETURN e.id, e.name
        ORDER BY e.id
      }
      """
    Then the result should be, in order:
      | e.id | e.name    |
      | 1    | "Alice"   |
      | 2    | "Bob"     |
      | 3    | "Charlie" |
    When executing query:
      """
      USE #import_immutable_composite_pk_g {
        MATCH (e@Person)-[ef:WorksFor]->(p@Person)
        RETURN e.id, e.name, p.id, ef.since
        ORDER BY ef.id
      }
      """
    Then the result should be, in order:
      | e.id | e.name  | p.id | ef.since          |
      | 1    | "Alice" | 2    | DATE "2020-01-01" |
      | 2    | "Bob"   | 3    | DATE "2019-05-15" |
    And drop the graph "#import_mutable_composite_pk_g"
    And drop the graph "#import_immutable_composite_pk_g"
    And drop the graph type "import_composite_pk_gt"

  Scenario: Unsupported
    And drop the graph type "unsupported_import_gt"
    And drop the graph "#unsupported_import_g"
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS unsupported_import_gt AS {
        NODE Person (
          LABEL Person {
            id INT PRIMARY KEY,
            date_col STRING
          }
        ),
        EDGE Likes (Person)-[:Likes
        {
          id INT,
          MULTIEDGE KEY()
        }]->(Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #unsupported_import_g TYPED unsupported_import_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ set_var(query_concurrency=10) */
      USE #unsupported_import_g {
        TABLE nodes TYPED TABLE {id INT, date_col STRING} =
          {id: 1, date_col: "xixi"},
          {id: 3, date_col: "xixi"},
          {id: 4, date_col: "xixi"},
          {id: 5, date_col: "xixi"}

        TABLE edges TYPED TABLE {src_id INT, dst_id INT, id INT} =
          {src_id: 1, dst_id: 3, id: 1},
          {src_id: 4, dst_id: 5, id: 2}

        IMPORT INTO GRAPH {
          NODE (v@Person{ id: id, date_col: date_col }) FROM nodes,
          EDGE (id:src_id)-[e@Likes{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then an Error should be raised:   "[NR125]: Invalid graph data source: Importing a non-distributed BindingTable into a distributed temporary graph is not supported"
    And drop the graph "#unsupported_import_g"
    And drop the graph type "unsupported_import_gt"
