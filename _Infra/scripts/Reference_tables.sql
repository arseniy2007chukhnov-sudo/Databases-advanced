DO
$$
BEGIN
 
    -- ТРАНЗАКЦИЯ 1. Очистка и счетчики
 
    BEGIN
        DROP TABLE IF EXISTS tablicy_popravok CASCADE;
        DROP TABLE IF EXISTS tipy_tablic_popravok CASCADE;
        DROP TABLE IF EXISTS standartnye_vysoty CASCADE;
 
        DROP SEQUENCE IF EXISTS seq_tablicy_popravok;
        DROP SEQUENCE IF EXISTS seq_tipy_tablic_popravok;
        DROP SEQUENCE IF EXISTS seq_standartnye_vysoty;
 
        CREATE SEQUENCE seq_standartnye_vysoty START WITH 1 INCREMENT BY 1;
        CREATE SEQUENCE seq_tipy_tablic_popravok START WITH 1 INCREMENT BY 1;
        CREATE SEQUENCE seq_tablicy_popravok START WITH 1 INCREMENT BY 1;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Транзакция 1 отменена: %', SQLERRM;
            RAISE;
    END;
 
 
    -- ТРАНЗАКЦИЯ 2. Структуры
 
    BEGIN
        -- 1. Стандартные высоты бюллетеня Y (строки таблиц 2 и 3)
        CREATE TABLE standartnye_vysoty (
            id        INTEGER     NOT NULL DEFAULT nextval('seq_standartnye_vysoty'),
            uniq_code VARCHAR(20) NOT NULL,
            height_m  INTEGER     NOT NULL,
            CONSTRAINT pk_standartnye_vysoty      PRIMARY KEY (id),
            CONSTRAINT uq_standartnye_vysoty_code UNIQUE (uniq_code),
            CONSTRAINT uq_standartnye_vysoty_h    UNIQUE (height_m),
            CONSTRAINT ck_standartnye_vysoty_h    CHECK (height_m > 0)
        );
 
        COMMENT ON TABLE  standartnye_vysoty           IS 'Стандартные высоты бюллетеня Y, м (строки таблиц 2 и 3)';
        COMMENT ON COLUMN standartnye_vysoty.id        IS 'Уникальный идентификатор';
        COMMENT ON COLUMN standartnye_vysoty.uniq_code IS 'Уникальный код записи';
        COMMENT ON COLUMN standartnye_vysoty.height_m  IS 'Высота Y, м';
 
 
        -- 2. Справочник типов таблиц поправок (со своими заголовками)
        --    Иерархия: родитель - общая таблица (Таблица 2 / Таблица 3, скорость / направление),
        --    потомок - вариант для оборудования или знака отклонения.
        CREATE TABLE tipy_tablic_popravok (
            id                   INTEGER      NOT NULL DEFAULT nextval('seq_tipy_tablic_popravok'),
            uniq_code            VARCHAR(20)  NOT NULL,
            code                 VARCHAR(30)  NOT NULL,
            parent_id            INTEGER,
            tip_oborudovaniya_id INTEGER,
            name                 VARCHAR(200) NOT NULL,
            header_values        INTEGER[],
            CONSTRAINT pk_tipy_tablic_popravok      PRIMARY KEY (id),
            CONSTRAINT uq_tipy_tablic_popravok_code UNIQUE (uniq_code),
            CONSTRAINT uq_tipy_tablic_popravok_sym  UNIQUE (code),
            CONSTRAINT fk_tipy_tablic_popravok_parent FOREIGN KEY (parent_id)
                REFERENCES tipy_tablic_popravok (id),
            CONSTRAINT fk_tipy_tablic_popravok_obor FOREIGN KEY (tip_oborudovaniya_id)
                REFERENCES tipy_oborudovaniya (id),
            CONSTRAINT ck_tipy_tablic_popravok_parent CHECK (parent_id IS NULL OR parent_id <> id),
            CONSTRAINT ck_tipy_tablic_popravok_header CHECK (header_values IS NULL OR cardinality(header_values) > 0)
        );
 
        COMMENT ON TABLE  tipy_tablic_popravok                      IS 'Справочник типов таблиц поправок (Таблица 2, Таблица 3) с заголовками столбцов';
        COMMENT ON COLUMN tipy_tablic_popravok.id                   IS 'Уникальный идентификатор';
        COMMENT ON COLUMN tipy_tablic_popravok.uniq_code            IS 'Уникальный код записи';
        COMMENT ON COLUMN tipy_tablic_popravok.code                 IS 'Символьный код типа таблицы, по нему ищут расчетные функции';
        COMMENT ON COLUMN tipy_tablic_popravok.parent_id            IS 'Ссылка на родительский тип (общая таблица)';
        COMMENT ON COLUMN tipy_tablic_popravok.tip_oborudovaniya_id IS 'Ссылка на тип оборудования (NULL - таблица общая для ДМК и ВР)';
        COMMENT ON COLUMN tipy_tablic_popravok.name                 IS 'Наименование таблицы';
        COMMENT ON COLUMN tipy_tablic_popravok.header_values        IS 'Значения заголовка столбцов (Δt, V0 или Дг); NULL - заголовка нет (берется у родителя, либо одно значение на всю строку)';
 
 
        -- 3. Строки таблиц поправок: одна строка таблицы = одна запись
        CREATE TABLE tablicy_popravok (
            id                     INTEGER     NOT NULL DEFAULT nextval('seq_tablicy_popravok'),
            uniq_code              VARCHAR(20) NOT NULL,
            tip_tablicy_id         INTEGER     NOT NULL,
            standartnaya_vysota_id INTEGER     NOT NULL,
            row_values             INTEGER[]   NOT NULL,
            CONSTRAINT pk_tablicy_popravok      PRIMARY KEY (id),
            CONSTRAINT uq_tablicy_popravok_code UNIQUE (uniq_code),
            CONSTRAINT uq_tablicy_popravok_key  UNIQUE (tip_tablicy_id, standartnaya_vysota_id),
            CONSTRAINT fk_tablicy_popravok_tip    FOREIGN KEY (tip_tablicy_id)
                REFERENCES tipy_tablic_popravok (id),
            CONSTRAINT fk_tablicy_popravok_vysota FOREIGN KEY (standartnaya_vysota_id)
                REFERENCES standartnye_vysoty (id),
            CONSTRAINT ck_tablicy_popravok_values CHECK (cardinality(row_values) > 0)
        );
 
        COMMENT ON TABLE  tablicy_popravok                        IS 'Универсальная таблица поправок: значения строк таблиц 2 и 3';
        COMMENT ON COLUMN tablicy_popravok.id                     IS 'Уникальный идентификатор';
        COMMENT ON COLUMN tablicy_popravok.uniq_code              IS 'Уникальный код записи';
        COMMENT ON COLUMN tablicy_popravok.tip_tablicy_id         IS 'Ссылка на тип таблицы';
        COMMENT ON COLUMN tablicy_popravok.standartnaya_vysota_id IS 'Ссылка на стандартную высоту (строка таблицы)';
        COMMENT ON COLUMN tablicy_popravok.row_values             IS 'Значения строки: row_values[i] - столбец header_values[i]; для направления ветра - одно значение (большие деления угломера: 1-00 = 1)';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Транзакция 2 отменена: %', SQLERRM;
            RAISE;
    END;
 
 
    -- ТРАНЗАКЦИЯ 3. Данные 
 
    BEGIN
        INSERT INTO standartnye_vysoty (uniq_code, height_m) VALUES
            ('VYS-001', 200),  ('VYS-002', 400),  ('VYS-003', 800),
            ('VYS-004', 1200), ('VYS-005', 1600), ('VYS-006', 2000),
            ('VYS-007', 2400), ('VYS-008', 3000), ('VYS-009', 4000);
 
        -- Общие (родительские) таблицы
        INSERT INTO tipy_tablic_popravok (uniq_code, code, name, header_values) VALUES
            ('TTP-001', 'TBL2',       'Таблица 2. Среднее отклонение температуры (ДМК, ВР)',
                ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]),
            ('TTP-002', 'TBL3_SPEED', 'Таблица 3. Скорость среднего ветра', NULL),
            ('TTP-003', 'TBL3_DIR',   'Таблица 3. Направление среднего ветра', NULL);
 
        -- Таблица 2: положительные значения (знаменатель) и отрицательные (числитель).
        -- Заголовок берется у родителя TBL2; у положительных значений нет столбцов 40 и 50.
        INSERT INTO tipy_tablic_popravok (uniq_code, code, parent_id, name)
        SELECT v.uniq_code, v.code, p.id, v.name
          FROM (VALUES
                ('TTP-004', 'TBL2_POS', 'Таблица 2. Положительные отклонения температуры'),
                ('TTP-005', 'TBL2_NEG', 'Таблица 2. Отрицательные отклонения температуры')
               ) AS v (uniq_code, code, name)
               INNER JOIN tipy_tablic_popravok p ON p.code = 'TBL2';
 
        -- Таблица 3: варианты для ВР и ДМК
        INSERT INTO tipy_tablic_popravok (uniq_code, code, parent_id, tip_oborudovaniya_id, name, header_values)
        SELECT v.uniq_code, v.code, p.id, t.id, v.name, v.header_values
          FROM (VALUES
                ('TTP-006', 'TBL3_SPEED_VR',  'TBL3_SPEED', 'ВР',  'Таблица 3. Скорость среднего ветра (ВР)',
                    ARRAY[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),
                ('TTP-007', 'TBL3_DIR_VR',    'TBL3_DIR',   'ВР',  'Таблица 3. Направление среднего ветра (ВР)',
                    NULL::INTEGER[]),
                ('TTP-008', 'TBL3_SPEED_DMK', 'TBL3_SPEED', 'ДМК', 'Таблица 3. Скорость среднего ветра (ДМК)',
                    ARRAY[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]),
                ('TTP-009', 'TBL3_DIR_DMK',   'TBL3_DIR',   'ДМК', 'Таблица 3. Направление среднего ветра (ДМК)',
                    NULL::INTEGER[])
               ) AS v (uniq_code, code, parent_code, equip, name, header_values)
               INNER JOIN tipy_tablic_popravok p ON p.code = v.parent_code
               INNER JOIN tipy_oborudovaniya   t ON t.short_name = v.equip;
 
        -- Строки таблиц: (код типа, высота, значения)
        INSERT INTO tablicy_popravok (uniq_code, tip_tablicy_id, standartnaya_vysota_id, row_values)
        SELECT 'TPP-' || to_char(t.id, 'FM000') || '-' || to_char(h.id, 'FM000'),
               t.id, h.id, v.vals
          FROM (VALUES
                -- Таблица 2, положительные (одинаковы для всех высот)
                ('TBL2_POS',  200, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),
                ('TBL2_POS',  400, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),
                ('TBL2_POS',  800, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),
                ('TBL2_POS', 1200, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),
                ('TBL2_POS', 1600, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),
                ('TBL2_POS', 2000, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),
                ('TBL2_POS', 2400, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),
                ('TBL2_POS', 3000, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),
                ('TBL2_POS', 4000, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]),
                -- Таблица 2, отрицательные
                ('TBL2_NEG',  200, ARRAY[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]),
                ('TBL2_NEG',  400, ARRAY[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -38, -48]),
                ('TBL2_NEG',  800, ARRAY[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]),
                ('TBL2_NEG', 1200, ARRAY[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]),
                ('TBL2_NEG', 1600, ARRAY[-1, -2, -3, -3, -4, -4, -5, -6, -7, -7, -17, -25, -34, -42]),
                ('TBL2_NEG', 2000, ARRAY[-1, -2, -3, -3, -4, -4, -5, -6, -6, -7, -16, -24, -32, -40]),
                ('TBL2_NEG', 2400, ARRAY[-1, -2, -2, -3, -4, -4, -5, -5, -6, -7, -15, -23, -31, -38]),
                ('TBL2_NEG', 3000, ARRAY[-1, -2, -2, -3, -4, -4, -4, -5, -5, -6, -15, -22, -30, -37]),
                ('TBL2_NEG', 4000, ARRAY[-1, -2, -2, -3, -4, -4, -4, -4, -5, -6, -14, -20, -27, -34]),
                -- Таблица 3, скорость среднего ветра (ВР), Дг = 40..150 м
                ('TBL3_SPEED_VR',  200, ARRAY[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]),
                ('TBL3_SPEED_VR',  400, ARRAY[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]),
                ('TBL3_SPEED_VR',  800, ARRAY[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16]),
                ('TBL3_SPEED_VR', 1200, ARRAY[4, 5, 7, 8, 8, 9, 11, 12, 13, 15, 15, 16]),
                ('TBL3_SPEED_VR', 1600, ARRAY[4, 6, 7, 8, 9, 10, 11, 13, 14, 15, 17, 17]),
                ('TBL3_SPEED_VR', 2000, ARRAY[4, 6, 7, 8, 9, 10, 11, 13, 14, 16, 17, 18]),
                ('TBL3_SPEED_VR', 2400, ARRAY[4, 6, 8, 9, 9, 10, 12, 14, 15, 16, 18, 19]),
                ('TBL3_SPEED_VR', 3000, ARRAY[5, 6, 8, 9, 10, 11, 12, 14, 15, 17, 18, 19]),
                ('TBL3_SPEED_VR', 4000, ARRAY[5, 6, 8, 9, 10, 11, 12, 14, 16, 18, 19, 20]),
                -- Таблица 3, направление среднего ветра (ВР): приращение в больших делениях
                ('TBL3_DIR_VR',  200, ARRAY[0]),
                ('TBL3_DIR_VR',  400, ARRAY[1]),
                ('TBL3_DIR_VR',  800, ARRAY[2]),
                ('TBL3_DIR_VR', 1200, ARRAY[2]),
                ('TBL3_DIR_VR', 1600, ARRAY[3]),
                ('TBL3_DIR_VR', 2000, ARRAY[3]),
                ('TBL3_DIR_VR', 2400, ARRAY[3]),
                ('TBL3_DIR_VR', 3000, ARRAY[4]),
                ('TBL3_DIR_VR', 4000, ARRAY[4]),
                -- Таблица 3, скорость среднего ветра (ДМК), V0 = 3..15 м/с
                ('TBL3_SPEED_DMK',  200, ARRAY[4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22]),
                ('TBL3_SPEED_DMK',  400, ARRAY[5, 7, 10, 11, 12, 14, 17, 18, 20, 22, 23, 25, 27]),
                ('TBL3_SPEED_DMK',  800, ARRAY[5, 8, 10, 11, 13, 15, 18, 19, 21, 23, 25, 27, 28]),
                ('TBL3_SPEED_DMK', 1200, ARRAY[5, 8, 11, 12, 13, 16, 19, 20, 22, 24, 26, 28, 30]),
                ('TBL3_SPEED_DMK', 1600, ARRAY[6, 8, 11, 13, 14, 17, 20, 21, 23, 25, 27, 29, 32]),
                ('TBL3_SPEED_DMK', 2000, ARRAY[6, 9, 11, 13, 14, 17, 20, 21, 24, 26, 28, 30, 32]),
                ('TBL3_SPEED_DMK', 2400, ARRAY[6, 9, 12, 14, 15, 18, 21, 22, 25, 27, 29, 32, 34]),
                ('TBL3_SPEED_DMK', 3000, ARRAY[6, 9, 12, 14, 15, 18, 21, 23, 25, 28, 30, 32, 36]),
                ('TBL3_SPEED_DMK', 4000, ARRAY[6, 10, 12, 14, 16, 19, 22, 24, 26, 29, 32, 34, 36]),
                -- Таблица 3, направление среднего ветра (ДМК)
                ('TBL3_DIR_DMK',  200, ARRAY[1]),
                ('TBL3_DIR_DMK',  400, ARRAY[2]),
                ('TBL3_DIR_DMK',  800, ARRAY[3]),
                ('TBL3_DIR_DMK', 1200, ARRAY[3]),
                ('TBL3_DIR_DMK', 1600, ARRAY[4]),
                ('TBL3_DIR_DMK', 2000, ARRAY[4]),
                ('TBL3_DIR_DMK', 2400, ARRAY[4]),
                ('TBL3_DIR_DMK', 3000, ARRAY[5]),
                ('TBL3_DIR_DMK', 4000, ARRAY[5])
               ) AS v (type_code, height_m, vals)
               INNER JOIN tipy_tablic_popravok t ON t.code     = v.type_code
               INNER JOIN standartnye_vysoty   h ON h.height_m = v.height_m;
 
        -- Пороги алгоритма (в существующую таблицу konstanty)
        INSERT INTO konstanty (uniq_code, code, name, value) VALUES
            ('KNS-006', 'MIN_SURFACE_WIND_DMK', 'ДМК: при V0 меньше этого значения (м/с) средний ветер = 0', 3),
            ('KNS-007', 'MIN_DRIFT_BP',          'ВР: при Дг меньше этого значения (м) средний ветер = 0',    40),
            ('KNS-008', 'MIN_STD_HEIGHT',        'Ниже этой высоты (м) берутся данные для нее',                200),
            ('KNS-009', 'MAX_STD_HEIGHT',        'Выше этой высоты (м) берутся данные для нее',                4000)
        ON CONFLICT DO NOTHING;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Транзакция 3 отменена: %', SQLERRM;
            RAISE;
    END;
 
 
    -- ТРАНЗАКЦИЯ 4. Проверка согласованности значений и заголовков
 
    BEGIN
        -- Заголовок берется у типа или у его родителя. Есть заголовок - значений
        -- не больше, чем столбцов; нет заголовка - одно значение на всю строку.
        IF EXISTS (
            SELECT 1
              FROM tablicy_popravok c
                   INNER JOIN tipy_tablic_popravok t ON t.id = c.tip_tablicy_id
                   LEFT JOIN  tipy_tablic_popravok p ON p.id = t.parent_id
             WHERE (COALESCE(t.header_values, p.header_values) IS NOT NULL
                    AND cardinality(c.row_values) > cardinality(COALESCE(t.header_values, p.header_values)))
                OR (COALESCE(t.header_values, p.header_values) IS NULL
                    AND cardinality(c.row_values) <> 1)
        ) THEN
            RAISE EXCEPTION 'Число значений в строке не соответствует заголовку таблицы';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Транзакция 4 отменена: %', SQLERRM;
            RAISE;
    END;
END
$$;
 
-- Проверочный запрос: Таблица 3 (ДМК) в развернутом виде.
-- Высота | V0, м/с | скорость среднего ветра | приращение направления
SELECT h.height_m  AS "Высота, м",
       hdr.v0      AS "V0, м/с",
       val.speed   AS "Скорость среднего ветра, м/с",
       dir.row_values[1] AS "Приращение направления"
  FROM tipy_tablic_popravok ts
       INNER JOIN tablicy_popravok c ON c.tip_tablicy_id = ts.id
       INNER JOIN standartnye_vysoty h ON h.id = c.standartnaya_vysota_id
       CROSS JOIN LATERAL unnest(ts.header_values) WITH ORDINALITY AS hdr (v0, n)
       INNER JOIN LATERAL unnest(c.row_values) WITH ORDINALITY AS val (speed, n) ON val.n = hdr.n
       INNER JOIN tipy_tablic_popravok td ON td.code = 'TBL3_DIR_DMK'
       INNER JOIN tablicy_popravok dir ON dir.tip_tablicy_id = td.id AND dir.standartnaya_vysota_id = h.id
 WHERE ts.code = 'TBL3_SPEED_DMK'
 ORDER BY h.height_m, hdr.v0;
 