-- FUNCTION: public.f_get_interpolation_params(numeric)

-- DROP FUNCTION IF EXISTS public.f_get_interpolation_params(numeric);

CREATE OR REPLACE FUNCTION public.f_get_interpolation_params(
	p_temperature numeric)
    RETURNS t_interpolation
    LANGUAGE 'plpgsql'
    COST 100
    STABLE PARALLEL UNSAFE
AS $BODY$
declare
    v_result  public.t_interpolation;
    v_low_to  numeric;
    v_low_d   numeric;
    v_max_t   numeric;
    v_max_d   numeric;
begin
    if p_temperature is null then
        return null;
    end if;

    -- Граничное условие: ниже диапазона 'Ниже 0' (поправка плоская)
    select p.t_to, p.delta_tv
      into v_low_to, v_low_d
    from public.popravki_virtualnoj_temperatury p
    where p.t_from < 0
    order by p.t_from
    limit 1;

    if p_temperature < v_low_to then
        v_result.x0 := p_temperature;
        v_result.y0 := v_low_d;
        v_result.x1 := v_low_to;
        v_result.y1 := v_low_d;
        return v_result;
    end if;

    -- Граничное условие: выше максимальной границы таблицы (поправка плоская)
    select max(p.t_to) into v_max_t
    from public.popravki_virtualnoj_temperatury p;

    select p.delta_tv into v_max_d
    from public.popravki_virtualnoj_temperatury p
    where p.t_to = v_max_t
    limit 1;

    if p_temperature > v_max_t then
        v_result.x0 := v_max_t;
        v_result.y0 := v_max_d;
        v_result.x1 := p_temperature;
        v_result.y1 := v_max_d;
        return v_result;
    end if;

    -- Нижний узел: ближайшая граница <= температуры
    select n.t, n.d
      into v_result.x0, v_result.y0
    from (
        select p.t_from as t, p.delta_tv as d
          from public.popravki_virtualnoj_temperatury p where p.t_from >= 0
        union
        select p.t_to, p.delta_tv
          from public.popravki_virtualnoj_temperatury p where p.t_from >= 0
    ) n
    where n.t <= p_temperature
    order by n.t desc
    limit 1;

    -- Верхний узел: ближайшая граница >= температуры
    select n.t, n.d
      into v_result.x1, v_result.y1
    from (
        select p.t_from as t, p.delta_tv as d
          from public.popravki_virtualnoj_temperatury p where p.t_from >= 0
        union
        select p.t_to, p.delta_tv
          from public.popravki_virtualnoj_temperatury p where p.t_from >= 0
    ) n
    where n.t >= p_temperature
    order by n.t
    limit 1;

    return v_result;
end;
$BODY$;

ALTER FUNCTION public.f_get_interpolation_params(numeric)
    OWNER TO aosu;

