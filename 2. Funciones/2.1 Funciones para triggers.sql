\c db_biblioteca;

-- Creación de funciones para triggers.

/*
 * FUNCTION: fn_verificar_requisitos_prestamos
 *
 * DESCRIPCIÓN:
 * Verifica los requisitos necesarios para realizar un préstamo. Comprueba si el carnet del usuario
 * está activo, si el recurso textual está disponible y si queda al menos un ejemplar en la biblioteca.
 * Esta función se utiliza como parte de un trigger en la tabla 'tb_prestamo'.
 *
 * RETORNA:
 *   - Esta función no retorna un valor explícito, pero lanza excepciones si no se cumplen los requisitos.
 *
 * EXCEPCIONES:
 *   - Si el estado del carnet del usuario no está activo, se lanza una excepción.
 *   - Si el recurso textual no está disponible, se lanza una excepción.
 *   - Si no queda al menos un ejemplar disponible del recurso textual, se lanza una excepción.
 *
 * NOTAS:
 *   - Esta función está diseñada para ser utilizada en un contexto de trigger,
 *     y se asume que el trigger llama a esta función antes de realizar la inserción
 *     de un nuevo préstamo.
 */
CREATE OR REPLACE FUNCTION fn_verificar_requisitos_prestamos()
RETURNS TRIGGER AS $$
DECLARE
    f_estado_carnet BOOLEAN;
    f_recurso_textual_disponible BOOLEAN;
    f_recurso_textual_ejemplar_disponible BOOLEAN;
    f_recurso_textual_codigo_base_nuevo VARCHAR;
    f_recurso_textual_codigo_base_antiguo VARCHAR;
    f_recurso_textual_stock_disp_nuevo INT;
BEGIN

    f_estado_carnet := (
        SELECT TIE.ties_activo FROM tb_usuario AS USU
               INNER JOIN tb_cliente AS CLI ON USU.usua_id = CLI.clie_usuario_id
               INNER JOIN tb_carnet AS CAR ON CAR.carn_id = CLI.clie_carnet_id
               INNER JOIN tb_tipo_estado AS TIE ON TIE.ties_id = CAR.carn_tipo_estado_id
        WHERE USU.usua_id = NEW.pres_usuario_id
    );

    IF f_estado_carnet IS NULL THEN
        RAISE EXCEPTION 'El usuario no tiene un carnet establecido';
    END IF;

    IF NOT f_estado_carnet AND NEW.pres_usuario_id <> OLD.pres_usuario_id THEN
        RAISE EXCEPTION 'El estado del carnet del usuario (%) no está activo', NEW.pres_usuario_id;
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

    IF NEW.pres_fec_inicial <> CURRENT_DATE THEN
        RAISE EXCEPTION 'No se puede realizar la operación, la fecha inicial no puede ser menor o mayor a la actual.';
    END IF ;

    IF NEW.pres_fec_final < NEW.pres_fec_inicial THEN
        RAISE EXCEPTION 'No se puede realizar la operación, la fecha final no puede ser menor que la inicial.';
    END IF;

    IF NEW.pres_fec_programada < CURRENT_DATE THEN
        RAISE EXCEPTION 'No se puede realizar la operación, la fecha programada no puede ser menor a la actual.';
    END IF ;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

/*
 * FUNCTION: fn_verificar_carnet_cambio_estado
 *
 * DESCRIPCIÓN:
 * Verifica los requisitos necesarios para cambiar el estado de un carnet en la base de datos.
 * Comprueba si el estado actual y el nuevo estado del carnet son válidos, teniendo en cuenta
 * la fecha de vencimiento. Esta función se utiliza como parte de un trigger en la tabla 'tb_carnet'.
 *
 * RETORNA:
 *   - Esta función no retorna un valor explícito, pero lanza excepciones si no se cumplen los requisitos.
 *
 * EXCEPCIONES:
 *   - Si la fecha de vencimiento es menor a la fecha actual cuando se intenta activar el carnet,
 *     se lanza una excepción.
 *   - Si la fecha de vencimiento es mayor o igual a la fecha actual cuando se intenta suspender el carnet,
 *     se lanza una excepción.
 *
 * NOTAS:
 *   - Esta función está diseñada para ser utilizada en un contexto de trigger,
 *     y se asume que el trigger llama a esta función antes de realizar la actualización
 *     del estado del carnet.
 */
CREATE OR REPLACE FUNCTION fn_verificar_carnet_cambio_estado()
    RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_verificar_recurso_textual_creacion()
    RETURNS TRIGGER AS $$
BEGIN

    IF NEW.rete_fec_publicacion > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de publicación no puede ser futura.';
    END IF;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_realizar_prestamo()
    RETURNS TRIGGER AS $$
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
        UPDATE tb_recurso_textual_codigo SET reco_disponible = FALSE
        WHERE reco_id = NEW.pres_recurso_textual_codigo_id;
    END IF;

    RETURN NEW;
END
$$ LANGUAGE plpgsql;




