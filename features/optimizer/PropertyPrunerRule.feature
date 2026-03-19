# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: PropertyPrunerRule

  Scenario: The root plan node is not a Project or an Aggregate.
    When executing query:
      """
      USE ldbc
      MATCH (v:Person) RETURN v, v.id ORDER BY v.firstName
      """
    Then the result should be, in any order:
      | v                                                                                                                                                                                                                      | v.id |
      | ({lastName:"cao",firstName:"Kyle",browserUsed:"Chrome",gender:"male",birthday:DATE "1990-01-01",id:1,creationDate:DATETIME "2021-01-01T10:00:40.213000",locationIP:"192.168.1",vec:VECTOR [1.0, 2.0, 3.0]})            | 1    |
      | ({lastName:"Yao",firstName:"Ming",browserUsed:"Firefox",gender:"male",birthday:DATE "1995-06-12",id:3,creationDate:DATETIME "2021-01-01T12:00:40.213000",locationIP:"192.168.3",vec:VECTOR [7.0, 8.0, 9.0]})           | 3    |
      | ({lastName:"Marceau",firstName:"Sophie",browserUsed:"Chrome",gender:"female",birthday:DATE "1999-12-24",id:4,creationDate:DATETIME "2031-01-01T10:00:40.213000",locationIP:"192.168.4",vec:VECTOR [10.0, 11.0, 12.0]}) | 4    |
      | ({lastName:"Duncan",firstName:"Tim",browserUsed:"IE",gender:"male",birthday:DATE "2001-04-25",id:2,creationDate:DATETIME "2021-01-01T11:00:40.213000",locationIP:"192.168.2",vec:VECTOR [4.0, 5.0, 6.0]})              | 2    |

  Scenario: prune vector type properties
    When executing query:
      """
      /*+ SET_VAR(prune_vector_properties = false) */
      USE ldbc
      MATCH (v:Person) RETURN v, v.id ORDER BY v.firstName
      """
    Then the result should be, in any order:
      | v                                                                                                                                                                                                                      | v.id |
      | ({lastName:"cao",firstName:"Kyle",browserUsed:"Chrome",gender:"male",birthday:DATE "1990-01-01",id:1,creationDate:DATETIME "2021-01-01T10:00:40.213000",locationIP:"192.168.1",vec:VECTOR [1.0, 2.0, 3.0]})            | 1    |
      | ({lastName:"Yao",firstName:"Ming",browserUsed:"Firefox",gender:"male",birthday:DATE "1995-06-12",id:3,creationDate:DATETIME "2021-01-01T12:00:40.213000",locationIP:"192.168.3",vec:VECTOR [7.0, 8.0, 9.0]})           | 3    |
      | ({lastName:"Marceau",firstName:"Sophie",browserUsed:"Chrome",gender:"female",birthday:DATE "1999-12-24",id:4,creationDate:DATETIME "2031-01-01T10:00:40.213000",locationIP:"192.168.4",vec:VECTOR [10.0, 11.0, 12.0]}) | 4    |
      | ({lastName:"Duncan",firstName:"Tim",browserUsed:"IE",gender:"male",birthday:DATE "2001-04-25",id:2,creationDate:DATETIME "2021-01-01T11:00:40.213000",locationIP:"192.168.2",vec:VECTOR [4.0, 5.0, 6.0]})              | 2    |
    When executing query:
      """
      /*+ SET_VAR(prune_vector_properties = true) */
      USE ldbc
      MATCH (v:Person) RETURN v, v.id ORDER BY v.firstName
      """
    Then the result should be, in any order:
      | v                                                                                                                                                                                        | v.id |
      | ({lastName:"cao",firstName:"Kyle",browserUsed:"Chrome",gender:"male",birthday:DATE "1990-01-01",id:1,creationDate:DATETIME "2021-01-01T10:00:40.213000",locationIP:"192.168.1"})         | 1    |
      | ({lastName:"Yao",firstName:"Ming",browserUsed:"Firefox",gender:"male",birthday:DATE "1995-06-12",id:3,creationDate:DATETIME "2021-01-01T12:00:40.213000",locationIP:"192.168.3"})        | 3    |
      | ({lastName:"Marceau",firstName:"Sophie",browserUsed:"Chrome",gender:"female",birthday:DATE "1999-12-24",id:4,creationDate:DATETIME "2031-01-01T10:00:40.213000",locationIP:"192.168.4"}) | 4    |
      | ({lastName:"Duncan",firstName:"Tim",browserUsed:"IE",gender:"male",birthday:DATE "2001-04-25",id:2,creationDate:DATETIME "2021-01-01T11:00:40.213000",locationIP:"192.168.2"})           | 2    |
    # the vector property will not be pruned if the vector property is used in the query
    When executing query:
      """
      /*+ SET_VAR(prune_vector_properties = true) */
      USE ldbc
      MATCH (v:Person) where euclidean(v.vec, VECTOR<3,float>([4,5,6]))=0
      RETURN v, v.id
      """
    Then the result should be, in any order:
      | v                                                                                                                                                                              | v.id |
      | ({lastName:"Duncan",firstName:"Tim",browserUsed:"IE",gender:"male",birthday:DATE "2001-04-25",id:2,creationDate:DATETIME "2021-01-01T11:00:40.213000",locationIP:"192.168.2"}) | 2    |
    When executing query:
      """
      /*+ SET_VAR(prune_vector_properties = true) */
      USE ldbc
      MATCH (v:Person) where euclidean(v.vec, VECTOR<3,float>([4,5,6]))=0
      RETURN v, v.vec ORDER BY v.firstName LIMIT 3
      """
    Then the result should be, in any order:
      | v                                                                                                                                                                              | v.vec                  |
      | ({lastName:"Duncan",firstName:"Tim",browserUsed:"IE",gender:"male",birthday:DATE "2001-04-25",id:2,creationDate:DATETIME "2021-01-01T11:00:40.213000",locationIP:"192.168.2"}) | VECTOR [4.0, 5.0, 6.0] |
    When executing query:
      """
      /*+ SET_VAR(prune_vector_properties = true) */
      USE ldbc
      MATCH (v) where euclidean(v.vec, VECTOR<3,float>([4,5,6]))=0
      RETURN collect(v) AS vs GROUP BY ()
      """
    Then the result should be, in any order:
      | vs                                                                                                                                                                                    |
      | LIST [({lastName:"Duncan",firstName:"Tim",browserUsed:"IE",gender:"male",birthday:DATE "2001-04-25",id:2,creationDate:DATETIME "2021-01-01T11:00:40.213000",locationIP:"192.168.2"})] |
    When executing query:
      """
      /*+ SET_VAR(prune_vector_properties = true) */
      USE ldbc
      MATCH (v where v.id=3)->(n) where n.id=1
      RETURN [v,n] AS targetNodes
      """
    Then the result should be, in any order:
      | targetNodes                                                                                                                                                                                                                                                                                                                                                              |
      | LIST [({birthday:DATE"1995-06-12",browserUsed:"Firefox",creationDate:DATETIME "2021-01-01T12:00:40.213000",firstName:"Ming",gender:"male",id:3,lastName:"Yao",locationIP:"192.168.3"}),({birthday:DATE "1990-01-01",browserUsed:"Chrome",creationDate:DATETIME "2021-01-01T10:00:40.213000",firstName:"Kyle",gender:"male",id:1,lastName:"cao",locationIP:"192.168.1"})] |
    When executing query:
      """
      /*+ SET_VAR(prune_vector_properties = true) */
      USE ldbc
      MATCH p = (v:Person{id:2})
      RETURN p, v.vec AS vec
      """
    Then the result should be, in any order:
      | p                                                                                                                                                                                     | vec                    |
      | PATH [({lastName:"Duncan",birthday:DATE '2001-04-25',browserUsed:"IE",gender:"male",locationIP:"192.168.2",firstName:"Tim",creationDate:DATETIME '2021-01-01T11:00:40.213000',id:2})] | VECTOR [4.0, 5.0, 6.0] |
    When executing query:
      """
      /*+ SET_VAR(prune_vector_properties = true) */
      USE ldbc
      MATCH p=(v:Person)-[e:KNOWS]->()
      RETURN e, [e] AS elist
      """
    Then the result should be, in any order:
      | e                                                      | elist                                                         |
      | [{creationDate:DATETIME "2021-01-01T10:00:40.213000"}] | LIST [[{creationDate:DATETIME "2021-01-01T10:00:40.213000"}]] |
      | [{creationDate:DATETIME "2021-01-01T10:00:40.213000"}] | LIST [[{creationDate:DATETIME "2021-01-01T10:00:40.213000"}]] |
      | [{creationDate:DATETIME "2021-01-01T10:00:40.213000"}] | LIST [[{creationDate:DATETIME "2021-01-01T10:00:40.213000"}]] |

  Scenario: prune dedup properties
    When executing query:
      """
      USE ldbc
      MATCH (person:Person {id: 2})<-[:KNOWS]-(friend:Person)<-[:HAS_CREATOR]-(post:Post)-[:HAS_TAG]->(tag:Tag)
      RETURN DISTINCT tag
      NEXT
      USE ldbc
      LET id = tag.id
      RETURN id
      """
    Then the result should be, in any order:
      | id |
      | 2  |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules="property_pruner=off") */
      USE ldbc
      MATCH (person:Person {id: 2})<-[:KNOWS]-(friend:Person)<-[:HAS_CREATOR]-(post:Post)-[:HAS_TAG]->(tag:Tag)
      RETURN DISTINCT tag
      NEXT
      USE ldbc
      LET id = tag.id
      RETURN id
      """
    Then the result should be, in any order:
      | id |
      | 2  |

  Scenario: window keeps order-by property
    When executing query:
      """
      USE ldbc
      MATCH (m:City)
      LET maxCity = VALUE {
        USE ldbc MATCH (m)-[:IS_PART_OF]->(p)
        RETURN p
        ORDER BY p.id
        LIMIT 1
      }
      RETURN m.name, maxCity.name
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)-[e:KNOWS]->(b:Person)
      LET firstEdge = VALUE {
        USE ldbc MATCH (a)-[e2:KNOWS]->(b)
        RETURN e2
        ORDER BY e2.creationDate
        LIMIT 1
      }
      RETURN element_id(a), element_id(b)
      """
    Then the execution should be successful

  Scenario: more graph element function
    When executing query:
      """
      use ldbc
      match (a:Person)
      return type(a)
      """
    Then the result should be, in any order:
      | type(a)  |
      | "Person" |
      | "Person" |
      | "Person" |
      | "Person" |
    When executing query:
      """
      use ldbc
      match (a:Person)
      return labels(a)
      """
    Then the result should be, in any order:
      | labels(a)      |
      | LIST["Person"] |
      | LIST["Person"] |
      | LIST["Person"] |
      | LIST["Person"] |
    When executing query:
      """
      /*+ set_var(optimizer_rules="property_pruner=on") */
      use ldbc
      match (a:Person)
      return type(a), a.id
      """
    Then the result should be, in any order:
      | type(a)  | a.id |
      | "Person" | 4    |
      | "Person" | 2    |
      | "Person" | 3    |
      | "Person" | 1    |
