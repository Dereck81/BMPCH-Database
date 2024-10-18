\c bd_Biblioteca;

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

