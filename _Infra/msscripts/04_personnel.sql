-- База данных: Front (Microsoft SQL Server, схема dbo). Синтаксис T-SQL.
-- Запросы только читают данные (SELECT). Для скриншота выполняйте по одному.


-- ===== Группа 4: Анализ работы персонала =====


-- Q4.1 Наличие данных в таблицах группы
-- Цель: подтвердить, какие таблицы группы содержат данные, а какие пусты.
WITH tbl (table_name, role_in_group, sort_no) AS (
    SELECT * FROM (VALUES
        (N'personnel', N'основная', 1),
        (N'bm_PersonnelSecurity', N'основная', 1),
        (N'bm_JournalSessions', N'основная', 1),
        (N'securityaccess', N'связанная', 2),
        (N'bm_SecurityObjects', N'связанная', 2),
        (N'bm_SecurityObjects_Info', N'связанная', 2),
        (N'bm_BonusHistory', N'связанная', 2),
        (N'bm_JournalBarnetDocs', N'связанная', 2),
        (N'journal', N'связанная', 2),
        (N'wastemessages', N'связанная', 2),
        (N'bm_ShiftsOperations', N'связанная', 2),
        (N'bm_TicketLoadInfo_History', N'связанная', 2),
        (N'bm_WorkHours', N'проверка наличия', 3)
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


-- Q4.2 Сотрудники по уровням доступа и правам
-- Цель: Подтвердить справочник персонала и связку personnel.securityaccess → securityaccess; оценить, сколько сотрудников активно и какие у них флаги прав.
-- Ожидание: Строки по уровням доступа; сумма employees_cnt = 109. (Допущение: deleteflag = 1 — сотрудник удалён.)
SELECT COALESCE(CAST(sa.description AS NVARCHAR(100)), N'(уровень не задан)') AS access_level,
       COUNT(*) AS employees_cnt,
       SUM(CASE WHEN COALESCE(p.deleteflag, 0) = 0 THEN 1 ELSE 0 END) AS active_cnt,
       SUM(CAST(COALESCE(p.flagsales, 0) AS INT)) AS can_sell,
       SUM(CAST(COALESCE(p.flagrefunds, 0) AS INT)) AS can_refund,
       SUM(CAST(COALESCE(p.flagdiscounts, 0) AS INT)) AS can_discount,
       SUM(CAST(COALESCE(p.bartender, 0) AS INT)) AS bartenders
FROM dbo.personnel AS p
LEFT JOIN dbo.securityaccess AS sa ON sa.securityaccessid = p.securityaccess
GROUP BY COALESCE(CAST(sa.description AS NVARCHAR(100)), N'(уровень не задан)')
ORDER BY employees_cnt DESC;


-- Q4.3 Матрица прав: число выданных прав у каждого сотрудника
-- Цель: Подтвердить связь bm_PersonnelSecurity → personnel (логическая) и → bm_SecurityObjects (FK).
-- Ожидание: 109 строк; у большинства сотрудников есть права; сотрудники с granted_cnt = 0 — без прав в системе.
WITH perm AS (
    SELECT ps.PersonID,
           COUNT(*) AS objects_cnt,
           SUM(CASE WHEN ps.IsUse = 1 THEN 1 ELSE 0 END) AS granted_cnt
    FROM dbo.bm_PersonnelSecurity AS ps
    INNER JOIN dbo.bm_SecurityObjects AS so ON so.ID = ps.ObjectID
    GROUP BY ps.PersonID
)
SELECT RANK() OVER (ORDER BY COALESCE(perm.granted_cnt, 0) DESC) AS rnk,
       p.personid, CONCAT(p.lastname, ' ', p.firstname) AS employee,
       COALESCE(perm.objects_cnt, 0) AS objects_cnt,
       COALESCE(perm.granted_cnt, 0) AS granted_cnt
FROM dbo.personnel AS p
LEFT JOIN perm ON perm.PersonID = p.personid
ORDER BY rnk, p.personid;


-- Q4.4 Активность сотрудника: документы, события приложения, бонусы
-- Цель: Свести «следы работы» из трёх таблиц с объявленным/логическим PersonID и найти сотрудников без активности.
-- Ожидание: Строки по сотрудникам с числом документов, событий, доли ошибок и бонусных операций. Нули — нет активности.
WITH docs AS (
    SELECT d.PersonID, COUNT(*) AS docs_cnt, SUM(d.Amount) AS docs_amount, MAX(d.[DateAdd]) AS last_doc
    FROM dbo.bm_JournalBarnetDocs AS d
    GROUP BY d.PersonID
),
sessions AS (
    SELECT s.PersonID, COUNT(*) AS events_cnt, SUM(CASE WHEN s.IsError = 1 THEN 1 ELSE 0 END) AS errors_cnt
    FROM dbo.bm_JournalSessions AS s
    GROUP BY s.PersonID
),
bonus AS (
    SELECT b.PersonID, COUNT(*) AS bonus_ops, SUM(b.BonusValue) AS bonus_sum
    FROM dbo.bm_BonusHistory AS b
    GROUP BY b.PersonID
)
SELECT p.personid, CONCAT(p.lastname, ' ', p.firstname) AS employee,
       COALESCE(docs.docs_cnt, 0) AS docs_cnt,
       COALESCE(docs.docs_amount, 0) AS docs_amount,
       docs.last_doc,
       COALESCE(sessions.events_cnt, 0) AS events_cnt,
       COALESCE(sessions.errors_cnt, 0) AS errors_cnt,
       CAST(100.0 * COALESCE(sessions.errors_cnt, 0) / NULLIF(sessions.events_cnt, 0) AS DECIMAL(5, 1)) AS error_pct,
       COALESCE(bonus.bonus_ops, 0) AS bonus_ops,
       COALESCE(bonus.bonus_sum, 0) AS bonus_sum
FROM dbo.personnel AS p
LEFT JOIN docs ON docs.PersonID = p.personid
LEFT JOIN sessions ON sessions.PersonID = p.personid
LEFT JOIN bonus ON bonus.PersonID = p.personid
ORDER BY docs_cnt DESC, events_cnt DESC;


-- Q4.5 Выручка и средний чек по кассирам (journal.loginid)
-- Цель: Оценить работу персонала по продажам: выручка, чеки, средний чек, скидки, возвраты, ранг.
-- Ожидание: ТОП-30 кассиров. Если employee пуст, то loginid не равен personid — тогда ориентируйтесь на результат Q4.6.
WITH by_login AS (
    SELECT LTRIM(RTRIM(j.loginid)) AS loginid,
           COUNT(DISTINCT j.receiptn) AS receipts_cnt,
           SUM(j.amount) AS revenue,
           SUM(j.discountamount) AS discount_sum,
           SUM(CASE WHEN j.flagrefund = 1 THEN 1 ELSE 0 END) AS refund_lines
    FROM dbo.journal AS j
    GROUP BY LTRIM(RTRIM(j.loginid))
)
SELECT TOP 30
       RANK() OVER (ORDER BY bl.revenue DESC) AS rnk,
       bl.loginid, CONCAT(p.lastname, ' ', p.firstname) AS employee,
       bl.receipts_cnt, bl.revenue,
       CAST(bl.revenue / NULLIF(bl.receipts_cnt, 0) AS DECIMAL(12, 2)) AS avg_check,
       CAST(100.0 * bl.discount_sum / NULLIF(bl.revenue + bl.discount_sum, 0) AS DECIMAL(5, 2)) AS discount_pct,
       bl.refund_lines
FROM by_login AS bl
LEFT JOIN dbo.personnel AS p ON CAST(p.personid AS VARCHAR(13)) = bl.loginid
ORDER BY rnk;


-- Q4.6 Документы по сменам
-- Цель: Подтвердить FK bm_JournalBarnetDocs.ShiftID → bm_ShiftsOperations.ID и показать, насколько смены используются (в таблице смен всего одна запись).
-- Ожидание: Одна строка со сменой и строка «документ без смены» — подтверждает, что сменный учёт почти не ведётся.
SELECT COALESCE(CAST(sh.ShiftNumber AS NVARCHAR(50)), N'(документ без смены)') AS shift_number,
       COUNT(*) AS docs_cnt,
       SUM(d.Amount) AS docs_amount,
       MIN(d.[DateAdd]) AS first_doc,
       MAX(d.[DateAdd]) AS last_doc
FROM dbo.bm_JournalBarnetDocs AS d
LEFT JOIN dbo.bm_ShiftsOperations AS sh ON sh.ID = d.ShiftID
GROUP BY COALESCE(CAST(sh.ShiftNumber AS NVARCHAR(50)), N'(документ без смены)')
ORDER BY docs_cnt DESC;
