\c db_biblioteca;

CREATE OR REPLACE FUNCTION fn_actualizar_carnets() RETURNS void AS
$$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_actualizar_prestamos() RETURNS void AS
$$
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
$$ LANGUAGE plpgsql;