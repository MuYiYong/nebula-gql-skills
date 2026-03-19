# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: EliminateCrossJoinByReorderRule

  Scenario: EliminateCrossJoinByReorderRule
    When executing query:
      """
      TABLE t {person_id, tag_id, post_id} =
      (1,2,3),
      (2,3,4),
      (3,2,1)
      USE ldbc
      FOR r IN t
      MATCH (a@Person),(b@Tag),(c@Post)
      WHERE a.id = r.person_id
      and b.id = r.tag_id
      and c.id = r.post_id
      RETURN a.id, b.id, c.id
      """
    Then the result should be, in any order:
      | a.id | b.id | c.id |
      | 2    | 3    | 4    |
      | 3    | 2    | 1    |
      | 1    | 2    | 3    |
    When executing query:
      """
      TABLE t {person_id, tag_id, post_id, test_id_1,test_id_2,test_id_3} =
      (1,2,3,0,2,1),
      (2,3,2,1,1,1),
      (2,2,1,2,0,1)
      USE ldbc
      FOR r IN t
      MATCH (a@Person),(b@Tag),(c@Post)
      WHERE a.id = r.person_id + r.test_id_1
      and b.id = r.tag_id + r.test_id_2
      and c.id = r.post_id + r.test_id_3
      RETURN a.id, b.id, c.id
      """
    Then the result should be, in any order:
      | a.id | b.id | c.id |
      | 4    | 2    | 2    |
      | 1    | 4    | 4    |
      | 3    | 4    | 3    |
    When executing query:
      """
      TABLE t {person_id, tag_id, post_id, mask} =
      (1,2,3,0),
      (2,3,4,1),
      (3,2,1,1)
      USE ldbc
      FOR r IN t
      MATCH (a@Person),(b@Tag),(c@Post)
      WHERE a.id = r.person_id
      and b.id = r.tag_id
      and c.id = r.post_id
      and a.id = r.person_id + r.mask
      RETURN a.id, b.id, c.id
      """
    Then the result should be, in any order:
      | a.id | b.id | c.id |
      | 1    | 2    | 3    |
