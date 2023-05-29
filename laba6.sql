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


CREATE VIEW owners_and_cars AS
SELECT people_name, car_name, date_purchase
FROM date_buy_car
JOIN people p ON date_buy_car.people_id = p.people_id
JOIN cars c on c.car_id = date_buy_car.car_id;


CREATE OR REPLACE FUNCTION insert_in() RETURNS TRIGGER AS $$
DECLARE
    p_id INTEGER;
    c_id INTEGER;
BEGIN

  SELECT people_id FROM people WHERE people_name = NEW.people_name INTO p_id;
  IF p_id IS NULL THEN
    INSERT INTO people(people_name) VALUES (NEW.people_name) returning people_id INTO p_id;
  END IF;

  SELECT car_id FROM cars WHERE car_name = NEW.car_name INTO c_id;
  IF c_id IS NULL THEN
    INSERT INTO cars(car_name) VALUES (NEW.car_name) returning car_id INTO c_id;
  END IF;

    IF EXISTS(SELECT * FROM date_buy_car WHERE people_id = p_id AND
                                                car_id = c_id AND
                                                date_purchase = NEW.date_purchase) THEN
    RAISE EXCEPTION 'Эта строчка уже есть';
  END IF;

  INSERT INTO date_buy_car(car_id, people_id, date_purchase)
  VALUES (c_id, p_id, NEW.date_purchase);
--   SELECT c_id, p_id, NEW.date_purchase
--   WHERE NOT EXISTS (SELECT * FROM date_buy_car
--   WHERE car_id = c_id AND people_id = p_id AND date_purchase = NEW.date_purchase);

  RETURN NEW;
END
$$ LANGUAGE plpgsql;


--   WITH c AS (SELECT car_id FROM cars WHERE car_name = NEW.car_name),
--        p AS (SELECT people_id FROM people WHERE people_name = NEW.people_name)
--   INSERT INTO date_buy_car(car_id, people_id, date_purchase)
--   SELECT c.car_id, p.people_id, NEW.date_purchase
--   FROM c, p
--   WHERE NOT EXISTS (SELECT 1 FROM date_buy_car
--   WHERE car_id = c.car_id AND people_id = p.people_id AND date_purchase = NEW.date_purchase);

CREATE TRIGGER insert_in_trigger
INSTEAD OF INSERT ON owners_and_cars
FOR EACH ROW
EXECUTE FUNCTION insert_in();


CREATE OR REPLACE FUNCTION update_in() RETURNS TRIGGER AS $$
BEGIN
  UPDATE date_buy_car SET date_purchase = NEW.date_purchase
  WHERE car_id IN (SELECT car_id FROM cars WHERE car_name = NEW.car_name)
    AND people_id IN (SELECT people_id FROM people WHERE people_name = NEW.people_name)
  AND date_purchase = NEW.date_purchase;

  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_in_trigger
INSTEAD OF UPDATE ON owners_and_cars
FOR EACH ROW
EXECUTE FUNCTION update_in();


CREATE OR REPLACE FUNCTION delete_() RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM date_buy_car WHERE
  car_id IN (SELECT car_id FROM cars WHERE car_name = OLD.car_name)
    AND people_id IN (SELECT people_id FROM people WHERE people_name = OLD.people_name)
  AND date_purchase = OLD.date_purchase;

  RETURN OLD;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_trigger
INSTEAD OF DELETE ON owners_and_cars
FOR EACH ROW
EXECUTE FUNCTION delete_();


INSERT INTO owners_and_cars(people_name, car_name, date_purchase) VALUES ('David', 'bmw', '2003-01-01');
INSERT INTO owners_and_cars(people_name, car_name, date_purchase) VALUES ('Viktor', 'granta', '2018-01-01');
INSERT INTO owners_and_cars(people_name, car_name, date_purchase) VALUES ('Vanya', 'priora', '2014-01-01');
SELECT * FROM people;
SELECT * FROM cars;
SELECT * FROM date_buy_car;
SELECT * FROM owners_and_cars;

INSERT INTO owners_and_cars(people_name, car_name, date_purchase) VALUES ('David', 'mers', '2003-01-01');
SELECT * FROM people;
SELECT * FROM cars;
SELECT * FROM date_buy_car;
SELECT * FROM owners_and_cars;

INSERT INTO owners_and_cars(people_name, car_name, date_purchase) VALUES ('Miller', 'bmw', '2003-01-01');
SELECT * FROM people;
SELECT * FROM cars;
SELECT * FROM date_buy_car;
SELECT * FROM owners_and_cars;

INSERT INTO owners_and_cars(people_name, car_name, date_purchase) VALUES ('David', 'bmw', '2008-01-01');
SELECT * FROM people;
SELECT * FROM cars;
SELECT * FROM date_buy_car;
SELECT * FROM owners_and_cars;

INSERT INTO owners_and_cars(people_name, car_name, date_purchase) VALUES ('David', 'bmw', '2003-01-01');
SELECT * FROM people;
SELECT * FROM cars;
SELECT * FROM date_buy_car;
SELECT * FROM owners_and_cars;

UPDATE owners_and_cars SET date_purchase = '2020-01-01' WHERE people_name = 'David';
SELECT * FROM owners_and_cars;
SELECT * FROM date_buy_car;

UPDATE owners_and_cars SET date_purchase = '2023-01-01' WHERE people_name = 'Miller';
SELECT * FROM owners_and_cars;
SELECT * FROM date_buy_car;

UPDATE owners_and_cars SET date_purchase = '2020-01-01' WHERE car_name = 'bmw';
SELECT * FROM owners_and_cars;
SELECT * FROM date_buy_car;

UPDATE owners_and_cars SET date_purchase = '2023-02-01' WHERE date_purchase = '2003-01-01';
SELECT * FROM owners_and_cars;
SELECT * FROM date_buy_car;

UPDATE owners_and_cars SET date_purchase = '2007-01-01' WHERE people_name = 'aboba';
SELECT * FROM owners_and_cars;
SELECT * FROM date_buy_car;

DELETE FROM owners_and_cars WHERE date_purchase = '2020-01-01';
SELECT * FROM owners_and_cars;
SELECT * FROM date_buy_car;

DELETE FROM owners_and_cars WHERE date_purchase = '2005-01-01';
SELECT * FROM owners_and_cars;
SELECT * FROM date_buy_car;

DELETE FROM owners_and_cars WHERE people_name = 'Viktor';
SELECT * FROM owners_and_cars;
SELECT * FROM date_buy_car;

DELETE FROM owners_and_cars WHERE car_name = 'priora';
SELECT * FROM owners_and_cars;
SELECT * FROM  date_buy_car;

INSERT INTO owners_and_cars(people_name, car_name, date_purchase) VALUES ('David', 'bmw', '2003-01-01');
INSERT INTO owners_and_cars(people_name, car_name, date_purchase) VALUES ('David', 'bmw', '2005-01-01');
DELETE FROM owners_and_cars WHERE date_purchase = '2003-01-01';
SELECT * FROM owners_and_cars;
SELECT * FROM  date_buy_car;



/*
DROP TABLE people cascade;
DROP TABLE cars cascade;
DROP TABLE date_buy_car;
*/