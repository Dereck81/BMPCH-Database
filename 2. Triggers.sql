USE BMPCH;

DELIMITER $

/* Creación de trigger que verifica si se cumple con
   los requerimientos antes de realizar la operación
   de inserción en la tabla prestamos.
   Algunos requisitos son:
   - Verificar estado del carnet
   - Verificar stock del recurso textual.
*/
CREATE TRIGGER tri_verificarRequisitosPrestamos
    BEFORE INSERT ON prestamos
    FOR EACH ROW
    BEGIN
        -- Se declaran variables para usar en este trigger
        DECLARE id_tipo_estado_carnet BIGINT UNSIGNED;
        DECLARE estadoCarnet BOOLEAN;
        DECLARE nombreEstado VARCHAR(255);
        DECLARE mensajeError VARCHAR(255);
        DECLARE stockRecursoTextual SMALLINT UNSIGNED;

        -- Por medio de una consulta se consigue el id_tipo_estado_carnet
        SET id_tipo_estado_carnet = (
            SELECT TP_STD.id_tipo_estado FROM usuarios AS USR
            INNER JOIN clientes AS CLN ON USR.cliente_id = CLN.id_cliente
            INNER JOIN carnets AS CRN ON CLN.carnet_id = CRN.id_carnet
            INNER JOIN tipos_estados AS TP_STD ON CRN.tipo_estado_id = TP_STD.id_tipo_estado
            WHERE USR.id_usuario = NEW.usuario_id
        );

        -- Por medio de una consulta se consigue el estado del carnet
        SET estadoCarnet = (
            SELECT activo FROM tipos_estados AS TP_STD WHERE TP_STD.id_tipo_estado = id_tipo_estado_carnet
        );

        -- Por medio de una consulta se consigue el nombre del estado del carnet
        SET nombreEstado = (
            SELECT tipo_estado FROM tipos_estados WHERE id_tipo_estado = id_tipo_estado_carnet
        );

        /* Con un condicional se verifica si el estado del carnet es falso
        para emitir una señal de error y evitar que la insercion de datos
        se realice.*/
        IF NOT estadoCarnet THEN
            SET mensajeError = CONCAT('No se puede realizar esta operación. Estado del carnet: ', nombreEstado);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = mensajeError;
        END IF;

        -- Obtenemos el stock del recurso textual al cual se desea realizar un prestamo
        SET stockRecursoTextual = (
            SELECT stock FROM recursos_textuales WHERE id_recurso_textual = NEW.recurso_textual_id
        );

        -- Con un condicional verificamos si el stock no está en 0, de ser así, lanzamos una señal de error
        IF stockRecursoTextual = 1 THEN
            SET mensajeError = CONCAT(
                'No se puede realizar esta operación. No hay stock suficiente del recurso textual con ID: ',
                NEW.recurso_textual_id
            );
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = mensajeError;
        END IF;

    END $

/* Creación de trigger que disminuye el stock de un libro, revista, etc.
   Después de realizar una operación de inserción en la tabla prestamos.*/
CREATE TRIGGER tri_modificarStockRecursoTextual
    AFTER INSERT ON prestamos
    FOR EACH ROW
    BEGIN
        DECLARE stockRecursoTextual SMALLINT UNSIGNED;

         -- Obtenemos el stock del recurso textual al cual se realizó un prestamo
        SET stockRecursoTextual = (
            SELECT stock FROM recursos_textuales WHERE id_recurso_textual = NEW.recurso_textual_id
        );

        /* Con un UPDATE, actualizamos el stock del recurso textual
        al cual se realizó un prestamo, disminuyendo en 1*/
        UPDATE recursos_textuales SET stock = stockRecursoTextual - 1
        WHERE id_recurso_textual = NEW.recurso_textual_id;

    END $

/*CREACION DE TRIGGER QUE SE LANZA AL MOMENTO DE MODIFICAR UN VALOR EN LOS CARNETS
  ESPECIALMENTE VERIFICAR A LA HORA DE VER SI EL ESTADO DEL CARNET VA A CAMBIAR.
 */
CREATE TRIGGER tri_verificarModificacionCarnet
    BEFORE UPDATE ON carnets
    FOR EACH ROW
    BEGIN

        IF (NEW.tipo_estado_id = 2 AND NOT CURRENT_DATE > OLD.fecha_vencimiento) THEN -- VERIFICAR ESTO!

        END IF;



    END $

DELIMITER ;
