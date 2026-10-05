-- 5. Единицы измерения верны по отношению к параметрам?  (ожидаем 0 строк)
SELECT tp.id AS type_id,
       tp.name AS type_name,
       tp.edinica_izmereniya_id AS actual_unit_id,
       ei.short_name AS actual_unit,
       ei.bazovaya_edinica_id AS actual_base_id,
       x.unit_id AS expected_unit_id,
       x.base_id AS expected_base_id
FROM tipy_parametrov tp
INNER JOIN (
    SELECT 1 AS tip_parametra_id, 1 AS unit_id, 1 AS base_id   -- Высота: м, длина
    UNION ALL SELECT 2, 2, 2                                   -- Температура: C, температура
    UNION ALL SELECT 3, 3, 3                                   -- Давление: мм рт.ст., давление
    UNION ALL SELECT 4, 4, 4                                   -- Направление ветра: д.у., угол
    UNION ALL SELECT 5, 5, 5                                   -- Скорость ветра: м/с, скорость
    UNION ALL SELECT 6, 1, 1                                   -- Дальность сноса: м, длина
) x ON x.tip_parametra_id = tp.id
LEFT JOIN edinicy_izmereniya ei ON ei.id = tp.edinica_izmereniya_id
WHERE ei.id IS NULL
   OR ei.id <> x.unit_id
   OR ei.bazovaya_edinica_id <> x.base_id
ORDER BY tp.id;