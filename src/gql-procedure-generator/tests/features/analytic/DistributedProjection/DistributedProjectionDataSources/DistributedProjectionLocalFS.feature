# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Distributed Graph Projection - Local File System

  Scenario: Load distributed temporary graph from external data source
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gen_graph_type AS {
        NODE TYPE person (LABEL person {id INT PRIMARY KEY}),
        NODE TYPE place  (LABEL place  {id INT PRIMARY KEY}),
        NODE TYPE item   (LABEL item   {id INT PRIMARY KEY}),
        EDGE TYPE follow (person)-[LABEL follow {MULTIEDGE KEY()}]->(person),
        EDGE TYPE likes  (person)-[LABEL likes {MULTIEDGE KEY()}]->(person),
        EDGE TYPE livein (person)-[LABEL livein {MULTIEDGE KEY()}]->(place)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_projection_gen TYPED gen_graph_type
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_projection_gen TYPED gen_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #graph_projection_gen {
          VALUE person_cnt SumAgg<INT> = 0
          VALUE place_cnt  SumAgg<INT> = 0
          VALUE likes_cnt  SumAgg<INT> = 0
          VALUE livein_cnt SumAgg<INT> = 0
          VALUE item_cnt   SumAgg<INT> = 0
      	MATCH(v:person)
      	PER NODE (v){
      	  SET @person_cnt += 1
      	}
      	MATCH(v:place)
      	PER NODE (v){
      	  SET @place_cnt += 1
      	}
      	MATCH()-[e:likes]->()
      	PER PATH {
      	  SET @likes_cnt += 1
      	}
      	MATCH()-[e:livein]->()
      	PER PATH {
      	  SET @livein_cnt += 1
      	}
      	MATCH(v:item)
      	PER NODE (v){
      	  SET @item_cnt += 1
      	}
      	RETURN @person_cnt, @place_cnt, @likes_cnt, @livein_cnt, @item_cnt
      }
      """
    Then the result should be, in any order:
      | @person_cnt | @place_cnt | @likes_cnt | @livein_cnt | @item_cnt |
      | 0           | 0          | 0          | 0           | 0         |
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #graph_projection_gen IMPORT INTO GRAPH {
       GRAPH FROM gen_graph("person:1000, place:10, follow:1000, likes:500, livein:1000, item:99")
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #graph_projection_gen {
          VALUE person_cnt SumAgg<INT> = 0
          VALUE place_cnt  SumAgg<INT> = 0
          VALUE likes_cnt  SumAgg<INT> = 0
          VALUE livein_cnt SumAgg<INT> = 0
          VALUE item_cnt   SumAgg<INT> = 0
      	MATCH(v:person)
      	PER NODE (v){
      	  SET @person_cnt += 1
      	}
      	MATCH(v:place)
      	PER NODE (v){
      	  SET @place_cnt += 1
      	}
      	MATCH()-[e:likes]->()
      	PER PATH {
      	  SET @likes_cnt += 1
      	}
      	MATCH()-[e:livein]->()
      	PER PATH {
      	  SET @livein_cnt += 1
      	}
      	MATCH(v:item)
      	PER NODE (v){
      	  SET @item_cnt += 1
      	}
      	RETURN @person_cnt, @place_cnt, @likes_cnt, @livein_cnt, @item_cnt
      }
      """
    Then the result should be, in any order:
      | @person_cnt | @place_cnt | @likes_cnt | @livein_cnt | @item_cnt |
      | 1000        | 10         | 500        | 1000        | 99        |
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_projection_gen TYPED gen_graph_type PARTITION BY HAHA
      """
    Then an Error should be raised: "[AN101]: Analytic error, invalid partition method: HAHA"
    When executing graph analytic query:
      """
      DROP GRAPH #graph_projection_gen
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      DROP GRAPH TYPE IF EXISTS gen_graph_type
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dist_graph_type AS {
      NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
      EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv TYPED dist_graph_type PARTITION BY DEFAULT
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: PARTITION BY is not supported when create temporary graph in graphd service"
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv TYPED dist_graph_type
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: PARTITION BY is needed when create temporary graph in analyticd service"
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv TYPED dist_graph_type PARTITION BY DEFAULT OPTIONS {immutable:false}
      """
    Then an Error should be raised: "[NR127]: Create temporary graph failed: mutable distributed temporary graph not supported"
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv TYPED dist_graph_type
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_immutable TYPED dist_graph_type OPTIONS {immutable:true}
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv TYPED dist_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:   "file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
      }
      USE #dist_graph_csv IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:x.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:n.dst_id) FROM ef
      }
      """
    Then an Error should be raised: "Variable `x` is not found in the source"
    When executing graph analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:   "file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
      }
      USE #dist_graph_csv IMPORT INTO GRAPH
      {
        NODE (v@player{id:nfile.id, name:nfile.name}) FROM nfile,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:n.dst_id) FROM ef
      }
      """
    Then an Error should be raised: "[NS001]: Semantic error, undefined variable: `nfile`"
    When executing graph analytic query:
      """
      FILE nf {idx INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:   "file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
      }
      USE #dist_graph_csv IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:n.dst_id) FROM ef
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Column `id` not found in `nf`"
    When executing graph analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/empty_graph_csv_comma/empty_graph_csv_comma.v"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:   "file://${TEST_DIR}/dataset/external_source/empty_graph_csv_comma/empty_graph_csv_comma.e"
      }
      USE #dist_graph_csv IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:n.dst_id) FROM ef
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_graph_csv SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
    When executing graph analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v",
          skip_rows: 0,
          skip_rows_after_names: 0,
          autogenerate_column_names: false,
          delimiter: ",",
          quoting: true,
          quote_char: '\"',
          double_quote: true,
          escaping: false,
          escape_char: '*',
          newlines_in_values: false,
          ignore_empty_lines: true,
          check_utf8: true,
          null_values: ["NULL"],
          true_values: ["true"],
          false_values: ["false"],
          strings_can_be_null: false,
          quoted_strings_can_be_null: true,
          include_columns: ["id","name"],
          include_missing_columns: false
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:   "file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
      }
      USE #dist_graph_csv IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:n.dst_id) FROM ef
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT: "csv",
          PATH:   "file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:   "file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
      }
      USE #dist_graph_csv IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:n.dst_id) FROM ef
      }
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: Import to non-empty graph"
    When executing graph analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT: "csv",
          PATH:   "file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:   "file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
      }
      USE #dist_graph_csv IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:n.dst_id) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:false}
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: Import to non-empty graph"
    When executing graph query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT: "csv",
          PATH:   "file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:   "file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
      }
      USE #dist_graph_csv_immutable IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:n.dst_id) FROM ef
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_wrong_delimiter TYPED dist_graph_type
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_wrong_delimiter TYPED dist_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 2) */
      USE #dist_graph_csv_wrong_delimiter IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v",
          delimiter: " ",
          include_columns: ["id","name"]
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
        }
      }
      """
    Then an Error should be raised: "error: Key error: Column 'id' in include_columns does not exist in CSV file"
    # test block size
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 2) */
      USE #dist_graph_csv_wrong_delimiter IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE{
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v",
          block_size: 268435456,
          delimiter: " "
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
        }
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: block_size 268435456 is too large, the max size is 134217728(128MB)"
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_space TYPED dist_graph_type
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_space TYPED dist_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_space IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.v",
          delimiter: " "
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.e",
          delimiter: " "
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                    | graph_type        | schema        | owner  | extra               |
      | "#dist_graph_csv_space" | "dist_graph_type" | "/tmp_schema" | "root" | "distributed:false" |
    When executing graph analytic query:
      """
      DROP GRAPH #dist_graph_csv_space
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_orc TYPED dist_graph_type
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_orc TYPED dist_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_orc IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"orc",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_orc/mini_graph_orc.v"
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"orc",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_orc/mini_graph_orc.e"
        }
      }
      """
    Then the execution should be successful
    And drop the graph "#dist_graph_csv"
    And drop the graph "#dist_graph_csv_immutable"
    And drop the graph "#dist_graph_csv_wrong_delimiter"
    And drop the graph "#dist_graph_csv_space"
    And drop the graph "#dist_graph_orc"
    And drop the graph type "dist_graph_type"

  Scenario: Load temporary graph from twitter csv file
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS twitter_type AS {
        NODE TYPE user (LABEL user {id INT PRIMARY KEY, twitter_id INT}),
        EDGE TYPE follow (user)-[LABEL follow {MULTIEDGE KEY()}]->(user)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #twitter_temp TYPED twitter_type
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #twitter_temp TYPED twitter_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #twitter_temp IMPORT INTO GRAPH
      {
        NODE (v@user{id:node_id, twitter_id:twitter_id}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_twitter_csv/mini_twitter_csv.v"
        },
        EDGE (id:src)-[e@follow{}]->(id:dst) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_twitter_csv/mini_twitter_csv.e",
          column_names: ["src","dst"],
          delimiter: " "
        }
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #twitter_temp SHOW VERBOSE STATS
      """
    Then the result should be, in any order:
      | entry_name          | element_type | total_num | partitioned_num                                                 |
      | "Node Total"        | "Node"       | 9         | ""                                                              |
      | "Edge Total"        | "Edge"       | 7         | ""                                                              |
      | "Node Local Total"  | "Node"       | 14        | /127\.0\.0\.1:\d+: 3, 127\.0\.0\.1:\d+: 4, 127\.0\.0\.1:\d+: 7/ |
      | "Node Local Master" | "Node"       | 9         | /127\.0\.0\.1:\d+: 3, 127\.0\.0\.1:\d+: 2, 127\.0\.0\.1:\d+: 4/ |
      | "Node Local Mirror" | "Node"       | 5         | /127\.0\.0\.1:\d+: 0, 127\.0\.0\.1:\d+: 2, 127\.0\.0\.1:\d+: 3/ |
      | "Edge Local Total"  | "Edge"       | 7         | /127\.0\.0\.1:\d+: 0, 127\.0\.0\.1:\d+: 2, 127\.0\.0\.1:\d+: 5/ |
    And drop the graph "#twitter_temp"
    And drop the graph type "twitter_type"

  Scenario: Load graph from parquet file
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dist_graph_type_parquet AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    # local file]
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_parquet_2d TYPED dist_graph_type_parquet
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_parquet_2d TYPED dist_graph_type_parquet PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_parquet_2d IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"parquet",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_parquet/mini_graph_parquet.v"
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"parquet",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_parquet/mini_graph_parquet.e"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      DROP GRAPH #dist_graph_parquet_2d
      """
    Then the execution should be successful
    # with all parquet read options
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_parquet_all_options TYPED dist_graph_type_parquet
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_parquet_all_options TYPED dist_graph_type_parquet PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_parquet_all_options IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"parquet",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_parquet/mini_graph_parquet.v",
          buffer_size: 1048576,
          thrift_string_size_limit: 1000000,
          thrift_container_size_limit: 1000000,
          buffered_stream_enabled: true,
          page_checksum_verification: false,
          read_dense_for_nullable: true,
          use_threads: true,
          batch_size: 65536,
          pre_buffer: false
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"parquet",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_parquet/mini_graph_parquet.e",
          buffer_size: 1048576,
          thrift_string_size_limit: 1000000,
          thrift_container_size_limit: 1000000,
          buffered_stream_enabled: true,
          page_checksum_verification: false,
          read_dense_for_nullable: true,
          use_threads: true,
          batch_size: 65536,
          pre_buffer: false
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      DROP GRAPH #dist_graph_parquet_all_options
      """
    Then the execution should be successful
    And drop the graph type "dist_graph_type_parquet"

  Scenario: Load from csv directory
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS load_from_csv_directory_gt {
        NODE TYPE node_type ({id INT PRIMARY KEY, score DOUBLE}),
        EDGE TYPE edge_type (node_type)-[{weight INT,MULTIEDGE KEY()}]->(node_type)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMP GRAPH IF NOT EXISTS #load_from_csv_dir TYPED load_from_csv_directory_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+SET_VAR(query_concurrency = 4) */
      USE #load_from_csv_dir IMPORT INTO GRAPH
      {
            NODE (v@node_type{id:f0, score:f1}) FROM DATAFILE {
              FORMAT:"csv",
              PATH:"file://${TEST_DIR}/dataset/external_source/csv_source/node",
              autogenerate_column_names: true,
              delimiter: " "
            },
            EDGE (id:f0)-[e@edge_type{weight:f2}]->(id:f1) FROM DATAFILE {
              FORMAT:"csv",
              PATH:"file://${TEST_DIR}/dataset/external_source/csv_source/edge",
              autogenerate_column_names: true,
              delimiter: " "
            }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #load_from_csv_dir {
          TABLE result_table TYPED TABLE {id INT, score DOUBLE, out_edge INT}
          NODE VALUE out_edge SumAgg<INT> = 0
          MATCH (a)-[]->(b)
          PER PATH {
            SET a.@out_edge += 1
          }
          MATCH (a)
          PER NODE (a) {
            EXPORT a.id, a.score, a.@out_edge INTO result_table
          }
          FOR r IN result_table
          RETURN r.id, r.score, r.out_edge
      }
      """
    Then the result should be, in any order:
      | r.id | r.score | r.out_edge |
      | 5    | 5.0     | 0          |
      | 6    | 6.0     | 1          |
      | 7    | 7.0     | 1          |
      | 8    | 8.0     | 1          |
      | 9    | 9.0     | 0          |
      | 10   | 10.0    | 0          |
      | 0    | 0.0     | 3          |
      | 1    | 1.0     | 2          |
      | 2    | 2.0     | 4          |
      | 3    | 3.0     | 1          |
      | 4    | 4.0     | 1          |
      | 11   | 11.0    | 0          |
    When executing analytic query:
      """
      USE #load_from_csv_dir {
        TABLE result_table TYPED TABLE {src INT, dst INT, weight INT}
        MATCH (a)-[e]->(b)
        PER PATH {
            EXPORT a.id, b.id, e.weight INTO result_table
        }
        FOR r IN result_table
        RETURN r.src, r.dst, r.weight
      }
      """
    Then the result should be, in any order:
      | r.src | r.dst | r.weight |
      | 6     | 8     | 2        |
      | 7     | 10    | 12       |
      | 0     | 1     | 1        |
      | 0     | 2     | 2        |
      | 0     | 3     | 0        |
      | 8     | 11    | 32       |
      | 4     | 7     | 1        |
      | 1     | 4     | 1        |
      | 1     | 5     | 2        |
      | 2     | 6     | 1        |
      | 2     | 7     | 222      |
      | 2     | 8     | 13       |
      | 2     | 9     | 1324     |
      | 3     | 10    | 1        |
    # Export graph elements to table
    When executing analytic query:
      """
      USE #load_from_csv_dir {
        TABLE result_table TYPED TABLE {node_str STRING, edge_str STRING}
        MATCH (a)-[e]->(b)
        PER PATH {
            EXPORT a, e INTO result_table
        }
        FOR r IN result_table
        RETURN r.node_str, r.edge_str
      }
      """
    # The localID is not stable, so we need to use a regex to match the result
    # The result below is correct but needs regex, however make fmt will remove the backslash, so comment it out
    Then the execution should be successful
    # Then the result should be, in any order:
    # | r.node_str                                                           | r.edge_str                                                       |
    # | "/\\(288230376151711744\\[0/1024/0/0\\]\\{_LocalId:\\d+,id:0,score:0\\}\\)/" | "[:(288230376151711744->288230376151711745 0@1024) weight:1]"    |
    # | "/\\(288230376151711744\\[0/1024/0/0\\]\\{_LocalId:\\d+,id:0,score:0\\}\\)/" | "[:(288230376151711744->288230376151711746 0@1024) weight:2]"    |
    # | "/\\(288230376151711744\\[0/1024/0/0\\]\\{_LocalId:\\d+,id:0,score:0\\}\\)/" | "[:(288230376151711744->288230376151711747 0@1024) weight:0]"    |
    # | "/\\(288230376151711750\\[0/1024/0/6\\]\\{_LocalId:\\d+,id:6,score:6\\}\\)/" | "[:(288230376151711750->288230376151711752 0@1024) weight:2]"    |
    # | "/\\(288230376151711751\\[0/1024/0/7\\]\\{_LocalId:\\d+,id:7,score:7\\}\\)/" | "[:(288230376151711751->288230376151711754 0@1024) weight:12]"   |
    # | "/\\(288230376151711752\\[0/1024/0/8\\]\\{_LocalId:\\d+,id:8,score:8\\}\\)/" | "[:(288230376151711752->288230376151711755 0@1024) weight:32]"   |
    # | "/\\(288230376151711748\\[0/1024/0/4\\]\\{_LocalId:\\d+,id:4,score:4\\}\\)/" | "[:(288230376151711748->288230376151711751 0@1024) weight:1]"    |
    # | "/\\(288230376151711745\\[0/1024/0/1\\]\\{_LocalId:\\d+,id:1,score:1\\}\\)/" | "[:(288230376151711745->288230376151711748 0@1024) weight:1]"    |
    # | "/\\(288230376151711745\\[0/1024/0/1\\]\\{_LocalId:\\d+,id:1,score:1\\}\\)/" | "[:(288230376151711745->288230376151711749 0@1024) weight:2]"    |
    # | "/\\(288230376151711746\\[0/1024/0/2\\]\\{_LocalId:\\d+,id:2,score:2\\}\\)/" | "[:(288230376151711746->288230376151711750 0@1024) weight:1]"    |
    # | "/\\(288230376151711746\\[0/1024/0/2\\]\\{_LocalId:\\d+,id:2,score:2\\}\\)/" | "[:(288230376151711746->288230376151711751 0@1024) weight:222]"  |
    # | "/\\(288230376151711746\\[0/1024/0/2\\]\\{_LocalId:\\d+,id:2,score:2\\}\\)/" | "[:(288230376151711746->288230376151711752 0@1024) weight:13]"   |
    # | "/\\(288230376151711746\\[0/1024/0/2\\]\\{_LocalId:\\d+,id:2,score:2\\}\\)/" | "[:(288230376151711746->288230376151711753 0@1024) weight:1324]" |
    # | "/\\(288230376151711747\\[0/1024/0/3\\]\\{_LocalId:\\d+,id:3,score:3\\}\\)/" | "[:(288230376151711747->288230376151711754 0@1024) weight:1]"    |
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #load_without_prop TYPED load_from_csv_directory_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+SET_VAR(query_concurrency = 4) */
      USE #load_without_prop IMPORT INTO GRAPH{
            NODE (v@node_type{id:f0}) FROM DATAFILE {
              FORMAT:"csv",
              PATH:"file://${TEST_DIR}/dataset/external_source/csv_source/node",
              autogenerate_column_names: true,
              delimiter: " "
            },
            EDGE (id:f0)-[e@edge_type{}]->(id:f1) FROM DATAFILE {
              FORMAT:"csv",
              PATH:"file://${TEST_DIR}/dataset/external_source/csv_source/edge",
              autogenerate_column_names: true,
              delimiter: " "
            }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #load_without_prop {
        TABLE result_table TYPED TABLE {src INT, dst INT}
        MATCH (a)-[e]->(b)
        PER PATH {
            EXPORT a.id, b.id INTO result_table
        }
        FOR r IN result_table
        RETURN r.src, r.dst
      }
      """
    Then the result should be, in any order:
      | r.src | r.dst |
      | 0     | 1     |
      | 0     | 2     |
      | 0     | 3     |
      | 6     | 8     |
      | 7     | 10    |
      | 8     | 11    |
      | 4     | 7     |
      | 1     | 4     |
      | 1     | 5     |
      | 2     | 6     |
      | 2     | 7     |
      | 2     | 8     |
      | 2     | 9     |
      | 3     | 10    |
    And drop the graph "#load_from_csv_dir"
    And drop the graph "#load_without_prop"
    And drop the graph type "load_from_csv_directory_gt"

  Scenario: Import null value into mutable distributed temporary graph from CSV
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_import_default_null_distributed_gt AS {
            NODE person ({
                id int64 PRIMARY KEY,
                age int8 DEFAULT 18,
                name string
            })
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_import_default_null_distributed TYPED test_import_default_null_distributed_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      FILE f1  {
              id int64,
              name string
          }  = DATAFILE {PATH:'file://${TEST_DIR}/test_import_default_distributed.csv',  FORMAT:'CSV'}
          FOR i IN RANGE(1,10)
          EXPORT
              i AS id,
              NULL AS name
          INTO f1
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_import_default_null_distributed IMPORT INTO GRAPH {
              NODE (v@person{id:id, name:name})
              FROM DATAFILE {
                      PATH:'file://${TEST_DIR}/test_import_default_distributed.csv',
                      FORMAT:'CSV'
                  }
              }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_import_default_null_distributed SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 10        |
      | "Edge Total" | "Edge"       | 0         |
    When executing analytic query:
      """
      FILE f1  {
              id int64,
              name string
          }  = DATAFILE {PATH:'file://${TEST_DIR}/test_import_default_distributed.csv',  FORMAT:'CSV'}
          FOR i IN RANGE(1,10) RETURN i NEXT
          EXPORT
              i AS id,
              NULL AS name
          INTO f1
      """
    Then the execution should be successful
    When executing analytic query:
      """
      FILE f1  {
              id int64,
              name string
          }  = DATAFILE {PATH:'file://${TEST_DIR}/test_import_default_distributed.csv',  FORMAT:'CSV'}
          FOR i IN RANGE(1,10) FINISH
          EXPORT
              1 AS id,
              NULL AS name
          INTO f1
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_import_default_null_distributed {
        TABLE test_import_default_null TYPED TABLE {id INT64, age INT8, name STRING}
        MATCH (v)
        PER NODE (v) {
          EXPORT v.id, v.age, v.name INTO test_import_default_null
        }
        FOR r IN test_import_default_null
        RETURN r.id, r.age, r.name
      }
      """
    Then the result should be, in any order:
      | r.id | r.age | r.name |
      | 1    | 18    | null   |
      | 2    | 18    | null   |
      | 3    | 18    | null   |
      | 4    | 18    | null   |
      | 5    | 18    | null   |
      | 6    | 18    | null   |
      | 7    | 18    | null   |
      | 8    | 18    | null   |
      | 9    | 18    | null   |
      | 10   | 18    | null   |
    When executing analytic query:
      """
      VALUE l LIST<INT> =[1,2,3]
      VALUE i INT = 1
      VALUE l_int LISTAGG<INT>
      SET @l_int = l[1:3]
      SET @l_int += 1
      RETURN l AS ll
      NEXT
      RETURN l[i] AS l_i, @l_int AS l_int, ll[i] AS ll_i
      """
    Then the result should be, in any order:
      | l_i | l_int        | ll_i |
      | 2   | LIST [2,3,1] | 2    |
    When executing analytic query:
      """
      VALUE l LIST<INT> =[1,2,3]
      VALUE i INT = 1
      VALUE l_int LISTAGG<INT>
      SET @l_int = l[1:3]
      SET @l_int += 1
      FINISH
      RETURN l[i] AS l_i, @l_int AS l_int
      """
    Then the result should be, in any order:
      | l_i | l_int        |
      | 2   | LIST [2,3,1] |
    Then remove the temporary directory "${TEST_DIR}/test_import_default_distributed.csv"
    And drop the graph "#test_import_default_null_distributed"
    And drop the graph type "test_import_default_null_distributed_gt"
