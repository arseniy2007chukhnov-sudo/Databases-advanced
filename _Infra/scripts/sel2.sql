-- 2. Нет ли пустых пачек измерения?  (ожидаем 0 строк)
SELECT p.id AS pachka_id,
       p.uniq_code,
       p.created_date
FROM pachki p
LEFT JOIN parametry par ON par.pachka_id = p.id
WHERE par.id IS NULL
ORDER BY p.id;