# Copyright (c) 2024 vesoft inc. All rights reserved.
# issues: https://github.com/vesoft-inc/nebula-ng/issues/3936
@skip
Feature: LDBCInteractiveWorkload_ComplexReads

  @BI1
  Scenario: BI1_posting_summary
    When executing query:
      """
      $datetime=TIMESTAMP "2012-11-21T11:28:30.662+00"
      LET totalCount = VALUE {
        USE snb_bi_sf01
        MATCH (msg:Message)
        WHERE msg.creationDate < $datetime
        RETURN count(*) GROUP BY()
      } RETURN totalCount * 1.0 as totalCount
      NEXT
      MATCH (msg:Message)
      WHERE msg.creationDate < $datetime
        and length(msg.content) >= 0
      LET year =  msg.creationDate.year,
        isComment = "Comment" in labels(msg),
        lengthCategory = CASE
          WHEN length(msg.content) < 40 THEN 0
          WHEN length(msg.content) < 80 THEN 1
          WHEN length(msg.content) < 160 THEN 2
          ELSE 3
        END
      RETURN
        year,
        isComment,
        totalCount,
        count(*) as messageCount,
        avg(length(msg.content)) as averageMessageLength,
        sum(length(msg.content)) as sumMessageLength,
        lengthCategory
      GROUP BY
        year,
        isComment,
        lengthCategory,
        totalCount
      NEXT
        RETURN year, isComment, lengthCategory, messageCount, averageMessageLength, sumMessageLength, messageCount / totalCount as percentageOfMessages
        ORDER BY year desc, isComment asc, lengthCategory asc
      """
    Then the result should be, in order:
      | year | isComment | lengthCategory | messageCount | averageMessageLength | sumMessageLength | percentageOfMessages  |
      | 2012 | false     | 0              | 68834        | 0.0                  | 0                | 0.22036964114778923   |
      | 2012 | false     | 2              | 9312         | 105.15861254295532   | 979237           | 0.029812041990414814  |
      | 2012 | false     | 3              | 1137         | 204.04573438874232   | 232000           | 0.0036400656940616025 |
      | 2012 | true      | 0              | 88727        | 4.191486244322473    | 371898           | 0.28405638420141055   |
      | 2012 | true      | 1              | 13192        | 76.38439963614312    | 1007663          | 0.04223372615308765   |
      | 2012 | true      | 2              | 28990        | 92.6405657123146     | 2685650          | 0.09281047007110453   |
      | 2012 | true      | 3              | 1917         | 173.5863328116849    | 332765           | 0.0061372083865576885 |
      | 2011 | false     | 0              | 50924        | 0.0                  | 0                | 0.16303140317009063   |
      | 2011 | false     | 2              | 6263         | 104.99233594124222   | 657567           | 0.02005077523474742   |
      | 2011 | false     | 3              | 766          | 205.49869451697128   | 157412           | 0.002452322182630772  |
      | 2011 | true      | 0              | 12616        | 4.18365567533291     | 52781            | 0.040389682318629     |
      | 2011 | true      | 1              | 1906         | 76.45278069254984    | 145719           | 0.006101992271663513  |
      | 2011 | true      | 2              | 4202         | 92.9588291289862     | 390613           | 0.01345255588957507   |
      | 2011 | true      | 3              | 289          | 177.01384083044982   | 51157            | 0.0009252233822197038 |
      | 2010 | false     | 0              | 18403        | 0.0                  | 0                | 0.05891656021795574   |
      | 2010 | false     | 2              | 2859         | 105.10213361315145   | 300487           | 0.00915298840749527   |
      | 2010 | false     | 3              | 333          | 203.02702702702703   | 67608            | 0.001066087841796406  |
      | 2010 | true      | 0              | 1172         | 4.1058020477815695   | 4812             | 0.0037521169687248887 |
      | 2010 | true      | 1              | 160          | 76.45625             | 12233            | 0.0005122343984607356 |
      | 2010 | true      | 2              | 335          | 92.01492537313433    | 30825            | 0.0010724907717771651 |
      | 2010 | true      | 3              | 20           | 172.2                | 3444             | 6.402929980759195e-05 |

  @BI2
  Scenario: BI2_tag_evolution
    When executing query:
      """
      $date=date "2012-12-21",$tagClass="Person"
      USE snb_bi_sf01
      MATCH (tag:Tag)-[:TAG_HAS_TYPE_TAGCLASS]->(:TagClass {name: $tagClass})
      OPTIONAL MATCH (message1:Message)-[:POST_HAS_TAG_TAG|COMMENT_HAS_TAG_TAG]->(tag),
          (message2:Message)-[:HAS_TAG]->(tag)
        WHERE $date <= message1.creationDate
          AND message1.creationDate < datetime "2012-11-21T11:28:30.662+00:00"
      RETURN tag, count(message1) AS countWindow1 GROUP BY tag
      NEXT
      USE snb_bi_sf01
      OPTIONAL MATCH (message2:Message)-[:HAS_TAG]->(tag)
        WHERE datetime "2012-11-21T11:28:30.662+00:00" <= message2.creationDate
          AND message2.creationDate < datetime "2012-12-21T11:28:30.662+00:00"
      RETURN
        tag,
        count(message2) AS countWindow2,
        countWindow1
      GROUP BY
        tag,
        countWindow1
      NEXT
        RETURN
        tag.name,
        countWindow1, countWindow2,
        abs(countWindow1 - countWindow2) AS diff
      ORDER BY
        diff DESC,
        tag.name ASC
      LIMIT
        100
      """
    Then the execution should be successful

  @BI3
  Scenario: BI3_popular_topics_in_a_country
    When executing query:
      """
      $country="China",$tagClass="Person"
      USE snb_bi_sf01
      MATCH (:TagClass {name: $tagClass})<-[:HAS_TYPE]-(:Tag)<-[:HAS_TAG]-(message:Message)-[:REPLY_OF]->*(post)<-[:CONTAINER_OF]-(forum:Forum)
        -[:HAS_MODERATOR]->(person:Person)-[:IS_LOCATED_IN]->(:City)-[:IS_PART_OF]->(:Country {name: $country})
      RETURN
        forum.id as forum_id,
        forum.title as forum_title,
        forum.creationDate as forum_date,
        person.id as person_id,
        count(message) as messageCount
      GROUP BY
        forum_id,
        forum_title,
        forum_date,
        person_id
      ORDER BY
        messageCount DESC,
        forum_id ASC
      LIMIT
        20
      """
    Then the execution should be successful

  @BI4
  Scenario: BI4_top_message_creators_by_country
    When executing query:
      """
      $date=TIMESTAMP "2012-11-21T11:28:30.662+00"
      USE snb_bi_sf01
      MATCH (country:Country)<-[:IS_PART_OF]-(:City)<-[:IS_LOCATED_IN]-(person:Person)<-[:HAS_MEMBER]-(forum:Forum)
        WHERE forum.creationDate > $date
      RETURN
        DISTINCT forum as selectedForum,
        country,
        count(person) as numberOfMembers
      GROUP BY
        selectedForum,
        country
      ORDER BY
        numberOfMembers DESC,
        selectedForum.id ASC,
        country.id
      LIMIT 100
      NEXT
      RETURN
        collect(selectedForum) as topForums GROUP BY()
      NEXT
      MATCH (topForum1:Forum)-[:CONTAINER_OF]->(post:Post)<-[:REPLY_OF]-(message:Message)-[:HAS_CREATOR]->(person:Person)<-[:HAS_MEMBER]-(topForum2:Forum)
      WHERE
        topForum1 in topForums
        AND topForum2 in topForums
      RETURN
        person,
        count(DISTINCT message) AS messageCount
      GROUP BY
        person
      UNION ALL
      MATCH (person:Person)<-[:HAS_MEMBER]-(topForum3:Forum)
      WHERE
        topForum3 in topForums
      RETURN
        person,
        0 AS messageCount
      NEXT
      RETURN
        person.id as PersonID,
        person.firstName as PersonFirstName,
        person.lastName as PersonLastName,
        person.creationDate as PersonCreationDate,
        messageCount
      ORDER BY
        messageCount DESC,
        PersonID ASC
      LIMIT
        100
      """
    Then the execution should be successful

  @BI5
  Scenario: BI5_most_active_posters_of_a_given_topic
    When executing query:
      """
      $tag="China"
      USE snb_bi_sf01
      MATCH (tag:Tag {name: $tag})<-[:HAS_TAG]-(message:Message)-[:HAS_CREATOR]->(person:Person)
      OPTIONAL MATCH (message)<-[likes:LIKES]-(:Person)
      RETURN
        person,
        likes,
        message
      NEXT
      OPTIONAL MATCH (message)<-[:REPLY_OF]-(reply:Comment)
      RETURN
        person,
        count(likes) as likeCount,
        count(message) as messageCount,
        count(reply) as replyCount
      GROUP BY
        person
      NEXT
      RETURN
        person.id,
        replyCount,
        likeCount,
        messageCount,
        1 * messageCount + 2 * replyCount + 10 * likeCount as score
      ORDER BY
        score DESC,
        person.id ASC
      LIMIT
        100
      """

  @BI6
  Scenario: BI6_most_authoritative_users_on_a_given_topic
    When executing query:
      """
      $tag="China"
      USE snb_bi_sf01
      MATCH (tag:Tag {name: $tag})<-[:HAS_TAG]-(message1:Message)-[:HAS_CREATOR]->(person1:Person)
      RETURN
        person1,
        message1
      NEXT
      OPTIONAL MATCH (message1)<-[:LIKES]-(person2:Person)
      RETURN
        person1,
        person2
      NEXT
      OPTIONAL MATCH (person2)<-[:HAS_CREATOR]-(message2:Message)<-[eLike:LIKES]-(person3:Person)
      RETURN
        person1.id,
        count(eLike) AS authorityScore
      GROUP BY
        person1
      ORDER BY
        authorityScore DESC,
        person1.id ASC
      LIMIT
        100
      """
    Then the execution should be successful

  @BI7
  Scenario: BI7_related_topics
    When executing query:
      """
      $tag="China"
      USE snb_bi_sf01
      MATCH (tag:Tag {name: $tag})<-[:HAS_TAG]-(message:Message), (message)<-[:REPLY_OF]-(comment:Comment)-[:HAS_TAG]->(relatedTag:Tag)
      WHERE NOT EXISTS ((comment)-[:HAS_TAG]->(tag))
      RETURN
        relatedTag,
        count(DISTINCT comment) AS commentCounter
      GROUP BY
        relatedTag
      ORDER BY
        commentCounter DESC,
        relatedTag.name ASC
      LIMIT
        100
      """
    Then the execution should be successful

  @BI8
  Scenario: BI8_central_person_for_a_tag
    When executing query:
      """
      $tag="China",$startDate=TIMESTAMP "2012-11-21T11:28:30.662",$endDate=TIMESTAMP "2012-11-21T11:28:30.662"
      USE snb_bi_sf01
       MATCH (tag: Tag{name: $tag})<-[interest:HAS_INTEREST]-(person:Person)
      RETURN
        tag,
        person
      UNION
       MATCH (tag)<-[:HAS_TAG]-(message:Message)-[:HAS_CREATOR]->(person:Person)
      WHERE $startDate < message.creationDate
        AND message.creationDate < $endDate
      RETURN
        tag,
        person
      """
    Then the execution should be successful

  @BI9
  Scenario: BI9_top_thread_initiators
    When executing query:
      """
      $startDate=TIMESTAMP "2012-11-21T11:28:30.662",$endDate=TIMESTAMP "2012-11-21T11:28:30.662"
      USE snb_bi_sf01
      MATCH (person:Person)<-[:HAS_CREATOR]-(post:Post)*<-[:REPLY_OF]-(reply:Message)
      WHERE  post.creationDate >= $startDate
        AND  post.creationDate <= $endDate
        AND reply.creationDate >= $startDate
        AND reply.creationDate <= $endDate
      RETURN
        person.id as personID,
        person.firstName as personFirstName,
        person.lastName as personLastName,
        count(DISTINCT post) AS threadCount,
        count(DISTINCT reply) AS messageCount
      GROUP BY
        personID,
        personFirstName,
        personLastName
      ORDER BY
        messageCount DESC,
        person.id ASC
      LIMIT 100
      """
    Then the execution should be successful

  @BI10
  Scenario: BI10_experts_in_social_circle
    When executing query:
      """
      $persionID=100,$minPathDistance=1,$maxPathDistance=3,$country="China",$tagClass="Person"
      USE snb_bi_sf01
      MATCH path1 = ANY SHORTEST PATH (startPerson:Person{id: $persionID})<-[:KNOWS]->*(expertCandidatePerson:Person)-[:IS_LOCATED_IN]->(:City)-[:IS_PART_OF]->(:Country {name: $country})
      WHERE
        length(path1) >= $minPathDistance + 2
        AND length(path1) <= $maxPathDistance + 2
      MATCH (message:Message)-[:HAS_CREATOR]->(expertCandidatePerson)
      RETURN
        message,
        expertCandidatePerson
      NEXT
      MATCH (tag:Tag)<-[:HAS_TAG]-(message)-[:HAS_TAG]->(:Tag)-[:HAS_TYPE]->(:TagClass {name: $tagClass})
      RETURN
        count(message) as messageCount,
        tag.name as tagName,
        expertCandidatePerson.id as expertCandidatePersonID
      GROUP BY
        expertCandidatePersonID,
        tagName
      ORDER BY
        messageCount  DESC,
        tagName ASC,
        expertCandidatePersonID ASC
      LIMIT
        100
      """
    Then the execution should be successful

  @BI11
  Scenario: BI11_friend_triangles
    When executing query:
      """
      $country="China",$startDate=TIMESTAMP "2012-11-21T11:28:30.662+00",$endDate=TIMESTAMP "2012-11-21T11:28:30.662+00"
      USE snb_bi_sf01
      MATCH (a:Person)-[:IS_LOCATED_IN]->(:City)-[:IS_PART_OF]->(country:Country {name: $country}), (a)-[k1:KNOWS]-(b:Person)
      WHERE a.id < b.id
        AND k1.creationDate >= $startDate
        AND k1.creationDate <= $endDate
      RETURN
        DISTINCT country,
        a,
        b
      NEXT
      MATCH (b)-[:IS_LOCATED_IN]->(:City)-[:IS_PART_OF]->(country)
      RETURN
        DISTINCT country,
        a,
        b
      NEXT
      MATCH (b)-[k2:KNOWS]-(c:Person), (c)-[:IS_LOCATED_IN]->(:City)-[:IS_PART_OF]->(country)
      WHERE b.id < c.id
        AND k2.creationDate >= $startDate
        AND k2.creationDate <= $endDate
      RETURN
        DISTINCT a,
        b,
        c
      NEXT
      MATCH (c)-[k3:KNOWS]-(a)
      WHERE k3.creationDate >= $startDate
        AND k3.creationDate <= $endDate
      RETURN
        DISTINCT a,
        b,
        c
      NEXT
      RETURN count(*)
      GROUP BY ()
      """
    Then the execution should be successful

  @BI12
  Scenario: BI12_how_many_persons_have_a_given_number_of_messages
    When executing query:
      """
      $startDate=TIMESTAMP "2012-11-21T11:28:30.662+00",$lengthThreshold=10,$languages=["Chinese", "English"]
      USE snb_bi_sf01
      MATCH (person:Person)<-[:HAS_CREATOR]-(message:Message)-[:REPLY_OF]->*(post:Post)
      WHERE message.content is NOT NULL
        AND $startDate < message.creationDate
        AND length(message.content) < $lengthThreshold
        AND length(post.imageFile) = 0
        AND post.language in $languages
      RETURN
        person,
        count(message) as messageCount
      GROUP BY
        person
      NEXT
      RETURN
        messageCount,
        count(person) as personCount
      GROUP BY
        messageCount
      ORDER BY
        personCount DESC,
        messageCount DESC
      """
    Then the execution should be successful

  @BI13
  Scenario: BI13_zombies_in_a_country
    When executing query:
      """
      $country="China",$endDate=TIMESTAMP "2024-12-21T11:28:30.662+00"
      USE snb_bi_sf01
      MATCH (country:Country{name: $country})<-[:IS_PART_OF]-(:City)<-[:IS_LOCATED_IN]-(zombie:Person)
        WHERE zombie.creationDate < $endDate
      RETURN
        country,
        zombie
      NEXT
      OPTIONAL MATCH (zombie)<-[:HAS_CREATOR]-(message:Message)
        WHERE message.creationDate < $endDate
      RETURN
        country,
        zombie,
        count(message) as messageCount
      GROUP BY
        country,
        zombie
      NEXT
      RETURN
        country,
        zombie,
        12.0 * ($endDate.year  - zombie.creationDate.year ) + ($endDate.month - zombie.creationDate.month) + 1 AS months,
        messageCount
      NEXT
      FILTER
        messageCount / months < 1
      OPTIONAL MATCH (zombie)-[:HAS_CREATOR]->(message:Message)<-[:LIKES]-(likerPerson:Person)
      WHERE EXISTS ((likerPerson)-[:HAS_CREATOR]->(message))
      RETURN
        zombie,
        count(likerPerson) as zombieLikeCount
      GROUP BY
        zombie
      NEXT
      OPTIONAL MATCH (zombie)-[:HAS_CREATOR]->(message:Message)<-[:LIKES]-(likerPerson:Person)
      WHERE likerPerson.creationDate < $endDate
      RETURN
        zombie,
        zombieLikeCount,
        count(likerPerson) as totalLikeCount
      GROUP BY
        zombie,
        zombieLikeCount
      NEXT
      RETURN
        zombie.id,
        zombieLikeCount,
        totalLikeCount,
        CASE WHEN totalLikeCount = 0 THEN 0 ELSE zombieLikeCount * 1.0 / totalLikeCount END AS zombieScore
      ORDER BY
        zombieScore DESC,
        zombie.id ASC
      """
    Then the execution should be successful

  @BI14
  Scenario: BI14_international_dialog
    When executing query:
      """
      $country1="China",$country2="United States"
      USE snb_bi_sf01
      MATCH
        (country1:Country {name: $country1})<-[:IS_PART_OF]-(city1:City)<-[:IS_LOCATED_IN]-(person1:Person),
        (country2:Country {name: $country2})<-[:IS_PART_OF]-(city2:City)<-[:IS_LOCATED_IN]-(person2:Person),
        (person1)-[:KNOWS]-(person2)
      RETURN
        DISTINCT person1,
        person2,
        city1,
        0 as score
      NEXT
      OPTIONAL MATCH (person1)<-[:HAS_CREATOR]-(c:Comment)-[:REPLY_OF]->(:Message)-[:HAS_CREATOR]->(person2)
      RETURN
        DISTINCT person1,
        person2,
        city1,
        score + (CASE WHEN c IS NULL THEN 0 ELSE 4 END) as score
      NEXT
      OPTIONAL MATCH (person1)<-[:HAS_CREATOR]-(m:Message)<-[:REPLY_OF]-(:Comment)-[:HAS_CREATOR]->(person2)
      RETURN
        DISTINCT person1,
        person2,
        city1,
        score + (CASE WHEN m IS NULL THEN 0 ELSE 1 END) as score
      NEXT
      OPTIONAL MATCH (person1)-[:LIKES]->(m:Message)-[:HAS_CREATOR]->(person2)
      RETURN
        DISTINCT person1,
        person2,
        city1,
        score + (CASE WHEN m IS NULL THEN 0 ELSE 10 END) as score
      NEXT
      OPTIONAL MATCH (person1)<-[:HAS_CREATOR]-(m:Message)<-[:LIKES]-(person2)
      RETURN
        DISTINCT person1,
        person2,
        city1,
        score + (CASE WHEN m IS NULL THEN 0 ELSE  1 END) AS score
      ORDER BY
        city1.name ASC,
        score DESC,
        person1.id ASC,
        person2.id ASC
      NEXT
      RETURN
        city1,
        collect({score: score, person1ID: person1.id, person2ID: person2.id})[0] AS top
      GROUP BY
        city1
      NEXT
      RETURN
        top.person1ID,
        top.person2ID,
        city1.name,
        top.score
      ORDER BY
        top.score DESC,
        top.person1ID ASC,
        top.person2ID ASC
      LIMIT
        100
      """
    Then the execution should be successful

  # @BI15
  # Scenario: BI15_trusted_connection_paths_through_forums_created_in_a_given_timeframe
  # https://github.com/vesoft-inc/nebula-ng/issues/3975
  # @BI16
  # Scenario: BI16_fake_news_detection
  # https://github.com/vesoft-inc/nebula-ng/issues/3977
  @BI17
  Scenario: BI17_information_propagation_analysis
    When exeucting query:
      """
      $tag='someTag',$delta=4
      USE snb_bi_sf01
      MATCH
        (tag:Tag {name: $tag}),
        (person1:Person)<-[:HAS_CREATOR]-(message1:Message)-[:REPLY_OF]->*(post1:Post)<-[:CONTAINER_OF]-(forum1:Forum),
        (message1)-[:HAS_TAG]->(tag),
        (forum1)<-[:HAS_MEMBER]->(person2:Person)<-[:HAS_CREATOR]-(comment:Comment)-[:HAS_TAG]->(tag),
        (forum1)<-[:HAS_MEMBER]->(person3:Person)<-[:HAS_CREATOR]-(message2:Message),
        (comment)-[:REPLY_OF]->(message2)-[:REPLY_OF]->*(post2:Post)<-[:CONTAINER_OF]-(forum2:Forum)
      MATCH (comment)-[:HAS_TAG]->(tag)
      MATCH (message2)-[:HAS_TAG]->(tag)
      WHERE forum1 <> forum2
        AND message2.creationDate > message1.creationDate + duration({hours: $delta})
        AND NOT (forum2)-[:HAS_MEMBER]->(person1)
      RETURN person1.id, count(DISTINCT message2) AS messageCount
      ORDER BY messageCount DESC, person1.id ASC
      LIMIT 10
      """
    Then the exeuction should be successful

  @BI18
  Scenario: BI18_friend_recommendation
    When executing query:
      """
      $tag="someTag"
      USE snb_bi_sf01
      MATCH (tag:Tag {name: $tag})<-[:HAS_INTEREST]-(person1:Person)-[:KNOWS]-(mutualFriend:Person)-[:KNOWS]-(person2:Person)-[:HAS_INTEREST]->(tag)
      WHERE person1 <> person2
        AND NOT EXISTS ((person1)-[:KNOWS]-(person2))
      RETURN
        person1.id AS person1Id,
        person2.id AS person2Id,
        count(DISTINCT mutualFriend) AS mutualFriendCount
      GROUP BY
        person1Id,
        person2Id
      ORDER BY mutualFriendCount DESC, person1Id ASC, person2Id ASC
      LIMIT 20
      """
    Then the execution should be successful

# @BI19
# Scenario: BI19_interaction_path_between_cities
# https://github.com/vesoft-inc/nebula-ng/issues/3975
# @BI20
# Scenario: BI20_recruitment
# https://github.com/vesoft-inc/nebula-ng/issues/3975
