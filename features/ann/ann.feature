# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Ann

  Scenario: ddl and errors
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ann_test_gt AS {
        NODE TYPE N1 (LABEL N1 {id INT PRIMARY KEY, vec1 VECTOR<3, float> default null, vec2 VECTOR<7, float>, vec3 VECTOR<3, float>}),
        NODE TYPE N2 (LABEL N2 {id INT PRIMARY KEY, vec1 VECTOR<3, float>, vec2 VECTOR<7, float>, vec5 VECTOR<5, float>}),
        EDGE TYPE E1 (N1)-[LABEL E1 {id INT MULTIEDGE KEY, vec1 VECTOR<3, float>, vec2 VECTOR<7, float>, vec3 VECTOR<3, float>}]->(N2)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ann_test TYPED ann_test_gt
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_ivf_ip ON NODE N1&N2::vec1 OPTIONS {dim: 3, type:IVF, metric:IP}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_hnsw_ip ON NODE N1&N2::vec1 OPTIONS {dim: 3, type:HNSW, metric:IP, capacity:2}
      """
    Then the execution should be successful
    # test no op
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_ivf_l2 ON NODE N1&N2::vec1 OPTIONS {metric: L2, dim: 3, nlist:10}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_hnsw_ip ON EDGE E1::vec1 OPTIONS {metric: IP, dim: 3, type:HNSW, maxDegree:3, capacity:200, efConstruction:6}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_ivf_l2 ON EDGE E1::vec1 OPTIONS {metric: L2, dim: 3, type:IVF, nlist:8}
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id, vec1, vec2, vec3} =
      {id:1, vec1:vector(1.0, 2.0, 3.0), vec2:vector(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0), vec3:vector(1.0, 2.0, 3.0)},
      {id:2, vec1:vector(2.0, 3.0, 4.0), vec2:vector(2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0), vec3:vector(2.0, 3.0, 4.0)},
      {id:3, vec1:vector(3.0, 4.0, 5.0), vec2:vector(3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0), vec3:vector(3.0, 4.0, 5.0)},
      {id:4, vec1:vector(4.0, 5.0, 6.0), vec2:vector(4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0), vec3:vector(4.0, 5.0, 6.0)},
      {id:5, vec1:vector(5.0, 6.0, 7.0), vec2:vector(5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0), vec3:vector(5.0, 6.0, 7.0)},
      {id:6, vec1:vector(6.0, 7.0, 8.0), vec2:vector(6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0), vec3:vector(6.0, 7.0, 8.0)},
      {id:7, vec1:vector(7.0, 8.0, 9.0), vec2:vector(7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0), vec3:vector(7.0, 8.0, 9.0)},
      {id:8, vec1:vector(8.0, 9.0, 10.0), vec2:vector(8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0), vec3:vector(8.0, 9.0, 10.0)},
      {id:9, vec1:vector(9.0, 10.0, 11.0), vec2:vector(9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0), vec3:vector(9.0, 10.0, 11.0)},
      {id:10, vec1:vector(10.0, 11.0, 12.0), vec2:vector(10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0), vec3:vector(10.0, 11.0, 12.0)},
      {id:11, vec1:vector(11.0, 12.0, 13.0), vec2:vector(11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0), vec3:vector(11.0, 12.0, 13.0)},
      {id:12, vec1:vector(12.0, 13.0, 14.0), vec2:vector(12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0), vec3:vector(12.0, 13.0, 14.0)},
      {id:13, vec1:vector(13.0, 14.0, 15.0), vec2:vector(13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0), vec3:vector(13.0, 14.0, 15.0)},
      {id:14, vec1:vector(14.0, 15.0, 16.0), vec2:vector(14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0), vec3:vector(14.0, 15.0, 16.0)},
      {id:15, vec1:vector(15.0, 16.0, 17.0), vec2:vector(15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0), vec3:vector(15.0, 16.0, 17.0)},
      {id:16, vec1:vector(16.0, 17.0, 18.0), vec2:vector(16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0), vec3:vector(16.0, 17.0, 18.0)},
      {id:17, vec1:vector(17.0, 18.0, 19.0), vec2:vector(17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0), vec3:vector(17.0, 18.0, 19.0)},
      {id:18, vec1:vector(18.0, 19.0, 20.0), vec2:vector(18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0), vec3:vector(18.0, 19.0, 20.0)},
      {id:19, vec1:vector(19.0, 20.0, 21.0), vec2:vector(19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0), vec3:vector(19.0, 20.0, 21.0)},
      {id:20, vec1:vector(20.0, 21.0, 22.0), vec2:vector(20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0), vec3:vector(20.0, 21.0, 22.0)},
      {id:21, vec1:vector(21.0, 22.0, 23.0), vec2:vector(21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0), vec3:vector(21.0, 22.0, 23.0)},
      {id:22, vec1:vector(22.0, 23.0, 24.0), vec2:vector(22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0), vec3:vector(22.0, 23.0, 24.0)},
      {id:23, vec1:vector(23.0, 24.0, 25.0), vec2:vector(23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0), vec3:vector(23.0, 24.0, 25.0)},
      {id:24, vec1:vector(24.0, 25.0, 26.0), vec2:vector(24.0, 25.0, 26.0, 27.0, 28.0, 29.0, 30.0), vec3:vector(24.0, 25.0, 26.0)},
      {id:25, vec1:vector(25.0, 26.0, 27.0), vec2:vector(25.0, 26.0, 27.0, 28.0, 29.0, 30.0, 31.0), vec3:vector(25.0, 26.0, 27.0)},
      {id:26, vec1:vector(26.0, 27.0, 28.0), vec2:vector(26.0, 27.0, 28.0, 29.0, 30.0, 31.0, 32.0), vec3:vector(26.0, 27.0, 28.0)},
      {id:27, vec1:vector(27.0, 28.0, 29.0), vec2:vector(27.0, 28.0, 29.0, 30.0, 31.0, 32.0, 33.0), vec3:vector(27.0, 28.0, 29.0)}
      use ann_test
      FOR r IN t
      INSERT OR IGNORE (@N1{id:r.id,vec1:r.vec1,vec2:r.vec2,vec3:r.vec3})
      """
    Then the execution should be successful
    When executing query:
      """
      use ann_test
      INSERT OR REPLACE
      (@N1{id:10000, vec1:VECTOR<3,float>([10000.0,235,3.343]),vec2:VECTOR<7,float>([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]), vec3:NULL}),
      (@N1{id:10001, vec1:VECTOR<3,float>([11.0, 22.0, 33.0]), vec2:VECTOR<7,float>([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]), vec3:VECTOR<3,float>([11.0, 22.0, 33.0])}),
      (@N1{id:10002, vec1:NULL, vec2:NULL, vec3:VECTOR<3,float>([11.0, 22.0, 33.0])}),
      (@N1{id:10003, vec1:VECTOR<3,float>([10000.0,235,3.343])}),
      (@N1{id:10004, vec1:VECTOR<3,float>([111.0, 222.0, 334.0]), vec2:VECTOR<7,float>([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0])}),
      (@N1{id:10002, vec1:VECTOR<3,float>([111.0, 222.0, 332.0]), vec3:VECTOR<3,float>([111.0, 222.0, 333.0])}),
      (@N1{id:10001, vec1:VECTOR<3,float>([111.0, 222.0, 331.0]), vec3:VECTOR<3,float>([111.0, 222.0, 333.0])})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id, vec1, vec2, vec5} =
      {id:1, vec1:VECTOR<3,float>([1.1, 2.1, 3.1]), vec2:VECTOR<7,float>([1.2, 2.2, 3.2, 4.2, 5.2, 6.2, 7.2]), vec5:VECTOR<5,float>([1.3, 2.3, 3.3, 4.3, 5.3])},
      {id:2, vec1:VECTOR<3,float>([2.1, 3.1, 4.1]), vec2:VECTOR<7,float>([2.2, 3.2, 4.2, 5.2, 6.2, 7.2, 8.2]), vec5:VECTOR<5,float>([2.3, 3.3, 4.3, 5.3, 6.3])},
      {id:3, vec1:VECTOR<3,float>([3.1, 4.1, 5.1]), vec2:VECTOR<7,float>([3.2, 4.2, 5.2, 6.2, 7.2, 8.2, 9.2]), vec5:VECTOR<5,float>([3.3, 4.3, 5.3, 6.3, 7.3])},
      {id:4, vec1:VECTOR<3,float>([4.1, 5.1, 6.1]), vec2:VECTOR<7,float>([4.2, 5.2, 6.2, 7.2, 8.2, 9.2, 10.2]), vec5:VECTOR<5,float>([4.3, 5.3, 6.3, 7.3, 8.3])},
      {id:5, vec1:VECTOR<3,float>([5.1, 6.1, 7.1]), vec2:VECTOR<7,float>([5.2, 6.2, 7.2, 8.2, 9.2, 10.2, 11.2]), vec5:VECTOR<5,float>([5.3, 6.3, 7.3, 8.3, 9.3])},
      {id:6, vec1:VECTOR<3,float>([6.1, 7.1, 8.1]), vec2:VECTOR<7,float>([6.2, 7.2, 8.2, 9.2, 10.2, 11.2, 12.2]), vec5:VECTOR<5,float>([6.3, 7.3, 8.3, 9.3, 10.3])},
      {id:7, vec1:VECTOR<3,float>([7.1, 8.1, 9.1]), vec2:VECTOR<7,float>([7.2, 8.2, 9.2, 10.2, 11.2, 12.2, 13.2]), vec5:VECTOR<5,float>([7.3, 8.3, 9.3, 10.3, 11.3])},
      {id:8, vec1:VECTOR<3,float>([8.1, 9.1, 10.1]), vec2:VECTOR<7,float>([8.2, 9.2, 10.2, 11.2, 12.2, 13.2, 14.2]), vec5:VECTOR<5,float>([8.3, 9.3, 10.3, 11.3, 12.3])},
      {id:9, vec1:VECTOR<3,float>([9.1, 10.1, 11.1]), vec2:VECTOR<7,float>([9.2, 10.2, 11.2, 12.2, 13.2, 14.2, 15.2]), vec5:VECTOR<5,float>([9.3, 10.3, 11.3, 12.3, 13.3])},
      {id:10, vec1:VECTOR<3,float>([10.1, 11.1, 12.1]), vec2:VECTOR<7,float>([10.2, 11.2, 12.2, 13.2, 14.2, 15.2, 16.2]), vec5:VECTOR<5,float>([10.3, 11.3, 12.3, 13.3, 14.3])},
      {id:11, vec1:VECTOR<3,float>([11.1, 12.1, 13.1]), vec2:VECTOR<7,float>([11.2, 12.2, 13.2, 14.2, 15.2, 16.2, 17.2]), vec5:VECTOR<5,float>([11.3, 12.3, 13.3, 14.3, 15.3])},
      {id:12, vec1:VECTOR<3,float>([12.1, 13.1, 14.1]), vec2:VECTOR<7,float>([12.2, 13.2, 14.2, 15.2, 16.2, 17.2, 18.2]), vec5:VECTOR<5,float>([12.3, 13.3, 14.3, 15.3, 16.3])},
      {id:13, vec1:VECTOR<3,float>([13.1, 14.1, 15.1]), vec2:VECTOR<7,float>([13.2, 14.2, 15.2, 16.2, 17.2, 18.2, 19.2]), vec5:VECTOR<5,float>([13.3, 14.3, 15.3, 16.3, 17.3])},
      {id:14, vec1:VECTOR<3,float>([14.1, 15.1, 16.1]), vec2:VECTOR<7,float>([14.2, 15.2, 16.2, 17.2, 18.2, 19.2, 20.2]), vec5:VECTOR<5,float>([14.3, 15.3, 16.3, 17.3, 18.3])},
      {id:15, vec1:VECTOR<3,float>([15.1, 16.1, 17.1]), vec2:VECTOR<7,float>([15.2, 16.2, 17.2, 18.2, 19.2, 20.2, 21.2]), vec5:VECTOR<5,float>([15.3, 16.3, 17.3, 18.3, 19.3])},
      {id:16, vec1:VECTOR<3,float>([16.1, 17.1, 18.1]), vec2:VECTOR<7,float>([16.2, 17.2, 18.2, 19.2, 20.2, 21.2, 22.2]), vec5:VECTOR<5,float>([16.3, 17.3, 18.3, 19.3, 20.3])},
      {id:17, vec1:VECTOR<3,float>([17.1, 18.1, 19.1]), vec2:VECTOR<7,float>([17.2, 18.2, 19.2, 20.2, 21.2, 22.2, 23.2]), vec5:VECTOR<5,float>([17.3, 18.3, 19.3, 20.3, 21.3])},
      {id:18, vec1:VECTOR<3,float>([18.1, 19.1, 20.1]), vec2:VECTOR<7,float>([18.2, 19.2, 20.2, 21.2, 22.2, 23.2, 24.2]), vec5:VECTOR<5,float>([18.3, 19.3, 20.3, 21.3, 22.3])},
      {id:19, vec1:VECTOR<3,float>([19.1, 20.1, 21.1]), vec2:VECTOR<7,float>([19.2, 20.2, 21.2, 22.2, 23.2, 24.2, 25.2]), vec5:VECTOR<5,float>([19.3, 20.3, 21.3, 22.3, 23.3])}
      use ann_test
      FOR r IN t
      INSERT OR IGNORE (@N2{id:r.id,vec1:r.vec1,vec2:r.vec2,vec5:r.vec5})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src, dst, id, vec1, vec2, vec3} =
      {src: 1, dst:1, id:1, vec1:VECTOR<3,float>([1.11, 2.12, 3.13]), vec2:VECTOR<7,float>([1.21, 2.22, 3.23, 4.24, 5.25, 6.26, 7.27]), vec3:VECTOR<3,float>([1.31, 2.32, 3.33])},
      {src: 2, dst:2, id:2, vec1:VECTOR<3,float>([2.11, 3.12, 4.13]), vec2:VECTOR<7,float>([2.21, 3.22, 4.23, 5.24, 6.25, 7.26, 8.27]), vec3:VECTOR<3,float>([2.31, 3.32, 4.33])},
      {src: 3, dst:3, id:3, vec1:VECTOR<3,float>([3.11, 4.12, 5.13]), vec2:VECTOR<7,float>([3.21, 4.22, 5.23, 6.24, 7.25, 8.26, 9.27]), vec3:VECTOR<3,float>([3.31, 4.32, 5.33])},
      {src: 4, dst:4, id:4, vec1:VECTOR<3,float>([4.11, 5.12, 6.13]), vec2:VECTOR<7,float>([4.21, 5.22, 6.23, 7.24, 8.25, 9.26, 10.27]), vec3:VECTOR<3,float>([4.31, 5.32, 6.33])},
      {src: 5, dst:5, id:5, vec1:VECTOR<3,float>([5.11, 6.12, 7.13]), vec2:VECTOR<7,float>([5.21, 6.22, 7.23, 8.24, 9.25, 10.26, 11.27]), vec3:VECTOR<3,float>([5.31, 6.32, 7.33])},
      {src: 6, dst:6, id:6, vec1:VECTOR<3,float>([6.11, 7.12, 8.13]), vec2:VECTOR<7,float>([6.21, 7.22, 8.23, 9.24, 10.25, 11.26, 12.27]), vec3:VECTOR<3,float>([6.31, 7.32, 8.33])},
      {src: 7, dst:7, id:7, vec1:VECTOR<3,float>([7.11, 8.12, 9.13]), vec2:VECTOR<7,float>([7.21, 8.22, 9.23, 10.24, 11.25, 12.26, 13.27]), vec3:VECTOR<3,float>([7.31, 8.32, 9.33])},
      {src: 8, dst:8, id:8, vec1:VECTOR<3,float>([8.11, 9.12, 10.13]), vec2:VECTOR<7,float>([8.21, 9.22, 10.23, 11.24, 12.25, 13.26, 14.27]), vec3:VECTOR<3,float>([8.31, 9.32, 10.33])},
      {src: 9, dst:9, id:9, vec1:VECTOR<3,float>([9.11, 10.12, 11.13]), vec2:VECTOR<7,float>([9.21, 10.22, 11.23, 12.24, 13.25, 14.26, 15.27]), vec3:VECTOR<3,float>([9.31, 10.32, 11.33])},
      {src: 10, dst:10, id:10, vec1:VECTOR<3,float>([10.11, 11.12, 12.13]), vec2:VECTOR<7,float>([10.21, 11.22, 12.23, 13.24, 14.25, 15.26, 16.27]), vec3:VECTOR<3,float>([10.31, 11.32, 12.33])},
      {src: 11, dst:11, id:11, vec1:VECTOR<3,float>([11.11, 12.12, 13.13]), vec2:VECTOR<7,float>([11.21, 12.22, 13.23, 14.24, 15.25, 16.26, 17.27]), vec3:VECTOR<3,float>([11.31, 12.32, 13.33])},
      {src: 12, dst:12, id:12, vec1:VECTOR<3,float>([12.11, 13.12, 14.13]), vec2:VECTOR<7,float>([12.21, 13.22, 14.23, 15.24, 16.25, 17.26, 18.27]), vec3:VECTOR<3,float>([12.31, 13.32, 14.33])},
      {src: 13, dst:13, id:13, vec1:VECTOR<3,float>([13.11, 14.12, 15.13]), vec2:VECTOR<7,float>([13.21, 14.22, 15.23, 16.24, 17.25, 18.26, 19.27]), vec3:VECTOR<3,float>([13.31, 14.32, 15.33])},
      {src: 14, dst:14, id:14, vec1:VECTOR<3,float>([14.11, 15.12, 16.13]), vec2:VECTOR<7,float>([14.21, 15.22, 16.23, 17.24, 18.25, 19.26, 20.27]), vec3:VECTOR<3,float>([14.31, 15.32, 16.33])},
      {src: 15, dst:15, id:15, vec1:VECTOR<3,float>([15.11, 16.12, 17.13]), vec2:VECTOR<7,float>([15.21, 16.22, 17.23, 18.24, 19.25, 20.26, 21.27]), vec3:VECTOR<3,float>([15.31, 16.32, 17.33])},
      {src: 16, dst:16, id:16, vec1:VECTOR<3,float>([16.11, 17.12, 18.13]), vec2:VECTOR<7,float>([16.21, 17.22, 18.23, 19.24, 20.25, 21.26, 22.27]), vec3:VECTOR<3,float>([16.31, 17.32, 18.33])},
      {src: 17, dst:17, id:17, vec1:VECTOR<3,float>([17.11, 18.12, 19.13]), vec2:VECTOR<7,float>([17.21, 18.22, 19.23, 20.24, 21.25, 22.26, 23.27]), vec3:VECTOR<3,float>([17.31, 18.32, 19.33])},
      {src: 18, dst:18, id:18, vec1:VECTOR<3,float>([18.11, 19.12, 20.13]), vec2:VECTOR<7,float>([18.21, 19.22, 20.23, 21.24, 22.25, 23.26, 24.27]), vec3:VECTOR<3,float>([18.31, 19.32, 20.33])},
      {src: 19, dst:19, id:19, vec1:VECTOR<3,float>([19.11, 20.12, 21.13]), vec2:VECTOR<7,float>([19.21, 20.22, 21.23, 22.24, 23.25, 24.26, 25.27]), vec3:VECTOR<3,float>([19.31, 20.32, 21.33])},
      {src: 20, dst:17, id:20, vec1:VECTOR<3,float>([20.11, 21.12, 22.13]), vec2:VECTOR<7,float>([20.21, 21.22, 22.23, 23.24, 24.25, 25.26, 26.27]), vec3:VECTOR<3,float>([20.31, 21.32, 22.33])},
      {src: 21, dst:17, id:21, vec1:VECTOR<3,float>([21.11, 22.12, 23.13]), vec2:VECTOR<7,float>([21.21, 22.22, 23.23, 24.24, 25.25, 26.26, 27.27]), vec3:VECTOR<3,float>([21.31, 22.32, 23.33])},
      {src: 22, dst:17, id:22, vec1:VECTOR<3,float>([22.11, 23.12, 24.13]), vec2:VECTOR<7,float>([22.21, 23.22, 24.23, 25.24, 26.25, 27.26, 28.27]), vec3:VECTOR<3,float>([22.31, 23.32, 24.33])},
      {src: 23, dst:17, id:23, vec1:VECTOR<3,float>([23.11, 24.12, 25.13]), vec2:VECTOR<7,float>([23.21, 24.22, 25.23, 26.24, 27.25, 28.26, 29.27]), vec3:VECTOR<3,float>([23.31, 24.32, 25.33])},
      {src: 24, dst:17, id:24, vec1:VECTOR<3,float>([24.11, 25.12, 26.13]), vec2:VECTOR<7,float>([24.21, 25.22, 26.23, 27.24, 28.25, 29.26, 30.27]), vec3:VECTOR<3,float>([24.31, 25.32, 26.33])},
      {src: 25, dst:17, id:25, vec1:VECTOR<3,float>([25.11, 26.12, 27.13]), vec2:VECTOR<7,float>([25.21, 26.22, 27.23, 28.24, 29.25, 30.26, 31.27]), vec3:VECTOR<3,float>([25.31, 26.32, 27.33])},
      {src: 26, dst:17, id:26, vec1:VECTOR<3,float>([26.11, 27.12, 28.13]), vec2:VECTOR<7,float>([26.21, 27.22, 28.23, 29.24, 30.25, 31.26, 32.27]), vec3:VECTOR<3,float>([26.31, 27.32, 28.33])},
      {src: 27, dst:17, id:27, vec1:VECTOR<3,float>([27.11, 28.12, 29.13]), vec2:VECTOR<7,float>([27.21, 28.22, 29.23, 30.24, 31.25, 32.26, 33.27]), vec3:VECTOR<3,float>([27.31, 28.32, 29.33])}
      use ann_test
      FOR r IN t
      MATCH (n1:N1{id:r.src}), (n2:N2{id:r.dst})
      INSERT OR IGNORE (n1)-[@E1{id:r.id,vec1:r.vec1,vec2:r.vec2,vec3:r.vec3}]->(n2)
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_ivf_l2 ON NODE N1&N2::vec1 OPTIONS {dim: 3}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_hnsw_l2 ON EDGE E1::vec1 OPTIONS {metric: L2, dim: 3, type:HNSW}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_hnsw_l2 ON NODE N1&N2::vec1 OPTIONS {dim: 3, type:hnsw, metric:L2}
      """
    Then the execution should be successful
    # test no op
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_ivf_l2 ON NODE N1&N2::vec1 OPTIONS {metric: L2, dim: 3}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_ivf_ip ON EDGE E1::vec1 OPTIONS {metric: IP, dim: 3, type:IVF}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_hnsw_ip ON EDGE E1::vec1 OPTIONS {metric: IP, dim: 3, type:HNSW}
      """
    Then the execution should be successful
    And wait "3" seconds
    When executing query:
      """
      BALANCE DATA
      """
    Then the execution should be successful
    When executing query:
      """
      BALANCE LEADER
      """
    Then the execution should be successful
    And wait "3" seconds
    When executing query:
      """
      CALL show_all_indexes()
      FILTER graph_name='ann_test'
      RETURN name, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name               | index_type                                                                                  | graph_name | entity_type | element_type | properties    |
      | "ann_node_hnsw_l2" | "Vector{type:HNSW, metric:L2, dimension:3, maxDegree:8, efConstruction:16, capacity:10000}" | "ann_test" | "Node"      | "N1,N2"      | LIST ["vec1"] |
      | "ann_node_ivf_l2"  | "Vector{type:IVF, metric:L2, dimension:3, nlist:10, trainSize:3}"                           | "ann_test" | "Node"      | "N1,N2"      | LIST ["vec1"] |
      | "ann_node_ivf_ip"  | "Vector{type:IVF, metric:IP, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Node"      | "N1,N2"      | LIST ["vec1"] |
      | "ann_node_hnsw_ip" | "Vector{type:HNSW, metric:IP, dimension:3, maxDegree:8, efConstruction:16, capacity:2}"     | "ann_test" | "Node"      | "N1,N2"      | LIST ["vec1"] |
      | "ann_edge_ivf_l2"  | "Vector{type:IVF, metric:L2, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_hnsw_ip" | "Vector{type:HNSW, metric:IP, dimension:3, maxDegree:3, efConstruction:6, capacity:200}"    | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_hnsw_l2" | "Vector{type:HNSW, metric:L2, dimension:3, maxDegree:8, efConstruction:16, capacity:10000}" | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_ivf_ip"  | "Vector{type:IVF, metric:IP, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
    When executing query:
      """
      USE ann_test REPAIR INDEX ann_edge_hnsw_ip
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test REPAIR INDEX ann_idx3
      """
    Then an Error should be raised: "[NC007]: Catalog index not found: `ann_idx3`"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX ann_node_ivf_l2 ON NODE N1&N2::vec1 OPTIONS {metric: L2, nlist:8, dim: 3}
      """
    Then an Error should be raised: "[NC111]: Node vector index already exists: ann_node_ivf_l2"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX ann_node_ivf_l2 ON EDGE E1::vec1 OPTIONS {metric: L2, dim: 3, nlist:10}
      """
    Then an Error should be raised: "[NC111]: Node vector index already exists: ann_node_ivf_l2"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX ann_node_ivf_l2 ON NODE N1&N2::vec1 OPTIONS {metric: L2, dim: 3}
      """
    Then an Error should be raised: "[NC111]: Node vector index already exists: ann_node_ivf_l2"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX ann_edge_ivf_l2 ON EDGE E1::vec1 OPTIONS {metric: L2, dim: 3}
      """
    Then an Error should be raised: "[NC112]: Edge vector index already exists: ann_edge_ivf_l2"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX ann_edge_ivf_l2 ON NODE N1&N2::vec1 OPTIONS {metric: L2, dim: 3}
      """
    Then an Error should be raised: "[NC112]: Edge vector index already exists: ann_edge_ivf_l2"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_idx_invalid ON NODE N1&N2::vec1 OPTIONS {metric: L2, dim: 33}
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Creating vector index with different dimension `N1::vec1` is not allowed."
    When executing query:
      """
      USE ldbc CREATE VECTOR INDEX IF NOT EXISTS scalar_idx ON NODE Person::id OPTIONS {metric: L2, dim: 33}
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Creating vector index on non-vector type property `Person::id` is not allowed."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_idx_invalid ON NODE N1&N4::vec1 OPTIONS {metric: IP, dim: 3}
      """
    Then an Error should be raised: "[NC003]: Node type not found: `N4`"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_idx_invalid ON NODE N1&N2::vec33 OPTIONS {metric: L2, dim: 33}
      """
    Then an Error should be raised: "[NC006]: Property `vec33` of type `N1` not found"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_idx_invalid ON EDGE N1&N2::vec1 OPTIONS {metric: L2, dim: 33}
      """
    Then an Error should be raised: "[NC004]: Edge type not found: `N1`"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_idx_invalid ON EDGE E1::vec1 OPTIONS {metric: L2, dim: 33}
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Creating vector index with different dimension `E1::vec1` is not allowed."
    When executing query:
      """
      USE ldbc CREATE VECTOR INDEX IF NOT EXISTS scalar_idx ON EDGE KNOWS::creationDate OPTIONS {metric: L2, dim: 33, nlist:8}
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Creating vector index on non-vector type property `KNOWS::creationDate` is not allowed."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_idx_invalid ON EDGE E4::vec1 OPTIONS {metric: IP, dim: 3}
      """
    Then an Error should be raised: "[NC004]: Edge type not found: `E4`"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_idx_invalid ON EDGE E1::vec33 OPTIONS {metric: L2, dim: 33}
      """
    Then an Error should be raised: "[NC006]: Property `vec33` of type `E1` not found"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_idx_invalid ON NODE N1&E1::vec1 OPTIONS {metric: L2, dim: 3}
      """
    Then an Error should be raised: "[NC003]: Node type not found: `E1`"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_idx_invalid ON EDGE N1&E1::vec1 OPTIONS {metric: L2, dim: 3}
      """
    Then an Error should be raised: "[NC004]: Edge type not found: `N1`"
    # incremental DML for existing vector index
    When executing query:
      """
      TABLE t {id, vec1, vec2, vec3} =
      {id:81, vec1:VECTOR<3,float>([1.08, 2.08, 3.08]), vec2:VECTOR<7,float>([1.08, 2.08, 3.08, 4.08, 5.08, 6.08, 7.08]), vec3:VECTOR<3,float>([1.08, 2.08, 3.08])},
      {id:82, vec1:VECTOR<3,float>([2.08, 3.08, 4.08]), vec2:VECTOR<7,float>([2.08, 3.08, 4.08, 5.08, 6.08, 7.08, 8.08]), vec3:VECTOR<3,float>([2.08, 3.08, 4.08])},
      {id:83, vec1:VECTOR<3,float>([3.08, 4.08, 5.08]), vec2:VECTOR<7,float>([3.08, 4.08, 5.08, 6.08, 7.08, 8.08, 9.08]), vec3:VECTOR<3,float>([3.08, 4.08, 5.08])},
      {id:84, vec1:VECTOR<3,float>([4.08, 5.08, 6.08]), vec2:VECTOR<7,float>([4.08, 5.08, 6.08, 7.08, 8.08, 9.08, 10.08]), vec3:VECTOR<3,float>([4.08, 5.08, 6.08])},
      {id:85, vec1:VECTOR<3,float>([5.08, 6.08, 7.08]), vec2:VECTOR<7,float>([5.08, 6.08, 7.08, 8.08, 9.08, 10.08, 11.08]), vec3:VECTOR<3,float>([5.08, 6.08, 7.08])},
      {id:86, vec1:VECTOR<3,float>([6.08, 7.08, 8.08]), vec2:VECTOR<7,float>([6.08, 7.08, 8.08, 9.08, 10.08, 11.08, 12.08]), vec3:VECTOR<3,float>([6.08, 7.08, 8.08])},
      {id:87, vec1:VECTOR<3,float>([7.08, 8.08, 9.08]), vec2:VECTOR<7,float>([7.08, 8.08, 9.08, 10.08, 11.08, 12.08, 13.08]), vec3:VECTOR<3,float>([7.08, 8.08, 9.08])},
      {id:88, vec1:VECTOR<3,float>([8.08, 9.08, 10.08]), vec2:VECTOR<7,float>([8.08, 9.08, 10.08, 11.08, 12.08, 13.08, 14.08]), vec3:VECTOR<3,float>([8.08, 9.08, 10.08])},
      {id:89, vec1:VECTOR<3,float>([9.08, 10.08, 11.08]), vec2:VECTOR<7,float>([9.08, 10.08, 11.08, 12.08, 13.08, 14.08, 15.08]), vec3:VECTOR<3,float>([9.08, 10.08, 11.08])},
      {id:810, vec1:VECTOR<3,float>([10.08, 11.08, 12.08]), vec2:VECTOR<7,float>([10.08, 11.08, 12.08, 13.08, 14.08, 15.08, 16.08]), vec3:VECTOR<3,float>([10.08, 11.08, 12.08])},
      {id:811, vec1:VECTOR<3,float>([11.08, 12.08, 13.08]), vec2:VECTOR<7,float>([11.08, 12.08, 13.08, 14.08, 15.08, 16.08, 17.08]), vec3:VECTOR<3,float>([11.08, 12.08, 13.08])},
      {id:812, vec1:VECTOR<3,float>([12.08, 13.08, 14.08]), vec2:VECTOR<7,float>([12.08, 13.08, 14.08, 15.08, 16.08, 17.08, 18.08]), vec3:VECTOR<3,float>([12.08, 13.08, 14.08])},
      {id:813, vec1:VECTOR<3,float>([13.08, 14.08, 15.08]), vec2:VECTOR<7,float>([13.08, 14.08, 15.08, 16.08, 17.08, 18.08, 19.08]), vec3:VECTOR<3,float>([13.08, 14.08, 15.08])},
      {id:814, vec1:VECTOR<3,float>([14.08, 15.08, 16.08]), vec2:VECTOR<7,float>([14.08, 15.08, 16.08, 17.08, 18.08, 19.08, 20.08]), vec3:VECTOR<3,float>([14.08, 15.08, 16.08])},
      {id:815, vec1:VECTOR<3,float>([15.08, 16.08, 17.08]), vec2:VECTOR<7,float>([15.08, 16.08, 17.08, 18.08, 19.08, 20.08, 21.08]), vec3:VECTOR<3,float>([15.08, 16.08, 17.08])},
      {id:816, vec1:VECTOR<3,float>([16.08, 17.08, 18.08]), vec2:VECTOR<7,float>([16.08, 17.08, 18.08, 19.08, 20.08, 21.08, 22.08]), vec3:VECTOR<3,float>([16.08, 17.08, 18.08])},
      {id:817, vec1:VECTOR<3,float>([17.08, 18.08, 19.08]), vec2:VECTOR<7,float>([17.08, 18.08, 19.08, 20.08, 21.08, 22.08, 23.08]), vec3:VECTOR<3,float>([17.08, 18.08, 19.08])},
      {id:818, vec1:VECTOR<3,float>([18.08, 19.08, 20.08]), vec2:VECTOR<7,float>([18.08, 19.08, 20.08, 21.08, 22.08, 23.08, 24.08]), vec3:VECTOR<3,float>([18.08, 19.08, 20.08])},
      {id:819, vec1:VECTOR<3,float>([19.08, 20.08, 21.08]), vec2:VECTOR<7,float>([19.08, 20.08, 21.08, 22.08, 23.08, 24.08, 25.08]), vec3:VECTOR<3,float>([19.08, 20.08, 21.08])}
      use ann_test
      FOR r IN t
      INSERT OR IGNORE (@N1{id:r.id,vec1:r.vec1,vec2:r.vec2,vec3:r.vec3})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id, vec1, vec2, vec5} =
      {id:91, vec1:VECTOR<3,float>([1.19, 2.19, 3.19]), vec2:VECTOR<7,float>([1.29, 2.29, 3.29, 4.29, 5.29, 6.29, 7.29]), vec5:VECTOR<5,float>([1.39, 2.39, 3.39, 4.39, 5.39])},
      {id:92, vec1:VECTOR<3,float>([2.19, 3.19, 4.19]), vec2:VECTOR<7,float>([2.29, 3.29, 4.29, 5.29, 6.29, 7.29, 8.29]), vec5:VECTOR<5,float>([2.39, 3.39, 4.39, 5.39, 6.39])},
      {id:93, vec1:VECTOR<3,float>([3.19, 4.19, 5.19]), vec2:VECTOR<7,float>([3.29, 4.29, 5.29, 6.29, 7.29, 8.29, 9.29]), vec5:VECTOR<5,float>([3.39, 4.39, 5.39, 6.39, 7.39])},
      {id:94, vec1:VECTOR<3,float>([4.19, 5.19, 6.19]), vec2:VECTOR<7,float>([4.29, 5.29, 6.29, 7.29, 8.29, 9.29, 10.29]), vec5:VECTOR<5,float>([4.39, 5.39, 6.39, 7.39, 8.39])},
      {id:95, vec1:VECTOR<3,float>([5.19, 6.19, 7.19]), vec2:VECTOR<7,float>([5.29, 6.29, 7.29, 8.29, 9.29, 10.29, 11.29]), vec5:VECTOR<5,float>([5.39, 6.39, 7.39, 8.39, 9.39])},
      {id:96, vec1:VECTOR<3,float>([6.19, 7.19, 8.19]), vec2:VECTOR<7,float>([6.29, 7.29, 8.29, 9.29, 10.29, 11.29, 12.29]), vec5:VECTOR<5,float>([6.39, 7.39, 8.39, 9.39, 10.39])},
      {id:97, vec1:VECTOR<3,float>([7.19, 8.19, 9.19]), vec2:VECTOR<7,float>([7.29, 8.29, 9.29, 10.29, 11.29, 12.29, 13.29]), vec5:VECTOR<5,float>([7.39, 8.39, 9.39, 10.39, 11.39])},
      {id:98, vec1:VECTOR<3,float>([8.19, 9.19, 10.19]), vec2:VECTOR<7,float>([8.29, 9.29, 10.29, 11.29, 12.29, 13.29, 14.29]), vec5:VECTOR<5,float>([8.39, 9.39, 10.39, 11.39, 12.39])},
      {id:99, vec1:VECTOR<3,float>([9.19, 10.19, 11.19]), vec2:VECTOR<7,float>([9.29, 10.29, 11.29, 12.29, 13.29, 14.29, 15.29]), vec5:VECTOR<5,float>([9.39, 10.39, 11.39, 12.39, 13.39])},
      {id:910, vec1:VECTOR<3,float>([10.19, 11.19, 12.19]), vec2:VECTOR<7,float>([10.29, 11.29, 12.29, 13.29, 14.29, 15.29, 16.29]), vec5:VECTOR<5,float>([10.39, 11.39, 12.39, 13.39, 14.39])},
      {id:911, vec1:VECTOR<3,float>([11.19, 12.19, 13.19]), vec2:VECTOR<7,float>([11.29, 12.29, 13.29, 14.29, 15.29, 16.29, 17.29]), vec5:VECTOR<5,float>([11.39, 12.39, 13.39, 14.39, 15.39])},
      {id:912, vec1:VECTOR<3,float>([12.19, 13.19, 14.19]), vec2:VECTOR<7,float>([12.29, 13.29, 14.29, 15.29, 16.29, 17.29, 18.29]), vec5:VECTOR<5,float>([12.39, 13.39, 14.39, 15.39, 16.39])},
      {id:913, vec1:VECTOR<3,float>([13.19, 14.19, 15.19]), vec2:VECTOR<7,float>([13.29, 14.29, 15.29, 16.29, 17.29, 18.29, 19.29]), vec5:VECTOR<5,float>([13.39, 14.39, 15.39, 16.39, 17.39])},
      {id:914, vec1:VECTOR<3,float>([14.19, 15.19, 16.19]), vec2:VECTOR<7,float>([14.29, 15.29, 16.29, 17.29, 18.29, 19.29, 20.29]), vec5:VECTOR<5,float>([14.39, 15.39, 16.39, 17.39, 18.39])},
      {id:915, vec1:VECTOR<3,float>([15.19, 16.19, 17.19]), vec2:VECTOR<7,float>([15.29, 16.29, 17.29, 18.29, 19.29, 20.29, 21.29]), vec5:VECTOR<5,float>([15.39, 16.39, 17.39, 18.39, 19.39])},
      {id:916, vec1:VECTOR<3,float>([16.19, 17.19, 18.19]), vec2:VECTOR<7,float>([16.29, 17.29, 18.29, 19.29, 20.29, 21.29, 22.29]), vec5:VECTOR<5,float>([16.39, 17.39, 18.39, 19.39, 20.39])},
      {id:917, vec1:VECTOR<3,float>([17.19, 18.19, 19.19]), vec2:VECTOR<7,float>([17.29, 18.29, 19.29, 20.29, 21.29, 22.29, 23.29]), vec5:VECTOR<5,float>([17.39, 18.39, 19.39, 20.39, 21.39])},
      {id:918, vec1:VECTOR<3,float>([18.19, 19.19, 20.19]), vec2:VECTOR<7,float>([18.29, 19.29, 20.29, 21.29, 22.29, 23.29, 24.29]), vec5:VECTOR<5,float>([18.39, 19.39, 20.39, 21.39, 22.39])},
      {id:919, vec1:VECTOR<3,float>([19.19, 20.19, 21.19]), vec2:VECTOR<7,float>([19.29, 20.29, 21.29, 22.29, 23.29, 24.29, 25.29]), vec5:VECTOR<5,float>([19.39, 20.39, 21.39, 22.39, 23.39])}
      use ann_test
      FOR r IN t
      INSERT OR IGNORE (@N2{id:r.id,vec1:r.vec1,vec2:r.vec2,vec5:r.vec5})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src, dst, id, vec1, vec2, vec3} =
      {src: 71, dst:1, id:1, vec1:VECTOR<3,float>([1.117, 2.127, 3.137]), vec2:VECTOR<7,float>([1.217, 2.227, 3.237, 4.247, 5.257, 6.267, 7.277]), vec3:VECTOR<3,float>([1.317, 2.327, 3.337])},
      {src: 72, dst:2, id:2, vec1:VECTOR<3,float>([2.117, 3.127, 4.137]), vec2:VECTOR<7,float>([2.217, 3.227, 4.237, 5.247, 6.257, 7.267, 8.277]), vec3:VECTOR<3,float>([2.317, 3.327, 4.337])},
      {src: 73, dst:3, id:3, vec1:VECTOR<3,float>([3.117, 4.127, 5.137]), vec2:VECTOR<7,float>([3.217, 4.227, 5.237, 6.247, 7.257, 8.267, 9.277]), vec3:VECTOR<3,float>([3.317, 4.327, 5.337])},
      {src: 74, dst:4, id:4, vec1:VECTOR<3,float>([4.117, 5.127, 6.137]), vec2:VECTOR<7,float>([4.217, 5.227, 6.237, 7.247, 8.257, 9.267, 10.277]), vec3:VECTOR<3,float>([4.317, 5.327, 6.337])},
      {src: 75, dst:5, id:5, vec1:VECTOR<3,float>([5.117, 6.127, 7.137]), vec2:VECTOR<7,float>([5.217, 6.227, 7.237, 8.247, 9.257, 10.267, 11.277]), vec3:VECTOR<3,float>([5.317, 6.327, 7.337])},
      {src: 76, dst:6, id:6, vec1:VECTOR<3,float>([6.117, 7.127, 8.137]), vec2:VECTOR<7,float>([6.217, 7.227, 8.237, 9.247, 10.257, 11.267, 12.277]), vec3:VECTOR<3,float>([6.317, 7.327, 8.337])},
      {src: 77, dst:7, id:7, vec1:VECTOR<3,float>([7.117, 8.127, 9.137]), vec2:VECTOR<7,float>([7.217, 8.227, 9.237, 10.247, 11.257, 12.267, 13.277]), vec3:VECTOR<3,float>([7.317, 8.327, 9.337])},
      {src: 78, dst:8, id:8, vec1:VECTOR<3,float>([8.117, 9.127, 10.137]), vec2:VECTOR<7,float>([8.217, 9.227, 10.237, 11.247, 12.257, 13.267, 14.277]), vec3:VECTOR<3,float>([8.317, 9.327, 10.337])},
      {src: 79, dst:9, id:9, vec1:VECTOR<3,float>([9.117, 10.127, 11.137]), vec2:VECTOR<7,float>([9.217, 10.227, 11.237, 12.247, 13.257, 14.267, 15.277]), vec3:VECTOR<3,float>([9.317, 10.327, 11.337])},
      {src: 710, dst:10, id:10, vec1:VECTOR<3,float>([10.117, 11.127, 12.137]), vec2:VECTOR<7,float>([10.217, 11.227, 12.237, 13.247, 14.257, 15.267, 16.277]), vec3:VECTOR<3,float>([10.317, 11.327, 12.337])},
      {src: 711, dst:11, id:11, vec1:VECTOR<3,float>([11.117, 12.127, 13.137]), vec2:VECTOR<7,float>([11.217, 12.227, 13.237, 14.247, 15.257, 16.267, 17.277]), vec3:VECTOR<3,float>([11.317, 12.327, 13.337])},
      {src: 712, dst:12, id:12, vec1:VECTOR<3,float>([12.117, 13.127, 14.137]), vec2:VECTOR<7,float>([12.217, 13.227, 14.237, 15.247, 16.257, 17.267, 18.277]), vec3:VECTOR<3,float>([12.317, 13.327, 14.337])},
      {src: 713, dst:13, id:13, vec1:VECTOR<3,float>([13.117, 14.127, 15.137]), vec2:VECTOR<7,float>([13.217, 14.227, 15.237, 16.247, 17.257, 18.267, 19.277]), vec3:VECTOR<3,float>([13.317, 14.327, 15.337])},
      {src: 714, dst:14, id:14, vec1:VECTOR<3,float>([14.117, 15.127, 16.137]), vec2:VECTOR<7,float>([14.217, 15.227, 16.237, 17.247, 18.257, 19.267, 20.277]), vec3:VECTOR<3,float>([14.317, 15.327, 16.337])},
      {src: 715, dst:15, id:15, vec1:VECTOR<3,float>([15.117, 16.127, 17.137]), vec2:VECTOR<7,float>([15.217, 16.227, 17.237, 18.247, 19.257, 20.267, 21.277]), vec3:VECTOR<3,float>([15.317, 16.327, 17.337])},
      {src: 716, dst:16, id:16, vec1:VECTOR<3,float>([16.117, 17.127, 18.137]), vec2:VECTOR<7,float>([16.217, 17.227, 18.237, 19.247, 20.257, 21.267, 22.277]), vec3:VECTOR<3,float>([16.317, 17.327, 18.337])},
      {src: 717, dst:17, id:17, vec1:VECTOR<3,float>([17.117, 18.127, 19.137]), vec2:VECTOR<7,float>([17.217, 18.227, 19.237, 20.247, 21.257, 22.267, 23.277]), vec3:VECTOR<3,float>([17.317, 18.327, 19.337])},
      {src: 718, dst:18, id:18, vec1:VECTOR<3,float>([18.117, 19.127, 20.137]), vec2:VECTOR<7,float>([18.217, 19.227, 20.237, 21.247, 22.257, 23.267, 24.277]), vec3:VECTOR<3,float>([18.317, 19.327, 20.337])},
      {src: 719, dst:19, id:19, vec1:VECTOR<3,float>([19.117, 20.127, 21.137]), vec2:VECTOR<7,float>([19.217, 20.227, 21.237, 22.247, 23.257, 24.267, 25.277]), vec3:VECTOR<3,float>([19.317, 20.327, 21.337])}
      use ann_test
      FOR r IN t
      MATCH (n1:N1{id:r.src}), (n2:N2{id:r.dst})
      INSERT (n1)-[@E1{id:r.id,vec1:r.vec1,vec2:r.vec2,vec3:r.vec3}]->(n2)
      """
    Then the execution should be successful
    When executing query:
      """
      BALANCE DATA
      """
    Then the execution should be successful
    When executing query:
      """
      BALANCE LEADER
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test
      MATCH (v:N1|N2) where v.id>=10000
      RETURN v
      """
    Then the result should be, in any order:
      | v                                                                                                  |
      | ({id:10002,vec1:VECTOR [111.0,222.0,333.0],vec2:NULL,vec3:VECTOR [111.0,222.0,332.0]})             |
      | ({id:10000,vec1:VECTOR [10000.0,235.0,3.343],vec2:VECTOR [1.0,2.0,3.0,4.0,5.0,6.0,7.0],vec3:NULL}) |
      | ({id:10001,vec1:VECTOR [111.0,222.0,333.0],vec2:NULL,vec3:VECTOR [111.0,222.0,331.0]})             |
      | ({id:10003,vec1:VECTOR [10000.0,235.0,3.343],vec2:NULL,vec3:NULL})                                 |
      | ({id:10004,vec1:VECTOR [111.0,222.0,334.0],vec2:VECTOR [1.0,2.0,3.0,4.0,5.0,6.0,7.0],vec3:NULL})   |
    When executing query:
      """
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) LIMIT 3
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                       |
      | 1   | VECTOR [1.0, 2.0, 3.0 ]    |
      | 81  | VECTOR [1.08, 2.08, 3.08 ] |
      | 1   | VECTOR [1.1, 2.1, 3.1 ]    |
    When executing query:
      """
      USE ann_test INSERT (@N1{id:888,vec1:VECTOR<3,float>([1.09, 2.09, 3.09]), vec2:VECTOR<7,float>([1.08, 2.08, 3.08, 4.08, 5.08, 6.08,
      7.08]), vec3:VECTOR<3,float>([1.08, 2.08, 3.08])})
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1)
      APPROX LIMIT 3 OPTIONS {nprobe: 8, type:HNSW}
      RETURN v.id as vid, v.vec2 as vec2, euclidean(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec2) as dist
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: Invalid search option for HNSW index type: nprobe"
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1)
      APPROX LIMIT 3 OPTIONS {efSearch: 8, type:IVF}
      RETURN v.id as vid, v.vec2 as vec2, euclidean(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec2) as dist
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: Invalid search option for IVF index type: efSearch"
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1)
      APPROX LIMIT 3 OPTIONS {efSearch: 8}
      RETURN v.id as vid, v.vec2 as vec2, euclidean(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec2) as dist
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: The ANN index type need to be specified in search options"
    When executing query:
      """
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY vector_distance(vector<3, float>([1, 2, 3]), v.vec1) LIMIT 3
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                       |
      | 1   | VECTOR [1.0, 2.0, 3.0 ]    |
      | 81  | VECTOR [1.08, 2.08, 3.08 ] |
      | 888 | VECTOR [1.09, 2.09, 3.09 ] |
    When executing query:
      """
      USE ann_test MATCH (v:N1{id:888}) DELETE v
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY vector_distance(vector<3, float>([1, 2, 3]), v.vec1 euclidean) LIMIT 3
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                       |
      | 1   | VECTOR [1.0, 2.0, 3.0 ]    |
      | 81  | VECTOR [1.08, 2.08, 3.08 ] |
      | 1   | VECTOR [1.1, 2.1, 3.1 ]    |
    # use ann_node_ivf_l2
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) APPROX LIMIT 17 OPTIONS {type:IVF, metric:L2}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                    |
      | 1   | VECTOR [1.0,2.0,3.0]    |
      | 81  | VECTOR [1.08,2.08,3.08] |
      | 1   | VECTOR [1.1,2.1,3.1]    |
      | 91  | VECTOR [1.19,2.19,3.19] |
      | 2   | VECTOR [2.0,3.0,4.0]    |
      | 82  | VECTOR [2.08,3.08,4.08] |
      | 2   | VECTOR [2.1,3.1,4.1]    |
      | 92  | VECTOR [2.19,3.19,4.19] |
      | 3   | VECTOR [3.0,4.0,5.0]    |
      | 83  | VECTOR [3.08,4.08,5.08] |
      | 3   | VECTOR [3.1,4.1,5.1]    |
      | 93  | VECTOR [3.19,4.19,5.19] |
      | 4   | VECTOR [4.0,5.0,6.0]    |
      | 84  | VECTOR [4.08,5.08,6.08] |
      | 4   | VECTOR [4.1,5.1,6.1]    |
      | 94  | VECTOR [4.19,5.19,6.19] |
      | 5   | VECTOR [5.0,6.0,7.0]    |
    When executing query:
      """
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) LIMIT 17
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                    |
      | 1   | VECTOR [1.0,2.0,3.0]    |
      | 81  | VECTOR [1.08,2.08,3.08] |
      | 1   | VECTOR [1.1,2.1,3.1]    |
      | 91  | VECTOR [1.19,2.19,3.19] |
      | 2   | VECTOR [2.0,3.0,4.0]    |
      | 82  | VECTOR [2.08,3.08,4.08] |
      | 2   | VECTOR [2.1,3.1,4.1]    |
      | 92  | VECTOR [2.19,3.19,4.19] |
      | 3   | VECTOR [3.0,4.0,5.0]    |
      | 83  | VECTOR [3.08,4.08,5.08] |
      | 3   | VECTOR [3.1,4.1,5.1]    |
      | 93  | VECTOR [3.19,4.19,5.19] |
      | 4   | VECTOR [4.0,5.0,6.0]    |
      | 84  | VECTOR [4.08,5.08,6.08] |
      | 4   | VECTOR [4.1,5.1,6.1]    |
      | 94  | VECTOR [4.19,5.19,6.19] |
      | 5   | VECTOR [5.0,6.0,7.0]    |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) APPROX LIMIT 17 OPTIONS {type:IVF, metric:L2}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                     |
      | 1   | VECTOR [1.0,2.0,3.0]     |
      | 81  | VECTOR [1.08,2.08,3.08]  |
      | 2   | VECTOR [2.0,3.0,4.0]     |
      | 82  | VECTOR [2.08,3.08,4.08]  |
      | 3   | VECTOR [3.0,4.0,5.0]     |
      | 83  | VECTOR [3.08,4.08,5.08]  |
      | 4   | VECTOR [4.0,5.0,6.0]     |
      | 84  | VECTOR [4.08,5.08,6.08]  |
      | 5   | VECTOR [5.0,6.0,7.0]     |
      | 85  | VECTOR [5.08,6.08,7.08]  |
      | 6   | VECTOR [6.0,7.0,8.0]     |
      | 86  | VECTOR [6.08,7.08,8.08]  |
      | 7   | VECTOR [7.0,8.0,9.0]     |
      | 87  | VECTOR [7.08,8.08,9.08]  |
      | 8   | VECTOR [8.0,9.0,10.0]    |
      | 88  | VECTOR [8.08,9.08,10.08] |
      | 9   | VECTOR [9.0,10.0,11.0]   |
    When executing query:
      """
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) LIMIT 17
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                     |
      | 1   | VECTOR [1.0,2.0,3.0]     |
      | 81  | VECTOR [1.08,2.08,3.08]  |
      | 2   | VECTOR [2.0,3.0,4.0]     |
      | 82  | VECTOR [2.08,3.08,4.08]  |
      | 3   | VECTOR [3.0,4.0,5.0]     |
      | 83  | VECTOR [3.08,4.08,5.08]  |
      | 4   | VECTOR [4.0,5.0,6.0]     |
      | 84  | VECTOR [4.08,5.08,6.08]  |
      | 5   | VECTOR [5.0,6.0,7.0]     |
      | 85  | VECTOR [5.08,6.08,7.08]  |
      | 6   | VECTOR [6.0,7.0,8.0]     |
      | 86  | VECTOR [6.08,7.08,8.08]  |
      | 7   | VECTOR [7.0,8.0,9.0]     |
      | 87  | VECTOR [7.08,8.08,9.08]  |
      | 8   | VECTOR [8.0,9.0,10.0]    |
      | 88  | VECTOR [8.08,9.08,10.08] |
      | 9   | VECTOR [9.0,10.0,11.0]   |
    # use ann_node_ivf_l2
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) APPROX LIMIT 17 OPTIONS {type:IVF, metric:L2, nprobe:8}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                    |
      | 1   | VECTOR [1.0,2.0,3.0]    |
      | 81  | VECTOR [1.08,2.08,3.08] |
      | 1   | VECTOR [1.1,2.1,3.1]    |
      | 91  | VECTOR [1.19,2.19,3.19] |
      | 2   | VECTOR [2.0,3.0,4.0]    |
      | 82  | VECTOR [2.08,3.08,4.08] |
      | 2   | VECTOR [2.1,3.1,4.1]    |
      | 92  | VECTOR [2.19,3.19,4.19] |
      | 3   | VECTOR [3.0,4.0,5.0]    |
      | 83  | VECTOR [3.08,4.08,5.08] |
      | 3   | VECTOR [3.1,4.1,5.1]    |
      | 93  | VECTOR [3.19,4.19,5.19] |
      | 4   | VECTOR [4.0,5.0,6.0]    |
      | 84  | VECTOR [4.08,5.08,6.08] |
      | 4   | VECTOR [4.1,5.1,6.1]    |
      | 94  | VECTOR [4.19,5.19,6.19] |
      | 5   | VECTOR [5.0,6.0,7.0]    |
    When executing query:
      """
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) LIMIT 17
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                    |
      | 1   | VECTOR [1.0,2.0,3.0]    |
      | 81  | VECTOR [1.08,2.08,3.08] |
      | 1   | VECTOR [1.1,2.1,3.1]    |
      | 91  | VECTOR [1.19,2.19,3.19] |
      | 2   | VECTOR [2.0,3.0,4.0]    |
      | 82  | VECTOR [2.08,3.08,4.08] |
      | 2   | VECTOR [2.1,3.1,4.1]    |
      | 92  | VECTOR [2.19,3.19,4.19] |
      | 3   | VECTOR [3.0,4.0,5.0]    |
      | 83  | VECTOR [3.08,4.08,5.08] |
      | 3   | VECTOR [3.1,4.1,5.1]    |
      | 93  | VECTOR [3.19,4.19,5.19] |
      | 4   | VECTOR [4.0,5.0,6.0]    |
      | 84  | VECTOR [4.08,5.08,6.08] |
      | 4   | VECTOR [4.1,5.1,6.1]    |
      | 94  | VECTOR [4.19,5.19,6.19] |
      | 5   | VECTOR [5.0,6.0,7.0]    |
    # use ann_node_hnsw_l2
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) APPROX LIMIT 17 OPTIONS {type:HNSW, metric:L2, efSearch:8}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                    |
      | 1   | VECTOR [1.0,2.0,3.0]    |
      | 81  | VECTOR [1.08,2.08,3.08] |
      | 1   | VECTOR [1.1,2.1,3.1]    |
      | 91  | VECTOR [1.19,2.19,3.19] |
      | 2   | VECTOR [2.0,3.0,4.0]    |
      | 82  | VECTOR [2.08,3.08,4.08] |
      | 2   | VECTOR [2.1,3.1,4.1]    |
      | 92  | VECTOR [2.19,3.19,4.19] |
      | 3   | VECTOR [3.0,4.0,5.0]    |
      | 83  | VECTOR [3.08,4.08,5.08] |
      | 3   | VECTOR [3.1,4.1,5.1]    |
      | 93  | VECTOR [3.19,4.19,5.19] |
      | 4   | VECTOR [4.0,5.0,6.0]    |
      | 84  | VECTOR [4.08,5.08,6.08] |
      | 4   | VECTOR [4.1,5.1,6.1]    |
      | 94  | VECTOR [4.19,5.19,6.19] |
      | 5   | VECTOR [5.0,6.0,7.0]    |
    # use ann_node_ivf_ip
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), v.vec1) DESC LIMIT APPROX 33 OPTIONS {type:IVF, metric:IP, nprobe:8}
      RETURN v.id as vid, v.vec1 as vec1, round(vector_distance(vector<3, float>([1, 2, 3]), v.vec1 DOT)) as dist
      """
    Then the result should contain:
      | vid   | vec1                         | dist    |
      # FIXME(czp): miss high rank result
      # | 10003 | VECTOR [10000.0,235.0,3.343] | 10480.0 |
      | 10000 | VECTOR [10000.0,235.0,3.343] | 10480.0 |
      | 10004 | VECTOR [111.0,222.0,334.0]   | 1557.0  |
      | 10002 | VECTOR [111.0,222.0,332.0]   | 1551.0  |
      | 10001 | VECTOR [111.0,222.0,331.0]   | 1548.0  |
      | 27    | VECTOR [27.0,28.0,29.0]      | 170.0   |
      | 26    | VECTOR [26.0,27.0,28.0]      | 164.0   |
      | 25    | VECTOR [25.0,26.0,27.0]      | 158.0   |
      | 24    | VECTOR [24.0,25.0,26.0]      | 152.0   |
      | 23    | VECTOR [23.0,24.0,25.0]      | 146.0   |
      | 22    | VECTOR [22.0,23.0,24.0]      | 140.0   |
      | 21    | VECTOR [21.0,22.0,23.0]      | 134.0   |
      | 20    | VECTOR [20.0,21.0,22.0]      | 128.0   |
      | 919   | VECTOR [19.19,20.19,21.19]   | 123.0   |
      | 19    | VECTOR [19.1,20.1,21.1]      | 123.0   |
      | 819   | VECTOR [19.08,20.08,21.08]   | 122.0   |
      | 19    | VECTOR [19.0,20.0,21.0]      | 122.0   |
      | 918   | VECTOR [18.19,19.19,20.19]   | 117.0   |
      | 18    | VECTOR [18.1,19.1,20.1]      | 117.0   |
      | 818   | VECTOR [18.08,19.08,20.08]   | 116.0   |
      | 18    | VECTOR [18.0,19.0,20.0]      | 116.0   |
      | 917   | VECTOR [17.19,18.19,19.19]   | 111.0   |
      | 17    | VECTOR [17.1,18.1,19.1]      | 111.0   |
      | 817   | VECTOR [17.08,18.08,19.08]   | 110.0   |
      | 17    | VECTOR [17.0,18.0,19.0]      | 110.0   |
      | 916   | VECTOR [16.19,17.19,18.19]   | 105.0   |
      | 16    | VECTOR [16.1,17.1,18.1]      | 105.0   |
      | 816   | VECTOR [16.08,17.08,18.08]   | 104.0   |
      | 16    | VECTOR [16.0,17.0,18.0]      | 104.0   |
      | 915   | VECTOR [15.19,16.19,17.19]   | 99.0    |
      | 15    | VECTOR [15.1,16.1,17.1]      | 99.0    |
      | 815   | VECTOR [15.08,16.08,17.08]   | 98.0    |
      | 15    | VECTOR [15.0,16.0,17.0]      | 98.0    |
    When executing query:
      """
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), v.vec1) DESC LIMIT 33
      RETURN v.id as vid, v.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), v.vec1)) as dist
      """
    Then the result should be, in any order:
      | vid   | vec1                         | dist    |
      | 10003 | VECTOR [10000.0,235.0,3.343] | 10480.0 |
      | 10000 | VECTOR [10000.0,235.0,3.343] | 10480.0 |
      | 10004 | VECTOR [111.0,222.0,334.0]   | 1557.0  |
      | 10002 | VECTOR [111.0,222.0,332.0]   | 1551.0  |
      | 10001 | VECTOR [111.0,222.0,331.0]   | 1548.0  |
      | 27    | VECTOR [27.0,28.0,29.0]      | 170.0   |
      | 26    | VECTOR [26.0,27.0,28.0]      | 164.0   |
      | 25    | VECTOR [25.0,26.0,27.0]      | 158.0   |
      | 24    | VECTOR [24.0,25.0,26.0]      | 152.0   |
      | 23    | VECTOR [23.0,24.0,25.0]      | 146.0   |
      | 22    | VECTOR [22.0,23.0,24.0]      | 140.0   |
      | 21    | VECTOR [21.0,22.0,23.0]      | 134.0   |
      | 20    | VECTOR [20.0,21.0,22.0]      | 128.0   |
      | 919   | VECTOR [19.19,20.19,21.19]   | 123.0   |
      | 19    | VECTOR [19.1,20.1,21.1]      | 123.0   |
      | 819   | VECTOR [19.08,20.08,21.08]   | 122.0   |
      | 19    | VECTOR [19.0,20.0,21.0]      | 122.0   |
      | 918   | VECTOR [18.19,19.19,20.19]   | 117.0   |
      | 18    | VECTOR [18.1,19.1,20.1]      | 117.0   |
      | 818   | VECTOR [18.08,19.08,20.08]   | 116.0   |
      | 18    | VECTOR [18.0,19.0,20.0]      | 116.0   |
      | 917   | VECTOR [17.19,18.19,19.19]   | 111.0   |
      | 17    | VECTOR [17.1,18.1,19.1]      | 111.0   |
      | 817   | VECTOR [17.08,18.08,19.08]   | 110.0   |
      | 17    | VECTOR [17.0,18.0,19.0]      | 110.0   |
      | 916   | VECTOR [16.19,17.19,18.19]   | 105.0   |
      | 16    | VECTOR [16.1,17.1,18.1]      | 105.0   |
      | 816   | VECTOR [16.08,17.08,18.08]   | 104.0   |
      | 16    | VECTOR [16.0,17.0,18.0]      | 104.0   |
      | 915   | VECTOR [15.19,16.19,17.19]   | 99.0    |
      | 15    | VECTOR [15.1,16.1,17.1]      | 99.0    |
      | 815   | VECTOR [15.08,16.08,17.08]   | 98.0    |
      | 15    | VECTOR [15.0,16.0,17.0]      | 98.0    |
    # use ann_node_hnsw_ip
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), v.vec1) DESC APPROX LIMIT 33 OPTIONS {type:HNSW, metric:IP, efSearch:8}
      RETURN v.id as vid, v.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), v.vec1)) as dist
      """
    Then the result should be, in any order:
      | vid   | vec1                         | dist    |
      | 10003 | VECTOR [10000.0,235.0,3.343] | 10480.0 |
      | 10000 | VECTOR [10000.0,235.0,3.343] | 10480.0 |
      | 10004 | VECTOR [111.0,222.0,334.0]   | 1557.0  |
      | 10002 | VECTOR [111.0,222.0,332.0]   | 1551.0  |
      | 10001 | VECTOR [111.0,222.0,331.0]   | 1548.0  |
      | 27    | VECTOR [27.0,28.0,29.0]      | 170.0   |
      | 26    | VECTOR [26.0,27.0,28.0]      | 164.0   |
      | 25    | VECTOR [25.0,26.0,27.0]      | 158.0   |
      | 24    | VECTOR [24.0,25.0,26.0]      | 152.0   |
      | 23    | VECTOR [23.0,24.0,25.0]      | 146.0   |
      | 22    | VECTOR [22.0,23.0,24.0]      | 140.0   |
      | 21    | VECTOR [21.0,22.0,23.0]      | 134.0   |
      | 20    | VECTOR [20.0,21.0,22.0]      | 128.0   |
      | 919   | VECTOR [19.19,20.19,21.19]   | 123.0   |
      | 19    | VECTOR [19.1,20.1,21.1]      | 123.0   |
      | 819   | VECTOR [19.08,20.08,21.08]   | 122.0   |
      | 19    | VECTOR [19.0,20.0,21.0]      | 122.0   |
      | 918   | VECTOR [18.19,19.19,20.19]   | 117.0   |
      | 18    | VECTOR [18.1,19.1,20.1]      | 117.0   |
      | 818   | VECTOR [18.08,19.08,20.08]   | 116.0   |
      | 18    | VECTOR [18.0,19.0,20.0]      | 116.0   |
      | 917   | VECTOR [17.19,18.19,19.19]   | 111.0   |
      | 17    | VECTOR [17.1,18.1,19.1]      | 111.0   |
      | 817   | VECTOR [17.08,18.08,19.08]   | 110.0   |
      | 17    | VECTOR [17.0,18.0,19.0]      | 110.0   |
      | 916   | VECTOR [16.19,17.19,18.19]   | 105.0   |
      | 16    | VECTOR [16.1,17.1,18.1]      | 105.0   |
      | 816   | VECTOR [16.08,17.08,18.08]   | 104.0   |
      | 16    | VECTOR [16.0,17.0,18.0]      | 104.0   |
      | 915   | VECTOR [15.19,16.19,17.19]   | 99.0    |
      | 15    | VECTOR [15.1,16.1,17.1]      | 99.0    |
      | 815   | VECTOR [15.08,16.08,17.08]   | 98.0    |
      | 15    | VECTOR [15.0,16.0,17.0]      | 98.0    |
    # use ann_edge_ivf_l2
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), e.vec1) APPROX LIMIT 17 OPTIONS {type:IVF, metric:L2, nprobe:16}
      RETURN e.id as vid, e.vec1 as vec1, round(euclidean(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in order:
      | vid | vec1                       | dist |
      | 1   | VECTOR [1.11,2.12,3.13]    | 0.0  |
      | 2   | VECTOR [2.11,3.12,4.13]    | 2.0  |
      | 3   | VECTOR [3.11,4.12,5.13]    | 4.0  |
      | 4   | VECTOR [4.11,5.12,6.13]    | 5.0  |
      | 5   | VECTOR [5.11,6.12,7.13]    | 7.0  |
      | 6   | VECTOR [6.11,7.12,8.13]    | 9.0  |
      | 7   | VECTOR [7.11,8.12,9.13]    | 11.0 |
      | 8   | VECTOR [8.11,9.12,10.13]   | 12.0 |
      | 9   | VECTOR [9.11,10.12,11.13]  | 14.0 |
      | 10  | VECTOR [10.11,11.12,12.13] | 16.0 |
      | 11  | VECTOR [11.11,12.12,13.13] | 18.0 |
      | 12  | VECTOR [12.11,13.12,14.13] | 19.0 |
      | 13  | VECTOR [13.11,14.12,15.13] | 21.0 |
      | 14  | VECTOR [14.11,15.12,16.13] | 23.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 24.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 26.0 |
      | 17  | VECTOR [17.11,18.12,19.13] | 28.0 |
    When executing query:
      """
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), e.vec1) LIMIT 17
      RETURN e.id as vid, e.vec1 as vec1, round(euclidean(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in order:
      | vid | vec1                       | dist |
      | 1   | VECTOR [1.11,2.12,3.13]    | 0.0  |
      | 2   | VECTOR [2.11,3.12,4.13]    | 2.0  |
      | 3   | VECTOR [3.11,4.12,5.13]    | 4.0  |
      | 4   | VECTOR [4.11,5.12,6.13]    | 5.0  |
      | 5   | VECTOR [5.11,6.12,7.13]    | 7.0  |
      | 6   | VECTOR [6.11,7.12,8.13]    | 9.0  |
      | 7   | VECTOR [7.11,8.12,9.13]    | 11.0 |
      | 8   | VECTOR [8.11,9.12,10.13]   | 12.0 |
      | 9   | VECTOR [9.11,10.12,11.13]  | 14.0 |
      | 10  | VECTOR [10.11,11.12,12.13] | 16.0 |
      | 11  | VECTOR [11.11,12.12,13.13] | 18.0 |
      | 12  | VECTOR [12.11,13.12,14.13] | 19.0 |
      | 13  | VECTOR [13.11,14.12,15.13] | 21.0 |
      | 14  | VECTOR [14.11,15.12,16.13] | 23.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 24.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 26.0 |
      | 17  | VECTOR [17.11,18.12,19.13] | 28.0 |
    # use ann_edge_hnsw_l2
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), e.vec1) ASC APPROX LIMIT 17 OPTIONS {type:HNSW, metric:L2, efSearch:16}
      RETURN e.id as vid, e.vec1 as vec1, round(euclidean(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in any order:
      | vid | vec1                       | dist |
      | 1   | VECTOR [1.11,2.12,3.13]    | 0.0  |
      | 2   | VECTOR [2.11,3.12,4.13]    | 2.0  |
      | 3   | VECTOR [3.11,4.12,5.13]    | 4.0  |
      | 4   | VECTOR [4.11,5.12,6.13]    | 5.0  |
      | 5   | VECTOR [5.11,6.12,7.13]    | 7.0  |
      | 6   | VECTOR [6.11,7.12,8.13]    | 9.0  |
      | 7   | VECTOR [7.11,8.12,9.13]    | 11.0 |
      | 8   | VECTOR [8.11,9.12,10.13]   | 12.0 |
      | 9   | VECTOR [9.11,10.12,11.13]  | 14.0 |
      | 10  | VECTOR [10.11,11.12,12.13] | 16.0 |
      | 11  | VECTOR [11.11,12.12,13.13] | 18.0 |
      | 12  | VECTOR [12.11,13.12,14.13] | 19.0 |
      | 13  | VECTOR [13.11,14.12,15.13] | 21.0 |
      | 14  | VECTOR [14.11,15.12,16.13] | 23.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 24.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 26.0 |
      | 17  | VECTOR [17.11,18.12,19.13] | 28.0 |
    # use ann_edge_ivf_ip
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), e.vec1) DESC APPROX LIMIT 17 OPTIONS {type:IVF, metric:IP, nprobe:16}
      RETURN e.id as vid, e.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in order:
      | vid | vec1                       | dist  |
      | 27  | VECTOR [27.11,28.12,29.13] | 171.0 |
      | 26  | VECTOR [26.11,27.12,28.13] | 165.0 |
      | 25  | VECTOR [25.11,26.12,27.13] | 159.0 |
      | 24  | VECTOR [24.11,25.12,26.13] | 153.0 |
      | 23  | VECTOR [23.11,24.12,25.13] | 147.0 |
      | 22  | VECTOR [22.11,23.12,24.13] | 141.0 |
      | 21  | VECTOR [21.11,22.12,23.13] | 135.0 |
      | 20  | VECTOR [20.11,21.12,22.13] | 129.0 |
      | 19  | VECTOR [19.11,20.12,21.13] | 123.0 |
      | 18  | VECTOR [18.11,19.12,20.13] | 117.0 |
      | 17  | VECTOR [17.11,18.12,19.13] | 111.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 105.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 99.0  |
      | 14  | VECTOR [14.11,15.12,16.13] | 93.0  |
      | 13  | VECTOR [13.11,14.12,15.13] | 87.0  |
      | 12  | VECTOR [12.11,13.12,14.13] | 81.0  |
      | 11  | VECTOR [11.11,12.12,13.13] | 75.0  |
    When executing query:
      """
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), e.vec1) DESC LIMIT 17
      RETURN e.id as vid, e.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in order:
      | vid | vec1                       | dist  |
      | 27  | VECTOR [27.11,28.12,29.13] | 171.0 |
      | 26  | VECTOR [26.11,27.12,28.13] | 165.0 |
      | 25  | VECTOR [25.11,26.12,27.13] | 159.0 |
      | 24  | VECTOR [24.11,25.12,26.13] | 153.0 |
      | 23  | VECTOR [23.11,24.12,25.13] | 147.0 |
      | 22  | VECTOR [22.11,23.12,24.13] | 141.0 |
      | 21  | VECTOR [21.11,22.12,23.13] | 135.0 |
      | 20  | VECTOR [20.11,21.12,22.13] | 129.0 |
      | 19  | VECTOR [19.11,20.12,21.13] | 123.0 |
      | 18  | VECTOR [18.11,19.12,20.13] | 117.0 |
      | 17  | VECTOR [17.11,18.12,19.13] | 111.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 105.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 99.0  |
      | 14  | VECTOR [14.11,15.12,16.13] | 93.0  |
      | 13  | VECTOR [13.11,14.12,15.13] | 87.0  |
      | 12  | VECTOR [12.11,13.12,14.13] | 81.0  |
      | 11  | VECTOR [11.11,12.12,13.13] | 75.0  |
    # use ann_edge_hnsw_ip
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), e.vec1) DESC APPROX LIMIT 17 OPTIONS {type:HNSW, metric:IP, efSearch:16}
      RETURN e.id as vid, e.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in order:
      | vid | vec1                       | dist  |
      | 27  | VECTOR [27.11,28.12,29.13] | 171.0 |
      | 26  | VECTOR [26.11,27.12,28.13] | 165.0 |
      | 25  | VECTOR [25.11,26.12,27.13] | 159.0 |
      | 24  | VECTOR [24.11,25.12,26.13] | 153.0 |
      | 23  | VECTOR [23.11,24.12,25.13] | 147.0 |
      | 22  | VECTOR [22.11,23.12,24.13] | 141.0 |
      | 21  | VECTOR [21.11,22.12,23.13] | 135.0 |
      | 20  | VECTOR [20.11,21.12,22.13] | 129.0 |
      | 19  | VECTOR [19.11,20.12,21.13] | 123.0 |
      | 18  | VECTOR [18.11,19.12,20.13] | 117.0 |
      | 17  | VECTOR [17.11,18.12,19.13] | 111.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 105.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 99.0  |
      | 14  | VECTOR [14.11,15.12,16.13] | 93.0  |
      | 13  | VECTOR [13.11,14.12,15.13] | 87.0  |
      | 12  | VECTOR [12.11,13.12,14.13] | 81.0  |
      | 11  | VECTOR [11.11,12.12,13.13] | 75.0  |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1)
      APPROX LIMIT 17 OPTIONS {type:IVF, metric:L2, nprobe: 8}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                     |
      | 1   | VECTOR [1.0,2.0,3.0]     |
      | 81  | VECTOR [1.08,2.08,3.08]  |
      | 2   | VECTOR [2.0,3.0,4.0]     |
      | 82  | VECTOR [2.08,3.08,4.08]  |
      | 3   | VECTOR [3.0,4.0,5.0]     |
      | 83  | VECTOR [3.08,4.08,5.08]  |
      | 4   | VECTOR [4.0,5.0,6.0]     |
      | 84  | VECTOR [4.08,5.08,6.08]  |
      | 5   | VECTOR [5.0,6.0,7.0]     |
      | 85  | VECTOR [5.08,6.08,7.08]  |
      | 6   | VECTOR [6.0,7.0,8.0]     |
      | 86  | VECTOR [6.08,7.08,8.08]  |
      | 7   | VECTOR [7.0,8.0,9.0]     |
      | 87  | VECTOR [7.08,8.08,9.08]  |
      | 8   | VECTOR [8.0,9.0,10.0]    |
      | 88  | VECTOR [8.08,9.08,10.08] |
      | 9   | VECTOR [9.0,10.0,11.0]   |
    When executing query:
      """
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) LIMIT 17
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                     |
      | 1   | VECTOR [1.0,2.0,3.0]     |
      | 81  | VECTOR [1.08,2.08,3.08]  |
      | 2   | VECTOR [2.0,3.0,4.0]     |
      | 82  | VECTOR [2.08,3.08,4.08]  |
      | 3   | VECTOR [3.0,4.0,5.0]     |
      | 83  | VECTOR [3.08,4.08,5.08]  |
      | 4   | VECTOR [4.0,5.0,6.0]     |
      | 84  | VECTOR [4.08,5.08,6.08]  |
      | 5   | VECTOR [5.0,6.0,7.0]     |
      | 85  | VECTOR [5.08,6.08,7.08]  |
      | 6   | VECTOR [6.0,7.0,8.0]     |
      | 86  | VECTOR [6.08,7.08,8.08]  |
      | 7   | VECTOR [7.0,8.0,9.0]     |
      | 87  | VECTOR [7.08,8.08,9.08]  |
      | 8   | VECTOR [8.0,9.0,10.0]    |
      | 88  | VECTOR [8.08,9.08,10.08] |
      | 9   | VECTOR [9.0,10.0,11.0]   |
    # The query below return empty result, this is an known issue,
    # ann cannot work well with scalar filter now
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1)
      WHERE v.id = 26
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) APPROX LIMIT 1 OPTIONS {type:IVF}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH ()-[e:E1]->()
      ORDER BY euclidean(vector<3, float>([2.11,3.12,4.13]), e.vec1)
      APPROX LIMIT 17 OPTIONS {type:HNSW, metric:L2, efSearch:16}
      RETURN e.id as eid, e.vec1 as vec1
      """
    Then the result should be, in any order:
      | eid | vec1                       |
      | 2   | VECTOR [2.11,3.12,4.13]    |
      | 1   | VECTOR [1.11,2.12,3.13]    |
      | 3   | VECTOR [3.11,4.12,5.13]    |
      | 4   | VECTOR [4.11,5.12,6.13]    |
      | 5   | VECTOR [5.11,6.12,7.13]    |
      | 6   | VECTOR [6.11,7.12,8.13]    |
      | 7   | VECTOR [7.11,8.12,9.13]    |
      | 8   | VECTOR [8.11,9.12,10.13]   |
      | 9   | VECTOR [9.11,10.12,11.13]  |
      | 10  | VECTOR [10.11,11.12,12.13] |
      | 11  | VECTOR [11.11,12.12,13.13] |
      | 12  | VECTOR [12.11,13.12,14.13] |
      | 13  | VECTOR [13.11,14.12,15.13] |
      | 14  | VECTOR [14.11,15.12,16.13] |
      | 15  | VECTOR [15.11,16.12,17.13] |
      | 16  | VECTOR [16.11,17.12,18.13] |
      | 17  | VECTOR [17.11,18.12,19.13] |
    When executing query:
      """
      USE ann_test
      MATCH ()-[e:E1]->()
      ORDER BY euclidean(vector<3, float>([2.11,3.12,4.13]), e.vec1) LIMIT 17
      RETURN e.id as eid, e.vec1 as vec1
      """
    Then the result should be, in any order:
      | eid | vec1                       |
      | 2   | VECTOR [2.11,3.12,4.13]    |
      | 1   | VECTOR [1.11,2.12,3.13]    |
      | 3   | VECTOR [3.11,4.12,5.13]    |
      | 4   | VECTOR [4.11,5.12,6.13]    |
      | 5   | VECTOR [5.11,6.12,7.13]    |
      | 6   | VECTOR [6.11,7.12,8.13]    |
      | 7   | VECTOR [7.11,8.12,9.13]    |
      | 8   | VECTOR [8.11,9.12,10.13]   |
      | 9   | VECTOR [9.11,10.12,11.13]  |
      | 10  | VECTOR [10.11,11.12,12.13] |
      | 11  | VECTOR [11.11,12.12,13.13] |
      | 12  | VECTOR [12.11,13.12,14.13] |
      | 13  | VECTOR [13.11,14.12,15.13] |
      | 14  | VECTOR [14.11,15.12,16.13] |
      | 15  | VECTOR [15.11,16.12,17.13] |
      | 16  | VECTOR [16.11,17.12,18.13] |
      | 17  | VECTOR [17.11,18.12,19.13] |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH ()-[e:E1]->()
      ORDER BY euclidean(vector<3, float>([2.11,3.12,4.13]), e.vec1)
      APPROX LIMIT 17 OPTIONS {type:IVF, nprobe: 8}
      RETURN e.id as eid, e.vec1 as vec1
      """
    Then the result should be, in any order:
      | eid | vec1                       |
      | 2   | VECTOR [2.11,3.12,4.13]    |
      | 1   | VECTOR [1.11,2.12,3.13]    |
      | 3   | VECTOR [3.11,4.12,5.13]    |
      | 4   | VECTOR [4.11,5.12,6.13]    |
      | 5   | VECTOR [5.11,6.12,7.13]    |
      | 6   | VECTOR [6.11,7.12,8.13]    |
      | 7   | VECTOR [7.11,8.12,9.13]    |
      | 8   | VECTOR [8.11,9.12,10.13]   |
      | 9   | VECTOR [9.11,10.12,11.13]  |
      | 10  | VECTOR [10.11,11.12,12.13] |
      | 11  | VECTOR [11.11,12.12,13.13] |
      | 12  | VECTOR [12.11,13.12,14.13] |
      | 13  | VECTOR [13.11,14.12,15.13] |
      | 14  | VECTOR [14.11,15.12,16.13] |
      | 15  | VECTOR [15.11,16.12,17.13] |
      | 16  | VECTOR [16.11,17.12,18.13] |
      | 17  | VECTOR [17.11,18.12,19.13] |
    When executing query:
      """
      TABLE t {id, vec1, vec2, vec3} =
      {id:81, vec1:VECTOR<3,float>([1.8, 2.48, 9.58]), vec2:VECTOR<7,float>([1.08, 2.28, 3.08, 7.38, 5.08, 6.08, 7.08]), vec3:VECTOR<3,float>([1.18, 6.28, 4.38])},
      {id:81, vec1:VECTOR<3,float>([1.08, 2.48, 3.58]), vec2:VECTOR<7,float>([1.08, 2.28, 3.08, 4.38, 5.08, 6.08, 7.08]), vec3:VECTOR<3,float>([1.18, 2.28, 3.38])}
      use ann_test
      FOR r IN t
      INSERT OR REPLACE (@N1{id:r.id,vec1:r.vec1,vec2:r.vec2,vec3:r.vec3})
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) APPROX LIMIT 3 OPTIONS {type:IVF, metric:L2}
      RETURN v.id as vid, v.vec1 as vec1, v.vec2 as vec2, v.vec3 as vec3
      """
    Then the result should be, in order:
      | vid | vec1                    | vec2                                        | vec3                    |
      | 1   | VECTOR [1.0,2.0,3.0]    | VECTOR [1.0,2.0,3.0,4.0,5.0,6.0,7.0]        | VECTOR [1.0,2.0,3.0]    |
      | 81  | VECTOR [1.08,2.48,3.58] | VECTOR [1.08,2.28,3.08,4.38,5.08,6.08,7.08] | VECTOR [1.18,2.28,3.38] |
      | 2   | VECTOR [2.0,3.0,4.0]    | VECTOR [2.0,3.0,4.0,5.0,6.0,7.0,8.0]        | VECTOR [2.0,3.0,4.0]    |
    When executing query:
      """
      use ann_test
      INSERT OR UPDATE (@N1{id:81, vec1:VECTOR<3,float>([111.2, 222.0, 333.0]), vec2:VECTOR<7,float>([31., 32., 33., 4., 5, 6., 7.]), vec3:VECTOR<3,float>([5445.00, 238.000, 3.38])})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test
      MATCH (v:N1 {id:81})
      RETURN v.id as vid, v.vec1 as vec1, v.vec2 as vec2, v.vec3 as vec3
      """
    Then the result should be, in order:
      | vid | vec1                       | vec2                                    | vec3                       |
      | 81  | VECTOR [111.2,222.0,333.0] | VECTOR [31.0,32.0,33.0,4.0,5.0,6.0,7.0] | VECTOR [5445.0,238.0,3.38] |
    When executing query:
      """
      use ann_test
      INSERT OR UPDATE (@N1{id:81, vec1:VECTOR<3,float>([1.18, 2.18, 3.18]), vec2:VECTOR<7,float>([1.28, 2.28, 3.28, 4.28, 5.28, 6.28, 7.28]), vec3:VECTOR<3,float>([1.38, 2.38, 3.38])})
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) APPROX LIMIT 3 OPTIONS {type:IVF}
      RETURN v.id as vid, v.vec1 as vec1, v.vec2 as vec2, v.vec3 as vec3
      """
    Then the result should be, in order:
      | vid | vec1                    | vec2                                        | vec3                    |
      | 1   | VECTOR [1.0,2.0,3.0]    | VECTOR [1.0,2.0,3.0,4.0,5.0,6.0,7.0]        | VECTOR [1.0,2.0,3.0]    |
      | 81  | VECTOR [1.18,2.18,3.18] | VECTOR [1.28,2.28,3.28,4.28,5.28,6.28,7.28] | VECTOR [1.38,2.38,3.38] |
      | 2   | VECTOR [2.0,3.0,4.0]    | VECTOR [2.0,3.0,4.0,5.0,6.0,7.0,8.0]        | VECTOR [2.0,3.0,4.0]    |
    When executing query:
      """
      use ann_test
      MATCH (v:N1)
      WHERE v.id = 81
      SET v.vec1 = VECTOR<3,float>([1.08, 2.48, 3.58]),v.vec2=VECTOR<7,float>([1.08, 2.28, 3.08, 4.38, 5.08, 6.08, 7.08]),v.vec3=VECTOR<3,float>([1.18, 2.28, 3.38])
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) APPROX LIMIT 3 OPTIONS {type:IVF}
      RETURN v.id as vid, v.vec1 as vec1, v.vec2 as vec2, v.vec3 as vec3
      """
    Then the result should be, in order:
      | vid | vec1                    | vec2                                        | vec3                    |
      | 1   | VECTOR [1.0,2.0,3.0]    | VECTOR [1.0,2.0,3.0,4.0,5.0,6.0,7.0]        | VECTOR [1.0,2.0,3.0]    |
      | 81  | VECTOR [1.08,2.48,3.58] | VECTOR [1.08,2.28,3.08,4.38,5.08,6.08,7.08] | VECTOR [1.18,2.28,3.38] |
      | 2   | VECTOR [2.0,3.0,4.0]    | VECTOR [2.0,3.0,4.0,5.0,6.0,7.0,8.0]        | VECTOR [2.0,3.0,4.0]    |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH ()-[e:E1]->()
      ORDER BY euclidean(vector<3, float>([2.11,3.12,4.13]), e.vec1)
      APPROX LIMIT 3 OPTIONS {type:IVF}
      RETURN e.id as eid, e.vec1 as vec1, e.vec2 as vec2, e.vec3 as vec3
      """
    Then the result should be, in any order:
      | eid | vec1                    | vec2                                        | vec3                    |
      | 2   | VECTOR [2.11,3.12,4.13] | VECTOR [2.21,3.22,4.23,5.24,6.25,7.26,8.27] | VECTOR [2.31,3.32,4.33] |
      | 1   | VECTOR [1.11,2.12,3.13] | VECTOR [1.21,2.22,3.23,4.24,5.25,6.26,7.27] | VECTOR [1.31,2.32,3.33] |
      | 3   | VECTOR [3.11,4.12,5.13] | VECTOR [3.21,4.22,5.23,6.24,7.25,8.26,9.27] | VECTOR [3.31,4.32,5.33] |
    When executing query:
      """
      use ann_test
      MATCH ()-[e:E1]-()
      WHERE e.id = 2
      SET e.vec1 = VECTOR<3,float>([1.08, 2.48, 3.58]),e.vec2=VECTOR<7,float>([1.08, 2.28, 3.08, 4.38, 5.08, 6.08, 7.08]),e.vec3=VECTOR<3,float>([1.18, 2.28, 3.38])
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH ()-[e:E1]->()
      ORDER BY euclidean(vector<3, float>([2.11,3.12,4.13]), e.vec1)
      APPROX LIMIT 3 OPTIONS {type:IVF}
      RETURN e.id as eid, e.vec1 as vec1, e.vec2 as vec2, e.vec3 as vec3
      """
    Then the result should be, in any order:
      | eid | vec1                    | vec2                                        | vec3                    |
      | 2   | VECTOR [1.08,2.48,3.58] | VECTOR [1.08,2.28,3.08,4.38,5.08,6.08,7.08] | VECTOR [1.18,2.28,3.38] |
      | 3   | VECTOR [3.11,4.12,5.13] | VECTOR [3.21,4.22,5.23,6.24,7.25,8.26,9.27] | VECTOR [3.31,4.32,5.33] |
      | 1   | VECTOR [1.11,2.12,3.13] | VECTOR [1.21,2.22,3.23,4.24,5.25,6.26,7.27] | VECTOR [1.31,2.32,3.33] |
    When executing query:
      """
      USE ann_test
      MATCH ()-[e:E1]->()
      ORDER BY euclidean(null, e.vec1)
      APPROX LIMIT 3 OPTIONS {type:IVF}
      RETURN euclidean(null, e.vec1) as dist
      """
    Then the result should be, in any order:
      | dist |
      | NULL |
      | NULL |
      | NULL |
    When executing query:
      """
      USE ann_test
      INSERT OR UPDATE
      (:N1{id:4,vec1:VECTOR<3,float>([0,0,0])})-[@E1{id:4,vec1:VECTOR<3,float>([2.11,3.12,4.13]), vec2:VECTOR<7,float>([4.21, 5.22, 6.23, 7.24, 8.25, 9.26, 10.27]), vec3:VECTOR<3,float>([4.31, 5.32, 6.33])}]->(:N2{id:4}),
      (:N1{id:2})-[@E1{id:2,vec1:VECTOR<3,float>([1.11,2.12,3.13]), vec2:VECTOR<7,float>([1.21, 2.22, 3.23, 4.24, 5.25, 6.26, 7.27]), vec3:VECTOR<3,float>([1.31, 2.32, 3.33])}]->(:N2{id:2,vec1:VECTOR<3,float>([0,0,0])}),
      (:N1{id:1})-[@E1{id:2,vec1:VECTOR<3,float>([2.11,2.99,4.13]), vec2:VECTOR<7,float>([1.21, 2.22, 3.23, 4.24, 5.25, 6.26, 7.27]), vec3:VECTOR<3,float>([1.31, 2.32, 3.33])}]->(:N2{id:2}),
      (:N1{id:3})-[@E1{id:3,vec1:VECTOR<3,float>([3.11,4.,5.13]), vec2:VECTOR<7,float>([3.21, 4.22, 5.23, 6.24, 7.25, 8.26, 9.27]), vec3:VECTOR<3,float>([3., 4.32, 5.33])}]->(:N2{id:3})
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH (v1)-[e:E1]->(v2)
      ORDER BY euclidean(vector<3, float>([2.11,3.12,4.13]), e.vec1)
      APPROX LIMIT 3 OPTIONS {type:IVF}
      RETURN e.id as eid, e.vec1 as vec1, e.vec2 as vec2, e.vec3 as vec3, v1.id as v1_id, v2.id as v2_id, v1.vec1 as v1_vec1, v2.vec1 as v2_vec1
      """
    Then the result should be, in any order:
      | eid | vec1                    | vec2                                         | vec3                    | v1_id | v2_id | v1_vec1              | v2_vec1              |
      | 4   | VECTOR [2.11,3.12,4.13] | VECTOR [4.21,5.22,6.23,7.24,8.25,9.26,10.27] | VECTOR [4.31,5.32,6.33] | 4     | 4     | VECTOR [0.0,0.0,0.0] | VECTOR [4.1,5.1,6.1] |
      | 2   | VECTOR [2.11,2.99,4.13] | VECTOR [1.21,2.22,3.23,4.24,5.25,6.26,7.27]  | VECTOR [1.31,2.32,3.33] | 1     | 2     | VECTOR [1.0,2.0,3.0] | VECTOR [0.0,0.0,0.0] |
      | 3   | VECTOR [3.11,4.0,5.13]  | VECTOR [3.21,4.22,5.23,6.24,7.25,8.26,9.27]  | VECTOR [3.0,4.32,5.33]  | 3     | 3     | VECTOR [3.0,4.0,5.0] | VECTOR [3.1,4.1,5.1] |
    # use ann_node_ivf_l2
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) APPROX LIMIT 4 OPTIONS {type:IVF, metric:L2, nprobe:8}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                    |
      | 1   | VECTOR [1.0,2.0,3.0]    |
      | 1   | VECTOR [1.1,2.1,3.1]    |
      | 91  | VECTOR [1.19,2.19,3.19] |
      | 81  | VECTOR [1.08,2.48,3.58] |
    When executing query:
      """
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) LIMIT 4
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                    |
      | 1   | VECTOR [1.0,2.0,3.0]    |
      | 1   | VECTOR [1.1,2.1,3.1]    |
      | 91  | VECTOR [1.19,2.19,3.19] |
      | 81  | VECTOR [1.08,2.48,3.58] |
    # use ann_node_hnsw_l2
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) APPROX LIMIT 4 OPTIONS {type:HNSW, metric:L2, efSearch:8}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then the result should be, in order:
      | vid | vec1                    |
      | 1   | VECTOR [1.0,2.0,3.0]    |
      | 1   | VECTOR [1.1,2.1,3.1]    |
      | 91  | VECTOR [1.19,2.19,3.19] |
      | 81  | VECTOR [1.08,2.48,3.58] |
    # use ann_node_ivf_ip
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), v.vec1) DESC APPROXIMATE LIMIT 17 OPTIONS {type:IVF, metric:IP, nprobe:8}
      RETURN v.id as vid, v.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), v.vec1)) as dist
      """
    Then the result should contain:
      | vid   | vec1                         | dist    |
      | 10003 | VECTOR [10000.0,235.0,3.343] | 10480.0 |
      # FIXME(czp): https://github.com/vesoft-inc/nebula-ng/issues/7472
      # | 10000 | VECTOR [10000.0,235.0,3.343] | 10480.0 |
      | 10004 | VECTOR [111.0,222.0,334.0]   | 1557.0  |
      | 10002 | VECTOR [111.0,222.0,332.0]   | 1551.0  |
      | 10001 | VECTOR [111.0,222.0,331.0]   | 1548.0  |
      | 27    | VECTOR [27.0,28.0,29.0]      | 170.0   |
      | 26    | VECTOR [26.0,27.0,28.0]      | 164.0   |
      | 25    | VECTOR [25.0,26.0,27.0]      | 158.0   |
      | 24    | VECTOR [24.0,25.0,26.0]      | 152.0   |
      | 23    | VECTOR [23.0,24.0,25.0]      | 146.0   |
      | 22    | VECTOR [22.0,23.0,24.0]      | 140.0   |
      | 21    | VECTOR [21.0,22.0,23.0]      | 134.0   |
      | 20    | VECTOR [20.0,21.0,22.0]      | 128.0   |
      | 919   | VECTOR [19.19,20.19,21.19]   | 123.0   |
      | 19    | VECTOR [19.1,20.1,21.1]      | 123.0   |
      | 819   | VECTOR [19.08,20.08,21.08]   | 122.0   |
      | 19    | VECTOR [19.0,20.0,21.0]      | 122.0   |
    When executing query:
      """
      USE ann_test
      MATCH (v:N1|N2)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), v.vec1) DESC LIMIT 17
      RETURN v.id as vid, v.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), v.vec1)) as dist
      """
    Then the result should be, in any order:
      | vid   | vec1                         | dist    |
      | 10003 | VECTOR [10000.0,235.0,3.343] | 10480.0 |
      | 10000 | VECTOR [10000.0,235.0,3.343] | 10480.0 |
      | 10004 | VECTOR [111.0,222.0,334.0]   | 1557.0  |
      | 10002 | VECTOR [111.0,222.0,332.0]   | 1551.0  |
      | 10001 | VECTOR [111.0,222.0,331.0]   | 1548.0  |
      | 27    | VECTOR [27.0,28.0,29.0]      | 170.0   |
      | 26    | VECTOR [26.0,27.0,28.0]      | 164.0   |
      | 25    | VECTOR [25.0,26.0,27.0]      | 158.0   |
      | 24    | VECTOR [24.0,25.0,26.0]      | 152.0   |
      | 23    | VECTOR [23.0,24.0,25.0]      | 146.0   |
      | 22    | VECTOR [22.0,23.0,24.0]      | 140.0   |
      | 21    | VECTOR [21.0,22.0,23.0]      | 134.0   |
      | 20    | VECTOR [20.0,21.0,22.0]      | 128.0   |
      | 919   | VECTOR [19.19,20.19,21.19]   | 123.0   |
      | 19    | VECTOR [19.1,20.1,21.1]      | 123.0   |
      | 819   | VECTOR [19.08,20.08,21.08]   | 122.0   |
      | 19    | VECTOR [19.0,20.0,21.0]      | 122.0   |
    When executing query:
      """
      use ann_test
      MATCH (v:N1)
      WHERE v.id = 10002
      SET v.vec1 = VECTOR<3,float>([111.08, 222.48, 333.58]),v.vec2=VECTOR<7,float>([1.08, 2.28, 3.08, 4.38, 5.08, 6.08, 7.08]),v.vec3=VECTOR<3,float>([1.18, 2.28, 3.38])
      """
    Then the execution should be successful
    # use ann_node_hnsw_ip
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2 where v.id>10000)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), v.vec1) DESC APPROX LIMIT 3 OPTIONS {type:HNSW, metric:IP, efSearch:8}
      RETURN v.id as vid, v.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), v.vec1)) as dist
      """
    Then the result should be, in order:
      | vid   | vec1                          | dist    |
      | 10003 | VECTOR [10000.0,235.0,3.343]  | 10480.0 |
      | 10004 | VECTOR [111.0,222.0,334.0]    | 1557.0  |
      | 10002 | VECTOR [111.08,222.48,333.58] | 1557.0  |
    When executing query:
      """
      USE ann_test
      MATCH (v:N1|N2 where v.id>10000)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), v.vec1) DESC LIMIT 3
      RETURN v.id as vid, v.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), v.vec1)) as dist
      """
    Then the result should be, in order:
      | vid   | vec1                          | dist    |
      | 10003 | VECTOR [10000.0,235.0,3.343]  | 10480.0 |
      | 10004 | VECTOR [111.0,222.0,334.0]    | 1557.0  |
      | 10002 | VECTOR [111.08,222.48,333.58] | 1557.0  |
    # use ann_edge_ivf_l2
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), e.vec1) ASC APPROX LIMIT 17 OPTIONS {type:IVF, metric:L2, nprobe:16}
      RETURN e.id as vid, e.vec1 as vec1, round(euclidean(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in any order:
      | vid | vec1                       | dist |
      | 1   | VECTOR [1.11,2.12,3.13]    | 0.0  |
      | 2   | VECTOR [1.11,2.12,3.13]    | 0.0  |
      | 2   | VECTOR [2.11,2.99,4.13]    | 2.0  |
      | 4   | VECTOR [2.11,3.12,4.13]    | 2.0  |
      | 3   | VECTOR [3.11,4.0,5.13]     | 4.0  |
      | 5   | VECTOR [5.11,6.12,7.13]    | 7.0  |
      | 6   | VECTOR [6.11,7.12,8.13]    | 9.0  |
      | 7   | VECTOR [7.11,8.12,9.13]    | 11.0 |
      | 8   | VECTOR [8.11,9.12,10.13]   | 12.0 |
      | 9   | VECTOR [9.11,10.12,11.13]  | 14.0 |
      | 10  | VECTOR [10.11,11.12,12.13] | 16.0 |
      | 11  | VECTOR [11.11,12.12,13.13] | 18.0 |
      | 12  | VECTOR [12.11,13.12,14.13] | 19.0 |
      | 13  | VECTOR [13.11,14.12,15.13] | 21.0 |
      | 14  | VECTOR [14.11,15.12,16.13] | 23.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 24.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 26.0 |
    When executing query:
      """
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), e.vec1) ASC LIMIT 17
      RETURN e.id as vid, e.vec1 as vec1, round(euclidean(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in any order:
      | vid | vec1                       | dist |
      | 1   | VECTOR [1.11,2.12,3.13]    | 0.0  |
      | 2   | VECTOR [1.11,2.12,3.13]    | 0.0  |
      | 2   | VECTOR [2.11,2.99,4.13]    | 2.0  |
      | 4   | VECTOR [2.11,3.12,4.13]    | 2.0  |
      | 3   | VECTOR [3.11,4.0,5.13]     | 4.0  |
      | 5   | VECTOR [5.11,6.12,7.13]    | 7.0  |
      | 6   | VECTOR [6.11,7.12,8.13]    | 9.0  |
      | 7   | VECTOR [7.11,8.12,9.13]    | 11.0 |
      | 8   | VECTOR [8.11,9.12,10.13]   | 12.0 |
      | 9   | VECTOR [9.11,10.12,11.13]  | 14.0 |
      | 10  | VECTOR [10.11,11.12,12.13] | 16.0 |
      | 11  | VECTOR [11.11,12.12,13.13] | 18.0 |
      | 12  | VECTOR [12.11,13.12,14.13] | 19.0 |
      | 13  | VECTOR [13.11,14.12,15.13] | 21.0 |
      | 14  | VECTOR [14.11,15.12,16.13] | 23.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 24.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 26.0 |
    # use ann_edge_hnsw_l2
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), e.vec1) ASC APPROX LIMIT 17 OPTIONS {type:HNSW, metric:L2, efSearch:16}
      RETURN e.id as vid, e.vec1 as vec1, round(euclidean(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in any order:
      | vid | vec1                       | dist |
      | 1   | VECTOR [1.11,2.12,3.13]    | 0.0  |
      | 2   | VECTOR [1.11,2.12,3.13]    | 0.0  |
      | 2   | VECTOR [2.11,2.99,4.13]    | 2.0  |
      | 4   | VECTOR [2.11,3.12,4.13]    | 2.0  |
      | 3   | VECTOR [3.11,4.0,5.13]     | 4.0  |
      | 5   | VECTOR [5.11,6.12,7.13]    | 7.0  |
      | 6   | VECTOR [6.11,7.12,8.13]    | 9.0  |
      | 7   | VECTOR [7.11,8.12,9.13]    | 11.0 |
      | 8   | VECTOR [8.11,9.12,10.13]   | 12.0 |
      | 9   | VECTOR [9.11,10.12,11.13]  | 14.0 |
      | 10  | VECTOR [10.11,11.12,12.13] | 16.0 |
      | 11  | VECTOR [11.11,12.12,13.13] | 18.0 |
      | 12  | VECTOR [12.11,13.12,14.13] | 19.0 |
      | 13  | VECTOR [13.11,14.12,15.13] | 21.0 |
      | 14  | VECTOR [14.11,15.12,16.13] | 23.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 24.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 26.0 |
    # use ann_edge_ivf_ip
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), e.vec1) DESC APPROX LIMIT 17 OPTIONS {type:IVF, metric:IP, nprobe:16}
      RETURN e.id as vid, e.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in order:
      | vid | vec1                       | dist  |
      | 27  | VECTOR [27.11,28.12,29.13] | 171.0 |
      | 26  | VECTOR [26.11,27.12,28.13] | 165.0 |
      | 25  | VECTOR [25.11,26.12,27.13] | 159.0 |
      | 24  | VECTOR [24.11,25.12,26.13] | 153.0 |
      | 23  | VECTOR [23.11,24.12,25.13] | 147.0 |
      | 22  | VECTOR [22.11,23.12,24.13] | 141.0 |
      | 21  | VECTOR [21.11,22.12,23.13] | 135.0 |
      | 20  | VECTOR [20.11,21.12,22.13] | 129.0 |
      | 19  | VECTOR [19.11,20.12,21.13] | 123.0 |
      | 18  | VECTOR [18.11,19.12,20.13] | 117.0 |
      | 17  | VECTOR [17.11,18.12,19.13] | 111.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 105.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 99.0  |
      | 14  | VECTOR [14.11,15.12,16.13] | 93.0  |
      | 13  | VECTOR [13.11,14.12,15.13] | 87.0  |
      | 12  | VECTOR [12.11,13.12,14.13] | 81.0  |
      | 11  | VECTOR [11.11,12.12,13.13] | 75.0  |
    When executing query:
      """
      TABLE t {id, vec1, vec2, vec3} =
      {id:1, vec1:VECTOR<3,float>([1.0, 2.1, 3.0]), vec2:VECTOR<7,float>([1.08, 2.28, 3.08, 7.38, 5.08, 6.08, 7.08]), vec3:VECTOR<3,float>([1.18, 6.28, 4.38])},
      {id:27, vec1:VECTOR<3,float>([133.08, 22.48, 33.58]), vec2:VECTOR<7,float>([1.08, 2.28, 3.08, 4.38, 5.08, 6.08, 7.08]), vec3:VECTOR<3,float>([1.18, 2.28, 3.38])}
      use ann_test
      FOR r IN t
      MATCH ()-[e:E1]->()
      WHERE e.id = r.id
      SET e.vec1 = r.vec1, e.vec2 = r.vec2, e.vec3 = r.vec3
      """
    Then the execution should be successful
    # use ann_edge_hnsw_l2
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), e.vec1) ASC APPROX LIMIT 17 OPTIONS {type:HNSW, metric:L2, efSearch:16}
      RETURN e.id as vid, e.vec1 as vec1, round(euclidean(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in order:
      | vid | vec1                       | dist |
      | 1   | VECTOR [1.0,2.1,3.0]       | 0.0  |
      | 2   | VECTOR [1.11,2.12,3.13]    | 0.0  |
      | 2   | VECTOR [2.11,2.99,4.13]    | 2.0  |
      | 4   | VECTOR [2.11,3.12,4.13]    | 2.0  |
      | 3   | VECTOR [3.11,4.0,5.13]     | 4.0  |
      | 5   | VECTOR [5.11,6.12,7.13]    | 7.0  |
      | 6   | VECTOR [6.11,7.12,8.13]    | 9.0  |
      | 7   | VECTOR [7.11,8.12,9.13]    | 11.0 |
      | 8   | VECTOR [8.11,9.12,10.13]   | 12.0 |
      | 9   | VECTOR [9.11,10.12,11.13]  | 14.0 |
      | 10  | VECTOR [10.11,11.12,12.13] | 16.0 |
      | 11  | VECTOR [11.11,12.12,13.13] | 18.0 |
      | 12  | VECTOR [12.11,13.12,14.13] | 19.0 |
      | 13  | VECTOR [13.11,14.12,15.13] | 21.0 |
      | 14  | VECTOR [14.11,15.12,16.13] | 23.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 24.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 26.0 |
    When executing query:
      """
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), e.vec1) ASC LIMIT 17
      RETURN e.id as vid, e.vec1 as vec1, round(euclidean(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in order:
      | vid | vec1                       | dist |
      | 1   | VECTOR [1.0,2.1,3.0]       | 0.0  |
      | 2   | VECTOR [1.11,2.12,3.13]    | 0.0  |
      | 2   | VECTOR [2.11,2.99,4.13]    | 2.0  |
      | 4   | VECTOR [2.11,3.12,4.13]    | 2.0  |
      | 3   | VECTOR [3.11,4.0,5.13]     | 4.0  |
      | 5   | VECTOR [5.11,6.12,7.13]    | 7.0  |
      | 6   | VECTOR [6.11,7.12,8.13]    | 9.0  |
      | 7   | VECTOR [7.11,8.12,9.13]    | 11.0 |
      | 8   | VECTOR [8.11,9.12,10.13]   | 12.0 |
      | 9   | VECTOR [9.11,10.12,11.13]  | 14.0 |
      | 10  | VECTOR [10.11,11.12,12.13] | 16.0 |
      | 11  | VECTOR [11.11,12.12,13.13] | 18.0 |
      | 12  | VECTOR [12.11,13.12,14.13] | 19.0 |
      | 13  | VECTOR [13.11,14.12,15.13] | 21.0 |
      | 14  | VECTOR [14.11,15.12,16.13] | 23.0 |
      | 15  | VECTOR [15.11,16.12,17.13] | 24.0 |
      | 16  | VECTOR [16.11,17.12,18.13] | 26.0 |
    # use ann_edge_hnsw_ip
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), e.vec1) DESC APPROX LIMIT 17 OPTIONS {type:HNSW, metric:IP, efSearch:16}
      RETURN e.id as vid, e.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in order:
      | vid | vec1                        | dist  |
      | 27  | VECTOR [133.08,22.48,33.58] | 279.0 |
      | 26  | VECTOR [26.11,27.12,28.13]  | 165.0 |
      | 25  | VECTOR [25.11,26.12,27.13]  | 159.0 |
      | 24  | VECTOR [24.11,25.12,26.13]  | 153.0 |
      | 23  | VECTOR [23.11,24.12,25.13]  | 147.0 |
      | 22  | VECTOR [22.11,23.12,24.13]  | 141.0 |
      | 21  | VECTOR [21.11,22.12,23.13]  | 135.0 |
      | 20  | VECTOR [20.11,21.12,22.13]  | 129.0 |
      | 19  | VECTOR [19.11,20.12,21.13]  | 123.0 |
      | 18  | VECTOR [18.11,19.12,20.13]  | 117.0 |
      | 17  | VECTOR [17.11,18.12,19.13]  | 111.0 |
      | 16  | VECTOR [16.11,17.12,18.13]  | 105.0 |
      | 15  | VECTOR [15.11,16.12,17.13]  | 99.0  |
      | 14  | VECTOR [14.11,15.12,16.13]  | 93.0  |
      | 13  | VECTOR [13.11,14.12,15.13]  | 87.0  |
      | 12  | VECTOR [12.11,13.12,14.13]  | 81.0  |
      | 11  | VECTOR [11.11,12.12,13.13]  | 75.0  |
    When executing query:
      """
      USE ann_test
      MATCH (v)-[e:E1]->(n)
      ORDER BY inner_product(vector<3, float>([1, 2, 3]), e.vec1) DESC LIMIT 17
      RETURN e.id as vid, e.vec1 as vec1, round(inner_product(vector<3, float>([1, 2, 3]), e.vec1)) as dist
      """
    Then the result should be, in order:
      | vid | vec1                        | dist  |
      | 27  | VECTOR [133.08,22.48,33.58] | 279.0 |
      | 26  | VECTOR [26.11,27.12,28.13]  | 165.0 |
      | 25  | VECTOR [25.11,26.12,27.13]  | 159.0 |
      | 24  | VECTOR [24.11,25.12,26.13]  | 153.0 |
      | 23  | VECTOR [23.11,24.12,25.13]  | 147.0 |
      | 22  | VECTOR [22.11,23.12,24.13]  | 141.0 |
      | 21  | VECTOR [21.11,22.12,23.13]  | 135.0 |
      | 20  | VECTOR [20.11,21.12,22.13]  | 129.0 |
      | 19  | VECTOR [19.11,20.12,21.13]  | 123.0 |
      | 18  | VECTOR [18.11,19.12,20.13]  | 117.0 |
      | 17  | VECTOR [17.11,18.12,19.13]  | 111.0 |
      | 16  | VECTOR [16.11,17.12,18.13]  | 105.0 |
      | 15  | VECTOR [15.11,16.12,17.13]  | 99.0  |
      | 14  | VECTOR [14.11,15.12,16.13]  | 93.0  |
      | 13  | VECTOR [13.11,14.12,15.13]  | 87.0  |
      | 12  | VECTOR [12.11,13.12,14.13]  | 81.0  |
      | 11  | VECTOR [11.11,12.12,13.13]  | 75.0  |
    # Invalid ANN search syntax
    When executing query:
      """
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1)
      OFFSET 3 APPROX LIMIT 17 OPTIONS {nprobe: 1, type:IVF}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: offset clause is not allowed"
    When executing query:
      """
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) DESC
      APPROX LIMIT 17 OPTIONS {nprobe: 1, type:IVF}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: Distance type metric can only be queried in ascending order"
    When executing query:
      """
      USE ann_test
      MATCH (v:N1)
      ORDER BY v.id, euclidean(vector<3, float>([1, 2, 3]), v.vec1)
      APPROX LIMIT 17 OPTIONS {nprobe: 1, type:IVF}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: only the first order factor can be metric function"
    When executing query:
      """
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) + 1
      APPROX LIMIT 17 OPTIONS {type:IVF}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: invalid metric function: +"
    When executing query:
      """
      USE ann_test
      MATCH (v:N1)
      ORDER BY v.id, euclidean(vector<3, float>([1, 2, 3]), v.vec1)
      APPROX LIMIT 17 OPTIONS {type:IVF, nprobe: 1}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: only the first order factor can be metric function"
    When executing query:
      """
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1)
      APPROX LIMIT 17 OPTIONS {type:IVF, nprobe: 1, metric:IP}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: metric mismatch between order factor and search option"
    When executing query:
      """
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<3, float>([1, 2, 3]), v.vec1) DESC
      APPROX LIMIT 17 OPTIONS {nprobe: 1, type:IVF, metric:L2}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: Distance type metric can only be queried in ascending order"
    When executing query:
      """
      CALL show_all_indexes()
      FILTER graph_name='ann_test'
      RETURN name, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name               | index_type                                                                                  | graph_name | entity_type | element_type | properties    |
      | "ann_node_hnsw_l2" | "Vector{type:HNSW, metric:L2, dimension:3, maxDegree:8, efConstruction:16, capacity:10000}" | "ann_test" | "Node"      | "N1,N2"      | LIST ["vec1"] |
      | "ann_node_ivf_l2"  | "Vector{type:IVF, metric:L2, dimension:3, nlist:10, trainSize:3}"                           | "ann_test" | "Node"      | "N1,N2"      | LIST ["vec1"] |
      | "ann_node_ivf_ip"  | "Vector{type:IVF, metric:IP, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Node"      | "N1,N2"      | LIST ["vec1"] |
      | "ann_node_hnsw_ip" | "Vector{type:HNSW, metric:IP, dimension:3, maxDegree:8, efConstruction:16, capacity:2}"     | "ann_test" | "Node"      | "N1,N2"      | LIST ["vec1"] |
      | "ann_edge_ivf_l2"  | "Vector{type:IVF, metric:L2, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_hnsw_ip" | "Vector{type:HNSW, metric:IP, dimension:3, maxDegree:3, efConstruction:6, capacity:200}"    | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_hnsw_l2" | "Vector{type:HNSW, metric:L2, dimension:3, maxDegree:8, efConstruction:16, capacity:10000}" | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_ivf_ip"  | "Vector{type:IVF, metric:IP, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
    When executing query:
      """
      ALTER GRAPH TYPE ann_test_gt {
        ALTER NODE TYPE N1 DROP PROPERTIES{ vec1 }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test
      MATCH (v:N1)
      ORDER BY vector_distance(vector<3, float>([1, 2, 3]), v.vec1)
      APPROX LIMIT 3 OPTIONS {nprobe: 8, type:IVF}
      RETURN v.id as vid, v.vec1 as vec1
      """
    Then an Error should be raised: "[NS230]: property `vec1` not found in NODE<(N1)>"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS idx_hnsw_vec2 ON NODE N1&N2::vec2 OPTIONS {dim: 7, type:HNSW, metric:IP, capacity:2, efConstruction:9}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS idx_ivf_vec2 ON NODE N1::vec2 OPTIONS {dim: 7, type:IVF, metric:L2, nlist:3}
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_all_indexes()
      FILTER graph_name='ann_test'
      RETURN name, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name               | index_type                                                                                  | graph_name | entity_type | element_type | properties    |
      | "idx_hnsw_vec2"    | "Vector{type:HNSW, metric:IP, dimension:7, maxDegree:8, efConstruction:9, capacity:2}"      | "ann_test" | "Node"      | "N1,N2"      | LIST ["vec2"] |
      | "idx_ivf_vec2"     | "Vector{type:IVF, metric:L2, dimension:7, nlist:3, trainSize:3}"                            | "ann_test" | "Node"      | "N1"         | LIST ["vec2"] |
      | "ann_edge_ivf_l2"  | "Vector{type:IVF, metric:L2, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_hnsw_ip" | "Vector{type:HNSW, metric:IP, dimension:3, maxDegree:3, efConstruction:6, capacity:200}"    | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_hnsw_l2" | "Vector{type:HNSW, metric:L2, dimension:3, maxDegree:8, efConstruction:16, capacity:10000}" | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_ivf_ip"  | "Vector{type:IVF, metric:IP, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec2)
      APPROX LIMIT 3 OPTIONS {nprobe: 8, type:IVF}
      RETURN v.id as vid, v.vec2 as vec2, euclidean(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec2) as dist
      """
    Then the result should be, in any order:
      | vid   | vec2                                 | dist |
      | 10004 | VECTOR [1.0,2.0,3.0,4.0,5.0,6.0,7.0] | 0.0  |
      | 1     | VECTOR [1.0,2.0,3.0,4.0,5.0,6.0,7.0] | 0.0  |
      | 10000 | VECTOR [1.0,2.0,3.0,4.0,5.0,6.0,7.0] | 0.0  |
    When executing query:
      """
      ALTER GRAPH TYPE ann_test_gt {
        ALTER NODE TYPE N1 RENAME PROPERTIES{ vec2 TO vec22 }
      }
      """
    Then an Error should be raised: "[NT016]: Renaming property used by multiple vector index is not allowed, element type: `N1`, property name: `vec2`"
    When executing query:
      """
      ALTER GRAPH TYPE ann_test_gt {
        ALTER NODE TYPE N1 MODIFY PROPERTIES{ vec2 VECTOR<33,float> }
      }
      """
    Then an Error should be raised: "[NT008]: Modifying property used by index is not supported, element type: `N1`, property name: `vec2`"
    When executing query:
      """
      DROP INDEX idx_hnsw_vec2 for ann_test
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE ann_test_gt {
        ALTER NODE TYPE N1 RENAME PROPERTIES{ vec2 TO vec22 }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_all_indexes()
      FILTER graph_name='ann_test'
      RETURN name, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name               | index_type                                                                                  | graph_name | entity_type | element_type | properties     |
      | "idx_ivf_vec2"     | "Vector{type:IVF, metric:L2, dimension:7, nlist:3, trainSize:3}"                            | "ann_test" | "Node"      | "N1"         | LIST ["vec22"] |
      | "ann_edge_ivf_l2"  | "Vector{type:IVF, metric:L2, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"]  |
      | "ann_edge_hnsw_ip" | "Vector{type:HNSW, metric:IP, dimension:3, maxDegree:3, efConstruction:6, capacity:200}"    | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"]  |
      | "ann_edge_hnsw_l2" | "Vector{type:HNSW, metric:L2, dimension:3, maxDegree:8, efConstruction:16, capacity:10000}" | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"]  |
      | "ann_edge_ivf_ip"  | "Vector{type:IVF, metric:IP, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"]  |
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS idx_hnsw_vec2 ON NODE N1::vec22 OPTIONS {dim: 7, type:HNSW, metric:IP, capacity:2, efConstruction:9}
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1)
      ORDER BY vector_distance(vector<3, float>([1, 2, 3]), v.vec22)
      APPROX LIMIT 3 OPTIONS {nprobe: 8, type:IVF}
      RETURN v.id as vid, v.vec22 as vec2
      """
    Then an Error should be raised: "[NS226]: Vector dimension mismatch 3 vs 7, in expression: euclidean([1.000000, 2.000000, 3.000000], v.vec22)"
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1)
      ORDER BY euclidean(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec22)
      APPROX LIMIT 3 OPTIONS {nprobe: 8, type:IVF}
      RETURN v.id as vid, v.vec22 as vec2, euclidean(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec22) as dist
      """
    Then the result should be, in any order:
      | vid   | vec2                                 | dist |
      | 10004 | VECTOR [1.0,2.0,3.0,4.0,5.0,6.0,7.0] | 0.0  |
      | 1     | VECTOR [1.0,2.0,3.0,4.0,5.0,6.0,7.0] | 0.0  |
      | 10000 | VECTOR [1.0,2.0,3.0,4.0,5.0,6.0,7.0] | 0.0  |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1)
      ORDER BY inner_product(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec22) DESC
      APPROX LIMIT 3 OPTIONS {efSearch: 8, type:HNSW}
      RETURN v.id as vid, v.vec22 as vec2, inner_product(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec22) as dist
      """
    Then the result should be, in any order:
      | vid | vec2                                        | dist  |
      | 27  | VECTOR [27.0,28.0,29.0,30.0,31.0,32.0,33.0] | 868.0 |
      | 26  | VECTOR [26.0,27.0,28.0,29.0,30.0,31.0,32.0] | 840.0 |
      | 25  | VECTOR [25.0,26.0,27.0,28.0,29.0,30.0,31.0] | 812.0 |
    When executing query:
      """
      USE ann_test
      MATCH (v:N1|N2) where v.vec22 IS NOT NULL
      ORDER BY inner_product(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec22) DESC
      APPROX LIMIT 3 OPTIONS {efSearch: 8, type:HNSW}
      RETURN v.id as vid, v.vec22 as vec2, inner_product(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec22) as dist
      """
    Then the result should be, in any order:
      | vid | vec2                                        | dist  |
      | 27  | VECTOR [27.0,28.0,29.0,30.0,31.0,32.0,33.0] | 868.0 |
      | 26  | VECTOR [26.0,27.0,28.0,29.0,30.0,31.0,32.0] | 840.0 |
      | 25  | VECTOR [25.0,26.0,27.0,28.0,29.0,30.0,31.0] | 812.0 |
    # node type collection mismatched
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ann_test
      MATCH (v:N1|N2) where v.vec22 IS NOT NULL
      ORDER BY inner_product(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec22) DESC
      APPROX LIMIT 3 OPTIONS {efSearch: 8, type:HNSW}
      RETURN v.id as vid, v.vec22 as vec2, inner_product(vector<7, float>([1, 2, 3, 4, 5, 6, 7]), v.vec22) as dist
      """
    Then an Error should be raised: "[NZ001]: Optimizer internal error: no execution plan generated, optimizer rules may be disabled or misconfigured"
    When executing query:
      """
      ALTER GRAPH TYPE ann_test_gt {
        ALTER NODE TYPE N1 DROP PROPERTIES{vec22 }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_all_indexes()
      FILTER graph_name='ann_test'
      RETURN name, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name               | index_type                                                                                  | graph_name | entity_type | element_type | properties    |
      | "ann_edge_ivf_l2"  | "Vector{type:IVF, metric:L2, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_hnsw_ip" | "Vector{type:HNSW, metric:IP, dimension:3, maxDegree:3, efConstruction:6, capacity:200}"    | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_hnsw_l2" | "Vector{type:HNSW, metric:L2, dimension:3, maxDegree:8, efConstruction:16, capacity:10000}" | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
      | "ann_edge_ivf_ip"  | "Vector{type:IVF, metric:IP, dimension:3, nlist:8, trainSize:3}"                            | "ann_test" | "Edge"      | "E1"         | LIST ["vec1"] |
    When executing query:
      """
      ALTER GRAPH TYPE ann_test_gt {
        ALTER EDGE TYPE E1 DROP PROPERTIES{ vec1 }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_all_indexes()
      FILTER graph_name='ann_test'
      RETURN name, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name | index_type | graph_name | entity_type | element_type | properties |
    When executing query:
      """
      ALTER GRAPH TYPE ann_test_gt {
        ALTER EDGE TYPE E1 ADD PROPERTIES{ vec1 VECTOR<3,float32>}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_all_indexes()
      FILTER graph_name='ann_test'
      RETURN name, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name | index_type | graph_name | entity_type | element_type | properties |
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_idx ON NODE N1&N2::vec1 OPTIONS {type:HNSW, metric:IP, capacity:2}
      """
    Then an Error should be raised: "[42001]: Vector dimension is required. near `type:HNSW, metric:IP, capacity:2`"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_idx ON NODE N1&N2::vec1 OPTIONS {type:IVF,dim:0, metric:IP, capacity:2}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: Dimension must be greater than 0."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_idx ON NODE N2::vec1 OPTIONS {type:IVF,dim:3, metric:L2, capacity:2}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: Invalid build parameter for IVF index: capacity"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_idx ON NODE N2::vec1 OPTIONS {type:IVF,dim:3, metric:L2, maxDegree:2}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: Invalid build parameter for IVF index: maxDegree"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_idx ON NODE N2::vec1 OPTIONS {type:IVF,dim:3, metric:L2, efConstruction:2}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: Invalid build parameter for IVF index: efConstruction"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_idx ON NODE N2::vec1 OPTIONS {type:HNSW,dim:3, metric:IP, nlist:2}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: Invalid build parameter for HNSW index: nlist"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_idx ON NODE N2::vec1 OPTIONS {type:IVF,dim:3, metric:IP, nlist:0}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: nlist must be greater than 0."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_idx ON NODE N2::vec1 OPTIONS {type:HNSW,dim:3, metric:IP, efConstruction:9,maxDegree:0}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: maxDegree must be greater than 0."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_idx ON NODE N2::vec1 OPTIONS {type:HNSW,dim:3, metric:IP, efConstruction:0,maxDegree:8}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: efConstruction must be greater than 0."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_node_idx ON NODE N2::vec1 OPTIONS {type:HNSW,dim:3, metric:IP, capacity:0,maxDegree:8}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: capacity must be greater than 0."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx ON EDGE E1::vec1 OPTIONS {type:HNSW, metric:IP, capacity:2}
      """
    Then an Error should be raised: "[42001]: Vector dimension is required. near `type:HNSW, metric:IP, capacity:2`"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx ON EDGE E1::vec1 OPTIONS {type:IVF,dim:0, metric:IP, capacity:2}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: Dimension must be greater than 0."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx ON EDGE E1::vec1 OPTIONS {type:IVF,dim:3, metric:L2, capacity:2}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: Invalid build parameter for IVF index: capacity"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx ON EDGE E1::vec1 OPTIONS {type:IVF,dim:3, metric:L2, maxDegree:2}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: Invalid build parameter for IVF index: maxDegree"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx ON EDGE E1::vec1 OPTIONS {type:IVF,dim:3, metric:L2, efConstruction:2}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: Invalid build parameter for IVF index: efConstruction"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx ON EDGE E1::vec1 OPTIONS {type:HNSW,dim:3, metric:IP, nlist:2}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: Invalid build parameter for HNSW index: nlist"
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx ON EDGE E1::vec1 OPTIONS {type:IVF,dim:3, metric:IP, nlist:0}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: nlist must be greater than 0."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx ON EDGE E1::vec1 OPTIONS {type:HNSW,dim:3, metric:IP, efConstruction:9,maxDegree:0}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: maxDegree must be greater than 0."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx ON EDGE E1::vec1 OPTIONS {type:HNSW,dim:3, metric:IP, efConstruction:0,maxDegree:8}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: efConstruction must be greater than 0."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx ON EDGE E1::vec1 OPTIONS {type:HNSW,dim:3, metric:IP, capacity:0,maxDegree:8}
      """
    Then an Error should be raised: "[NS234]: Invalid ANN index build option: capacity must be greater than 0."
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS idx_ivf_vec2 ON NODE N1::vec3 OPTIONS {dim: 3, type:IVF, metric:L2, nlist:3}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test CREATE VECTOR INDEX IF NOT EXISTS idx_ivf_vec3 ON EDGE E1::vec3 OPTIONS {dim: 3, type:HNSW, metric:IP, efConstruction:3}
      """
    Then the execution should be successful
    And wait "3" seconds
    When executing query:
      """
      CALL show_all_indexes()
      FILTER graph_name='ann_test'
      RETURN name, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name           | index_type                                                                                 | graph_name | entity_type | element_type | properties    |
      | "idx_ivf_vec2" | "Vector{type:IVF, metric:L2, dimension:3, nlist:3, trainSize:3}"                           | "ann_test" | "Node"      | "N1"         | LIST ["vec3"] |
      | "idx_ivf_vec3" | "Vector{type:HNSW, metric:IP, dimension:3, maxDegree:8, efConstruction:3, capacity:10000}" | "ann_test" | "Edge"      | "E1"         | LIST ["vec3"] |
    When executing query:
      """
      ALTER GRAPH TYPE ann_test_gt {
          DROP NODE TYPE `N1`,
          DROP EDGE TYPE `E1`
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_all_indexes()
      FILTER graph_name='ann_test'
      RETURN name, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name | index_type | graph_name | entity_type | element_type | properties |
    When executing query:
      """
      DROP GRAPH ann_test
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE ann_test_gt
      """
    Then the execution should be successful

  Scenario: across multiple types
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ann_test_multitype_gt AS {
        Node `User` (:Person {id INT PRIMARY KEY, born INT, name STRING, vec1 VECTOR<3, float>}),
        Node Movie  (:Movie {id INT PRIMARY KEY, name STRING, vec1 VECTOR<3, float>})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ann_test_multitype_g TYPED ann_test_multitype_gt
      """
    Then the execution should be successful
    And graph "ann_test_multitype_g" should be ready to use
    When executing query:
      """
      CREATE VECTOR INDEX ann_idx on NODE `User`&Movie::vec1 OPTIONS {dim: 3} FOR ann_test_multitype_g
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test_multitype_g
      INSERT
      (u1@`User`{id:1, name:'Dina Meyer', born:1964, vec1:vector(0,1,0)}),
      (u2@`User`{id:2, name:'Carrie-Anne Mosss', born:1967, vec1:null}),
      (u3@`User`{id:3, name:'Laurence Fishburne', born:1961, vec1:VECTOR<3,float>([1.1,2.1,3.1])}),
      (m1@Movie{id:1, name:"The Matrix Reloaded", vec1:VECTOR<3,float>([1.2,2.2,3.2])}),
      (m2@Movie{id:2, name:"The Devil's Advocate", vec1:VECTOR<3,float>([1.28,2.28,3.28])}),
      (m3@Movie{id:3, name:"Cloud Atlas", vec1:VECTOR<3,float>([1.3,2.3,3.3])})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ann_test_multitype_g
      MATCH (v)
      ORDER BY euclidean(VECTOR<3,float>([1,2,3]),v.vec1)
      APPROX LIMIT 10 OPTIONS {type:IVF}
      RETURN count(*) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 5   |
    And drop the index "ann_idx" of "ann_test_multitype_g"
    And drop the graph "ann_test_multitype_g"
    And drop the graph type "ann_test_multitype_gt"
