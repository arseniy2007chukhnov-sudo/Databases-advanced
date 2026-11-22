-- ОБЩИЕ РЕСУРСЫ (закупки, продажи, остатки)


-- 1. Единицы измерения -> res_units
select id, sizeid as name, portionrate as factor
from [size] 
order by id;

-- 2. Категории -> res_categories (ParentID = 0 -> NULL)
select c.id, c.description as name, p.id as parent_id
from category c
    left join category p on p.id = c.ParentID
order by c.id;

-- 3. Номенклатура -> res_products (vendorid = 0 - "нет поставщика" -> NULL)
select p.id,
       p.productid   as code,
       p.description as name,
       c.id          as category_id,
       v.id          as vendor_id,
       case when coalesce(p.IsUse, 1) = 0 then 0 else 1 end as is_active
from product p
    left join category c on c.id = p.CategoryID
    left join vendors  v on v.id = p.vendorid
order by p.id;

-- 4. Склады -> res_storages
select s.id, s.description as name, c.ID as company_id
from storages s
    left join bm_Companies c on c.ID = s.CompanyID
order by s.id;

-- 5. Виды складских операций -> res_storage_operation_types
select ID as id, cast(Description as varchar(255)) as name, Factor as factor
from bm_StorageOperationsType
order by ID;


-- АНАЛИЗ ЗАКУПКИ ПРОДУКЦИИ


-- 6. Группы поставщиков -> res_vendor_groups
select vendorgroupid as id, description as name
from vendorgroup
order by vendorgroupid;

-- 7. Поставщики -> res_vendors
select v.id,
       coalesce(nullif(v.lastname, ''), v.clientid) as name,
       g.vendorgroupid as group_id,
       case when coalesce(v.IsUse, 1) = 0 then 0 else 1 end as is_active
from vendors v
    left join vendorgroup g on g.vendorgroupid = v.clientgroup
order by v.id;

-- 8. Организации -> res_companies
select ID as id, ShortName as name, INN as inn
from bm_Companies
order by ID;

-- 9. Журналы документов -> res_journal_types
select ID as id, JournalName as name
from bm_JournalType
order by ID;

-- 10. Типы документов -> res_document_types
select t.ID as id,
       cast(t.Description as varchar(500)) as name,
       j.ID as journal_type_id
from bm_JournalTypeDocuments t
    left join bm_JournalType j on j.ID = t.JournalID
order by t.ID;


-- АНАЛИЗ ПРОДАЖИ ТОВАРА


-- 11. Типы операций журнала -> res_transaction_types
select transtypeid as id, transgroupid as group_id, cast(description as varchar(500)) as name
from transtype
order by transtypeid;

-- 12. Группы клиентов -> res_client_groups
select clientgroupid as id, description as name, discount
from clientgroup
order by clientgroupid;

-- 13. Клиенты -> res_clients
select c.id,
       c.clientid as code,
       nullif(c.cardid, '') as card_id,
       g.clientgroupid as group_id,
       c.discount
from clients c
    left join clientgroup g on g.clientgroupid = c.clientgroup
order by c.id;

-- 14. Виды оплаты -> res_payment_types
select paymenttypeid as id, description as name, currencyid as currency
from paymenttype
order by paymenttypeid;


-- АНАЛИЗ РАБОТЫ ПЕРСОНАЛА

-- 15. Уровни доступа -> res_access_levels
select securityaccessid as id, description as name
from securityaccess
order by securityaccessid;

-- 16. Сотрудники -> res_employees (ФИО без лишних пробелов)
select p.personid as id,
       concat_ws(' ', nullif(p.lastname, ''), nullif(p.firstname, ''), nullif(p.middlename, '')) as name,
       a.securityaccessid as access_level_id,
       case when p.deleteflag = 1 then 1 else 0 end as is_deleted
from personnel p
    left join securityaccess a on a.securityaccessid = p.securityaccess
order by p.personid;


-- АНАЛИЗ ОСТАТКОВ

-- 17. Причины списания -> res_write_off_reasons (ParentID = 0 -> NULL)
select r.ID as id, r.Description as name, p.ID as parent_id
from bm_ReasonDebit r
    left join bm_ReasonDebit p on p.ID = r.ParentID
order by r.ID;


-- Сколько строк должно оказаться в каждом ресурсе OLAP
-- (сравнить с проверочным запросом в конце 03_olap_insert.sql)
select 'res_units' as resource, count(*) as cnt from [size]
union all select 'res_categories',              count(*) from category
union all select 'res_products',                count(*) from product
union all select 'res_storages',                count(*) from storages
union all select 'res_storage_operation_types', count(*) from bm_StorageOperationsType
union all select 'res_vendor_groups',           count(*) from vendorgroup
union all select 'res_vendors',                 count(*) from vendors
union all select 'res_companies',               count(*) from bm_Companies
union all select 'res_journal_types',           count(*) from bm_JournalType
union all select 'res_document_types',          count(*) from bm_JournalTypeDocuments
union all select 'res_transaction_types',       count(*) from transtype
union all select 'res_client_groups',           count(*) from clientgroup
union all select 'res_clients',                 count(*) from clients
union all select 'res_payment_types',           count(*) from paymenttype
union all select 'res_access_levels',           count(*) from securityaccess
union all select 'res_employees',               count(*) from personnel
union all select 'res_write_off_reasons',       count(*) from bm_ReasonDebit;
