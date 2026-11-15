-- База данных: Front (Microsoft SQL Server, схема dbo). Синтаксис T-SQL.
-- Запросы только читают данные (SELECT). Для скриншота выполняйте по одному.


-- ===== Группа 1: Анализ закупки продукции =====


-- Q1.1 Наличие данных в таблицах группы
-- Цель: подтвердить, какие таблицы группы содержат данные, а какие пусты.
WITH tbl (table_name, role_in_group, sort_no) AS (
    SELECT * FROM (VALUES
        (N'bm_StorageOperations', N'основная', 1),
        (N'bm_JournalBarnetDocs', N'основная', 1),
        (N'pricelist', N'основная', 1),
        (N'bm_StorageOperationsType', N'связанная', 2),
        (N'bm_JournalTypeDocuments', N'связанная', 2),
        (N'bm_JournalType', N'связанная', 2),
        (N'vendors', N'связанная', 2),
        (N'product', N'связанная', 2),
        (N'category', N'связанная', 2),
        (N'size', N'связанная', 2),
        (N'storages', N'связанная', 2),
        (N'bm_Companies', N'связанная', 2),
        (N'bm_ReasonDebit', N'связанная', 2),
        (N'bm_Contracts', N'связанная (проверка наличия)', 3),
        (N'receiving', N'устаревшая', 3),
        (N'orders', N'устаревшая', 3),
        (N'ordervendorinfo', N'связанная (проверка наличия)', 3)
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


-- Q1.2 Виды складских операций и их объём
-- Цель: Подтвердить, где хранится приход: какие виды операций есть, какой у них знак (Factor), сколько строк/документов и за какой период.
-- Ожидание: 5 видов операций (по bm_StorageOperationsType); приходные имеют Factor = 1. Именно по ним в Q1.4–Q1.6 считается закупка.
SELECT ot.ID AS operation_type_id,
       CAST(ot.Description AS NVARCHAR(200)) AS operation_type,
       ot.Factor,
       COUNT(*) AS rows_cnt,
       COUNT(DISTINCT so.DocumentID) AS docs_cnt,
       SUM(so.Quantity) AS quantity_sum,
       SUM(so.Amount) AS amount_sum,
       MIN(so.[DateAdd]) AS first_date,
       MAX(so.[DateAdd]) AS last_date
FROM dbo.bm_StorageOperations AS so
INNER JOIN dbo.bm_StorageOperationsType AS ot ON ot.ID = so.OperationID
GROUP BY ot.ID, CAST(ot.Description AS NVARCHAR(200)), ot.Factor
ORDER BY ot.ID;


-- Q1.3 Типы документов и доля документов со складскими движениями
-- Цель: Подтвердить связку «документ → тип документа → журнал» и выяснить, какие типы документов порождают движения по складу (то есть являются закупочными).
-- Ожидание: Типы документов (приходная накладная и т.п.) с ненулевым docs_with_storage_ops; типы с нулём — это не складские документы (прайс-листы, рецептуры, кассовые).
WITH docs_with_ops AS (
    SELECT DISTINCT DocumentID FROM dbo.bm_StorageOperations
)
SELECT CAST(jt.JournalName AS NVARCHAR(200)) AS journal_name,
       CAST(td.Description AS NVARCHAR(200)) AS document_type,
       COUNT(*) AS docs_cnt,
       COUNT(dwo.DocumentID) AS docs_with_storage_ops,
       SUM(d.Amount) AS amount_sum,
       MIN(d.Period) AS first_period,
       MAX(d.Period) AS last_period
FROM dbo.bm_JournalBarnetDocs AS d
INNER JOIN dbo.bm_JournalTypeDocuments AS td ON td.ID = d.DocumentTypeID
INNER JOIN dbo.bm_JournalType AS jt ON jt.ID = d.JournalID
LEFT JOIN docs_with_ops AS dwo ON dwo.DocumentID = d.ID
GROUP BY CAST(jt.JournalName AS NVARCHAR(200)), CAST(td.Description AS NVARCHAR(200))
ORDER BY docs_cnt DESC;


-- Q1.4 Закупки по месяцам (динамика)
-- Примечание: в выборке Quantity = 0 при Amount > 0, поэтому добавлена pieces_sum (колонка Count) — сверьте, какая из них несёт количество.
-- Цель: Показать, что закупочные данные пригодны для анализа во времени: число документов, поставщиков, товаров, сумма и прирост к предыдущему месяцу (оконная функция LAG).
-- Ожидание: Непрерывный ряд месяцев; growth_pct пуст только в первом месяце.
WITH purchase AS (
    SELECT so.DocumentID, so.VendorID, so.ProductID, so.Price, so.Quantity, so.[Count] AS pieces, so.Amount, so.[DateAdd] AS op_date
    FROM dbo.bm_StorageOperations AS so
    INNER JOIN dbo.bm_StorageOperationsType AS ot ON ot.ID = so.OperationID
    WHERE ot.ID = 1                           -- «Поступление» (тип 3 «Инвентаризация» тоже Factor = 1, поэтому по знаку не отбираем)
      AND so.VendorID IS NOT NULL AND so.VendorID <> 0   -- с указанным поставщиком
),
monthly AS (
    SELECT DATEFROMPARTS(YEAR(op_date), MONTH(op_date), 1) AS month_start,
           COUNT(DISTINCT DocumentID) AS docs_cnt,
           COUNT(DISTINCT VendorID) AS vendors_cnt,
           COUNT(DISTINCT ProductID) AS products_cnt,
           SUM(Quantity) AS quantity_sum,
           SUM(pieces) AS pieces_sum,
           SUM(Amount) AS amount_sum
    FROM purchase
    GROUP BY DATEFROMPARTS(YEAR(op_date), MONTH(op_date), 1)
)
SELECT m.month_start, m.docs_cnt, m.vendors_cnt, m.products_cnt, m.quantity_sum, m.pieces_sum, m.amount_sum,
       LAG(m.amount_sum) OVER (ORDER BY m.month_start) AS prev_amount,
       CAST(100.0 * (m.amount_sum - LAG(m.amount_sum) OVER (ORDER BY m.month_start))
            / NULLIF(LAG(m.amount_sum) OVER (ORDER BY m.month_start), 0) AS DECIMAL(10, 1)) AS growth_pct
FROM monthly AS m
ORDER BY m.month_start;


-- Q1.5 ТОП-20 закупаемых товаров (ABC-доля)
-- Цель: Подтвердить связь движений с номенклатурой и категориями (product, category) и получить структуру закупки по товарам с рангом и долей.
-- Ожидание: 20 строк: у каждой заполнены наименование и категория; share_pct убывает по рангу.
WITH purchase AS (
    SELECT so.DocumentID, so.VendorID, so.ProductID, so.Price, so.Quantity, so.[Count] AS pieces, so.Amount, so.[DateAdd] AS op_date
    FROM dbo.bm_StorageOperations AS so
    INNER JOIN dbo.bm_StorageOperationsType AS ot ON ot.ID = so.OperationID
    WHERE ot.ID = 1                           -- «Поступление» (тип 3 «Инвентаризация» тоже Factor = 1, поэтому по знаку не отбираем)
      AND so.VendorID IS NOT NULL AND so.VendorID <> 0   -- с указанным поставщиком
),
by_product AS (
    SELECT ProductID, SUM(Quantity) AS quantity_sum, SUM(pieces) AS pieces_sum, SUM(Amount) AS amount_sum,
           COUNT(*) AS rows_cnt, MAX(op_date) AS last_purchase
    FROM purchase
    GROUP BY ProductID
)
SELECT TOP 20
       RANK() OVER (ORDER BY bp.amount_sum DESC) AS rnk,
       bp.ProductID, p.description AS product_name, c.description AS category,
       bp.quantity_sum, bp.pieces_sum, bp.amount_sum, bp.rows_cnt, bp.last_purchase,
       CAST(100.0 * bp.amount_sum / SUM(bp.amount_sum) OVER () AS DECIMAL(5, 2)) AS share_pct
FROM by_product AS bp
INNER JOIN dbo.product AS p ON p.id = bp.ProductID
LEFT JOIN dbo.category AS c ON c.id = p.CategoryID
ORDER BY rnk;


-- Q1.6 Прайс-лист поставщика против фактической закупочной цены
-- Цель: Подтвердить, что pricelist и bm_StorageOperations описывают одни и те же пары «товар — поставщик», и найти расхождения цен.
-- Ожидание: Строки с парами, найденными в обоих источниках; diff_pct показывает отклонение факта от последнего прайса. Пустой результат означал бы, что pricelist.vendorid не соответствует vendors.id.
WITH last_price AS (
    SELECT pl.productid, pl.vendorid, pl.basecost, pl.dateeff,
           ROW_NUMBER() OVER (PARTITION BY pl.productid, pl.vendorid
                              ORDER BY pl.dateeff DESC, pl.id DESC) AS rn
    FROM dbo.pricelist AS pl
),
purchase AS (
    SELECT so.DocumentID, so.VendorID, so.ProductID, so.Price, so.Quantity, so.[Count] AS pieces, so.Amount, so.[DateAdd] AS op_date
    FROM dbo.bm_StorageOperations AS so
    INNER JOIN dbo.bm_StorageOperationsType AS ot ON ot.ID = so.OperationID
    WHERE ot.ID = 1                           -- «Поступление» (тип 3 «Инвентаризация» тоже Factor = 1, поэтому по знаку не отбираем)
      AND so.VendorID IS NOT NULL AND so.VendorID <> 0   -- с указанным поставщиком
),
avg_purchase AS (
    SELECT ProductID, VendorID, AVG(Price) AS avg_price, COUNT(*) AS rows_cnt
    FROM purchase
    GROUP BY ProductID, VendorID
)
SELECT TOP 50
       p.description AS product_name, COALESCE(NULLIF(LTRIM(RTRIM(v.lastname)), ''), v.clientid) AS vendor_name,
       lp.basecost AS pricelist_price, lp.dateeff AS pricelist_date,
       ap.avg_price AS avg_purchase_price, ap.rows_cnt,
       CAST(100.0 * (ap.avg_price - lp.basecost) / NULLIF(lp.basecost, 0) AS DECIMAL(10, 1)) AS diff_pct
FROM avg_purchase AS ap
INNER JOIN last_price AS lp ON lp.productid = ap.ProductID AND lp.vendorid = ap.VendorID AND lp.rn = 1
INNER JOIN dbo.product AS p ON p.id = ap.ProductID
INNER JOIN dbo.vendors AS v ON v.id = ap.VendorID
ORDER BY ABS(CAST(100.0 * (ap.avg_price - lp.basecost) / NULLIF(lp.basecost, 0) AS DECIMAL(10, 1))) DESC;


-- Q1.7 Проверка целостности закупочных данных
-- Цель: Количественно подтвердить, какие связи работают, а какие «висят» (FK не объявлены для VendorID, ContractID).
-- Ожидание: orphan для документа/товара/склада = 0 (FK объявлены); для поставщика — 0, если логическая связь с vendors.id верна; ContractID заполнен — не должен, так как bm_Contracts пуста.
SELECT N'Движения без документа' AS check_name, COUNT(*) AS bad_rows
FROM dbo.bm_StorageOperations AS so
LEFT JOIN dbo.bm_JournalBarnetDocs AS d ON d.ID = so.DocumentID
WHERE d.ID IS NULL
UNION ALL
SELECT N'Движения с поставщиком, которого нет в vendors', COUNT(*)
FROM dbo.bm_StorageOperations AS so
LEFT JOIN dbo.vendors AS v ON v.id = so.VendorID
WHERE so.VendorID IS NOT NULL AND so.VendorID <> 0 AND v.id IS NULL
UNION ALL
SELECT N'Движения с товаром, которого нет в product', COUNT(*)
FROM dbo.bm_StorageOperations AS so
LEFT JOIN dbo.product AS p ON p.id = so.ProductID
WHERE p.id IS NULL
UNION ALL
SELECT N'Движения со складом, которого нет в storages', COUNT(*)
FROM dbo.bm_StorageOperations AS so
LEFT JOIN dbo.storages AS s ON s.id = so.StorageID
WHERE s.id IS NULL
UNION ALL
SELECT N'Движения с заполненным ContractID (bm_Contracts пуста)', COUNT(*)
FROM dbo.bm_StorageOperations AS so
WHERE so.ContractID IS NOT NULL AND so.ContractID <> 0
UNION ALL
SELECT N'Строки прайс-листа с поставщиком, которого нет в vendors', COUNT(*)
FROM dbo.pricelist AS pl
LEFT JOIN dbo.vendors AS v ON v.id = pl.vendorid
WHERE pl.vendorid IS NOT NULL AND pl.vendorid <> 0 AND v.id IS NULL;
