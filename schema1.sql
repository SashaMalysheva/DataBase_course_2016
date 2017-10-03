SET search_path=public;

/**
 * Пироговый справочник.
 *
 * Предполгается, что названия пирогов уникальны (их называют посетители),
 * но для ускорения работы есть фиктивные номера. Вес указывается только в
 * килограммах (три знака после запятой - граммы), валюта оплаты - только рубли.
 *
 * Так как ассортимент меняется, пироги из старых заказов могут исчезнуть, однако
 * информацию о них терять не хочется. Поэтому пирог можно пометить как "доступный"
 * или "недоступный" для заказа.
 */
DROP TABLE IF EXISTS Pies CASCADE;
CREATE TABLE Pies (
  Id            SERIAL         NOT NULL PRIMARY KEY,
  Title         VARCHAR(100)   NOT NULL UNIQUE,
  FullWeightKg  DECIMAL(10, 3) NOT NULL CHECK(FullWeightKg > 0),
  PriceRubPerKg DECIMAL(10, 2) NOT NULL CHECK(PriceRubPerKg > 0),
  IsOffered     BOOLEAN        NOT NULL DEFAULT true
);

INSERT INTO Pies(Title, FullWeightKg, PriceRubPerKg) VALUES
    ('Пирог с рисом и яйцом', 0.5, 480),
    ('Пирог с картофелем, сыром и грибами', 1, 640),
    ('Пирог с кроликом и грибами', 0.5, 480),
    ('Пирог с яблоками', 2.0, 400),
    ('Пирог с яблоками и корицей', 2.0, 400),
    ('Пирог с капустой и брусникой', 2.0, 350),
    ('Пирожок с капустой', 0.1, 500),
    ('Кулебяка с мясом', 1.0, 720),
    ('Пирожок с мороженым', 0.1, 600),
    ('Булка с изюмом', 0.1, 300);
/**
 * Справочник существующих ингридиентов.
 *
 * Только имена. Каждый ингридиент может считаться в разных единицах в
 * разных рецептах (штуки шоколадок, граммы шоколада), но на складе должен
 * храниться только в одном виде (либо невскрытые пачки, либо суммарный вес),
 * иначе приложениям надо будет постоянно конвертировать. Поэтому имена
 * уникальны.
 */
DROP TABLE IF EXISTS Ingredients CASCADE;
CREATE TABLE Ingredients (
  Id    SERIAL       NOT NULL PRIMARY KEY,
  Title VARCHAR(100) NOT NULL UNIQUE
);
INSERT INTO Ingredients(Title) VALUES
  ('Мука'), ('Соль'), ('Яйцо'), ('Рис'), ('Картофель'),
  ('Сыр'), ('Грибы'), ('Яблоки'), ('Кролик'), ('Капуста'),
  ('Мясо'), ('Брусника'), ('Корица'), ('Бумага'), ('Тараканы'), ('Мороженое');

/**
 * Единицы измерения в ингридиентах пирогов: кг (по массе), литр (по объёму),
 * штука.
 */
DROP TYPE IF EXISTS AmountUnit CASCADE;
CREATE TYPE AmountUnit AS ENUM ('кг', 'гр', 'шт');

/**
 * Ингридиенты пирогов.
 *
 * Может потребоваться несколько ингридиентов в разных единицах измерения:
 * 200 грамм яблок в тесто и ещё одно целое для украшения.
 */
DROP TABLE IF EXISTS PieComponents CASCADE;
CREATE TABLE PieComponents (
  PieId        INT            NOT NULL REFERENCES Pies,
  IngredientId INT            NOT NULL REFERENCES Ingredients,
  Amount       DECIMAL(10, 3) NOT NULL CHECK(Amount > 0),
  AmountUnit   AmountUnit     NOT NULL,
  PRIMARY KEY (PieId, IngredientId, AmountUnit)
);
INSERT INTO PieComponents(PieId, IngredientId, Amount, AmountUnit) VALUES
-- с рисом и яйцом 0.5 kg
(1, 1, 200, 'гр'),
(1, 2, 10, 'гр'),
(1, 3, 4, 'шт'),
(1, 4, 200, 'гр'),
-- с картофелем сыром и грибами 1kg
(2, 1, 300, 'гр'),
(2, 5, 300, 'гр'),
(2, 6, 100, 'гр'),
(2, 7, 100, 'гр'),
-- с кроликом и грибами 0.5kg
(3, 1, 200, 'гр'),
(3, 2, 10, 'гр'),
(3, 9, 50, 'гр'),
(3, 6, 100, 'гр'),
-- с яблоками 2kg
(4, 1, 1, 'кг'),
(4, 2, 10, 'гр'),
(4, 8, 0.6, 'кг'),
-- с яблоками и корицей 2kg
(5, 1, 1, 'кг'),
(5, 2, 10, 'гр'),
(5, 8, 0.6, 'кг'),
(5, 13, 40, 'гр'),
-- с капустой и брусникой 2kg
(6, 1, 1, 'кг'),
(6, 2, 10, 'гр'),
(6, 12, 0.2, 'кг'),
(6, 10, 0.5, 'кг'),
-- пирожок с капустой
(7, 1, 50, 'гр'),
(7, 2, 3, 'гр'),
(7, 12, 15, 'гр'),
(7, 10, 30, 'гр'),
-- кулебяка
(8, 1, 0.5, 'кг'),
(8, 2, 15, 'гр'),
(8, 11, 200, 'гр'),
(8, 14, 200, 'гр'),
-- пирожок с мороженым
(9, 1, 50, 'гр'),
(9, 16, 50, 'гр');

/**
 * Остатки на складе.
 *
 * Разные вещи может быть удобно мерять в разных единицах (литры молока,
 * килограммы мяса), но каждая должна быть измерена ровно в одной единице.
 * Нули разрешены для упрощения учёта.
 */
DROP TABLE IF EXISTS IngredientsRemaining CASCADE;
CREATE TABLE IngredientsRemaining (
  IngredientId INT            NOT NULL PRIMARY KEY REFERENCES Ingredients,
  Amount       DECIMAL(10, 3) NOT NULL CHECK (Amount >= 0),
  AmountUnit   AmountUnit     NOT NULL
);
--  'Мука', 'Соль', 'Яйцо', 'Рис', 'Картофель',
--  'Сыр', 'Грибы', 'Яблоки', 'Кролик', 'Капуста',
--  'Мясо', 'Брусника', 'Корица', 'Бумага'

INSERT INTO IngredientsRemaining(IngredientId, Amount, AmountUnit) VALUES
(1, 200, 'кг'),
(2, 2, 'кг'),
(3, 100, 'шт'),
(4, 10, 'кг'),
(5, 100, 'кг'),
(6, 5, 'кг'),
(7, 20, 'кг'),
(8, 55, 'кг'),
(9, 2, 'кг'),
(10, 50, 'кг'),
(11, 5, 'кг'),
(12, 7, 'кг'),
(13, 2, 'кг'),
(14, 30, 'кг'),
(15, 38, 'шт'),
(16, 5.5, 'кг');

/**
 * За какой период статистика.
 *
 * Прямо сейчас есть только выходные и будни, но если хранить статистику
 * в отдельных строках, то её удобно дополнительно агрегировать
 * (например, минимальная среднесуточная статистика получится через
 * MIN и GROUP BY).
 */
DROP TYPE IF EXISTS StatsType CASCADE;
CREATE TYPE StatsType AS ENUM ('holiday', 'business_day');

/**
 * Статистика о продажах.
 *
 * Для каждого пирога и периода есть не более одной записи.
 * Нули разрешены для упрощения экспорта из стороннего формата.
 */
DROP TABLE IF EXISTS SalesStats CASCADE;
CREATE TABLE SalesStats (
  PieId      INT       NOT NULL REFERENCES Pies,
  StatsType  StatsType NOT NULL,
  SoldAmount INT       NOT NULL CHECK(SoldAmount >= 0),
  PRIMARY KEY (PieId, StatsType)
);

--   ('Пирог с рисом и яйцом', 0.5, 480),
--    ('Пирог с картофелем, сыром и грибами', 1, 640),
--    ('Пирог с кроликом и грибами', 0.5, 480),
--    ('Пирог с яблоками', 2.0, 400),
--    ('Пирог с яблоками и корицей', 2.0, 400),
--    ('Пирог с капустой и брусникой', 2.0, 350),
--    ('Пирожок с капустой', 0.1, 500),
--    ('Кулебяка с мясом', 1.0, 720));
--/
INSERT INTO SalesStats(PieId, StatsType, SoldAmount) VALUES
(1, 'holiday', 20), (1, 'business_day', 28),
(2, 'holiday', 15), (2, 'business_day', 30),
(3, 'holiday', 17), (3, 'business_day', 25),
(4, 'holiday', 40), (4, 'business_day', 35),
(5, 'holiday', 45), (5, 'business_day', 30),
(6, 'holiday', 30), (6, 'business_day', 32),
(7, 'holiday', 60), (7, 'business_day', 120),
(8, 'holiday', 10), (8, 'business_day', 42),
(9, 'holiday', 100);

/**
 * Постоянные клиенты.
 *
 * У каждого есть уникальный номер и неуникальное имя (название организации,
 * имя-фамилия, ник). Скидка бывает нулевая, чтобы можно было давать
 * постоянным клиентам какие-то ещё бонусы, кроме денежных.
 */
DROP TABLE IF EXISTS Customers CASCADE;
CREATE Table Customers (
  Id              SERIAL       NOT NULL PRIMARY KEY,
  Name            VARCHAR(100) NOT NULL,
  DiscountPercent INT          NOT NULL CHECK(DiscountPercent BETWEEN 0 AND 100)
);
WITH Ids AS(
  SELECT generate_series(1, 100) AS id
), Customer AS (
  SELECT id, random()::TEXT AS name, (0.5 + random() * 20)::int AS discount
  FROM Ids
)
INSERT INTO Customers(Name, DiscountPercent)
SELECT name, discount FROM Customer;

/**
 * Статус заказа.
 */
DROP TYPE IF EXISTS OrderStatus CASCADE;
CREATE TYPE OrderStatus AS ENUM ('received', 'processing', 'shipped', 'completed');

/**
 * Мелкооптовые заказы.
 *
 * У каждого есть уникальный номер, ожидаемое время доставки (с TZ,
 * чтобы поменьше зависеть от переводов часов), адрес доставки, статус.
 * Также может быть имя получателя (может не быть, если доставка на Reception),
 * и может быть номер постоянного покупателя.
 */
DROP TABLE IF EXISTS BatchOrders CASCADE;
CREATE Table BatchOrders (
  Id               SERIAL                   NOT NULL  PRIMARY KEY,
  Customer         INT                      NULL      REFERENCES Customers,
  ExpectedDelivery TIMESTAMP                NOT NULL,
  ReceiverName     TEXT                     NULL,
  Address          TEXT                     NULL,
  Status           OrderStatus              NOT NULL
);
WITH Ids AS(
  SELECT generate_series(1, 200) AS id
), BO AS (
  SELECT id,
    (0.5 + random() * (SELECT COUNT(*) FROM Customers))::int AS customer_id,
    timestamp '2016-06-01' + random() * interval '180 days' AS delivery_time
  FROM Ids
)
INSERT INTO BatchOrders(Customer, ExpectedDelivery, Status)
SELECT customer_id, delivery_time, 'completed'
FROM BO;

INSERT INTO BatchOrders(ReceiverName, ExpectedDelivery, Status) VALUES ('Александр Омельченко', '2016-12-15 14:00', 'completed');

/**
 * Состав заказов.
 */
DROP TABLE IF EXISTS BatchOrderPies CASCADE;
CREATE TABLE BatchOrderPies (
  BatchOrderId INT NOT NULL REFERENCES BatchOrders,
  PieId        INT NOT NULL REFERENCES Pies,
  Amount       INT NOT NULL CHECK(Amount > 0),
  PRIMARY KEY(BatchOrderId, PieId)
);
WITH Ids AS(
  SELECT generate_series(1, 350) AS id
), BOP AS (
  SELECT id,
    (0.5 + random() * (SELECT COUNT(*) FROM BatchOrders))::int AS order_id,
    0.5 + (random() +random() + random() + random() + random() + random() + random() + random())::INT as pie_id
  FROM Ids
),
UBOP AS (
SELECT DISTINCT order_id, pie_id FROM BOP
)
INSERT INTO BatchOrderPies(BatchOrderId, PieId, Amount)
SELECT order_id, pie_id, GREATEST(1, (random() + random() + random())::INT) as amount FROM UBOP;
