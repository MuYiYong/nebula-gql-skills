# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Streaming Hash Join

  @sf01
  Scenario: recursive limit
    # This query should finish in less than 1 second
    When executing query:
      """
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{20}(f:Person)
      LIMIT 100
      RETURN count(f.id) group by ()
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=on") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{1}(f:Person)
      LIMIT 10000000
      RETURN f.id as fid
      """
    Then the result should be, in any order:
      | fid            |
      | 32985348834375 |
      | 13194139533574 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=off") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{1}(f:Person)
      LIMIT 10000000
      RETURN f.id as fid
      """
    Then the result should be, in any order:
      | fid            |
      | 32985348834375 |
      | 13194139533574 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=on") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{2}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total |
      | 69    |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=off") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{2}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total |
      | 69    |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=on") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{5}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total |
      | 42941 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=off") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{5}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total |
      | 42941 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=on") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{0, 1}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total |
      | 3     |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=off") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{0, 1}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total |
      | 3     |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=on") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{0, 5}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total |
      | 50380 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=off") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{0, 5}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total |
      | 50380 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=on") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{1, 5}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total |
      | 50379 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=off") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{1, 5}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total |
      | 50379 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=on") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{2, 6}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total  |
      | 272365 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=off") */
      USE sf01 MATCH (v:Person{id: 4398046511467})-[:KNOWS]->{2, 6}(f:Person)
      LIMIT 10000000
      RETURN count(f.id) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total  |
      | 272365 |
    When executing query:
      """
      use sf01 match p=trail (n1@Person)-[e@PERSON_IS_LOCATED_IN_CITY]->*(n2:Person) return * limit 1
      """
    Then the execution should be successful

  Scenario: Share delimnode and bridge
    When executing query:
      """
      USE ldbc {
      MATCH
        ()-[e1]-(v1)
      MATCH
        ()-[e2]-{1,1}(),
        (v1)
      LIMIT 1
      FILTER true
      RETURN count(e1) as c
      }
      """
    Then the result should be, in any order:
      | c |
      | 1 |

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/9545
  @sf01
  Scenario: Do not push down limit for edge scan of compound types
    When executing query:
      """
      USE sf01 {
        MATCH p=(v1:Person{id:318})-[e]->{2}(v2:University) return v2.id AS vid LIMIT 10
        NEXT RETURN COUNT(vid) as cnt
      }
      """
    Then the result should be, in any order:
      | cnt |
      | 10  |

  Scenario: Limit On Multi Hop Query Extend From Multiedge
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS shj_multiedge_type AS {
        NODE person (LABEL Person {id INT PRIMARY KEY}),
        NODE company (LABEL Company {id INT PRIMARY KEY}),
        EDGE knows (person)-[LABEL KNOWS]->(person),
        EDGE works_at (person)-[LABEL WORKS_AT]->(company)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS shj_multiedge TYPED shj_multiedge_type
      """
    Then the execution should be successful
    And graph "shj_multiedge" should be ready to use
    When executing query:
      """
      USE shj_multiedge FOR pid IN RANGE(11, 13) INSERT (@person{id: pid})
      """
    Then the execution should be successful
    When executing query:
      """
      USE shj_multiedge FOR cid IN RANGE(21, 21) INSERT (@company{id: cid})
      """
    Then the execution should be successful
    When executing query:
      """
      USE shj_multiedge
      MATCH (p1:Person{id: 11}), (p2:Person{id: 12}), (p3:Person{id: 13}), (c1:Company{id: 21})
      INSERT
        (p1)-[@knows]->(p2),
        (p2)-[@knows]->(p3),
        (p3)-[@knows]->(p1),
        (p1)-[@knows]->(p3),
        (p3)-[@works_at]->(c1)
      """
    Then the execution should be successful
    When executing query:
      """
      USE shj_multiedge
      MATCH (p1:Person{id: 11})-[e]->{1, 2}(c1:Company)
      RETURN c1.id AS cid LIMIT 1
      """
    Then the result should be, in any order:
      | cid |
      | 21  |
    When executing query:
      """
      USE shj_multiedge
      MATCH p = (p1:Person{id: 11})-[e]->{1, 3}(c1)
      RETURN c1.id AS cid, type(c1) AS ctyp limit 10
      """
    Then the result should be, in any order:
      | cid | ctyp      |
      | 12  | "person"  |
      | 12  | "person"  |
      | 11  | "person"  |
      | 11  | "person"  |
      | 13  | "person"  |
      | 13  | "person"  |
      | 13  | "person"  |
      | 21  | "company" |
      | 21  | "company" |
    When executing query:
      """
      USE shj_multiedge
      MATCH p = ACYCLIC (p1:Person{id: 11})-[e]->{1, 3}(c1)
      RETURN c1.id AS cid, type(c1) AS ctyp limit 10
      """
    Then the result should be, in any order:
      | cid | ctyp      |
      | 12  | "person"  |
      | 13  | "person"  |
      | 13  | "person"  |
      | 21  | "company" |
      | 21  | "company" |
    When executing query:
      """
      USE shj_multiedge
      MATCH p = TRAIL (p1:Person{id: 11})-[e]->{1, 3}(c1)
      RETURN c1.id AS cid, type(c1) AS ctyp limit 10
      """
    Then the result should be, in any order:
      | cid | ctyp      |
      | 12  | "person"  |
      | 12  | "person"  |
      | 11  | "person"  |
      | 11  | "person"  |
      | 13  | "person"  |
      | 13  | "person"  |
      | 21  | "company" |
      | 21  | "company" |
    When executing query:
      """
      USE shj_multiedge
      MATCH p = (p1:Person{id: 11})-[e]->{1, 3}(c1)
      RETURN c1.id AS cid, type(c1) AS ctyp, length(p) as len limit 10
      """
    Then the result should be, in any order:
      | cid | ctyp      | len |
      | 12  | "person"  | 1   |
      | 12  | "person"  | 3   |
      | 11  | "person"  | 2   |
      | 11  | "person"  | 3   |
      | 13  | "person"  | 1   |
      | 13  | "person"  | 2   |
      | 13  | "person"  | 3   |
      | 21  | "company" | 3   |
      | 21  | "company" | 2   |
    When executing query:
      """
      USE shj_multiedge
      MATCH p = ACYCLIC (p1:Person{id: 11})-[e]->{1, 3}(c1)
      RETURN c1.id AS cid, type(c1) AS ctyp, length(p) as len limit 10
      """
    Then the result should be, in any order:
      | cid | ctyp      | len |
      | 12  | "person"  | 1   |
      | 13  | "person"  | 1   |
      | 13  | "person"  | 2   |
      | 21  | "company" | 2   |
      | 21  | "company" | 3   |
    When executing query:
      """
      USE shj_multiedge
      MATCH p = TRAIL (p1:Person{id: 11})-[e]->{1, 3}(c1)
      RETURN c1.id AS cid, type(c1) AS ctyp, length(p) as len limit 10
      """
    Then the result should be, in any order:
      | cid | ctyp      | len |
      | 12  | "person"  | 1   |
      | 12  | "person"  | 3   |
      | 11  | "person"  | 2   |
      | 11  | "person"  | 3   |
      | 13  | "person"  | 1   |
      | 13  | "person"  | 2   |
      | 21  | "company" | 3   |
      | 21  | "company" | 2   |
    And drop the graph "shj_multiedge"
    And drop the graph type "shj_multiedge_type"

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/9775
  Scenario: Filter on node scan of last hop
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[e:KNOWS]->{0,2}(b where b.id < 2)
      RETURN v.id as src, b.id as dst
      LIMIT 1
      """
    Then the result should be, in any order:
      | src | dst |
      | 1   | 1   |

  Scenario: Streaming limit push down test
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS shj_streaming_limit_type AS {
        NODE n1 (LABEL N1 {n1prop INT64 PRIMARY KEY}),
        NODE n2 (LABEL N2 {n2prop INT64 PRIMARY KEY}),
        EDGE e1 (n1)-[LABEL E1 {e1prop INT64}]->(n1),
        EDGE e2 (n1)-[LABEL E2 {e2prop INT64}]->(n2),
        EDGE e3 (n2)-[LABEL E2 {e3prop INT64}]->(n1)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS shj_streaming_limit_graph TYPED shj_streaming_limit_type
      """
    Then the execution should be successful
    And graph "shj_streaming_limit_graph" should be ready to use
    When executing query:
      """
      USE shj_streaming_limit_graph
      INSERT (@n1{n1prop: 1}),
        (@n1{n1prop: 2}),
        (@n1{n1prop: 3}),
        (@n1{n1prop: 4})
      """
    Then the execution should be successful
    When executing query:
      """
      USE shj_streaming_limit_graph
      MATCH (v:N1{n1prop: 1}), (t:N1 WHERE t.n1prop > 1)
      INSERT
        (v)-[@e1{e1prop: 11}]->(t)
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "var_len_to_bi_var_len=off") */
      USE shj_streaming_limit_graph
      MATCH (s:N1{n1prop: 1})-[e:E1]->{0, 1}(t:N1)
      LIMIT 100
      RETURN t.n1prop AS n1prop
      """
    Then the result should be, in any order:
      | n1prop |
      | 1      |
      | 2      |
      | 3      |
      | 4      |
    # no limit should be push down
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "var_len_to_bi_var_len=off") */
      USE shj_streaming_limit_graph
      MATCH (s:N1{n1prop: 1})-[e:E1]->{0, 1}(t:N1 WHERE t.n1prop > 3)
      LIMIT 1
      RETURN t.n1prop AS n1prop
      """
    Then the result should be, in any order:
      | n1prop |
      | 4      |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "var_len_to_bi_var_len=off") */
      USE shj_streaming_limit_graph
      MATCH p = (s:N1{n1prop: 1})-[e:E1]->{0, 1}(t:N1)
      LIMIT 10
      RETURN (nodes(p)[1]).n1prop AS n1prop
      """
    Then the result should be, in any order:
      | n1prop |
      | 2      |
      | 3      |
      | 4      |
      | null   |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "var_len_to_bi_var_len=off") */
      USE shj_streaming_limit_graph
      MATCH p = (s:N1{n1prop: 1})-[e:E1]->{0, 1}(t:N1 WHERE t.n1prop > 3)
      LIMIT 1
      RETURN (nodes(p)[1]).n1prop AS n1prop
      """
    Then the result should be, in any order:
      | n1prop |
      | 4      |
    # node edge type filter
    When executing query:
      """
      USE shj_streaming_limit_graph
      MATCH ()-[e]->()
      DELETE e
      """
    Then the execution should be successful
    When executing query:
      """
      USE shj_streaming_limit_graph
      MATCH (v)
      DELETE v
      """
    Then the execution should be successful
    When executing query:
      """
      USE shj_streaming_limit_graph
      INSERT (@n1{n1prop: 1}),
        (@n1{n1prop: 2}),
        (@n2{n2prop: 3})
      """
    Then the execution should be successful
    When executing query:
      """
      USE shj_streaming_limit_graph
      MATCH (n11:N1{n1prop: 1}), (n12:N1{n1prop: 2}), (n23:N2{n2prop: 3})
      INSERT
        (n11)-[@e1{e1prop: 1112}]->(n12),
        (n12)-[@e2{e2prop: 1223}]->(n23),
        (n11)-[@e2{e2prop: 1123}]->(n23),
        (n23)-[@e3{e3prop: 2312}]->(n12)
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "var_len_to_bi_var_len=off") */
      USE shj_streaming_limit_graph
      MATCH p = (v:N1)-[e]->{2}(t:N1)
      RETURN LENGTH(p) AS sz
      LIMIT 1
      """
    Then the result should be, in any order:
      | sz |
      | 2  |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "var_len_to_bi_var_len=off") */
      USE shj_streaming_limit_graph
      MATCH p = (v:N1)-[e]->{2}(t)
      RETURN LENGTH(p) AS sz
      LIMIT 10
      """
    Then the result should be, in any order:
      | sz |
      | 2  |
      | 2  |
      | 2  |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "var_len_to_bi_var_len=off") */
      USE shj_streaming_limit_graph
      MATCH p = (v:N1)-[e]->{1, 2}(t)
      RETURN LENGTH(p) AS sz
      LIMIT 10
      """
    Then the result should be, in any order:
      | sz |
      | 2  |
      | 2  |
      | 2  |
      | 1  |
      | 1  |
      | 1  |
    # test quantified path
    When executing query:
      """
      USE shj_streaming_limit_graph
      MATCH ()-[e]->()
      DELETE e
      """
    Then the execution should be successful
    When executing query:
      """
      USE shj_streaming_limit_graph
      MATCH (v)
      DELETE v
      """
    Then the execution should be successful
    When executing query:
      """
      USE shj_streaming_limit_graph
      INSERT (@n1{n1prop: 1}),
        (@n1{n1prop: 2}),
        (@n1{n1prop: 3})
      """
    Then the execution should be successful
    When executing query:
      """
      USE shj_streaming_limit_graph
      MATCH (n11:N1{n1prop: 1}), (n12:N1{n1prop: 2}), (n13:N1{n1prop: 3})
      INSERT
        (n11)-[@e1{e1prop: 1112}]->(n12),
        (n11)-[@e1{e1prop: 1113}]->(n13),
        (n12)-[@e1{e1prop: 1211}]->(n11),
        (n13)-[@e1{e1prop: 1311}]->(n11)
      """
    Then the execution should be successful
    # streaming should be triggered for quantifed subpath to return early
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "var_len_to_bi_var_len=off") */
      USE shj_streaming_limit_graph {
        MATCH p = (v:N1)((x:N1)-[]->(y:N1)-[]->(z:N1)->(o:N1)){4, 32}(t1:N1)->(t2:N1)
        RETURN p
        LIMIT 10
        NEXT RETURN COUNT(p) AS total
      }
      """
    Then the result should be, in any order:
      | total |
      | 10    |
    # multiple quantified path query, both of them should trigger streaming
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "var_len_to_bi_var_len=off") */
      USE shj_streaming_limit_graph {
        MATCH p1 = (v1)->{3, 32}(v2) LIMIT 1 RETURN LENGTH(p1)
        UNION
        MATCH p1 = (v1)->{3, 32}(v2) LIMIT 1 RETURN LENGTH(p1)
      }
      """
    Then the execution should be successful
    # should no trigger streaming for unbound quantifed path query
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "var_len_to_bi_var_len=off") */
      USE shj_streaming_limit_graph {
        MATCH p1 = ACYCLIC (v1)->{0, }(v2) LIMIT 1 RETURN LENGTH(p1) AS sz
      }
      """
    Then the result should be, in any order:
      | sz |
      | 0  |
    # TODO: the query below should trigger streaming but we still need an push limit down cross join rule to make it work
    # use shj_streaming_limit_graph { match p1 = (v1)->{0, 1}(v2) return p1 limit 10 next match p2 = (v1)->{0, 1}(v2) limit 10 return p1, p2 next match p3 = (v1)->{0, 1}(v2) return p1, p2, p3 }
    And drop the graph "shj_streaming_limit_graph"
    And drop the graph type "shj_streaming_limit_type"

  @sf01
  Scenario: quantifed subpath result check
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION SET streaming_join_batches = 1024
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=off") */
      USE sf01 {
        MATCH p = (v1@Person{id: 4398046512440}) ((@Person)-[e1]->(@Person)-[e2]->(@Person)){1} (v2)
        RETURN  p limit 10000000
        NEXT
        RETURN COUNT(*) AS total
      }
      """
    Then the result should be, in any order:
      | total |
      | 238   |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=off") */
      USE sf01 {
        MATCH p = (v1@Person{id: 4398046512440}) ((@Person)-[e1]->(@Person)-[e2]->(@Person)){2} (v2)
        RETURN  p limit 10000000
        NEXT
        RETURN COUNT(*) AS total
      }
      """
    Then the result should be, in any order:
      | total |
      | 18417 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=off") */
      USE sf01 {
        MATCH p = (v1@Person{id: 4398046512440}) ((@Person)-[e1]->(@Person)-[e2]->(@Person)){3} (v2)
        RETURN  p limit 10000000
        NEXT
        RETURN COUNT(*) AS total
      }
      """
    Then the result should be, in any order:
      | total  |
      | 567266 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=on") */
      USE sf01 {
        MATCH p = (v1@Person{id: 4398046512440}) ((@Person)-[e1]->(@Person)-[e2]->(@Person)){1} (v2)
        RETURN  p limit 10000000
        NEXT
        RETURN COUNT(*) AS total
      }
      """
    Then the result should be, in any order:
      | total |
      | 238   |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=on") */
      USE sf01 {
        MATCH p = (v1@Person{id: 4398046512440}) ((@Person)-[e1]->(@Person)-[e2]->(@Person)){2} (v2)
        RETURN  p limit 10000000
        NEXT
        RETURN COUNT(*) AS total
      }
      """
    Then the result should be, in any order:
      | total |
      | 18417 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "recursive_to_streaming=on") */
      USE sf01 {
        MATCH p = (v1@Person{id: 4398046512440}) ((@Person)-[e1]->(@Person)-[e2]->(@Person)){3} (v2)
        RETURN  p limit 10000000
        NEXT
        RETURN COUNT(*) AS total
      }
      """
    Then the result should be, in any order:
      | total  |
      | 567266 |
