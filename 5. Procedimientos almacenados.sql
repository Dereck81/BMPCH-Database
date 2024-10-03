USE bmpch;

DELIMITER $


-- TODO: FALTA VERIFICAR COMO SE VA A PROPORCIONAR EL CODIGO DEL CARNET
DROP PROCEDURE IF EXISTS sp_registrarClientes$
CREATE PROCEDURE sp_registrarClientes(
    IN p_nombre VARCHAR(255),
    IN p_apellido_paterno VARCHAR(255),
    IN p_apellido_materno VARCHAR(255),
    IN p_genero_id BIGINT UNSIGNED,
    IN p_documento VARCHAR(20),
    IN p_tipo_documento_id BIGINT UNSIGNED,
    IN p_telefono CHAR(9),
    IN p_correo VARCHAR(255),
    IN p_nivel_educativo_id BIGINT UNSIGNED,
    IN p_rol_usuario_id BIGINT UNSIGNED,
    IN p_pais VARCHAR(255),
    IN p_region VARCHAR(255),
    IN p_provincia VARCHAR(255),
    IN p_distrito VARCHAR(255),
    IN p_direccion VARCHAR(255),
    IN p_psk VARCHAR(255)
)
BEGIN
    DECLARE id_carnet_, id_direccion_cliente_, id_cliente_ BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
        BEGIN
           ROLLBACK;
           RESIGNAL;
        END;

    START TRANSACTION;

        INSERT INTO carnets(tipo_estado_id, codigo, fecha_emision, fecha_vencimiento)
            VALUES (1, 'nosequeponerleaqui', DEFAULT, DEFAULT);

        SET id_carnet_ = LAST_INSERT_ID();

        CALL sp_registrarDireccionRetorno(p_pais, p_region, p_provincia,
                                          p_distrito, p_direccion,
                                          id_direccion_cliente_);

        IF id_direccion_cliente_ IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se pudo registrar la dirección.';
        END IF;

        INSERT INTO clientes(nombre, apellido_paterno, apellido_materno, genero_id, direccion_cliente_id, telefono, correo, carnet_id, nivel_educativo_id)
            VALUES (p_nombre, p_apellido_paterno, p_apellido_materno,
                    p_genero_id, id_direccion_cliente_, p_telefono,
                    p_correo, id_carnet_, p_nivel_educativo_id);

        SET id_cliente_ = LAST_INSERT_ID();

        -- TODO: VERIFICAR EL ID DEL P_ROL_USUARIO (TIENE QUE SER UN ID YA ESTABLECIDO)

        INSERT INTO usuarios(cliente_id, rol_usuario_id, documento, tipo_documento_id, psk)
            VALUES (id_cliente_, p_rol_usuario_id, p_documento,
                    p_tipo_documento_id, p_psk);

    COMMIT;

END $

DROP PROCEDURE IF EXISTS sp_registrarDireccion$
CREATE PROCEDURE sp_registrarDireccion(
    IN p_pais VARCHAR(255),
    IN p_region VARCHAR(255),
    IN p_provincia VARCHAR(255),
    IN p_distrito VARCHAR(255),
    IN p_direccion VARCHAR(255)
)
BEGIN

    DECLARE id_pais_, id_region_, id_provincia_, id_distrito_, id_direccion_ BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
        BEGIN
            ROLLBACK;
            RESIGNAL;
        END;

    START TRANSACTION;
        SET id_pais_ = (SELECT P.id_pais FROM paises AS P WHERE P.pais = p_pais);

        IF id_pais_ IS NULL THEN
            INSERT INTO paises(pais) VALUES(p_pais);
            SET id_pais_ = LAST_INSERT_ID();
        END IF;

        SET id_region_ = (SELECT R.id_region FROM regiones AS R
                        WHERE R.pais_id = id_pais_ AND R.region = p_region);

        IF id_region_ IS NULL THEN
            INSERT INTO regiones(pais_id, region) VALUES (id_pais_, p_region);
            SET id_region_ = LAST_INSERT_ID();
        END IF;

        SET id_provincia_ = (SELECT PR.id_provincia FROM provincias AS PR
                             WHERE PR.region_id = id_region_ AND PR.provincia = p_provincia);

        IF id_provincia_ IS NULL THEN
            INSERT INTO provincias(region_id, provincia) VALUES (id_region_, p_provincia);
            SET id_provincia_ = LAST_INSERT_ID();
        END IF;

        SET id_distrito_ = (SELECT D.id_distrito FROM distritos AS D
                             WHERE D.provincia_id = id_provincia_ AND D.distrito = p_distrito);

        IF id_distrito_ IS NULL THEN
            INSERT INTO distritos(provincia_id, distrito) VALUES (id_provincia_, p_distrito);
            SET id_distrito_ = LAST_INSERT_ID();
        END IF;

        SET id_direccion_ = (SELECT DC.id_direccion_cliente FROM direcciones_clientes AS DC
                            WHERE DC.distrito_id = id_distrito_ AND DC.direccion = p_direccion);

        IF id_direccion_ IS NULL THEN
            INSERT INTO direcciones_clientes(distrito_id, direccion) VALUES (id_distrito_, p_direccion);
        END IF;

    COMMIT;

END $

DROP PROCEDURE IF EXISTS sp_registrarDireccionRetorno$
CREATE PROCEDURE sp_registrarDireccionRetorno(
    IN p_pais VARCHAR(255),
    IN p_region VARCHAR(255),
    IN p_provincia VARCHAR(255),
    IN p_distrito VARCHAR(255),
    IN p_direccion VARCHAR(255),
    OUT id_direccion_resultado BIGINT UNSIGNED
)
BEGIN

    DECLARE id_pais_, id_region_, id_provincia_, id_distrito_ BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
        BEGIN
            ROLLBACK;
            SET id_direccion_resultado = NULL;
            RESIGNAL;
        END;

    START TRANSACTION;
    SET id_pais_ = (SELECT P.id_pais FROM paises AS P WHERE P.pais = p_pais);

    IF id_pais_ IS NULL THEN
        INSERT INTO paises(pais) VALUES(p_pais);
        SET id_pais_ = LAST_INSERT_ID();
    END IF;

    SET id_region_ = (SELECT R.id_region FROM regiones AS R
                      WHERE R.pais_id = id_pais_ AND R.region = p_region);

    IF id_region_ IS NULL THEN
        INSERT INTO regiones(pais_id, region) VALUES (id_pais_, p_region);
        SET id_region_ = LAST_INSERT_ID();
    END IF;

    SET id_provincia_ = (SELECT PR.id_provincia FROM provincias AS PR
                         WHERE PR.region_id = id_region_ AND PR.provincia = p_provincia);

    IF id_provincia_ IS NULL THEN
        INSERT INTO provincias(region_id, provincia) VALUES (id_region_, p_provincia);
        SET id_provincia_ = LAST_INSERT_ID();
    END IF;

    SET id_distrito_ = (SELECT D.id_distrito FROM distritos AS D
                        WHERE D.provincia_id = id_provincia_ AND D.distrito = p_distrito);

    IF id_distrito_ IS NULL THEN
        INSERT INTO distritos(provincia_id, distrito) VALUES (id_provincia_, p_distrito);
        SET id_distrito_ = LAST_INSERT_ID();
    END IF;

    SET id_direccion_resultado = (SELECT DC.id_direccion_cliente FROM direcciones_clientes AS DC
                         WHERE DC.distrito_id = id_distrito_ AND DC.direccion = p_direccion);

    IF id_direccion_resultado IS NULL THEN
        INSERT INTO direcciones_clientes(distrito_id, direccion) VALUES (id_distrito_, p_direccion);
        SET id_direccion_resultado = LAST_INSERT_ID();
    END IF;

    COMMIT;

END $

DROP PROCEDURE IF EXISTS sp_registrarRecursoTextual$
CREATE PROCEDURE sp_registrarRecursoTextual(
    IN p_titulo VARCHAR(255),
    IN p_fecha_publicacion DATE,
    IN p_stock TINYINT UNSIGNED,
    IN p_numero_paginas SMALLINT UNSIGNED,
    IN p_edicion TINYINT UNSIGNED,
    IN p_volumen TINYINT UNSIGNED,
    IN p_codigo VARCHAR(50),
    IN p_tipo_texto_id BIGINT UNSIGNED,
    IN p_editorial_id BIGINT UNSIGNED,
    IN p_id_autor BIGINT UNSIGNED
)
BEGIN

    DECLARE id_recurso_textual_ BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
        BEGIN
            ROLLBACK;
            RESIGNAL;
        END;

    START TRANSACTION;

        INSERT IGNORE INTO recursos_textuales(titulo, fecha_publicacion, stock, numero_paginas, edicion, volumen, codigo,
                                       tipo_texto_id, editorial_id)
            VALUE (p_titulo, p_fecha_publicacion, p_stock,
                   p_numero_paginas, p_edicion, p_volumen,
                   p_codigo, p_tipo_texto_id, p_editorial_id);

        SET id_recurso_textual_ = (SELECT RT.id_recurso_textual
                                    FROM recursos_textuales AS RT
                                    WHERE RT.codigo = p_codigo);

        INSERT IGNORE INTO recursos_textuales_autores(recurso_textual_id, autor_id)
            VALUE (id_recurso_textual_, p_id_autor);

    COMMIT;

END $

DROP PROCEDURE IF EXISTS sp_registrarAutores$
CREATE PROCEDURE sp_registrarAutores (
    -- ELIMINAR ATRIBUTO SEUDONMIO, POSIBLEMENTE AGREGAR NACIONALIDAD, FECHA DE NACIMIENTO
)
BEGIN

END $

CREATE PROCEDURE sp_renovarCarnet (
    IN p_documento_cliente BIGINT
)
BEGIN
    DECLARE id_carnet_ BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
        BEGIN
            ROLLBACK;
            RESIGNAL;
        END;

    START TRANSACTION;

        SET id_carnet_ = (
            SELECT C.carnet_id FROM usuarios AS U
                INNER JOIN clientes AS C ON U.cliente_id = C.id_cliente
                GROUP BY U.documento = p_documento_cliente
            );

        IF id_carnet_ IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
                'No se consiguió el id del carnet a renovar.';
        END IF;

        -- SE DEDUCE QUE ID = 1 ES ACTIVO

        UPDATE carnets AS C SET tipo_estado_id = 1, fecha_emision = CURRENT_DATE,
                           fecha_vencimiento = DATE_ADD(CURRENT_DATE, INTERVAL 1 YEAR)
        WHERE C.id_carnet = id_carnet_ AND C.tipo_estado_id <> 1;

    COMMIT;
END $

DELIMITER ;
