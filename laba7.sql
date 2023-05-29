CREATE TABLE people (
    id SERIAL PRIMARY KEY,
    name TEXT,
    age INT
);


CREATE TABLE cars (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER NOT NULL,
    title TEXT,
    model TEXT,
    FOREIGN KEY (owner_id) REFERENCES people(id)
);


INSERT INTO people (name, age) VALUES ('dava', 20), ('miller', 19);
INSERT INTO cars (owner_id, title, model) VALUES (1, 'bmw', 'm5'), (2, 'merc', 'gt53');

SAVEPOINT start_;

--НЕПОВТОРЯЕМОЕ ЧТЕНИЕ
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED; --ТЕСТ 1
SELECT * FROM cars WHERE owner_id = 1;
SELECT pg_sleep(5);
SELECT * FROM cars WHERE owner_id = 1;
COMMIT;

--НЕПОВТОРЯЕМОЕ ЧТЕНИЕ
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ; --ТЕСТ 2
SELECT * FROM cars WHERE owner_id = 1;
SELECT pg_sleep(5);
SELECT * FROM cars WHERE owner_id = 1;
COMMIT;

--ФАНТОМНОЕ ЧТЕНИЕ
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ; --ТЕСТ3
SELECT COUNT(*) FROM cars WHERE owner_id = 1;
SELECT pg_sleep(5);
SELECT COUNT(*) FROM cars WHERE owner_id = 1;
COMMIT;


--ФАНТОМНОЕ ЧТЕНИЕ
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE; --ТЕСТ5
SELECT COUNT(*) FROM cars WHERE owner_id = 1;
SELECT pg_sleep(5);
SELECT COUNT(*) FROM cars WHERE owner_id = 1;
COMMIT;


--ФАНТОМНОЕ ЧТЕНИЕ
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED; --ТЕСТ3
SELECT COUNT(*) FROM cars WHERE owner_id = 1;
SELECT pg_sleep(5);
SELECT COUNT(*) FROM cars WHERE owner_id = 1;
COMMIT;


BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ ;
UPDATE cars SET model = 'aboba' WHERE owner_id = 1;
SELECT * FROM cars WHERE owner_id = 1;
SELECT pg_sleep(5);
SELECT * FROM cars WHERE owner_id = 1;
COMMIT;

CREATE TABLE test (
    id INT,
    ab INT
);

INSERT INTO test (id, ab) VALUES (1, 1), (1, 2), (2, 3), (2, 4);

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ ;
INSERT INTO test(id, ab) VALUES (2, (SELECT sum(ab) FROM test WHERE id = 1));
SELECT * FROM test;
SELECT pg_sleep(5);
COMMIT;
SELECT * FROM test;

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
INSERT INTO test(id, ab) VALUES (2, (SELECT sum(ab) FROM test WHERE id = 1));
SELECT * FROM test;
SELECT pg_sleep(5);
COMMIT;
SELECT * FROM test;

DROP TABLE test;
DROP TABLE people CASCADE;
DROP TABLE cars;