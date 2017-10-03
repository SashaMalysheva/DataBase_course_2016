-- Базовый запрос, считающий пассажиров на рейсе
-- Не учитывает рейсы без пассажиров
SELECT F.id, F.planet_id, F.spacecraft_id, F.commander_id, COUNT(*) AS pax_cnt
FROM Flight F JOIN Booking B ON F.id=B.flight_id
GROUP BY F.id;

-- Этот запрос считает количество планет, на которые слетал каждый из капитанов
-- Считает не учитывая полеты без пассажиров
SELECT C.id, C.name, COUNT(planet_id) AS planet_count
FROM (
  -- Это копия базового запроса
  SELECT F.id, F.planet_id, F.spacecraft_id, F.commander_id, COUNT(*) AS pax_cnt
  FROM Flight F JOIN Booking B ON F.id=B.flight_id
  GROUP BY F.id

) AS PaxFlight

JOIN Commander C ON C.id=PaxFlight.commander_id
GROUP BY C.id;


-- Этот запрос считает для каждой планеты среднее количество пассажиров на рейсах
-- на эту планету
SELECT P.id, P.name, AVG(pax_cnt)
FROM (
  -- Это копия базового запроса
  SELECT F.id, F.planet_id, F.spacecraft_id, COUNT(*) AS pax_cnt
  FROM Flight F JOIN Booking B ON F.id=B.flight_id
  GROUP BY F.id

) AS PaxFlight

JOIN Planet P ON P.id=PaxFlight.planet_id
GROUP BY P.id;

-- Если мы предполагаем часто использовать запрос, считающий пассажиров на
-- рейсе, имеет смысл оформить его в виде представления
-- Теперь мы его поправили, запрос учитывает рейсы без пассажиров.
CREATE VIEW PaxFlight AS
SELECT F.id, F.planet_id, F.spacecraft_id, F.commander_id, COUNT(DISTINCT B.ref_num) AS pax_cnt
FROM Flight F LEFT JOIN Booking B ON F.id=B.flight_id
GROUP BY F.id;


-- Желаем найти трех самых опытных капитанов, посетившее наибольшее количество планет
-- Или семерых. Или пятерых.
-- Этот запрос сработает корректно и выдаст троих
SELECT * FROM (
  SELECT C.id, C.name, COUNT(DISTINCT planet_id) AS planet_count
  FROM  PaxFlight
  JOIN Commander C ON C.id=PaxFlight.commander_id
  GROUP BY C.id
) AS CmdPlanet
ORDER BY CmdPlanet.planet_count DESC
LIMIT 3;

-- Сделаем из этого представление!
-- Оно будет "отсортировано" по убыванию количества планет
CREATE OR REPLACE VIEW CommanderPlanetCount AS
SELECT * FROM (
  SELECT C.id, COUNT(DISTINCT planet_id) AS planet_count
  FROM PaxFlight
  JOIN Commander C ON C.id=PaxFlight.commander_id
  GROUP BY C.id
) AS CmdPlanet
ORDER BY CmdPlanet.planet_count DESC;


-- Давайте посчитаем еще пройденное расстояние для каждого капитана
SELECT F.commander_id, SUM(P.distance) AS total_distance
FROM Flight F JOIN Planet P ON F.planet_id = P.id
GROUP BY F.commander_id;


-- И допишем к капитанам-лидерам по количеству планет суммарное расстояние
-- и суммарное количество перевезённых пассажиров
-- Мы надеемся, что благодаря упорядоченности CommanderPlanetCount
-- результат получится упорядоченным по количеству посещённых планет DESC
SELECT CPC.id, C.name, CPC.planet_count, TD.total_distance, PC.pax_sum
FROM
Commander C JOIN
CommanderPlanetCount CPC ON C.id=CPC.id
JOIN
(
  SELECT F.commander_id, SUM(P.distance) AS total_distance
  FROM Flight F JOIN Planet P ON F.planet_id = P.id
  GROUP BY F.commander_id
) AS TD ON CPC.id = TD.commander_id
JOIN
(
  SELECT F.commander_id, COUNT(*) AS pax_sum
  FROM Flight F JOIN Booking B ON F.id=B.flight_id
  GROUP BY F.commander_id
) AS PC ON PC.commander_id = TD.commander_id
WHERE C.rating = 'Elite' -- выберите рейтинг с 3 капитанами
LIMIT 3;

-- И это даже похоже на правду
-- Но сделаем невинное действие
CREATE INDEX ON Commander(rating);

-- Теперь тот же самый запрос будет возвращать капитанов уже в другом порядке.
-- ORDER BY в представлении опасен!


-- ====================================================================
-- Как правильно выбрать N лучших по какому-то критерию?

-- Подсчет статистики
CREATE OR REPLACE VIEW CommanderStats AS
  SELECT C.id, COUNT(DISTINCT planet_id) AS planet_count, SUM(pax_cnt) AS pax_total
  FROM PaxFlight
  JOIN Commander C ON C.id=PaxFlight.commander_id
  GROUP BY C.id;

-- Какое максимальное количество посещённых планет?
SELECT MAX(planet_count) FROM CommanderStats;

-- На какой записи оно достигнуто?
SELECT * FROM CommanderStats WHERE planet_count = (
  SELECT MAX(planet_count) FROM CommanderStats
);

--
-- отношение  < между капитанами:
-- Cap1.planet_count < Cap2.planet_count
-- OR Cap1.planet_count=Cap2.planet_count AND Cap1.pax_total < Cap2.pax_total

-- Построим элементы отношения <
-- Сюда войдут все, кроме самого опытного
SELECT * FROM
CommanderStats CS1 JOIN CommanderStats CS2
ON CS1.planet_count < CS2.planet_count
OR CS1.planet_count=CS2.planet_count AND CS1.pax_total < CS2.pax_total;


-- Самый опытный капитан
SELECT * FROM
CommanderStats CS1 LEFT JOIN CommanderStats CS2
ON CS1.planet_count < CS2.planet_count
OR CS1.planet_count=CS2.planet_count AND CS1.pax_total < CS2.pax_total
WHERE CS2.id IS NULL;


-- Сюда войдут все, и rank = количество капитанов, с которыми данный CS1.id
-- находится в отношении CS1.id <
SELECT CS1.id,
       SUM(CASE CS2.id IS NULL WHEN true THEN 0 ELSE 1 END) AS rank
FROM
CommanderStats CS1 LEFT JOIN CommanderStats CS2
ON CS1.planet_count < CS2.planet_count
OR CS1.planet_count=CS2.planet_count AND CS1.pax_total < CS2.pax_total
GROUP BY CS1.id;

-- Запрос, возвращающий трех лучших капитанов
SELECT * FROM (
  SELECT CS1.id,
         SUM(CASE CS2.id IS NULL WHEN true THEN 0 ELSE 1 END) AS rank
  FROM
  CommanderStats CS1 LEFT JOIN CommanderStats CS2
  ON CS1.planet_count < CS2.planet_count
  OR CS1.planet_count=CS2.planet_count AND CS1.pax_total < CS2.pax_total
  GROUP BY CS1.id
) AS CapRank
WHERE CapRank.rank < 3;

-- Что если бы мы не использовали представления?
-- мегазапрос
SELECT * FROM (
  SELECT CS1.id,
         SUM(CASE CS2.id IS NULL WHEN true THEN 0 ELSE 1 END) AS rank

  FROM
  (
    SELECT C.id, COUNT(DISTINCT planet_id) AS planet_count, SUM(pax_cnt) AS pax_total
    FROM
    (
      SELECT F.id, F.planet_id, F.spacecraft_id, F.commander_id,
             SUM(CASE B.flight_id IS NULL WHEN true THEN 0 ELSE 1 END) AS pax_cnt
      FROM Flight F LEFT JOIN Booking B ON F.id=B.flight_id
      GROUP BY F.id

    ) AS PaxFlight

    JOIN Commander C ON C.id=PaxFlight.commander_id
    GROUP BY C.id
  ) AS CS1
  LEFT JOIN
  (
    SELECT C.id, COUNT(DISTINCT planet_id) AS planet_count, SUM(pax_cnt) AS pax_total
    FROM (

      SELECT F.id, F.planet_id, F.spacecraft_id, F.commander_id,
             SUM(CASE B.flight_id IS NULL WHEN true THEN 0 ELSE 1 END) AS pax_cnt
      FROM Flight F LEFT JOIN Booking B ON F.id=B.flight_id
      GROUP BY F.id

    ) AS PaxFlight

    JOIN Commander C ON C.id=PaxFlight.commander_id
    GROUP BY C.id
  ) AS CS2
  ON CS1.planet_count < CS2.planet_count
  OR CS1.planet_count=CS2.planet_count AND CS1.pax_total < CS2.pax_total
  GROUP BY CS1.id
) AS CapRank
WHERE CapRank.rank < 3;


-- Что если мы не можем или не хотим создать представление, а запрос упростить хотим?
WITH FlightStats AS (
  SELECT F.id, F.planet_id, F.spacecraft_id, F.commander_id,
         SUM(CASE B.flight_id IS NULL WHEN true THEN 0 ELSE 1 END) AS pax_cnt
  FROM Flight F LEFT JOIN Booking B ON F.id=B.flight_id
  GROUP BY F.id
),
CmdStats AS (
  SELECT C.id, COUNT(DISTINCT planet_id) AS planet_count, SUM(pax_cnt) AS pax_total
  FROM FlightStats
  JOIN Commander C ON C.id=FlightStats.commander_id
  GROUP BY C.id
),
CmdOrdering AS (
  SELECT CS1.id,
         SUM(CASE CS2.id IS NULL WHEN true THEN 0 ELSE 1 END) AS rank
  FROM CmdStats CS1 LEFT JOIN CmdStats CS2
  ON CS1.planet_count < CS2.planet_count
  OR CS1.planet_count=CS2.planet_count AND CS1.pax_total < CS2.pax_total
  GROUP BY CS1.id
)
SELECT * FROM CmdOrdering WHERE rank < 3;

--- Что если мы хотим такую таблицу:
-- commander_id, name, rank,
-- planet_id, distance,
-- total_pax_per_commander, total_pax_per_planet,
-- total_pax_per_commander_and_planet

-- Нам помогут оконные функции
WITH FlightStats AS (
  -- Это всё тот же PaxFlight
  SELECT F.id, F.planet_id, F.spacecraft_id, F.commander_id,
         SUM(CASE B.flight_id IS NULL WHEN true THEN 0 ELSE 1 END) AS pax_cnt
  FROM Flight F LEFT JOIN Booking B ON F.id=B.flight_id
  GROUP BY F.id
),
FlightStatsExt AS (
  -- Просто добавили атрибуты капитана и планеты
  SELECT FS.*, C.name AS commander_name, P.name AS planet_name, P.distance FROM
  FlightStats FS
  JOIN Commander C ON FS.commander_id = C.id
  JOIN Planet P ON P.id = FS.planet_id
)
-- А теперь суммируем и считаем по разным партициям
SELECT DISTINCT FSE.commander_name, FSE.planet_id,
       SUM(pax_cnt) OVER (PARTITION BY commander_id) AS total_pax_per_commander,
       SUM(pax_cnt) OVER (PARTITION BY planet_id) AS total_pax_per_planet,
       SUM(pax_cnt) OVER (PARTITION BY commander_id, planet_id) AS total_pax_per_commander_and_planet,
       COUNT(*) OVER (PARTITION BY commander_id, planet_id) AS flight_count
FROM FlightStatsExt FSE;



WITH FlightStats AS (
  -- Посчитаем базовую статистику
  SELECT F.id AS flight_id, F.planet_id, F.spacecraft_id, F.commander_id,
         SUM(CASE B.flight_id IS NULL WHEN true THEN 0 ELSE 1 END) AS pax_cnt
  FROM Flight F LEFT JOIN Booking B ON F.id=B.flight_id
  GROUP BY F.id
),
FlightStatsExt AS (
  -- Добавим атрибуты капитанов и планет
  SELECT FS.*, C.name AS commander_name, P.name AS planet_name, P.distance FROM
  FlightStats FS
  JOIN Commander C ON FS.commander_id = C.id
  JOIN Planet P ON P.id = FS.planet_id
),
CommanderPlanetCount AS (
  -- Отдельно посчитаем количество разных планет, посещённых капитаном
  -- К сожалению Постгрес не умеет делать COUNT DISTINCT в окне
  SELECT commander_id, COUNT(DISTINCT planet_id) total_planet_per_commander FROM FlightStats GROUP BY commander_id
),
CommanderPlanetStats AS (
  -- Посчитаем несколько агрегатных значений по разным группам
  -- и допишем их к атрибутам планеты и капитана
  SELECT DISTINCT FSE.commander_id, FSE.commander_name, FSE.planet_id,
         CPC.total_planet_per_commander,
         SUM(pax_cnt) OVER (PARTITION BY commander_id) AS total_pax_per_commander,
         SUM(pax_cnt) OVER (PARTITION BY planet_id) AS total_pax_per_planet,
         SUM(pax_cnt) OVER (PARTITION BY commander_id, planet_id) AS total_pax_per_commander_and_planet,
         COUNT(*) OVER (PARTITION BY commander_id, planet_id) AS flight_count
  FROM FlightStatsExt AS FSE JOIN CommanderPlanetCount AS CPC USING (commander_id)
),
CommanderRank AS (
  -- Посчитаем ранк! У нас одна партиция, упорядоченная по планетам и пассажирам DESC
  SELECT commander_id,
    ROW_NUMBER() OVER (ORDER BY total_planet_per_commander DESC, total_pax_per_commander DESC) AS rank
  FROM (
    -- в CommanderPlanetStats каждый капитан повторён столько раз, сколько
    -- сделал рейсов. Выберем только уникальные сведения для ранжирования
    SELECT DISTINCT commander_id, total_planet_per_commander, total_pax_per_commander
    FROM CommanderPlanetStats
  ) AS T
)
SELECT DISTINCT rank, commander_name, total_planet_per_commander, total_pax_per_commander
FROM CommanderPlanetStats JOIN CommanderRank USING (commander_id)
ORDER BY rank;




-- Бывают и другие оконные функции!
WITH FlightStats AS (
  -- Посчитаем базовую статистику
  SELECT F.id AS flight_id, F.planet_id, F.spacecraft_id, F.commander_id,
         SUM(CASE B.flight_id IS NULL WHEN true THEN 0 ELSE 1 END) AS pax_cnt
  FROM Flight F LEFT JOIN Booking B ON F.id=B.flight_id
  GROUP BY F.id
),
PaxPerPlanet AS (
  SELECT planet_id, SUM(pax_cnt) AS pax_cnt FROM FlightStats GROUP BY planet_id
)
SELECT planet_id, pax_cnt, NTILE(10) OVER (ORDER BY pax_cnt)
FROM PaxPerPlanet;
