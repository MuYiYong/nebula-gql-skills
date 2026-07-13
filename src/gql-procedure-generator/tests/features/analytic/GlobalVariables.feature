# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Global Variables test

  Scenario: Global Variables
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_v     = 1
        VALUE sum_value    SumAgg<INT> = 0
        TABLE result_table TYPED TABLE {score INT}

        MATCH (a@Person)
        PER NODE (a) {
          VALUE local_v = global_v
          SET @sum_value += global_v
          EXPORT global_v INTO result_table
          LOG_INFO("global_v == ", global_v, " local_v == ",local_v)
        }

        FOR r IN result_table
        RETURN r.score, @sum_value
      }
      """
    Then the result should be, in any order:
      | r.score | @sum_value |
      | 1       | 4          |
      | 1       | 4          |
      | 1       | 4          |
      | 1       | 4          |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_v = 1
        VALUE sum_value SumAgg<INT> = 0

        MATCH (a@Person)
        PER NODE (a) {
          VALUE local_v = global_v - 1
          IF local_v < global_v THEN  {
            SET @sum_value += global_v
          }
        }
        RETURN @sum_value
      }
      """
    Then the result should be, in any order:
      | @sum_value |
      | 4          |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_v = 1
        VALUE sum_value SumAgg<INT> = 0

        MATCH (a@Person)
        PER NODE (a) {
          VALUE local_v = global_v - 10
          WHILE local_v < global_v THEN  {
            SET @sum_value += global_v
            SET local_v = local_v + 1
          }
        }
        RETURN @sum_value
      }
      """
    Then the result should be, in any order:
      | @sum_value |
      | 40         |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
      Value cnt SumAgg<int8> = 0
      VALUE ids SetAgg<int8>
      VALUE id_list ListAgg<int8>
      VALUE maxid MaxAgg<int8> = 0
      VALUE minid MinAgg<int8> = 0
      VALUE nmap MapAgg<int8, TopKAgg<1, k int8 DESC, v double DESC>>
      VALUE topk TopKAgg<1, k int8 DESC, v double DESC>

      match (v) per node (v) {
       set @cnt += 1
       set @ids += cast(v.id as int8)
       set @id_list += cast(v.id as int8)
         if (v.id > @maxid) then {
            set @maxid += cast(v.id as int8)
         }
         if (v.id < @minid) then {
            set @minid += cast(v.id as int8)
         }
         set @nmap += tuple(cast(v.id as int8), {k:cast(v.id as int8), v:1.0})
         set @topk += {k:cast(v.id as int8), v:1.0}
      }

      return @cnt AS cnt, size(@ids) AS ids, length(@id_list) AS id_list, @maxid AS maxid, @minid AS minid, size(@nmap) AS nmap, @topk AS topk
      }
      """
    Then the result should be, in any order:
      | cnt | ids | id_list | maxid | minid | nmap | topk                    |
      # | 34  | [3,5,1,6,2,4] | [4,2,3,1,4,2,5,3,1,6,4,2,3,1,4,2,3,1,2,4,3,1,4,2,3,1,4,2,3,1,2,4,3,1] | 6     | 0     | [{_0:6,_1:[{k:6,v:1.0}]},{_0:2,_1:[{k:2,v:1.0}]},{_0:3,_1:[{k:3,v:1.0}]},{_0:5,_1:[{k:5,v:1.0}]},{_0:4,_1:[{k:4,v:1.0}]},{_0:1,_1:[{k:1,v:1.0}]}] | [{k:6,v:1.0}] |
      | 34  | 6   | 34      | 6     | 0     | 6    | LIST[RECORD{k:6,v:1.0}] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
      Value cnt SumAgg<int8> = 0
      VALUE ids SetAgg<int16>
      VALUE id_list ListAgg<int32>
      VALUE maxid MaxAgg<int64> = 0
      VALUE minid MinAgg<int8> = 0
      VALUE nmap MapAgg<int16, TopKAgg<1, k int32 DESC, v float DESC>>
      VALUE topk TopKAgg<1, k int8 DESC, v double DESC>

      match (v) per node (v) {
       set @cnt += 1
       set @ids += cast(v.id as int8)
       set @id_list += cast(v.id as int8)
         if (v.id > @maxid) then {
            set @maxid += cast(v.id as int8)
         }
         if (v.id < @minid) then {
            set @minid += cast(v.id as int8)
         }
         set @nmap += tuple(cast(v.id as int8), {k:cast(v.id as int8), v:1.0})
         set @topk += {k:cast(v.id as int8), v:1.0}
      }

      return @cnt AS cnt, size(@ids) AS ids, length(@id_list) AS id_list, @maxid AS maxid, @minid AS minid, size(@nmap) AS nmap, @topk AS topk
      }
      """
    Then the result should be, in any order:
      | cnt | ids | id_list | maxid | minid | nmap | topk                    |
      # | 34  | [3,5,1,6,2,4] | [4,2,3,1,4,2,5,3,1,6,4,2,3,1,4,2,3,1,2,4,3,1,4,2,3,1,4,2,3,1,2,4,3,1] | 6     | 0     | [{_0:6,_1:[{k:6,v:1.0}]},{_0:2,_1:[{k:2,v:1.0}]},{_0:3,_1:[{k:3,v:1.0}]},{_0:5,_1:[{k:5,v:1.0}]},{_0:4,_1:[{k:4,v:1.0}]},{_0:1,_1:[{k:1,v:1.0}]}] | [{k:6,v:1.0}] |
      | 34  | 6   | 34      | 6     | 0     | 6    | LIST[RECORD{k:6,v:1.0}] |
