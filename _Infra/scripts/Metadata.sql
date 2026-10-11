-- Метаданные
SELECT
    ROW_NUMBER() OVER (ORDER BY t.type_order, t.obj_name) AS "№",
    t.obj_name AS "Наименование",
    t.obj_type  AS "Тип"
FROM (
    SELECT table_name AS obj_name, 'Таблица' AS obj_type, 1 AS type_order
      FROM information_schema.tables
     WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    UNION ALL
    SELECT sequence_name, 'Последовательность', 2
      FROM information_schema.sequences
     WHERE sequence_schema = 'public'
    UNION ALL
    SELECT constraint_name,
           CASE constraint_type
               WHEN 'PRIMARY KEY' THEN 'Первичный ключ'
               WHEN 'FOREIGN KEY' THEN 'Внешний ключ'
               WHEN 'UNIQUE' THEN 'Уникальное ограничение'
               WHEN 'CHECK' THEN 'Ограничение CHECK'
           END,
           3
      FROM information_schema.table_constraints
     WHERE table_schema = 'public'
       AND constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY', 'UNIQUE', 'CHECK')
) t
ORDER BY 1;