SET search_path=public;
 
DROP TABLE IF EXISTS AmericanCountry CASCADE;
DROP TABLE IF EXISTS EuropeanCountry CASCADE;
DROP TABLE IF EXISTS Plantation CASCADE;
DROP TABLE IF EXISTS AmericanPort CASCADE;
DROP TABLE IF EXISTS EuropeanPort CASCADE;
DROP TABLE IF EXISTS Procurement CASCADE;
DROP TABLE IF EXISTS Ship CASCADE;
DROP TABLE IF EXISTS TransferType CASCADE;
DROP TABLE IF EXISTS Transfer CASCADE;
DROP TABLE IF EXISTS CoffeeCustomer CASCADE;
 
CREATE TABLE AmericanCountry (
    id              SERIAL    PRIMARY KEY,
    name            TEXT      NOT NULL
);
 
 
CREATE TABLE EuropeanCountry (
    id              SERIAL    PRIMARY KEY,
    name            TEXT      NOT NULL
);
 
 
CREATE TABLE AmericanPort (
    id              SERIAL    PRIMARY KEY,
    name            TEXT      NOT NULL,
    country_id      INTEGER   NOT NULL REFERENCES AmericanCountry(id),
    longitude       NUMERIC(8, 5)   NULL CHECK ((longitude > -180) AND (longitude < 180)),
    latitude        NUMERIC(7, 5)   NULL CHECK ((latitude > -90) AND (latitude < 90))
);
 
 
CREATE TABLE EuropeanPort (
    id              SERIAL    PRIMARY KEY,
    name            TEXT      NOT NULL,
    country_id      INTEGER   NOT NULL REFERENCES EuropeanCountry(id),
    longitude       NUMERIC(8, 5)   NULL CHECK ((longitude > -180) AND (longitude < 180)),
    latitude        NUMERIC(7, 5)   NULL CHECK ((latitude > -90) AND (latitude < 90))
);
 
CREATE TABLE Plantation (
    id              SERIAL   PRIMARY KEY,
    country_id      INTEGER   NOT NULL REFERENCES AmericanCountry(id),
    head_name       TEXT      NOT NULL,
    port_id         INTEGER   NOT NULL REFERENCES AmericanPort(id)
);
 
CREATE TABLE Procurement (
    id              SERIAL   PRIMARY KEY,
    plantation_id   INTEGER   NOT NULL REFERENCES Plantation(id),
  --  port_id         INTEGER   NOT NULL REFERENCES AmericanPort(id),
  --  Не нужно, так как у плантации только один вариант для поставки
    weight          NUMERIC(8,2)      NOT NULL CHECK (weight > 0),
    pr_date         DATE      NOT NULL
);
 
CREATE TABLE Ship (
    id              SERIAL    PRIMARY KEY,
    name            TEXT      NOT NULL,
    capacity        INT       NOT NULL CHECK (capacity > 0)
);
 
CREATE TABLE TransferType (
    id              SERIAL    PRIMARY KEY,
    am_port         INTEGER   NOT NULL REFERENCES AmericanPort(id),
    eu_port         INTEGER   NOT NULL REFERENCES EuropeanPort(id),
    ship            INTEGER   NOT NULL REFERENCES Ship(id),
    price           NUMERIC(15,2)      NOT NULL CHECK (price > 0),
    UNIQUE (am_port, eu_port, ship)
);

CREATE TABLE Tarif (
    id              SERIAL    PRIMARY KEY,
    name            TEXT      NOT NULL,
    price           NUMERIC   NOT NULL CHECK (price > 0)
);

 
CREATE TABLE CoffeeCustomer (
    id              SERIAL    PRIMARY KEY,
    name            TEXT      NOT NULL,
    price           NUMERIC (4, 2) NOT NULL CHECK (price > 0)
);
 
CREATE TABEL Tarif_Customer (
    cust_id          INTEGER   NOT NULL REFERENCES CoffeeCustomer(id)
    tarif_id         INTEGER   NOT NULL REFERENCES Tarif(id)
    PRIMARY KEY (cust_id, tarif_id)
)

CREATE TABLE Transfer (
    id              SERIAL    PRIMARY KEY,
    type            INTEGER   NOT NULL REFERENCES TransferType(id),
    t_date          DATE      NOT NULL,
    customer_id     INTEGER   REFERENCES CoffeeCustomer(id)
    -- customer_id может быть null, если не знаем покупателя при добавлении трансфера
);

CREATE TABEL Transfer_Customer (
    cust_id             INTEGER   NOT NULL 
    tarnsfer_id         INTEGER   NOT NULL 
    tarif_id            INTEGER   NOT NULL REFERENCES Tarif(id)
    amount 		INTEGER   NOT NULL CHECK (price > 0)
    PRIMARY KEY (cust_id, tarnsfer_id )
    FOREIGN KEY (cust_id, tarif_id) REFERENCES Tariff_Customer(tariff_id, customer_id),
)


    PRIMARY KEY (customer_id, transfer_id)    
);
