USE bmpch;

-- Habilitar programador de eventos
SET GLOBAL event_scheduler = ON;

DELIMITER $

CREATE EVENT event_actualizarEstadoCarnet
    ON SCHEDULE EVERY 1 DAY
    DO
BEGIN

    DECLARE id_tipo_estado_vencido BIGINT;
    DECLARE cantidad_carnets_por_vencer BIGINT;

    SET cantidad_carnets_por_vencer = (
        SELECT COUNT(fecha_vencimiento) FROM carnets
        WHERE fecha_vencimiento = DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY)
    );

    SET id_tipo_estado_vencido = 2; -- VERIFICAR ESTO!

    -- Actualización automatica de carnet para clientes.
    -- ver caso cuando está suspendido pero a la vez puede estar vencido (plantearlo)
    UPDATE carnets INNER JOIN tipos_estados ON tipo_estado_id = id_tipo_estado
    SET tipo_estado_id = id_tipo_estado_vencido
    WHERE activo = 1 AND fecha_vencimiento = DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY);

    -- Actualización automatica de carnet para administradores y el cambio de su estado a activo.
    UPDATE carnets AS CR
        INNER JOIN clientes AS CL ON CL.carnet_id = CR.id_carnet
        INNER JOIN usuarios AS U ON U.cliente_id = CL.id_cliente
    SET tipo_estado_id = 1, fecha_emision = CURRENT_DATE,
        fecha_vencimiento = DATE_ADD(CURRENT_DATE, INTERVAL 1 YEAR)
    WHERE U.rol_usuario_id = 1 AND fecha_vencimiento = DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY);

END $

DELIMITER ;