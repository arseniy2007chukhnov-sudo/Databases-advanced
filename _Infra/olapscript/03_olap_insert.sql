do
$$
begin

    -- ТРАНЗАКЦИЯ 1. Очистка 
    begin
        delete from res_products;
        delete from res_vendors;
        delete from res_employees;
        delete from res_clients;
        delete from res_document_types;
        delete from res_storages;

        delete from res_units;
        delete from res_categories;
        delete from res_vendor_groups;
        delete from res_companies;
        delete from res_storage_operation_types;
        delete from res_journal_types;
        delete from res_transaction_types;
        delete from res_client_groups;
        delete from res_payment_types;
        delete from res_access_levels;
        delete from res_write_off_reasons;
    exception
        when others then
            raise notice 'Транзакция 1 отменена: %', sqlerrm;
            raise;
    end;


    -- ТРАНЗАКЦИЯ 2. Ресурсы без ссылок на другие ресурсы
    begin
        -- Запрос 1. Единицы измерения
        insert into res_units (id, name, factor) values
            (1, 'порция', null);                                  -- результат запроса 1

        -- Запрос 2. Категории
        insert into res_categories (id, name, parent_id) values
            (147, 'Меню доставка', null);                         -- результат запроса 2

        -- Запрос 6. Группы поставщиков
        insert into res_vendor_groups (id, name) values
            (31, 'Поставщики'),
            (32, 'Без названия');                                 -- результат запроса 6

        -- Запрос 8. Организации
        insert into res_companies (id, name, inn) values
            (6, 'Пиzzбург', '380122679974');                      -- результат запроса 8

        -- Запрос 5. Виды складских операций
        insert into res_storage_operation_types (id, name, factor) values
            (1, 'Поступление', 1),
            (2, 'Списание', -1),
            (3, 'Инвентаризация', 1);                             -- результат запроса 5

        -- Запрос 9. Журналы документов
        insert into res_journal_types (id, name) values
            (1, 'Хозяйственный учет'),
            (2, 'Финансовый учет'),
            (3, 'Складской учет');                                -- результат запроса 9

        -- Запрос 11. Типы операций журнала
        insert into res_transaction_types (id, group_id, name) values
            (101, 1, 'PLU Sales'),
            (14, null, 'Rent'),
            (15, null, 'Lottery');                                -- результат запроса 11

        -- Запрос 12. Группы клиентов
        insert into res_client_groups (id, name, discount) values
            (37, 'Дсконт карты', 5.000);                          -- результат запроса 12

        -- Запрос 14. Виды оплаты
        insert into res_payment_types (id, name, currency) values
            (211, 'Наличные', null),
            (212, 'USD', 'USD');                                  -- результат запроса 14

        -- Запрос 15. Уровни доступа
        insert into res_access_levels (id, name) values
            (3, 'Manager/Adm'),
            (2, 'Clerk'),
            (9, 'Special Access');                                -- результат запроса 15

        -- Запрос 17. Причины списания
        insert into res_write_off_reasons (id, name, parent_id) values
            (1, 'Порча продукта', null);                          -- результат запроса 17
    exception
        when others then
            raise notice 'Транзакция 2 отменена: %', sqlerrm;
            raise;
    end;


    -- ТРАНЗАКЦИЯ 3. Ресурсы со ссылками на другие ресурсы
    begin
        -- Запрос 7. Поставщики
        insert into res_vendors (id, name, group_id, is_active) values
            (91, 'Габур', 31, true);                              -- результат запроса 7

        -- Запрос 4. Склады
        insert into res_storages (id, name, company_id) values
            (41, 'Склад', 6);                                     -- результат запроса 4

        -- Запрос 10. Типы документов
        insert into res_document_types (id, name, journal_type_id) values
            (1, 'Ввод состава нового рецепта', 1);                -- результат запроса 10

        -- Запрос 13. Клиенты
        insert into res_clients (id, code, card_id, group_id, discount) values
            (109, '1234', null, 37, 0);                           -- результат запроса 13

        -- Запрос 16. Сотрудники
        insert into res_employees (id, name, access_level_id, is_deleted) values
            (897, 'Администратор Barnet', 9, true);               -- результат запроса 16

        -- Запрос 3. Номенклатура
        insert into res_products (id, code, name, category_id, vendor_id, is_active) values
            (4337, '1204073', 'Бананы', null, null, true);        -- результат запроса 3
    exception
        when others then
            raise notice 'Транзакция 3 отменена: %', sqlerrm;
            raise;
    end;
end
$$;

-- Проверка: число строк по ресурсам
select 'res_units' as "Ресурс", count(*) as "Строк" from res_units
union all select 'res_categories',              count(*) from res_categories
union all select 'res_products',                count(*) from res_products
union all select 'res_storages',                count(*) from res_storages
union all select 'res_storage_operation_types', count(*) from res_storage_operation_types
union all select 'res_vendor_groups',           count(*) from res_vendor_groups
union all select 'res_vendors',                 count(*) from res_vendors
union all select 'res_companies',               count(*) from res_companies
union all select 'res_journal_types',           count(*) from res_journal_types
union all select 'res_document_types',          count(*) from res_document_types
union all select 'res_transaction_types',       count(*) from res_transaction_types
union all select 'res_client_groups',           count(*) from res_client_groups
union all select 'res_clients',                 count(*) from res_clients
union all select 'res_payment_types',           count(*) from res_payment_types
union all select 'res_access_levels',           count(*) from res_access_levels
union all select 'res_employees',               count(*) from res_employees
union all select 'res_write_off_reasons',       count(*) from res_write_off_reasons;
