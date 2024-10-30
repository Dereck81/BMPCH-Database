\c db_biblioteca;

/*
 * TRIGGER: tr_verificar_requisitos_prestamos
 *
 * DESCRIPCIÓN:
 * Este trigger se activa antes de insertar un nuevo registro en la tabla 'tb_prestamo'.
 * Llama a la función 'fn_verificar_requisitos_prestamos' para verificar si se cumplen
 * los requisitos necesarios para realizar el préstamo.
 *
 * CONTEXTO:
 * Este trigger asegura que no se puedan realizar préstamos si el carnet del usuario no
 * está activo, si el recurso textual no está disponible o si no queda al menos un ejemplar
 * en la biblioteca.
 *
 */
CREATE TRIGGER tr_verificar_requisitos_prestamos
BEFORE INSERT ON tb_prestamo
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_requisitos_prestamos();

/*
 * TRIGGER: tr_verificar_carnet_cambio_estado
 *
 * DESCRIPCIÓN:
 * Este trigger se activa antes de actualizar un registro en la tabla 'tb_carnet'.
 * Llama a la función 'fn_verificar_carnet_cambio_estado' para verificar si se cumplen
 * los requisitos necesarios para cambiar el estado del carnet.
 *
 * CONTEXTO:
 * Este trigger garantiza que el cambio de estado del carnet solo se realice si la
 * fecha de vencimiento es válida, asegurando que no se activen carnets vencidos
 * ni se suspendan carnets activos.
 *
 * NOTAS:
 *   - Este trigger ayuda a mantener la integridad de los datos relacionados con los
 *     carnets y su estado en la base de datos.
 */
CREATE TRIGGER tr_verficar_carnet_cambio_estado
BEFORE UPDATE ON tb_carnet
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_carnet_cambio_estado();

CREATE TRIGGER tr_verificar_recurso_textual_creacion
    BEFORE INSERT OR UPDATE ON tb_recurso_textual
    FOR EACH ROW
EXECUTE FUNCTION fn_verificar_recurso_textual_creacion();
