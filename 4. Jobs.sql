SELECT cron.schedule('Actualizar Carnets', '0 2 * * *', $$
    DO $$
DECLARE 
    id_tipo_estado_vencido BIGINT;
cantidad_carnets_por_vencer BIGINT;
BEGIN
SELECT COUNT(carn_fec_vencimiento) INTO cantidad_carnets_por_vencer
FROM tb_carnet
WHERE carn_fec_vencimiento = CURRENT_DATE - INTERVAL '1 day';

id_tipo_estado_vencido := 2; -- VERIFICAR ESTO!

    -- Actualización automática de carnet para clientes.
UPDATE carnets
SET tipo_estado_id = id_tipo_estado_vencido
WHERE activo = 1 AND fecha_vencimiento = CURRENT_DATE - INTERVAL '1 day';

-- Actualización automática de carnet para administradores y el cambio de su estado a activo.
UPDATE carnets AS CR
    INNER JOIN clientes AS CL ON CL.carnet_id = CR.id_carnet
    INNER JOIN usuarios AS U ON U.cliente_id = CL.id_cliente
    SET tipo_estado_id = 1, fecha_emision = CURRENT_DATE,
        fecha_vencimiento = CURRENT_DATE + INTERVAL '1 year'
WHERE U.rol_usuario_id = 1 AND fecha_vencimiento = CURRENT_DATE - INTERVAL '1 day';
END $$;
$$);
