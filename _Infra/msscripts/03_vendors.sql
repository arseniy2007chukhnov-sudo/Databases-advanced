-- База данных: Front (Microsoft SQL Server, схема dbo). Синтаксис T-SQL.
-- Запросы только читают данные (SELECT). Для скриншота выполняйте по одному.


-- ===== Группа 3: Анализ взаимоотношений с поставщиками =====


-- Q3.1 Наличие данных в таблицах группы
-- Цель: подтвердить, какие таблицы группы содержат данные, а какие пусты.
WITH tbl (table_name, role_in_group, sort_no) AS (
    SELECT * FROM (VALUES
        (N'vendors', N'основная', 1),
        (N'vendorgroup', N'основная', 1),
        (N'pricelist', N'основная', 1),
        (N'bm_StorageOperations', N'связанная', 2),
        (N'product', N'связанная', 2),
        (N'bm_JournalBarnetDocs', N'связанная', 2),
        (N'journal', N'связанная', 2),
        (N'stockperiod', N'связанная', 2),
        (N'bm_Companies', N'связанная', 2),
        (N'bm_Contracts', N'проверка наличия', 3),
        (N'bm_PaymentOperations', N'проверка наличия', 3),
        (N'bm_CashOperations', N'проверка наличия', 3),
        (N'complaince', N'проверка наличия', 3),
        (N'ordervendorinfo', N'проверка наличия', 3),
        (N'conversionvendors', N'проверка наличия', 3)
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


-- Q3.2 Поставщики по группам и полнота карточек
-- Цель: Подтвердить структуру справочника (FK vendors.clientgroup → vendorgroup) и оценить качество данных: сколько активных, у скольких заполнены ИНН, e-mail, телефон.
-- Ожидание: Строки по группам поставщиков; сумма vendors_cnt = 63. Низкие with_inn/with_email — риск для анализа.
SELECT COALESCE(vg.description, N'(без группы)') AS vendor_group,
       COUNT(*) AS vendors_cnt,
       SUM(CASE WHEN v.IsUse = 1 THEN 1 ELSE 0 END) AS active_cnt,
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(v.INN)), '') IS NOT NULL THEN 1 ELSE 0 END) AS with_inn,
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(v.emaliaddress)), '') IS NOT NULL THEN 1 ELSE 0 END) AS with_email,
       SUM(CASE WHEN NULLIF(LTRIM(RTRIM(v.teln)), '') IS NOT NULL THEN 1 ELSE 0 END) AS with_phone
FROM dbo.vendors AS v
LEFT JOIN dbo.vendorgroup AS vg ON vg.vendorgroupid = v.clientgroup
GROUP BY COALESCE(vg.description, N'(без группы)')
ORDER BY vendors_cnt DESC;


-- Q3.3 «Поставщик 360°»: закупки, прайсы, номенклатура по каждому поставщику
-- Цель: Свести все три следа поставщика в одну строку и увидеть поставщиков без связей (справочник есть, а работы с ним нет).
-- Ожидание: 63 строки; у активных поставщиков заполнены purchase_amount, price_positions, products_cnt. Нули/NULL — «спящие» поставщики.
WITH ops AS (
    SELECT so.VendorID, COUNT(DISTINCT so.DocumentID) AS docs_cnt, SUM(so.Amount) AS purchase_amount,
           MAX(so.[DateAdd]) AS last_purchase
    FROM dbo.bm_StorageOperations AS so
    INNER JOIN dbo.bm_StorageOperationsType AS ot ON ot.ID = so.OperationID
    WHERE ot.ID = 1   -- «Поступление»
    GROUP BY so.VendorID
),
prices AS (
    SELECT pl.vendorid, COUNT(*) AS price_positions, COUNT(DISTINCT pl.DocumentID) AS pricelists_cnt,
           MAX(pl.dateeff) AS last_price_date
    FROM dbo.pricelist AS pl
    GROUP BY pl.vendorid
),
prods AS (
    SELECT p.vendorid, COUNT(*) AS products_cnt
    FROM dbo.product AS p
    GROUP BY p.vendorid
)
SELECT v.id, v.clientid, COALESCE(NULLIF(LTRIM(RTRIM(v.lastname)), ''), v.clientid) AS vendor_name,
       COALESCE(ops.docs_cnt, 0) AS docs_cnt,
       COALESCE(ops.purchase_amount, 0) AS purchase_amount,
       ops.last_purchase,
       COALESCE(prices.price_positions, 0) AS price_positions,
       prices.last_price_date,
       COALESCE(prods.products_cnt, 0) AS products_cnt
FROM dbo.vendors AS v
LEFT JOIN ops ON ops.VendorID = v.id
LEFT JOIN prices ON prices.vendorid = v.id
LEFT JOIN prods ON prods.vendorid = v.id
ORDER BY purchase_amount DESC, v.id;


-- Q3.4 Концентрация закупок: ABC/Парето по поставщикам
-- Цель: Оценить зависимость от поставщиков: доля каждого и накопительная доля с классами A (до 80 %), B (до 95 %), C.
-- Ожидание: Несколько поставщиков класса A дают основную долю закупок.
WITH purchase AS (
    SELECT so.DocumentID, so.VendorID, so.ProductID, so.Price, so.Quantity, so.[Count] AS pieces, so.Amount, so.[DateAdd] AS op_date
    FROM dbo.bm_StorageOperations AS so
    INNER JOIN dbo.bm_StorageOperationsType AS ot ON ot.ID = so.OperationID
    WHERE ot.ID = 1                           -- «Поступление» (тип 3 «Инвентаризация» тоже Factor = 1, поэтому по знаку не отбираем)
      AND so.VendorID IS NOT NULL AND so.VendorID <> 0   -- с указанным поставщиком
),
by_vendor AS (
    SELECT VendorID, SUM(Amount) AS amount_sum, COUNT(DISTINCT DocumentID) AS docs_cnt
    FROM purchase
    GROUP BY VendorID
),
shares AS (
    SELECT bv.VendorID, bv.amount_sum, bv.docs_cnt,
           100.0 * bv.amount_sum / SUM(bv.amount_sum) OVER () AS share_pct,
           100.0 * SUM(bv.amount_sum) OVER (ORDER BY bv.amount_sum DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                 / SUM(bv.amount_sum) OVER () AS cum_share_pct
    FROM by_vendor AS bv
)
SELECT RANK() OVER (ORDER BY s.amount_sum DESC) AS rnk,
       v.clientid, COALESCE(NULLIF(LTRIM(RTRIM(v.lastname)), ''), v.clientid) AS vendor_name, s.docs_cnt, s.amount_sum,
       CAST(s.share_pct AS DECIMAL(5, 2)) AS share_pct,
       CAST(s.cum_share_pct AS DECIMAL(5, 2)) AS cum_share_pct,
       CASE WHEN s.cum_share_pct <= 80 THEN 'A' WHEN s.cum_share_pct <= 95 THEN 'B' ELSE 'C' END AS abc_class
FROM shares AS s
LEFT JOIN dbo.vendors AS v ON v.id = s.VendorID
ORDER BY rnk;


-- Q3.5 Целостность ссылок на поставщика (FK не объявлены)
-- Цель: Подтвердить, что логические связи с vendors.id корректны, и показать «осиротевшие» ссылки.
-- Ожидание: Все orphan = 0 подтверждают логический FK; ненулевые значения — дефекты данных, которые нужно учитывать в отчётах.
SELECT N'bm_StorageOperations.VendorID не найден в vendors.id' AS check_name, COUNT(*) AS bad_rows
FROM dbo.bm_StorageOperations AS so
LEFT JOIN dbo.vendors AS v ON v.id = so.VendorID
WHERE so.VendorID IS NOT NULL AND so.VendorID <> 0 AND v.id IS NULL
UNION ALL
SELECT N'pricelist.vendorid не найден в vendors.id', COUNT(*)
FROM dbo.pricelist AS pl
LEFT JOIN dbo.vendors AS v ON v.id = pl.vendorid
WHERE pl.vendorid IS NOT NULL AND pl.vendorid <> 0 AND v.id IS NULL
UNION ALL
SELECT N'product.vendorid не найден в vendors.id', COUNT(*)
FROM dbo.product AS p
LEFT JOIN dbo.vendors AS v ON v.id = p.vendorid
WHERE p.vendorid IS NOT NULL AND p.vendorid <> 0 AND v.id IS NULL
UNION ALL
SELECT N'Поставщики без единой связи (ни закупок, ни прайса, ни товаров)', COUNT(*)
FROM dbo.vendors AS v
WHERE NOT EXISTS (SELECT 1 FROM dbo.bm_StorageOperations AS so WHERE so.VendorID = v.id)
  AND NOT EXISTS (SELECT 1 FROM dbo.pricelist AS pl WHERE pl.vendorid = v.id)
  AND NOT EXISTS (SELECT 1 FROM dbo.product AS p WHERE p.vendorid = v.id);
