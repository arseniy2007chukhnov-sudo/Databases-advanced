-- База данных: Front (Microsoft SQL Server, схема dbo). Синтаксис T-SQL.
-- Запросы только читают данные (SELECT). Для скриншота выполняйте по одному.


-- ===== Группа 2: Анализ продажи товара =====


-- Q2.1 Наличие данных в таблицах группы
-- Цель: подтвердить, какие таблицы группы содержат данные, а какие пусты.
WITH tbl (table_name, role_in_group, sort_no) AS (
    SELECT * FROM (VALUES
        (N'journal', N'основная', 1),
        (N'bm_Journal_Details', N'основная', 1),
        (N'bm_JournalBarnetDocs', N'основная', 1),
        (N'transtype', N'связанная', 2),
        (N'product', N'связанная', 2),
        (N'category', N'связанная', 2),
        (N'size', N'связанная', 2),
        (N'clients', N'связанная', 2),
        (N'clientgroup', N'связанная', 2),
        (N'recipe', N'связанная', 2),
        (N'bm_BonusHistory', N'связанная', 2),
        (N'bm_BarnetPortal_ExportHistory', N'связанная', 2),
        (N'paymenttype', N'связанная', 2),
        (N'wastemessages', N'связанная', 2),
        (N'PreReceipt', N'связанная', 2),
        (N'bm_PaymentOperations', N'связанная (проверка наличия)', 3),
        (N'journala', N'архив формата journal', 3),
        (N'journalday', N'архив формата journal', 3),
        (N'salestmp1', N'временная', 3)
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


-- Q2.2 Типы операций журнала
-- Цель: Подтвердить структуру журнала продаж: какие типы операций есть (продажа, возврат, оплата и т.д.), их объём и период.
-- Ожидание: Список типов с описанием из transtype. Код типа «продажа» используется как параметр @transtype в Q2.3 и Q2.4.
SELECT j.transtype,
       CAST(tt.description AS NVARCHAR(200)) AS transtype_name,
       tt.transgroupid,
       COUNT(*) AS lines_cnt,
       COUNT(DISTINCT j.receiptn) AS receipts_cnt,
       SUM(j.quantity) AS quantity_sum,
       SUM(j.amount) AS amount_sum,
       MIN(j.dater) AS first_date,
       MAX(j.dater) AS last_date
FROM dbo.journal AS j
INNER JOIN dbo.transtype AS tt ON tt.transtypeid = j.transtype
GROUP BY j.transtype, CAST(tt.description AS NVARCHAR(200)), tt.transgroupid
ORDER BY amount_sum DESC;


-- Q2.3 Выручка, чеки и средний чек по месяцам
-- Цель: Подтвердить пригодность журнала для анализа динамики: выручка, число чеков, средний чек, скидки и прирост к предыдущему месяцу.
-- Ожидание: Ряд месяцев; avg_check = revenue / receipts_cnt. @transtype = NULL — все типы; подставьте код продажи из Q2.2.
DECLARE @transtype INT = NULL;   -- код типа «продажа» из Q2.2 (NULL = все типы)

WITH sales AS (
    SELECT j.receiptn, j.dater, j.quantity, j.amount, j.discountamount
    FROM dbo.journal AS j
    WHERE @transtype IS NULL OR j.transtype = @transtype
),
monthly AS (
    SELECT DATEFROMPARTS(YEAR(s.dater), MONTH(s.dater), 1) AS month_start,
           COUNT(DISTINCT s.receiptn) AS receipts_cnt,
           SUM(s.quantity) AS quantity_sum,
           SUM(s.amount) AS revenue,
           SUM(s.discountamount) AS discount_sum
    FROM sales AS s
    GROUP BY DATEFROMPARTS(YEAR(s.dater), MONTH(s.dater), 1)
)
SELECT m.month_start, m.receipts_cnt, m.quantity_sum, m.revenue, m.discount_sum,
       CAST(m.revenue / NULLIF(m.receipts_cnt, 0) AS DECIMAL(12, 2)) AS avg_check,
       CAST(100.0 * (m.revenue - LAG(m.revenue) OVER (ORDER BY m.month_start))
            / NULLIF(LAG(m.revenue) OVER (ORDER BY m.month_start), 0) AS DECIMAL(10, 1)) AS growth_pct
FROM monthly AS m
ORDER BY m.month_start;


-- Q2.4 ТОП-20 продаваемых товаров с накопительной долей (ABC)
-- Цель: Подтвердить логическую связь journal.id = product.productid и категорий (product → category), получить ABC-структуру продаж.
-- Ожидание: 20 строк с наименованием и категорией; cum_share_pct растёт к 100 %. Строки с пустым product_name означали бы нарушение связи по коду.
DECLARE @transtype INT = NULL;   -- код типа «продажа» из Q2.2

WITH sales AS (
    SELECT j.id AS product_code, j.receiptn, j.quantity, j.amount
    FROM dbo.journal AS j
    WHERE @transtype IS NULL OR j.transtype = @transtype
),
by_product AS (
    SELECT s.product_code, SUM(s.quantity) AS quantity_sum, SUM(s.amount) AS revenue,
           COUNT(DISTINCT s.receiptn) AS receipts_cnt
    FROM sales AS s
    GROUP BY s.product_code
)
SELECT TOP 20
       RANK() OVER (ORDER BY bp.revenue DESC) AS rnk,
       bp.product_code, p.description AS product_name, c.description AS category,
       bp.quantity_sum, bp.revenue, bp.receipts_cnt,
       CAST(100.0 * SUM(bp.revenue) OVER (ORDER BY bp.revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            / SUM(bp.revenue) OVER () AS DECIMAL(5, 2)) AS cum_share_pct
FROM by_product AS bp
LEFT JOIN dbo.product AS p ON p.productid = bp.product_code
LEFT JOIN dbo.category AS c ON c.id = p.CategoryID
ORDER BY rnk;


-- Q2.5 Связь строк журнала с расшифровкой bm_Journal_Details
-- Цель: Подтвердить FK bm_Journal_Details.SourceID → journal.transnumber и объём расшифровки (блюдо/ингредиент).
-- Ожидание: Расшифровок ≈ 1,09 млн на ≈ 225 тыс. строк журнала; «без родителя» = 0.
SELECT N'Строк в journal' AS metric, COUNT(*) AS value FROM dbo.journal
UNION ALL
SELECT N'Строк в bm_Journal_Details', COUNT(*) FROM dbo.bm_Journal_Details
UNION ALL
SELECT N'Строк journal, у которых есть расшифровка', COUNT(DISTINCT d.SourceID) FROM dbo.bm_Journal_Details AS d
UNION ALL
SELECT N'Расшифровок без строки в journal', COUNT(*)
FROM dbo.bm_Journal_Details AS d
LEFT JOIN dbo.journal AS j ON j.transnumber = d.SourceID
WHERE j.transnumber IS NULL
UNION ALL
SELECT N'Расшифровок с указанным блюдом (BludoID)', COUNT(*)
FROM dbo.bm_Journal_Details AS d
WHERE d.BludoID IS NOT NULL AND d.BludoID <> 0
UNION ALL
SELECT N'Различных блюд в расшифровках', COUNT(DISTINCT d.BludoID) FROM dbo.bm_Journal_Details AS d;


-- Q2.6 Проверка связи по номеру чека (TicketNumber)
-- Цель: Определить, с каким полем журнала (receiptn или transnumber) совпадает TicketNumber в документах, истории выгрузки и бонусах, — FK для этих связей не объявлен.
-- Ожидание: Высокий matched_pct у одной из двух строк для каждой таблицы — это и есть реальный ключ связи; используйте его в ER и отчётах.
WITH j_receipt AS (SELECT DISTINCT CAST(receiptn AS BIGINT) AS n FROM dbo.journal),
j_trans AS (SELECT DISTINCT CAST(transnumber AS BIGINT) AS n FROM dbo.journal),
docs AS (SELECT DISTINCT CAST(TicketNumber AS BIGINT) AS n FROM dbo.bm_JournalBarnetDocs
         WHERE TicketNumber IS NOT NULL AND TicketNumber <> 0),
exp_hist AS (SELECT DISTINCT TicketNumber AS n FROM dbo.bm_BarnetPortal_ExportHistory),
bonus AS (SELECT DISTINCT CAST(TicketNumber AS BIGINT) AS n FROM dbo.bm_BonusHistory
          WHERE ISNUMERIC(TicketNumber) = 1),
links AS (
    SELECT N'bm_JournalBarnetDocs → journal.receiptn' AS link_name, d.n, jr.n AS hit FROM docs AS d LEFT JOIN j_receipt AS jr ON jr.n = d.n
    UNION ALL
    SELECT N'bm_JournalBarnetDocs → journal.transnumber', d.n, jt.n FROM docs AS d LEFT JOIN j_trans AS jt ON jt.n = d.n
    UNION ALL
    SELECT N'bm_BarnetPortal_ExportHistory → journal.receiptn', e.n, jr.n FROM exp_hist AS e LEFT JOIN j_receipt AS jr ON jr.n = e.n
    UNION ALL
    SELECT N'bm_BarnetPortal_ExportHistory → journal.transnumber', e.n, jt.n FROM exp_hist AS e LEFT JOIN j_trans AS jt ON jt.n = e.n
    UNION ALL
    SELECT N'bm_BonusHistory → journal.receiptn', b.n, jr.n FROM bonus AS b LEFT JOIN j_receipt AS jr ON jr.n = b.n
    UNION ALL
    SELECT N'bm_BonusHistory → journal.transnumber', b.n, jt.n FROM bonus AS b LEFT JOIN j_trans AS jt ON jt.n = b.n
)
SELECT l.link_name,
       COUNT(*) AS distinct_tickets,
       SUM(CASE WHEN l.hit IS NOT NULL THEN 1 ELSE 0 END) AS matched,
       CAST(100.0 * SUM(CASE WHEN l.hit IS NOT NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5, 1)) AS matched_pct
FROM links AS l
GROUP BY l.link_name
ORDER BY l.link_name;


-- Q2.7 Продажи по группам клиентов
-- Цель: Подтвердить логическую связь journal.customerid = clients.clientid и FK clients → clientgroup.
-- Ожидание: Строки по группам клиентов и строка «клиент не найден / без группы». Если почти вся выручка — в последней строке, то чеки по клиентам оформляются редко или связь иная.
WITH s AS (
    SELECT j.receiptn, j.customerid, j.amount, j.discountamount
    FROM dbo.journal AS j
    WHERE j.customerid IS NOT NULL AND LTRIM(RTRIM(j.customerid)) <> ''
)
SELECT COALESCE(CAST(cg.description AS NVARCHAR(100)), N'(клиент не найден / без группы)') AS client_group,
       COUNT(DISTINCT s.customerid) AS clients_cnt,
       COUNT(DISTINCT s.receiptn) AS receipts_cnt,
       SUM(s.amount) AS revenue,
       SUM(s.discountamount) AS discount_sum
FROM s
LEFT JOIN dbo.clients AS c ON c.clientid = s.customerid
LEFT JOIN dbo.clientgroup AS cg ON cg.clientgroupid = c.clientgroup
GROUP BY COALESCE(CAST(cg.description AS NVARCHAR(100)), N'(клиент не найден / без группы)')
ORDER BY revenue DESC;
