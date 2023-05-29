CREATE TABLE spec_table
(
    id INT NOT NULL PRIMARY KEY,
    name_table VARCHAR NOT NULL,
    name_column VARCHAR NOT NULL,
    max INT NOT NULL,
    UNIQUE (name_table, name_column)
);

INSERT INTO spec_table VALUES (1, 'spec', 'id', 1);


CREATE OR REPLACE FUNCTION new_trigger_name(name_table_ VARCHAR, name_column_ VARCHAR, OUT trigger_name_ VARCHAR)
    LANGUAGE plpgsql AS
$$
DECLARE
    trigger_count INT;
BEGIN
    SELECT COUNT(*) + 1 FROM information_schema.triggers WHERE event_object_table = name_table_ INTO trigger_count;
    trigger_name_ := quote_ident(name_table_ || '_' || name_column_ || '_' || trigger_count);
    IF EXISTS (SELECT triggers.trigger_name FROM information_schema.triggers WHERE triggers.trigger_name = trigger_name_
        AND triggers.event_object_table = name_table_) THEN
        trigger_name_ := quote_ident(trigger_name_ || '_' || gen_random_uuid());
    END IF;
END;
$$;


CREATE OR REPLACE FUNCTION update_spec_table()
    RETURNS TRIGGER LANGUAGE plpgsql AS
$$
DECLARE
    max_value INT;
BEGIN
    EXECUTE format('SELECT MAX(%s) FROM new_table', quote_ident(tg_argv[0])) INTO max_value;
    UPDATE spec_table SET max = max_value WHERE name_table = tg_table_name AND name_column = tg_argv[0] AND max_value > max;
    RETURN NULL;
END;
$$;


CREATE OR REPLACE FUNCTION max_val_id(_name_table VARCHAR, _name_column VARCHAR, out _max_id INTEGER)
    LANGUAGE plpgsql
AS
$$
    DECLARE
    data_type_ TEXT;
    BEGIN
    UPDATE spec_table SET max = max + 1 WHERE name_table = _name_table AND name_column = _name_column RETURNING max INTO _max_id;
    IF _max_id IS NULL
        THEN

            IF NOT EXISTS(SELECT * FROM information_schema.tables WHERE table_name = _name_table) THEN
            RAISE EXCEPTION 'Таблица % не найдена', _name_table;
            END IF;
            SELECT data_type FROM information_schema.columns WHERE (table_name = _name_table AND column_name = _name_column) INTO data_type_;
            IF data_type_ IS NULL THEN
                RAISE EXCEPTION 'Столбец % в таблице % не найден', _name_column, _name_table;
            ELSEIF data_type_ <> 'integer' THEN
                RAISE EXCEPTION 'Столбец % в таблице % не INT', _name_column, _name_table;
            END IF;

            EXECUTE format('SELECT COALESCE(MAX(%s) + 1, 1) FROM %s', quote_ident(_name_column), quote_ident(_name_table)) INTO _max_id;

            EXECUTE ('CREATE OR REPLACE TRIGGER ' || new_trigger_name(_name_table, _name_column)
            || ' AFTER UPDATE ON ' || quote_ident(_name_table) || ' REFERENCING NEW TABLE AS new_table' ||
            ' FOR EACH STATEMENT EXECUTE FUNCTION update_spec_table ('
            || quote_literal(_name_column) || ')');

            EXECUTE ('CREATE OR REPLACE TRIGGER ' || new_trigger_name(_name_table, _name_column)
            || ' AFTER INSERT ON ' || quote_ident(_name_table) || ' REFERENCING NEW TABLE AS new_table' ||
            ' FOR EACH STATEMENT EXECUTE FUNCTION update_spec_table ('
            || quote_literal(_name_column) || ')');

            INSERT INTO spec_table VALUES (max_val_id('spec', 'id'), _name_table, _name_column, _max_id);
    END IF;
END
$$;

CREATE TABLE test (id INT);
SELECT * FROM max_val_id('test', 'id'); --ТЕСТЫ ДЛЯ ПРОШЛЫХ ЛАББ
SELECT * FROM spec_table;
INSERT INTO test VALUES (14210);
SELECT * FROM max_val_id('test', 'id');
SELECT * FROM spec_table;
SELECT * FROM max_val_id('bebraaaaa', 'id'); --ОШИБКА НЕТ ТАБЛИЦЫ
SELECT * FROM max_val_id('test', 'chupapi'); --ОШИБКА НЕТ СТОЛБЦА
SELECT * FROM max_val_id('nfjsdkjndasf', 'iiiiiiiiid'); --ОШИБКА НЕТ ТАБЛИЦЫ, НЕТ СТОЛБЦА
CREATE TABLE test1(id TEXT);
SELECT * FROM max_val_id('test1', 'id'); --ОШИБКА ТИПА ДАННЫХ
SELECT trigger_name FROM information_schema.triggers;
DROP TABLE test;
DROP TABLE test1;

CREATE TABLE test2 (num1 INT, num2 INT);
SELECT * FROM max_val_id('test2', 'num1');
SELECT * FROM max_val_id('test2', 'num2'); --ТЕСТЫ ДЛЯ ПРОШЛОЙ ЛАБЫ НЕСКОЛЬКО СТОЛБЦОВ
SELECT * FROM spec_table;
INSERT INTO test2 VALUES (100, 3);
SELECT * FROM max_val_id('test2', 'num1');
SELECT * FROM max_val_id('test2', 'num2');
SELECT * FROM spec_table;
SELECT * FROM max_val_id('t', 'num1');  --ТЕСТЫ ОШИБОК ДЛЯ НЕСКОЛЬКИХ СТОЛБЦОВ
SELECT * FROM max_val_id('test2', 'num');
SELECT * FROM max_val_id('teeeeeeest', 'iiiiiiiiid');
CREATE TABLE test3(id INT, txt TEXT);
SELECT * FROM max_val_id('test3', 'id');
SELECT * FROM max_val_id('test3','txt');
SELECT trigger_name FROM information_schema.triggers;
DROP TABLE test2;
DROP TABLE test3;

CREATE TABLE "my-table" ("a b c d" INT); --ТЕСТ НА QUOTE_IDENT
SELECT * FROM max_val_id('my-table', 'a b 11c d');

SELECT * FROM spec_table;
SELECT trigger_name FROM information_schema.triggers;
DROP TABLE "my-table";

CREATE FUNCTION aboba123() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN END; $$; --ТЕСТЫ НА УНИКАЛЬНЫЕ НАЗВАНИЯ ТРИГГЕРОВ
CREATE TABLE test4(id INT, idd INT);
CREATE TRIGGER test4_id_2 AFTER DELETE ON test4 EXECUTE FUNCTION aboba123();
SELECT * FROM max_val_id('test4', 'id');
SELECT * FROM max_val_id('test4', 'idd');
SELECT * FROM spec_table;

SELECT trigger_name FROM information_schema.triggers;

DROP TABLE test4;
DROP FUNCTION aboba123;
DROP TABLE spec_table;
