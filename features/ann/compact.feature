# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: ANN compaction

  Scenario: test compact filter of vector index kvs
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_vector_gt AS {
        NODE person({id int primary key, vec vector<10,float> NOT NULL}),
        EDGE knows (person)-[{vec vector<10,float> NOT NULL}]->(person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_vector_g test_vector_gt
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_vector_g CREATE VECTOR INDEX IF NOT EXISTS idx_1  on edge `knows`::vec OPTIONS {dim: 10}
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_vector_g FOR i in range (1,10000) INSERT (a@person{id:i, vec:vector(1,2,3,4,5,6,7,8,9,10)})-[@knows{vec:vector(1,2,3,4,5,6,7,8,9,10)}]->(a)
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_vector_g
      MATCH (s)-[e]->(d)
      ORDER BY euclidean(e.vec,vector<10,float>([11,22,33,44,55,66,77,88, 99,1010])) APPROX LIMIT 10000 OPTIONS {TYPE: IVF}
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt   |
      | 10000 |
    When executing query:
      """
      submit job compact
      """
    Then the execution should be successful
    And wait "2" seconds
    When executing query:
      """
      USE test_vector_g
      MATCH (s)-[e]->(d)
      ORDER BY euclidean(e.vec,vector<10,float>([11,22,33,44,55,66,77,88, 99,1010])) APPROX LIMIT 10000 OPTIONS {TYPE: IVF}
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt   |
      | 10000 |
    And drop the index "idx1" of "test_vector_g"
    And drop the graph "test_vector_g"
    And drop the graph type "test_vector_gt"
