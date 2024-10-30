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
    f_recurso_textual_id BIGINT;
    f_recurso_textual_stock_disp INT;
BEGIN

    f_estado_carnet := (
        SELECT TIE.ties_activo FROM tb_usuario AS USU
               INNER JOIN tb_cliente AS CLI ON USU.usua_id = CLI.clie_usuario_id
               INNER JOIN tb_carnet AS CAR ON CAR.carn_id = CLI.clie_carnet_id
               INNER JOIN tb_tipo_estado AS TIE ON TIE.ties_id = CAR.carn_tipo_estado_id
        WHERE USU.usua_id = NEW.pres_usuario_id
    );

    IF NOT f_estado_carnet THEN
        RAISE EXCEPTION 'El estado del carnet del usuario (%) no está activo', NEW.pres_usuario_id;
    END IF;

    f_recurso_textual_disponible := (
        SELECT RT.activo FROM tb_recurso_textual_codigo AS RTC
                                  INNER JOIN tb_recurso_textual AS RT ON RTC.reco_rete_codigo_base = RT.rete_codigo_base
        WHERE RTC.reco_id = NEW.pres_recurso_textual_codigo_id);

    IF NOT f_recurso_textual_disponible THEN
        RAISE EXCEPTION 'El recurso textual no se encuentra disponible';
    END IF;

    f_recurso_textual_ejemplar_disponible := (
        SELECT reco_disponible FROM tb_recurso_textual_codigo
        WHERE reco_id = NEW.pres_recurso_textual_codigo_id
    );

    IF NOT f_recurso_textual_ejemplar_disponible THEN
        RAISE EXCEPTION 'El recurso textual no está disponible.';
    END IF;

    f_recurso_textual_id := (
        SELECT reco_recurso_textual_id FROM tb_recurso_textual_codigo
        WHERE reco_id = NEW.pres_recurso_textual_codigo_id
    );

    f_recurso_textual_stock_disp := (
        SELECT COUNT(reco_recurso_textual_id) FROM tb_recurso_textual_codigo
        WHERE reco_recurso_textual_id = f_recurso_textual_id AND reco_disponible = TRUE
    );

    IF f_recurso_textual_stock_disp < 2 THEN
        RAISE EXCEPTION 'No se puede realizar la operación, debe de quedar al menos un ejemplar en la biblioteca';
    END IF;

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