CREATE OR REPLACE FUNCTION take_(table_name_audit TEXT, OUT column_names_ TEXT) RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
column_name_ TEXT;
takes_ CURSOR FOR (SELECT column_name FROM information_schema.columns WHERE table_name = table_name_audit);
BEGIN
OPEN takes_;
column_names_ := '';
LOOP
    FETCH takes_ INTO column_name_;
    EXIT WHEN NOT FOUND;
    IF column_name_ <> 'who_modified' AND column_name_ <> 'operation' AND column_name_ <> 'time' THEN
        column_names_ :=  column_names_ || quote_ident(column_name_) || ', ';
    END IF;
END LOOP;
CLOSE takes_;
END
$$;


CREATE OR REPLACE FUNCTION create_audit() RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    tables CURSOR FOR (SELECT table_name FROM information_schema.tables WHERE table_schema = 'public');
    table_name_ TEXT;
    table_name_audit TEXT;
    columnssss TEXT;
BEGIN
    OPEN tables;
    LOOP
        FETCH tables INTO table_name_;
        EXIT WHEN NOT FOUND;
        table_name_audit = quote_ident(table_name_ || '_audit');
        EXECUTE 'CREATE TABLE ' || table_name_audit || ' AS SELECT * FROM ' || quote_ident(table_name_);
        EXECUTE 'ALTER TABLE ' || table_name_audit || ' ADD COLUMN who_modified TEXT DEFAULT current_user';
        EXECUTE 'ALTER TABLE ' || table_name_audit || ' ADD COLUMN operation TEXT';
        EXECUTE 'ALTER TABLE ' || table_name_audit || ' ADD COLUMN time TIMESTAMP DEFAULT current_timestamp';

        columnssss = take_(table_name_audit);

        EXECUTE 'CREATE OR REPLACE FUNCTION ' || quote_ident(table_name_ || '_audit_insert') ||
                '() RETURNS TRIGGER AS $BODY$ BEGIN ' || 'INSERT INTO ' || table_name_audit ||
                ' (' || columnssss || 'operation)' ||
                ' SELECT ' || columnssss || ' ''INSERT'' FROM new_table; ' ||
                'RETURN NULL; END; $BODY$ LANGUAGE plpgsql';
        EXECUTE 'CREATE OR REPLACE TRIGGER ' || quote_ident(table_name_ || '_insert_trigger') || ' AFTER INSERT ON ' ||
                quote_ident(table_name_) || ' REFERENCING NEW TABLE AS new_table FOR EACH STATEMENT EXECUTE FUNCTION ' ||
                quote_ident(table_name_ || '_audit_insert') || '()';

        EXECUTE 'CREATE OR REPLACE FUNCTION ' || quote_ident(table_name_ || '_audit_update') ||
                '() RETURNS TRIGGER AS $BODY$ BEGIN ' || 'INSERT INTO ' || table_name_audit ||
                ' (' || columnssss || 'who_modified, operation)' ||
                ' SELECT ' || columnssss || 'current_user, ''UPDATE'' FROM new_table; ' ||
                'RETURN NULL; END; $BODY$ LANGUAGE plpgsql';
        EXECUTE 'CREATE OR REPLACE TRIGGER ' || quote_ident(table_name_ || '_update_trigger') || ' AFTER UPDATE ON ' ||
                quote_ident(table_name_) || ' REFERENCING NEW TABLE AS new_table FOR EACH STATEMENT EXECUTE FUNCTION ' ||
                quote_ident(table_name_ || '_audit_update') || '()';

        EXECUTE 'CREATE OR REPLACE FUNCTION ' || quote_ident(table_name_ || '_audit_delete') ||
                '() RETURNS TRIGGER AS $BODY$ BEGIN ' || 'INSERT INTO ' || table_name_audit ||
                ' (' || columnssss || 'who_modified, operation)' ||
                ' SELECT ' || columnssss || 'current_user, ''DELETE'' FROM old_table; ' ||
                'RETURN NULL; END; $BODY$ LANGUAGE plpgsql';
        EXECUTE 'CREATE OR REPLACE TRIGGER ' || quote_ident(table_name_ || '_delete_trigger') || ' AFTER DELETE ON ' ||
                quote_ident(table_name_) || ' REFERENCING OLD TABLE AS old_table FOR EACH STATEMENT EXECUTE FUNCTION ' ||
                quote_ident(table_name_ || '_audit_delete') || '()';
    END LOOP;
    CLOSE tables;
END;
$$;

CREATE TABLE "my_table" (
    id SERIAL PRIMARY KEY,
    "a b c d" INT
); --ТЕСТ НА QUOTE_IDENT

CREATE TABLE people (
  people_id SERIAL PRIMARY KEY,
  people_name TEXT,
  UNIQUE (people_name)
);

CREATE TABLE cars (
  car_id SERIAL PRIMARY KEY,
  car_name TEXT,
  model TEXT,
  UNIQUE (car_name)
);


SELECT * FROM create_audit();
CREATE USER dava WITH PASSWORD '1234';
GRANT ALL PRIVILEGES ON TABLE people TO dava;
GRANT ALL PRIVILEGES ON TABLE people_audit TO dava;
GRANT USAGE, SELECT ON SEQUENCE people_people_id_seq TO dava;

INSERT INTO "my_table"("a b c d") VALUES (4), (5); --ТЕСТ НА QUOTE_IDENT
SELECT * FROM "my_table";
SELECT * FROM my_table_audit;

INSERT INTO people (people_name) VALUES ('dava'), ('miller');
INSERT INTO cars (car_name, model) VALUES ('bmw', 'm5'), ('merc', 'gt53');
SELECT * FROM people_audit;
SELECT * FROM cars_audit;
UPDATE cars SET car_name = 'audi', model = 'q8' WHERE car_name = 'bmw';
SELECT * FROM cars_audit;
DELETE FROM cars WHERE car_name = 'merc';
SELECT * FROM cars_audit;


SET ROLE dava;

INSERT INTO people (people_name) VALUES ('viktor'), ('vanya');
SELECT * FROM people_audit;
UPDATE people SET people_name = 'bebbbbb' WHERE people_name = 'viktor';
SELECT * FROM people_audit;
DELETE FROM people WHERE people_name = 'miller';
SELECT * FROM people_audit;

SET ROLE postgres;



SET ROLE postgres;
DROP FUNCTION create_audit();
DROP TABLE people CASCADE ;
DROP TABLE cars CASCADE;
DROP TABLE cars_audit;
DROP TABLE people_audit;
DROP ROLE dava;
DROP FUNCTION take_(text);
DROP TABLE "my_table";
DROP TABLE my_table_audit;