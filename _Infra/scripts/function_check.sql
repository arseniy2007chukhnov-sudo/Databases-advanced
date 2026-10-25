do $test$
declare
    v_point  public.t_interpolation;
    v_y      numeric;
    v_t0     numeric;
    v_dev    numeric;
    v_fail   integer := 0;
begin
    raise notice '=== Проверка f_get_interpolation_params ===';

    -- Пример из задания: 26 -> 25 - 2 и 30 - 3.5
    v_point := public.f_get_interpolation_params(26);
    if (v_point.x0, v_point.y0, v_point.x1, v_point.y1) = (25, 2, 30, 3.5) then
        raise notice 'OK   t=26: x0-y0 = % - %, x1-y1 = % - %', v_point.x0, v_point.y0, v_point.x1, v_point.y1;
    else
        raise notice 'FAIL t=26: получено %', v_point; v_fail := v_fail + 1;
    end if;

    -- Точное попадание в узел
    v_point := public.f_get_interpolation_params(25);
    if (v_point.x0, v_point.y0, v_point.x1, v_point.y1) = (25, 2, 25, 2) then
        raise notice 'OK   t=25 (узел): x0-y0 = % - %, x1-y1 = % - %', v_point.x0, v_point.y0, v_point.x1, v_point.y1;
    else
        raise notice 'FAIL t=25: получено %', v_point; v_fail := v_fail + 1;
    end if;

    -- Граница диапазона 0
    v_point := public.f_get_interpolation_params(0);
    if (v_point.x0, v_point.y0, v_point.x1, v_point.y1) = (0, 0.5, 0, 0.5) then
        raise notice 'OK   t=0: x0-y0 = % - %, x1-y1 = % - %', v_point.x0, v_point.y0, v_point.x1, v_point.y1;
    else
        raise notice 'FAIL t=0: получено %', v_point; v_fail := v_fail + 1;
    end if;

    -- Промежуток между диапазонами 0-5 и 10-15
    v_point := public.f_get_interpolation_params(7);
    if (v_point.x0, v_point.y0, v_point.x1, v_point.y1) = (5, 0.5, 10, 1) then
        raise notice 'OK   t=7: x0-y0 = % - %, x1-y1 = % - %', v_point.x0, v_point.y0, v_point.x1, v_point.y1;
    else
        raise notice 'FAIL t=7: получено %', v_point; v_fail := v_fail + 1;
    end if;

    -- Ниже 0
    v_point := public.f_get_interpolation_params(-10);
    if (v_point.x0, v_point.y0, v_point.x1, v_point.y1) = (-10, 0, 0, 0) then
        raise notice 'OK   t=-10 (ниже 0): x0-y0 = % - %, x1-y1 = % - %', v_point.x0, v_point.y0, v_point.x1, v_point.y1;
    else
        raise notice 'FAIL t=-10: получено %', v_point; v_fail := v_fail + 1;
    end if;

    -- Выше 40
    v_point := public.f_get_interpolation_params(50);
    if (v_point.x0, v_point.y0, v_point.x1, v_point.y1) = (40, 4.5, 50, 4.5) then
        raise notice 'OK   t=50 (выше 40): x0-y0 = % - %, x1-y1 = % - %', v_point.x0, v_point.y0, v_point.x1, v_point.y1;
    else
        raise notice 'FAIL t=50: получено %', v_point; v_fail := v_fail + 1;
    end if;

    raise notice '=== Проверка f_calc_interpolation ===';

    -- пример 1: t0 = 23 => ΔTv = 1.8 (теперь прямо из таблицы)
    v_y := public.f_calc_interpolation(23, public.f_get_interpolation_params(23));
    if v_y = 1.8 then
        raise notice 'OK   пример 1: ΔTv(23) = %', v_y;
    else
        raise notice 'FAIL пример 1: ожидалось 1.8, получено %', v_y; v_fail := v_fail + 1;
    end if;

    v_y := public.f_calc_interpolation(26, public.f_get_interpolation_params(26));
    if v_y = 2.3 then
        raise notice 'OK   t=26: поправка = %', v_y;
    else
        raise notice 'FAIL t=26: ожидалось 2.3, получено %', v_y; v_fail := v_fail + 1;
    end if;

    v_y := public.f_calc_interpolation(25, public.f_get_interpolation_params(25));
    if v_y = 2 then
        raise notice 'OK   t=25 (узел): поправка = %', v_y;
    else
        raise notice 'FAIL t=25: ожидалось 2, получено %', v_y; v_fail := v_fail + 1;
    end if;

    v_y := public.f_calc_interpolation(7, public.f_get_interpolation_params(7));
    if v_y = 0.7 then
        raise notice 'OK   t=7: поправка = %', v_y;
    else
        raise notice 'FAIL t=7: ожидалось 0.7, получено %', v_y; v_fail := v_fail + 1;
    end if;

    v_y := public.f_calc_interpolation(-10, public.f_get_interpolation_params(-10));
    if v_y = 0 then
        raise notice 'OK   t=-10: поправка = %', v_y;
    else
        raise notice 'FAIL t=-10: ожидалось 0, получено %', v_y; v_fail := v_fail + 1;
    end if;

    v_y := public.f_calc_interpolation(50, public.f_get_interpolation_params(50));
    if v_y = 4.5 then
        raise notice 'OK   t=50: поправка = %', v_y;
    else
        raise notice 'FAIL t=50: ожидалось 4.5, получено %', v_y; v_fail := v_fail + 1;
    end if;

    raise notice '=== Проверка расчета ТТ (отклонение температуры) ===';

    -- пример 1: T0 = 23 + 1.8 = 24.8, отклонение 8.9 -> 9 -> '09'
    v_t0  := 23 + public.f_calc_interpolation(23, public.f_get_interpolation_params(23));
    v_dev := round(v_t0 - 15.9);
    if v_t0 = 24.8 and to_char(v_dev, 'FM00') = '09' then
        raise notice 'OK   пример 1: T0 = %, ТТ = %', v_t0, to_char(v_dev, 'FM00');
    else
        raise notice 'FAIL пример 1: T0 = %, ТТ = %', v_t0, to_char(v_dev, 'FM00'); v_fail := v_fail + 1;
    end if;

    -- пример 2: t = 25 => T0 = 27, отклонение 11.1 -> 11
    v_t0  := 25 + public.f_calc_interpolation(25, public.f_get_interpolation_params(25));
    v_dev := round(v_t0 - 15.9);
    if to_char(v_dev, 'FM00') = '11' then
        raise notice 'OK   пример 2: T0 = %, ТТ = %', v_t0, to_char(v_dev, 'FM00');
    else
        raise notice 'FAIL пример 2: T0 = %, ТТ = %', v_t0, to_char(v_dev, 'FM00'); v_fail := v_fail + 1;
    end if;

    if v_fail = 0 then
        raise notice '=== ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ ===';
    else
        raise exception '=== ПРОВАЛЕНО ПРОВЕРОК: % ===', v_fail;
    end if;
end $test$;