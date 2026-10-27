-- ТЕСТОВЫЕ ДАННЫЕ С ОШИБКАМИ + ЗАПРОСЫ
 
 
-- 1. Тестовые данные (пачки PCH-E01..E06 с намеренными ошибками). Только DML.
--    Типы параметров: 1 высота, 2 температура, 3 давление,
--    4 направление ветра, 5 скорость ветра, 6 дальность сноса пуль
 
DO
$$
BEGIN
    DELETE FROM parametry WHERE uniq_code LIKE 'PAR-E%';
    DELETE FROM pachki    WHERE uniq_code LIKE 'PCH-E%';
 
    INSERT INTO pachki (uniq_code, tip_oborudovaniya_id, polzovatel_id, measured_at) VALUES
        ('PCH-E01', 1, 2, TIMESTAMP '2026-09-10 09:30:00'),  -- ДМК: давление < 500
        ('PCH-E02', 1, 2, TIMESTAMP '2026-09-11 10:10:00'),  -- ДМК: давление 1000.5 (две ошибки), направление > 59, скорость > 15
        ('PCH-E03', 2, 3, TIMESTAMP '2026-09-12 11:20:00'),  -- ВР: температура > 58, дальность > 150
        ('PCH-E04', 1, 3, TIMESTAMP '2026-09-13 12:40:00'),  -- ДМК: нет скорости ветра, дробное давление
        ('PCH-E05', 2, 1, TIMESTAMP '2026-09-14 13:50:00'),  -- ВР: лишний параметр "скорость ветра"
        ('PCH-E06', 1, 1, TIMESTAMP '2026-09-15 14:00:00');  -- ДМК: без ошибок
 
    INSERT INTO parametry (uniq_code, pachka_id, tip_parametra_id, value)
    SELECT 'PAR-' || substr(d.pachka, 5) || '-' || d.tip, p.id, d.tip, d.val
      FROM (VALUES
            ('PCH-E01', 1, 100), ('PCH-E01', 2, 12), ('PCH-E01', 3, 450),    ('PCH-E01', 4, 10), ('PCH-E01', 5, 5),
            ('PCH-E02', 1, 100), ('PCH-E02', 2, 15), ('PCH-E02', 3, 1000.5),    ('PCH-E02', 4, 61), ('PCH-E02', 5, 20),
            ('PCH-E03', 1, 80),  ('PCH-E03', 2, 60.5), ('PCH-E03', 3, 745),  ('PCH-E03', 4, 5),  ('PCH-E03', 6, 200),
            ('PCH-E04', 1, 100), ('PCH-E04', 2, 20), ('PCH-E04', 3, 750.55), ('PCH-E04', 4, 20),
            ('PCH-E05', 1, 90),  ('PCH-E05', 2, 14), ('PCH-E05', 3, 748),    ('PCH-E05', 4, 30), ('PCH-E05', 5, 5), ('PCH-E05', 6, 30),
            ('PCH-E06', 1, 100), ('PCH-E06', 2, 25), ('PCH-E06', 3, 765),    ('PCH-E06', 4, 15), ('PCH-E06', 5, 6)
           ) AS d (pachka, tip, val)
           INNER JOIN pachki p ON p.uniq_code = d.pachka;
END
$$;
 
-- 2. Запрос "Список параметров с ошибками"
--    № | Тип оборудования | Высота | Температура | Давление | Направление ветра |
--    Скорость ветра | Дальность сноса пуль | Есть ошибка | Описание ошибки
 
WITH batch_params AS (           
    SELECT pa.id AS pachka_id, pa.uniq_code, pa.measured_at, pa.polzovatel_id, pa.tip_oborudovaniya_id,
           MAX(CASE WHEN par.tip_parametra_id = 1 THEN par.value END) AS height,
           MAX(CASE WHEN par.tip_parametra_id = 2 THEN par.value END) AS temperature,
           MAX(CASE WHEN par.tip_parametra_id = 3 THEN par.value END) AS pressure,
           MAX(CASE WHEN par.tip_parametra_id = 4 THEN par.value END) AS wind_direction,
           MAX(CASE WHEN par.tip_parametra_id = 5 THEN par.value END) AS wind_speed,
           MAX(CASE WHEN par.tip_parametra_id = 6 THEN par.value END) AS bullet_drift
      FROM pachki pa
           LEFT JOIN parametry par ON par.pachka_id = pa.id
     GROUP BY pa.id, pa.uniq_code, pa.measured_at, pa.polzovatel_id, pa.tip_oborudovaniya_id
),
checked AS (
    SELECT bp.*,
           f_validate_params(ROW(bp.tip_oborudovaniya_id, bp.height, bp.temperature, bp.pressure,
                                 bp.wind_direction, bp.wind_speed, bp.bullet_drift)::t_meteo_params) AS errors_text
      FROM batch_params bp
)
SELECT c.uniq_code        AS "№",
       t.short_name       AS "Тип оборудования",
       c.height           AS "Высота метеопоста",
       c.temperature      AS "Температура",
       c.pressure         AS "Давление",
       c.wind_direction   AS "Направление ветра",
       c.wind_speed       AS "Скорость ветра",
       c.bullet_drift     AS "Дальность сноса пуль",
       CASE WHEN c.errors_text <> '' THEN 'Да' ELSE 'Нет' END AS "Есть ошибка",
       c.errors_text      AS "Описание ошибки"
  FROM checked c
       INNER JOIN tipy_oborudovaniya t ON t.id = c.tip_oborudovaniya_id
 ORDER BY CASE WHEN c.errors_text <> '' THEN 0 ELSE 1 END, c.uniq_code;
 
 
-- 3. Запрос "Лучший стрелок": пользователи и число ошибок в параметрах
--    (меньше ошибок - выше место; окно RANK + группировка + CTE)
 
WITH batch_params AS (
    SELECT pa.id AS pachka_id, pa.polzovatel_id, pa.tip_oborudovaniya_id,
           MAX(CASE WHEN par.tip_parametra_id = 1 THEN par.value END) AS height,
           MAX(CASE WHEN par.tip_parametra_id = 2 THEN par.value END) AS temperature,
           MAX(CASE WHEN par.tip_parametra_id = 3 THEN par.value END) AS pressure,
           MAX(CASE WHEN par.tip_parametra_id = 4 THEN par.value END) AS wind_direction,
           MAX(CASE WHEN par.tip_parametra_id = 5 THEN par.value END) AS wind_speed,
           MAX(CASE WHEN par.tip_parametra_id = 6 THEN par.value END) AS bullet_drift
      FROM pachki pa
           LEFT JOIN parametry par ON par.pachka_id = pa.id
     GROUP BY pa.id, pa.polzovatel_id, pa.tip_oborudovaniya_id
),
errors AS (                       -- одна строка = одна ошибка
    SELECT bp.polzovatel_id, bp.pachka_id, e.tip_parametra_id, e.error_code
      FROM batch_params bp
           CROSS JOIN LATERAL f_param_errors(
               ROW(bp.tip_oborudovaniya_id, bp.height, bp.temperature, bp.pressure,
                   bp.wind_direction, bp.wind_speed, bp.bullet_drift)::t_meteo_params) e
),
batches_stat AS (
    SELECT polzovatel_id, COUNT(*) AS batches_cnt
      FROM batch_params
     GROUP BY polzovatel_id
),
errors_stat AS (
    SELECT polzovatel_id,
           COUNT(*) AS errors_cnt,
           COUNT(DISTINCT pachka_id) AS bad_batches_cnt,
           COUNT(*) FILTER (WHERE error_code = 'OUT_OF_RANGE')                              AS out_of_range_cnt,
           COUNT(*) FILTER (WHERE error_code IN ('NOT_INTEGER', 'TOO_MANY_DECIMALS'))       AS bad_format_cnt,
           COUNT(*) FILTER (WHERE error_code IN ('MISSING_REQUIRED', 'NOT_APPLICABLE'))     AS bad_set_cnt
      FROM errors
     GROUP BY polzovatel_id
),
ranked AS (
    SELECT u.full_name,
           d.name                              AS dolzhnost,
           COALESCE(bs.batches_cnt, 0)         AS batches_cnt,
           COALESCE(es.bad_batches_cnt, 0)     AS bad_batches_cnt,
           COALESCE(es.errors_cnt, 0)          AS errors_cnt,
           COALESCE(es.out_of_range_cnt, 0)    AS out_of_range_cnt,
           COALESCE(es.bad_format_cnt, 0)      AS bad_format_cnt,
           COALESCE(es.bad_set_cnt, 0)         AS bad_set_cnt,
           RANK() OVER (ORDER BY COALESCE(es.errors_cnt, 0)) AS place
      FROM polzovateli u
           INNER JOIN dolzhnosti d ON d.id = u.dolzhnost_id
           LEFT JOIN batches_stat bs ON bs.polzovatel_id = u.id
           LEFT JOIN errors_stat  es ON es.polzovatel_id = u.id
)
SELECT r.place            AS "Место",
       r.full_name        AS "ФИО сотрудника",
       r.dolzhnost        AS "Должность",
       r.batches_cnt      AS "Пачек",
       r.bad_batches_cnt  AS "Пачек с ошибками",
       r.errors_cnt       AS "Ошибок в параметрах",
       r.out_of_range_cnt AS "Вне диапазона",
       r.bad_format_cnt   AS "Целое / разрядность",
       r.bad_set_cnt      AS "Не задан / не применим",
       CASE WHEN r.place = 1 THEN 'Лучший стрелок' ELSE '' END AS "Итог"
  FROM ranked r
 ORDER BY r.place, r.full_name;
 
 
-- 4. Ошибки по видам (классификатор tipy_oshibok): количество и доля
--    (окно SUM() OVER для доли, RANK() для места вида ошибки)
 
WITH batch_params AS (
    SELECT pa.id AS pachka_id, pa.tip_oborudovaniya_id,
           MAX(CASE WHEN par.tip_parametra_id = 1 THEN par.value END) AS height,
           MAX(CASE WHEN par.tip_parametra_id = 2 THEN par.value END) AS temperature,
           MAX(CASE WHEN par.tip_parametra_id = 3 THEN par.value END) AS pressure,
           MAX(CASE WHEN par.tip_parametra_id = 4 THEN par.value END) AS wind_direction,
           MAX(CASE WHEN par.tip_parametra_id = 5 THEN par.value END) AS wind_speed,
           MAX(CASE WHEN par.tip_parametra_id = 6 THEN par.value END) AS bullet_drift
      FROM pachki pa
           LEFT JOIN parametry par ON par.pachka_id = pa.id
     GROUP BY pa.id, pa.tip_oborudovaniya_id
),
errors AS (
    SELECT e.tip_oshibki_id
      FROM batch_params bp
           CROSS JOIN LATERAL f_param_errors(
               ROW(bp.tip_oborudovaniya_id, bp.height, bp.temperature, bp.pressure,
                   bp.wind_direction, bp.wind_speed, bp.bullet_drift)::t_meteo_params) e
),
stat AS (
    SELECT tip_oshibki_id, COUNT(*) AS cnt
      FROM errors
     GROUP BY tip_oshibki_id
),
joined AS (
    SELECT ot.id, ot.uniq_code, ot.name, COALESCE(s.cnt, 0) AS cnt
      FROM tipy_oshibok ot
           LEFT JOIN stat s ON s.tip_oshibki_id = ot.id
)
SELECT j.uniq_code AS "Код",
       j.name      AS "Вид ошибки",
       j.cnt       AS "Количество",
       ROUND(100.0 * j.cnt / NULLIF(SUM(j.cnt) OVER (), 0), 1) AS "Доля, %",
       RANK() OVER (ORDER BY j.cnt DESC) AS "Место"
  FROM joined j
 ORDER BY j.cnt DESC, j.id;
 
 
-- 5. Все ошибки построчно: одна строка = одна ошибка (текст из классификатора).
--    Если у параметра две ошибки - будет две строки.
 
WITH batch_params AS (
    SELECT pa.id AS pachka_id, pa.uniq_code, pa.measured_at, pa.tip_oborudovaniya_id,
           MAX(CASE WHEN par.tip_parametra_id = 1 THEN par.value END) AS height,
           MAX(CASE WHEN par.tip_parametra_id = 2 THEN par.value END) AS temperature,
           MAX(CASE WHEN par.tip_parametra_id = 3 THEN par.value END) AS pressure,
           MAX(CASE WHEN par.tip_parametra_id = 4 THEN par.value END) AS wind_direction,
           MAX(CASE WHEN par.tip_parametra_id = 5 THEN par.value END) AS wind_speed,
           MAX(CASE WHEN par.tip_parametra_id = 6 THEN par.value END) AS bullet_drift
      FROM pachki pa
           LEFT JOIN parametry par ON par.pachka_id = pa.id
     GROUP BY pa.id, pa.uniq_code, pa.measured_at, pa.tip_oborudovaniya_id
),
errors AS (
    SELECT bp.uniq_code, bp.measured_at, e.tip_parametra_id, e.error_code, e.message
      FROM batch_params bp
           CROSS JOIN LATERAL f_param_errors(
               ROW(bp.tip_oborudovaniya_id, bp.height, bp.temperature, bp.pressure,
                   bp.wind_direction, bp.wind_speed, bp.bullet_drift)::t_meteo_params) e
)
SELECT er.uniq_code    AS "№",
       er.measured_at  AS "Дата измерения",
       tp.name         AS "Параметр",
       ot.name         AS "Вид ошибки",
       er.message      AS "Сообщение"
  FROM errors er
       LEFT JOIN tipy_parametrov tp ON tp.id = er.tip_parametra_id
       INNER JOIN tipy_oshibok ot   ON ot.code = er.error_code
 ORDER BY er.uniq_code, er.tip_parametra_id, ot.id;
 
 
-- 6. Метео приближенный по пачкам (ДДЧЧМ ВВВВ БББТТ).
--    Для пачек с ошибками расчет не выполняется.
 
WITH batch_params AS (
    SELECT pa.id AS pachka_id, pa.uniq_code, pa.measured_at, pa.tip_oborudovaniya_id,
           MAX(CASE WHEN par.tip_parametra_id = 1 THEN par.value END) AS height,
           MAX(CASE WHEN par.tip_parametra_id = 2 THEN par.value END) AS temperature,
           MAX(CASE WHEN par.tip_parametra_id = 3 THEN par.value END) AS pressure,
           MAX(CASE WHEN par.tip_parametra_id = 4 THEN par.value END) AS wind_direction,
           MAX(CASE WHEN par.tip_parametra_id = 5 THEN par.value END) AS wind_speed,
           MAX(CASE WHEN par.tip_parametra_id = 6 THEN par.value END) AS bullet_drift
      FROM pachki pa
           LEFT JOIN parametry par ON par.pachka_id = pa.id
     GROUP BY pa.id, pa.uniq_code, pa.measured_at, pa.tip_oborudovaniya_id
),
checked AS (
    SELECT bp.*,
           f_validate_params(ROW(bp.tip_oborudovaniya_id, bp.height, bp.temperature, bp.pressure,
                                 bp.wind_direction, bp.wind_speed, bp.bullet_drift)::t_meteo_params) AS errors_text
      FROM batch_params bp
)
SELECT c.uniq_code AS "№",
       c.measured_at AS "Дата измерения",
       CASE WHEN c.errors_text = ''
            THEN f_meteo_approx(c.measured_at, c.height, c.pressure, c.temperature)
            ELSE 'расчет невозможен: есть ошибки'
       END AS "Метео приближенный"
  FROM checked c
 ORDER BY c.measured_at, c.uniq_code;
 
 
-- 7. Самопроверка функций по примерам ТЗ
 
WITH checks (name, actual, expected) AS (
    VALUES
        ('Поправка ΔTv при t0 = 23 (интерполяция, ТЗ: 1,8)', f_fmt_num(f_virtual_correction(23)), '1.8'),
        ('ТТ при t0 = 23 (ТЗ пример 1: 09)',                f_meteo_tt(23),                      '09'),
        ('БББТТ при P = 765, t0 = 25 (ТЗ пример 2: 01511)', f_meteo_bbb(765) || f_meteo_tt(25),  '01511'),
        ('ДДЧЧМ для 24.09 09:30 (ТЗ: 24093)',               f_meteo_ddchhm(TIMESTAMP '2026-09-24 09:30:00'), '24093'),
        ('ВВВВ при высоте 60 (ТЗ: 0060)',                   f_meteo_vvvv(60),                    '0060'),
        ('БББ при P = 757 (ТЗ: 007)',                       f_meteo_bbb(757),                    '007'),
        ('БББ при P = 763 (ТЗ: 013)',                       f_meteo_bbb(763),                    '013'),
        ('БББ при P = 743 (ТЗ: 507)',                       f_meteo_bbb(743),                    '507'),
        ('БББ при P = 737 (ТЗ: 513)',                       f_meteo_bbb(737),                    '513'),
        ('Поправка при t0 = -10 (ниже таблицы: крайний узел, 0.5)', f_fmt_num(f_virtual_correction(-10)), '0.5'),
        ('Поправка при t0 = 45 (выше таблицы, ожидается 4.5)', f_fmt_num(f_virtual_correction(45)), '4.5')
)
SELECT c.name AS "Проверка", c.actual AS "Получено", c.expected AS "Ожидается",
       CASE WHEN c.actual = c.expected THEN 'OK' ELSE 'ОШИБКА' END AS "Результат"
  FROM checks c;
 