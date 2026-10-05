-- 3. Каждая пачка содержит полный набор параметров (5 шт)?  (ожидаем 0 строк)
SELECT p.id AS pachka_id,
       p.uniq_code,
       p.tip_oborudovaniya_id,
       COUNT(par.id) AS cnt_params,
       COUNT(DISTINCT par.tip_parametra_id) AS cnt_distinct_types
FROM pachki p
LEFT JOIN parametry par ON par.pachka_id = p.id
GROUP BY p.id, p.uniq_code, p.tip_oborudovaniya_id
HAVING COUNT(par.id) <> 5
    OR COUNT(DISTINCT par.tip_parametra_id) <> 5
ORDER BY p.id;