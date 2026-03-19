# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: If test

  Scenario: If
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE count_person SumAgg<INT> = 0
        VALUE count_tag SumAgg<INT> = 0
        VALUE count_others SumAgg<INT> = 0
        MATCH (a)
        PER NODE (a) {
          IF type(a) = "Person" THEN {
            SET @count_person += 1
          } ELSEIF type(a) = "Tag" THEN {
            SET @count_tag += 1
          } ELSE {
            SET @count_others += 1
          }
        }
        MATCH (a)
        PER NODE (a) {
          IF type(a) = "Person" THEN {
            SET @count_person += 1
          } ELSEIF type(a) = "Tag" THEN {
            SET @count_tag += 1
          } ELSE {
            SET @count_others += 1
          }
        }
        RETURN @count_person, @count_tag, @count_others
      }
      """
    Then the result should be, in any order:
      | @count_person | @count_tag | @count_others |
      | 8             | 8          | 52            |
    When executing graph analytic query:
      """
       USE #analytic_ldbc {
        VALUE count SumAgg<INT> = 0
        VALUE if_count_0 SumAgg<INT> = 0
        VALUE if_count_1 SumAgg<INT> = 0
        VALUE if_count_2 SumAgg<INT> = 0
        VALUE if_count_3 SumAgg<INT> = 0

        MATCH (a@Person)
        PER NODE (a) {
          SET @count += 1
          IF a.id > 3 THEN {
            SET @if_count_3 += 1
          } ELSE {
            IF a.id > 2 THEN {
              SET @if_count_2 += 1
            }
            ELSE {
              IF a.id > 1 THEN {
                SET @if_count_1 += 1
              }
              ELSE {
                IF a.id > 0 THEN {
                  SET @if_count_0 += 1
                }
              }
            }
          }
        }
        RETURN @if_count_0, @if_count_1, @if_count_2, @if_count_3
      }
      """
    Then the result should be, in any order:
      | @if_count_0 | @if_count_1 | @if_count_2 | @if_count_3 |
      | 1           | 1           | 1           | 1           |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_count SumAgg<INT> = 0
        TABLE result_table TYPED TABLE {vid INT64, gender STRING, node_count INT64}
        MATCH (a@Person)
        PER NODE (a) {
          IF a.gender = "male" THEN {
            SET a.@node_count += 1
          } ELSE {
            SET a.@node_count += (-1)
          }
          IF a.id > 2 THEN {
            SET a.@node_count += a.id
          }
          ELSE {
            SET a.@node_count += (-a.id)
          }
        }
        PER NODE (a) {
          EXPORT a.id, a.gender, a.@node_count INTO result_table
        }
        FOR r IN result_table
        RETURN r.vid, r.gender, r.node_count
      }
      """
    Then the result should be, in any order:
      | r.vid | r.gender | r.node_count |
      | 3     | "male"   | 4            |
      | 2     | "male"   | -1           |
      | 4     | "female" | 3            |
      | 1     | "male"   | 0            |
