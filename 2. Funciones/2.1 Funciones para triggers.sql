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
        SELECT reco_disponible FROM tb_recurso_textual_codigo
        WHERE reco_id = NEW.pres_recurso_textual_codigo_id
    );

    IF NOT f_recurso_textual_disponible THEN
        RAISE EXCEPTION 'El recurso textual no está disponible.';
    END IF;

    f_recurso_textual_id := (
        SELECT reco_recurso_textual_id FROM tb_recurso_textual_codigo
        WHERE reco_id = NEW.pres_recurso_textual_codigo_id
    );

    f_recurso_textual_stock_disp := (
        SELECT COUNT(f_recurso_textual_id) FROM tb_recurso_textual_codigo
        WHERE reco_recurso_textual_id = f_recurso_textual_id AND reco_disponible = TRUE
    );

    IF f_recurso_textual_stock_disp < 2 THEN
        RAISE EXCEPTION 'No se puede realizar la operación, debe de quedar al menos un ejemplar en la biblioteca';
    END IF;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;


