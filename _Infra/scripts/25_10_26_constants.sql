-- КОНСТАНТЫ 
 
-- Очистка для повторного запуска
DROP TABLE IF EXISTS parametry_oborudovaniya CASCADE;
DROP TABLE IF EXISTS ogranicheniya_parametrov CASCADE;
DROP TABLE IF EXISTS konstanty CASCADE;
DROP TABLE IF EXISTS tipy_oshibok CASCADE;   -- CASCADE снимет FK из parametry, если он уже создан
 
DROP SEQUENCE IF EXISTS seq_parametry_oborudovaniya;
DROP SEQUENCE IF EXISTS seq_ogranicheniya_parametrov;
DROP SEQUENCE IF EXISTS seq_konstanty;
DROP SEQUENCE IF EXISTS seq_tipy_oshibok;
 
CREATE SEQUENCE seq_tipy_oshibok START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_konstanty START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_ogranicheniya_parametrov START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_parametry_oborudovaniya START WITH 1 INCREMENT BY 1;
 

-- 1. Общие константы расчета 
CREATE TABLE konstanty (
    id          INTEGER       NOT NULL DEFAULT nextval('seq_konstanty'),
    uniq_code   VARCHAR(20)   NOT NULL,
    code        VARCHAR(50)   NOT NULL,   -- символьный код, по нему читает f_get_constant
    name        VARCHAR(200)  NOT NULL,
    value       NUMERIC(10,2) NOT NULL,
    CONSTRAINT pk_konstanty      PRIMARY KEY (id),
    CONSTRAINT uq_konstanty_code UNIQUE (uniq_code),
    CONSTRAINT uq_konstanty_symcode UNIQUE (code)
);
 
COMMENT ON TABLE  konstanty           IS 'Константы расчета Метео приближенный';
COMMENT ON COLUMN konstanty.id        IS 'Уникальный идентификатор';
COMMENT ON COLUMN konstanty.uniq_code IS 'Уникальный код записи';
COMMENT ON COLUMN konstanty.code      IS 'Символьный код константы';
COMMENT ON COLUMN konstanty.name      IS 'Описание константы';
COMMENT ON COLUMN konstanty.value     IS 'Значение константы';
 
INSERT INTO konstanty (uniq_code, code, name, value) VALUES
    ('KNS-001', 'TABLE_PRESSURE',        'Табличное давление, мм рт.ст.',                          750),
    ('KNS-002', 'TABLE_TEMPERATURE',     'Табличная виртуальная температура, °C',                  15.9),
    ('KNS-003', 'NEG_PRESSURE_OFFSET',   'БББ: для отрицательного отклонения впереди ставится 5 (500 - откл.)', 500),
    ('KNS-004', 'NEG_TEMPERATURE_OFFSET','ТТ: для отрицательного отклонения добавляется 50', 50),
    ('KNS-005', 'MINUTES_STEP',          'ЧЧМ: минуты выводятся десятками',                         10);
 

-- 2. Допустимые значения входных параметров 

CREATE TABLE ogranicheniya_parametrov (
    id               INTEGER       NOT NULL DEFAULT nextval('seq_ogranicheniya_parametrov'),
    uniq_code        VARCHAR(20)   NOT NULL,
    tip_parametra_id INTEGER       NOT NULL,
    min_value        NUMERIC(10,2),
    max_value        NUMERIC(10,2),
    scale_digits     SMALLINT      NOT NULL DEFAULT 0,
    CONSTRAINT pk_ogranicheniya_parametrov      PRIMARY KEY (id),
    CONSTRAINT uq_ogranicheniya_parametrov_code UNIQUE (uniq_code),
    CONSTRAINT uq_ogranicheniya_parametrov_tip  UNIQUE (tip_parametra_id),
    CONSTRAINT fk_ogranicheniya_parametrov_tip  FOREIGN KEY (tip_parametra_id) REFERENCES tipy_parametrov (id),
    CONSTRAINT ck_ogranicheniya_diapazon        CHECK (min_value IS NULL OR max_value IS NULL OR min_value <= max_value),
    CONSTRAINT ck_ogranicheniya_scale           CHECK (scale_digits >= 0)
);
 
COMMENT ON TABLE  ogranicheniya_parametrov                  IS 'Допустимые диапазоны входных параметров';
COMMENT ON COLUMN ogranicheniya_parametrov.id               IS 'Уникальный идентификатор';
COMMENT ON COLUMN ogranicheniya_parametrov.uniq_code        IS 'Уникальный код записи';
COMMENT ON COLUMN ogranicheniya_parametrov.tip_parametra_id IS 'Ссылка на тип параметра';
COMMENT ON COLUMN ogranicheniya_parametrov.min_value        IS 'Минимальное значение (NULL - без ограничения)';
COMMENT ON COLUMN ogranicheniya_parametrov.max_value        IS 'Максимальное значение (NULL - без ограничения)';
COMMENT ON COLUMN ogranicheniya_parametrov.scale_digits     IS 'Допустимое число знаков после запятой (0 - целое)';
 
-- id типов параметров: 1 высота, 2 температура, 3 давление,
-- 4 направление ветра, 5 скорость ветра, 6 дальность сноса пуль
INSERT INTO ogranicheniya_parametrov (uniq_code, tip_parametra_id, min_value, max_value, scale_digits) VALUES
    ('OGR-001', 1, NULL, NULL, 0),
    ('OGR-002', 2, -58,  58,   1),
    ('OGR-003', 3, 500,  900,  0),
    ('OGR-004', 4, 0,    59,   0),
    ('OGR-005', 5, 0,    15,   0),
    ('OGR-006', 6, 0,    150,  0);
 

-- 3. Какие параметры нужны для какого оборудования 
CREATE TABLE parametry_oborudovaniya (
    id                   INTEGER     NOT NULL DEFAULT nextval('seq_parametry_oborudovaniya'),
    uniq_code            VARCHAR(20) NOT NULL,
    tip_oborudovaniya_id INTEGER     NOT NULL,
    tip_parametra_id     INTEGER     NOT NULL,
    is_required          BOOLEAN     NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_parametry_oborudovaniya      PRIMARY KEY (id),
    CONSTRAINT uq_parametry_oborudovaniya_code UNIQUE (uniq_code),
    CONSTRAINT uq_parametry_oborudovaniya_pair UNIQUE (tip_oborudovaniya_id, tip_parametra_id),
    CONSTRAINT fk_parametry_oborudovaniya_obor FOREIGN KEY (tip_oborudovaniya_id) REFERENCES tipy_oborudovaniya (id),
    CONSTRAINT fk_parametry_oborudovaniya_par  FOREIGN KEY (tip_parametra_id)     REFERENCES tipy_parametrov (id)
);
 
COMMENT ON TABLE  parametry_oborudovaniya                      IS 'Набор входных параметров для типа оборудования';
COMMENT ON COLUMN parametry_oborudovaniya.id                   IS 'Уникальный идентификатор';
COMMENT ON COLUMN parametry_oborudovaniya.uniq_code            IS 'Уникальный код записи';
COMMENT ON COLUMN parametry_oborudovaniya.tip_oborudovaniya_id IS 'Ссылка на тип оборудования';
COMMENT ON COLUMN parametry_oborudovaniya.tip_parametra_id     IS 'Ссылка на тип параметра';
COMMENT ON COLUMN parametry_oborudovaniya.is_required          IS 'Параметр обязателен';
 
INSERT INTO parametry_oborudovaniya (uniq_code, tip_oborudovaniya_id, tip_parametra_id)
SELECT 'POB-' || to_char(row_number() OVER (ORDER BY t.id, v.tip), 'FM000'),
       t.id,
       v.tip
  FROM tipy_oborudovaniya t
       INNER JOIN (VALUES ('ДМК', 1), ('ДМК', 2), ('ДМК', 3), ('ДМК', 4), ('ДМК', 5),
                          ('ВР',  1), ('ВР',  2), ('ВР',  3), ('ВР',  4), ('ВР',  6))
                  AS v (short_name, tip)
               ON v.short_name = t.short_name;
 

-- 4. Классификатор видов ошибок входных параметров

CREATE TABLE tipy_oshibok (
    id        INTEGER      NOT NULL DEFAULT nextval('seq_tipy_oshibok'),
    uniq_code VARCHAR(20)  NOT NULL,
    code      VARCHAR(30)  NOT NULL,
    name      VARCHAR(200) NOT NULL,
    CONSTRAINT pk_tipy_oshibok          PRIMARY KEY (id),
    CONSTRAINT uq_tipy_oshibok_code     UNIQUE (uniq_code),
    CONSTRAINT uq_tipy_oshibok_symcode  UNIQUE (code)
);
 
COMMENT ON TABLE  tipy_oshibok           IS 'Классификатор видов ошибок входных параметров';
COMMENT ON COLUMN tipy_oshibok.id        IS 'Уникальный идентификатор';
COMMENT ON COLUMN tipy_oshibok.uniq_code IS 'Уникальный код записи';
COMMENT ON COLUMN tipy_oshibok.code      IS 'Символьный код вида ошибки';
COMMENT ON COLUMN tipy_oshibok.name      IS 'Наименование вида ошибки';
 
INSERT INTO tipy_oshibok (uniq_code, code, name) VALUES
    ('ERR-001', 'OUT_OF_RANGE',      'Значение вне допустимого диапазона'),
    ('ERR-002', 'NOT_INTEGER',       'Значение должно быть целым числом'),
    ('ERR-003', 'TOO_MANY_DECIMALS', 'Превышено число знаков после запятой'),
    ('ERR-004', 'MISSING_REQUIRED',  'Не задан обязательный параметр'),
    ('ERR-005', 'NOT_APPLICABLE',    'Параметр не применим для данного оборудования'),
    ('ERR-006', 'NO_EQUIPMENT',      'Не указан тип оборудования'),
    ('ERR-007', 'UNKNOWN_PARAMETER', 'Неизвестный тип параметра');
 

-- 5. Функции чтения констант и классификатора

CREATE OR REPLACE FUNCTION f_get_constant(p_code VARCHAR)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_value NUMERIC;
BEGIN
    SELECT k.value INTO v_value FROM konstanty k WHERE k.code = p_code;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Константа "%" не найдена в таблице konstanty', p_code;
    END IF;
    RETURN v_value;
END;
$$;
 
COMMENT ON FUNCTION f_get_constant(VARCHAR) IS 'Значение константы из konstanty по символьному коду';