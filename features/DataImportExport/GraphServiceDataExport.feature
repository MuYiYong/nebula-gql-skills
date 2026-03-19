# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Graph Service Data Export

  Scenario: ConcurrrentCSVFileOutputInGraphService
    When executing query:
      """
      /*+ SET_VAR(query_concurrency=2) */ FILE f {id INT64, firstName STRING} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/", FORMAT:"csv"}
      USE ldbc MATCH(v:Person) EXPORT v.id, v.firstName INTO f
      """
    Then the execution should be successful

  Scenario: CSVFileOutputInGraphService
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/FileOutputBase.csv"
    When executing query:
      """
      FILE f {id INT64, firstName STRING} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/FileOutputBase.csv", FORMAT:"csv"}
      USE ldbc MATCH(v:Person) EXPORT v.id, v.firstName INTO f
      """
    Then the execution should be successful
    Then the path "file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/FileOutputBase.csv" should be a "directory" path
    And the query stats should be, in any order:
      | name                   | value |
      | "num_affected_nodes"   | 0     |
      | "num_affected_edges"   | 0     |
      | "num_exported_records" | 4     |
      | "exported_paths"       | 1     |
    Then the "csv" output under "${TCK_SERVER_DIR}/output/output_csv_file_tck/FileOutputBase.csv" should match:
      | v.id | v.firstName |
      | 3    | "Ming"      |
      | 2    | "Tim"       |
      | 4    | "Sophie"    |
      | 1    | "Kyle"      |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/FileOutputBase.csv"
    # Using alias
    When executing query:
      """
      FILE f {id INT64, firstName STRING, birthday DATE, creationDate LOCAL DATETIME} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/FileOutputBase.csv", FORMAT:"csv"}
      USE ldbc MATCH(v:Person) EXPORT v.id AS alias_id, v.firstName AS alias_firstName, v.birthday AS alias_birthday, v.creationDate AS alias_creationDate INTO f
      """
    Then the execution should be successful
    Then the "csv" output under "${TCK_SERVER_DIR}/output/output_csv_file_tck/FileOutputBase.csv" should match:
      | alias_id | alias_firstName | alias_birthday | alias_creationDate           |
      | 4        | "Sophie"        | "1999-12-24"   | "2031-01-01T10:00:40.213000" |
      | 2        | "Tim"           | "2001-04-25"   | "2021-01-01T11:00:40.213000" |
      | 3        | "Ming"          | "1995-06-12"   | "2021-01-01T12:00:40.213000" |
      | 1        | "Kyle"          | "1990-01-01"   | "2021-01-01T10:00:40.213000" |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/FileOutputBase.csv"
    # Export graph elements
    When executing query:
      """
      FILE f {nodes STRING, edges STRING} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/FileOutputGraphElement.csv", FORMAT:"csv"}
      USE ldbc MATCH(v:Person)-[e]-(v2:Person) EXPORT v,e INTO f
      """
    Then the execution should be successful
    # Below is the actual file output, commented out because the order of properties is not stable
    # Then the "csv" output under "${TCK_SERVER_DIR}/output/output_csv_file_tck/FileOutputGraphElement.csv" should match:
    # | v                                                                                                                                                                                                                                                                                   | e                                                                                                                                                  |
    # | "(289316916978253828[1024/1027/56372/4]{birthday:DATE \"1999-12-24\",gender:\"female\",creationDate:DATETIME \"2031-01-01T10:00:40.213000\",browserUsed:\"Chrome\",firstName:\"Sophie\",lastName:\"Marceau\",locationIP:\"192.168.4\",id:4,vec:[10.000000, 11.000000, 12.000000]})" | "[:(289316916978253828<-289293960378056708 0@1073742859) dst:4,src:2]"                                                                             |
    # | "(289293960378056708[1024/1027/51027/4]{birthday:DATE \"2001-04-25\",gender:\"male\",creationDate:DATETIME \"2021-01-01T11:00:40.213000\",browserUsed:\"IE\",firstName:\"Tim\",lastName:\"Duncan\",locationIP:\"192.168.2\",id:2,vec:[4.000000, 5.000000, 6.000000]})"              | "[:(289293960378056708->289293960378056708 0@1034) creationDate:DATETIME \"2021-01-01T10:00:40.213000\",vec:[4.000000, 5.000000, 6.000000]]"       |
    # | "(289293960378056708[1024/1027/51027/4]{birthday:DATE \"2001-04-25\",gender:\"male\",creationDate:DATETIME \"2021-01-01T11:00:40.213000\",browserUsed:\"IE\",firstName:\"Tim\",lastName:\"Duncan\",locationIP:\"192.168.2\",id:2,vec:[4.000000, 5.000000, 6.000000]})"              | "[:(289293960378056708<-289293960378056708 0@1073742858) creationDate:DATETIME \"2021-01-01T10:00:40.213000\",vec:[4.000000, 5.000000, 6.000000]]" |
    # | "(289293960378056708[1024/1027/51027/4]{birthday:DATE \"2001-04-25\",gender:\"male\",creationDate:DATETIME \"2021-01-01T11:00:40.213000\",browserUsed:\"IE\",firstName:\"Tim\",lastName:\"Duncan\",locationIP:\"192.168.2\",id:2,vec:[4.000000, 5.000000, 6.000000]})"              | "[:(289293960378056708->289166301065117700 0@1035) dst:3,src:2]"                                                                                   |
    # | "(289293960378056708[1024/1027/51027/4]{birthday:DATE \"2001-04-25\",gender:\"male\",creationDate:DATETIME \"2021-01-01T11:00:40.213000\",browserUsed:\"IE\",firstName:\"Tim\",lastName:\"Duncan\",locationIP:\"192.168.2\",id:2,vec:[4.000000, 5.000000, 6.000000]})"              | "[:(289293960378056708->289316916978253828 0@1035) dst:4,src:2]"                                                                                   |
    # | "(289293960378056708[1024/1027/51027/4]{birthday:DATE \"2001-04-25\",gender:\"male\",creationDate:DATETIME \"2021-01-01T11:00:40.213000\",browserUsed:\"IE\",firstName:\"Tim\",lastName:\"Duncan\",locationIP:\"192.168.2\",id:2,vec:[4.000000, 5.000000, 6.000000]})"              | "[:(289293960378056708<-289107795020611588 0@1073742859) dst:2,src:1]"                                                                             |
    # | "(289293960378056708[1024/1027/51027/4]{birthday:DATE \"2001-04-25\",gender:\"male\",creationDate:DATETIME \"2021-01-01T11:00:40.213000\",browserUsed:\"IE\",firstName:\"Tim\",lastName:\"Duncan\",locationIP:\"192.168.2\",id:2,vec:[4.000000, 5.000000, 6.000000]})"              | "[:(289293960378056708<-289166301065117700 0@1073742859) dst:2,src:3]"                                                                             |
    # | "(289107795020611588[1024/1027/7682/4]{birthday:DATE \"1990-01-01\",gender:\"male\",creationDate:DATETIME \"2021-01-01T10:00:40.213000\",browserUsed:\"Chrome\",firstName:\"Kyle\",lastName:\"cao\",locationIP:\"192.168.1\",id:1,vec:[1.000000, 2.000000, 3.000000]})"             | "[:(289107795020611588->289107795020611588 0@1034) creationDate:DATETIME \"2021-01-01T10:00:40.213000\",vec:[1.000000, 2.000000, 3.000000]]"       |
    # | "(289107795020611588[1024/1027/7682/4]{birthday:DATE \"1990-01-01\",gender:\"male\",creationDate:DATETIME \"2021-01-01T10:00:40.213000\",browserUsed:\"Chrome\",firstName:\"Kyle\",lastName:\"cao\",locationIP:\"192.168.1\",id:1,vec:[1.000000, 2.000000, 3.000000]})"             | "[:(289107795020611588<-289107795020611588 0@1073742858) creationDate:DATETIME \"2021-01-01T10:00:40.213000\",vec:[1.000000, 2.000000, 3.000000]]" |
    # | "(289107795020611588[1024/1027/7682/4]{birthday:DATE \"1990-01-01\",gender:\"male\",creationDate:DATETIME \"2021-01-01T10:00:40.213000\",browserUsed:\"Chrome\",firstName:\"Kyle\",lastName:\"cao\",locationIP:\"192.168.1\",id:1,vec:[1.000000, 2.000000, 3.000000]})"             | "[:(289107795020611588->289293960378056708 0@1035) dst:2,src:1]"                                                                                   |
    # | "(289107795020611588[1024/1027/7682/4]{birthday:DATE \"1990-01-01\",gender:\"male\",creationDate:DATETIME \"2021-01-01T10:00:40.213000\",browserUsed:\"Chrome\",firstName:\"Kyle\",lastName:\"cao\",locationIP:\"192.168.1\",id:1,vec:[1.000000, 2.000000, 3.000000]})"             | "[:(289107795020611588<-289166301065117700 0@1073742859) dst:1,src:3]"                                                                             |
    # | "(289166301065117700[1024/1027/21304/4]{birthday:DATE \"1995-06-12\",gender:\"male\",creationDate:DATETIME \"2021-01-01T12:00:40.213000\",browserUsed:\"Firefox\",firstName:\"Ming\",lastName:\"Yao\",locationIP:\"192.168.3\",id:3,vec:[7.000000, 8.000000, 9.000000]})"           | "[:(289166301065117700->289166301065117700 0@1034) creationDate:DATETIME \"2021-01-01T10:00:40.213000\",vec:[7.000000, 8.000000, 9.000000]]"       |
    # | "(289166301065117700[1024/1027/21304/4]{birthday:DATE \"1995-06-12\",gender:\"male\",creationDate:DATETIME \"2021-01-01T12:00:40.213000\",browserUsed:\"Firefox\",firstName:\"Ming\",lastName:\"Yao\",locationIP:\"192.168.3\",id:3,vec:[7.000000, 8.000000, 9.000000]})"           | "[:(289166301065117700<-289166301065117700 0@1073742858) creationDate:DATETIME \"2021-01-01T10:00:40.213000\",vec:[7.000000, 8.000000, 9.000000]]" |
    # | "(289166301065117700[1024/1027/21304/4]{birthday:DATE \"1995-06-12\",gender:\"male\",creationDate:DATETIME \"2021-01-01T12:00:40.213000\",browserUsed:\"Firefox\",firstName:\"Ming\",lastName:\"Yao\",locationIP:\"192.168.3\",id:3,vec:[7.000000, 8.000000, 9.000000]})"           | "[:(289166301065117700->289107795020611588 0@1035) dst:1,src:3]"                                                                                   |
    # | "(289166301065117700[1024/1027/21304/4]{birthday:DATE \"1995-06-12\",gender:\"male\",creationDate:DATETIME \"2021-01-01T12:00:40.213000\",browserUsed:\"Firefox\",firstName:\"Ming\",lastName:\"Yao\",locationIP:\"192.168.3\",id:3,vec:[7.000000, 8.000000, 9.000000]})"           | "[:(289166301065117700->289293960378056708 0@1035) dst:2,src:3]"                                                                                   |
    # | "(289166301065117700[1024/1027/21304/4]{birthday:DATE \"1995-06-12\",gender:\"male\",creationDate:DATETIME \"2021-01-01T12:00:40.213000\",browserUsed:\"Firefox\",firstName:\"Ming\",lastName:\"Yao\",locationIP:\"192.168.3\",id:3,vec:[7.000000, 8.000000, 9.000000]})"           | "[:(289166301065117700<-289293960378056708 0@1073742859) dst:3,src:2]"                                                                             |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/FileOutputGraphElement.csv"

  Scenario: ParquetFileOutputBase
    When executing query:
      """
      FILE f {id INT64, firstName STRING} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_parquet_file_tck/FileOutputBase.parquet", FORMAT:"parquet"}
      USE ldbc MATCH(v:Person) EXPORT v.id, v.firstName INTO f
      """
    Then the execution should be successful
    Then the path "file:///${TCK_SERVER_DIR}/output/output_parquet_file_tck/FileOutputBase.parquet" should be a "directory" path
    Then the "parquet" output under "${TCK_SERVER_DIR}/output/output_parquet_file_tck/FileOutputBase.parquet" should match:
      | v.id | v.firstName |
      | 3    | "Ming"      |
      | 2    | "Tim"       |
      | 4    | "Sophie"    |
      | 1    | "Kyle"      |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_parquet_file_tck/FileOutputBase.parquet"

  Scenario: OrcFileOutputBase
    When executing query:
      """
      FILE f {id INT64, firstName STRING} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_orc_file_tck/FileOutputBase.orc", FORMAT:"ORC"}
      USE ldbc MATCH(v:Person) EXPORT v.id, v.firstName INTO f
      """
    Then the execution should be successful
    Then the path "file:///${TCK_SERVER_DIR}/output/output_orc_file_tck/FileOutputBase.orc" should be a "directory" path
    Then the "orc" output under "${TCK_SERVER_DIR}/output/output_orc_file_tck/FileOutputBase.orc" should match:
      | v.id | v.firstName |
      | 3    | "Ming"      |
      | 2    | "Tim"       |
      | 4    | "Sophie"    |
      | 1    | "Kyle"      |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_orc_file_tck/FileOutputBase.orc"

  Scenario: Export in match compute
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/graph_export_match_compute"
    When executing graph query:
      """
      /*+ SET_VAR(exec_batch_size = 1) */ USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {firstName STRING, score DOUBLE} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/graph_export_match_compute", FORMAT:"CSV"}
        MATCH (s1:Person)
        PER NODE (s1) {
            EXPORT s1.firstName, s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                   | value |
      | "num_affected_nodes"   | 0     |
      | "num_affected_edges"   | 0     |
      | "num_exported_records" | 4     |
      | "exported_paths"       | 1     |
    Then the "csv" output under "${TCK_SERVER_DIR}/output/output_csv_file_tck/graph_export_match_compute" should match:
      | firstName | score |
      | "Tim"     | 0     |
      | "Sophie"  | 0     |
      | "Ming"    | 0     |
      | "Kyle"    | 0     |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/graph_export_match_compute"

  Scenario: CSVFileOutputViaProcedureCall
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/export_procedure_case"
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE csv_export_proc(file_name STRING) RETURNS ret BOOL AS {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {name STRING, score DOUBLE} = DATAFILE {PATH:file_name, FORMAT:"CSV"}
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
            EXPORT s1.firstName, s1.@current_score INTO f
        }
        PER NODE (s1) {
            SET s1.@current_score += 1.0
            EXPORT s1.firstName, s1.@current_score INTO f
        }
        RETURN true
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      /*+SET_VAR(query_concurrency = 1) */
      USE #analytic_ldbc
      LET file_name = "file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/export_procedure_case"
      CALL csv_export_proc(file_name)
      FINISH
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                   | value |
      | "num_affected_nodes"   | 0     |
      | "num_affected_edges"   | 0     |
      | "num_exported_records" | 8     |
      | "exported_paths"       | 1     |
    Then the "csv" output under "${TCK_SERVER_DIR}/output/output_csv_file_tck/export_procedure_case" should match:
      | name     | score |
      | "Sophie" | 1     |
      | "Ming"   | 1     |
      | "Tim"    | 1     |
      | "Kyle"   | 1     |
      | "Kyle"   | 2     |
      | "Tim"    | 2     |
      | "Ming"   | 2     |
      | "Sophie" | 2     |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/export_procedure_case"

  # Fix https://github.com/vesoft-inc/nebula-ng/issues/9058
  Scenario: All supported data types export
    And drop the graph "#all_supported_data_types_g"
    And drop the graph "all_supported_data_types_g"
    And drop the graph type "all_supported_data_types_gt"
    And create a new session with username "root" and password "NebulaGraph01"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/all_supported_data_types"
    # The temporal data types uses current session timezone to export
    When executing query:
      """
      SESSION SET timezone = "Asia/Shanghai"
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS all_supported_data_types_gt AS {
        NODE person (LABEL person {
          id INT PRIMARY KEY,
          _string STRING,
          _uint8 UINT8,
          _float FLOAT,
          _decimal DECIMAL(10,2),
          _boolean BOOLEAN,
          _date DATE,
          _time LOCAL TIME,
          _zoned_time ZONED TIME,
          _local_datetime LOCAL DATETIME,
          _zoned_datetime ZONED DATETIME,
          _vector VECTOR<3,FLOAT>,
          _geo GEOGRAPHY,
          _list LIST<STRING>
        })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS all_supported_data_types_g all_supported_data_types_gt
      """
    Then the execution should be successful
    When executing query:
      """
      USE all_supported_data_types_g
      INSERT (p1@person{id:3,_string:"string",_uint8:18, _float: 3.4f, _decimal:1088.88m, _boolean:true,
               _date:date("2021-01-01"),
               _time:local_time("10:00:40.213"),
               _zoned_time:zoned_time("10:00:40.213 +0800"),
               _local_datetime:LOCAL_DATETIME("2021-01-01T10:00:40.213"),
               _zoned_datetime:zoned_datetime("2021-01-01T10:00:40.213 +0800"),
               _vector:vector<3,float>([1,2,3]),
               _geo:ST_GeogFromText('POINT(1 1)'),
               _list:["1","2"]})
      """
    Then the execution should be successful
    When executing query:
      """
      FILE f1  {id int,
        _string string,
        _uint8 uint8,
        _float float,
        _decimal decimal(10,2),
        _boolean boolean,
        _date date,
        _time local time,
        _zoned_time zoned time,
        _local_datetime local datetime,
        _zoned_datetime zoned datetime,
        _vector vector<3,float>,
        _geo geography,
        _list list<string>}
      = DATAFILE {PATH:'file://${TEST_DIR}/dataset/temp_test_files/all_supported_data_types/',  FORMAT:'CSV'}
      USE all_supported_data_types_g MATCH (v@person) EXPORT
        v.id,
        v._string,
        v._uint8,
        v._float,
        v._decimal,
        v._boolean,
        v._date,
        v._time,
        v._zoned_time,
        v._local_datetime,
        v._zoned_datetime,
        v._vector,
        v._geo,
        v._list
      INTO f1
      """
    Then the execution should be successful
    Then the "csv" output under "${TEST_DIR}/dataset/temp_test_files/all_supported_data_types" should match:
      | v.id | v._string | v._uint8 | v._float | v._decimal | v._boolean | v._date      | v._time           | v._zoned_time           | v._local_datetime            | v._zoned_datetime                  | v._vector                        | v._geo       | v._list         |
      | 3    | "string"  | 18       | 3.4      | 1088.88    | true       | "2021-01-01" | "10:00:40.213000" | "10:00:40.213000 +0800" | "2021-01-01T10:00:40.213000" | "2021-01-01T10:00:40.213000 +0800" | "[1.000000, 2.000000, 3.000000]" | "POINT(1 1)" | "[\"1\",\"2\"]" |
    # Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/all_supported_data_types"
    And drop the graph "#all_supported_data_types_g"
    And drop the graph "all_supported_data_types_g"
    And drop the graph type "all_supported_data_types_gt"
    And close the current session
