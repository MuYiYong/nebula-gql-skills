# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: IndexOrderSatisfiesTopNRule

  Scenario: Query-to-note TopN with split outbound edge types
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS topn_idx_edge_gt AS {
        NODE SearchQuery (LABEL SEARCH_QUERY {id INT PRIMARY KEY}),
        NODE Note (LABEL NOTE {id INT PRIMARY KEY}),
        EDGE QueryClickNote (SearchQuery)-[LABEL QUERY_CLICK_NOTE {src_id INT, score INT, level INT}]->(Note),
        EDGE QueryInfluencedByNote (SearchQuery)-[LABEL QUERY_INFLUENCED_BY_NOTE {src_id INT, score INT, level INT}]->(Note)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS topn_idx_edge_graph topn_idx_edge_gt
      """
    Then the execution should be successful
    And graph "topn_idx_edge_graph" should be ready to use
    And use graph "topn_idx_edge_graph"
    When executing query:
      """
      CREATE INDEX IF NOT EXISTS idx_qcn_vc ON EDGE QueryClickNote(_src, score ASC, level ASC)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE INDEX IF NOT EXISTS idx_qin_vc ON EDGE QueryInfluencedByNote(_src, score ASC, level ASC)
      """
    Then the execution should be successful
    And index "idx_qcn_vc" of "topn_idx_edge_graph" should be ready to use
    And index "idx_qin_vc" of "topn_idx_edge_graph" should be ready to use
    When executing query:
      """
      USE topn_idx_edge_graph
      INSERT
        (q1@SearchQuery{id:1}),
        (q2@SearchQuery{id:2}),
        (n1@Note{id:101}),
        (n2@Note{id:102}),
        (n3@Note{id:103}),
        (n4@Note{id:104}),
        (q1)-[@QueryClickNote{src_id:1, score:18, level:1}]->(n3),
        (q2)-[@QueryInfluencedByNote{src_id:2, score:16, level:2}]->(n3),
        (q1)-[@QueryInfluencedByNote{src_id:1, score:20, level:2}]->(n2),
        (q1)-[@QueryClickNote{src_id:1, score:10, level:1}]->(n1),
        (q1)-[@QueryInfluencedByNote{src_id:1, score:25, level:3}]->(n4),
        (q2)-[@QueryClickNote{src_id:2, score:12, level:1}]->(n2),
        (q1)-[@QueryClickNote{src_id:1, score:28, level:3}]->(n2),
        (q1)-[@QueryInfluencedByNote{src_id:1, score:15, level:1}]->(n1),
        (q1)-[@QueryClickNote{src_id:1, score:22, level:2}]->(n4),
        (q1)-[@QueryInfluencedByNote{src_id:1, score:32, level:4}]->(n3),
        (q2)-[@QueryClickNote{src_id:2, score:30, level:1}]->(n4),
        (q2)-[@QueryInfluencedByNote{src_id:2, score:35, level:3}]->(n1)
      """
    Then the execution should be successful
    When executing query:
      """
      USE topn_idx_edge_graph
      MATCH (q:SEARCH_QUERY{id:1})-[e:QUERY_CLICK_NOTE|QUERY_INFLUENCED_BY_NOTE]->(n)
      ORDER BY e.score, e.level
      LIMIT 2
      RETURN e.src_id AS srcId, e.score AS score, e.level AS level, n.id AS noteId
      """
    Then the result should be, in order:
      | srcId | score | level | noteId |
      | 1     | 10    | 1     | 101    |
      | 1     | 15    | 1     | 101    |
    When executing query:
      """
      USE topn_idx_edge_graph
      MATCH (q:SEARCH_QUERY{id:1})-[e:QUERY_CLICK_NOTE|QUERY_INFLUENCED_BY_NOTE]->(n)
      WHERE e.level >= 2
      ORDER BY e.score, e.level
      LIMIT 2
      RETURN e.src_id AS srcId, e.score AS score, e.level AS level, n.id AS noteId
      """
    Then the result should be, in order:
      | srcId | score | level | noteId |
      | 1     | 20    | 2     | 102    |
      | 1     | 22    | 2     | 104    |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "index_order_satisfies_topn=off") */
      USE topn_idx_edge_graph
      MATCH (q:SEARCH_QUERY{id:1})-[e:QUERY_CLICK_NOTE|QUERY_INFLUENCED_BY_NOTE]->(n)
      ORDER BY e.score, e.level
      LIMIT 2
      RETURN e.src_id AS srcId, e.score AS score, e.level AS level, n.id AS noteId
      """
    Then the result should be, in order:
      | srcId | score | level | noteId |
      | 1     | 10    | 1     | 101    |
      | 1     | 15    | 1     | 101    |
    And drop the index "idx_qcn_vc" of "topn_idx_edge_graph"
    And drop the index "idx_qin_vc" of "topn_idx_edge_graph"
    And drop the graph "topn_idx_edge_graph"
    And drop the graph type "topn_idx_edge_gt"
