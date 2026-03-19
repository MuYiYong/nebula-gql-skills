# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: LDBCInteractiveWorkload_ComplexReads

  @sf01 @ic1
  Scenario: _IC1TransitiveFriendsWithCertainName
    When executing query:
      """
      USE sf01 {
      MATCH (p:Person{id : 24189255811707}), (friend:Person{firstName : "Jun"})
        WHERE p<>friend
      MATCH path = ANY SHORTEST PATH (p:Person{id: 24189255811707})<-[:KNOWS]->{1,3}(friend:Person)
      RETURN min(length(path)) AS distance, friend GROUP BY friend
      NEXT
      ORDER BY
          distance ASC,
          friend.lastName ASC,
          friend.id ASC
      LIMIT 20
      MATCH (friend:Person)-[:IS_LOCATED_IN]->(friendCity:City)
      OPTIONAL MATCH (friend:Person)-[studyAt:STUDY_AT]->(uni:University)-[:IS_LOCATED_IN]->(uniCity:City)
      RETURN collect(
        CASE
          WHEN NOT uni.name IS NULL THEN RECORD {uniName:uni.name, studyAtClassYear:studyAt.classYear,
            uniCityName:uniCity.name}
        END
        ) AS unis, friend, friendCity, distance GROUP BY friend, friendCity, distance
      NEXT
      OPTIONAL MATCH (friend:Person)-[workAt:WORK_AT]->(company:Company)-[:IS_LOCATED_IN]->(companyCountry:Country)
      ORDER BY
          company.name ASC,
          workAt.workFrom ASC,
          companyCountry.name ASC
      RETURN collect(
        CASE
          WHEN NOT company.name is null THEN RECORD {companyName:company.name, workAtWorkFrom:workAt.workFrom,
            companyCountryName:companyCountry.name}
        END
        ) AS companies, friend, unis, friendCity, distance GROUP BY friend, unis, friendCity, distance
      NEXT
      ORDER BY
          distance ASC,
          friend.lastName ASC,
          friend.id ASC
      LIMIT 20
      RETURN
          friend.id AS friendId,
          friend.lastName AS friendLastName,
          distance AS distanceFromPerson,
          friend.birthday AS friendBirthday,
          friend.creationDate AS friendCreationDate,
          friend.gender AS friendGender,
          friend.browserUsed AS friendBrowserUsed,
          friend.locationIP AS friendLocationIp,
          friend.email AS friendEmails,
          friend.speaks AS friendLanguages,
          friendCity.name AS friendCityName,
          unis AS friendUniversities,
          companies AS friendCompanies
      }
      """
    Then the result should be, in order:
      | friendId       | friendLastName | distanceFromPerson | friendBirthday    | friendCreationDate                    | friendGender | friendBrowserUsed   | friendLocationIp | friendEmails                                                                                                   | friendLanguages | friendCityName | friendUniversities                                                                                                                  | friendCompanies                                                                                                                                                                                                                                                                                                                                                                                                                        |
      | 8796093022435  | "Chen"         | 2                  | DATE '1981-04-07' | DATETIME '2010-10-05T03:14:06.553000' | "female"     | "Chrome"            | "1.207.98.196"   | "Jun8796093022435@gmx.com"                                                                                     | "zh,en"         | "Chizhou"      | LIST[]                                                                                                                              | LIST[{companyCountryName:"China",companyName:"Chang'an_Airlines",workAtWorkFrom:2011}]                                                                                                                                                                                                                                                                                                                                                 |
      | 26388279067358 | "Chen"         | 2                  | DATE '1983-12-01' | DATETIME '2012-01-23T11:48:36.524000' | "female"     | "Firefox"           | "1.4.4.25"       | "Jun26388279067358@gmail.com"                                                                                  | "zh,en"         | "Lanzhou"      | LIST[]                                                                                                                              | LIST[{companyCountryName:"China",companyName:"Shenzhen_Donghai_Airlines",workAtWorkFrom:2004}]                                                                                                                                                                                                                                                                                                                                         |
      | 21990232557038 | "He"           | 2                  | DATE '1980-03-23' | DATETIME '2011-09-10T03:50:55.636000' | "female"     | "Firefox"           | "1.28.102.211"   | "Jun21990232557038@gmail.com,Jun21990232557038@gmx.com,Jun21990232557038@yahoo.com"                            | "zh,en"         | "Hefei"        | LIST[{studyAtClassYear:2000,uniCityName:"Xi'an",uniName:"Xi'an_Polytechnic_University"}]                                            | LIST[{companyCountryName:"China",companyName:"Air_China_Cargo",workAtWorkFrom:2001},{companyCountryName:"China",companyName:"China_Southern_Airlines",workAtWorkFrom:2000},{companyCountryName:"China",companyName:"Shenzhen_Airlines",workAtWorkFrom:2000},{companyCountryName:"China",companyName:"United_Eagle_Airlines",workAtWorkFrom:2000}]                                                                                      |
      | 17592186045019 | "Ito"          | 2                  | DATE '1983-06-19' | DATETIME '2011-07-01T19:47:52.978000' | "female"     | "Chrome"            | "27.118.2.33"    | "Jun17592186045019@gmail.com"                                                                                  | "ja,en"         | "Osaka"        | LIST[{studyAtClassYear:2005,uniCityName:"Hachinohe",uniName:"Hachinohe_Junior_College"}]                                            | LIST[]                                                                                                                                                                                                                                                                                                                                                                                                                                 |
      | 32985348833702 | "Kato"         | 2                  | DATE '1986-08-14' | DATETIME '2012-07-17T10:09:57.251000' | "female"     | "Internet Explorer" | "27.111.77.194"  | "Jun32985348833702@gmail.com,Jun32985348833702@gmx.com,Jun32985348833702@yahoo.com,Jun32985348833702@zoho.com" | "ja,en"         | "Chiyoda"      | LIST[{studyAtClassYear:2008,uniCityName:"Hachiōji",uniName:"Sōka_University"}]                                                      | LIST[{companyCountryName:"Japan",companyName:"Air_Hokkaido",workAtWorkFrom:2008},{companyCountryName:"Japan",companyName:"Air_Next",workAtWorkFrom:2009}]                                                                                                                                                                                                                                                                              |
      | 17592186044857 | "Li"           | 2                  | DATE '1987-04-20' | DATETIME '2011-06-23T16:37:24.350000' | "female"     | "Firefox"           | "27.50.46.217"   | "Jun17592186044857@gmail.com"                                                                                  | "zh,en"         | "Dangyang"     | LIST[{studyAtClassYear:2009,uniCityName:"Hangzhou",uniName:"Hangzhou_International_School"}]                                        | LIST[{companyCountryName:"China",companyName:"Shenzhen_Airlines",workAtWorkFrom:2009}]                                                                                                                                                                                                                                                                                                                                                 |
      | 4398046511870  | "Wang"         | 2                  | DATE '1987-10-21' | DATETIME '2010-05-09T05:13:16.555000' | "female"     | "Firefox"           | "1.204.167.114"  | "Jun4398046511870@gmail.com"                                                                                   | "zh,en"         | "Nanchong"     | LIST[{studyAtClassYear:2008,uniCityName:"Ürümqi",uniName:"College_of_Traditional_Chinese_Medicine_of_Xinjiang_Medical_University"}] | LIST[{companyCountryName:"China",companyName:"Chongqing_Airlines",workAtWorkFrom:2009},{companyCountryName:"China",companyName:"Sichuan_Airlines",workAtWorkFrom:2010},{companyCountryName:"China",companyName:"Spring_Airlines",workAtWorkFrom:2009}]                                                                                                                                                                                 |
      | 26388279068220 | "Wang"         | 2                  | DATE '1988-03-27' | DATETIME '2012-03-07T23:03:52.355000' | "female"     | "Opera"             | "1.12.242.179"   | "Jun26388279068220@gmail.com,Jun26388279068220@gmx.com"                                                        | "zh,en"         | "Shanxi"       | LIST[{studyAtClassYear:2007,uniCityName:"Hangzhou",uniName:"Hangzhou_Dianzi_University"}]                                           | LIST[{companyCountryName:"China",companyName:"Air_China_Cargo",workAtWorkFrom:2008},{companyCountryName:"China",companyName:"Okay_Airways",workAtWorkFrom:2007},{companyCountryName:"China",companyName:"Shandong_Airlines",workAtWorkFrom:2008}]                                                                                                                                                                                      |
      | 24189255812657 | "Yang"         | 2                  | DATE '1983-07-15' | DATETIME '2011-12-22T03:08:15.963000' | "female"     | "Firefox"           | "1.203.198.207"  | "Jun24189255812657@gmail.com,Jun24189255812657@gmx.com,Jun24189255812657@yahoo.com"                            | "zh,en"         | "Anqing"       | LIST[{studyAtClassYear:2004,uniCityName:"Xi'an",uniName:"Xi'an_Polytechnic_University"}]                                            | LIST[{companyCountryName:"China",companyName:"Air_China",workAtWorkFrom:2005},{companyCountryName:"China",companyName:"Chang'an_Airlines",workAtWorkFrom:2006},{companyCountryName:"China",companyName:"Guizhou_Airlines",workAtWorkFrom:2005},{companyCountryName:"China",companyName:"Spring_Airlines",workAtWorkFrom:2006},{companyCountryName:"China",companyName:"Wuhan_Airlines",workAtWorkFrom:2005}]                           |
      | 13194139534915 | "Zhang"        | 2                  | DATE '1988-06-25' | DATETIME '2011-02-23T17:01:59.319000' | "female"     | "Internet Explorer" | "1.10.15.31"     | "Jun13194139534915@gmail.com"                                                                                  | "zh,en"         | "Chishui"      | LIST[{studyAtClassYear:2008,uniCityName:"Chongqing",uniName:"Yangtze_Normal_University"}]                                           | LIST[{companyCountryName:"China",companyName:"China_Yunnan_Airlines",workAtWorkFrom:2010},{companyCountryName:"China",companyName:"East_Star_Airlines",workAtWorkFrom:2008},{companyCountryName:"China",companyName:"Shanghai_Airlines_Cargo",workAtWorkFrom:2008},{companyCountryName:"China",companyName:"Tibet_Airlines",workAtWorkFrom:2009},{companyCountryName:"China",companyName:"United_Eagle_Airlines",workAtWorkFrom:2009}] |
      | 21990232556482 | "Zhu"          | 2                  | DATE '1989-05-30' | DATETIME '2011-09-08T09:50:23.141000' | "female"     | "Internet Explorer" | "1.1.22.34"      | "Jun21990232556482@gmail.com,Jun21990232556482@yahoo.com,Jun21990232556482@zoho.com"                           | "zh,en"         | "Feicheng"     | LIST[{studyAtClassYear:2009,uniCityName:"Shanghai",uniName:"China_Europe_International_Business_School"}]                           | LIST[{companyCountryName:"China",companyName:"China_Northern_Airlines",workAtWorkFrom:2009},{companyCountryName:"China",companyName:"Kunming_Airlines",workAtWorkFrom:2011}]                                                                                                                                                                                                                                                           |
      | 26388279068269 | "Zhu"          | 2                  | DATE '1987-12-12' | DATETIME '2012-02-11T12:58:10.694000' | "female"     | "Firefox"           | "1.189.111.251"  | "Jun26388279068269@gmail.com,Jun26388279068269@gmx.com"                                                        | "zh,en"         | "Gongyi"       | LIST[{studyAtClassYear:2008,uniCityName:"Chongqing",uniName:"Southwest_University"}]                                                | LIST[{companyCountryName:"China",companyName:"Great_Wall_Airlines",workAtWorkFrom:2009},{companyCountryName:"China",companyName:"Guizhou_Airlines",workAtWorkFrom:2010},{companyCountryName:"Iran",companyName:"Mahan_Air",workAtWorkFrom:2010},{companyCountryName:"China",companyName:"Tianjin_Airlines",workAtWorkFrom:2010},{companyCountryName:"China",companyName:"West_Air_(People's_Republic_of_China)",workAtWorkFrom:2010}]  |
      | 13194139533469 | "Chen"         | 3                  | DATE '1983-05-04' | DATETIME '2011-01-24T20:26:47.705000' | "female"     | "Chrome"            | "1.2.7.208"      | "Jun13194139533469@gmail.com,Jun13194139533469@yahoo.com,Jun13194139533469@zoho.com"                           | "zh,en"         | "Dalian"       | LIST[{studyAtClassYear:2004,uniCityName:"Hangzhou",uniName:"Hangzhou_International_School"}]                                        | LIST[{companyCountryName:"China",companyName:"China_Northwest_Airlines",workAtWorkFrom:2005},{companyCountryName:"China",companyName:"Chongqing_Airlines",workAtWorkFrom:2005},{companyCountryName:"Laos",companyName:"Lao_Air",workAtWorkFrom:2006},{companyCountryName:"China",companyName:"Sichuan_Airlines",workAtWorkFrom:2004}]                                                                                                  |
      | 6597069767359  | "Li"           | 3                  | DATE '1984-04-22' | DATETIME '2010-07-14T04:52:49.439000' | "female"     | "Safari"            | "27.29.124.155"  | "Jun6597069767359@gmx.com,Jun6597069767359@hotmail.com"                                                        | "zh,en"         | "Nanning"      | LIST[{studyAtClassYear:2003,uniCityName:"Shenyang",uniName:"Shenyang_Aerospace_University"}]                                        | LIST[{companyCountryName:"China",companyName:"China_Flying_Dragon_Aviation",workAtWorkFrom:2005},{companyCountryName:"China",companyName:"Okay_Airways",workAtWorkFrom:2003},{companyCountryName:"China",companyName:"Tianjin_Airlines",workAtWorkFrom:2004},{companyCountryName:"Chad",companyName:"Toumaï_Air_Tchad",workAtWorkFrom:2003}]                                                                                           |
      | 24189255811079 | "Li"           | 3                  | DATE '1987-10-07' | DATETIME '2011-12-29T07:56:39.032000' | "female"     | "Chrome"            | "1.29.220.142"   | "Jun24189255811079@gmail.com,Jun24189255811079@yahoo.com"                                                      | "zh,en"         | "Bei'an"       | LIST[{studyAtClassYear:2006,uniCityName:"Shenyang",uniName:"Shenyang_Conservatory_of_Music"}]                                       | LIST[{companyCountryName:"China",companyName:"Air_China_Cargo",workAtWorkFrom:2007},{companyCountryName:"China",companyName:"China_Postal_Airlines",workAtWorkFrom:2008},{companyCountryName:"China",companyName:"Tianjin_Airlines",workAtWorkFrom:2008},{companyCountryName:"China",companyName:"United_Eagle_Airlines",workAtWorkFrom:2007}]                                                                                         |
      | 30786325578075 | "Li"           | 3                  | DATE '1982-04-24' | DATETIME '2012-06-26T20:00:44.538000' | "female"     | "Chrome"            | "1.92.53.196"    | "Jun30786325578075@gmail.com,Jun30786325578075@yahoo.com"                                                      | "zh,en"         | "Dandong"      | LIST[{studyAtClassYear:2003,uniCityName:"Hangzhou",uniName:"China_Jiliang_University"}]                                             | LIST[{companyCountryName:"China",companyName:"Chang'an_Airlines",workAtWorkFrom:2004},{companyCountryName:"China",companyName:"Shandong_Airlines",workAtWorkFrom:2004},{companyCountryName:"China",companyName:"United_Eagle_Airlines",workAtWorkFrom:2003}]                                                                                                                                                                           |
      | 19791209300572 | "Xu"           | 3                  | DATE '1980-10-09' | DATETIME '2011-07-19T10:27:00.805000' | "female"     | "Chrome"            | "27.98.216.57"   | "Jun19791209300572@gmail.com"                                                                                  | "zh,en"         | "Cangzhou"     | LIST[{studyAtClassYear:2002,uniCityName:"Hangzhou",uniName:"Hangzhou_International_School"}]                                        | LIST[{companyCountryName:"China",companyName:"Chang'an_Airlines",workAtWorkFrom:2003},{companyCountryName:"China",companyName:"Great_Wall_Airlines",workAtWorkFrom:2004},{companyCountryName:"China",companyName:"Shanghai_Airlines_Cargo",workAtWorkFrom:2003}]                                                                                                                                                                       |
      | 10995116279040 | "Yamada"       | 3                  | DATE '1983-07-03' | DATETIME '2010-12-10T20:29:43.883000' | "female"     | "Firefox"           | "27.110.117.214" | "Jun10995116279040@gmail.com,Jun10995116279040@gmx.com"                                                        | "ja,en"         | "Yokohama"     | LIST[]                                                                                                                              | LIST[]                                                                                                                                                                                                                                                                                                                                                                                                                                 |
      | 30786325578060 | "Yang"         | 3                  | DATE '1987-01-25' | DATETIME '2012-05-30T05:54:57.910000' | "female"     | "Chrome"            | "1.2.0.161"      | "Jun30786325578060@gmail.com"                                                                                  | "zh,en"         | "Cenxi"        | LIST[{studyAtClassYear:2005,uniCityName:"Xi'an",uniName:"Xi'an_Polytechnic_University"}]                                            | LIST[{companyCountryName:"China",companyName:"Air_China_Cargo",workAtWorkFrom:2007}]                                                                                                                                                                                                                                                                                                                                                   |
      | 19791209300990 | "Zhang"        | 3                  | DATE '1984-12-09' | DATETIME '2011-08-07T22:37:30.150000' | "female"     | "Chrome"            | "1.10.21.91"     | "Jun19791209300990@gmail.com,Jun19791209300990@gmx.com"                                                        | "zh,en"         | "Dali"         | LIST[{studyAtClassYear:2004,uniCityName:"Huainan",uniName:"Anhui_University_of_Science_and_Technology"}]                            | LIST[]                                                                                                                                                                                                                                                                                                                                                                                                                                 |

  @sf01 @ic2
  Scenario: _IC2RecentMessagesByYourFriends
    When executing query:
      """
      USE sf01
      MATCH (person:Person {id: 30786325579117})<-[:KNOWS]->(friend:Person)<-[:HAS_CREATOR]-(message:Message WHERE message.creationDate < local_datetime('2012-04-03T00:00:00.000', "%Y-%m-%dT%H:%M:%S"))
      ORDER BY
          message.creationDate DESC,
          message.id ASC
      LIMIT 20
      RETURN
          friend.id AS personId,
          friend.firstName AS personFirstName,
          friend.lastName AS personLastName,
          message.id AS postOrCommentId,
          CASE WHEN message.content <>""
            THEN message.content
            ELSE message.imageFile
          END AS messageContent,
          message.creationDate AS postOrCommentCreationDate
      """
    Then the result should be, in order:
      | personId       | personFirstName | personLastName | postOrCommentId | messageContent                                                                                                                                                                                                    | postOrCommentCreationDate             |
      | 24189255811566 | "The"           | "Kunda"        | 893353445120    | "About Zine El Abidine Ben Ali, ySenior Intelligence School in Maryland School for Anti-Aircraft Field Artillery in Texas. Religion Sunni Islam Zine El Abidine Ben Ali is a Tunisian political figure who was t" | DATETIME '2012-04-02T23:11:04.138000' |
      | 2199023256816  | "K."            | "Bose"         | 893353553302    | "great"                                                                                                                                                                                                           | DATETIME '2012-04-02T22:06:16.679000' |
      | 24189255811566 | "The"           | "Kunda"        | 893353276051    | "fine"                                                                                                                                                                                                            | DATETIME '2012-04-02T22:02:02.016000' |
      | 13194139533618 | "Yang"          | "Zhang"        | 893353420155    | "yes"                                                                                                                                                                                                             | DATETIME '2012-04-02T15:58:59.299000' |
      | 17592186045864 | "Hoang Yen"     | "Pham"         | 893353399035    | "About Daisy Bell, me your answer doAbout Bukovina, historical regionAbout Beat Ag"                                                                                                                               | DATETIME '2012-04-02T14:06:04.637000' |
      | 24189255811566 | "The"           | "Kunda"        | 893353399037    | "no"                                                                                                                                                                                                              | DATETIME '2012-04-02T10:17:56.255000' |
      | 13194139533618 | "Yang"          | "Zhang"        | 893353339918    | "no"                                                                                                                                                                                                              | DATETIME '2012-04-02T03:23:22.385000' |
      | 24189255811566 | "The"           | "Kunda"        | 893353276061    | "thx"                                                                                                                                                                                                             | DATETIME '2012-04-02T02:32:32.718000' |
      | 2199023256816  | "K."            | "Bose"         | 893353511090    | "maybe"                                                                                                                                                                                                           | DATETIME '2012-04-01T15:57:55.687000' |
      | 24189255811566 | "The"           | "Kunda"        | 893353429200    | "right"                                                                                                                                                                                                           | DATETIME '2012-04-01T09:41:54.881000' |
      | 24189255811566 | "The"           | "Kunda"        | 893353504389    | "thanks"                                                                                                                                                                                                          | DATETIME '2012-04-01T06:39:13.822000' |
      | 13194139533618 | "Yang"          | "Zhang"        | 893353491724    | "yes"                                                                                                                                                                                                             | DATETIME '2012-04-01T02:03:09.360000' |
      | 24189255811566 | "The"           | "Kunda"        | 893353499890    | "About Hamid Karzai,  Conference on Afghanistan in Germany, Karzai was selectedAbout The Return of the Los Palmas 7"                                                                                              | DATETIME '2012-03-31T23:58:44.970000' |
      | 24189255811566 | "The"           | "Kunda"        | 893353499877    | "good"                                                                                                                                                                                                            | DATETIME '2012-03-31T16:06:46.356000' |
      | 13194139533618 | "Yang"          | "Zhang"        | 893353491721    | "roflol"                                                                                                                                                                                                          | DATETIME '2012-03-31T10:37:54.541000' |
      | 24189255811566 | "The"           | "Kunda"        | 893353278697    | "ok"                                                                                                                                                                                                              | DATETIME '2012-03-31T06:52:40.129000' |
      | 13194139533618 | "Yang"          | "Zhang"        | 893353278706    | "cool"                                                                                                                                                                                                            | DATETIME '2012-03-31T06:33:33.507000' |
      | 24189255811566 | "The"           | "Kunda"        | 893353278699    | "About Augustine of Hippo, s a spiritual City of God, distinct from tAbout Serbia an"                                                                                                                             | DATETIME '2012-03-31T05:22:43.995000' |
      | 2199023256816  | "K."            | "Bose"         | 893353528339    | "I see"                                                                                                                                                                                                           | DATETIME '2012-03-30T19:42:33.178000' |
      | 2199023256816  | "K."            | "Bose"         | 893353528325    | "thanks"                                                                                                                                                                                                          | DATETIME '2012-03-30T14:46:30.838000' |

  @sf01 @ic3
  Scenario: _IC3FriendsAndFriendsOfFriendsThatHaveBeenToGivenCountries
    When executing query:
      """
      USE sf01 {
      MATCH (countryX:Country {name : "Uruguay"}),
            (countryY:Country {name : "Puerto_Rico"}),
            (person:Person {id : 4398046512362})
      MATCH (city:City)-[:IS_PART_OF]->(country:Country)
      FILTER country IN List [countryX, countryY]
      RETURN collect(element_id(city)) AS cities, person, countryX, countryY GROUP BY person, countryX, countryY
      NEXT
      MATCH WALK (person:Person{id : 4398046512362})<-[:KNOWS]->{1,2}(friend:Person)-[:IS_LOCATED_IN]->(city:City)
      FILTER person <> friend AND NOT element_id(city) IN cities
      RETURN DISTINCT
          friend,
          countryX,
          countryY
      NEXT
      MATCH (friend:Person)<-[:HAS_CREATOR]-(message:Message where local_datetime('2012-02-04T00:00:00.000', "%Y-%m-%dT%H:%M:%S") > message.creationDate AND message.creationDate >= local_datetime('2012-01-01T00:00:00.000', "%Y-%m-%dT%H:%M:%S"))-[:IS_LOCATED_IN]->(country:Country)
      FILTER country IN List [countryX, countryY]
      LET
        messageX=CASE WHEN country=countryX THEN 1 ELSE 0 END,
        messageY=CASE WHEN country=countryY THEN 1 ELSE 0 END
      RETURN sum(messageX) AS xCount, sum(messageY) AS yCount, friend GROUP BY friend
      NEXT
      FILTER xCount > 0 AND yCount > 0
      ORDER BY
          xCount+yCount DESC,
          friend.id ASC
      LIMIT 20
      RETURN
          friend.id AS friendId,
          friend.firstName AS friendFirstName,
          friend.lastName AS friendLastName,
          xCount,
          yCount,
          xCount + yCount AS xyCount
      }
      """
    Then the result should be, in order:
      | friendId | friendFirstName | friendLastName | xCount | yCount | xyCount |

  @sf01 @ic4
  Scenario: _IC4NewTopics
    When executing query:
      """
      USE sf01 {
      MATCH (person:Person {id : 24189255811906})<-[:KNOWS]->(friend:Person)<-[:HAS_CREATOR]-(post:Post)-[:HAS_TAG]->(tag:Tag)
      RETURN DISTINCT tag, post
      NEXT
      LET valid = CASE WHEN local_datetime('2012-08-29T00:00:00.000', "%Y-%m-%dT%H:%M:%S") > post.creationDate AND post.creationDate >= local_datetime('2012-08-01T00:00:00.000', "%Y-%m-%dT%H:%M:%S")
                    THEN 1
                    ELSE 0
                  END,
          invalid = CASE WHEN local_datetime('2012-08-01T00:00:00.000', "%Y-%m-%dT%H:%M:%S") > post.creationDate
                    THEN 1
                    ELSE 0
                  END
      RETURN sum(valid) AS postCount, sum(invalid) AS inValidPostCount, tag GROUP BY tag
      NEXT
      FILTER WHERE postCount>0 AND inValidPostCount=0
      ORDER BY
          postCount DESC,
          tag.name ASC
      LIMIT 10
      RETURN
          tag.name AS tagName,
          postCount
      }
      """
    Then the result should be, in order:
      | tagName              | postCount |
      | "Billy_Joel"         | 2         |
      | "David_Lloyd_George" | 1         |
      | "Ray_Charles"        | 1         |

  @sf01 @ic5
  Scenario: _IC5NewGroups
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "enhanced_column_pruner=on") */
      USE sf01 {
      MATCH (person:Person {id : 6597069768287})<-[:KNOWS]->{1,2}(otherPerson:Person)
          WHERE person <> otherPerson
      RETURN DISTINCT otherPerson
      NEXT
      MATCH (otherPerson:Person)<-[membership:HAS_MEMBER WHERE membership.joinDate > local_datetime('2012-07-17T00:00:00.000', "%Y-%m-%dT%H:%M:%S")]-(forum:Forum)
      OPTIONAL MATCH (otherPerson:Person)<-[:HAS_CREATOR]-(post:Post)<-[:CONTAINER_OF]-(forum:Forum)
      RETURN count(post) AS postCount, forum GROUP BY forum
      NEXT
      ORDER BY
          postCount DESC,
          forum.id ASC
      LIMIT 20
      RETURN
          forum.title AS forumName,
          postCount
      }
      """
    Then the result should be, in order:
      | forumName                                               | postCount |
      | "Group for David_Lloyd_George in Sampaloc"              | 5         |
      | "Group for Mahathir_Mohamad in Pedro_Escobedo"          | 4         |
      | "Group for Arnold_Schwarzenegger in Dehradun"           | 3         |
      | "Group for Mahathir_Mohamad in Pedro_Escobedo"          | 3         |
      | "Group for Samuel_L._Jackson in Tagbilaran"             | 3         |
      | "Group for Keith_Richards in Dehradun"                  | 2         |
      | "Group for Benjamin_Disraeli in Pudong"                 | 2         |
      | "Group for Bertolt_Brecht in Moravia"                   | 2         |
      | "Group for Hilary_Duff in Belfast"                      | 2         |
      | "Group for Saddam_Hussein in Kassel"                    | 2         |
      | "Group for Ray_Bradbury in Taxila"                      | 2         |
      | "Group for Louis_Philippe_I in Padang"                  | 2         |
      | "Group for Poul_Anderson in Nakuru"                     | 2         |
      | "Group for Kurt_Aland in Baiyin"                        | 1         |
      | "Group for Guy_Forget in Banda_Aceh"                    | 1         |
      | "Group for Ferdinand_II,_Holy_Roman_Emperor in Chennai" | 1         |
      | "Group for Paul_Keres in Antananarivo"                  | 1         |
      | "Group for Talk_on_Corners in Cagayan_de_Oro"           | 1         |
      | "Group for Heinz_Guderian in Dire_Dawa"                 | 1         |
      | "Group for George_Clooney in Narathiwat"                | 1         |

  @sf01 @ic6
  Scenario: _IC6TagCoOccurrence
    When executing query:
      """
      USE sf01 {
      MATCH WALK (person:Person {id : 8796093023655})<-[:KNOWS]->{1,2}(friend:Person)
        WHERE person <> friend
      RETURN distinct friend AS f
      NEXT
      MATCH (t:Tag {name : "Justin_Timberlake"})<-[:HAS_TAG]-(post:Post)-[:HAS_CREATOR]->(f:Person),
        (post:Post)-[:HAS_TAG]->(tag:Tag)
      WHERE t <> tag
      RETURN count(post) AS postCount, tag GROUP BY tag
      NEXT
      ORDER BY
          postCount DESC,
          tag.name ASC
      LIMIT 10
      RETURN
          tag.name AS tagName,
          postCount
      }
      """
    Then the result should be, in order:
      | tagName              | postCount |
      | "A_Different_Corner" | 1         |
      | "Chocolate_Factory"  | 1         |
      | "Da_Real_World"      | 1         |
      | "David_Foster"       | 1         |
      | "Flower_of_Scotland" | 1         |
      | "Free_as_a_Bird"     | 1         |
      | "George_Gershwin"    | 1         |
      | "Ho_Chi_Minh"        | 1         |
      | "Hulk_Hogan"         | 1         |
      | "Jacques_Chirac"     | 1         |

  @sf01 @ic7
  Scenario: _IC7RecentLikers
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "enhanced_column_pruner=on, edge_prefix_push_down=off") */
      USE sf01 {
      MATCH (person:Person {id: 26388279067534})<-[:HAS_CREATOR]-(message:Message)<-[likes:LIKES]-(liker:Person)
      LET likeTime=likes.creationDate
      ORDER BY
          likeTime DESC,
          message.id ASC
      RETURN
          head(collect(message)) AS latestLikeMsg,
          head(collect(likeTime)) AS likeCreationDate,
          liker,
          person GROUP BY liker, person
      NEXT
      ORDER BY
          likeCreationDate DESC,
          liker.id ASC
      LIMIT 20
      RETURN
          liker.id AS personId,
          liker.firstName AS personFirstName,
          liker.lastName AS personLastName,likeCreationDate,
          latestLikeMsg.id AS messageId,
          CASE WHEN latestLikeMsg.content <> ""
              THEN latestLikeMsg.content
              ELSE latestLikeMsg.imageFile
          END AS messageContent,
          latestLikeMsg.creationDate AS minutesLatency,
          NOT EXISTS ((person:Person)<-[:KNOWS]->(liker:Person))  AS isNew
      }
      """
    Then the result should be, in order:
      | personId       | personFirstName     | personLastName | likeCreationDate                      | messageId     | messageContent                                                                                              | minutesLatency                        | isNew |
      | 32985348834301 | "Anh"               | "Nguyen"       | DATETIME '2012-09-07T23:38:20.109000' | 1030792374999 | "About David Foster, llace's unfinished novel, About Paul McCartney,  as a solo artist and as aAbout "      | DATETIME '2012-07-29T23:15:38.050000' | false |
      | 21990232556992 | "Shweta"            | "Kumar"        | DATETIME '2012-09-01T14:54:51.019000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 15393162790476 | "K."                | "Rao"          | DATETIME '2012-09-01T01:46:04.285000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 10995116278184 | "Arjun"             | "Kumar"        | DATETIME '2012-09-01T00:54:35.173000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | false |
      | 21990232556605 | "Arjun"             | "Sen"          | DATETIME '2012-08-31T14:41:23.954000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 13194139534142 | "Rahul"             | "Reddy"        | DATETIME '2012-08-31T11:01:41.910000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 8796093023493  | "Anupam"            | "Reddy"        | DATETIME '2012-08-31T08:41:02.450000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 24189255811940 | "Arjun"             | "Khan"         | DATETIME '2012-08-30T15:27:58.487000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 26388279067534 | "Emperor of Brazil" | "Dom Pedro II" | DATETIME '2012-08-30T12:25:44.355000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 687            | "Deepak"            | "Singh"        | DATETIME '2012-08-30T10:47:48.418000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 13194139533535 | "Shweta"            | "Singh"        | DATETIME '2012-08-30T05:47:08.827000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 26388279067635 | "John"              | "Sheikh"       | DATETIME '2012-08-30T02:31:55.386000' | 893353421832  | "photo893353421832.jpg"                                                                                     | DATETIME '2012-05-05T01:28:47.301000' | false |
      | 15393162790406 | "A."                | "Sharma"       | DATETIME '2012-08-29T22:40:33.526000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 8796093023060  | "Karim"             | "Akhmadiyeva"  | DATETIME '2012-08-29T18:40:43.787000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 4398046511667  | "John"              | "Chopra"       | DATETIME '2012-08-29T18:33:12.141000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 4398046512376  | "Jack"              | "Wilson"       | DATETIME '2012-08-29T14:15:59.910000' | 1030792465816 | "About Srivijaya, dated 16 June 682. The kingdom ceased to exiAbout Kingdom of Hanover,"                    | DATETIME '2012-08-28T21:02:46.946000' | true  |
      | 2199023256816  | "K."                | "Bose"         | DATETIME '2012-08-29T13:36:50.406000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | false |
      | 26388279067551 | "Anand"             | "Rao"          | DATETIME '2012-08-29T10:15:28.898000' | 1030792399080 | "About I Only Have Eyes for You, ou is episode 19 of season two of Buffy the Vampire Sl"                    | DATETIME '2012-08-29T01:48:53.946000' | true  |
      | 8796093022764  | "Zheng"             | "Xu"           | DATETIME '2012-08-29T01:53:51.200000' | 962072804153  | "About Bertolt Brecht,  – 14 August 1956) was a German poet, playwright, and theatre director. An influent" | DATETIME '2012-07-01T06:31:55.005000' | true  |
      | 28587302322631 | "David"             | "Fenter"       | DATETIME '2012-08-29T00:44:34.886000' | 893353421832  | "photo893353421832.jpg"                                                                                     | DATETIME '2012-05-05T01:28:47.301000' | false |

  @sf01 @ic8
  Scenario: _IC8RecentReplies
    When executing query:
      """
      USE sf01
      MATCH (startPerson:Person {id: 2199023256816})<-[:HAS_CREATOR]-(:Message)<-[:REPLY_OF]-(comment:Comment)-[:HAS_CREATOR]->(person:Person)
      ORDER BY
          comment.creationDate DESC,
          comment.id ASC
      LIMIT 20
      RETURN
          person.id AS personId,
          person.firstName AS personFirstName,
          person.lastName AS personLastName,
          comment.creationDate AS commentCreationDate,
          comment.id AS commentId,
          comment.content AS commentContent
      """
    Then the result should be, in order:
      | personId       | personFirstName | personLastName | commentCreationDate                   | commentId     | commentContent                                                                              |
      | 13194139533482 | "Ana Paula"     | "Silva"        | DATETIME '2012-09-13T02:46:15.078000' | 1099511667820 | "About Heinz Guderian, aised and organized under his direction About Malacca Sul"           |
      | 8796093022928  | "Hao"           | "Zhu"          | DATETIME '2012-09-09T13:41:03.021000' | 1099511964827 | "About Nothing but the Beat, icki Minaj, Usher, Jennifer Hudson, Jessie J and Sia Furler"   |
      | 10995116278796 | "Kenji"         | "Sakai"        | DATETIME '2012-09-09T11:58:26.789000' | 1099511964825 | "About Humayun, to expand the Empire further, leaving a suAbout Philip K. Dick, r o"        |
      | 30786325577752 | "Jie"           | "Yang"         | DATETIME '2012-09-09T06:55:07.083000' | 1099511964826 | "no"                                                                                        |
      | 24189255812755 | "Paulo"         | "Santos"       | DATETIME '2012-09-09T05:15:06.094000' | 1099511964828 | "good"                                                                                      |
      | 687            | "Deepak"        | "Singh"        | DATETIME '2012-09-08T10:59:18.087000' | 1030792351589 | "no way!"                                                                                   |
      | 2199023256586  | "Alfonso"       | "Elizalde"     | DATETIME '2012-09-07T14:58:33.508000' | 1030792488768 | "About Humayun, ial legacy for his son, Akbar. His peaceful About Busta Rhymes, sta Rhy"    |
      | 30786325578896 | "Yang"          | "Li"           | DATETIME '2012-09-07T14:17:05.148000' | 1030792488774 | "roflol"                                                                                    |
      | 21990232555834 | "John"          | "Garcia"       | DATETIME '2012-09-07T13:40:41.067000' | 1030792488763 | "no way!"                                                                                   |
      | 13194139534578 | "Kunal"         | "Sharma"       | DATETIME '2012-09-07T12:24:17.245000' | 1030792488765 | "maybe"                                                                                     |
      | 15393162789932 | "Fali Sam"      | "Price"        | DATETIME '2012-09-07T10:17:59.051000' | 1030792488767 | "roflol"                                                                                    |
      | 30786325579189 | "Cheh"          | "Yang"         | DATETIME '2012-09-07T05:26:08.122000' | 1030792488759 | "yes"                                                                                       |
      | 555            | "Chen"          | "Yang"         | DATETIME '2012-09-07T02:47:04.535000' | 1030792488769 | "About Skin and Bones, Another Round, reprising the contribution he made to the original a" |
      | 13194139534382 | "A."            | "Budjana"      | DATETIME '2012-09-07T02:45:14.312000' | 1030792488758 | "duh"                                                                                       |
      | 8796093022290  | "Alexei"        | "Codreanu"     | DATETIME '2012-09-06T21:23:21.712000' | 1030792488760 | "ok"                                                                                        |
      | 21990232555958 | "Ernest B"      | "Law-Yone"     | DATETIME '2012-09-06T20:18:08.132000' | 1030792488766 | "great"                                                                                     |
      | 26388279067760 | "Max"           | "Bauer"        | DATETIME '2012-09-06T17:54:31.955000' | 1030792488761 | "thx"                                                                                       |
      | 10995116278300 | "Jie"           | "Li"           | DATETIME '2012-09-06T17:40:21.751000' | 1030792488762 | "maybe"                                                                                     |
      | 10995116279093 | "Diem"          | "Nguyen"       | DATETIME '2012-09-06T17:39:46.333000' | 1030792488764 | "thanks"                                                                                    |
      | 26388279066662 | "Alfonso"       | "Rodriguez"    | DATETIME '2012-09-06T12:40:58.972000' | 1030792487632 | "good"                                                                                      |

  @sf01 @ic9
  Scenario: _IC9RecentMessagesByFriendsOrFriendsOfFriends
    When executing query:
      """
      USE sf01 {
      MATCH WALK (root:Person {id: 454})<-[:KNOWS]->{1,2}(friend:Person)
        WHERE friend <> root
      RETURN DISTINCT friend
      NEXT
      MATCH (friend:Person)<-[:HAS_CREATOR]-(message:Message WHERE message.creationDate < local_datetime('2012-11-28T00:00:00.000', "%Y-%m-%dT%H:%M:%S"))
      ORDER BY
          message.creationDate DESC,
          message.id ASC
      LIMIT 20
      RETURN
          friend.id AS personId,
          friend.firstName AS personFirstName,
          friend.lastName AS personLastName,
          message.id AS commentOrPostId,
          CASE WHEN message.content <> ""
              THEN message.content
              ELSE message.imageFile
          END AS commentOrPostContent,
          message.creationDate AS commentOrPostCreationDate
      }
      """
    Then the result should be, in order:
      | personId       | personFirstName | personLastName | commentOrPostId | commentOrPostContent                                                                      | commentOrPostCreationDate             |
      | 238            | "Burak"         | "Koksal"       | 1099511913485   | "thx"                                                                                     | DATETIME '2012-09-13T09:03:16.942000' |
      | 4398046512267  | "Chris"         | "Michie"       | 1099511997885   | "yes"                                                                                     | DATETIME '2012-09-13T09:02:35.921000' |
      | 30786325578747 | "Zhang"         | "Huang"        | 1099511787223   | "About Rumours, widespread critical acclaim. Praise centred on its production quali"      | DATETIME '2012-09-13T09:00:08.592000' |
      | 30786325578938 | "Hao"           | "Zhang"        | 1099511909177   | "yes"                                                                                     | DATETIME '2012-09-13T08:50:50.562000' |
      | 19791209300961 | "Ning"          | "Zhang"        | 1099511763797   | "thx"                                                                                     | DATETIME '2012-09-13T08:40:57.438000' |
      | 30786325578938 | "Hao"           | "Zhang"        | 1099511909180   | "cool"                                                                                    | DATETIME '2012-09-13T08:31:36.663000' |
      | 4398046512194  | "Jesus"         | "Mendez"       | 1099511747114   | "thx"                                                                                     | DATETIME '2012-09-13T08:18:39.392000' |
      | 6597069767836  | "Joao"          | "Morais"       | 1099511909185   | "LOL"                                                                                     | DATETIME '2012-09-13T08:15:53.583000' |
      | 17592186045813 | "Lin"           | "Zhang"        | 1099511997847   | "fine"                                                                                    | DATETIME '2012-09-13T08:10:09.985000' |
      | 32985348834053 | "James"         | "Wilson"       | 1099511747465   | "LOL"                                                                                     | DATETIME '2012-09-13T07:54:45.138000' |
      | 30786325578938 | "Hao"           | "Zhang"        | 1099511909179   | "About United Kingdom of Great Britain and Ireland, ritory now known as the Republ"       | DATETIME '2012-09-13T07:52:35.362000' |
      | 24189255811663 | "Chris"         | "Hall"         | 1099511717508   | "About Barbie Girl, an dance-pop group Aqua. It was released in May 1997 as their t"      | DATETIME '2012-09-13T07:49:29.771000' |
      | 17592186044504 | "Chong"         | "Zhang"        | 1099511997942   | "thanks"                                                                                  | DATETIME '2012-09-13T07:48:29.188000' |
      | 4398046511700  | "Mahmoud"       | "Ali"          | 1099511787228   | "no way!"                                                                                 | DATETIME '2012-09-13T07:47:44.849000' |
      | 32985348833533 | "Fritz"         | "Muller"       | 1099511909184   | "right"                                                                                   | DATETIME '2012-09-13T07:32:00.799000' |
      | 941            | "Aryo"          | "Tobing"       | 1099511909182   | "About Muhammad, tribes of Arabia into a single religious polity under Islam. He is beli" | DATETIME '2012-09-13T07:31:25.882000' |
      | 30786325578932 | "Alexander"     | "Hleb"         | 1099511997876   | "right"                                                                                   | DATETIME '2012-09-13T07:25:06.539000' |
      | 32985348834961 | "Carlos"        | "Parra"        | 1099511787222   | "good"                                                                                    | DATETIME '2012-09-13T07:24:53.748000' |
      | 6597069767300  | "Jose"          | "Salvador"     | 1099511909175   | "About The Lamb Lies Down on Broadway, cept album recorded and released in 1974"          | DATETIME '2012-09-13T07:19:07.331000' |
      | 6597069766961  | "Daouda Malam"  | "Diori"        | 1099511909178   | "fine"                                                                                    | DATETIME '2012-09-13T07:18:33.753000' |

  @sf01 @ic10
  Scenario: _IC10FriendRecommendation
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "enhanced_column_pruner=on, edge_prefix_push_down=off") */
      USE sf01 {
      MATCH WALK (person:Person {id : 17592186044737})<-[:KNOWS]->{2}(friend:Person),(friend:Person)-[:IS_LOCATED_IN]->(city:City)
        WHERE friend <> person AND NOT EXISTS((person:Person)<-[:KNOWS]->(friend:Person))
      FILTER WHERE (friend.birthday.month = 6 AND friend.birthday.day >= 21) OR (friend.birthday.month = (6 % 12) + 1 AND friend.birthday.day < 22)
      RETURN DISTINCT
          friend,
          city,
          person
      NEXT
      OPTIONAL MATCH (friend:Person)<-[:HAS_CREATOR]-(post:Post)
      OPTIONAL MATCH (p:Person {id : 17592186044737})-[:HAS_INTEREST]->(m:Tag)<-[:HAS_TAG]->(post:Post)
      RETURN count(m) AS tmp, friend, city, post GROUP BY friend, city, post
      NEXT
      LET cnt = CASE WHEN tmp > 0 THEN 1 ELSE 0 END
      RETURN count(post) AS postCount, sum(cnt) AS commonPostCount, friend, city GROUP BY friend, city
      NEXT
      RETURN
          friend.id AS personId,
          friend.firstName AS personFirstName,
          friend.lastName AS personLastName,
          commonPostCount - (postCount - commonPostCount) AS commonInterestScore,
          friend.gender AS personGender,
          city.name AS personCityName
      ORDER BY
          commonInterestScore DESC,
          personId ASC
      LIMIT 10
      }
      """
    Then the result should be, in order:
      | personId       | personFirstName | personLastName | commonInterestScore | personGender | personCityName |
      | 21990232556536 | "Sayed"         | "Mahmoud"      | 0                   | "female"     | "Giza"         |
      | 32985348833995 | "John"          | "Sharma"       | 0                   | "male"       | "Tamil_Nadu"   |
      | 24189255811481 | "Arun"          | "Sharma"       | -1                  | "female"     | "Coimbatore"   |
      | 13194139533320 | "Djelaludin"    | "Zaland"       | -2                  | "male"       | "Herat"        |
      | 13194139534915 | "Jun"           | "Zhang"        | -2                  | "female"     | "Chishui"      |
      | 19791209300882 | "Pedro"         | "Oliveira"     | -2                  | "male"       | "Mesa"         |
      | 26388279066958 | "Cesar"         | "Ha"           | -2                  | "male"       | "Da_Nang"      |
      | 32985348834605 | "Lin"           | "Li"           | -2                  | "male"       | "Gao'an"       |
      | 6597069767887  | "Thomas Ilenda" | "Omonga"       | -4                  | "female"     | "Boma"         |
      | 21990232555611 | "Gayatri"       | "Reddy"        | -4                  | "male"       | "Jammu"        |

  @sf01 @ic11
  Scenario: _IC11JobReferral
    When executing query:
      """
      USE sf01 {
      MATCH WALK (person:Person {id: 24189255811707})<-[:KNOWS]->{1,2}(friend:Person)
          WHERE person <> friend
      RETURN DISTINCT friend
      NEXT
      MATCH (friend:Person)-[workAt:WORK_AT WHERE workAt.workFrom < 2006]->(company:Company)-[:IS_LOCATED_IN]->(:Country {name : "Switzerland"})
      ORDER BY
          workAt.workFrom ASC,
          friend.id ASC,
          company.name DESC
      LIMIT 10
      RETURN
          friend.id AS personId,
          friend.firstName AS personFirstName,
          friend.lastName AS personLastName,
          company.name AS organizationName,
          workAt.workFrom AS organizationWorkFromYear
      }
      """
    Then the result should be, in order:
      | personId       | personFirstName | personLastName | organizationName | organizationWorkFromYear |
      | 19791209300839 | "Akira"         | "Inoue"        | "PrivatAir"      | 2003                     |

  @sf01 @ic12
  Scenario: _IC12ExpertSearch
    When executing query:
      """
      USE sf01 {
      MATCH WALK (tag:Tag)-[:HAS_TYPE|IS_SUBCLASS_OF]->{0,3}(baseTagClass:TagClass)
          WHERE tag.name = "BasketballPlayer" OR baseTagClass.name = "BasketballPlayer"
      RETURN collect(tag.id) AS tags GROUP BY ()
      NEXT
      MATCH (:Person {id: 19791209300143})<-[:KNOWS]->(friend:Person)<-[:HAS_CREATOR]-(comment:Comment)-[:REPLY_OF]->(:Post)-[:HAS_TAG]->(tag:Tag)
      FILTER WHERE tag.id IN tags
      RETURN collect(DISTINCT tag.name) AS tagNames,count(DISTINCT comment) AS replyCount, friend GROUP BY friend
      NEXT
      ORDER BY
          replyCount DESC,
          friend.id ASC
      LIMIT 20
      RETURN
          friend.id AS personId,
          friend.firstName AS personFirstName,
          friend.lastName AS personLastName,
          tagNames,
          replyCount
      }
      """
    Then the result should be, in any order:
      | personId      | personFirstName | personLastName | tagNames                | replyCount |
      | 8796093023000 | "Peng"          | "Zhang"        | LIST ["Michael_Jordan"] | 4          |

  @sf01 @ic13
  Scenario: _IC13SingleShortestPath
    When executing query:
      """
      USE sf01
      OPTIONAL MATCH ANY SHORTEST (person1:Person{id:2199023256586})<-[e:KNOWS]->*(person2:Person{id:32985348833679})
      RETURN CASE WHEN e IS NULL THEN -1 ELSE length(e) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 3                  |

  # issue: https://github.com/vesoft-inc/nebula-ng/issues/986
  @sf01 @ic14
  Scenario: _IC14TrustedConnectionPaths
    # (dijkstra not supported yet)
    When executing query:
      """
      USE sf01 {
      MATCH paths = ALL SHORTEST PATH (person1:Person {id:32985348833679})<-[:KNOWS]->*(person2:Person {id:2199023256862})
      LET pathNodes = nodes(paths)
      LET numNodes = size(pathNodes)-1
      FOR i IN range(1, numNodes)
      LET prev = pathNodes[i-1], curr = pathNodes[i]
      RETURN 1.0d * VALUE {MATCH (curr)<-[:HAS_CREATOR]-(:Comment)-[:REPLY_OF]->(:Post)-[:HAS_CREATOR]->(prev) RETURN COUNT(*) AS a GROUP BY ()}
           + 1.0d * VALUE {MATCH (prev)<-[:HAS_CREATOR]-(:Comment)-[:REPLY_OF]->(:Post)-[:HAS_CREATOR]->(curr) RETURN COUNT(*) AS b GROUP BY ()}
           + 0.5d * VALUE {MATCH (prev)<-[:HAS_CREATOR]-(:Comment)<-[:REPLY_OF]->(:Comment)-[:HAS_CREATOR]->(curr) RETURN COUNT(*) AS c GROUP BY ()}
           AS weight, pathNodes, numNodes
      NEXT
      RETURN pathNodes, numNodes, SUM(weight) AS pathWeight GROUP BY pathNodes, numNodes
      ORDER BY pathWeight DESC
      NEXT
      FOR i IN range(0, numNodes)
      LET pathNode = pathNodes[i]
      RETURN COLLECT(pathNode.id) AS personIdsInPath, pathWeight GROUP BY pathNodes, pathWeight
      }
      """
    Then the result should be, in any order:
      | personIdsInPath                                                     | pathWeight |
      | LIST[32985348833679, 26388279067534, 2199023256816, 2199023256862]  | 18.5       |
      | LIST[32985348833679, 28587302322537, 2199023256816, 2199023256862]  | 17.0       |
      | LIST[32985348833679, 28587302322537, 6597069767242, 2199023256862]  | 13.0       |
      | LIST[32985348833679, 28587302322537, 8796093023000, 2199023256862]  | 11.5       |
      | LIST[32985348833679, 28587302322537, 19791209300852, 2199023256862] | 6.5        |
