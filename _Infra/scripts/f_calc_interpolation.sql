-- FUNCTION: public.f_calc_interpolation(numeric, t_interpolation)

-- DROP FUNCTION IF EXISTS public.f_calc_interpolation(numeric, t_interpolation);

CREATE OR REPLACE FUNCTION public.f_calc_interpolation(
	p_x numeric,
	p_point t_interpolation)
    RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
begin
    if p_x is null or p_point is null then
        return null;
    end if;

    -- Точное попадание в узел таблицы (деление на ноль невозможно)
    if p_point.x1 = p_point.x0 then
        return p_point.y0;
    end if;

    return p_point.y0
         + (p_x - p_point.x0) * (p_point.y1 - p_point.y0)
           / (p_point.x1 - p_point.x0);
end;
$BODY$;

ALTER FUNCTION public.f_calc_interpolation(numeric, t_interpolation)
    OWNER TO aosu;

