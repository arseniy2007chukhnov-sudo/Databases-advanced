-- Type: t_interpolation

-- DROP TYPE IF EXISTS public.t_interpolation;

CREATE TYPE public.t_interpolation AS
(
	x0 numeric(8,2),
	y0 numeric(8,2),
	x1 numeric(8,2),
	y1 numeric(8,2)
);

ALTER TYPE public.t_interpolation
    OWNER TO aosu;
