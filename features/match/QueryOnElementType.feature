# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: Query on element type

  Scenario: Node Type Predicate In Pattern
    When executing query:
      """
      USE ldbc match (v@Person) where v.id=1 return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)  |
      | 1    | "Person" |
    When executing query:
      """
      USE ldbc match (v@[Person,Tag]) where v.id=1 return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)  |
      | 1    | "Tag"    |
      | 1    | "Person" |
    When executing query:
      """
      USE ldbc match (v@!Person) where v.id=1 return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)        |
      | 1    | "TagClass"     |
      | 1    | "Comment"      |
      | 1    | "Post"         |
      | 1    | "Place"        |
      | 1    | "Tag"          |
      | 1    | "Forum"        |
      | 1    | "Organisation" |
    When executing query:
      """
      USE ldbc match (v@![Person,Tag]) where v.id=1 return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)        |
      | 1    | "Post"         |
      | 1    | "Organisation" |
      | 1    | "TagClass"     |
      | 1    | "Place"        |
      | 1    | "Forum"        |
      | 1    | "Comment"      |
    When executing query:
      """
      USE ldbc match (v:Person@Person) where v.id=1 return v.id, type(v)
      """
    Then an Error should be raised: "[42N34]: Invalid syntax, label expression and type expression cannot coexist in single Node pattern `(v:Person@Person)`"

  Scenario: Edge Type Predicate In Pattern
    When executing query:
      """
      USE ldbc match (src:Person)-[e@KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    When executing query:
      """
      USE ldbc match (src:Person)-[e@[KNOWS,WORK_AT]]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)   | type(dst)      |
      | "Person"  | "WORK_AT" | "Organisation" |
      | "Person"  | "KNOWS"   | "Person"       |
    When executing query:
      """
      USE ldbc match (src:Person)-[e@!KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)           | type(dst)      |
      | "Person"  | "FOLLOWS"         | "Person"       |
      | "Person"  | "HAS_INTEREST"    | "Tag"          |
      | "Person"  | "STUDY_AT"        | "Organisation" |
      | "Person"  | "WORK_AT"         | "Organisation" |
      | "Person"  | "LIKES_1"         | "Post"         |
      | "Person"  | "LIKES_2"         | "Comment"      |
      | "Person"  | "IS_LOCATED_IN_1" | "Place"        |
    When executing query:
      """
      USE ldbc match (src:Person)-[e@![KNOWS,WORK_AT]]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)           | type(dst)      |
      | "Person"  | "FOLLOWS"         | "Person"       |
      | "Person"  | "LIKES_2"         | "Comment"      |
      | "Person"  | "STUDY_AT"        | "Organisation" |
      | "Person"  | "LIKES_1"         | "Post"         |
      | "Person"  | "IS_LOCATED_IN_1" | "Place"        |
      | "Person"  | "HAS_INTEREST"    | "Tag"          |
    When executing query:
      """
      USE ldbc match (src:Person)-[e:KNOWS@KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then an Error should be raised: "[42N34]: Invalid syntax, label expression and type expression cannot coexist in single Edge pattern `-[e:KNOWS@KNOWS]->`"

  Scenario: Mixed Node Edge Type Predicate In Pattern
    When executing query:
      """
      USE ldbc match (src@Person)-[e@KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    When executing query:
      """
      USE ldbc match (src@Person)-[e:KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    When executing query:
      """
      USE ldbc match (src:Person)-[e@KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |

  Scenario: Node Typed In Predicate In Filter
    When executing query:
      """
      USE ldbc MATCH (v) WHERE v.id=1 AND v IS ELEMENT TYPED Person RETURN v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)  |
      | 1    | "Person" |
    When executing query:
      """
      USE ldbc match (v) where v.id=1 AND v IS ELEMENT TYPED [Person,Tag] return v.id, type(v), v IS ELEMENT TYPED Person AS is_person
      """
    Then the result should be, in any order:
      | v.id | type(v)  | is_person |
      | 1    | "Tag"    | false     |
      | 1    | "Person" | true      |
    When executing query:
      """
      USE ldbc match (v) where v.id=1 AND v IS ELEMENT TYPED !Person return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)        |
      | 1    | "TagClass"     |
      | 1    | "Comment"      |
      | 1    | "Post"         |
      | 1    | "Place"        |
      | 1    | "Tag"          |
      | 1    | "Forum"        |
      | 1    | "Organisation" |
    When executing query:
      """
      USE ldbc match (v) where v.id=1 AND v IS NOT ELEMENT TYPED Person return v.id, type(v), v @!Person as is_not_person
      """
    Then the result should be, in any order:
      | v.id | type(v)        | is_not_person |
      | 1    | "Place"        | true          |
      | 1    | "Tag"          | true          |
      | 1    | "Post"         | true          |
      | 1    | "Comment"      | true          |
      | 1    | "Organisation" | true          |
      | 1    | "Forum"        | true          |
      | 1    | "TagClass"     | true          |
    When executing query:
      """
      USE ldbc match (v) where v.id=1 AND v IS NOT ELEMENT TYPED !Person return v.id, type(v), v IS NOT ELEMENT TYPED Person as is_not_person
      """
    Then the result should be, in any order:
      | v.id | type(v)  | is_not_person |
      | 1    | "Person" | false         |
    When executing query:
      """
      USE ldbc match (v) where v.id=1 AND v@![Person,Tag] return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)        |
      | 1    | "Post"         |
      | 1    | "Organisation" |
      | 1    | "TagClass"     |
      | 1    | "Place"        |
      | 1    | "Forum"        |
      | 1    | "Comment"      |
    When executing query:
      """
      USE ldbc LET v=1 FILTER WHERE v IS ELEMENT TYPED Person RETURN v
      """
    Then an Error should be raised: "[NS211]: Invalid type expression input: `v`, expect NODE or EDGE type but got `INT32`"

  Scenario: Edge Typed In Predicate In Filter
    When executing query:
      """
      USE ldbc match (src:Person)-[e]->(dst) where src.id=1 AND e IS ELEMENT TYPED KNOWS return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    When executing query:
      """
      USE ldbc match (src:Person)-[e]->(dst) where src.id=1 AND e @KNOWS return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    When executing query:
      """
      USE ldbc match (src:Person)-[e]->(dst) where src.id=1 AND e @[KNOWS,WORK_AT] return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)   | type(dst)      |
      | "Person"  | "WORK_AT" | "Organisation" |
      | "Person"  | "KNOWS"   | "Person"       |
    When executing query:
      """
      USE ldbc match (src:Person)-[e]->(dst) where src.id=1 AND e @!KNOWS return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)           | type(dst)      |
      | "Person"  | "FOLLOWS"         | "Person"       |
      | "Person"  | "HAS_INTEREST"    | "Tag"          |
      | "Person"  | "STUDY_AT"        | "Organisation" |
      | "Person"  | "WORK_AT"         | "Organisation" |
      | "Person"  | "LIKES_1"         | "Post"         |
      | "Person"  | "LIKES_2"         | "Comment"      |
      | "Person"  | "IS_LOCATED_IN_1" | "Place"        |
    When executing query:
      """
      USE ldbc match (src:Person)-[e]->(dst) where src.id=1 AND e@![KNOWS,WORK_AT] return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)           | type(dst)      |
      | "Person"  | "FOLLOWS"         | "Person"       |
      | "Person"  | "LIKES_2"         | "Comment"      |
      | "Person"  | "STUDY_AT"        | "Organisation" |
      | "Person"  | "LIKES_1"         | "Post"         |
      | "Person"  | "IS_LOCATED_IN_1" | "Place"        |
      | "Person"  | "HAS_INTEREST"    | "Tag"          |
