-- ФУНКЦИИ
 

-- 1. DDL: информация об ошибках во входных параметрах

ALTER TABLE parametry ADD COLUMN IF NOT EXISTS has_error      BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE parametry ADD COLUMN IF NOT EXISTS tip_oshibki_id INTEGER;
ALTER TABLE parametry DROP COLUMN IF EXISTS error_text;   
 
ALTER TABLE parametry DROP CONSTRAINT IF EXISTS fk_parametry_tip_oshibki;
ALTER TABLE parametry ADD CONSTRAINT fk_parametry_tip_oshibki
    FOREIGN KEY (tip_oshibki_id) REFERENCES tipy_oshibok (id);
 
COMMENT ON COLUMN parametry.has_error      IS 'Признак: значение параметра содержит ошибку';
COMMENT ON COLUMN parametry.tip_oshibki_id IS 'Ссылка на вид ошибки (классификатор tipy_oshibok)';
 

-- 2. Новый тип данных: список параметров одной пачки

DROP TYPE IF EXISTS t_meteo_params CASCADE;
 
CREATE TYPE t_meteo_params AS (
    tip_oborudovaniya_id INTEGER,   -- 1 ДМК, 2 ВР
    height               NUMERIC,   -- высота метеопоста
    temperature          NUMERIC,   -- температура
    pressure             NUMERIC,   -- давление
    wind_direction       NUMERIC,   -- направление ветра
    wind_speed           NUMERIC,   -- скорость ветра (только ДМК)
    bullet_drift         NUMERIC    -- дальность сноса пуль (только ВР)
);
 
COMMENT ON TYPE t_meteo_params IS 'Список входных параметров пачки измерений';
 

-- 3. Вспомогательная: число без хвостовых нулей (34.00 -> 34, 0.20 -> 0.2)

CREATE OR REPLACE FUNCTION f_fmt_num(p_value NUMERIC)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE WHEN position('.' IN p_value::text) > 0
                THEN regexp_replace(p_value::text, '\.?0+$', '')
                ELSE p_value::text
           END;
$$;
 

-- 4. Проверка одного значения по таблице ограничений.

DROP FUNCTION IF EXISTS f_check_param(INTEGER, NUMERIC);
 
CREATE OR REPLACE FUNCTION f_check_param(
    p_tip_parametra_id INTEGER,
    p_value            NUMERIC,
    OUT error_code     TEXT,
    OUT message        TEXT)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_name  TEXT;
    v_min   NUMERIC;
    v_max   NUMERIC;
    v_scale SMALLINT;
BEGIN
    error_code := NULL;
    message    := NULL;
 
    IF p_value IS NULL THEN
        RETURN;
    END IF;
 
    SELECT tp.name, o.min_value, o.max_value, o.scale_digits
      INTO v_name, v_min, v_max, v_scale
      FROM tipy_parametrov tp
           LEFT JOIN ogranicheniya_parametrov o ON o.tip_parametra_id = tp.id
     WHERE tp.id = p_tip_parametra_id;
 
    IF NOT FOUND THEN
        error_code := 'UNKNOWN_PARAMETER';
        message    := 'Неизвестный тип параметра ' || coalesce(p_tip_parametra_id::text, 'NULL');
        RETURN;
    END IF;
 
    -- разрядность
    IF v_scale IS NOT NULL AND p_value <> round(p_value, v_scale) THEN
        IF v_scale = 0 THEN
            error_code := 'NOT_INTEGER';
            message    := v_name || ': значение ' || f_fmt_num(p_value) || ' должно быть целым числом';
        ELSE
            error_code := 'TOO_MANY_DECIMALS';
            message    := v_name || ': значение ' || f_fmt_num(p_value)
                          || ' допускает не более ' || v_scale || ' знака после запятой';
        END IF;
        RETURN;
    END IF;
 
    -- диапазон
    IF (v_min IS NOT NULL AND p_value < v_min) OR (v_max IS NOT NULL AND p_value > v_max) THEN
        error_code := 'OUT_OF_RANGE';
        message    := v_name || ': значение ' || f_fmt_num(p_value) || ' вне диапазона '
                      || coalesce(f_fmt_num(v_min), '-∞') || '..' || coalesce(f_fmt_num(v_max), '+∞');
    END IF;
END;
$$;
 

-- 5. Ошибки пачки построчно: (тип параметра, вид ошибки, текст).
--    Основа для f_validate_params и для подсчета ошибок в запросах.

CREATE OR REPLACE FUNCTION f_param_errors(p t_meteo_params)
RETURNS TABLE (tip_parametra_id INTEGER, tip_oshibki_id INTEGER, error_code TEXT, message TEXT)
LANGUAGE sql
STABLE
AS $$
    WITH v (tip, val) AS (
        VALUES (1, p.height),
               (2, p.temperature),
               (3, p.pressure),
               (4, p.wind_direction),
               (5, p.wind_speed),
               (6, p.bullet_drift)
    ),
    checked AS (
        SELECT v.tip,
               CASE
                   WHEN po.id IS NULL AND v.val IS NOT NULL THEN 'NOT_APPLICABLE'
                   WHEN po.is_required AND v.val IS NULL    THEN 'MISSING_REQUIRED'
                   ELSE cp.error_code
               END AS err_code,
               CASE
                   WHEN po.id IS NULL AND v.val IS NOT NULL
                       THEN 'Параметр «' || tp.name || '» не применим для данного оборудования'
                   WHEN po.is_required AND v.val IS NULL
                       THEN 'Не задан параметр «' || tp.name || '»'
                   ELSE cp.message
               END AS msg
          FROM v
               INNER JOIN tipy_parametrov tp ON tp.id = v.tip
               LEFT JOIN parametry_oborudovaniya po
                      ON po.tip_oborudovaniya_id = p.tip_oborudovaniya_id
                     AND po.tip_parametra_id     = v.tip
               CROSS JOIN LATERAL f_check_param(v.tip, v.val) cp
    )
    SELECT NULL::INTEGER, ot.id, ot.code::TEXT, ot.name::TEXT
      FROM tipy_oshibok ot
     WHERE ot.code = 'NO_EQUIPMENT'
       AND p.tip_oborudovaniya_id IS NULL
    UNION ALL
    SELECT c.tip, ot.id, ot.code::TEXT, c.msg
      FROM checked c
           INNER JOIN tipy_oshibok ot ON ot.code = c.err_code
     WHERE p.tip_oborudovaniya_id IS NOT NULL
    ORDER BY 1;
$$;
 

-- 6. Основная функция по заданию: тип со списком параметров -> строка ошибок
--    Пустая строка = ошибок нет.

CREATE OR REPLACE FUNCTION f_validate_params(p t_meteo_params)
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
    SELECT coalesce(string_agg(e.message, '; ' ORDER BY e.tip_parametra_id), '')
      FROM f_param_errors(p) e;
$$;
 
COMMENT ON FUNCTION f_validate_params(t_meteo_params) IS 'Проверка параметров пачки: возвращает список ошибок через "; "';
 

-- 7. Заполнение parametry.has_error / tip_oshibki_id по каждой записи.

CREATE OR REPLACE FUNCTION f_refresh_param_errors()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_cnt INTEGER;
BEGIN
    UPDATE parametry par
       SET has_error      = (e.error_type_id IS NOT NULL),
           tip_oshibki_id = e.error_type_id
      FROM (SELECT pr.id,
                   ot.id AS error_type_id
              FROM parametry pr
                   INNER JOIN pachki pa ON pa.id = pr.pachka_id
                   LEFT JOIN parametry_oborudovaniya po
                          ON po.tip_oborudovaniya_id = pa.tip_oborudovaniya_id
                         AND po.tip_parametra_id     = pr.tip_parametra_id
                   CROSS JOIN LATERAL f_check_param(pr.tip_parametra_id, pr.value) cp
                   LEFT JOIN tipy_oshibok ot
                          ON ot.code = CASE WHEN po.id IS NULL THEN 'NOT_APPLICABLE' ELSE cp.error_code END) e
     WHERE e.id = par.id;
 
    SELECT count(*) INTO v_cnt FROM parametry WHERE has_error;
    RETURN v_cnt;
END;
$$;
 

-- 8. Виртуальная поправка ΔTv по температуре 

CREATE OR REPLACE FUNCTION f_virtual_correction(p_t NUMERIC)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
    SELECT f_calc_interpolation(p_t, f_get_interpolation_params(p_t));
$$;
 
COMMENT ON FUNCTION f_virtual_correction(NUMERIC) IS 'Виртуальная поправка ΔTv: интерполяция по узлам popravki_virtualnoj_temperatury';
 

-- 9. Метео приближенный: ДДЧЧМ
--    ДД - день месяца, ЧЧ - часы, М - десятки минут. Пример: 24093

CREATE OR REPLACE FUNCTION f_meteo_ddchhm(p_measured_at TIMESTAMP)
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
    SELECT to_char(p_measured_at, 'DDHH24')
           || (extract(minute FROM p_measured_at)::INTEGER / f_get_constant('MINUTES_STEP')::INTEGER)::TEXT;
$$;
 

-- 10. Метео приближенный: ВВВВ - высота метеопоста, 4 цифры. Пример: 0060

CREATE OR REPLACE FUNCTION f_meteo_vvvv(p_height NUMERIC)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_height < 0 THEN
        RAISE EXCEPTION 'Формат ВВВВ для отрицательной высоты (%) в ТЗ не определен', p_height;
    END IF;
    RETURN to_char(round(p_height), 'FM0000');
END;
$$;
 

-- 11. Метео приближенный: БББ - отклонение давления от 750 мм рт.ст.
--     +7 -> 007, +13 -> 013; -7 -> 507, -13 -> 513

CREATE OR REPLACE FUNCTION f_meteo_bbb(p_pressure NUMERIC)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_delta INTEGER;
BEGIN
    v_delta := round(p_pressure - f_get_constant('TABLE_PRESSURE'))::INTEGER;
    IF v_delta >= 0 THEN
        RETURN to_char(v_delta, 'FM000');
    END IF;
    RETURN to_char(f_get_constant('NEG_PRESSURE_OFFSET')::INTEGER - v_delta, 'FM000');
END;
$$;
 

-- 12. Метео приближенный: ТТ - отклонение виртуальной температуры от 15.9
--     T0 = t0 + ΔTv;  ТТ = round(T0 - 15.9). Пример: t0 = 23 -> 09

CREATE OR REPLACE FUNCTION f_meteo_tt(p_temperature NUMERIC)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_t0    NUMERIC;
    v_delta INTEGER;
BEGIN
    v_t0    := p_temperature + f_virtual_correction(p_temperature);
    v_delta := round(v_t0 - f_get_constant('TABLE_TEMPERATURE'))::INTEGER;
    IF v_delta >= 0 THEN
        RETURN to_char(v_delta, 'FM00');
    END IF;
    RETURN to_char(f_get_constant('NEG_TEMPERATURE_OFFSET')::INTEGER - v_delta, 'FM00');
END;
$$;
 

-- 13. Метео приближенный целиком: 'ДДЧЧМ ВВВВ БББТТ'

CREATE OR REPLACE FUNCTION f_meteo_approx(
    p_measured_at TIMESTAMP,
    p_height      NUMERIC,
    p_pressure    NUMERIC,
    p_temperature NUMERIC)
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
    SELECT f_meteo_ddchhm(p_measured_at) || ' '
        || f_meteo_vvvv(p_height)        || ' '
        || f_meteo_bbb(p_pressure)       || f_meteo_tt(p_temperature);
$$;
 
COMMENT ON FUNCTION f_meteo_approx(TIMESTAMP, NUMERIC, NUMERIC, NUMERIC) IS 'Заголовок Метео приближенный: ДДЧЧМ ВВВВ БББТТ';
 