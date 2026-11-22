do
$$
declare
    v_tbl text;
begin

    -- ТРАНЗАКЦИЯ 1. Очистка для повторного запуска
    begin
        drop table if exists res_products cascade;
        drop table if exists res_vendors cascade;
        drop table if exists res_vendor_groups cascade;
        drop table if exists res_employees cascade;
        drop table if exists res_access_levels cascade;
        drop table if exists res_clients cascade;
        drop table if exists res_client_groups cascade;
        drop table if exists res_document_types cascade;
        drop table if exists res_journal_types cascade;
        drop table if exists res_storages cascade;
        drop table if exists res_companies cascade;
        drop table if exists res_storage_operation_types cascade;
        drop table if exists res_transaction_types cascade;
        drop table if exists res_payment_types cascade;
        drop table if exists res_write_off_reasons cascade;
        drop table if exists res_categories cascade;
        drop table if exists res_units cascade;
    exception
        when others then
            raise notice 'Транзакция 1 отменена: %', sqlerrm;
            raise;
    end;


    -- ТРАНЗАКЦИЯ 2. Справочники без внешних ключей на другие ресурсы
    begin
        -- Единицы измерения (Front: size)
        create table res_units (
            id        bigint        not null,
            uniq_code varchar(20)   generated always as ('UNT-' || lpad(id::text, 10, '0')) stored not null,
            name      varchar(100)  not null,
            factor    numeric(18,6),
            constraint pk_res_units      primary key (id),
            constraint uq_res_units_code unique (uniq_code)
        );

        -- Категории номенклатуры, дерево (Front: category)
        create table res_categories (
            id        bigint       not null,
            uniq_code varchar(20)  generated always as ('CAT-' || lpad(id::text, 10, '0')) stored not null,
            name      varchar(255) not null,
            parent_id bigint,
            constraint pk_res_categories      primary key (id),
            constraint uq_res_categories_code unique (uniq_code),
            constraint fk_res_categories_parent foreign key (parent_id) references res_categories (id),
            constraint ck_res_categories_parent check (parent_id is null or parent_id <> id)
        );

        -- Группы поставщиков (Front: vendorgroup)
        create table res_vendor_groups (
            id        bigint       not null,
            uniq_code varchar(20)  generated always as ('VGR-' || lpad(id::text, 10, '0')) stored not null,
            name      varchar(100) not null,
            constraint pk_res_vendor_groups      primary key (id),
            constraint uq_res_vendor_groups_code unique (uniq_code)
        );

        -- Организации (Front: bm_Companies)
        create table res_companies (
            id        bigint       not null,
            uniq_code varchar(20)  generated always as ('CMP-' || lpad(id::text, 10, '0')) stored not null,
            name      varchar(255) not null,
            inn       varchar(50),
            constraint pk_res_companies      primary key (id),
            constraint uq_res_companies_code unique (uniq_code)
        );

        -- Виды складских операций (Front: bm_StorageOperationsType)
        create table res_storage_operation_types (
            id        bigint       not null,
            uniq_code varchar(20)  generated always as ('SOT-' || lpad(id::text, 10, '0')) stored not null,
            name      varchar(255) not null,
            factor    smallint     not null,
            constraint pk_res_storage_operation_types      primary key (id),
            constraint uq_res_storage_operation_types_code unique (uniq_code),
            constraint ck_res_storage_operation_types_factor check (factor in (-1, 1))
        );

        -- Журналы документов (Front: bm_JournalType)
        create table res_journal_types (
            id        bigint       not null,
            uniq_code varchar(20)  generated always as ('JRT-' || lpad(id::text, 10, '0')) stored not null,
            name      varchar(255) not null,
            constraint pk_res_journal_types      primary key (id),
            constraint uq_res_journal_types_code unique (uniq_code)
        );

        -- Типы операций журнала продаж (Front: transtype)
        create table res_transaction_types (
            id        bigint       not null,
            uniq_code varchar(20)  generated always as ('TRN-' || lpad(id::text, 10, '0')) stored not null,
            group_id  integer,
            name      varchar(500) not null,
            constraint pk_res_transaction_types      primary key (id),
            constraint uq_res_transaction_types_code unique (uniq_code)
        );

        -- Группы клиентов (Front: clientgroup)
        create table res_client_groups (
            id        bigint        not null,
            uniq_code varchar(20)   generated always as ('CGR-' || lpad(id::text, 10, '0')) stored not null,
            name      varchar(100)  not null,
            discount  numeric(7,3),
            constraint pk_res_client_groups      primary key (id),
            constraint uq_res_client_groups_code unique (uniq_code)
        );

        -- Виды оплаты (Front: paymenttype)
        create table res_payment_types (
            id        bigint       not null,
            uniq_code varchar(20)  generated always as ('PTP-' || lpad(id::text, 10, '0')) stored not null,
            name      varchar(100) not null,
            currency  char(3),
            constraint pk_res_payment_types      primary key (id),
            constraint uq_res_payment_types_code unique (uniq_code)
        );

        -- Уровни доступа сотрудников (Front: securityaccess)
        create table res_access_levels (
            id        bigint       not null,
            uniq_code varchar(20)  generated always as ('ACL-' || lpad(id::text, 10, '0')) stored not null,
            name      varchar(100) not null,
            constraint pk_res_access_levels      primary key (id),
            constraint uq_res_access_levels_code unique (uniq_code)
        );

        -- Причины списания, дерево (Front: bm_ReasonDebit)
        create table res_write_off_reasons (
            id        bigint       not null,
            uniq_code varchar(20)  generated always as ('WOR-' || lpad(id::text, 10, '0')) stored not null,
            name      varchar(255) not null,
            parent_id bigint,
            constraint pk_res_write_off_reasons      primary key (id),
            constraint uq_res_write_off_reasons_code unique (uniq_code),
            constraint fk_res_write_off_reasons_parent foreign key (parent_id) references res_write_off_reasons (id),
            constraint ck_res_write_off_reasons_parent check (parent_id is null or parent_id <> id)
        );
    exception
        when others then
            raise notice 'Транзакция 2 отменена: %', sqlerrm;
            raise;
    end;


    -- ТРАНЗАКЦИЯ 3. Справочники со ссылками на другие ресурсы
    begin
        -- Поставщики (Front: vendors)
        create table res_vendors (
            id        bigint       not null,
            uniq_code varchar(20)  generated always as ('VND-' || lpad(id::text, 10, '0')) stored not null,
            name      varchar(255) not null,
            group_id  bigint,
            is_active boolean      not null default true,
            constraint pk_res_vendors      primary key (id),
            constraint uq_res_vendors_code unique (uniq_code),
            constraint fk_res_vendors_group foreign key (group_id) references res_vendor_groups (id)
        );

        -- Склады (Front: storages)
        create table res_storages (
            id         bigint       not null,
            uniq_code  varchar(20)  generated always as ('STR-' || lpad(id::text, 10, '0')) stored not null,
            name       varchar(255) not null,
            company_id bigint,
            constraint pk_res_storages      primary key (id),
            constraint uq_res_storages_code unique (uniq_code),
            constraint fk_res_storages_company foreign key (company_id) references res_companies (id)
        );

        -- Типы документов внутри журнала (Front: bm_JournalTypeDocuments)
        create table res_document_types (
            id              bigint       not null,
            uniq_code       varchar(20)  generated always as ('DTP-' || lpad(id::text, 10, '0')) stored not null,
            name            varchar(500) not null,
            journal_type_id bigint,
            constraint pk_res_document_types      primary key (id),
            constraint uq_res_document_types_code unique (uniq_code),
            constraint fk_res_document_types_journal foreign key (journal_type_id) references res_journal_types (id)
        );

        -- Клиенты (Front: clients)
        create table res_clients (
            id        bigint        not null,
            uniq_code varchar(20)   generated always as ('CLN-' || lpad(id::text, 10, '0')) stored not null,
            code      varchar(24),            -- бизнес-код клиента (journal.customerid)
            card_id   varchar(50),
            group_id  bigint,
            discount  numeric(7,3),
            constraint pk_res_clients      primary key (id),
            constraint uq_res_clients_code unique (uniq_code),
            constraint fk_res_clients_group foreign key (group_id) references res_client_groups (id)
        );

        -- Сотрудники (Front: personnel)
        create table res_employees (
            id              bigint       not null,
            uniq_code       varchar(20)  generated always as ('EMP-' || lpad(id::text, 10, '0')) stored not null,
            name            varchar(255) not null,
            access_level_id bigint,
            is_deleted      boolean      not null default false,
            constraint pk_res_employees      primary key (id),
            constraint uq_res_employees_code unique (uniq_code),
            constraint fk_res_employees_access foreign key (access_level_id) references res_access_levels (id)
        );

        -- Номенклатура (Front: product)
        create table res_products (
            id          bigint       not null,
            uniq_code   varchar(20)  generated always as ('PRD-' || lpad(id::text, 10, '0')) stored not null,
            code        varchar(16),          -- бизнес-код товара (product.productid, journal.id)
            name        varchar(255) not null,
            category_id bigint,
            vendor_id   bigint,               -- основной поставщик, NULL - нет поставщика
            is_active   boolean      not null default true,
            constraint pk_res_products      primary key (id),
            constraint uq_res_products_code unique (uniq_code),
            constraint fk_res_products_category foreign key (category_id) references res_categories (id),
            constraint fk_res_products_vendor   foreign key (vendor_id)   references res_vendors (id)
        );

        create index idx_res_products_code     on res_products (code);
        create index idx_res_products_category on res_products (category_id);
        create index idx_res_products_vendor   on res_products (vendor_id);
        create index idx_res_clients_code      on res_clients (code);
    exception
        when others then
            raise notice 'Транзакция 3 отменена: %', sqlerrm;
            raise;
    end;


    -- ТРАНЗАКЦИЯ 4. Комментарии
    begin
        comment on table res_units                  is 'Единицы измерения / порции (Front: size)';
        comment on table res_categories             is 'Категории номенклатуры, дерево (Front: category)';
        comment on table res_vendor_groups          is 'Группы поставщиков (Front: vendorgroup)';
        comment on table res_vendors                is 'Поставщики (Front: vendors)';
        comment on table res_products               is 'Номенклатура: товары, блюда, ингредиенты (Front: product)';
        comment on table res_companies              is 'Организации (Front: bm_Companies)';
        comment on table res_storages               is 'Склады (Front: storages)';
        comment on table res_storage_operation_types is 'Виды складских операций, factor: +1 приход / -1 расход (Front: bm_StorageOperationsType)';
        comment on table res_journal_types          is 'Журналы документов (Front: bm_JournalType)';
        comment on table res_document_types         is 'Типы документов внутри журнала (Front: bm_JournalTypeDocuments)';
        comment on table res_transaction_types      is 'Типы операций журнала продаж (Front: transtype)';
        comment on table res_client_groups          is 'Группы клиентов (Front: clientgroup)';
        comment on table res_clients                is 'Клиенты (Front: clients)';
        comment on table res_payment_types          is 'Виды оплаты (Front: paymenttype)';
        comment on table res_access_levels          is 'Уровни доступа сотрудников (Front: securityaccess)';
        comment on table res_employees              is 'Сотрудники (Front: personnel)';
        comment on table res_write_off_reasons      is 'Причины списания, дерево (Front: bm_ReasonDebit)';

        for v_tbl in
            select c.table_name
              from information_schema.columns c
             where c.table_schema = 'public'
               and c.table_name like 'res\_%'
               and c.column_name = 'uniq_code'
        loop
            execute format('COMMENT ON COLUMN %I.id IS %L', v_tbl, 'Код записи в Front (источник)');
            execute format('COMMENT ON COLUMN %I.uniq_code IS %L', v_tbl, 'Уникальный код записи (формируется автоматически из id)');
        end loop;
    exception
        when others then
            raise notice 'Транзакция 4 отменена: %', sqlerrm;
            raise;
    end;
end
$$;

-- Проверка: созданные ресурсы
select t.table_name as "Ресурс", obj_description(('public.' || t.table_name)::regclass) as "Описание"
  from information_schema.tables t
 where t.table_schema = 'public' and t.table_name like 'res\_%'
 order by t.table_name;