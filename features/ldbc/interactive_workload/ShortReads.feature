# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: LDBCInteractiveWorkload_ShortReads

  @sf01
  Scenario: _IS1ProfileOfAPerson
    When executing query:
      """
      USE sf01
      MATCH (n:Person WHERE n.id = 35184372090183)-[:IS_LOCATED_IN]->(p:City)
      RETURN
        n.firstName AS firstName,
        n.lastName AS lastName,
        n.birthday AS birthday,
        n.locationIP AS locationIP,
        n.browserUsed AS browserUsed,
        p.id AS cityId,
        n.gender AS gender,
        n.creationDate AS creationDate
      """
    Then the result should be, in any order:
      | firstName | lastName | birthday          | locationIP      | browserUsed         | cityId | gender   | creationDate                          |
      | "David"   | "Brown"  | DATE '1982-06-15' | "31.220.246.87" | "Internet Explorer" | 1425   | "female" | DATETIME '2012-09-09T04:50:09.438000' |

  @sf01
  Scenario: _IS2RecentMessagesOfAPerson
    When executing query:
      """
      USE sf01
      MATCH (p:Person WHERE p.id = 28587302322974 )<-[:HAS_CREATOR]-(message:Message)
      LET messageId=message.id, messageCreationDate=message.creationDate
      ORDER BY messageCreationDate DESC, messageId ASC
      LIMIT 10
      MATCH WALK (message:Message)-[:REPLY_OF]->{0,5}(post:Post)-[:HAS_CREATOR]->(person:Person)
      ORDER BY messageCreationDate DESC, messageId ASC
      RETURN
        messageId,
        CASE WHEN message.content <> ""
            THEN message.content
            ELSE message.imageFile
        END AS messageContent,
        messageCreationDate,
        post.id AS postId,
        person.id AS personId,
        person.firstName AS personFirstName,
        person.lastName AS personLastName
      """
    Then the result should be, in order:
      | messageId     | messageContent                                                                                                     | messageCreationDate                   | postId        | personId       | personFirstName | personLastName |
      | 1099511681331 | "About Ferdinand Marcos, nd his wife Imelda Marcos had moved billAbout Edward H"                                   | DATETIME '2012-09-12T17:42:37.462000' | 1099511681326 | 21990232555889 | "Yang"          | "Lei"          |
      | 1099511885009 | "About Augustine of Hippo, n the Eastern Orthodox Church he is also consideAbout Giuseppe Garib"                   | DATETIME '2012-09-10T00:24:54.265000' | 1099511885009 | 28587302322974 | "Zhang"         | "Li"           |
      | 1030792390882 | "thanks"                                                                                                           | DATETIME '2012-09-05T03:00:37.011000' | 1030792390865 | 24189255812657 | "Jun"           | "Yang"         |
      | 1030792508198 | "thx"                                                                                                              | DATETIME '2012-08-24T06:22:31.700000' | 1030792508189 | 19791209301664 | "Yang"          | "Li"           |
      | 1030792332571 | "good"                                                                                                             | DATETIME '2012-08-22T02:24:43.380000' | 1030792332555 | 30786325578747 | "Zhang"         | "Huang"        |
      | 1030792248964 | "cool"                                                                                                             | DATETIME '2012-08-19T20:29:47.271000' | 1030792248954 | 17592186044868 | "Wei"           | "Huang"        |
      | 1030792385478 | "roflol"                                                                                                           | DATETIME '2012-08-14T18:49:14.798000' | 1030792385476 | 6597069766797  | "Yang"          | "Li"           |
      | 1030792258004 | "great"                                                                                                            | DATETIME '2012-08-01T15:59:26.582000' | 1030792258002 | 10995116277765 | "Eric"          | "Mettacara"    |
      | 1030792257960 | "About Dominion of Newfoundland, plus a governor) administered Newfoundland, reporting "                           | DATETIME '2012-07-31T12:23:04.323000' | 1030792257956 | 10995116277765 | "Eric"          | "Mettacara"    |
      | 1030792408294 | "About Augustine of Hippo, dered a saint, his feast day being celAbout John Calvin,  Philipp Melanchthon and Hein" | DATETIME '2012-07-14T18:59:37.896000' | 1030792408294 | 28587302322974 | "Zhang"         | "Li"           |

  @sf01
  Scenario: _IS3FriendsOfAPerson
    When executing query:
      """
      USE sf01
      MATCH (n:Person WHERE n.id = 26388279067635)<-[r:KNOWS]->(friend:Person)
      ORDER BY
          r.creationDate DESC,
          friend.id ASC
      RETURN
        friend.id AS personId,
        friend.firstName AS firstName,
        friend.lastName AS lastName,
        r.creationDate AS friendshipCreationDate
      """
    Then the result should be, in order:
      | personId       | firstName           | lastName       | friendshipCreationDate                |
      | 32985348834824 | "Lei"               | "Chen"         | DATETIME '2012-08-10T03:11:44.892000' |
      | 32985348833673 | "Muhammad"          | "Qureshi"      | DATETIME '2012-07-30T14:13:08.225000' |
      | 32985348834483 | "Michel"            | "Breton"       | DATETIME '2012-07-28T13:45:54.964000' |
      | 32985348834375 | "Alfred"            | "Hoffmann"     | DATETIME '2012-07-26T11:56:36.708000' |
      | 32985348834100 | "Bruno"             | "Oliveira"     | DATETIME '2012-07-25T07:12:28.075000' |
      | 32985348833438 | "Javed"             | "Khan"         | DATETIME '2012-07-17T12:24:26.887000' |
      | 30786325578585 | "Ayesha"            | "Butt"         | DATETIME '2012-07-11T06:32:32.922000' |
      | 30786325578676 | "Jana"              | "Kerndlova"    | DATETIME '2012-07-09T00:31:38.484000' |
      | 28587302322553 | "Adam"              | "Supinyo"      | DATETIME '2012-05-13T02:45:15.010000' |
      | 28587302322548 | "Grigore"           | "Bologan"      | DATETIME '2012-05-04T00:51:28.929000' |
      | 4398046512573  | "Eko Maulana"       | "Irama"        | DATETIME '2012-03-15T14:45:55.641000' |
      | 8796093022574  | "Abdul-Malik"       | "Binalshibh"   | DATETIME '2012-03-14T14:00:37.020000' |
      | 290            | "Ayesha"            | "Baloch"       | DATETIME '2012-03-13T20:43:40.941000' |
      | 4398046512548  | "Mikhail"           | "Sheik"        | DATETIME '2012-03-13T09:01:34.494000' |
      | 26388279066885 | "Andrei"            | "Kahnovich"    | DATETIME '2012-03-13T02:19:59.270000' |
      | 15393162789219 | "Alex Obanda"       | "Ngoche"       | DATETIME '2012-03-11T07:06:31.670000' |
      | 10995116279452 | "Mohammad Reza"     | "Forouhar"     | DATETIME '2012-03-10T14:01:46.560000' |
      | 2199023256816  | "K."                | "Bose"         | DATETIME '2012-03-09T15:49:36.119000' |
      | 2199023256893  | "Babar"             | "Hussain"      | DATETIME '2012-03-09T04:03:36.236000' |
      | 1481           | "Akira"             | "Takahashi"    | DATETIME '2012-03-07T23:32:04.289000' |
      | 8796093023897  | "Zheng"             | "Liu"          | DATETIME '2012-03-07T14:40:56.872000' |
      | 13194139534578 | "Kunal"             | "Sharma"       | DATETIME '2012-03-06T18:52:46.022000' |
      | 8796093023903  | "Faisal"            | "Malik"        | DATETIME '2012-03-04T23:48:17.154000' |
      | 26388279067534 | "Emperor of Brazil" | "Dom Pedro II" | DATETIME '2012-03-04T05:52:26.335000' |
      | 26388279067805 | "Chi"               | "Li"           | DATETIME '2012-03-03T19:44:25.384000' |
      | 2199023256456  | "John"              | "Singh"        | DATETIME '2012-03-03T11:58:01.347000' |
      | 8796093022467  | "Muhammad"          | "Amjad"        | DATETIME '2012-03-02T17:52:12.023000' |
      | 21990232555834 | "John"              | "Garcia"       | DATETIME '2012-03-02T12:08:10.250000' |
      | 21990232556585 | "Faisal"            | "Malik"        | DATETIME '2012-03-01T11:48:11.880000' |
      | 17592186045093 | "Aamer"             | "Ahmed"        | DATETIME '2012-02-27T16:04:38.512000' |
      | 17592186045551 | "Muhammad"          | "Ahmed"        | DATETIME '2012-02-24T01:22:14.044000' |
      | 26388279067868 | "Tariq"             | "Amjad"        | DATETIME '2012-02-22T19:07:35.928000' |
      | 1160           | "Ching"             | "Do"           | DATETIME '2012-02-22T04:27:14.254000' |
      | 13194139534982 | "Rafael"            | "Alves"        | DATETIME '2012-02-22T00:02:04.736000' |
      | 24189255811116 | "Alexei"            | "Kahnovich"    | DATETIME '2012-02-17T16:23:49.657000' |
      | 6597069767708  | "Abdou"             | "Dia"          | DATETIME '2012-02-17T15:32:10.258000' |
      | 24189255812047 | "Djelaludin"        | "Jahani"       | DATETIME '2012-02-17T02:05:51.249000' |
      | 17592186044425 | "Alim"              | "Guliyev"      | DATETIME '2012-02-15T18:16:52.555000' |

  @sf01
  Scenario: _IS4ContentOfAMessage
    When executing query:
      """
      USE sf01
      MATCH (m:Message WHERE m.id = 206158435983 or m.id = 687194815415)
      RETURN
        m.creationDate as messageCreationDate,
        CASE WHEN m.content <> ""
            THEN m.content
            ELSE m.imageFile
        END AS messageContent
      """
    Then the result should be, in any order:
      | messageCreationDate                   | messageContent                                                                          |
      | DATETIME '2010-08-13T14:04:01.094000' | "thanks"                                                                                |
      | DATETIME '2011-10-13T18:05:58.776000' | "About Luxembourg,  grand duke. It isAbout Fight the Power, ideo by Public EneAbout Ma" |

  @sf01
  Scenario: _IS5CreatorOfAMessage
    When executing query:
      """
      USE sf01
      MATCH (m:Message WHERE m.id = 1099511823013)-[:HAS_CREATOR]->(p:Person)
      RETURN
          p.id AS personId,
          p.firstName AS firstName,
          p.lastName AS lastName
      """
    Then the result should be, in any order:
      | personId      | firstName  | lastName |
      | 8796093023634 | "Bingjian" | "Zhang"  |

  @sf01
  Scenario: _IS6ForumOfAMessage
    When executing query:
      """
      USE sf01
      MATCH WALK (m:Message WHERE m.id = 1099511823013)-[:REPLY_OF]->{0,3}(p:Post)<-[:CONTAINER_OF]-(f:Forum)-[:HAS_MODERATOR]->(moderator:Person)
      RETURN
        f.id AS forumId,
        f.title AS forumTitle,
        moderator.id AS moderatorId,
        moderator.firstName AS moderatorFirstName,
        moderator.lastName AS moderatorLastName
      """
    Then the result should be, in any order:
      | forumId      | forumTitle                               | moderatorId | moderatorFirstName | moderatorLastName |
      | 481036344986 | "Group for Silly_Love_Songs in Dehradun" | 1549        | "John"             | "Kumar"           |

  @sf01
  Scenario: _IS7RepliesOfAMessage
    When executing query:
      """
      USE sf01
      MATCH (m:Message WHERE m.id = 1099511823022)<-[:REPLY_OF]-(c:Comment)-[:HAS_CREATOR]->(p:Person)
      OPTIONAL MATCH (m:Message WHERE m.id = 1099511823022)-[:HAS_CREATOR]->(a:Person)<-[r:KNOWS]->(p:Person)
      ORDER BY c.creationDate DESC, p.id
      RETURN c.id AS commentId,
          c.content AS commentContent,
          c.creationDate AS commentCreationDate,
          p.id AS replyAuthorId,
          p.firstName AS replyAuthorFirstName,
          p.lastName AS replyAuthorLastName,
          CASE WHEN r is null THEN false ELSE true
          END AS replyAuthorKnowsOriginalMessageAuthor
      """
    Then the result should be, in order:
      | commentId     | commentContent | commentCreationDate                   | replyAuthorId | replyAuthorFirstName | replyAuthorLastName | replyAuthorKnowsOriginalMessageAuthor |
      | 1099511823023 | "right"        | DATETIME '2012-09-12T09:11:43.098000' | 6597069766850 | "Claude"             | "Aly"               | false                                 |
      | 1099511823028 | "no"           | DATETIME '2012-09-12T08:12:10.260000' | 2199023256321 | "dou"                | "Faye"              | false                                 |
