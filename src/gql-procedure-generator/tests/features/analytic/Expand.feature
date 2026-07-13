# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Expand

  Scenario: ExpandAll
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result TYPED TABLE {src_id INT64, dst_id INT64}
        MATCH (a WHERE a.id > 2)-[e:FOLLOWS]->(b)
        PER PATH {
          EXPORT a.id, b.id INTO result
        }

        FOR r IN result
        RETURN r.src_id, r.dst_id
      }
      """
    Then the result should be, in any order:
      | r.src_id | r.dst_id |
      | 3        | 2        |
      | 3        | 1        |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result TYPED TABLE {src_id INT64, dst_id INT64}
        MATCH (a)-[e:FOLLOWS WHERE e.src < e.dst]->(b WHERE b.id <> 2)
        PER PATH {
          EXPORT a.id, b.id INTO result
        }

        FOR r IN result
        RETURN r.src_id, r.dst_id
      }
      """
    Then the result should be, in any order:
      | r.src_id | r.dst_id |
      | 2        | 4        |
      | 2        | 3        |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result TYPED TABLE {src_id INT64, dst_id INT64}
        MATCH (a)-[e:FOLLOWS WHERE e.src > 0]->(b)
        PER PATH {
          EXPORT a.id,b.id INTO result
        }

        FOR r IN result
        RETURN r.src_id, r.dst_id
      }
      """
    Then the result should be, in any order:
      | r.src_id | r.dst_id |
      | 3        | 1        |
      | 1        | 2        |
      | 3        | 2        |
      | 2        | 3        |
      | 2        | 4        |

  Scenario: multi edge types
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result TYPED TABLE {src_id INT64, dst_id INT64, type_src STRING, type_dst STRING, type_e STRING}
        MATCH (a WHERE a.id = 3)-[e@[WORK_AT, FOLLOWS, HAS_MODERATOR]]->(b)
        PER PATH {
          EXPORT a.id,b.id,type(a),type(b),type(e) INTO result
        }
        FOR r IN result
        RETURN r.src_id, r.dst_id, r.type_src, r.type_dst, r.type_e
      }
      """
    Then the result should be, in any order:
      | r.src_id | r.dst_id | r.type_src | r.type_dst     | r.type_e        |
      | 3        | 3        | "Forum"    | "Person"       | "HAS_MODERATOR" |
      | 3        | 3        | "Person"   | "Organisation" | "WORK_AT"       |
      | 3        | 1        | "Person"   | "Person"       | "FOLLOWS"       |
      | 3        | 2        | "Person"   | "Person"       | "FOLLOWS"       |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result TYPED TABLE {id INT64, ntype STRING, out_edge INT}
        NODE VALUE out_edge SumAgg<INT> = 0
        MATCH (a WHERE a.id <> 10)-[]->()
        PER PATH {
          SET a.@out_edge += 1
        }
        PER NODE (a) {
          EXPORT a.id, type(a), a.@out_edge INTO result
        }

        FOR r IN result
        RETURN r.id, r.ntype, r.out_edge
      }
      """
    Then the result should be, in any order:
      | r.id | r.ntype        | r.out_edge |
      | 2    | "Place"        | 1          |
      | 1    | "Place"        | 1          |
      | 3    | "Place"        | 1          |
      | 2    | "Forum"        | 4          |
      | 1    | "Forum"        | 4          |
      | 3    | "Forum"        | 4          |
      | 2    | "Organisation" | 1          |
      | 1    | "Organisation" | 1          |
      | 3    | "Organisation" | 1          |
      | 2    | "Comment"      | 5          |
      | 1    | "Comment"      | 5          |
      | 3    | "Comment"      | 5          |
      | 2    | "Person"       | 9          |
      | 1    | "Person"       | 8          |
      | 3    | "Person"       | 9          |
      | 2    | "Tag"          | 1          |
      | 1    | "Tag"          | 1          |
      | 3    | "Tag"          | 1          |
      | 2    | "Post"         | 3          |
      | 1    | "Post"         | 3          |
      | 3    | "Post"         | 3          |
      | 2    | "TagClass"     | 1          |
      | 1    | "TagClass"     | 1          |
      | 3    | "TagClass"     | 1          |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE result TYPED TABLE {src_id INT64, dst_id INT64, type_src STRING, type_dst STRING, type_e STRING, weight INT}
        NODE VALUE out_edge SumAgg<INT> = 0
        MATCH (a)<-[e]-(b@[Person,Comment] WHERE a.id <> 10)
        WHERE e.classYear is not null
        PER PATH {
          EXPORT a.id,b.id,type(a),type(b),type(e), e.classYear INTO result
        }

        FOR r IN result
        RETURN r.src_id, r.dst_id, r.type_src, r.type_dst, r.type_e, r.weight
      }
      """
    Then the result should be, in any order:
      | r.src_id | r.dst_id | r.type_src     | r.type_dst | r.type_e   | r.weight |
      | 2        | 2        | "Organisation" | "Person"   | "STUDY_AT" | 1        |
      | 3        | 3        | "Organisation" | "Person"   | "STUDY_AT" | 1        |
      | 1        | 1        | "Organisation" | "Person"   | "STUDY_AT" | 1        |
