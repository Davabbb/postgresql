CREATE TABLE people (
  people_id SERIAL PRIMARY KEY,
  people_name TEXT,
  UNIQUE (people_name)
);

CREATE TABLE cars (
  car_id SERIAL PRIMARY KEY,
  car_name TEXT,
  UNIQUE (car_name)
);

CREATE TABLE date_buy_car (
  people_id INTEGER,
  car_id INTEGER,
  date_purchase DATE,
  FOREIGN KEY (people_id) REFERENCES people(people_id),
  FOREIGN KEY (car_id) REFERENCES cars(car_id)
);


CREATE USER admin WITH PASSWORD 'admin';
CREATE USER provider WITH PASSWORD 'provider123';
CREATE USER owner WITH PASSWORD '1234';

GRANT ALL PRIVILEGES ON TABLE people TO admin;
GRANT ALL PRIVILEGES ON TABLE cars to admin;
GRANT ALL PRIVILEGES ON TABLE date_buy_car to admin;
GRANT USAGE, SELECT ON SEQUENCE people_people_id_seq TO admin;
GRANT USAGE, SELECT ON SEQUENCE cars_car_id_seq TO admin;


GRANT SELECT, INSERT ON TABLE cars TO provider;
GRANT USAGE, SELECT ON SEQUENCE cars_car_id_seq TO provider;

GRANT SELECT ON TABLE cars TO owner;
ALTER TABLE date_buy_car ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE date_buy_car TO owner;
GRANT SELECT ON TABLE people TO owner;

GRANT SELECT (people_id) ON people TO owner;

CREATE POLICY owner_car ON date_buy_car FOR SELECT TO owner USING
  (EXISTS (SELECT * FROM people WHERE people.people_id = date_buy_car.people_id AND user = people_name));
SELECT * FROM pg_policies;

CREATE USER viktor;
GRANT owner TO viktor;

SET ROLE admin;

INSERT INTO people(people_name) VALUES ('David'); --ТЕСТЫ НА INSERT ADMIN
INSERT INTO cars(car_name) VALUES ('bmw');
SELECT * FROM people;
SELECT * FROM cars;
SELECT * FROM date_buy_car;

UPDATE people SET people_name = 'miller' WHERE people_id = 1; --ТЕСТЫ НА UPDATE ADMIN
UPDATE cars SET car_name = 'lada' WHERE car_id = 1;
SELECT * FROM people;
SELECT * FROM cars;

INSERT INTO people(people_name) VALUES ('viktor'); --ТЕСТЫ НА DELETE ADMIN
SELECT * FROM people;
DELETE FROM people WHERE people_name = 'viktor';
SELECT * FROM people;

SET ROLE provider;
INSERT INTO people(people_name) VALUES ('viktor'); --ТЕСТЫ НА INSERT PROVIDER
INSERT INTO cars(car_name) VALUES ('merc');
SELECT * FROM cars;

UPDATE cars SET car_name = 'audi' WHERE car_id = 2; --ТЕСТЫ НА UPDATE PROVIDER
SELECT * FROM cars;

SET ROLE owner;
INSERT INTO people(people_name) VALUES ('name'); --ТЕСТЫ НА INSERT OWNER
INSERT INTO cars(car_name) values ('audi');

SELECT * FROM cars; --ТЕСТЫ НА SELECT OWNER

SET ROLE postgres;
INSERT INTO people(people_name) VALUES ('viktor');
SELECT * FROM people;
INSERT INTO cars(car_name) values ('carrrrrrr');
SELECT * FROM cars;
INSERT INTO date_buy_car (people_id, car_id, date_purchase) VALUES (3, 1, '2023-01-01'), (3, 2, '2023-01-01'),
                                                                   (1, 3, '2023-01-01');

SELECT * FROM date_buy_car;
SET ROLE viktor;
SELECT * FROM date_buy_car;

SET ROLE postgres; --ТЕСТ НА INSERT ВЛАДЕЛЬЦА
INSERT INTO cars(car_name) values ('audi');
SELECT * FROM cars;

DROP POLICY owner_car ON date_buy_car;
DROP TABLE people cascade;
DROP TABLE cars cascade;
DROP TABLE date_buy_car;
DROP ROLE admin;
DROP ROLE provider;
DROP ROLE owner;
DROP USER viktor;

