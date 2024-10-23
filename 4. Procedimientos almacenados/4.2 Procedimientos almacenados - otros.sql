\c db_biblioteca

/*
 * PROCEDURE: sp_realizar_prestamos
 *
 * DESCRIPCIÓN:
 * Registra un nuevo préstamo en la tabla 'tb_prestamo' y actualiza el recurso textual como no disponible.
 *
 * PARÁMETROS:
 *   @p_usuario_id BIGINT: ID del usuario que realiza el préstamo.
 *   @p_recurso_textual_codigo_id BIGINT: ID del recurso que se presta.
 *   @p_tipo_prestamo_id SMALLINT: ID del tipo de préstamo.
 *   @p_fec_programada DATE: Fecha programada para el préstamo.
 *
 * EXCEPCIONES:
 *   Si ocurre un error, se registra un mensaje de error con la descripción del problema y se realiza un ROLLBACK.
 *
 * NOTA IMPORTANTE:
 *  - Se supone que el ID 1 de 'pres_estado_prestamo_id' corresponde a un estado como 'Activo' o similar.
 *  - Al llamar al procedimiento almacenado, debe utilizarse de la siguiente manera:
 *    CALL sp_realizar_prestamos(1::BIGINT, 1::BIGINT, 1::SMALLINT, '2024-10-10'::DATE);
 *    Este es un ejemplo de cómo se debe de llamar el procedimiento almacenado.
 */
CREATE OR REPLACE PROCEDURE sp_realizar_prestamos (
    p_usuario_id BIGINT,
    p_recurso_textual_codigo_id BIGINT,
    p_tipo_prestamo_id SMALLINT,
    p_fec_programada DATE
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN

    BEGIN

        INSERT INTO tb_prestamo(pres_usuario_id, pres_recurso_textual_codigo_id, pres_tipo_prestamo_id,
                                pres_estado_prestamo_id, pres_fec_inicial, pres_fec_final, pres_fec_programada)
        VALUES (p_usuario_id, p_recurso_textual_codigo_id,
                p_tipo_prestamo_id, 1, DEFAULT, DEFAULT,
                p_fec_programada);

        UPDATE tb_recurso_textual_codigo SET reco_disponible = FALSE
        WHERE reco_id = p_recurso_textual_codigo_id;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Se produjo un error al realizar el prestamo: %', SQLERRM;
            RAISE;

    END;
END;
$$;

/*
 * PROCEDURE: sp_renovar_carnet
 *
 * DESCRIPCIÓN:
 * Renueva el carnet de un cliente en la base de datos, actualizando la fecha de
 * emisión y la fecha de vencimiento. El procedimiento busca el ID del carnet
 * asociado al documento proporcionado y lo actualiza a un estado activo si no lo está.
 *
 * PARÁMETROS:
 *   @p_documento VARCHAR(20): Documento del cliente cuyo carnet se va a renovar.
 *
 * EXCEPCIONES:
 *   Si ocurre un error durante el proceso de renovación, se realiza un ROLLBACK y
 *   se genera un mensaje de aviso que notifica el error. Si no se encuentra el ID
 *   del carnet, se lanza una excepción específica.
 *
 * NOTA IMPORTANTE:
 *  - Se deduce que el tipo de estado activo tiene de id 1
 */
CREATE OR REPLACE PROCEDURE sp_renovar_carnet(
    p_documento VARCHAR(20)
)
    LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_id_carnet BIGINT;
    v_id_tipo_estado BIGINT;
BEGIN

    BEGIN

        v_id_carnet := (SELECT C.clie_carnet_id FROM tb_usuario AS U
                                                         INNER JOIN tb_cliente AS C ON U.usua_id = C.clie_usuario_id
                        WHERE U.usua_documento = p_documento);

        IF v_id_carnet IS NULL THEN
            RAISE EXCEPTION 'No se pudo obtener el id del carnet del documento: %s', p_documento;
        END IF;

        v_id_tipo_estado := (
            SELECT carn_tipo_estado_id FROM tb_carnet WHERE carn_id = v_id_carnet
        );

        IF v_id_tipo_estado NOT BETWEEN 1 AND 2 THEN
            RAISE NOTICE 'No se puede renovar carnets que no están entre activo o vencido.';
            RETURN;
        END IF;

        UPDATE tb_carnet AS C SET carn_tipo_estado_id = 1, carn_fec_emision = CURRENT_DATE,
                                  carn_fec_vencimiento = (CURRENT_DATE + INTERVAL '1 YEAR')
        WHERE C.carn_id = v_id_carnet AND C.carn_tipo_estado_id <> 1;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Falló al renovar el carnet: %s', SQLERRM;
            RAISE;

    END;

END;
$$;

/*
 * PROCEDURE: sp_suspender_carnet
 *
 * DESCRIPCIÓN:
 * Suspende el carnet de un cliente. Cambia el estado del carnet a
 * un estado de suspensión. Se busca el carnet a través del documento del cliente.
 *
 * PARÁMETROS:
 *   @p_documento VARCHAR(20): Documento de identificación del cliente cuyo carnet se va a suspender.
 *
 * EXCEPCIONES:
 *   Si no se encuentra el carnet asociado al documento, se lanza una excepción.
 *   Si ocurre un error durante el proceso, se genera un mensaje de aviso que notifica el error.
 *
 * NOTA IMPORTANTE:
 *  - Este procedimiento debe ser llamado con el documento del cliente para el cual se desea
 *    suspender el carnet.
 */
CREATE OR REPLACE PROCEDURE sp_suspender_carnet(
    p_documento VARCHAR(20)
)
    LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_id_carnet BIGINT;
BEGIN

    BEGIN

        v_id_carnet := (SELECT C.clie_carnet_id FROM tb_usuario AS U
                                                         INNER JOIN tb_cliente AS C ON U.usua_id = C.clie_usuario_id
                        WHERE U.usua_documento = p_documento);

        IF v_id_carnet IS NULL THEN
            RAISE EXCEPTION 'No se pudo obtener el id del carnet del documento: %s', p_documento;
        END IF;

        UPDATE tb_carnet AS C SET carn_tipo_estado_id = 3
        WHERE C.carn_id = v_id_carnet AND C.carn_tipo_estado_id <> 3;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Falló al renovar el carnet: %s', SQLERRM;
            RAISE;

    END;

END;
$$;

/*
 * PROCEDURE: sp_quitar_suspension_carnet
 *
 * DESCRIPCIÓN:
 * Quita la suspensión del carnet de un cliente. Cambia el estado del carnet
 * a activo o vencido, según la fecha de vencimiento. Se busca el carnet a través del documento
 * del cliente.
 *
 * PARÁMETROS:
 *   @p_documento VARCHAR(20): Documento de identificación del cliente cuyo carnet se va a activar.
 *
 * EXCEPCIONES:
 *   Si no se encuentra el carnet asociado al documento, se lanza una excepción.
 *   Si ocurre un error durante el proceso, se genera un mensaje de aviso que notifica el error.
 *
 * NOTA IMPORTANTE:
 *  - Este procedimiento debe ser llamado con el documento del cliente para el cual se desea
 *    quitar la suspensión del carnet.
 */
CREATE OR REPLACE PROCEDURE sp_quitar_suspension_carnet(
    p_documento VARCHAR(20)
)
    LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_id_carnet BIGINT;
    v_fec_vencimiento DATE;
    v_id_tipo_estado_nuevo BIGINT;
BEGIN

    BEGIN

        v_id_carnet := (SELECT C.clie_carnet_id FROM tb_usuario AS U
                                                         INNER JOIN tb_cliente AS C ON U.usua_id = C.clie_usuario_id
                        WHERE U.usua_documento = p_documento);

        IF v_id_carnet IS NULL THEN
            RAISE EXCEPTION 'No se pudo obtener el id del carnet del documento: %s', p_documento;
        END IF;

        v_fec_vencimiento := (SELECT carn_fec_vencimiento FROM tb_carnet WHERE carn_id = v_id_carnet);

        CASE
            WHEN v_fec_vencimiento <= (CURRENT_DATE - INTERVAL '1 DAY') THEN
                v_id_tipo_estado_nuevo = 2;
            WHEN v_fec_vencimiento >= CURRENT_DATE THEN
                v_id_tipo_estado_nuevo = 1;
            ELSE
                NULL;
            END CASE;


        UPDATE tb_carnet AS C SET carn_tipo_estado_id = v_id_tipo_estado_nuevo
        WHERE C.carn_id = v_id_carnet AND C.carn_tipo_estado_id = 3;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Falló al renovar el carnet: %s', SQLERRM;
            RAISE;

    END;

END;
$$;
