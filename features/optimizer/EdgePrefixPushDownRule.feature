# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: EdgePrefixPushDownRule

  Scenario: runtime edge prefix
    And create a new session with username "root" and password "NebulaGraph01"
    And use graph "ldbc"
    # edge prefix: src_id+dst_id
    When executing query:
      """
      MATCH (v:Person{id:1})-[e:KNOWS]->(v2:Person{id:1})
      RETURN e.creationDate AS d
      """
    Then the result should be, in any order:
      | d                                     |
      | DATETIME "2021-01-01T10:00:40.213000" |
    When executing query:
      """
      MATCH (v1:Person{id:1})<-[e1:HAS_CREATOR]-(m)<-[e2:LIKES]-(v2:Person)
      MATCH (v2)-[e3:KNOWS]->(v1) RETURN COUNT(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    When executing query:
      """
      TABLE t {src, dst} = (1,2),(2,4),(3,1),(3,3)
      FOR r IN t
      MATCH (src@Person) WHERE src.id = r.src
      MATCH (dst@Person) WHERE dst.id = r.dst
      MATCH (src)-[e:KNOWS|FOLLOWS]->(dst)
      RETURN src.id AS src_id, dst.id AS dst_id, type(e) AS etype
      """
    Then the result should be, in any order:
      | src_id | dst_id | etype     |
      | 1      | 2      | "FOLLOWS" |
      | 2      | 4      | "FOLLOWS" |
      | 3      | 1      | "FOLLOWS" |
      | 3      | 3      | "KNOWS"   |
    # edge prefix: src_id+dst_id+rank
    When executing query:
      """
      TABLE t {src, dst, rank} = (1,2,0),(2,4,0),(3,1,100),(3,3,0)
      FOR r IN t
      LET rank = r.rank
      MATCH (src@Person) WHERE src.id = r.src
      MATCH (dst@Person) WHERE dst.id = r.dst
      MATCH (src)-[e:KNOWS|FOLLOWS]->(dst) WHERE multiedge_id(e) = rank
      RETURN src.id AS src_id, dst.id AS dst_id, multiedge_id(e) AS rank, type(e) AS etype
      """
    Then the result should be, in any order:
      | src_id | dst_id | rank | etype     |
      | 1      | 2      | 0    | "FOLLOWS" |
      | 2      | 4      | 0    | "FOLLOWS" |
      | 3      | 3      | 0    | "KNOWS"   |
    When executing query:
      """
      TABLE t {src, dst, rank} = (1,2,0),(2,4,0),(3,1,100),(3,3,0)
      FOR r IN t
      LET rank = r.rank
      MATCH (src@Person) WHERE src.id = r.src
      MATCH (dst@Person) WHERE dst.id = r.dst
      MATCH (src)-[e:KNOWS]->(dst) WHERE multiedge_id(e) = rank
      RETURN src.id AS src_id, dst.id AS dst_id, multiedge_id(e) AS rank, type(e) AS etype
      """
    Then the result should be, in any order:
      | src_id | dst_id | rank | etype   |
      | 3      | 3      | 0    | "KNOWS" |
    # FIX: https://github.com/vesoft-inc/nebula-ng/issues/8301
    When executing query:
      """
      OPTIONAL MATCH
          (v0),
          (v0)-[]->(v3{id: 1})
      WHERE v0.id + 1 = v3.id
      RETURN v3.id
      """
    Then the execution should be successful
    # FIX: https://github.com/vesoft-inc/nebula-ng/issues/8963
    When executing query:
      """
      MATCH
          (v0)-[e0]-(v1)
      MATCH
          (v1)-[e1]->(v2{id: 3, id: multiedge_id(e0)})
      RETURN
          count(*)
      """
    Then the execution should be successful
    And close the current session
