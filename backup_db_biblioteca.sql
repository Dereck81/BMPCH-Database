--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_cron; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION pg_cron; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_cron IS 'Job scheduler for PostgreSQL';


--
-- Name: fn_actualizar_carnets(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_actualizar_carnets() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    id_tipo_estado_vencido BIGINT;
    cantidad_carnets_por_vencer BIGINT;
BEGIN
    -- Calcular la cantidad de carnets por vencer
    SELECT COUNT(carn_fec_vencimiento) INTO cantidad_carnets_por_vencer
    FROM tb_carnet
    WHERE carn_fec_vencimiento = CURRENT_DATE - INTERVAL '1 day';

    -- Definir el estado vencido
    id_tipo_estado_vencido := 2;

    -- Actualización automática de carnet para clientes
    UPDATE tb_carnet
    SET carn_tipo_estado_id = id_tipo_estado_vencido
    WHERE carn_fec_vencimiento = CURRENT_DATE - INTERVAL '1 day';

    -- Actualización automática de carnet para administradores y cambio de su estado a activo
    UPDATE tb_carnet AS CR
    SET carn_tipo_estado_id = 1,
        carn_fec_emision = CURRENT_DATE,
        carn_fec_vencimiento = CURRENT_DATE + INTERVAL '1 year'
    FROM tb_cliente AS CL
        INNER JOIN tb_usuario AS U ON U.usua_id = CL.clie_usuario_id
    WHERE CL.clie_carnet_id = CR.carn_id
      AND U.usua_rol_usuario_id = 1
      AND (CR.carn_tipo_estado_id = id_tipo_estado_vencido
      OR CR.carn_fec_vencimiento = CURRENT_DATE - INTERVAL '1 day');
END
$$;


ALTER FUNCTION public.fn_actualizar_carnets() OWNER TO postgres;

--
-- Name: fn_actualizar_prestamos(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_actualizar_prestamos() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    id_tipo_estado_vencido BIGINT;
BEGIN
    -- Definir el estado vencido
    id_tipo_estado_vencido := 3;

    -- Actualización automática de estado de prestamos
    UPDATE tb_prestamo
    SET pres_estado_prestamo_id = id_tipo_estado_vencido
    WHERE pres_estado_prestamo_id = 1 AND pres_fec_programada = CURRENT_DATE - INTERVAL '1 day';
END
$$;


ALTER FUNCTION public.fn_actualizar_prestamos() OWNER TO postgres;

--
-- Name: fn_realizar_prestamo(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_realizar_prestamo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.pres_estado_prestamo_id IS NOT NULL THEN  -- UPDATE
        -- Esto se ejecuta solamente cuando al actualizar el registro, se cambian de recurso textual
        IF NEW.pres_recurso_textual_codigo_id <> OLD.pres_recurso_textual_codigo_id THEN
            -- Se cambia el antigo recurso textual a reco_disponible = TRUE
            -- debido a que deja de estar en uso por el prestamo actual.
            UPDATE tb_recurso_textual_codigo SET reco_disponible = TRUE
                WHERE reco_id = OLD.pres_recurso_textual_codigo_id;

            /*
             * En este caso, si el "OLD._prestamo_id <> 2" (NO DEVUELTO | [1, 3, ...])
             se establece como reco_disponible = FALSE al nuevo recurso textual, debido a que
             el antiguo estado era NO DEVUELTO.
             * En el caso, de que el antiguo estado sea (DEVUELTO | 2) no se modifica, debido a que
             se supone que el prestamo fue aceptado porque el nuevo recurso textual estaba disponible.
             */
            IF OLD.pres_estado_prestamo_id <> 2 THEN
                UPDATE tb_recurso_textual_codigo SET reco_disponible = FALSE
                WHERE reco_id = NEW.pres_recurso_textual_codigo_id;
            END IF;

        END IF;

        -- CASE: NEW._prestamo_id = DEVUELTO Y OLD._prestamo_id = NO DEVUELTO
        IF NEW.pres_estado_prestamo_id = 2 AND OLD.pres_estado_prestamo_id <> 2 THEN
            UPDATE tb_recurso_textual_codigo SET reco_disponible = TRUE
            WHERE reco_id = NEW.pres_recurso_textual_codigo_id;
        END IF;

        -- CASE: NEW._prestamo_id = NO DEVUELTO Y OLD._prestamo_id = DEVUELTO
        IF NEW.pres_estado_prestamo_id = 1 AND OLD.pres_estado_prestamo_id = 2 THEN
            UPDATE tb_recurso_textual_codigo SET reco_disponible = FALSE
            WHERE reco_id = NEW.pres_recurso_textual_codigo_id;
        END IF;
    ELSE -- INSERT
        IF NEW.pres_estado_prestamo_id <> 2 THEN
            UPDATE tb_recurso_textual_codigo SET reco_disponible = FALSE
            WHERE reco_id = NEW.pres_recurso_textual_codigo_id;
        ELSE
            UPDATE tb_recurso_textual_codigo SET reco_disponible = TRUE
            WHERE reco_id = NEW.pres_recurso_textual_codigo_id;
        END IF;
    END IF;

    RETURN NEW;
END
$$;


ALTER FUNCTION public.fn_realizar_prestamo() OWNER TO postgres;

--
-- Name: fn_verificar_carnet_cambio_estado(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_verificar_carnet_cambio_estado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    f_estado_carnet_actual BOOLEAN;
    f_estado_carnet_nuevo BOOLEAN;
    f_mensaje VARCHAR;
BEGIN

    f_mensaje := 'Falló al cambiar el tipo de estado del carnet:';

    SELECT TIE.ties_activo INTO f_estado_carnet_actual
            FROM tb_carnet AS CRN INNER JOIN tb_tipo_estado AS TIE
                ON CRN.carn_tipo_estado_id = TIE.ties_id
            WHERE carn_id = NEW.carn_id;

    f_estado_carnet_nuevo := (
        SELECT ties_activo FROM tb_tipo_estado WHERE ties_id = NEW.carn_tipo_estado_id
    );

    CASE
        WHEN NEW.carn_tipo_estado_id = 1 AND NEW.carn_fec_vencimiento <= (CURRENT_DATE - INTERVAL '1 DAY') THEN
            RAISE EXCEPTION '%s La fecha de vencimiento es menor a la fecha actual.', f_mensaje;
        WHEN NEW.carn_tipo_estado_id = 2 AND NEW.carn_fec_vencimiento >= CURRENT_DATE THEN
            RAISE EXCEPTION '%s La fecha de vencimiento es mayor o igual a la fecha actual.', f_mensaje;
        ELSE
            NULL;
    END CASE;

    RETURN NEW;

END;
$$;


ALTER FUNCTION public.fn_verificar_carnet_cambio_estado() OWNER TO postgres;

--
-- Name: fn_verificar_recurso_textual_creacion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_verificar_recurso_textual_creacion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF NEW.rete_fec_publicacion > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de publicación no puede ser futura.';
    END IF;

    RETURN NEW;

END;
$$;


ALTER FUNCTION public.fn_verificar_recurso_textual_creacion() OWNER TO postgres;

--
-- Name: fn_verificar_requisitos_prestamos(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_verificar_requisitos_prestamos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    f_estado_carnet BOOLEAN;
    f_recurso_textual_disponible BOOLEAN;
    f_recurso_textual_ejemplar_disponible BOOLEAN;
    f_recurso_textual_codigo_base_nuevo VARCHAR;
    f_recurso_textual_codigo_base_antiguo VARCHAR;
    f_recurso_textual_stock_disp_nuevo INT;
BEGIN

    f_estado_carnet := (
        SELECT TIE.ties_activo FROM tb_cliente AS CLI
                INNER JOIN tb_carnet AS CAR ON CAR.carn_id = CLI.clie_carnet_id
                INNER JOIN tb_tipo_estado AS TIE ON TIE.ties_id = CAR.carn_tipo_estado_id
        WHERE CLI.clie_id = NEW.pres_cliente_id
    );

    IF f_estado_carnet IS NULL THEN
        RAISE EXCEPTION 'El usuario no tiene un carnet establecido';
    END IF;

    IF NOT f_estado_carnet AND COALESCE(NEW.pres_cliente_id <> OLD.pres_cliente_id, TRUE) THEN
        RAISE EXCEPTION 'El estado del carnet del cliente (%) no está activo', NEW.pres_cliente_id;
    END IF;

    SELECT RT.rete_activo, RTC.reco_disponible
    INTO f_recurso_textual_disponible, f_recurso_textual_ejemplar_disponible
    FROM tb_recurso_textual_codigo AS RTC
    INNER JOIN tb_recurso_textual AS RT ON RTC.reco_rete_codigo_base = RT.rete_codigo_base
    WHERE RTC.reco_id = NEW.pres_recurso_textual_codigo_id;

    IF (NOT f_recurso_textual_disponible
        AND COALESCE(NEW.pres_recurso_textual_codigo_id <> OLD.pres_recurso_textual_codigo_id, TRUE)) THEN
        RAISE EXCEPTION 'El recurso textual no se encuentra disponible';
    END IF;

    IF (NOT f_recurso_textual_ejemplar_disponible
        AND COALESCE(NEW.pres_recurso_textual_codigo_id <> OLD.pres_recurso_textual_codigo_id, TRUE)) THEN
        RAISE EXCEPTION 'El ejemplar del recurso textual no está disponible. (%)',
            NEW.pres_recurso_textual_codigo_id;
    END IF;

    f_recurso_textual_codigo_base_nuevo := (
        SELECT reco_rete_codigo_base FROM tb_recurso_textual_codigo
        WHERE reco_id = NEW.pres_recurso_textual_codigo_id
    );

    f_recurso_textual_codigo_base_antiguo := (
        SELECT reco_rete_codigo_base FROM tb_recurso_textual_codigo
        WHERE reco_id = OLD.pres_recurso_textual_codigo_id
    );

    f_recurso_textual_stock_disp_nuevo := (
        SELECT COUNT(reco_rete_codigo_base) FROM tb_recurso_textual_codigo
        WHERE reco_rete_codigo_base = f_recurso_textual_codigo_base_nuevo AND reco_disponible = TRUE
    );

    IF (f_recurso_textual_stock_disp_nuevo < 2
           AND COALESCE(f_recurso_textual_codigo_base_nuevo <> f_recurso_textual_codigo_base_antiguo, TRUE)) THEN
        RAISE EXCEPTION 'No se puede realizar la operación, debe de quedar al menos un ejemplar en la biblioteca';
    END IF;

    IF (NEW.pres_fec_inicial <> CURRENT_DATE
            AND COALESCE(NEW.pres_fec_inicial <> OLD.pres_fec_inicial, TRUE)) THEN
        RAISE EXCEPTION 'No se puede realizar la operación, la fecha inicial no puede ser menor o mayor a la actual.';
    END IF ;

    IF NEW.pres_fec_final < NEW.pres_fec_inicial THEN
        RAISE EXCEPTION 'No se puede realizar la operación, la fecha final no puede ser menor que la inicial.';
    END IF;

    IF NEW.pres_fec_programada < NEW.pres_fec_inicial THEN
        RAISE EXCEPTION 'No se puede realizar la operación, la fecha programada no puede ser menor a la inicial.';
    END IF ;

    IF OLD.pres_fec_final IS NOT NULL THEN
        RAISE EXCEPTION 'No se puede modificar el prestamo, ya se estableció una fecha final';
    END IF;

    IF NEW.pres_fec_final IS NULL AND NEW.pres_estado_prestamo_id = 2 THEN
        RAISE EXCEPTION 'No se puede realizar la operación, debido a que el prestamo está con estado devuelto y fecha final nula';
    END IF;

    IF NEW.pres_fec_final IS NOT NULL AND NEW.pres_estado_prestamo_id <> 2 THEN
        RAISE EXCEPTION 'No se puede realizar la operación, debido a que el prestamo está con fecha final, pero el estado es diferente a devuelto';
    END IF;

    RETURN NEW;

END;
$$;


ALTER FUNCTION public.fn_verificar_requisitos_prestamos() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: tb_autor; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_autor (
    auto_id bigint NOT NULL,
    auto_nombre character varying(255) NOT NULL,
    auto_apellido_paterno character varying(255) NOT NULL,
    auto_apellido_materno character varying(255),
    auto_activo boolean DEFAULT true
);


ALTER TABLE public.tb_autor OWNER TO bmpch_user;

--
-- Name: tb_autor_auto_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_autor_auto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_autor_auto_id_seq OWNER TO bmpch_user;

--
-- Name: tb_autor_auto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_autor_auto_id_seq OWNED BY public.tb_autor.auto_id;


--
-- Name: tb_carnet; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_carnet (
    carn_id bigint NOT NULL,
    carn_tipo_estado_id smallint NOT NULL,
    carn_codigo character varying(255) NOT NULL,
    carn_fec_emision date DEFAULT CURRENT_DATE NOT NULL,
    carn_fec_vencimiento date DEFAULT (CURRENT_DATE + '1 year'::interval) NOT NULL,
    CONSTRAINT chk_fec_vencimiento_carnet CHECK ((carn_fec_vencimiento > carn_fec_emision))
);


ALTER TABLE public.tb_carnet OWNER TO bmpch_user;

--
-- Name: tb_carnet_carn_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_carnet_carn_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_carnet_carn_id_seq OWNER TO bmpch_user;

--
-- Name: tb_carnet_carn_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_carnet_carn_id_seq OWNED BY public.tb_carnet.carn_id;


--
-- Name: tb_categoria; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_categoria (
    cate_id bigint NOT NULL,
    cate_nombre character varying(255) NOT NULL
);


ALTER TABLE public.tb_categoria OWNER TO bmpch_user;

--
-- Name: tb_categoria_cate_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_categoria_cate_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_categoria_cate_id_seq OWNER TO bmpch_user;

--
-- Name: tb_categoria_cate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_categoria_cate_id_seq OWNED BY public.tb_categoria.cate_id;


--
-- Name: tb_categoria_recurso_textual; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_categoria_recurso_textual (
    care_recurso_textual_id bigint NOT NULL,
    care_categoria_id bigint NOT NULL
);


ALTER TABLE public.tb_categoria_recurso_textual OWNER TO bmpch_user;

--
-- Name: tb_cliente; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_cliente (
    clie_id bigint NOT NULL,
    clie_usuario_id bigint NOT NULL,
    clie_direccion_id bigint NOT NULL,
    clie_correo character varying(255) NOT NULL,
    clie_carnet_id bigint NOT NULL,
    clie_nivel_educativo_id smallint NOT NULL,
    CONSTRAINT chk_cliente_correo CHECK (((clie_correo)::text ~ '^[a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*@[a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*[.][a-zA-Z]{2,5}$'::text))
);


ALTER TABLE public.tb_cliente OWNER TO bmpch_user;

--
-- Name: tb_cliente_clie_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_cliente_clie_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_cliente_clie_id_seq OWNER TO bmpch_user;

--
-- Name: tb_cliente_clie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_cliente_clie_id_seq OWNED BY public.tb_cliente.clie_id;


--
-- Name: tb_direccion_cliente; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_direccion_cliente (
    dicl_id bigint NOT NULL,
    dicl_distrito_id bigint NOT NULL,
    dicl_direccion character varying(255) NOT NULL
);


ALTER TABLE public.tb_direccion_cliente OWNER TO bmpch_user;

--
-- Name: tb_direccion_cliente_dicl_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_direccion_cliente_dicl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_direccion_cliente_dicl_id_seq OWNER TO bmpch_user;

--
-- Name: tb_direccion_cliente_dicl_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_direccion_cliente_dicl_id_seq OWNED BY public.tb_direccion_cliente.dicl_id;


--
-- Name: tb_distrito; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_distrito (
    dist_id bigint NOT NULL,
    dist_provincia_id bigint NOT NULL,
    dist_nombre character varying(255) NOT NULL
);


ALTER TABLE public.tb_distrito OWNER TO bmpch_user;

--
-- Name: tb_distrito_dist_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_distrito_dist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_distrito_dist_id_seq OWNER TO bmpch_user;

--
-- Name: tb_distrito_dist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_distrito_dist_id_seq OWNED BY public.tb_distrito.dist_id;


--
-- Name: tb_editorial; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_editorial (
    edit_id bigint NOT NULL,
    edit_nombre character varying(255) NOT NULL
);


ALTER TABLE public.tb_editorial OWNER TO bmpch_user;

--
-- Name: tb_editorial_edit_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_editorial_edit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_editorial_edit_id_seq OWNER TO bmpch_user;

--
-- Name: tb_editorial_edit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_editorial_edit_id_seq OWNED BY public.tb_editorial.edit_id;


--
-- Name: tb_estado_prestamo; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_estado_prestamo (
    espr_id smallint NOT NULL,
    espr_nombre character varying(255) NOT NULL
);


ALTER TABLE public.tb_estado_prestamo OWNER TO bmpch_user;

--
-- Name: tb_estado_prestamo_espr_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_estado_prestamo_espr_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_estado_prestamo_espr_id_seq OWNER TO bmpch_user;

--
-- Name: tb_estado_prestamo_espr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_estado_prestamo_espr_id_seq OWNED BY public.tb_estado_prestamo.espr_id;


--
-- Name: tb_genero; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_genero (
    gene_id smallint NOT NULL,
    gene_nombre character varying(255) NOT NULL
);


ALTER TABLE public.tb_genero OWNER TO bmpch_user;

--
-- Name: tb_genero_gene_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_genero_gene_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_genero_gene_id_seq OWNER TO bmpch_user;

--
-- Name: tb_genero_gene_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_genero_gene_id_seq OWNED BY public.tb_genero.gene_id;


--
-- Name: tb_nivel_educativo; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_nivel_educativo (
    nied_id smallint NOT NULL,
    nied_nombre character varying(255) NOT NULL
);


ALTER TABLE public.tb_nivel_educativo OWNER TO bmpch_user;

--
-- Name: tb_nivel_educativo_nied_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_nivel_educativo_nied_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_nivel_educativo_nied_id_seq OWNER TO bmpch_user;

--
-- Name: tb_nivel_educativo_nied_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_nivel_educativo_nied_id_seq OWNED BY public.tb_nivel_educativo.nied_id;


--
-- Name: tb_pais; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_pais (
    pais_id smallint NOT NULL,
    pais_nombre character varying(255) NOT NULL
);


ALTER TABLE public.tb_pais OWNER TO bmpch_user;

--
-- Name: tb_pais_pais_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_pais_pais_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_pais_pais_id_seq OWNER TO bmpch_user;

--
-- Name: tb_pais_pais_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_pais_pais_id_seq OWNED BY public.tb_pais.pais_id;


--
-- Name: tb_prestamo; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_prestamo (
    pres_id bigint NOT NULL,
    pres_cliente_id bigint NOT NULL,
    pres_recurso_textual_codigo_id bigint NOT NULL,
    pres_tipo_prestamo_id smallint NOT NULL,
    pres_estado_prestamo_id smallint NOT NULL,
    pres_fec_inicial date DEFAULT CURRENT_DATE NOT NULL,
    pres_fec_final date,
    pres_fec_programada date NOT NULL,
    CONSTRAINT chk_prestamo_fecha_final CHECK (((pres_fec_final >= pres_fec_inicial) OR (pres_fec_final IS NULL))),
    CONSTRAINT chk_prestamo_fecha_programada CHECK ((pres_fec_programada >= pres_fec_inicial))
);


ALTER TABLE public.tb_prestamo OWNER TO bmpch_user;

--
-- Name: tb_prestamo_pres_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_prestamo_pres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_prestamo_pres_id_seq OWNER TO bmpch_user;

--
-- Name: tb_prestamo_pres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_prestamo_pres_id_seq OWNED BY public.tb_prestamo.pres_id;


--
-- Name: tb_provincia; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_provincia (
    prov_id bigint NOT NULL,
    prov_region_id bigint NOT NULL,
    prov_nombre character varying(255) NOT NULL
);


ALTER TABLE public.tb_provincia OWNER TO bmpch_user;

--
-- Name: tb_provincia_prov_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_provincia_prov_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_provincia_prov_id_seq OWNER TO bmpch_user;

--
-- Name: tb_provincia_prov_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_provincia_prov_id_seq OWNED BY public.tb_provincia.prov_id;


--
-- Name: tb_recurso_textual; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_recurso_textual (
    rete_id bigint NOT NULL,
    rete_tipo_texto_id bigint NOT NULL,
    rete_editorial_id bigint NOT NULL,
    rete_titulo character varying(255) NOT NULL,
    rete_codigo_base character varying(15) NOT NULL,
    rete_fec_publicacion date NOT NULL,
    rete_num_paginas smallint NOT NULL,
    rete_edicion smallint DEFAULT 0 NOT NULL,
    rete_volumen smallint DEFAULT 0 NOT NULL,
    rete_activo boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_recurso_textual_numero_paginas CHECK ((rete_num_paginas > 0))
);


ALTER TABLE public.tb_recurso_textual OWNER TO bmpch_user;

--
-- Name: tb_recurso_textual_autor; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_recurso_textual_autor (
    reau_recurso_textual_id bigint NOT NULL,
    reau_autor_id bigint NOT NULL
);


ALTER TABLE public.tb_recurso_textual_autor OWNER TO bmpch_user;

--
-- Name: tb_recurso_textual_codigo; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_recurso_textual_codigo (
    reco_id bigint NOT NULL,
    reco_rete_codigo_base character varying(15) NOT NULL,
    reco_codigo_ejemplar integer NOT NULL,
    reco_disponible boolean NOT NULL
);


ALTER TABLE public.tb_recurso_textual_codigo OWNER TO bmpch_user;

--
-- Name: tb_recurso_textual_codigo_reco_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_recurso_textual_codigo_reco_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_recurso_textual_codigo_reco_id_seq OWNER TO bmpch_user;

--
-- Name: tb_recurso_textual_codigo_reco_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_recurso_textual_codigo_reco_id_seq OWNED BY public.tb_recurso_textual_codigo.reco_id;


--
-- Name: tb_recurso_textual_rete_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_recurso_textual_rete_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_recurso_textual_rete_id_seq OWNER TO bmpch_user;

--
-- Name: tb_recurso_textual_rete_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_recurso_textual_rete_id_seq OWNED BY public.tb_recurso_textual.rete_id;


--
-- Name: tb_region; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_region (
    regi_id bigint NOT NULL,
    regi_pais_id smallint NOT NULL,
    regi_nombre character varying(255) NOT NULL
);


ALTER TABLE public.tb_region OWNER TO bmpch_user;

--
-- Name: tb_region_regi_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_region_regi_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_region_regi_id_seq OWNER TO bmpch_user;

--
-- Name: tb_region_regi_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_region_regi_id_seq OWNED BY public.tb_region.regi_id;


--
-- Name: tb_registro_accion_usuario; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_registro_accion_usuario (
    reau_id bigint NOT NULL,
    reau_usuario_id bigint NOT NULL,
    reau_detalle character varying NOT NULL,
    reau_fec_hora timestamp without time zone DEFAULT now() NOT NULL,
    reau_direccion_ip character varying(255) DEFAULT 'IP_NO_IDENTIFICADA'::character varying NOT NULL,
    CONSTRAINT chk_registro_accion_usuario_direccion_ip CHECK ((((reau_direccion_ip)::text ~ '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'::text) OR ((reau_direccion_ip)::text ~ '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))'::text) OR ((reau_direccion_ip)::text = 'IP_NO_IDENTIFICADA'::text) OR ((reau_direccion_ip)::text = 'LOCALHOST'::text)))
);


ALTER TABLE public.tb_registro_accion_usuario OWNER TO bmpch_user;

--
-- Name: tb_registro_accion_usuario_reau_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_registro_accion_usuario_reau_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_registro_accion_usuario_reau_id_seq OWNER TO bmpch_user;

--
-- Name: tb_registro_accion_usuario_reau_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_registro_accion_usuario_reau_id_seq OWNED BY public.tb_registro_accion_usuario.reau_id;


--
-- Name: tb_rol_usuario; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_rol_usuario (
    rolu_id smallint NOT NULL,
    rolu_nombre character varying(255) NOT NULL
);


ALTER TABLE public.tb_rol_usuario OWNER TO bmpch_user;

--
-- Name: tb_rol_usuario_rolu_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_rol_usuario_rolu_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_rol_usuario_rolu_id_seq OWNER TO bmpch_user;

--
-- Name: tb_rol_usuario_rolu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_rol_usuario_rolu_id_seq OWNED BY public.tb_rol_usuario.rolu_id;


--
-- Name: tb_tipo_documento; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_tipo_documento (
    tido_id smallint NOT NULL,
    tido_tipo character varying(255) NOT NULL
);


ALTER TABLE public.tb_tipo_documento OWNER TO bmpch_user;

--
-- Name: tb_tipo_documento_tido_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_tipo_documento_tido_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_tipo_documento_tido_id_seq OWNER TO bmpch_user;

--
-- Name: tb_tipo_documento_tido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_tipo_documento_tido_id_seq OWNED BY public.tb_tipo_documento.tido_id;


--
-- Name: tb_tipo_estado; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_tipo_estado (
    ties_id smallint NOT NULL,
    ties_tipo character varying(255) NOT NULL,
    ties_activo boolean DEFAULT false NOT NULL
);


ALTER TABLE public.tb_tipo_estado OWNER TO bmpch_user;

--
-- Name: tb_tipo_estado_ties_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_tipo_estado_ties_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_tipo_estado_ties_id_seq OWNER TO bmpch_user;

--
-- Name: tb_tipo_estado_ties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_tipo_estado_ties_id_seq OWNED BY public.tb_tipo_estado.ties_id;


--
-- Name: tb_tipo_prestamo; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_tipo_prestamo (
    tipr_id smallint NOT NULL,
    tipr_tipo character varying(255) NOT NULL
);


ALTER TABLE public.tb_tipo_prestamo OWNER TO bmpch_user;

--
-- Name: tb_tipo_prestamo_tipr_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_tipo_prestamo_tipr_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_tipo_prestamo_tipr_id_seq OWNER TO bmpch_user;

--
-- Name: tb_tipo_prestamo_tipr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_tipo_prestamo_tipr_id_seq OWNED BY public.tb_tipo_prestamo.tipr_id;


--
-- Name: tb_tipo_texto; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_tipo_texto (
    tite_id bigint NOT NULL,
    tite_tipo character varying(255) NOT NULL
);


ALTER TABLE public.tb_tipo_texto OWNER TO bmpch_user;

--
-- Name: tb_tipo_texto_tite_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_tipo_texto_tite_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_tipo_texto_tite_id_seq OWNER TO bmpch_user;

--
-- Name: tb_tipo_texto_tite_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_tipo_texto_tite_id_seq OWNED BY public.tb_tipo_texto.tite_id;


--
-- Name: tb_usuario; Type: TABLE; Schema: public; Owner: bmpch_user
--

CREATE TABLE public.tb_usuario (
    usua_id bigint NOT NULL,
    usua_rol_usuario_id smallint NOT NULL,
    usua_tipo_documento_id smallint NOT NULL,
    usua_documento character varying(20) NOT NULL,
    usua_psk character varying(255) NOT NULL,
    usua_nombre character varying(255) NOT NULL,
    usua_apellido_paterno character varying(255) NOT NULL,
    usua_apellido_materno character varying(255) NOT NULL,
    usua_telefono character(9) NOT NULL,
    usua_genero_id smallint NOT NULL,
    usua_activo boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_cliente_telefono CHECK ((usua_telefono ~ '^\d{9}$'::text)),
    CONSTRAINT chk_usuario_documento CHECK (((usua_documento)::text ~ '^\d{8,20}$'::text))
);


ALTER TABLE public.tb_usuario OWNER TO bmpch_user;

--
-- Name: tb_usuario_usua_id_seq; Type: SEQUENCE; Schema: public; Owner: bmpch_user
--

CREATE SEQUENCE public.tb_usuario_usua_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tb_usuario_usua_id_seq OWNER TO bmpch_user;

--
-- Name: tb_usuario_usua_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: bmpch_user
--

ALTER SEQUENCE public.tb_usuario_usua_id_seq OWNED BY public.tb_usuario.usua_id;


--
-- Name: tb_autor auto_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_autor ALTER COLUMN auto_id SET DEFAULT nextval('public.tb_autor_auto_id_seq'::regclass);


--
-- Name: tb_carnet carn_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_carnet ALTER COLUMN carn_id SET DEFAULT nextval('public.tb_carnet_carn_id_seq'::regclass);


--
-- Name: tb_categoria cate_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_categoria ALTER COLUMN cate_id SET DEFAULT nextval('public.tb_categoria_cate_id_seq'::regclass);


--
-- Name: tb_cliente clie_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_cliente ALTER COLUMN clie_id SET DEFAULT nextval('public.tb_cliente_clie_id_seq'::regclass);


--
-- Name: tb_direccion_cliente dicl_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_direccion_cliente ALTER COLUMN dicl_id SET DEFAULT nextval('public.tb_direccion_cliente_dicl_id_seq'::regclass);


--
-- Name: tb_distrito dist_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_distrito ALTER COLUMN dist_id SET DEFAULT nextval('public.tb_distrito_dist_id_seq'::regclass);


--
-- Name: tb_editorial edit_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_editorial ALTER COLUMN edit_id SET DEFAULT nextval('public.tb_editorial_edit_id_seq'::regclass);


--
-- Name: tb_estado_prestamo espr_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_estado_prestamo ALTER COLUMN espr_id SET DEFAULT nextval('public.tb_estado_prestamo_espr_id_seq'::regclass);


--
-- Name: tb_genero gene_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_genero ALTER COLUMN gene_id SET DEFAULT nextval('public.tb_genero_gene_id_seq'::regclass);


--
-- Name: tb_nivel_educativo nied_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_nivel_educativo ALTER COLUMN nied_id SET DEFAULT nextval('public.tb_nivel_educativo_nied_id_seq'::regclass);


--
-- Name: tb_pais pais_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_pais ALTER COLUMN pais_id SET DEFAULT nextval('public.tb_pais_pais_id_seq'::regclass);


--
-- Name: tb_prestamo pres_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_prestamo ALTER COLUMN pres_id SET DEFAULT nextval('public.tb_prestamo_pres_id_seq'::regclass);


--
-- Name: tb_provincia prov_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_provincia ALTER COLUMN prov_id SET DEFAULT nextval('public.tb_provincia_prov_id_seq'::regclass);


--
-- Name: tb_recurso_textual rete_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual ALTER COLUMN rete_id SET DEFAULT nextval('public.tb_recurso_textual_rete_id_seq'::regclass);


--
-- Name: tb_recurso_textual_codigo reco_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual_codigo ALTER COLUMN reco_id SET DEFAULT nextval('public.tb_recurso_textual_codigo_reco_id_seq'::regclass);


--
-- Name: tb_region regi_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_region ALTER COLUMN regi_id SET DEFAULT nextval('public.tb_region_regi_id_seq'::regclass);


--
-- Name: tb_registro_accion_usuario reau_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_registro_accion_usuario ALTER COLUMN reau_id SET DEFAULT nextval('public.tb_registro_accion_usuario_reau_id_seq'::regclass);


--
-- Name: tb_rol_usuario rolu_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_rol_usuario ALTER COLUMN rolu_id SET DEFAULT nextval('public.tb_rol_usuario_rolu_id_seq'::regclass);


--
-- Name: tb_tipo_documento tido_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_documento ALTER COLUMN tido_id SET DEFAULT nextval('public.tb_tipo_documento_tido_id_seq'::regclass);


--
-- Name: tb_tipo_estado ties_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_estado ALTER COLUMN ties_id SET DEFAULT nextval('public.tb_tipo_estado_ties_id_seq'::regclass);


--
-- Name: tb_tipo_prestamo tipr_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_prestamo ALTER COLUMN tipr_id SET DEFAULT nextval('public.tb_tipo_prestamo_tipr_id_seq'::regclass);


--
-- Name: tb_tipo_texto tite_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_texto ALTER COLUMN tite_id SET DEFAULT nextval('public.tb_tipo_texto_tite_id_seq'::regclass);


--
-- Name: tb_usuario usua_id; Type: DEFAULT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_usuario ALTER COLUMN usua_id SET DEFAULT nextval('public.tb_usuario_usua_id_seq'::regclass);


--
-- Data for Name: job; Type: TABLE DATA; Schema: cron; Owner: bmpch_user
--

COPY cron.job (jobid, schedule, command, nodename, nodeport, database, username, active, jobname) FROM stdin;
1	0 0 * * *	SELECT fn_actualizar_carnets();		5432	db_biblioteca	postgres	t	job_actualizar_carnets
3	0 0 * * *	SELECT fn_actualizar_prestamos();		5432	db_biblioteca	postgres	t	job_actualizar_prestamos
\.


--
-- Data for Name: job_run_details; Type: TABLE DATA; Schema: cron; Owner: bmpch_user
--

COPY cron.job_run_details (jobid, runid, job_pid, database, username, command, status, return_message, start_time, end_time) FROM stdin;
2	1	52790	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-11-30 19:00:00.439491-05	2024-11-30 19:00:00.56039-05
1	2	52791	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-11-30 19:00:00.441289-05	2024-11-30 19:00:00.565049-05
1	20	1118776	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-12-09 19:00:00.091109-05	2024-12-09 19:00:00.166243-05
3	13	658914	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-12-05 19:00:00.263324-05	2024-12-05 19:00:00.360769-05
1	12	658913	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-12-05 19:00:00.260458-05	2024-12-05 19:00:00.368297-05
3	21	1118777	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-12-09 19:00:00.09239-05	2024-12-09 19:00:00.176866-05
2	3	167519	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-12-01 19:00:00.258193-05	2024-12-01 19:00:00.353344-05
1	4	167520	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-12-01 19:00:00.259585-05	2024-12-01 19:00:00.358572-05
3	15	774729	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-12-06 19:00:00.100177-05	2024-12-06 19:00:00.176108-05
1	6	313142	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-12-02 19:00:00.071961-05	2024-12-02 19:00:00.081866-05
2	5	313141	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	failed	ERROR:  No se puede realizar la operación, la fecha inicial no puede ser menor o mayor a la actual.\nCONTEXT:  PL/pgSQL function fn_verificar_requisitos_prestamos() line 64 at RAISE\nSQL statement "UPDATE tb_prestamo\r\n    SET pres_estado_prestamo_id = id_tipo_estado_vencido\r\n    WHERE pres_estado_prestamo_id = 1 AND pres_fec_programada = CURRENT_DATE - INTERVAL '1 day'"\nPL/pgSQL function fn_actualizar_prestamos() line 9 at SQL statement\n	2024-12-02 19:00:00.070752-05	2024-12-02 19:00:00.149228-05
1	14	774728	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-12-06 19:00:00.100807-05	2024-12-06 19:00:00.18186-05
3	7	338822	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-12-03 00:19:00.146402-05	2024-12-03 00:19:00.155949-05
1	22	1233434	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-12-10 19:00:00.084612-05	2024-12-10 19:00:00.144232-05
3	23	1233435	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-12-10 19:00:00.08579-05	2024-12-10 19:00:00.149539-05
3	9	428131	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-12-03 19:00:00.067943-05	2024-12-03 19:00:00.072433-05
1	8	428130	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-12-03 19:00:00.067304-05	2024-12-03 19:00:00.077679-05
3	17	888444	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-12-07 19:00:00.08556-05	2024-12-07 19:00:00.146175-05
1	16	888443	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-12-07 19:00:00.084206-05	2024-12-07 19:00:00.149203-05
3	11	545146	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-12-04 19:00:00.166573-05	2024-12-04 19:00:00.253959-05
1	10	545145	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-12-04 19:00:00.165984-05	2024-12-04 19:00:00.260493-05
3	19	1003993	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-12-08 19:00:00.074244-05	2024-12-08 19:00:00.081541-05
1	18	1003992	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-12-08 19:00:00.073461-05	2024-12-08 19:00:00.084419-05
3	25	1350526	db_biblioteca	postgres	SELECT fn_actualizar_prestamos();	succeeded	1 row	2024-12-11 19:00:00.077115-05	2024-12-11 19:00:00.090213-05
1	24	1350525	db_biblioteca	postgres	SELECT fn_actualizar_carnets();	succeeded	1 row	2024-12-11 19:00:00.075842-05	2024-12-11 19:00:00.142883-05
\.


--
-- Data for Name: tb_autor; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_autor (auto_id, auto_nombre, auto_apellido_paterno, auto_apellido_materno, auto_activo) FROM stdin;
1	Juan	de Espinoza	Medrano	t
2	Charles	Lehmann	H.	t
3	Homero	  	  	t
4	James	Stewart	  	t
5	Dennis	Zill	G.	t
6	Warren	Wright	S.	t
8	Homero	  	  	t
9	Miguel	De Cervantes		t
12	Abram	Valdelomar	Pinto	t
13	Greg	Kroah	Hartman	t
\.


--
-- Data for Name: tb_carnet; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_carnet (carn_id, carn_tipo_estado_id, carn_codigo, carn_fec_emision, carn_fec_vencimiento) FROM stdin;
1	1	7326626820241130	2024-11-30	2025-11-30
2	1	7845963220241130	2024-11-30	2025-11-30
3	1	1234567820241205	2024-12-05	2025-12-05
4	1	1680418920241206	2024-12-06	2025-12-06
8	1	7326626720241207	2024-12-07	2025-12-07
9	1	7510115720241208	2024-12-08	2025-12-08
10	1	1680418920241208	2024-12-08	2025-12-08
11	1	5263148920241209	2024-12-09	2025-12-09
12	1	8888888820241209	2024-12-09	2025-12-09
13	1	2121212120241210	2024-12-10	2025-12-10
14	1	6565656520241210	2024-12-10	2025-12-10
15	1	7426628120241211	2024-12-11	2025-12-11
\.


--
-- Data for Name: tb_categoria; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_categoria (cate_id, cate_nombre) FROM stdin;
1	Ficción
2	No ficción
3	Ciencia
4	Historia
5	Tecnología
\.


--
-- Data for Name: tb_categoria_recurso_textual; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_categoria_recurso_textual (care_recurso_textual_id, care_categoria_id) FROM stdin;
\.


--
-- Data for Name: tb_cliente; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_cliente (clie_id, clie_usuario_id, clie_direccion_id, clie_correo, clie_carnet_id, clie_nivel_educativo_id) FROM stdin;
1	3	9	llacsahuanga.buques@gmail.com	1	3
2	4	10	alexserquen.t@gmail.com	2	4
3	7	11	a@a.com	3	3
4	9	12	diana@hotmail.com	4	3
7	1	15	llacsahuanga.buques@gmail.cm	8	2
8	2	16	dereck81@gmail.com	9	4
10	11	18	elopesr@biblioteca.org	11	3
12	13	20	pancho@gmail.com	13	1
13	15	21	chill@gmail.com	14	2
14	18	22	karenarianabecerrachero@gmail.com	15	3
11	12	23	tester@gmail.com	12	1
\.


--
-- Data for Name: tb_direccion_cliente; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_direccion_cliente (dicl_id, dicl_distrito_id, dicl_direccion) FROM stdin;
1	1	Calle 123, Centro, La Plata
2	2	Avenida Atlántica, Los Troncos, Mar del Plata
3	4	Rua das Flores, Barão Geraldo, Campinas
4	7	Alameda Peñablanca, Avenida Principal, Maipú
5	9	Jirón El Sol, San Miguel, Miraflores
6	11	Pasaje Los Pinos, Andenes, Yanahuara
7	11	Calle Olivares #353 2do Piso
8	11	Calle Olivares #303 2do Piso
9	9	Calle Las Peonías #145
10	10	Av. Colombia #532
11	3	Calle falsa 123
12	3	calle AAA Nª987
13	1	No especificado
14	1	No especificado
15	1	Coloniales de Zaña 341
16	3	Av. Superman 542
17	1	No especificado
18	5	Av. Leguia 351
19	3	Av. Coloniales de Zaña 123
20	9	Av. Universidad 123
21	4	Av. Universidad 123
22	3	Av. Leguía 105
23	3	Av. Coloniales de Zaña 123
\.


--
-- Data for Name: tb_distrito; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_distrito (dist_id, dist_provincia_id, dist_nombre) FROM stdin;
1	1	Centro
2	2	Los Troncos
3	3	San Roque
4	4	Barão Geraldo
5	5	Éden
6	6	Santa Rosa
7	7	Avenida Principal
8	8	Paseo Costero
9	9	San Miguel
10	9	Surco
11	10	Cerro Colorado
12	11	Andenes
\.


--
-- Data for Name: tb_editorial; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_editorial (edit_id, edit_nombre) FROM stdin;
1	Editorial Planeta
2	Penguin Random House
3	Santillana
4	Anagrama
5	Corefo
6	Mc Graw Hill
7	error
8	Arcángel San Miguel S.A.C.
9	La Opinión Nacional
\.


--
-- Data for Name: tb_estado_prestamo; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_estado_prestamo (espr_id, espr_nombre) FROM stdin;
1	Activo
2	Devuelto
3	Vencido
\.


--
-- Data for Name: tb_genero; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_genero (gene_id, gene_nombre) FROM stdin;
1	Masculino
2	Femenino
3	No binario
\.


--
-- Data for Name: tb_nivel_educativo; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_nivel_educativo (nied_id, nied_nombre) FROM stdin;
1	Primaria
2	Secundaria
3	Superior
4	Postgrado
5	No Especificado
\.


--
-- Data for Name: tb_pais; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_pais (pais_id, pais_nombre) FROM stdin;
1	Argentina
2	Brasil
3	Chile
4	Perú
\.


--
-- Data for Name: tb_prestamo; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_prestamo (pres_id, pres_cliente_id, pres_recurso_textual_codigo_id, pres_tipo_prestamo_id, pres_estado_prestamo_id, pres_fec_inicial, pres_fec_final, pres_fec_programada) FROM stdin;
6	4	5	1	2	2024-12-06	2024-12-06	2024-12-07
2	2	3	1	2	2024-12-04	2024-12-06	2024-12-04
1	2	4	1	2	2024-12-01	2024-12-06	2024-12-02
4	3	16	1	2	2024-12-05	2024-12-06	2049-10-20
11	4	12	1	2	2024-12-06	2024-12-06	2024-12-06
14	3	14	1	3	2024-12-09	\N	2024-12-09
12	4	19	2	2	2024-12-06	2024-12-10	2024-12-10
15	2	23	1	2	2024-12-11	2024-12-11	2024-12-13
58	1	19	2	1	2024-12-12	\N	2024-12-13
\.


--
-- Data for Name: tb_provincia; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_provincia (prov_id, prov_region_id, prov_nombre) FROM stdin;
1	1	La Plata
2	1	Mar del Plata
3	2	Villa Carlos Paz
4	3	Campinas
5	3	Sorocaba
6	4	Niterói
7	5	Maipú
8	5	Viña del Mar
9	7	Miraflores
10	7	San Isidro
11	8	Cayma
12	8	Yanahuara
\.


--
-- Data for Name: tb_recurso_textual; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_recurso_textual (rete_id, rete_tipo_texto_id, rete_editorial_id, rete_titulo, rete_codigo_base, rete_fec_publicacion, rete_num_paginas, rete_edicion, rete_volumen, rete_activo) FROM stdin;
1	1	3	La novena Maravilla	LNMJEM	2011-01-01	310	1	1	t
2	1	4	Geometría Analítica	GACHL	1989-01-01	516	1	1	t
5	1	6	Cálculo: Trascendentes Tempranas	CTTDSGWSW	2024-12-06	66	4	1	t
6	3	4	Condorito	wqwq	2024-12-10	10	1	1	t
7	1	4	Linux Device Drivers	LDDGKH	1998-01-01	820	5	1	t
4	1	5	La Odisea	ODISEA	2024-12-03	33	1	1	t
8	1	1	Matematica Primaria	MATPRI	2023-12-04	450	1	1	t
\.


--
-- Data for Name: tb_recurso_textual_autor; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_recurso_textual_autor (reau_recurso_textual_id, reau_autor_id) FROM stdin;
1	1
2	2
5	5
5	6
6	4
6	2
7	13
4	3
8	4
8	6
\.


--
-- Data for Name: tb_recurso_textual_codigo; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_recurso_textual_codigo (reco_id, reco_rete_codigo_base, reco_codigo_ejemplar, reco_disponible) FROM stdin;
1	LNMJEM	1	t
2	LNMJEM	2	t
6	GACHL	3	t
7	ODISEA	1	t
8	ODISEA	2	t
9	ODISEA	3	t
10	ODISEA	4	t
11	ODISEA	5	t
13	ODISEA	7	t
15	ODISEA	9	t
5	GACHL	2	t
3	LNMJEM	3	t
4	GACHL	1	t
16	ODISEA	10	t
17	CTTDSGWSW	1	t
18	CTTDSGWSW	2	t
20	CTTDSGWSW	4	t
12	ODISEA	6	t
14	ODISEA	8	f
21	wqwq	1	t
22	LDDGKH	1	t
24	LDDGKH	3	t
23	LDDGKH	2	t
25	MATPRI	1	t
26	MATPRI	2	t
19	CTTDSGWSW	3	f
\.


--
-- Data for Name: tb_region; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_region (regi_id, regi_pais_id, regi_nombre) FROM stdin;
1	1	Buenos Aires
2	1	Córdoba
3	2	São Paulo
4	2	Rio de Janeiro
5	3	Santiago
6	3	Valparaíso
7	4	Lima
8	4	Arequipa
\.


--
-- Data for Name: tb_registro_accion_usuario; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_registro_accion_usuario (reau_id, reau_usuario_id, reau_detalle, reau_fec_hora, reau_direccion_ip) FROM stdin;
1	1	[PUT] Actualizó un préstamo - ID: 6 - Cliente: 4 - ID Estado: 2 - ID Recurso: 5	2024-12-06 22:03:08.996987	127.0.0.1
2	1	[PUT] Actualizó un préstamo - ID: 2 - Cliente: 2 - ID Estado: 2 - ID Recurso: 3	2024-12-06 22:05:05.515703	127.0.0.1
3	1	[PUT] Actualizó un préstamo - ID: 1 - Cliente: 2 - ID Estado: 2 - ID Recurso: 4	2024-12-06 22:05:15.023863	127.0.0.1
4	1	[PUT] Actualizó un préstamo - ID: 4 - Cliente: 3 - ID Estado: 2 - ID Recurso: 16	2024-12-06 22:23:13.468873	38.56.219.72
5	2	[POST] Inició sesión	2024-12-06 22:24:21.879814	179.6.46.68
6	1	[POST] Inició sesión	2024-12-06 22:24:31.547042	38.56.219.72
7	2	[POST] Registró un nuevo préstamo - ID: 11 - Cliente: 4 - ID Estado: 1 - ID Recurso: 12	2024-12-06 22:29:55.473051	179.6.46.68
8	1	[POST] Creó un nuevo autor - ID: 4	2024-12-06 22:31:21.762713	38.56.219.72
9	1	[POST] Creó un nuevo autor - ID: 5	2024-12-06 22:34:14.835619	38.56.219.72
10	1	[POST] Creó un nuevo autor - ID: 6	2024-12-06 22:34:26.868362	38.56.219.72
11	1	[POST] Registró un nuevo recurso textual - ID: 5 - Título: Cálculo: Trascendentes Tempranas - Código base: CTTDSGWSW - Stock: 4	2024-12-06 22:37:05.364722	38.56.219.72
12	2	[PUT] Actualizó un préstamo - ID: 11 - Cliente: 4 - ID Estado: 2 - ID Recurso: 12	2024-12-06 22:41:46.355328	179.6.46.68
13	1	[POST] Registró un nuevo préstamo - ID: 12 - Cliente: 4 - ID Estado: 1 - ID Recurso: 19	2024-12-06 22:42:41.875435	38.56.219.72
14	1	[POST] Inició sesión	2024-12-06 23:00:46.253892	38.56.219.72
15	1	[POST] Registró una nueva dirección - ID: 13	2024-12-06 23:17:55.055197	38.56.219.72
16	1	[POST] Registró una nueva dirección - ID: 14	2024-12-06 23:19:37.086832	38.56.219.72
17	1	[POST] Inició sesión	2024-12-07 17:12:53.717204	179.6.46.68
18	1	[POST] Inició sesión	2024-12-07 23:18:30.644103	38.56.219.72
19	1	[POST] Inició sesión	2024-12-07 23:40:12.002981	LOCALHOST
20	1	[POST] Registró una nueva dirección - ID: 15	2024-12-07 23:44:01.71863	LOCALHOST
21	1	[POST] Creó un nuevo cliente - ID:7 - Document: 73266267 - UserID: 1	2024-12-07 23:44:02.1294	LOCALHOST
22	1	[POST] Inició sesión	2024-12-08 16:59:46.672808	38.56.219.72
23	1	[POST] Inició sesión	2024-12-08 17:33:39.773923	38.56.219.72
24	1	[POST] Registró una nueva dirección - ID: 16	2024-12-08 17:45:00.497438	LOCALHOST
25	1	[POST] Creó un nuevo cliente - ID:8 - Document: 75101157 - UserID: 2	2024-12-08 17:45:00.729343	LOCALHOST
26	1	[POST] Inició sesión	2024-12-08 19:28:24.505467	38.25.4.9
27	1	[POST] Inició sesión	2024-12-08 19:36:19.450457	38.25.4.9
28	1	[POST] Inició sesión	2024-12-08 22:15:42.352886	179.6.46.68
29	1	[POST] Inició sesión	2024-12-08 23:00:46.448407	38.56.219.72
30	1	[POST] Se registró un nuevo usuario - Documento: 52631489	2024-12-08 23:01:29.058179	38.56.219.72
31	1	[POST] Inició sesión	2024-12-08 23:02:15.434109	LOCALHOST
32	3	[POST] Inició sesión	2024-12-08 23:03:21.571819	LOCALHOST
33	3	[POST] Inició sesión	2024-12-08 23:03:26.842389	LOCALHOST
34	11	[POST] Inició sesión	2024-12-08 23:05:02.596499	LOCALHOST
35	3	[POST] Inició sesión	2024-12-08 23:22:56.160137	127.0.0.1
36	1	[POST] Inició sesión	2024-12-08 23:45:13.472871	179.6.46.68
37	1	[POST] Registró una nueva dirección - ID: 17	2024-12-08 23:46:09.767024	179.6.46.68
38	1	[POST] Inició sesión	2024-12-09 05:32:12.225721	127.0.0.1
39	4	[POST] Inició sesión	2024-12-09 05:59:52.14311	127.0.0.1
40	1	[POST] Inició sesión	2024-12-09 06:00:20.590519	127.0.0.1
41	1	[POST] Inició sesión	2024-12-09 07:01:32.087255	127.0.0.1
42	1	[POST] Inició sesión	2024-12-09 15:54:14.955672	179.6.46.68
43	1	[POST] Inició sesión	2024-12-09 16:55:32.066417	179.6.46.68
44	1	[POST] Inició sesión	2024-12-09 18:04:54.853089	179.6.46.68
45	1	[POST] Creó un nuevo autor - ID: 7	2024-12-09 18:05:31.986246	179.6.46.68
46	1	[POST] Creó un nuevo autor - ID: 8	2024-12-09 18:05:56.221576	179.6.46.68
47	1	[POST] Creó un nuevo autor - ID: 9	2024-12-09 18:08:47.147097	179.6.46.68
48	1	[POST] Inició sesión	2024-12-09 19:25:26.835543	38.56.219.72
49	1	[POST] Inició sesión	2024-12-09 19:41:21.260574	38.56.219.72
50	3	[POST] Inició sesión	2024-12-09 19:41:55.772017	38.56.219.72
51	1	[POST] Inició sesión	2024-12-09 19:46:05.187071	38.56.219.72
52	1	[POST] Registró una nueva dirección - ID: 18	2024-12-09 19:49:23.366036	38.56.219.72
53	1	[POST] Creó un nuevo cliente - ID:10 - Document: 52631489 - UserID: 11	2024-12-09 19:49:23.389212	38.56.219.72
54	1	[POST] Inició sesión	2024-12-09 20:00:40.546908	179.7.80.5
55	1	[POST] Registró un nuevo préstamo - ID: 14 - Cliente: 3 - ID Estado: 1 - ID Recurso: 14	2024-12-09 20:02:04.485687	179.7.80.5
56	1	[POST] Registró una nueva dirección - ID: 19	2024-12-09 20:05:15.996203	179.7.80.5
57	1	[POST] Creó un nuevo cliente - ID:11 - Document: 88888888 - UserID: 12	2024-12-09 20:05:16.013386	179.7.80.5
58	12	[POST] Inició sesión	2024-12-09 20:06:54.357321	179.7.80.5
59	1	[POST] Inició sesión	2024-12-09 20:15:39.783769	179.6.46.68
60	1	[POST] Inició sesión	2024-12-09 21:20:31.114773	38.56.219.72
61	3	[POST] Inició sesión	2024-12-09 21:21:14.24679	38.56.219.72
62	2	[POST] Inició sesión	2024-12-09 21:30:14.660142	179.6.46.68
63	1	[POST] Inició sesión	2024-12-09 22:27:06.347068	179.6.46.68
64	12	[POST] Inició sesión	2024-12-09 22:30:18.36777	179.7.80.126
65	1	[POST] Inició sesión	2024-12-09 23:22:47.34992	179.7.80.126
66	1	[POST] Inició sesión	2024-12-09 23:23:05.768508	179.7.80.126
67	1	[POST] Inició sesión	2024-12-09 23:38:00.552872	179.7.80.126
68	1	[POST] Inició sesión	2024-12-10 01:11:56.760203	181.67.205.67
69	1	[POST] Inició sesión	2024-12-10 03:08:37.205202	179.7.80.126
70	1	[POST] Inició sesión	2024-12-10 16:48:57.873395	38.56.219.72
71	1	[POST] Inició sesión	2024-12-10 17:25:58.563852	179.6.46.68
72	1	[POST] Inició sesión	2024-12-10 18:48:35.257878	38.25.4.9
73	1	[POST] Inició sesión	2024-12-10 19:13:46.600685	38.56.219.72
74	1	[POST] Se registró un nuevo usuario - Documento: 21212121	2024-12-10 19:29:45.951103	38.25.4.9
75	2	[POST] Inició sesión	2024-12-10 21:00:13.294716	179.6.46.68
76	1	[POST] Inició sesión	2024-12-10 21:05:41.886403	38.56.219.72
77	1	[POST] Inició sesión	2024-12-10 21:29:02.679012	179.7.80.135
78	1	[POST] Inició sesión	2024-12-10 21:33:26.18286	179.7.80.135
79	1	[POST] Se registró un nuevo usuario - Documento: 77777777	2024-12-10 21:36:35.761526	179.7.80.135
80	1	[POST] Inició sesión	2024-12-10 21:39:34.983136	179.7.80.135
81	1	[POST] Inició sesión	2024-12-10 21:40:52.065002	179.7.80.135
82	1	[POST] Inició sesión	2024-12-10 21:43:47.777738	179.7.80.135
83	1	[POST] Inició sesión	2024-12-10 21:45:04.053742	179.7.80.135
84	1	[POST] Inició sesión	2024-12-10 21:45:16.072464	179.7.80.135
85	1	[POST] Inició sesión	2024-12-10 22:04:07.04916	179.7.80.135
86	11	[POST] Inició sesión	2024-12-10 22:08:14.349164	38.56.219.72
87	1	[POST] Creó un nuevo autor - ID: 10	2024-12-10 22:13:21.16777	179.7.80.135
88	1	[POST] Creó un nuevo autor - ID: 11	2024-12-10 22:13:21.65771	179.7.80.135
89	1	[POST] Inició sesión	2024-12-10 22:39:05.748378	179.7.80.135
90	1	[POST] Inició sesión	2024-12-10 22:46:06.399072	38.56.219.72
91	1	[POST] Inició sesión	2024-12-10 22:51:30.157487	38.56.219.72
92	1	[POST] Inició sesión	2024-12-10 23:30:10.345281	38.25.4.9
93	1	[POST] Inició sesión	2024-12-10 23:31:08.370124	38.25.4.9
94	1	[POST] Registró una nueva dirección - ID: 20	2024-12-10 23:33:18.189395	38.25.4.9
95	1	[POST] Creó un nuevo cliente - ID:12 - Document: 21212121 - UserID: 13	2024-12-10 23:33:18.253633	38.25.4.9
96	1	[POST] Registró un nuevo recurso textual - ID: 6 - Título: Condorito - Código base: wqwq - Stock: 1	2024-12-10 23:37:58.500987	38.25.4.9
97	13	[POST] Inició sesión	2024-12-10 23:48:08.945131	38.25.4.9
98	1	[POST] Inició sesión	2024-12-10 23:53:31.446067	38.25.4.9
99	13	[POST] Inició sesión	2024-12-10 23:56:58.569032	38.25.4.9
100	13	[POST] Registró una nueva dirección - ID: 21	2024-12-10 23:58:46.539567	38.25.4.9
101	13	[POST] Creó un nuevo cliente - ID:13 - Document: 65656565 - UserID: 15	2024-12-10 23:58:46.559567	38.25.4.9
102	1	[POST] Inició sesión	2024-12-11 01:28:12.683187	190.102.157.138
103	1	[POST] Inició sesión	2024-12-11 01:28:43.781244	161.132.194.10
104	1	[POST] Inició sesión	2024-12-11 01:29:27.761832	161.132.194.10
105	1	[POST] Inició sesión	2024-12-11 01:31:51.78135	161.132.194.10
106	13	[POST] Inició sesión	2024-12-11 01:42:48.470798	161.132.194.10
107	7	[POST] Inició sesión	2024-12-11 01:43:09.281142	161.132.194.10
108	13	[POST] Inició sesión	2024-12-11 01:45:21.179839	161.132.194.10
109	13	[POST] Inició sesión	2024-12-11 01:46:30.773519	190.102.157.138
110	1	[POST] Inició sesión	2024-12-11 01:49:54.252567	200.121.249.129
111	1	[POST] Inició sesión	2024-12-11 01:50:13.74299	200.121.249.129
112	1	[POST] Actualizó un usuario - ID: 15 - ID Rol: 2	2024-12-11 01:50:48.737758	200.121.249.129
113	1	[POST] Inició sesión	2024-12-11 01:52:04.95439	190.102.157.138
114	1	[PUT] Actualizó un préstamo - ID: 12 - Cliente: 4 - ID Estado: 2 - ID Recurso: 19	2024-12-11 01:59:27.900952	161.132.194.10
115	1	[PUT] Actualizó un préstamo - ID: 12 - Cliente: 4 - ID Estado: 2 - ID Recurso: 19	2024-12-11 01:59:40.400235	161.132.194.10
116	3	[POST] Inició sesión	2024-12-11 02:00:39.57259	161.132.194.10
117	1	[POST] Inició sesión	2024-12-11 04:30:30.0307	179.7.80.205
118	1	[POST] Inició sesión	2024-12-11 13:19:58.444601	179.6.46.68
119	1	[POST] Inició sesión	2024-12-11 19:00:05.584462	179.7.80.20
120	1	[POST] Inició sesión	2024-12-11 19:00:50.262804	179.7.80.20
121	1	[POST] Inició sesión	2024-12-11 20:13:49.711849	179.6.46.68
122	2	[POST] Inició sesión	2024-12-11 20:15:56.589113	179.6.46.68
123	1	[POST] Inició sesión	2024-12-11 22:57:48.875671	179.6.46.68
124	1	[POST] Inició sesión	2024-12-11 23:01:45.163594	38.56.219.72
125	1	[POST] Inició sesión	2024-12-11 23:21:47.491236	38.56.219.72
126	1	[POST] Se registró un nuevo usuario - Documento: 16753999	2024-12-11 23:22:44.949616	38.56.219.72
127	1	[POST] Creó un nuevo autor - ID: 12	2024-12-11 23:25:32.498092	179.6.46.68
128	1	[POST] Se registró un nuevo usuario - Documento: 74266281	2024-12-11 23:29:50.341162	38.56.219.72
129	1	[POST] Creó un nuevo autor - ID: 13	2024-12-11 23:31:19.046727	38.56.219.72
130	1	[POST] Registró un nuevo recurso textual - ID: 7 - Título: Linux Device Drivers - Código base: LDDGKH - Stock: 3	2024-12-11 23:32:08.012958	38.56.219.72
131	1	[POST] Registró un nuevo préstamo - ID: 15 - Cliente: 2 - ID Estado: 1 - ID Recurso: 23	2024-12-11 23:37:04.905593	38.56.219.72
132	1	[PUT] Actualizó un préstamo - ID: 15 - Cliente: 2 - ID Estado: 2 - ID Recurso: 23	2024-12-11 23:37:24.766031	38.56.219.72
133	1	[PUT] Actualizó un préstamo - ID: 15 - Cliente: 2 - ID Estado: 2 - ID Recurso: 23	2024-12-11 23:37:27.588136	38.56.219.72
134	1	[PUT] Actualizó un préstamo - ID: 15 - Cliente: 2 - ID Estado: 2 - ID Recurso: 23	2024-12-11 23:37:28.964743	38.56.219.72
135	1	[PUT] Actualizó un préstamo - ID: 15 - Cliente: 2 - ID Estado: 2 - ID Recurso: 23	2024-12-11 23:37:30.546378	38.56.219.72
136	1	[POST] Registró una nueva dirección - ID: 22	2024-12-11 23:39:18.239334	38.56.219.72
137	1	[POST] Creó un nuevo cliente - ID:14 - Document: 74266281 - UserID: 18	2024-12-11 23:39:18.252863	38.56.219.72
138	3	[POST] Inició sesión	2024-12-11 23:42:13.845707	38.56.219.72
139	1	[POST] Inició sesión	2024-12-11 23:59:20.458423	38.56.219.72
140	2	[POST] Inició sesión	2024-12-12 00:09:38.940826	179.6.46.68
141	1	[POST] Inició sesión	2024-12-12 00:11:18.859682	179.6.46.68
142	1	[POST] Inició sesión	2024-12-12 00:11:51.253723	38.56.219.72
143	1	[POST] Inició sesión	2024-12-12 00:11:54.440274	179.7.80.20
144	1	[PUT] Registró una nueva dirección - ID: 23	2024-12-12 00:13:20.405157	179.7.80.20
145	1	[PUT] Actualizó un nuevo cliente - ID:11 - Document: 88888888 - UserID: 12	2024-12-12 00:13:20.647122	179.7.80.20
146	1	[PUT] Actualizó un recurso textual - ID: 4 - Título: La Odisea - Código base: ODISEA - Stock: null	2024-12-12 00:14:50.543525	179.7.80.20
147	1	[PUT] Actualizó un recurso textual - ID: 4 - Título: La Odisea - Código base: ODISEA - Stock: null	2024-12-12 00:14:51.657378	179.7.80.20
148	1	[PUT] Actualizó un recurso textual - ID: 4 - Título: La Odisea - Código base: ODISEA - Stock: null	2024-12-12 00:14:51.741653	179.7.80.20
149	1	[POST] Inició sesión	2024-12-12 00:15:22.258477	179.7.80.20
152	13	[POST] Inició sesión	2024-12-12 00:16:45.862901	38.25.4.9
150	1	[POST] Registró un nuevo recurso textual - ID: 8 - Título: Matematica Primaria - Código base: MATPRI - Stock: 2	2024-12-12 00:16:33.364156	179.6.46.68
154	1	[POST] Inició sesión	2024-12-12 00:19:00.3837	179.6.46.68
151	1	[PUT] Actualizó un recurso textual - ID: 8 - Título: Matematica Primaria - Código base: MATPRI - Stock: null	2024-12-12 00:16:44.462046	179.6.46.68
153	13	[POST] Se registró un nuevo usuario - Documento: 11111111	2024-12-12 00:18:31.589995	38.25.4.9
155	19	[POST] Inició sesión	2024-12-12 00:21:52.882926	38.25.4.9
156	13	[POST] Inició sesión	2024-12-12 00:39:56.856802	38.25.4.9
157	13	[POST] Se registró un nuevo usuario - Documento: 33333333	2024-12-12 00:42:48.963966	38.25.4.9
158	20	[POST] Inició sesión	2024-12-12 00:43:31.582176	38.25.4.9
159	3	[POST] Inició sesión	2024-12-12 00:44:09.088717	38.56.219.72
160	3	[POST] Inició sesión	2024-12-12 00:44:35.666609	38.56.219.72
161	1	[POST] Inició sesión	2024-12-12 01:27:49.171191	179.6.46.68
162	1	[POST] Inició sesión	2024-12-12 06:08:19.946716	38.56.219.72
163	1	[POST] Registró un nuevo préstamo - ID: 58 - Cliente: 1 - ID Estado: 1 - ID Recurso: 19	2024-12-12 06:08:51.380095	38.56.219.72
\.


--
-- Data for Name: tb_rol_usuario; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_rol_usuario (rolu_id, rolu_nombre) FROM stdin;
1	Administrador
2	Cliente
3	Bibliotecario
\.


--
-- Data for Name: tb_tipo_documento; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_tipo_documento (tido_id, tido_tipo) FROM stdin;
1	DNI
2	Pasaporte
3	Carné de extranjería
\.


--
-- Data for Name: tb_tipo_estado; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_tipo_estado (ties_id, ties_tipo, ties_activo) FROM stdin;
1	Activo	t
2	Vencido	f
3	Suspendido	f
\.


--
-- Data for Name: tb_tipo_prestamo; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_tipo_prestamo (tipr_id, tipr_tipo) FROM stdin;
1	Préstamo en sala
2	Préstamo a domicilio
\.


--
-- Data for Name: tb_tipo_texto; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_tipo_texto (tite_id, tite_tipo) FROM stdin;
1	Libro
2	Revista
3	Periódico
4	Tesis
\.


--
-- Data for Name: tb_usuario; Type: TABLE DATA; Schema: public; Owner: bmpch_user
--

COPY public.tb_usuario (usua_id, usua_rol_usuario_id, usua_tipo_documento_id, usua_documento, usua_psk, usua_nombre, usua_apellido_paterno, usua_apellido_materno, usua_telefono, usua_genero_id, usua_activo) FROM stdin;
1	1	1	73266267	$2a$10$ekueVm6N0ky1JRzpnE8eJuVv6wbjlmgn2nbn11Gv6Ej46Jo0LcpQu	Diego Alexis	Llacsahuanga	Buques	976849906	3	t
2	1	1	75101157	$2a$10$j/U3SsUH9YxRq8kTE8XC4uiyaqRVF22TQlX9YVJxVPc0Q8Wuv9qb2	Kevin	Huanca	Fernández	968370197	1	t
3	2	1	73266268	$2a$10$S18cJo0dNwrmylfqBKhICOnx5l9/yMCrQ4yrWb52KDV8a7Q.ypPiW	Diego Armando	Llacsahuanga	Buques	976849905	1	t
4	2	1	78459632	$2a$10$iTA9V5D4V3TNeEhbdkt.T.fFJrM3HqOCCvkG95DRPdxlPz9XQUKUi	Alex	Serquen	Yparraguirre	965428895	1	t
7	2	1	12345678	$2a$10$Sv07k4mrK/VCvdC2AAeaa.ZkryJizOOcaztOX.3lrsiNo.Ya4wlPi	aa	  bb	 cc 	987654321	2	t
8	1	1	40029519	$2a$10$w0qIxzrb/CMnroTUkj4Y7eAgYckILdLU3Xmdl36fYWbzaHA8UKtwS	Roberto Martìn	Celis 	Osores	979813011	1	t
9	2	1	16804189	$2a$10$Dt7iaMWDfWBzEdK8woUite7LJWi.NlT0emOLqVPteYZ29DHqZDani	Diana	Aguilar	Amaya	999999999	2	t
11	3	1	52631489	$2a$10$InA366QtTsqhQX3Skf7SX.GUW./dTu/CwJp.3J8Lw1JzzoTLstEwy	Enrique	Lopez	Ramos	965248531	1	t
6	2	1	87654321	$2a$10$ciQJ3GzW.GNPzjNloL5Et.U34v9GX.0OOyU.85e7sjauZhbzy7QOq	AA	BB	CC	987654321	1	t
12	2	1	88888888	$2a$10$6KUTKNbKkIt1VCIsH1E1gOcMhPtkqNvXU58XB8qs31oiKPoQ3IFIy	Test	TP	TM	999999999	1	t
13	1	1	21212121	$2a$10$sOR75ni55Y.CF4QP6Lp7NeDJ2geoziHnGw1MGDjPyXQxuI/TDzo.2	Pancho	Jimenez	Verastegui	222222222	3	t
14	2	1	77777777	$2a$10$bcJ7drTl1uY37CEgA3QGbuVktoiUE2p8oku9.22/lSF3XttSXRzQe	Alguien	pp	mm	728172812	1	t
15	2	1	65656565	$2a$10$JJBQEEVZ6A7N9bexTgxByOAtiKfbhetZ9kTmr8PlGygdtV9/KWFdK	Chill	Rondriguez	Vera	999999998	1	t
17	1	1	16753999	$2a$10$zB/orPNTo.RgfM1mLtzXN.KtqGhHBgEmbSp1XxukB3w7ywjcRuOY2	Rosa	Buques	Vargas	937732683	2	t
18	3	1	74266281	$2a$10$DtQrr8w7OCt6OKkvcMc3uu.JKbIiFrmuEuoSus8kdj73mPnA8W04O	Karen	Becerra	Chero	936383800	2	t
19	2	1	11111111	$2a$10$7P3gZIf7YUH.QmH2wDWw9eFwdssP.xqIJuHwx/lgQmI0j1nKHb1/2	Pancho2	Rondriguez2	Verastegui2	999999999	1	t
20	3	1	33333333	$2a$10$Rp.gK0WeeQorsZZVm/qXh.q.Axfh5Ej/XVC7wxLPrWSebzu4GVgha	Roberto	Celis	Osores	989898989	1	t
\.


--
-- Name: jobid_seq; Type: SEQUENCE SET; Schema: cron; Owner: postgres
--

SELECT pg_catalog.setval('cron.jobid_seq', 5, true);


--
-- Name: runid_seq; Type: SEQUENCE SET; Schema: cron; Owner: postgres
--

SELECT pg_catalog.setval('cron.runid_seq', 25, true);


--
-- Name: tb_autor_auto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_autor_auto_id_seq', 13, true);


--
-- Name: tb_carnet_carn_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_carnet_carn_id_seq', 15, true);


--
-- Name: tb_categoria_cate_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_categoria_cate_id_seq', 5, true);


--
-- Name: tb_cliente_clie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_cliente_clie_id_seq', 14, true);


--
-- Name: tb_direccion_cliente_dicl_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_direccion_cliente_dicl_id_seq', 23, true);


--
-- Name: tb_distrito_dist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_distrito_dist_id_seq', 12, true);


--
-- Name: tb_editorial_edit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_editorial_edit_id_seq', 12, true);


--
-- Name: tb_estado_prestamo_espr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_estado_prestamo_espr_id_seq', 3, true);


--
-- Name: tb_genero_gene_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_genero_gene_id_seq', 3, true);


--
-- Name: tb_nivel_educativo_nied_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_nivel_educativo_nied_id_seq', 5, true);


--
-- Name: tb_pais_pais_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_pais_pais_id_seq', 4, true);


--
-- Name: tb_prestamo_pres_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_prestamo_pres_id_seq', 58, true);


--
-- Name: tb_provincia_prov_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_provincia_prov_id_seq', 12, true);


--
-- Name: tb_recurso_textual_codigo_reco_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_recurso_textual_codigo_reco_id_seq', 26, true);


--
-- Name: tb_recurso_textual_rete_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_recurso_textual_rete_id_seq', 8, true);


--
-- Name: tb_region_regi_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_region_regi_id_seq', 8, true);


--
-- Name: tb_registro_accion_usuario_reau_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_registro_accion_usuario_reau_id_seq', 163, true);


--
-- Name: tb_rol_usuario_rolu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_rol_usuario_rolu_id_seq', 3, true);


--
-- Name: tb_tipo_documento_tido_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_tipo_documento_tido_id_seq', 3, true);


--
-- Name: tb_tipo_estado_ties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_tipo_estado_ties_id_seq', 3, true);


--
-- Name: tb_tipo_prestamo_tipr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_tipo_prestamo_tipr_id_seq', 2, true);


--
-- Name: tb_tipo_texto_tite_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_tipo_texto_tite_id_seq', 4, true);


--
-- Name: tb_usuario_usua_id_seq; Type: SEQUENCE SET; Schema: public; Owner: bmpch_user
--

SELECT pg_catalog.setval('public.tb_usuario_usua_id_seq', 20, true);


--
-- Name: tb_autor tb_autor_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_autor
    ADD CONSTRAINT tb_autor_pkey PRIMARY KEY (auto_id);


--
-- Name: tb_carnet tb_carnet_carn_codigo_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_carnet
    ADD CONSTRAINT tb_carnet_carn_codigo_key UNIQUE (carn_codigo);


--
-- Name: tb_carnet tb_carnet_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_carnet
    ADD CONSTRAINT tb_carnet_pkey PRIMARY KEY (carn_id);


--
-- Name: tb_categoria tb_categoria_cate_nombre_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_categoria
    ADD CONSTRAINT tb_categoria_cate_nombre_key UNIQUE (cate_nombre);


--
-- Name: tb_categoria tb_categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_categoria
    ADD CONSTRAINT tb_categoria_pkey PRIMARY KEY (cate_id);


--
-- Name: tb_categoria_recurso_textual tb_categoria_recurso_textual_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_categoria_recurso_textual
    ADD CONSTRAINT tb_categoria_recurso_textual_pkey PRIMARY KEY (care_recurso_textual_id, care_categoria_id);


--
-- Name: tb_cliente tb_cliente_clie_carnet_id_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_cliente
    ADD CONSTRAINT tb_cliente_clie_carnet_id_key UNIQUE (clie_carnet_id);


--
-- Name: tb_cliente tb_cliente_clie_correo_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_cliente
    ADD CONSTRAINT tb_cliente_clie_correo_key UNIQUE (clie_correo);


--
-- Name: tb_cliente tb_cliente_clie_direccion_id_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_cliente
    ADD CONSTRAINT tb_cliente_clie_direccion_id_key UNIQUE (clie_direccion_id);


--
-- Name: tb_cliente tb_cliente_clie_usuario_id_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_cliente
    ADD CONSTRAINT tb_cliente_clie_usuario_id_key UNIQUE (clie_usuario_id);


--
-- Name: tb_cliente tb_cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_cliente
    ADD CONSTRAINT tb_cliente_pkey PRIMARY KEY (clie_id);


--
-- Name: tb_direccion_cliente tb_direccion_cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_direccion_cliente
    ADD CONSTRAINT tb_direccion_cliente_pkey PRIMARY KEY (dicl_id);


--
-- Name: tb_distrito tb_distrito_dist_nombre_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_distrito
    ADD CONSTRAINT tb_distrito_dist_nombre_key UNIQUE (dist_nombre);


--
-- Name: tb_distrito tb_distrito_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_distrito
    ADD CONSTRAINT tb_distrito_pkey PRIMARY KEY (dist_id);


--
-- Name: tb_editorial tb_editorial_edit_nombre_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_editorial
    ADD CONSTRAINT tb_editorial_edit_nombre_key UNIQUE (edit_nombre);


--
-- Name: tb_editorial tb_editorial_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_editorial
    ADD CONSTRAINT tb_editorial_pkey PRIMARY KEY (edit_id);


--
-- Name: tb_estado_prestamo tb_estado_prestamo_espr_nombre_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_estado_prestamo
    ADD CONSTRAINT tb_estado_prestamo_espr_nombre_key UNIQUE (espr_nombre);


--
-- Name: tb_estado_prestamo tb_estado_prestamo_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_estado_prestamo
    ADD CONSTRAINT tb_estado_prestamo_pkey PRIMARY KEY (espr_id);


--
-- Name: tb_genero tb_genero_gene_nombre_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_genero
    ADD CONSTRAINT tb_genero_gene_nombre_key UNIQUE (gene_nombre);


--
-- Name: tb_genero tb_genero_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_genero
    ADD CONSTRAINT tb_genero_pkey PRIMARY KEY (gene_id);


--
-- Name: tb_nivel_educativo tb_nivel_educativo_nied_nombre_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_nivel_educativo
    ADD CONSTRAINT tb_nivel_educativo_nied_nombre_key UNIQUE (nied_nombre);


--
-- Name: tb_nivel_educativo tb_nivel_educativo_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_nivel_educativo
    ADD CONSTRAINT tb_nivel_educativo_pkey PRIMARY KEY (nied_id);


--
-- Name: tb_pais tb_pais_pais_nombre_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_pais
    ADD CONSTRAINT tb_pais_pais_nombre_key UNIQUE (pais_nombre);


--
-- Name: tb_pais tb_pais_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_pais
    ADD CONSTRAINT tb_pais_pkey PRIMARY KEY (pais_id);


--
-- Name: tb_prestamo tb_prestamo_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_prestamo
    ADD CONSTRAINT tb_prestamo_pkey PRIMARY KEY (pres_id);


--
-- Name: tb_provincia tb_provincia_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_provincia
    ADD CONSTRAINT tb_provincia_pkey PRIMARY KEY (prov_id);


--
-- Name: tb_provincia tb_provincia_prov_nombre_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_provincia
    ADD CONSTRAINT tb_provincia_prov_nombre_key UNIQUE (prov_nombre);


--
-- Name: tb_recurso_textual_autor tb_recurso_textual_autor_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual_autor
    ADD CONSTRAINT tb_recurso_textual_autor_pkey PRIMARY KEY (reau_recurso_textual_id, reau_autor_id);


--
-- Name: tb_recurso_textual_codigo tb_recurso_textual_codigo_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual_codigo
    ADD CONSTRAINT tb_recurso_textual_codigo_pkey PRIMARY KEY (reco_id);


--
-- Name: tb_recurso_textual tb_recurso_textual_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual
    ADD CONSTRAINT tb_recurso_textual_pkey PRIMARY KEY (rete_id);


--
-- Name: tb_recurso_textual tb_recurso_textual_rete_codigo_base_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual
    ADD CONSTRAINT tb_recurso_textual_rete_codigo_base_key UNIQUE (rete_codigo_base);


--
-- Name: tb_region tb_region_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_region
    ADD CONSTRAINT tb_region_pkey PRIMARY KEY (regi_id);


--
-- Name: tb_region tb_region_regi_nombre_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_region
    ADD CONSTRAINT tb_region_regi_nombre_key UNIQUE (regi_nombre);


--
-- Name: tb_registro_accion_usuario tb_registro_accion_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_registro_accion_usuario
    ADD CONSTRAINT tb_registro_accion_usuario_pkey PRIMARY KEY (reau_id);


--
-- Name: tb_rol_usuario tb_rol_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_rol_usuario
    ADD CONSTRAINT tb_rol_usuario_pkey PRIMARY KEY (rolu_id);


--
-- Name: tb_rol_usuario tb_rol_usuario_rolu_nombre_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_rol_usuario
    ADD CONSTRAINT tb_rol_usuario_rolu_nombre_key UNIQUE (rolu_nombre);


--
-- Name: tb_tipo_documento tb_tipo_documento_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_documento
    ADD CONSTRAINT tb_tipo_documento_pkey PRIMARY KEY (tido_id);


--
-- Name: tb_tipo_documento tb_tipo_documento_tido_tipo_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_documento
    ADD CONSTRAINT tb_tipo_documento_tido_tipo_key UNIQUE (tido_tipo);


--
-- Name: tb_tipo_estado tb_tipo_estado_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_estado
    ADD CONSTRAINT tb_tipo_estado_pkey PRIMARY KEY (ties_id);


--
-- Name: tb_tipo_estado tb_tipo_estado_ties_tipo_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_estado
    ADD CONSTRAINT tb_tipo_estado_ties_tipo_key UNIQUE (ties_tipo);


--
-- Name: tb_tipo_prestamo tb_tipo_prestamo_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_prestamo
    ADD CONSTRAINT tb_tipo_prestamo_pkey PRIMARY KEY (tipr_id);


--
-- Name: tb_tipo_prestamo tb_tipo_prestamo_tipr_tipo_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_prestamo
    ADD CONSTRAINT tb_tipo_prestamo_tipr_tipo_key UNIQUE (tipr_tipo);


--
-- Name: tb_tipo_texto tb_tipo_texto_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_texto
    ADD CONSTRAINT tb_tipo_texto_pkey PRIMARY KEY (tite_id);


--
-- Name: tb_tipo_texto tb_tipo_texto_tite_tipo_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_tipo_texto
    ADD CONSTRAINT tb_tipo_texto_tite_tipo_key UNIQUE (tite_tipo);


--
-- Name: tb_usuario tb_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_usuario
    ADD CONSTRAINT tb_usuario_pkey PRIMARY KEY (usua_id);


--
-- Name: tb_usuario tb_usuario_usua_documento_key; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_usuario
    ADD CONSTRAINT tb_usuario_usua_documento_key UNIQUE (usua_documento);


--
-- Name: tb_recurso_textual_codigo unq_recurso_textual_codigo_base_ejemplar; Type: CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual_codigo
    ADD CONSTRAINT unq_recurso_textual_codigo_base_ejemplar UNIQUE (reco_rete_codigo_base, reco_codigo_ejemplar);


--
-- Name: tb_prestamo tr_realizar_prestamo; Type: TRIGGER; Schema: public; Owner: bmpch_user
--

CREATE TRIGGER tr_realizar_prestamo AFTER INSERT OR UPDATE ON public.tb_prestamo FOR EACH ROW EXECUTE FUNCTION public.fn_realizar_prestamo();


--
-- Name: tb_carnet tr_verficar_carnet_cambio_estado; Type: TRIGGER; Schema: public; Owner: bmpch_user
--

CREATE TRIGGER tr_verficar_carnet_cambio_estado BEFORE UPDATE ON public.tb_carnet FOR EACH ROW EXECUTE FUNCTION public.fn_verificar_carnet_cambio_estado();


--
-- Name: tb_recurso_textual tr_verificar_recurso_textual_creacion; Type: TRIGGER; Schema: public; Owner: bmpch_user
--

CREATE TRIGGER tr_verificar_recurso_textual_creacion BEFORE INSERT OR UPDATE ON public.tb_recurso_textual FOR EACH ROW EXECUTE FUNCTION public.fn_verificar_recurso_textual_creacion();


--
-- Name: tb_prestamo tr_verificar_requisitos_prestamos; Type: TRIGGER; Schema: public; Owner: bmpch_user
--

CREATE TRIGGER tr_verificar_requisitos_prestamos BEFORE INSERT OR UPDATE ON public.tb_prestamo FOR EACH ROW EXECUTE FUNCTION public.fn_verificar_requisitos_prestamos();


--
-- Name: tb_carnet fk_carnet_tipo_estado; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_carnet
    ADD CONSTRAINT fk_carnet_tipo_estado FOREIGN KEY (carn_tipo_estado_id) REFERENCES public.tb_tipo_estado(ties_id);


--
-- Name: tb_categoria_recurso_textual fk_categoria_recurso_textual_categoria; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_categoria_recurso_textual
    ADD CONSTRAINT fk_categoria_recurso_textual_categoria FOREIGN KEY (care_categoria_id) REFERENCES public.tb_categoria(cate_id);


--
-- Name: tb_categoria_recurso_textual fk_categoria_recurso_textual_recurso; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_categoria_recurso_textual
    ADD CONSTRAINT fk_categoria_recurso_textual_recurso FOREIGN KEY (care_recurso_textual_id) REFERENCES public.tb_recurso_textual(rete_id);


--
-- Name: tb_cliente fk_cliente_carnet; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_cliente
    ADD CONSTRAINT fk_cliente_carnet FOREIGN KEY (clie_carnet_id) REFERENCES public.tb_carnet(carn_id);


--
-- Name: tb_cliente fk_cliente_direccion; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_cliente
    ADD CONSTRAINT fk_cliente_direccion FOREIGN KEY (clie_direccion_id) REFERENCES public.tb_direccion_cliente(dicl_id);


--
-- Name: tb_cliente fk_cliente_nivel_educativo; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_cliente
    ADD CONSTRAINT fk_cliente_nivel_educativo FOREIGN KEY (clie_nivel_educativo_id) REFERENCES public.tb_nivel_educativo(nied_id);


--
-- Name: tb_cliente fk_cliente_usuario; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_cliente
    ADD CONSTRAINT fk_cliente_usuario FOREIGN KEY (clie_usuario_id) REFERENCES public.tb_usuario(usua_id);


--
-- Name: tb_direccion_cliente fk_direccion_cliente_distrito; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_direccion_cliente
    ADD CONSTRAINT fk_direccion_cliente_distrito FOREIGN KEY (dicl_distrito_id) REFERENCES public.tb_distrito(dist_id);


--
-- Name: tb_distrito fk_distrito_provincia; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_distrito
    ADD CONSTRAINT fk_distrito_provincia FOREIGN KEY (dist_provincia_id) REFERENCES public.tb_provincia(prov_id);


--
-- Name: tb_usuario fk_genero; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_usuario
    ADD CONSTRAINT fk_genero FOREIGN KEY (usua_genero_id) REFERENCES public.tb_genero(gene_id);


--
-- Name: tb_prestamo fk_prestamo_cliente; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_prestamo
    ADD CONSTRAINT fk_prestamo_cliente FOREIGN KEY (pres_cliente_id) REFERENCES public.tb_cliente(clie_id);


--
-- Name: tb_prestamo fk_prestamo_estado_prestamo; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_prestamo
    ADD CONSTRAINT fk_prestamo_estado_prestamo FOREIGN KEY (pres_estado_prestamo_id) REFERENCES public.tb_estado_prestamo(espr_id);


--
-- Name: tb_prestamo fk_prestamo_recurso_textual_codigo; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_prestamo
    ADD CONSTRAINT fk_prestamo_recurso_textual_codigo FOREIGN KEY (pres_recurso_textual_codigo_id) REFERENCES public.tb_recurso_textual_codigo(reco_id);


--
-- Name: tb_prestamo fk_prestamo_tipo_prestamo; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_prestamo
    ADD CONSTRAINT fk_prestamo_tipo_prestamo FOREIGN KEY (pres_tipo_prestamo_id) REFERENCES public.tb_tipo_prestamo(tipr_id);


--
-- Name: tb_provincia fk_provincia_region; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_provincia
    ADD CONSTRAINT fk_provincia_region FOREIGN KEY (prov_region_id) REFERENCES public.tb_region(regi_id);


--
-- Name: tb_recurso_textual_autor fk_recurso_textual_autor_autor; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual_autor
    ADD CONSTRAINT fk_recurso_textual_autor_autor FOREIGN KEY (reau_autor_id) REFERENCES public.tb_autor(auto_id);


--
-- Name: tb_recurso_textual_autor fk_recurso_textual_autor_recurso; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual_autor
    ADD CONSTRAINT fk_recurso_textual_autor_recurso FOREIGN KEY (reau_recurso_textual_id) REFERENCES public.tb_recurso_textual(rete_id);


--
-- Name: tb_recurso_textual_codigo fk_recurso_textual_codigo_recurso; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual_codigo
    ADD CONSTRAINT fk_recurso_textual_codigo_recurso FOREIGN KEY (reco_rete_codigo_base) REFERENCES public.tb_recurso_textual(rete_codigo_base) ON UPDATE CASCADE;


--
-- Name: tb_recurso_textual fk_recurso_textual_editorial; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual
    ADD CONSTRAINT fk_recurso_textual_editorial FOREIGN KEY (rete_editorial_id) REFERENCES public.tb_editorial(edit_id);


--
-- Name: tb_recurso_textual fk_recurso_textual_tipo_texto; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_recurso_textual
    ADD CONSTRAINT fk_recurso_textual_tipo_texto FOREIGN KEY (rete_tipo_texto_id) REFERENCES public.tb_tipo_texto(tite_id);


--
-- Name: tb_region fk_region_pais; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_region
    ADD CONSTRAINT fk_region_pais FOREIGN KEY (regi_pais_id) REFERENCES public.tb_pais(pais_id);


--
-- Name: tb_registro_accion_usuario fk_registro_accion_usuario_usuario; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_registro_accion_usuario
    ADD CONSTRAINT fk_registro_accion_usuario_usuario FOREIGN KEY (reau_usuario_id) REFERENCES public.tb_usuario(usua_id);


--
-- Name: tb_usuario fk_usuario_rol_usuario; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_usuario
    ADD CONSTRAINT fk_usuario_rol_usuario FOREIGN KEY (usua_rol_usuario_id) REFERENCES public.tb_rol_usuario(rolu_id);


--
-- Name: tb_usuario fk_usuario_tipo_documento; Type: FK CONSTRAINT; Schema: public; Owner: bmpch_user
--

ALTER TABLE ONLY public.tb_usuario
    ADD CONSTRAINT fk_usuario_tipo_documento FOREIGN KEY (usua_tipo_documento_id) REFERENCES public.tb_tipo_documento(tido_id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO bmpch_user;


--
-- Name: FUNCTION fn_actualizar_carnets(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_actualizar_carnets() TO bmpch_user;


--
-- Name: FUNCTION fn_actualizar_prestamos(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_actualizar_prestamos() TO bmpch_user;


--
-- Name: FUNCTION fn_realizar_prestamo(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_realizar_prestamo() TO bmpch_user;


--
-- Name: FUNCTION fn_verificar_carnet_cambio_estado(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_verificar_carnet_cambio_estado() TO bmpch_user;


--
-- Name: FUNCTION fn_verificar_recurso_textual_creacion(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_verificar_recurso_textual_creacion() TO bmpch_user;


--
-- Name: FUNCTION fn_verificar_requisitos_prestamos(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_verificar_requisitos_prestamos() TO bmpch_user;


--
-- Name: TABLE job; Type: ACL; Schema: cron; Owner: bmpch_user
--

REVOKE ALL ON TABLE cron.job FROM postgres;
REVOKE SELECT ON TABLE cron.job FROM PUBLIC;
GRANT ALL ON TABLE cron.job TO bmpch_user;
GRANT SELECT ON TABLE cron.job TO PUBLIC;


--
-- Name: TABLE job_run_details; Type: ACL; Schema: cron; Owner: bmpch_user
--

REVOKE ALL ON TABLE cron.job_run_details FROM postgres;
REVOKE SELECT,DELETE ON TABLE cron.job_run_details FROM PUBLIC;
GRANT ALL ON TABLE cron.job_run_details TO bmpch_user;
GRANT SELECT,DELETE ON TABLE cron.job_run_details TO PUBLIC;


--
-- Name: TABLE tb_autor; Type: ACL; Schema: public; Owner: bmpch_user
--

GRANT SELECT ON TABLE public.tb_autor TO cliente;


--
-- Name: TABLE tb_carnet; Type: ACL; Schema: public; Owner: bmpch_user
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tb_carnet TO encargado_biblioteca;


--
-- Name: TABLE tb_categoria; Type: ACL; Schema: public; Owner: bmpch_user
--

GRANT SELECT ON TABLE public.tb_categoria TO cliente;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tb_categoria TO encargado_biblioteca;


--
-- Name: TABLE tb_categoria_recurso_textual; Type: ACL; Schema: public; Owner: bmpch_user
--

GRANT SELECT ON TABLE public.tb_categoria_recurso_textual TO cliente;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tb_categoria_recurso_textual TO encargado_biblioteca;


--
-- Name: TABLE tb_cliente; Type: ACL; Schema: public; Owner: bmpch_user
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tb_cliente TO encargado_biblioteca;


--
-- Name: TABLE tb_editorial; Type: ACL; Schema: public; Owner: bmpch_user
--

GRANT SELECT ON TABLE public.tb_editorial TO cliente;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tb_editorial TO encargado_biblioteca;


--
-- Name: TABLE tb_prestamo; Type: ACL; Schema: public; Owner: bmpch_user
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tb_prestamo TO encargado_biblioteca;


--
-- Name: TABLE tb_recurso_textual; Type: ACL; Schema: public; Owner: bmpch_user
--

GRANT SELECT ON TABLE public.tb_recurso_textual TO cliente;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tb_recurso_textual TO encargado_biblioteca;


--
-- Name: TABLE tb_recurso_textual_autor; Type: ACL; Schema: public; Owner: bmpch_user
--

GRANT SELECT ON TABLE public.tb_recurso_textual_autor TO cliente;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tb_recurso_textual_autor TO encargado_biblioteca;


--
-- Name: TABLE tb_recurso_textual_codigo; Type: ACL; Schema: public; Owner: bmpch_user
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tb_recurso_textual_codigo TO encargado_biblioteca;


--
-- Name: TABLE tb_usuario; Type: ACL; Schema: public; Owner: bmpch_user
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tb_usuario TO encargado_biblioteca;


--
-- PostgreSQL database dump complete
--

