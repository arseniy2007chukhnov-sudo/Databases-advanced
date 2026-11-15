-- База данных: Front (Microsoft SQL Server, схема dbo). Синтаксис T-SQL.
-- Запросы только читают данные (SELECT). Для скриншота выполняйте по одному.


-- ===== Группа 5: Анализ остатков =====


-- Q5.1 Наличие данных в таблицах группы
-- Цель: подтвердить, какие таблицы группы содержат данные, а какие пусты.
WITH tbl (table_name, role_in_group, sort_no) AS (
    SELECT * FROM (VALUES
        (N'product', N'основная', 1),
        (N'bm_StorageOperations', N'основная', 1),
        (N'stockperiod', N'основная', 1),
        (N'bm_StorageOperationsType', N'связанная', 2),
        (N'bm_StorageOperations_Table', N'связанная', 2),
        (N'storages', N'связанная', 2),
        (N'category', N'связанная', 2),
        (N'size', N'связанная', 2),
        (N'bm_ReasonDebit', N'связанная', 2),
        (N'wastemessages', N'связанная', 2),
        (N'beginperiod', N'связанная', 2),
        (N'bm_JournalBarnetDocs', N'связанная', 2),
        (N'closingcount', N'проверка наличия', 3),
        (N'onhand', N'проверка наличия', 3),
        (N'storagesonhand', N'проверка наличия', 3),
        (N'stock', N'проверка наличия', 3),
        (N'storeroom', N'проверка наличия', 3),
        (N'keg', N'проверка наличия', 3),
        (N'adjustment', N'проверка наличия', 3)
    ) AS v (table_name, role_in_group, sort_no)
),
cnt AS (
    SELECT t.name AS table_name, SUM(ps.row_count) AS row_cnt
    FROM sys.tables AS t
    INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id AND s.name = 'dbo'
    INNER JOIN sys.dm_db_partition_stats AS ps ON ps.object_id = t.object_id AND ps.index_id IN (0, 1)
    GROUP BY t.name
)
SELECT tbl.table_name, tbl.role_in_group,
       COALESCE(cnt.row_cnt, -1) AS row_cnt,
       CASE WHEN cnt.row_cnt IS NULL THEN N'таблица не найдена'
            WHEN cnt.row_cnt = 0 THEN N'пусто'
            ELSE N'есть данные' END AS state
FROM tbl
LEFT JOIN cnt ON cnt.table_name = tbl.table_name
ORDER BY tbl.sort_no, row_cnt DESC;


-- Q5.2 Текущие остатки по категориям (product.onhand)
-- Цель: Подтвердить связь product → category и получить картину остатков: сколько позиций в наличии, нулевых, отрицательных и ниже неснижаемого остатка.
-- Ожидание: Строки по категориям; negative_cnt > 0 — ошибки учёта, below_min_cnt — позиции к дозаказу.
SELECT COALESCE(c.description, N'(без категории)') AS category,
       COUNT(*) AS products_cnt,
       SUM(CASE WHEN p.onhand > 0 THEN 1 ELSE 0 END) AS in_stock_cnt,
       SUM(CASE WHEN p.onhand = 0 THEN 1 ELSE 0 END) AS zero_cnt,
       SUM(CASE WHEN p.onhand < 0 THEN 1 ELSE 0 END) AS negative_cnt,
       SUM(CASE WHEN p.minstockrate > 0 AND p.onhand < p.minstockrate THEN 1 ELSE 0 END) AS below_min_cnt,
       SUM(p.onhand) AS onhand_sum
FROM dbo.product AS p
LEFT JOIN dbo.category AS c ON c.id = p.CategoryID
GROUP BY COALESCE(c.description, N'(без категории)')
ORDER BY products_cnt DESC;


-- Q5.3 Согласованность остатков: движения ↔ последний Rest ↔ product.onhand
-- Цель: Выяснить, какому источнику остатка можно доверять: сколько пар «товар — склад» дают одинаковый остаток по сумме движений (Quantity × Factor), по последнему Rest и по product.onhand.
-- Ожидание: Доли совпадений (в пределах 0,001). Высокая доля у пары источников подтверждает, что Rest и сумма движений согласованы и их можно использовать как основной источник остатков.
WITH mv AS (
    SELECT so.ProductID, so.StorageID, SUM(so.Quantity * ot.Factor) AS qty_by_movements
    FROM dbo.bm_StorageOperations AS so
    INNER JOIN dbo.bm_StorageOperationsType AS ot ON ot.ID = so.OperationID
    GROUP BY so.ProductID, so.StorageID
),
last_rest AS (
    SELECT so.ProductID, so.StorageID, so.Rest,
           ROW_NUMBER() OVER (PARTITION BY so.ProductID, so.StorageID
                              ORDER BY so.[DateAdd] DESC, so.ID DESC) AS rn
    FROM dbo.bm_StorageOperations AS so
),
cmp AS (
    SELECT mv.ProductID, mv.StorageID, mv.qty_by_movements, lr.Rest AS last_rest, p.onhand
    FROM mv
    INNER JOIN last_rest AS lr ON lr.ProductID = mv.ProductID AND lr.StorageID = mv.StorageID AND lr.rn = 1
    INNER JOIN dbo.product AS p ON p.id = mv.ProductID
)
SELECT COUNT(*) AS pairs_cnt,
       SUM(CASE WHEN ABS(c.qty_by_movements - c.last_rest) < 0.001 THEN 1 ELSE 0 END) AS movements_eq_rest,
       SUM(CASE WHEN ABS(c.qty_by_movements - c.onhand) < 0.001 THEN 1 ELSE 0 END) AS movements_eq_onhand,
       SUM(CASE WHEN ABS(c.last_rest - c.onhand) < 0.001 THEN 1 ELSE 0 END) AS rest_eq_onhand,
       CAST(100.0 * SUM(CASE WHEN ABS(c.last_rest - c.onhand) < 0.001 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5, 1)) AS rest_eq_onhand_pct
FROM cmp AS c;


-- Q5.4 ТОП-30 расхождений остатков
-- Цель: Показать конкретные позиции, где источники остатка расходятся (кандидаты на инвентаризацию).
-- Ожидание: Список товаров с diff по убыванию. Пустой результат — расхождений нет.
WITH mv AS (
    SELECT so.ProductID, so.StorageID, SUM(so.Quantity * ot.Factor) AS qty_by_movements
    FROM dbo.bm_StorageOperations AS so
    INNER JOIN dbo.bm_StorageOperationsType AS ot ON ot.ID = so.OperationID
    GROUP BY so.ProductID, so.StorageID
),
last_rest AS (
    SELECT so.ProductID, so.StorageID, so.Rest,
           ROW_NUMBER() OVER (PARTITION BY so.ProductID, so.StorageID
                              ORDER BY so.[DateAdd] DESC, so.ID DESC) AS rn
    FROM dbo.bm_StorageOperations AS so
)
SELECT TOP 30
       p.id AS product_id, p.description AS product_name, mv.StorageID,
       mv.qty_by_movements, lr.Rest AS last_rest, p.onhand,
       ABS(lr.Rest - p.onhand) AS diff
FROM mv
INNER JOIN last_rest AS lr ON lr.ProductID = mv.ProductID AND lr.StorageID = mv.StorageID AND lr.rn = 1
INNER JOIN dbo.product AS p ON p.id = mv.ProductID
WHERE ABS(lr.Rest - p.onhand) >= 0.001
ORDER BY diff DESC;


-- Q5.5 Периодные остатки stockperiod: проверка баланса
-- Цель: Проверить арифметику периодных итогов: открытие + приход − расход = закрытие.
-- Ожидание: Статус «OK» у всех строк подтверждает корректность stockperiod.
SELECT sp.id, sp.storeid, sp.productid, p.description AS product_name,
       sp.datestart, sp.datefinish,
       sp.quantityopen, sp.quantityin, sp.quantityout, sp.quantityclose,
       sp.quantityopen + sp.quantityin - sp.quantityout AS calc_close,
       CASE WHEN ABS(sp.quantityopen + sp.quantityin - sp.quantityout - sp.quantityclose) < 0.001
            THEN N'OK' ELSE N'расхождение' END AS balance_status
FROM dbo.stockperiod AS sp
LEFT JOIN dbo.product AS p ON p.productid = sp.productid
ORDER BY sp.datefinish DESC, sp.id;


-- Q5.6 Списания по причинам (иерархия bm_ReasonDebit)
-- Цель: Подтвердить связь bm_StorageOperations.ReasonID → bm_ReasonDebit.ID (FK не объявлен) и оценить потери по причинам.
-- Ожидание: Строки «вид операции — группа причины — причина» с количеством и суммой. Пустой результат означал бы, что причины не заполняются.
SELECT CAST(ot.Description AS NVARCHAR(200)) AS operation_type,
       COALESCE(CAST(par.Description AS NVARCHAR(200)), N'—') AS reason_group,
       CAST(r.Description AS NVARCHAR(200)) AS reason,
       COUNT(*) AS rows_cnt,
       SUM(so.Quantity) AS quantity_sum,
       SUM(so.Amount) AS amount_sum
FROM dbo.bm_StorageOperations AS so
INNER JOIN dbo.bm_StorageOperationsType AS ot ON ot.ID = so.OperationID
INNER JOIN dbo.bm_ReasonDebit AS r ON r.ID = so.ReasonID
LEFT JOIN dbo.bm_ReasonDebit AS par ON par.ID = r.ParentID
WHERE so.ReasonID IS NOT NULL AND so.ReasonID <> 0
GROUP BY CAST(ot.Description AS NVARCHAR(200)), COALESCE(CAST(par.Description AS NVARCHAR(200)), N'—'), CAST(r.Description AS NVARCHAR(200))
ORDER BY amount_sum DESC;


-- Q5.7 Отмены и списания по чекам (wastemessages) по месяцам и причинам
-- Цель: Подтвердить, что wastemessages (≈3,6 тыс. строк) пригодна для анализа потерь, и сравнить с Q5.6.
-- Ожидание: Помесячная сводка по причинам; reason — свободный текст.
SELECT DATEFROMPARTS(YEAR(w.dater), MONTH(w.dater), 1) AS month_start,
       COALESCE(NULLIF(LTRIM(RTRIM(w.reason)), ''), N'(причина не указана)') AS reason,
       COUNT(*) AS msgs_cnt,
       SUM(w.quantity) AS quantity_sum,
       SUM(w.amount) AS amount_sum
FROM dbo.wastemessages AS w
GROUP BY DATEFROMPARTS(YEAR(w.dater), MONTH(w.dater), 1),
         COALESCE(NULLIF(LTRIM(RTRIM(w.reason)), ''), N'(причина не указана)')
ORDER BY month_start, amount_sum DESC;


-- Q5.8 Неликвиды: остаток есть, движений за 3 месяца нет
-- Цель: Практический результат анализа остатков: позиции, лежащие без движения 3 месяца от даты последней операции в БД.
-- Ожидание: ТОП-50 позиций с наибольшим остатком без движений.
WITH last_op AS (SELECT MAX(so.[DateAdd]) AS max_date FROM dbo.bm_StorageOperations AS so)
SELECT TOP 50
       p.id AS product_id, p.description AS product_name, p.onhand,
       p.lastreceived, p.lastsold
FROM dbo.product AS p
CROSS JOIN last_op AS lo
WHERE p.onhand > 0
  AND NOT EXISTS (SELECT 1 FROM dbo.bm_StorageOperations AS so
                  WHERE so.ProductID = p.id
                    AND so.[DateAdd] >= DATEADD(MONTH, -3, lo.max_date))
ORDER BY p.onhand DESC;
