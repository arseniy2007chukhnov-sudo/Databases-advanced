-- 4. Значения корректны и в допустимых диапазонах?  (ожидаем 0 строк)
SELECT v.id AS parametr_id,
       v.pachka_id,
       tp.id AS type_id,
       tp.name AS type_name,
       v.value,
       CASE tp.id
            WHEN 1 THEN 'целое число'
            WHEN 2 THEN 'от -58 до 58, 1 знак после запятой'
            WHEN 3 THEN 'целое, от 500 до 900'
            WHEN 4 THEN 'целое, от 0 до 59'
            WHEN 5 THEN 'целое, от 0 до 15'
            WHEN 6 THEN 'целое, от 0 до 150'
       END AS expected_rule
FROM (
    SELECT id, pachka_id, tip_parametra_id, value,
           CAST(value AS NUMERIC(10,2)) AS num_value
    FROM parametry
) v
INNER JOIN tipy_parametrov tp ON tp.id = v.tip_parametra_id
WHERE v.value IS NULL
   OR (tp.id = 1 AND v.num_value <> CAST(v.num_value AS INTEGER))
   OR (tp.id = 2 AND (v.num_value NOT BETWEEN -58 AND 58
                   OR v.num_value * 10 <> CAST(v.num_value * 10 AS INTEGER)))
   OR (tp.id = 3 AND (v.num_value NOT BETWEEN 500 AND 900
                   OR v.num_value <> CAST(v.num_value AS INTEGER)))
   OR (tp.id = 4 AND (v.num_value NOT BETWEEN 0 AND 59
                   OR v.num_value <> CAST(v.num_value AS INTEGER)))
   OR (tp.id = 5 AND (v.num_value NOT BETWEEN 0 AND 15
                   OR v.num_value <> CAST(v.num_value AS INTEGER)))
   OR (tp.id = 6 AND (v.num_value NOT BETWEEN 0 AND 150
                   OR v.num_value <> CAST(v.num_value AS INTEGER)))
ORDER BY v.pachka_id, tp.id;