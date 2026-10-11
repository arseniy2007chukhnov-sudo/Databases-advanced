-- ТРАНЗАКЦИЯ 1. Структура: таблицы + счетчики (sequence). Без связей.

BEGIN;
 
DO $$
BEGIN
    -- Очистка для повторного запуска (сначала таблицы, потом счетчики)
    DROP TABLE IF EXISTS parametry CASCADE;
    DROP TABLE IF EXISTS pachki CASCADE;
    DROP TABLE IF EXISTS polzovateli CASCADE;
    DROP TABLE IF EXISTS tipy_parametrov CASCADE;
    DROP TABLE IF EXISTS edinicy_izmereniya CASCADE;
    DROP TABLE IF EXISTS bazovye_edinicy_izmereniya CASCADE;
    DROP TABLE IF EXISTS tipy_oborudovaniya CASCADE;
    DROP TABLE IF EXISTS dolzhnosti CASCADE;
    DROP TABLE IF EXISTS popravki_virtualnoj_temperatury CASCADE;
 
    DROP SEQUENCE IF EXISTS seq_parametry;
    DROP SEQUENCE IF EXISTS seq_pachki;
    DROP SEQUENCE IF EXISTS seq_polzovateli;
    DROP SEQUENCE IF EXISTS seq_tipy_parametrov;
    DROP SEQUENCE IF EXISTS seq_edinicy_izmereniya;
    DROP SEQUENCE IF EXISTS seq_bazovye_edinicy_izmereniya;
    DROP SEQUENCE IF EXISTS seq_tipy_oborudovaniya;
    DROP SEQUENCE IF EXISTS seq_dolzhnosti;
    DROP SEQUENCE IF EXISTS seq_popravki_virtualnoj_temperatury;
 
    -- Счетчики
    CREATE SEQUENCE seq_dolzhnosti START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE seq_tipy_oborudovaniya START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE seq_polzovateli START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE seq_bazovye_edinicy_izmereniya START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE seq_edinicy_izmereniya START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE seq_tipy_parametrov START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE seq_pachki START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE seq_parametry START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE seq_popravki_virtualnoj_temperatury START WITH 1 INCREMENT BY 1;
 
    -- Таблицы (у каждой есть id и уникальный код uniq_code)
    CREATE TABLE dolzhnosti (
        id INTEGER NOT NULL DEFAULT nextval('seq_dolzhnosti'),
        uniq_code VARCHAR(20) NOT NULL,
        name VARCHAR(100) NOT NULL
    );
 
    CREATE TABLE tipy_oborudovaniya (
        id INTEGER NOT NULL DEFAULT nextval('seq_tipy_oborudovaniya'),
        uniq_code VARCHAR(20) NOT NULL,
        short_name VARCHAR(20) NOT NULL,
        name VARCHAR(100) NOT NULL
    );
 
    CREATE TABLE polzovateli (
        id INTEGER NOT NULL DEFAULT nextval('seq_polzovateli'),
        uniq_code VARCHAR(20) NOT NULL,
        full_name VARCHAR(150) NOT NULL,
        dolzhnost_id INTEGER NOT NULL
    );
 
    CREATE TABLE bazovye_edinicy_izmereniya (
        id INTEGER NOT NULL DEFAULT nextval('seq_bazovye_edinicy_izmereniya'),
        uniq_code VARCHAR(20) NOT NULL,
        name VARCHAR(100) NOT NULL
    );
 
    CREATE TABLE edinicy_izmereniya (
        id INTEGER NOT NULL DEFAULT nextval('seq_edinicy_izmereniya'),
        uniq_code VARCHAR(20) NOT NULL,
        bazovaya_edinica_id INTEGER  NOT NULL,
        short_name VARCHAR(20) NOT NULL,
        name VARCHAR(100) NOT NULL
    );
 
    CREATE TABLE tipy_parametrov (
        id INTEGER NOT NULL DEFAULT nextval('seq_tipy_parametrov'),
        uniq_code VARCHAR(20) NOT NULL,
        edinica_izmereniya_id INTEGER NOT NULL,
        name VARCHAR(100) NOT NULL
    );
 
    CREATE TABLE pachki (
        id INTEGER NOT NULL DEFAULT nextval('seq_pachki'),
        uniq_code VARCHAR(20) NOT NULL,
        tip_oborudovaniya_id INTEGER NOT NULL,
        polzovatel_id INTEGER NOT NULL,
        measured_at TIMESTAMP NOT NULL DEFAULT now()
    );
 
    CREATE TABLE parametry (
        id INTEGER NOT NULL DEFAULT nextval('seq_parametry'),
        uniq_code VARCHAR(20) NOT NULL,
        pachka_id INTEGER NOT NULL,
        tip_parametra_id INTEGER NOT NULL,
        value NUMERIC(10,2) NOT NULL
    );
 
    -- Новая таблица: "Расчет температуры"
    CREATE TABLE popravki_virtualnoj_temperatury (
        id INTEGER NOT NULL DEFAULT nextval('seq_popravki_virtualnoj_temperatury'),
        uniq_code VARCHAR(20) NOT NULL,
        label VARCHAR(20) NOT NULL,   -- как в таблице ТЗ: 'Ниже 0', '0 - 5', ...
        t_from NUMERIC(5,1) NOT NULL,   -- нижняя граница t0, °C
        t_to NUMERIC(5,1) NOT NULL,   -- верхняя граница t0, °C
        delta_tv NUMERIC(3,1) NOT NULL    -- виртуальная поправка ΔTv
    );
END
$$;
 
COMMIT;
 

-- ТРАНЗАКЦИЯ 2. Тестовые данные

BEGIN;
 
DO $$
DECLARE
    i         INTEGER;
    v_pachka  INTEGER;
    v_equip   INTEGER;
BEGIN
    INSERT INTO dolzhnosti (uniq_code, name) VALUES
        ('DLZ-001', 'Рядовой'),
        ('DLZ-002', 'Лейтенант'),
        ('DLZ-003', 'Сержант');
 
    INSERT INTO tipy_oborudovaniya (uniq_code, short_name, name) VALUES
        ('TIP-001', 'ДМК', 'Десантный метео комплекс'),
        ('TIP-002', 'ВР',  'Ветровое ружье');
 
    INSERT INTO polzovateli (uniq_code, full_name, dolzhnost_id) VALUES
        ('USR-001', 'Воловиков Александр Сергеевич', 2),
        ('USR-002', 'Иванов Петр Иванович',          1),
        ('USR-003', 'Сидоров Алексей Викторович',    3);
 
    INSERT INTO bazovye_edinicy_izmereniya (uniq_code, name) VALUES
        ('BED-001', 'Длина'),
        ('BED-002', 'Температура'),
        ('BED-003', 'Давление'),
        ('BED-004', 'Угол'),
        ('BED-005', 'Скорость');
 
    INSERT INTO edinicy_izmereniya (uniq_code, bazovaya_edinica_id, short_name, name) VALUES
        ('EDI-001', 1, 'м',         'Метр'),
        ('EDI-002', 2, 'C',         'Градус Цельсия'),
        ('EDI-003', 3, 'мм рт.ст.', 'Миллиметр ртутного столба'),
        ('EDI-004', 4, 'д.у.',      'Деление угломера'),
        ('EDI-005', 5, 'м/с',       'Метр в секунду');
 
    INSERT INTO tipy_parametrov (uniq_code, edinica_izmereniya_id, name) VALUES
        ('TPR-001', 1, 'Высота метеопоста'),
        ('TPR-002', 2, 'Температура'),
        ('TPR-003', 3, 'Давление'),
        ('TPR-004', 4, 'Направление ветра'),
        ('TPR-005', 5, 'Скорость ветра'),
        ('TPR-006', 1, 'Дальность сноса пуль');
 
    -- Таблица 1. Между точками значение
    -- интерполируется при расчете (пример в ТЗ: t0 = 23 -> 1,8).
    INSERT INTO popravki_virtualnoj_temperatury (uniq_code, label, t_from, t_to, delta_tv) VALUES
        ('PVT-001', 'Ниже 0',  -58,  0, 0.0),
        ('PVT-002', '0 - 5',     0,  5, 0.5),
        ('PVT-003', '10 - 15',  10, 15, 1.0),
        ('PVT-004', '20',       20, 20, 1.5),
        ('PVT-005', '25',       25, 25, 2.0),
        ('PVT-006', '30',       30, 30, 3.5),
        ('PVT-007', '40',       40, 40, 4.5);
 
    -- 6 пачек: 3 на ДМК и 3 на ВР, пользователи по кругу.
    -- Параметры: 1-4 есть всегда, 5 (скорость ветра) только у ДМК, 6 (дальность сноса) только у ВР.
    FOR i IN 1..6 LOOP
        IF i <= 3 THEN v_equip := 1; ELSE v_equip := 2; END IF;
 
        INSERT INTO pachki (uniq_code, tip_oborudovaniya_id, polzovatel_id, measured_at)
        VALUES ('PCH-' || to_char(i, 'FM000'), v_equip, ((i - 1) % 3) + 1,
                TIMESTAMP '2026-09-01 08:00:00' + (i - 1) * INTERVAL '1 day')
        RETURNING id INTO v_pachka;
 
        INSERT INTO parametry (uniq_code, pachka_id, tip_parametra_id, value) VALUES
            ('PAR-' || to_char(v_pachka, 'FM000') || '-1', v_pachka, 1, 100),
            ('PAR-' || to_char(v_pachka, 'FM000') || '-2', v_pachka, 2, 10 + i),
            ('PAR-' || to_char(v_pachka, 'FM000') || '-3', v_pachka, 3, 740 + i),
            ('PAR-' || to_char(v_pachka, 'FM000') || '-4', v_pachka, 4, (i * 7) % 60);
 
        IF v_equip = 1 THEN
            INSERT INTO parametry (uniq_code, pachka_id, tip_parametra_id, value)
            VALUES ('PAR-' || to_char(v_pachka, 'FM000') || '-5', v_pachka, 5, i);
        ELSE
            INSERT INTO parametry (uniq_code, pachka_id, tip_parametra_id, value)
            VALUES ('PAR-' || to_char(v_pachka, 'FM000') || '-6', v_pachka, 6, i * 10);
        END IF;
    END LOOP;
END
$$;
 
COMMIT;
 

-- ТРАНЗАКЦИЯ 3. Связи и ограничения

BEGIN;
 
DO $$
BEGIN
    -- Первичные ключи
    ALTER TABLE dolzhnosti                      ADD CONSTRAINT pk_dolzhnosti                      PRIMARY KEY (id);
    ALTER TABLE tipy_oborudovaniya              ADD CONSTRAINT pk_tipy_oborudovaniya              PRIMARY KEY (id);
    ALTER TABLE polzovateli                     ADD CONSTRAINT pk_polzovateli                     PRIMARY KEY (id);
    ALTER TABLE bazovye_edinicy_izmereniya      ADD CONSTRAINT pk_bazovye_edinicy_izmereniya      PRIMARY KEY (id);
    ALTER TABLE edinicy_izmereniya              ADD CONSTRAINT pk_edinicy_izmereniya              PRIMARY KEY (id);
    ALTER TABLE tipy_parametrov                 ADD CONSTRAINT pk_tipy_parametrov                 PRIMARY KEY (id);
    ALTER TABLE pachki                          ADD CONSTRAINT pk_pachki                          PRIMARY KEY (id);
    ALTER TABLE parametry                       ADD CONSTRAINT pk_parametry                       PRIMARY KEY (id);
    ALTER TABLE popravki_virtualnoj_temperatury ADD CONSTRAINT pk_popravki_virtualnoj_temperatury PRIMARY KEY (id);
 
    -- Уникальные коды
    ALTER TABLE dolzhnosti                      ADD CONSTRAINT uq_dolzhnosti_code                      UNIQUE (uniq_code);
    ALTER TABLE tipy_oborudovaniya              ADD CONSTRAINT uq_tipy_oborudovaniya_code              UNIQUE (uniq_code);
    ALTER TABLE polzovateli                     ADD CONSTRAINT uq_polzovateli_code                     UNIQUE (uniq_code);
    ALTER TABLE bazovye_edinicy_izmereniya      ADD CONSTRAINT uq_bazovye_edinicy_izmereniya_code      UNIQUE (uniq_code);
    ALTER TABLE edinicy_izmereniya              ADD CONSTRAINT uq_edinicy_izmereniya_code              UNIQUE (uniq_code);
    ALTER TABLE tipy_parametrov                 ADD CONSTRAINT uq_tipy_parametrov_code                 UNIQUE (uniq_code);
    ALTER TABLE pachki                          ADD CONSTRAINT uq_pachki_code                          UNIQUE (uniq_code);
    ALTER TABLE parametry                       ADD CONSTRAINT uq_parametry_code                       UNIQUE (uniq_code);
    ALTER TABLE popravki_virtualnoj_temperatury ADD CONSTRAINT uq_popravki_virtualnoj_temperatury_code UNIQUE (uniq_code);
 
    -- Внешние ключи
    ALTER TABLE polzovateli ADD CONSTRAINT fk_polzovateli_dolzhnost
        FOREIGN KEY (dolzhnost_id) REFERENCES dolzhnosti (id);
    ALTER TABLE edinicy_izmereniya ADD CONSTRAINT fk_edinicy_izmereniya_bazovaya
        FOREIGN KEY (bazovaya_edinica_id) REFERENCES bazovye_edinicy_izmereniya (id);
    ALTER TABLE tipy_parametrov ADD CONSTRAINT fk_tipy_parametrov_edinica
        FOREIGN KEY (edinica_izmereniya_id) REFERENCES edinicy_izmereniya (id);
    ALTER TABLE pachki ADD CONSTRAINT fk_pachki_tip_oborudovaniya
        FOREIGN KEY (tip_oborudovaniya_id) REFERENCES tipy_oborudovaniya (id);
    ALTER TABLE pachki ADD CONSTRAINT fk_pachki_polzovatel
        FOREIGN KEY (polzovatel_id) REFERENCES polzovateli (id);
    ALTER TABLE parametry ADD CONSTRAINT fk_parametry_pachka
        FOREIGN KEY (pachka_id) REFERENCES pachki (id);
    ALTER TABLE parametry ADD CONSTRAINT fk_parametry_tip_parametra
        FOREIGN KEY (tip_parametra_id) REFERENCES tipy_parametrov (id);
 
    -- Ограничения
    ALTER TABLE parametry ADD CONSTRAINT uq_parametry_pachka_tip
        UNIQUE (pachka_id, tip_parametra_id);          -- один параметр одного типа на пачку
    ALTER TABLE popravki_virtualnoj_temperatury ADD CONSTRAINT ck_popravki_diapazon
        CHECK (t_from <= t_to);
    ALTER TABLE popravki_virtualnoj_temperatury ADD CONSTRAINT ck_popravki_delta
        CHECK (delta_tv >= 0);
 
    -- Привязываем счетчики к колонкам (удаляются вместе с таблицей)
    ALTER SEQUENCE seq_dolzhnosti                      OWNED BY dolzhnosti.id;
    ALTER SEQUENCE seq_tipy_oborudovaniya              OWNED BY tipy_oborudovaniya.id;
    ALTER SEQUENCE seq_polzovateli                     OWNED BY polzovateli.id;
    ALTER SEQUENCE seq_bazovye_edinicy_izmereniya      OWNED BY bazovye_edinicy_izmereniya.id;
    ALTER SEQUENCE seq_edinicy_izmereniya              OWNED BY edinicy_izmereniya.id;
    ALTER SEQUENCE seq_tipy_parametrov                 OWNED BY tipy_parametrov.id;
    ALTER SEQUENCE seq_pachki                          OWNED BY pachki.id;
    ALTER SEQUENCE seq_parametry                       OWNED BY parametry.id;
    ALTER SEQUENCE seq_popravki_virtualnoj_temperatury OWNED BY popravki_virtualnoj_temperatury.id;
END
$$;
 
COMMIT;
 

-- Проверочный запрос (дата | пачка | ФИО | параметр (ед.) | значение)

SELECT
    p.measured_at AS "Дата измерения",
    p.uniq_code AS "Номер пачки",
    u.full_name AS "ФИО сотрудника",
    tp.name || ' (' || ei.short_name || ')' AS "Параметр и ед. измерения",
    par.value AS "Значение"
FROM pachki p
    INNER JOIN polzovateli u ON u.id  = p.polzovatel_id
    INNER JOIN parametry par ON par.pachka_id = p.id
    INNER JOIN tipy_parametrov tp ON tp.id = par.tip_parametra_id
    INNER JOIN edinicy_izmereniya ei ON ei.id = tp.edinica_izmereniya_id
ORDER BY p.measured_at, p.id, tp.id;