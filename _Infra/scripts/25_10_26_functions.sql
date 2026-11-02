-- ФУНКЦИИ


DO
$$
BEGIN
 
    -- ТРАНЗАКЦИЯ 1. Тип данных "Список параметров"
    --   (+ удаление объектов прошлой версии скрипта, если она запускалась)
 
    BEGIN
        DROP FUNCTION IF EXISTS f_refresh_param_errors();
        ALTER TABLE parametry DROP CONSTRAINT IF EXISTS fk_parametry_tip_oshibki;
        ALTER TABLE parametry DROP COLUMN IF EXISTS tip_oshibki_id;
        ALTER TABLE parametry DROP COLUMN IF EXISTS has_error;
        ALTER TABLE parametry DROP COLUMN IF EXISTS error_text;
 
        DROP FUNCTION IF EXISTS f_check_param(INTEGER, NUMERIC);
        DROP TYPE IF EXISTS t_meteo_params CASCADE;   -- CASCADE удалит функции, зависящие от типа
 
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
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Транзакция 1 отменена: %', SQLERRM;
            RAISE;
    END;
 
 
    -- ТРАНЗАКЦИЯ 2. Функции проверки параметров
 
    BEGIN
        -- Число без хвостовых нулей (34.00 -> 34, 0.20 -> 0.2)
        CREATE OR REPLACE FUNCTION f_fmt_num(p_value NUMERIC)
        RETURNS TEXT
        LANGUAGE sql
        IMMUTABLE
        AS $fn$
            SELECT CASE WHEN position('.' IN p_value::text) > 0
                        THEN regexp_replace(p_value::text, '\.?0+$', '')
                        ELSE p_value::text
                   END;
        $fn$;
 
        -- Текст ошибки из шаблона классификатора tipy_oshibok
        CREATE OR REPLACE FUNCTION f_error_text(
            p_code  TEXT,
            p_param TEXT    DEFAULT NULL,
            p_value NUMERIC DEFAULT NULL,
            p_min   NUMERIC DEFAULT NULL,
            p_max   NUMERIC DEFAULT NULL,
            p_scale INTEGER DEFAULT NULL)
        RETURNS TEXT
        LANGUAGE sql
        STABLE
        AS $fn$
            SELECT replace(replace(replace(replace(replace(ot.message_template,
                       '{param}', coalesce(p_param, '')),
                       '{value}', coalesce(f_fmt_num(p_value), '')),
                       '{min}',   coalesce(f_fmt_num(p_min), '-∞')),
                       '{max}',   coalesce(f_fmt_num(p_max), '+∞')),
                       '{scale}', coalesce(p_scale::TEXT, ''))
              FROM tipy_oshibok ot
             WHERE ot.code = p_code;
        $fn$;
 
        COMMENT ON FUNCTION f_error_text(TEXT, TEXT, NUMERIC, NUMERIC, NUMERIC, INTEGER) IS 'Текст ошибки по шаблону из tipy_oshibok';
 
        -- Проверка одного значения по таблице ограничений.
        -- Возвращает НАБОР ошибок: каждая нарушенная проверка - отдельная строка
        -- (например, 1000.5 для давления: "не целое" и "вне диапазона").
        CREATE OR REPLACE FUNCTION f_check_param(p_tip_parametra_id INTEGER, p_value NUMERIC)
        RETURNS TABLE (error_code TEXT, message TEXT)
        LANGUAGE plpgsql
        STABLE
        AS $fn$
        DECLARE
            v_name  TEXT;
            v_min   NUMERIC;
            v_max   NUMERIC;
            v_scale SMALLINT;
        BEGIN
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
                message    := f_error_text('UNKNOWN_PARAMETER', coalesce(p_tip_parametra_id::TEXT, 'NULL'));
                RETURN NEXT;
                RETURN;
            END IF;
 
            -- разрядность
            IF v_scale IS NOT NULL AND p_value <> round(p_value, v_scale) THEN
                IF v_scale = 0 THEN
                    error_code := 'NOT_INTEGER';
                ELSE
                    error_code := 'TOO_MANY_DECIMALS';
                END IF;
                message := f_error_text(error_code, v_name, p_value, v_min, v_max, v_scale);
                RETURN NEXT;
            END IF;
 
            -- диапазон (проверяется независимо от разрядности)
            IF (v_min IS NOT NULL AND p_value < v_min) OR (v_max IS NOT NULL AND p_value > v_max) THEN
                error_code := 'OUT_OF_RANGE';
                message    := f_error_text(error_code, v_name, p_value, v_min, v_max, v_scale);
                RETURN NEXT;
            END IF;
        END;
        $fn$;
 
        -- Ошибки пачки построчно: (тип параметра, вид ошибки, текст).
        -- Основа для f_validate_params и для подсчета ошибок в запросах.
        CREATE OR REPLACE FUNCTION f_param_errors(p t_meteo_params)
        RETURNS TABLE (tip_parametra_id INTEGER, tip_oshibki_id INTEGER, error_code TEXT, message TEXT)
        LANGUAGE sql
        STABLE
        AS $fn$
            WITH v (tip, val) AS (
                VALUES (1, p.height),
                       (2, p.temperature),
                       (3, p.pressure),
                       (4, p.wind_direction),
                       (5, p.wind_speed),
                       (6, p.bullet_drift)
            ),
            checked AS (
                SELECT v.tip, tp.name AS tip_name, v.val, po.id AS po_id, po.is_required
                  FROM v
                       INNER JOIN tipy_parametrov tp ON tp.id = v.tip
                       LEFT JOIN parametry_oborudovaniya po
                              ON po.tip_oborudovaniya_id = p.tip_oborudovaniya_id
                             AND po.tip_parametra_id     = v.tip
            ),
            errs AS (
                -- значение есть, но для этого оборудования параметр не предусмотрен
                SELECT c.tip, 'NOT_APPLICABLE' AS code, f_error_text('NOT_APPLICABLE', c.tip_name) AS msg
                  FROM checked c
                 WHERE c.po_id IS NULL AND c.val IS NOT NULL
                UNION ALL
                -- обязательный параметр не задан
                SELECT c.tip, 'MISSING_REQUIRED', f_error_text('MISSING_REQUIRED', c.tip_name)
                  FROM checked c
                 WHERE c.is_required AND c.val IS NULL
                UNION ALL
                -- проверка значения (набор ошибок)
                SELECT c.tip, cp.error_code, cp.message
                  FROM checked c
                       CROSS JOIN LATERAL f_check_param(c.tip, c.val) cp
                 WHERE c.po_id IS NOT NULL
            )
            SELECT NULL::INTEGER, ot.id, ot.code::TEXT, f_error_text('NO_EQUIPMENT')
              FROM tipy_oshibok ot
             WHERE ot.code = 'NO_EQUIPMENT'
               AND p.tip_oborudovaniya_id IS NULL
            UNION ALL
            SELECT e.tip, ot.id, ot.code::TEXT, e.msg
              FROM errs e
                   INNER JOIN tipy_oshibok ot ON ot.code = e.code
             WHERE p.tip_oborudovaniya_id IS NOT NULL
            ORDER BY 1, 3;
        $fn$;
 
        -- Основная функция по заданию: тип со списком параметров -> строка ошибок.
        -- Пустая строка = ошибок нет.
        CREATE OR REPLACE FUNCTION f_validate_params(p t_meteo_params)
        RETURNS TEXT
        LANGUAGE sql
        STABLE
        AS $fn$
            SELECT coalesce(string_agg(e.message, '; ' ORDER BY e.tip_parametra_id, e.error_code), '')
              FROM f_param_errors(p) e;
        $fn$;
 
        COMMENT ON FUNCTION f_validate_params(t_meteo_params) IS 'Проверка параметров пачки: возвращает список ошибок через "; "';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Транзакция 2 отменена: %', SQLERRM;
            RAISE;
    END;
 
 
    -- ТРАНЗАКЦИЯ 3. Функции расчета Метео приближенный
 
    BEGIN
        -- 8. Виртуальная поправка ΔTv по температуре 
 
        CREATE OR REPLACE FUNCTION f_virtual_correction(p_t NUMERIC)
        RETURNS NUMERIC
        LANGUAGE sql
        STABLE
        AS $fn$
            SELECT f_calc_interpolation(p_t, f_get_interpolation_params(p_t));
        $fn$;
 
        COMMENT ON FUNCTION f_virtual_correction(NUMERIC) IS 'Виртуальная поправка ΔTv: интерполяция по узлам popravki_virtualnoj_temperatury';
 
 
        -- 9. Метео приближенный: ДДЧЧМ
        --    ДД - день месяца, ЧЧ - часы, М - десятки минут. Пример: 24093
 
        CREATE OR REPLACE FUNCTION f_meteo_ddchhm(p_measured_at TIMESTAMP)
        RETURNS TEXT
        LANGUAGE sql
        STABLE
        AS $fn$
            SELECT to_char(p_measured_at, 'DDHH24')
                   || (extract(minute FROM p_measured_at)::INTEGER / f_get_constant('MINUTES_STEP')::INTEGER)::TEXT;
        $fn$;
 
 
        -- 10. Метео приближенный: ВВВВ - высота метеопоста, 4 цифры. Пример: 0060
 
        CREATE OR REPLACE FUNCTION f_meteo_vvvv(p_height NUMERIC)
        RETURNS TEXT
        LANGUAGE plpgsql
        IMMUTABLE
        AS $fn$
        BEGIN
            IF p_height < 0 THEN
                RAISE EXCEPTION 'Формат ВВВВ для отрицательной высоты (%) в ТЗ не определен', p_height;
            END IF;
            RETURN to_char(round(p_height), 'FM0000');
        END;
        $fn$;
 
 
        -- 11. Метео приближенный: БББ - отклонение давления от 750 мм рт.ст.
        --     +7 -> 007, +13 -> 013; -7 -> 507, -13 -> 513
 
        CREATE OR REPLACE FUNCTION f_meteo_bbb(p_pressure NUMERIC)
        RETURNS TEXT
        LANGUAGE plpgsql
        STABLE
        AS $fn$
        DECLARE
            v_delta INTEGER;
        BEGIN
            v_delta := round(p_pressure - f_get_constant('TABLE_PRESSURE'))::INTEGER;
            IF v_delta >= 0 THEN
                RETURN to_char(v_delta, 'FM000');
            END IF;
            RETURN to_char(f_get_constant('NEG_PRESSURE_OFFSET')::INTEGER - v_delta, 'FM000');
        END;
        $fn$;
 
 
        -- 12. Метео приближенный: ТТ - отклонение виртуальной температуры от 15.9
        --     T0 = t0 + ΔTv;  ТТ = round(T0 - 15.9). Пример: t0 = 23 -> 09
 
        CREATE OR REPLACE FUNCTION f_meteo_tt(p_temperature NUMERIC)
        RETURNS TEXT
        LANGUAGE plpgsql
        STABLE
        AS $fn$
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
        $fn$;
 
 
        -- 13. Метео приближенный целиком: 'ДДЧЧМ ВВВВ БББТТ'
 
        CREATE OR REPLACE FUNCTION f_meteo_approx(
            p_measured_at TIMESTAMP,
            p_height      NUMERIC,
            p_pressure    NUMERIC,
            p_temperature NUMERIC)
        RETURNS TEXT
        LANGUAGE sql
        STABLE
        AS $fn$
            SELECT f_meteo_ddchhm(p_measured_at) || ' '
                || f_meteo_vvvv(p_height)        || ' '
                || f_meteo_bbb(p_pressure)       || f_meteo_tt(p_temperature);
        $fn$;
 
        COMMENT ON FUNCTION f_meteo_approx(TIMESTAMP, NUMERIC, NUMERIC, NUMERIC) IS 'Заголовок Метео приближенный: ДДЧЧМ ВВВВ БББТТ';
 
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Транзакция 3 отменена: %', SQLERRM;
            RAISE;
    END;
END
$$;
 