do $test$
declare
	v_cur    refcursor;
	v_row    record;
	v_h200   integer;
	v_h4000  integer;
	v_fail   integer;
	r        record;
begin
	select id into v_h200  from public.calc_correction_heights where height = 200;
	select id into v_h4000 from public.calc_correction_heights where height = 4000;
 
	create temp table tmp_test_results
	(
		n serial,
		name text,
		expected text,
		actual text
	) on commit drop;
 

	-- 1. Таблица 2 (пример из алгоритма ДМК)

	insert into tmp_test_results(name, expected, actual) values
	('Таблица 2: отклонение -13, 200 м (-10 и -3 => -9 + -3)', '-12', public.fn_calc_mean_temp_deviation(-13, v_h200)::text),
	('Таблица 2: ТТ для -12 => |-12| + 50 (ТЗ: 62)',            '62',  to_char(abs(public.fn_calc_mean_temp_deviation(-13, v_h200)) + 50, 'FM00')),
	('Таблица 2: отклонение +9, 200 м',                          '9',   public.fn_calc_mean_temp_deviation(9, v_h200)::text),
	('Таблица 2: отклонение +11, 4000 м (10 и 1)',               '11',  public.fn_calc_mean_temp_deviation(11, v_h4000)::text),
	('Таблица 2: отклонение -27, 4000 м (-20 и -7 => -14 + -4)', '-18', public.fn_calc_mean_temp_deviation(-27, v_h4000)::text),
	('Таблица 2: отклонение 0',                                  '0',   public.fn_calc_mean_temp_deviation(0, v_h200)::text);
 
	-- 2. Поправка ΔTv (ТЗ, пример 1: t0 = 23 => 1,8)
	insert into tmp_test_results(name, expected, actual) values
	('ΔTv при t0 = 23 (ТЗ: 1,8)', '1.80', public.fn_calc_temperature_interpolation(23)::numeric(8,2)::text);
 

	-- 3. Таблица 3: скорость среднего ветра

	insert into tmp_test_results(name, expected, actual) values
	('Таблица 3 ДМК: V0 = 6, 200 м',            '9',  public.fn_calc_table_speed('TBL3_SPEED_DMK', v_h200, 6)::text),
	('Таблица 3 ДМК: V0 = 15, 4000 м',          '36', public.fn_calc_table_speed('TBL3_SPEED_DMK', v_h4000, 15)::text),
	('Таблица 3 ВР: Дг = 100, 200 м',           '8',  public.fn_calc_table_speed('TBL3_SPEED_VR', v_h200, 100)::text),
	('Таблица 3 ВР: Дг = 150, 4000 м',          '20', public.fn_calc_table_speed('TBL3_SPEED_VR', v_h4000, 150)::text),
	('Таблица 3 ВР: Дг = 45, 200 м (между 3 и 4, интерполяция)', '4', public.fn_calc_table_speed('TBL3_SPEED_VR', v_h200, 45)::text);
 
	-- 4. Процедура, ДМК: пример 2 из ТЗ
	
	raise notice '=== ДМК: высота 100, давление 765, t = 25, направление 15, V0 = 6 ===';
	call public.sp_calc_meteo(row(100, 25, 765, 15, 6, null)::public.calc_input_params, 1, v_cur);
 
	insert into tmp_test_results(name, expected, actual) values ('ДМК пример 2: число высот в результате', '9', '0');
	loop
		fetch v_cur into v_row;
		exit when not found;
 
		raise notice 'H = %, ТТ = %, НН = %, СС = %', lpad(v_row.height_m::text, 4), v_row.tt, v_row.hh, v_row.cc;
 
		update tmp_test_results set actual = (actual::integer + 1)::text where name = 'ДМК пример 2: число высот в результате';
		if v_row.height_m = 200 then
			insert into tmp_test_results(name, expected, actual)
			values ('ДМК пример 2: 200 м (ТТ-НН-СС)', '11-16-09', v_row.tt || '-' || v_row.hh || '-' || v_row.cc);
		elsif v_row.height_m = 4000 then
			insert into tmp_test_results(name, expected, actual)
			values ('ДМК пример 2: 4000 м (ТТ-НН-СС)', '11-20-14', v_row.tt || '-' || v_row.hh || '-' || v_row.cc);
		end if;
	end loop;
	close v_cur;
 

	-- 5. Процедура, ВР: t = 15 (t0 = 16, отклонение 0), направление 10, Дг = 100

	raise notice '=== ВР: высота 100, давление 750, t = 15, направление 10, Дг = 100 ===';
	call public.sp_calc_meteo(row(100, 15, 750, 10, null, 100)::public.calc_input_params, 2, v_cur);
	loop
		fetch v_cur into v_row;
		exit when not found;
 
		raise notice 'H = %, ТТ = %, НН = %, СС = %', lpad(v_row.height_m::text, 4), v_row.tt, v_row.hh, v_row.cc;
 
		if v_row.height_m = 200 then
			insert into tmp_test_results(name, expected, actual)
			values ('ВР: 200 м (ТТ-НН-СС)', '00-10-08', v_row.tt || '-' || v_row.hh || '-' || v_row.cc);
		elsif v_row.height_m = 4000 then
			insert into tmp_test_results(name, expected, actual)
			values ('ВР: 4000 м (ТТ-НН-СС)', '00-14-12', v_row.tt || '-' || v_row.hh || '-' || v_row.cc);
		end if;
	end loop;
	close v_cur;
 

	-- 6. Переход через 60 больших делений: 58 + 5 = 63 => 03

	call public.sp_calc_meteo(row(100, 25, 765, 58, 6, null)::public.calc_input_params, 1, v_cur);
	loop
		fetch v_cur into v_row;
		exit when not found;
		if v_row.height_m = 4000 then
			insert into tmp_test_results(name, expected, actual)
			values ('ДМК: направление 58 + 5 на 4000 м', '03', v_row.hh);
		end if;
	end loop;
	close v_cur;
 

	-- 7. Слабый ветер: ДМК V0 = 2 и ВР Дг = 39 => нули на всех высотах

	insert into tmp_test_results(name, expected, actual)
	select 'ДМК V0 = 2: все высоты НН = 00, СС = 00', '9',
	       count(*)::text
	from public.fn_calc_meteo_bulletin(row(100, 25, 765, 15, 2, null)::public.calc_input_params, 1) b
	where b.hh = '00' and b.cc = '00';
 
	insert into tmp_test_results(name, expected, actual)
	select 'ВР Дг = 39: все высоты НН = 00, СС = 00', '9',
	       count(*)::text
	from public.fn_calc_meteo_bulletin(row(100, 15, 750, 10, null, 39)::public.calc_input_params, 2) b
	where b.hh = '00' and b.cc = '00';
 
	-- 8. Ошибки во входных данных должны приводить к исключению

	begin
		perform * from public.fn_calc_meteo_bulletin(row(100, 60, 765, 15, 6, null)::public.calc_input_params, 1);
		insert into tmp_test_results(name, expected, actual) values ('Температура 60 (> 58)', 'ошибка', 'нет ошибки');
	exception when others then
		insert into tmp_test_results(name, expected, actual) values ('Температура 60 (> 58)', 'ошибка', 'ошибка');
	end;
 
	begin
		perform * from public.fn_calc_meteo_bulletin(row(100, 25, 765, 15, 6, null)::public.calc_input_params, 99);
		insert into tmp_test_results(name, expected, actual) values ('Неизвестное оборудование 99', 'ошибка', 'нет ошибки');
	exception when others then
		insert into tmp_test_results(name, expected, actual) values ('Неизвестное оборудование 99', 'ошибка', 'ошибка');
	end;
 
	begin
		perform * from public.fn_calc_meteo_bulletin(row(100, 25, 765, 15, null, 100)::public.calc_input_params, 1);
		insert into tmp_test_results(name, expected, actual) values ('ДМК без скорости ветра', 'ошибка', 'нет ошибки');
	exception when others then
		insert into tmp_test_results(name, expected, actual) values ('ДМК без скорости ветра', 'ошибка', 'ошибка');
	end;
 
	-- -----------------------------------------------------------------
	-- Итог
	-- -----------------------------------------------------------------
	raise notice '=== Результаты проверок ===';
	v_fail := 0;
	for r in select * from tmp_test_results order by n loop
		if r.expected = r.actual then
			raise notice 'OK   % : %', r.name, r.actual;
		else
			raise notice 'FAIL % : ожидалось %, получено %', r.name, r.expected, r.actual;
			v_fail := v_fail + 1;
		end if;
	end loop;
 
	if v_fail = 0 then
		raise notice '=== ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ ===';
	else
		raise exception '=== ПРОВАЛЕНО ПРОВЕРОК: % ===', v_fail;
	end if;
end $test$;