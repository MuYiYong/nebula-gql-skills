# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: ldbc acid

  Scenario: ldbc acid atomicity
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ldbc_acid_atomic_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, name STRING, emails LIST<STRING>}),
        NODE Post (LABEL Post {id INT PRIMARY KEY}),
        EDGE KNOWS (Person)-[LABEL KNOWS {since INT}]->(Person),
        EDGE LIKES (Person)-[LABEL LIKES {since INT}]->(Post)
      }
      """
    Then the execution should be successful
    And graph type "ldbc_acid_atomic_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ldbc_acid_atomic TYPED ldbc_acid_atomic_type
      """
    Then the execution should be successful
    And graph "ldbc_acid_atomic" should be ready to use
    # 1.1 atomicityInit
    When executing query:
      """
      START TRANSACTION
      USE ldbc_acid_atomic INSERT (:Person{id: 1, name: "Alice", emails: LIST["alice@aol.com"]}),
                           (:Person{id: 2, name: "Bob", emails: LIST["bob@hotmail.com","bobby@yahoo.com"]})
      COMMIT
      """
    Then the execution should be successful
    # 1.2 atomicityC
    When executing query:
      """
      START TRANSACTION
      USE ldbc_acid_atomic
      MATCH (p:Person{id: 1})
      INSERT OR UPDATE (p1:Person{id: 1, emails: p.emails || LIST["alice@otherdomain.net"]})-[k:KNOWS{since: 2020}]->(p2:Person{id: 3})
      COMMIT
      """
    Then the execution should be successful
    # 1.3 atomicityRB: not supportted yet
    When executing query:
      """
      START TRANSACTION
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_acid_atomic
      MATCH (p1:Person{id: 1}) SET p1.emails = p1.emails || LIST["alice@otherdomain.net"]
      """
    Then the execution should be successful
    # todo(doodle): According to paper, if p2 exists we need to abort in java test case, else we need to create p2.
    # instead, we could use INSERT OR IGNORE
    When executing query:
      """
      USE ldbc_acid_atomic
      INSERT OR IGNORE (:Person{id: 2, emails: []})
      """
    Then the execution should be successful
    When executing query:
      """
      COMMIT
      """
    Then the execution should be successful
    # 1.4 atomicityCheck
    When executing query:
      """
      START TRANSACTION
      USE ldbc_acid_atomic
      MATCH (p:Person)
      RETURN count(p) AS numPersons, count(p.name) AS numNames, sum(size(p.emails)) AS numEmails GROUP BY ()
      COMMIT
      """
    Then the execution should be successful
    And drop the graph "ldbc_acid_atomic"
    And drop the graph type "ldbc_acid_atomic_type"

  Scenario: ldbc acid g0
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ldbc_acid_g0_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, versionHistory LIST<INT>}),
        EDGE KNOWS (Person)-[LABEL KNOWS {versionHistory LIST<INT>}]->(Person)
      }
      """
    Then the execution should be successful
    And graph type "ldbc_acid_g0_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ldbc_acid_g0 TYPED ldbc_acid_g0_type
      """
    Then the execution should be successful
    And graph "ldbc_acid_g0" should be ready to use
    # g0Init
    When executing query:
      """
      START TRANSACTION
      USE ldbc_acid_g0
      INSERT OR UPDATE (p1:Person{id: 1, versionHistory: LIST[0]})-[k:KNOWS{versionHistory: LIST[0]}]->(p2:Person{id: 2, versionHistory: LIST[0]})
      COMMIT
      """
    Then the execution should be successful
    # 1.5 g0 (the `123` is a txn id passed from test case)
    When executing query:
      """
      START TRANSACTION
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_acid_g0
      MATCH (p1:Person{id: 1})-[k:KNOWS]->(p2:Person{id: 2})
      SET p1.versionHistory = p1.versionHistory || [123]
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_acid_g0
      MATCH (p1:Person{id: 1})-[k:KNOWS]->(p2:Person{id: 2})
      SET p2.versionHistory = p2.versionHistory || [123]
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_acid_g0
      MATCH (p1:Person{id: 1})-[k:KNOWS]->(p2:Person{id: 2})
      SET k.versionHistory = k.versionHistory || [123]
      """
    Then the execution should be successful
    When executing query:
      """
      COMMIT
      """
    Then the execution should be successful
    # 1.6 g0check
    When executing query:
      """
      START TRANSACTION
      USE ldbc_acid_g0
      MATCH (p1:Person{id: 1})-[k:KNOWS]->(p2:Person{id: 2})
      RETURN p1.versionHistory AS p1VersionHistory,
             k.versionHistory AS kVersionHistory,
             p2.versionHistory AS p2VersionHistory
      COMMIT
      """
    Then the execution should be successful
    And drop the graph "ldbc_acid_g0"
    And drop the graph type "ldbc_acid_g0_type"

  Scenario: ldbc acid g1
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ldbc_acid_g1_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, version INT}),
        EDGE KNOWS (Person)-[LABEL KNOWS {}]->(Person)
      }
      """
    Then the execution should be successful
    And graph type "ldbc_acid_g1_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ldbc_acid_g1 TYPED ldbc_acid_g1_type
      """
    Then the execution should be successful
    And graph "ldbc_acid_g1" should be ready to use
    # g1aInit
    When executing query:
      """
      START TRANSACTION
      USE ldbc_acid_g1
      INSERT (:Person{id: 1, version: 1})
      COMMIT
      """
    Then the execution should be successful
    # 1.7 g1aW
    When executing query:
      """
      START TRANSACTION
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_acid_g1
      MATCH (p:Person {id:1}) SET p.version = 2
      """
    Then the execution should be successful
    # We need to sleep in java test code later
    And wait "1" seconds
    When executing query:
      """
      ROLLBACK
      """
    Then the execution should be successful
    # 1.8 g1aR
    When executing query:
      """
      START TRANSACTION
      USE ldbc_acid_g1
      MATCH (p:Person {id:1})
      RETURN p.version AS pVersion
      COMMIT
      """
    Then the execution should be successful
    # g1bInit
    When executing query:
      """
      START TRANSACTION
      USE ldbc_acid_g1
      INSERT (:Person{id: 2, version: 99})
      COMMIT
      """
    Then the execution should be successful
    # 1.9 g1bW
    When executing query:
      """
      START TRANSACTION
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_acid_g1
      MATCH (p:Person {id:2}) SET p.version = 0
      """
    Then the execution should be successful
    # We need to sleep in java test code later
    And wait "1" seconds
    When executing query:
      """
      USE ldbc_acid_g1
      MATCH (p:Person {id:2}) SET p.version = 1
      """
    Then the execution should be successful
    When executing query:
      """
      COMMIT
      """
    Then the execution should be successful
    # 1.10 g1bR
    When executing query:
      """
      START TRANSACTION
      USE ldbc_acid_g1
      MATCH (p:Person {id:2})
      RETURN p.version AS pVersion
      COMMIT
      """
    Then the execution should be successful
    # g1cInit
    When executing query:
      """
      START TRANSACTION
      USE ldbc_acid_g1
      INSERT (:Person{id: 3, version: 0}), (:Person{id: 4, version: 0})
      COMMIT
      """
    Then the execution should be successful
    # 1.11 g1c (the `123` is a txn id passed from test case)
    # Txn1 write Person 3 and read Person 4
    When executing query:
      """
      START TRANSACTION
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_acid_g1
      MATCH (p1:Person{id: 3}) SET p1.version = 123
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_acid_g1
      MATCH (p2:Person{id: 4})
      RETURN p2.version AS person2Version
      """
    Then the execution should be successful
    When executing query:
      """
      COMMIT
      """
    Then the execution should be successful
    # Txn2 write Person 4 and read Person 3
    When executing query:
      """
      START TRANSACTION
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_acid_g1
      MATCH (p1:Person{id: 4}) SET p1.version = 123
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_acid_g1
      MATCH (p2:Person{id: 3})
      RETURN p2.version AS person2Version
      """
    Then the execution should be successful
    When executing query:
      """
      COMMIT
      """
    Then the execution should be successful
    And drop the graph "ldbc_acid_g1"
    And drop the graph type "ldbc_acid_g1_type"
