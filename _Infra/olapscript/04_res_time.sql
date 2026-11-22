do
$$
declare
    v_year_from integer := 2013;
    v_year_to   integer := 2030;
    v_from      date;
    v_months    integer;
begin
    v_from   := make_date(v_year_from, 1, 1);
    v_months := (v_year_to - v_year_from + 1) * 12;

    -- ТРАНЗАКЦИЯ 1. Структура
    begin
        drop table if exists res_time cascade;

        create table res_time (
            id           integer     not null,
            uniq_code    varchar(20) generated always as ('TIM-' || lpad(id::text, 10, '0')) stored not null,
            month_start  date        not null,
            month_end    date        not null,
            month_name   varchar(20) not null,
            year_num     integer     not null,
            quarter_num  smallint    not null,
            quarter_name varchar(20) not null,
            constraint pk_res_time        primary key (id),
            constraint uq_res_time_code   unique (uniq_code),
            constraint uq_res_time_start  unique (month_start),
            constraint ck_res_time_period check (month_end >= month_start),
            constraint ck_res_time_quarter check (quarter_num between 1 and 4)
        );

        comment on table  res_time              is 'Ресурс Время: календарь по месяцам';
        comment on column res_time.id           is 'Код месяца в формате ГГГГММ';
        comment on column res_time.uniq_code    is 'Уникальный код записи (формируется автоматически из id)';
        comment on column res_time.month_start  is 'Дата начала месяца';
        comment on column res_time.month_end    is 'Дата окончания месяца';
        comment on column res_time.month_name   is 'Название месяца';
        comment on column res_time.year_num     is 'Год';
        comment on column res_time.quarter_num  is 'Номер квартала (1-4)';
        comment on column res_time.quarter_name is 'Название квартала';
    exception
        when others then
            raise notice 'Транзакция 1 отменена: %', sqlerrm;
            raise;
    end;


    -- ТРАНЗАКЦИЯ 2. Заполнение
    begin
        insert into res_time (id, month_start, month_end, month_name, year_num, quarter_num, quarter_name)
        with m as (
            select (v_from + g.n * interval '1 month')::date as month_start
              from generate_series(0, v_months - 1) as g (n)
        )
        select to_char(m.month_start, 'YYYYMM')::integer,
               m.month_start,
               (m.month_start + interval '1 month')::date - 1,
               (array['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
                      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'])
                   [extract(month from m.month_start)::integer],
               extract(year from m.month_start)::integer,
               extract(quarter from m.month_start)::smallint,
               (array['I', 'II', 'III', 'IV'])[extract(quarter from m.month_start)::integer] || ' квартал'
          from m;
    exception
        when others then
            raise notice 'Транзакция 2 отменена: %', sqlerrm;
            raise;
    end;
end
$$;

-- Проверка: Код | Дата начала | Дата окончания | Месяц | Год | № квартала | Квартал
select t.id           as "Код",
       t.month_start  as "Дата начала месяца",
       t.month_end    as "Дата окончания месяца",
       t.month_name   as "Название месяца",
       t.year_num     as "Год",
       t.quarter_num  as "Номер квартала",
       t.quarter_name as "Название квартала"
  from res_time t
 where t.year_num in (2020, 2024)
 order by t.id;