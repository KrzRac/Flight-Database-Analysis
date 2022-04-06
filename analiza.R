library(odbc)
library(DBI)
con <- dbConnect(odbc::odbc(), 
                 Driver = "SQL Server", 
                 Server = "mssql-2017.labs.wmi.amu.edu.pl", 
                 Database = "dbad_flights", 
                 UID      = 'placeholder',
                 PWD      = 'placeholder',
                 Port     = 1433)


# a. Jakie było średnie opóźnienie przylotu?
  
dbGetQuery(con, "SELECT AVG(arr_delay_new) AS 'avg_delay'
FROM Flight_delays")



# b. Jakie było maksymalne opóźnienie przylotu?

dbGetQuery(con, "SELECT MAX(arr_delay_new) AS 'max_delay'
FROM Flight_delays")


# c. Który lot miał największe opóźnienie przylotu?
  
dbGetQuery(con, "SELECT fl_date, arr_delay_new, carrier, origin_city_name, dest_city_name
FROM Flight_delays
WHERE arr_delay_new = (SELECT MAX(arr_delay_new) AS 'max_delay'
                       FROM Flight_delays)")


# d. Które dni tygodnia są najgorsze do podróżowania? 
  
dbGetQuery(con, "SELECT AVG(arr_delay_new) AS 'avg_delay', weekday_name
FROM Flight_delays F
     INNER JOIN Weekdays W
        ON W.weekday_id = F.day_of_week
GROUP BY W.weekday_name
ORDER BY avg_delay DESC")


# e. Które linie lotnicze latające z San Francisco (SFO) mają najmniejsze opóźnienia przylotu? 
  
dbGetQuery(con, "SELECT AVG(arr_delay_new) AS 'avg_delay', A.airline_name
FROM Flight_delays F
    INNER JOIN Airlines A ON A.airline_id = F.airline_id
WHERE A.airline_name IN (SELECT A.airline_name
                         FROM Flight_delays F
                            INNER JOIN Airlines A ON A.airline_id = F.airline_id
                         WHERE F.origin = 'SFO')
GROUP BY A.airline_id, A.airline_name
ORDER BY avg_delay DESC")


# f. Jaka część linii lotniczych ma regularne opóźnienia, tj. jej lot ma średnio co najmniej 10 min. opóźnienia?
  
dbGetQuery(con, "SELECT (cast((SELECT DISTINCT COUNT(*) OVER () AS Total_1
              FROM Flight_delays F1
              WHERE 10 <= SOME (SELECT AVG(arr_delay_new)
                                FROM Flight_delays F2
                                WHERE F1.airline_id = F2.airline_id)
                                GROUP BY airline_id) AS FLOAT) / (cast((SELECT DISTINCT COUNT(*) OVER () AS Total_2
                                                                        FROM Flight_delays
                                                                        GROUP BY airline_id) AS FLOAT))) AS 'late_proportion'")



# g. Jak opóźnienia wylotów wpływają na opóźnienia przylotów?
  
dbGetQuery(con, "SELECT (AVG(dep_delay_new * arr_delay_new) - (AVG(dep_delay_new) * AVG(arr_delay_new))) / (STDEVP(dep_delay_new) * STDEVP(arr_delay_new)) AS 'Pearsons r'
FROM Flight_delays")


# h. Która linia lotnicza miała największy wzrost (różnica) średniego opóźnienia przylotów w ostatnim tygodniu miesiąca, tj. między 1-23 a 24-31 lipca?
  
dbGetQuery(con, "SELECT TOP 1 b.arr_delay_new2 - a.arr_delay_new1 AS 'delay_increase', a.airline_name
FROM (SELECT AVG(arr_delay_new) AS 'arr_delay_new1', F.airline_id, A.airline_name
        FROM Flight_delays F
            INNER JOIN Airlines A ON A.airline_id = F.airline_id
WHERE fl_date BETWEEN '20170701' AND '20170723'
GROUP BY F.airline_id, A.airline_name) a
    INNER JOIN (SELECT AVG(arr_delay_new) AS 'arr_delay_new2', F.airline_id
                FROM Flight_delays F
                       INNER JOIN Airlines A ON A.airline_id = F.airline_id
                WHERE fl_date BETWEEN '20170724' AND '20170731'
                GROUP BY F.airline_id) b
          ON a.airline_id = b.airline_id
ORDER BY delay_increase DESC")


# i. Które linie lotnicze latają zarówno na trasie SFO → PDX (Portland), jak i SFO → EUG (Eugene)?
  
dbGetQuery(con, "SELECT DISTINCT airline_name
FROM Airlines A
    INNER JOIN Flight_delays F
        ON F.airline_id = A.airline_id
WHERE (F.origin = 'SFO' AND F.dest = 'PDX')
       AND F.airline_id IN (SELECT airline_id
                            FROM Flight_delays
                            WHERE origin = 'SFO' AND dest = 'EUG')")



# j. Jak najszybciej dostać się z Chicago do Stanfordu, zakładając wylot po 14:00 czasu lokalnego?
  
dbGetQuery(con, "SELECT cast(AVG(arr_delay_new) AS DECIMAL(17,14)) AS 'avg_delay', origin, dest
FROM dbad_flights.dbo.Flight_delays
WHERE origin IN ('MDW', 'ORD')
       AND dest IN ('SFO', 'SJC', 'OAK')
       AND crs_dep_time > '1400'
GROUP BY origin, dest
ORDER BY avg_delay DESC")





