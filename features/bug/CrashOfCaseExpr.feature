# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Crash of case expr

  # #1668
  Scenario: Crash of case expr of any type casting
    When executing query:
      """
      USE ldbc
      MATCH (person:Person {id: 26388279067534})<-[:HAS_CREATOR]-(message:Message)<-[likes:LIKES]-(liker:Person)
        LET likeTime=likes.creationDate
        ORDER BY likeTime DESC, message.id ASC
        RETURN head(collect(message)) AS latestLikeMsg, head(collect(likeTime)) AS likeCreationDate, liker, person GROUP BY liker, person
        NEXT USE ldbc
      ORDER BY
        likeCreationDate DESC,
        liker.id ASC
      LIMIT 20
      RETURN
        liker.id AS personId,
        liker.firstName AS personFirstName,
        liker.lastName AS personLastName,likeCreationDate,
        latestLikeMsg.id AS messageId,
        CASE WHEN latestLikeMsg.content <>"" THEN latestLikeMsg.content  ELSE latestLikeMsg.imageFile END AS messageContent,
        latestLikeMsg.creationDate AS minutesLatency,
        NOT EXISTS ((liker:Person)<-[:KNOWS]->(person:Person{id: 26388279067534}))  AS isNew
      """
    Then the execution should be successful
