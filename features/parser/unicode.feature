# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: unicode

  Scenario: unicode digits
    When executing query:
      """
      RETURN substring("\u00a067", 2, 2) AS a
      """
    Then the result should be, in any order:
      | a    |
      | "67" |
    When executing query:
      """
      RETURN length("\U00a067") AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN length("\U00a067") AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |

  Scenario: chinese characters
    When executing query:
      """
      RETURN 666==”中国人“
      """
    Then an Error should be raised: "[42001]: syntax error near `=`"

# FIXME(jie): nbv_scanner has bug
# When executing query:
# """
# RETURN "\ud800"
# """
# Then an Error should be raised: "[42001]: Invalid unicode escape value: \ud800 near `\ud800`"
# When executing query:
# """
# RETURN "\udfff"
# """
# Then an Error should be raised: "[42001]: Invalid unicode escape value: \udfff near `\udfff`"
# When executing query:
# """
# RETURN "\U110001"
# """
# Then an Error should be raised: "[42001]: Invalid unicode escape value: \U110001 near `\U110001`"
# When executing query:
# """
# RETURN "\U4e2dff67"
# """
# Then an Error should be raised: "[42001]: Invalid unicode escape value: \U4e2dff67 near `\U4e2dff67`"
