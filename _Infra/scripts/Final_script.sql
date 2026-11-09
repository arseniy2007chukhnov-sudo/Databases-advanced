do $$
begin
 
	-- 1. Очистка для повторного запуска
 
	-- ТРАНЗАКЦИЯ 1
	begin
		drop procedure if exists public.sp_calc_meteo(public.calc_input_params, integer, refcursor);
		drop procedure if exists public.sp_calc_meteo(public.calc_input_params, integer);
		drop function if exists public.fn_calc_meteo_bulletin(public.calc_input_params, integer);
		drop type if exists public.calc_input_params;
		drop function if exists public.fn_calc_table_speed(text, integer, numeric);
		drop function if exists public.fn_calc_mean_temp_deviation(integer, integer);
		drop function if exists public.fn_get_correction_value(text, integer, integer);
		drop function if exists public.fn_get_calc_constant(text);
 
		drop table if exists public.calc_correction cascade;
		drop table if exists public.calc_correction_types cascade;
		drop table if exists public.calc_correction_headers cascade;
		drop table if exists public.calc_correction_heights cascade;
		drop table if exists public.calc_constants cascade;
 
		drop sequence if exists public.calc_correction_seq;
		drop sequence if exists public.calc_correction_types_seq;
		drop sequence if exists public.calc_correction_header_seq;
		drop sequence if exists public.calc_correction_height_seq;
		drop sequence if exists public.calc_constants_seq;
	exception
		when others then
			raise notice 'Транзакция 1 (очистка) отменена: %', sqlerrm;
			raise;
	end;
 
 
	-- 2. Учебный скрипт 20261102.sql
 
	-- ТРАНЗАКЦИЯ 2.1. Структуры
	begin
 
		create sequence calc_correction_height_seq;
		create table calc_correction_heights
		(
		        id integer primary key not null default nextval('public.calc_correction_height_seq'),
		        height integer not null
		);
 
		insert into calc_correction_heights(height)
		values(200),(400),(800),(1200),(1600),(2000),(2400),(3000),(4000);
 
		comment on table calc_correction_heights is 'Таблица стандартных высот';
		comment on column calc_correction_heights.id is 'Уникальный код';
		comment on column calc_correction_heights.height is 'Высота';
 
		create sequence calc_correction_types_seq;
		create table calc_correction_types
		(
		        id integer not null primary key default nextval('public.calc_correction_types_seq'),
		        parent_id integer,
		        measurment_equipment_id integer,
		        description text not null,
		        header_values integer[]
		);
 
		comment on table calc_correction_types is 'Справочник типов таблиц с собственными заголовками';
		comment on column calc_correction_types.id is 'Уникальный код';
		comment on column calc_correction_types.parent_id is 'Уникальный код владельца - тип таблицы';
		comment on column calc_correction_types.measurment_equipment_id is 'Тип оборудования';
		comment on column calc_correction_types.description is 'Описание к таблице';
		comment on column calc_correction_types.header_values is 'Значения в заголовке таблице';
 
		create sequence calc_correction_seq;
		create table calc_correction
		(
		        id integer not null primary key default nextval('public.calc_correction_seq'),
		        height_id integer not null,
		        type_id integer not null,
		        row_values integer[]
		);
 
		comment on table calc_correction is 'Универсальная таблица корректировок';
		comment on column calc_correction.id is 'Уникальный код';
		comment on column calc_correction.height_id is 'Код высоты';
		comment on column calc_correction.type_id is 'Код типа таблиц';
		comment on column calc_correction.row_values is 'Значения с корректировками';
 
	exception
		when others then
			raise notice 'Транзакция 2.1 (структуры учебного скрипта) отменена: %', sqlerrm;
			raise;
	end;
 
	-- ТРАНЗАКЦИЯ 2.2. Данные
	begin
 
		insert into calc_correction_types(  description, header_values)
		values( 'Таблица 2', array[0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 10, 20, 30, 40, 50]),  -- 1
		( 'Таблица 3, скорость среднего ветра', null), -- 2
		( 'Таблица 3, направление среднего ветра', null);       -- 3
 
		insert into calc_correction_types( description, parent_id, measurment_equipment_id, header_values)
		values
		('Таблица 3, Скорость среднего ветра (ВР)', 2, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), -- 4
		('Таблица 3, Направление среднего ветра (ВР)',3, 2, array[0, 1, 2, 2, 3, 3, 3, 4, 4]), -- 5
		('Таблица 3, Скорость среднего ветра (ДМК)',2, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), -- 6
		('Таблица 3, Направление среднего ветра (ДМК)',3, 1, array[1, 2, 3, 3, 4, 4, 4, 5, 5]); -- 7
 
		insert into calc_correction_types( description, parent_id)
		values('Таблица 2, Положительные температуры', 1 ), -- 8
		('Таблица 2, Отрицательные температуры', 1 ) --9
		;
 
		insert into calc_correction(height_id, type_id, row_values )
		values
		-- Таблица 2, отрицптельные значения
		(1, 8, array[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]), -- 200
		(2, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -38, -48]), -- 400
		(3, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]), -- 800
		(4, 8, array[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]), -- 1200
		(5, 8, array[-1, -2, -3, -4, -4, -4, -5, -6, -7, -7, -17, -25, -34, -42]), -- 1600
		(6, 8, array[-1, -2, -3, -3, -4, -4, -5, -6, -6, -7, -16, -24, -32, -40]), -- 2000
		(7, 8, array[-1, -2, -2, -3, -4, -4, -5, -5, -6, -7, -15, -23, -31, -38]), -- 2400
		(8, 8, array[-1, -2, -2, -3, -4, -4, -4, -5, -5, -6, -15, -22, -30, -37]), -- 3000
		(9, 8, array[-1, -2, -2, -3, -4, -4, -4, -4, -5, -6, -14, -20, -27, -35]), -- 4000
		-- Таблица 2, положитеьные значения
		(1, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 200
		(2, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 400
		(3, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 800
		(4, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 1200
		(5, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 1600
		(6, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 2000
		(7, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 2400
		(8, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 3000
		(9, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 4000
		-- Таблица 3, Скорость среднего ветра (ВР)
		(1, 4, array[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]), -- 200
		(2, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 ,15]), -- 400
		(3, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15 ,16]), -- 800
		(4, 4, array[4, 5, 7, 8, 8, 9, 11, 12, 13, 15 ,15, 16]), -- 1200
		-- Таблица 3, Направление среднего ветра (ВР)
		(1, 5, array[0]), -- 200
		(2, 5, array[1]), -- 400
		(3, 5, array[2]), -- 800
		(4, 5, array[2]), -- 1200
		(5, 5, array[3]), -- 1600
		(6, 5, array[3]), -- 2000
		(7, 5, array[3]), -- 2400
		(8, 5, array[4]), -- 3000
		(9, 5, array[4]), -- 4000
		-- Таблица 3,Скорость среднего ветра (ДМК)
		(1, 6, array[4,6,8,9,10,12,14,15,16,18,20,21,22]), -- 200
		(2, 6, array[5,7,10,11,12,14,17,18,20,22,23,25,27]), -- 400
		(3, 6, array[5,8,10,11,13,15,18,19,21,23,25,27,28]), -- 800
		(4, 6, array[5,8,11,12,13,16,19,20,23,24,26,28,30]), -- 1200
		-- 'Таблица 3, Направление среднего ветра (ДМК)
		(1, 7, array[1]), -- 200
		(2, 7, array[2]), -- 400
		(3, 7, array[3]), -- 800
		(4, 7, array[3]), -- 1200
		(5, 7, array[4]), -- 1600
		(6, 7, array[4]), -- 2000
		(7, 7, array[4]), -- 2400
		(8, 7, array[5]), -- 3000
		(9, 7, array[5]); -- 4000
 
	exception
		when others then
			raise notice 'Транзакция 2.2 (данные учебного скрипта) отменена: %', sqlerrm;
			raise;
	end;
 
	-- ТРАНЗАКЦИЯ 2.3. Прочее
	begin
		CREATE OR REPLACE FUNCTION public.fn_calc_temperature_interpolation(
			par_temperature numeric)
		    RETURNS numeric
		    LANGUAGE 'plpgsql'
		    COST 100
		    VOLATILE PARALLEL UNSAFE
		AS $BODY$
				        declare 
				                var_interpolation t_interpolation;
				                var_result numeric(8,2) default 0;
				                var_min_temparure numeric(8,2) default 0;
				                var_max_temperature numeric(8,2) default 0;
				                var_denominator numeric(8,2) default 0;
				        begin
				
				                                raise notice 'Расчет интерполяции для температуры %', par_temperature;
								         
				                if exists (select 1 from public.popravki_virtualnoj_temperatury where temperature = par_temperature ) then
				                begin
				                        select correction 
				                        into  var_result 
				                        from  public.popravki_virtualnoj_temperatury
				                        where 
				                                temperature = par_temperature;
				                end;
				                else    
				                begin
				                        select min(temperature), max(temperature) 
				                        into var_min_temparure, var_max_temperature
				                        from public.popravki_virtualnoj_temperatury;
				
				                        if par_temperature < var_min_temparure or   
				                           par_temperature > var_max_temperature then
				
				                                raise exception 'Некорректно передан параметр! Невозможно рассчитать поправку. Значение должно укладываться в диаппазон: %, %',
				                                        var_min_temparure, var_max_temperature;
				                        end if;   
				
				                        -- Получим граничные параметры
				
				                        select x0, y0, x1, y1 
				                                                 into var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1
				                        from
				                        (
				                                select t1.temperature as x0, t1.correction as y0
				                                from public.popravki_virtualnoj_temperatury as t1
				                                where t1.temperature <= par_temperature
				                                order by t1.temperature desc
				                                limit 1
				                        ) as leftPart
				                        cross join
				                        (
				                                select t1.temperature as x1, t1.correction as y1
				                                from public.popravki_virtualnoj_temperatury as t1
				                                where t1.temperature >= par_temperature
				                                order by t1.temperature 
				                                limit 1
				                        ) as rightPart;
				
				                        raise notice 'Граничные значения %', var_interpolation;
				                        var_result :=  f_calc_interpolation( par_temperature,  var_interpolation);
				                                                 
				                end;
				                end if;
				
				                                return var_result;
				
				end;
				
		$BODY$;
 
		-- роль admin есть не на каждом сервере
		if exists (select 1 from pg_roles where rolname = 'admin') then
			execute 'alter function public.fn_calc_temperature_interpolation(numeric) owner to admin';
		end if;
 
		COMMENT ON FUNCTION public.fn_calc_temperature_interpolation(numeric)
		    IS 'Функция для расчета интерполяции для метео приближенный';
	exception
		when others then
			raise notice 'Транзакция 2.3 (функция интерполяции температуры) отменена: %', sqlerrm;
			raise;
	end;
 
	-- 3. Новая таблица заголовков + изменение справочника типов таблиц
 
	-- ТРАНЗАКЦИЯ 3
	begin
		create sequence calc_correction_header_seq;
		create table calc_correction_headers
		(
		        id integer not null primary key default nextval('public.calc_correction_header_seq'),
		        code varchar(30) not null,
		        description text not null,
		        header_values integer[] not null,
		        constraint uq_calc_correction_headers_code unique (code),
		        constraint ck_calc_correction_headers_values check (cardinality(header_values) > 0)
		);
 
		comment on table calc_correction_headers is 'Заголовки таблиц корректировок (значения столбцов)';
		comment on column calc_correction_headers.id is 'Уникальный код';
		comment on column calc_correction_headers.code is 'Символьный код заголовка';
		comment on column calc_correction_headers.description is 'Описание заголовка';
		comment on column calc_correction_headers.header_values is 'Значения столбцов: header_values[i] соответствует row_values[i] в calc_correction';
 
		-- Правильные значения заголовков (в учебном скрипте у Таблицы 2
		-- был лишний 0 и повторялась 8, а у направлений вместо заголовка
		-- лежали значения строк)
		insert into calc_correction_headers(code, description, header_values)
		values
		('TBL2_DT',    'Таблица 2: отклонение приземной виртуальной температуры, °C',  array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]),
		('TBL3_DRIFT', 'Таблица 3 (ВР): дальность сноса ветровых пуль Дг, м',           array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),
		('TBL3_V0',    'Таблица 3 (ДМК): скорость приземного ветра V0, м/с',            array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
 
		alter table calc_correction_types add column header_id integer;
		alter table calc_correction_types add column code varchar(30);
 
		update calc_correction_types set header_id = (select h.id from calc_correction_headers h where h.code = 'TBL2_DT')
		where id in (1, 8, 9);
		update calc_correction_types set header_id = (select h.id from calc_correction_headers h where h.code = 'TBL3_DRIFT')
		where id = 4;
		update calc_correction_types set header_id = (select h.id from calc_correction_headers h where h.code = 'TBL3_V0')
		where id = 6;
 
		-- Символьные коды типов (по ним ищут расчетные функции)
		update calc_correction_types as t
		set code = v.code
		from (values
			(1, 'TBL2'),
			(2, 'TBL3_SPEED'),
			(3, 'TBL3_DIR'),
			(4, 'TBL3_SPEED_VR'),
			(5, 'TBL3_DIR_VR'),
			(6, 'TBL3_SPEED_DMK'),
			(7, 'TBL3_DIR_DMK'),
			(8, 'TBL2_POS'),
			(9, 'TBL2_NEG')
		) as v (id, code)
		where t.id = v.id;
 
		alter table calc_correction_types alter column code set not null;
		alter table calc_correction_types add constraint uq_calc_correction_types_code unique (code);
		alter table calc_correction_types add constraint fk_calc_correction_types_header
			foreign key (header_id) references calc_correction_headers (id);
 
		-- Старая колонка с массивом больше не нужна
		alter table calc_correction_types drop column header_values;
 
		comment on column calc_correction_types.header_id is 'Код заголовка (NULL - заголовка нет, в строке одно значение)';
		comment on column calc_correction_types.code is 'Символьный код типа таблицы';
	exception
		when others then
			raise notice 'Транзакция 3 (заголовки) отменена: %', sqlerrm;
			raise;
	end;
 
	-- 4. Исправление данных и добавление недостающих данных
 
	-- ТРАНЗАКЦИЯ 4
	begin
		-- 4.1. Таблица 2: отрицательные значения лежали под типом 8 (положительные),
		--      положительные - под типом 7 (направление ДМК).
		update calc_correction set type_id = 9 where type_id = 8;
		update calc_correction set type_id = 8 where type_id = 7 and cardinality(row_values) = 12;
 
		-- 4.2. Таблица 2, отрицательные: ошибки переписывания
		update calc_correction set row_values = array[-1, -2, -3, -3, -4, -4, -5, -6, -7, -7, -17, -25, -34, -42]
		where type_id = 9 and height_id = 5;   -- 1600 (4-е значение: -3, а не -4)
		update calc_correction set row_values = array[-1, -2, -2, -3, -4, -4, -4, -4, -5, -6, -14, -20, -27, -34]
		where type_id = 9 and height_id = 9;   -- 4000 (последнее значение: -34, а не -35)
 
		-- 4.3. Таблица 3 (ДМК), скорость: 1200 м, 9-е значение 22, а не 23
		update calc_correction set row_values = array[5, 8, 11, 12, 13, 16, 19, 20, 22, 24, 26, 28, 30]
		where type_id = 6 and height_id = 4;
 
		-- 4.4. Таблица 3, скорость: недостающие высоты 1600 - 4000
		insert into calc_correction(height_id, type_id, row_values)
		values
		-- ВР
		(5, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 15, 17, 17]), -- 1600
		(6, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 16, 17, 18]), -- 2000
		(7, 4, array[4, 6, 8, 9, 9, 10, 12, 14, 15, 16, 18, 19]), -- 2400
		(8, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 15, 17, 18, 19]), -- 3000
		(9, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 16, 18, 19, 20]), -- 4000
		-- ДМК
		(5, 6, array[6, 8, 11, 13, 14, 17, 20, 21, 23, 25, 27, 29, 32]), -- 1600
		(6, 6, array[6, 9, 11, 13, 14, 17, 20, 21, 24, 26, 28, 30, 32]), -- 2000
		(7, 6, array[6, 9, 12, 14, 15, 18, 21, 22, 25, 27, 29, 32, 34]), -- 2400
		(8, 6, array[6, 9, 12, 14, 15, 18, 21, 23, 25, 28, 30, 32, 36]), -- 3000
		(9, 6, array[6, 10, 12, 14, 16, 19, 22, 24, 26, 29, 32, 34, 36]); -- 4000
	exception
		when others then
			raise notice 'Транзакция 4 (исправление данных) отменена: %', sqlerrm;
			raise;
	end;
 
 
	-- 5. Ограничения целостности (после исправления данных)
 
	-- ТРАНЗАКЦИЯ 5
	begin
		alter table calc_correction_heights add constraint uq_calc_correction_heights_height unique (height);
		alter table calc_correction_types add constraint fk_calc_correction_types_parent
			foreign key (parent_id) references calc_correction_types (id);
 
		alter table calc_correction alter column row_values set not null;
		alter table calc_correction add constraint ck_calc_correction_values check (cardinality(row_values) > 0);
		alter table calc_correction add constraint uq_calc_correction_type_height unique (type_id, height_id);
		alter table calc_correction add constraint fk_calc_correction_height
			foreign key (height_id) references calc_correction_heights (id);
		alter table calc_correction add constraint fk_calc_correction_type
			foreign key (type_id) references calc_correction_types (id);
 
		if to_regclass('public.measurment_equipment') is not null then
			alter table calc_correction_types add constraint fk_calc_correction_types_equipment
				foreign key (measurment_equipment_id) references public.measurment_equipment (id);
		end if;
	exception
		when others then
			raise notice 'Транзакция 5 (ограничения) отменена: %', sqlerrm;
			raise;
	end;
 
 
	-- 6. Константы расчета
 
	-- ТРАНЗАКЦИЯ 6
	begin
		create sequence calc_constants_seq;
		create table calc_constants
		(
		        id integer not null primary key default nextval('public.calc_constants_seq'),
		        code varchar(50) not null,
		        description text not null,
		        value numeric(10,2) not null,
		        constraint uq_calc_constants_code unique (code)
		);
 
		comment on table calc_constants is 'Константы расчета Метео приближенный';
		comment on column calc_constants.id is 'Уникальный код';
		comment on column calc_constants.code is 'Символьный код константы';
		comment on column calc_constants.description is 'Описание';
		comment on column calc_constants.value is 'Значение';
 
		insert into calc_constants(code, description, value)
		values
		('TABLE_TEMPERATURE',     'Табличная виртуальная температура, °C', 15.9),
		('NEG_TEMPERATURE_OFFSET','ТТ: для отрицательного отклонения к модулю прибавляется', 50),
		('MIN_TEMPERATURE',       'Минимальная температура входных данных, °C', -58),
		('MAX_TEMPERATURE',       'Максимальная температура входных данных, °C', 58),
		('DIRECTION_DIVISIONS',   'Больших делений угломера в круге', 60),
		('MIN_SURFACE_WIND_DMK',  'ДМК: при V0 меньше этого значения (м/с) средний ветер = 0', 3),
		('MIN_DRIFT_BP',          'ВР: при Дг меньше этого значения (м) средний ветер = 0', 40),
		('EQUIPMENT_DMK_ID',      'Код типа оборудования ДМК', 1),
		('EQUIPMENT_VR_ID',       'Код типа оборудования ВР', 2);
	exception
		when others then
			raise notice 'Транзакция 6 (константы) отменена: %', sqlerrm;
			raise;
	end;
 
 
	-- 7. Функции и процедура расчета
 
	-- ТРАНЗАКЦИЯ 7.1. Тип и вспомогательные функции
	begin
		-- Тип "входящие параметры"
		create type public.calc_input_params as
		(
			height         numeric,   -- высота метеопоста, м
			temperature    numeric,   -- температура, °C
			pressure       numeric,   -- давление, мм рт.ст.
			wind_direction numeric,   -- направление ветра, большие деления угломера
			wind_speed     numeric,   -- скорость ветра, м/с (только ДМК)
			bullet_drift   numeric    -- дальность сноса пуль, м (только ВР)
		);
		comment on type public.calc_input_params is 'Входящие параметры для расчета Метео приближенный';
 
		-- Чтение константы
		create or replace function public.fn_get_calc_constant(par_code text)
		returns numeric
		language plpgsql
		stable
		as $fn$
		declare
			var_value numeric;
		begin
			select c.value into var_value from public.calc_constants c where c.code = par_code;
			if not found then
				raise exception 'Константа "%" не найдена в calc_constants', par_code;
			end if;
			return var_value;
		end;
		$fn$;
 
		-- Значение ячейки таблицы корректировок: тип (код), высота, значение в заголовке
		create or replace function public.fn_get_correction_value(
			par_type_code text, par_height_id integer, par_column integer)
		returns integer
		language plpgsql
		stable
		as $fn$
		declare
			var_result integer;
		begin
			select c.row_values[array_position(h.header_values, par_column)]
			into var_result
			from public.calc_correction c
				inner join public.calc_correction_types t on t.id = c.type_id
				inner join public.calc_correction_headers h on h.id = t.header_id
			where t.code = par_type_code
			  and c.height_id = par_height_id;
 
			return var_result;
		end;
		$fn$;
 
		-- Таблица 2: среднее отклонение температуры на высоте по отклонению
		-- приземной виртуальной температуры.
		create or replace function public.fn_calc_mean_temp_deviation(
			par_surface_deviation integer, par_height_id integer)
		returns integer
		language plpgsql
		stable
		as $fn$
		declare
			var_code  text;
			var_abs   integer;
			var_part  integer;
			var_value integer;
			var_sum   integer default 0;
		begin
			if par_surface_deviation = 0 then
				return 0;
			end if;
			if abs(par_surface_deviation) > 59 then
				raise exception 'Отклонение % выходит за пределы Таблицы 2 (до 59)', par_surface_deviation;
			end if;
 
			var_code := case when par_surface_deviation > 0 then 'TBL2_POS' else 'TBL2_NEG' end;
			var_abs  := abs(par_surface_deviation);
 
			-- десятки, затем единицы
			foreach var_part in array array[(var_abs / 10) * 10, var_abs % 10]
			loop
				if var_part > 0 then
					var_value := public.fn_get_correction_value(var_code, par_height_id, var_part);
					if var_value is null then
						raise exception 'Таблица 2 (%): нет значения для столбца % (отклонение %)',
							var_code, var_part, par_surface_deviation;
					end if;
					var_sum := var_sum + var_value;
				end if;
			end loop;
 
			return var_sum;
		end;
		$fn$;
 
		-- Таблица 3: скорость среднего ветра по высоте и входному значению
		-- (V0 для ДМК, Дг для ВР).
		create or replace function public.fn_calc_table_speed(
			par_type_code text, par_height_id integer, par_x numeric)
		returns integer
		language plpgsql
		stable
		as $fn$
		declare
			var_headers integer[];
			var_x0      integer;
			var_x1      integer;
			var_y0      numeric;
			var_y1      numeric;
		begin
			select h.header_values
			into var_headers
			from public.calc_correction_types t
				inner join public.calc_correction_headers h on h.id = t.header_id
			where t.code = par_type_code;
 
			select max(v) filter (where v <= par_x), min(v) filter (where v >= par_x)
			into var_x0, var_x1
			from unnest(var_headers) as v;
 
			if var_x0 is null or var_x1 is null then
				raise exception 'Значение % вне столбцов таблицы %', par_x, par_type_code;
			end if;
 
			var_y0 := public.fn_get_correction_value(par_type_code, par_height_id, var_x0);
			var_y1 := public.fn_get_correction_value(par_type_code, par_height_id, var_x1);
			if var_y0 is null or var_y1 is null then
				raise exception 'Таблица %: нет данных для высоты (id %)', par_type_code, par_height_id;
			end if;
 
			if var_x0 = var_x1 then
				return var_y0::integer;
			end if;
			return round(var_y0 + (var_y1 - var_y0) * (par_x - var_x0) / (var_x1 - var_x0))::integer;
		end;
		$fn$;
	exception
		when others then
			raise notice 'Транзакция 7.1 (тип и вспомогательные функции) отменена: %', sqlerrm;
			raise;
	end;
 
	-- ТРАНЗАКЦИЯ 7.2. Процедура расчета
	begin
		-- Расчет Метео приближенный по каждой стандартной высоте.
		-- Расчет выполняется одним запросом по справочнику высот,
		-- цикл нужен только для вывода строк (raise notice).
		create or replace procedure public.sp_calc_meteo(
			par_params public.calc_input_params,
			par_equipment_id integer)
		language plpgsql
		as $fn$
		declare
			var_row           record;
			var_wind_input    numeric;
			var_min_wind      numeric;
			var_calm          boolean;
			var_speed_code    text;
			var_dir_code      text;
			var_correction    numeric;
			var_t0            numeric;
			var_surface_dev   integer;
			var_divisions     integer;
			var_neg_offset    integer;
			var_tmin          numeric;
			var_tmax          numeric;
		begin
			if par_params is null then
				raise exception 'Не переданы входные параметры';
			end if;
 
			-- Проверка входных данных
			var_tmin       := public.fn_get_calc_constant('MIN_TEMPERATURE');
			var_tmax       := public.fn_get_calc_constant('MAX_TEMPERATURE');
			var_divisions  := public.fn_get_calc_constant('DIRECTION_DIVISIONS')::integer;
			var_neg_offset := public.fn_get_calc_constant('NEG_TEMPERATURE_OFFSET')::integer;
 
			if par_params.temperature is null or par_params.temperature < var_tmin or par_params.temperature > var_tmax then
				raise exception 'Температура % вне диапазона % .. %', par_params.temperature, var_tmin, var_tmax;
			end if;
			if par_params.wind_direction is null or par_params.wind_direction < 0 or par_params.wind_direction >= var_divisions then
				raise exception 'Направление ветра % вне диапазона 0 .. %', par_params.wind_direction, var_divisions - 1;
			end if;
 
			-- Тип оборудования
			if par_equipment_id = public.fn_get_calc_constant('EQUIPMENT_DMK_ID')::integer then
				var_wind_input := par_params.wind_speed;
				var_min_wind   := public.fn_get_calc_constant('MIN_SURFACE_WIND_DMK');
			elsif par_equipment_id = public.fn_get_calc_constant('EQUIPMENT_VR_ID')::integer then
				var_wind_input := par_params.bullet_drift;
				var_min_wind   := public.fn_get_calc_constant('MIN_DRIFT_BP');
			else
				raise exception 'Неизвестный тип оборудования %', par_equipment_id;
			end if;
			if var_wind_input is null then
				raise exception 'Для типа оборудования % не задан параметр ветра (скорость ветра / дальность сноса пуль)', par_equipment_id;
			end if;
 
			select t.code into var_speed_code
			from public.calc_correction_types t
				inner join public.calc_correction_types p on p.id = t.parent_id
			where p.code = 'TBL3_SPEED' and t.measurment_equipment_id = par_equipment_id;
 
			select t.code into var_dir_code
			from public.calc_correction_types t
				inner join public.calc_correction_types p on p.id = t.parent_id
			where p.code = 'TBL3_DIR' and t.measurment_equipment_id = par_equipment_id;
 
			if var_speed_code is null or var_dir_code is null then
				raise exception 'Для типа оборудования % не найдены таблицы корректировок', par_equipment_id;
			end if;
 
			-- Приземная виртуальная температура и ее отклонение от 15.9.
			-- Вне диапазона узлов поправка плоская (значение крайнего узла).
			select min(c.temperature), max(c.temperature)
			into var_correction, var_t0
			from public.popravki_virtualnoj_temperatury c;
 
			var_correction  := public.fn_calc_temperature_interpolation(
				greatest(var_correction, least(var_t0, par_params.temperature)));
			var_t0          := par_params.temperature + var_correction;
			var_surface_dev := round(var_t0 - public.fn_get_calc_constant('TABLE_TEMPERATURE'))::integer;
 
			-- Слабый ветер: направление и скорость нулевые на всех высотах
			var_calm := var_wind_input < var_min_wind;
 
			raise notice 'Отклонение приземной виртуальной температуры: %', var_surface_dev;
 
			for var_row in
				select h.height as height_m,
				       t.temp_deviation,
				       case when var_calm then 0
				            else public.fn_calc_table_speed(var_speed_code, h.id, var_wind_input)
				       end as wind_speed,
				       case when var_calm then 0
				            else mod(par_params.wind_direction::integer + d.delta, var_divisions)
				       end as wind_direction,
				       d.delta
				from public.calc_correction_heights h
					cross join lateral (
						select public.fn_calc_mean_temp_deviation(var_surface_dev, h.id) as temp_deviation
					) t
					left join (
						select c.height_id, c.row_values[1] as delta
						from public.calc_correction c
							inner join public.calc_correction_types ct on ct.id = c.type_id
						where ct.code = var_dir_code
					) d on d.height_id = h.id
				order by h.height
			loop
				if not var_calm and var_row.delta is null then
					raise exception 'Таблица %: нет приращения направления для высоты %', var_dir_code, var_row.height_m;
				end if;
 
				raise notice 'H = %, ТТ = %, НН = %, СС = %',
					lpad(var_row.height_m::text, 4),
					to_char(case when var_row.temp_deviation < 0
					             then abs(var_row.temp_deviation) + var_neg_offset
					             else var_row.temp_deviation end, 'FM00'),
					to_char(var_row.wind_direction, 'FM00'),
					to_char(var_row.wind_speed, 'FM00');
			end loop;
		end;
		$fn$;
 
		comment on procedure public.sp_calc_meteo(public.calc_input_params, integer)
			is 'Расчет Метео приближенный: на входе параметры и тип оборудования, на выходе (notice) ТТ, НН, СС по каждой стандартной высоте';
	exception
		when others then
			raise notice 'Транзакция 7.2 (процедура расчета) отменена: %', sqlerrm;
			raise;
	end;
 
 
	-- 8. Проверка согласованности данных справочников
 
	-- ТРАНЗАКЦИЯ 8
	begin
		-- Число значений в строке не больше числа столбцов заголовка;
		-- нет заголовка - одно значение на всю строку
		if exists (
			select 1
			from public.calc_correction c
				inner join public.calc_correction_types t on t.id = c.type_id
				left join public.calc_correction_headers h on h.id = t.header_id
			where (h.id is not null and cardinality(c.row_values) > cardinality(h.header_values))
			   or (h.id is null and cardinality(c.row_values) <> 1)
		) then
			raise exception 'Число значений в строке не соответствует заголовку таблицы';
		end if;
 
		-- Для каждого конечного типа таблицы есть строка на каждую стандартную высоту
		if exists (
			select 1
			from public.calc_correction_types t
			where not exists (select 1 from public.calc_correction_types ch where ch.parent_id = t.id)
			  and (select count(*) from public.calc_correction c where c.type_id = t.id)
			    <> (select count(*) from public.calc_correction_heights)
		) then
			raise exception 'Для одного из типов таблиц заданы не все стандартные высоты';
		end if;
	exception
		when others then
			raise notice 'Транзакция 8 (проверка данных) отменена: %', sqlerrm;
			raise;
	end;
 
end $$;
 