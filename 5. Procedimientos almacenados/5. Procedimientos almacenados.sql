\c bd_Biblioteca;

/*
 * PROCEDURE: sp_realizar_prestamos
 *
 * DESCRIPCIÓN:
 * Registra un nuevo préstamo en 'tb_prestamo' y actualiza el recurso textual como no disponible.
 *
 * PARÁMETROS:
 *   @p_usuario_id BIGINT: ID del usuario que realiza el préstamo.
 *   @p_recurso_textual_codigo_id BIGINT: ID del recurso que se presta.
 *   @p_tipo_prestamo_id SMALLINT: ID del tipo de préstamo.
 *   @p_fec_programada DATE: Fecha programada para el préstamo.
 *
 * EXCEPCIONES:
 *   Si ocurre un error, se realiza un ROLLBACK y se notifica el error.
 *
 * NOTA IMPORTANTE:
 *  - Se supone que el id 1 de 'pres_estado_prestamo_id' tiene que ser un estado
 *    como 'Activo' o algo similar.
 *  - Al llamar al procedimiento almacenado, tiene que usarse de la siguiente manera:
 *    CALL sp_realizar_prestamos(1::BIGINT, 1::BIGINT, 1::SMALLINT, '2024-10-10'::DATE);
 *    este es un ejemplo de como se debe de llamar el procedimiento almacenado.
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
 * PROCEDURE: sp_registrar_localizacion
 *
 * DESCRIPCIÓN:
 * Registra la localización de un país, región, provincia y distrito en las tablas correspondientes.
 * Si alguna de las entidades no existe, se creará un nuevo registro.
 *
 * PARÁMETROS:
 *   @p_pais VARCHAR(255): Nombre del país a registrar o buscar.
 *   @p_region VARCHAR(255): Nombre de la región a registrar o buscar.
 *   @p_provincia VARCHAR(255): Nombre de la provincia a registrar o buscar.
 *   @p_distrito VARCHAR(255): Nombre del distrito a registrar o buscar.
 *   @p_id_distrito BIGINT OUT: ID del distrito registrado o encontrado.
 *
 * EXCEPCIONES:
 *   Si ocurre un error, se realiza un ROLLBACK y se asigna NULL al parámetro de salida
 *   @p_id_distrito. Se genera un mensaje de aviso que notifica el error.
 *
 */
CREATE OR REPLACE PROCEDURE sp_registrar_localizacion (
    p_pais VARCHAR(255),
    p_region VARCHAR(255),
    p_provincia VARCHAR(255),
    p_distrito VARCHAR(255),
    OUT p_id_distrito BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_id_pais_ SMALLINT;
    v_id_region_ BIGINT;
    v_id_provincia_ BIGINT;
    v_id_distrito_ BIGINT;
BEGIN

    BEGIN

        START TRANSACTION;

        v_id_pais_ := (SELECT P.pais_id FROM tb_pais AS P WHERE P.pais_nombre = p_pais);

        IF v_id_pais_ IS NULL THEN
            INSERT INTO tb_pais(pais_nombre) VALUES(p_pais)
            RETURNING pais_id INTO v_id_pais_;
        END IF;

        v_id_region_ := (SELECT R.regi_id FROM tb_region AS R
                         WHERE R.regi_id = v_id_pais_ AND R.regi_nombre = p_region);

        IF v_id_region_ IS NULL THEN
            INSERT INTO tb_region(regi_pais_id, regi_nombre) VALUES (v_id_pais_, p_region)
            RETURNING regi_id INTO v_id_region_;
        END IF;

        v_id_provincia_ := (SELECT PR.prov_id FROM tb_provincia AS PR
                            WHERE PR.prov_region_id = v_id_region_ AND PR.prov_nombre = p_provincia);

        IF v_id_provincia_ IS NULL THEN
            INSERT INTO tb_provincia(prov_region_id, prov_nombre) VALUES (v_id_region_, p_provincia)
            RETURNING prov_id INTO v_id_provincia_;
        END IF;

        v_id_distrito_ := (SELECT D.dist_id FROM tb_distrito AS D
                           WHERE D.dist_id = v_id_provincia_ AND D.dist_nombre = p_distrito);

        IF v_id_distrito_ IS NULL THEN
            INSERT INTO tb_distrito(dist_provincia_id, dist_nombre) VALUES (v_id_provincia_, p_distrito)
            RETURNING dist_id INTO p_id_distrito;
        ELSE
            p_id_distrito := v_id_distrito_;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE NOTICE 'Falló al registrar la direccion: %s', SQLERRM;
            RAISE;
    END;
END;
$$;

/*
 * PROCEDURE: sp_registrar_direccion
 *
 * DESCRIPCIÓN:
 * Registra una nueva dirección asociada a un distrito específico.
 * Si la dirección ya existe en la base de datos, simplemente se devuelve su ID.
 * Este procedimiento también invoca al procedimiento 'sp_registrar_localizacion'
 * para asegurar que la localización esté registrada.
 *
 * PARÁMETROS:
 *   @p_pais VARCHAR(255): Nombre del país donde se registra la dirección.
 *   @p_region VARCHAR(255): Nombre de la región donde se registra la dirección.
 *   @p_provincia VARCHAR(255): Nombre de la provincia donde se registra la dirección.
 *   @p_distrito VARCHAR(255): Nombre del distrito donde se registra la dirección.
 *   @p_direccion VARCHAR(255): La dirección específica a registrar.
 *   @p_id_direccion BIGINT OUT: ID de la dirección registrada o encontrada.
 *
 * EXCEPCIONES:
 *   Si ocurre un error durante el proceso, se realiza un ROLLBACK, se asigna NULL al
 *   parámetro de salida @p_id_direccion y se genera un mensaje de aviso que notifica el error.
 *
 */
CREATE OR REPLACE PROCEDURE sp_registrar_direccion (
    p_pais VARCHAR(255),
    p_region VARCHAR(255),
    p_provincia VARCHAR(255),
    p_distrito VARCHAR(255),
    p_direccion VARCHAR(255),
    OUT p_id_direccion BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_id_distrito_ BIGINT;
    v_id_direccion_ BIGINT;
BEGIN

    BEGIN

        START TRANSACTION;

        CALL sp_registrar_localizacion(p_pais, p_region, p_provincia, p_distrito, v_id_distrito_);

        IF v_id_distrito_ IS NULL THEN
            RAISE EXCEPTION 'ID de distrito null';
        END IF;

        v_id_direccion_ := (SELECT DC.dicl_id FROM tb_direccion_cliente AS DC
                            WHERE DC.dicl_distrito_id = v_id_distrito_ AND DC.dicl_direccion = p_direccion);

        IF v_id_direccion_ IS NULL THEN
            INSERT INTO tb_direccion_cliente(dicl_distrito_id, dicl_direccion) VALUES (v_id_distrito_, p_direccion)
            RETURNING dicl_id INTO p_id_direccion;
        ELSE
            p_id_direccion := v_id_direccion_;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE NOTICE 'Falló al registrar la direccion: %s', SQLERRM;
            RAISE;
    END;
END;
$$;

/*
 * PROCEDURE: sp_modificar_direccion
 *
 * DESCRIPCIÓN:
 * Modifica la dirección de un cliente asociado a un usuario específico.
 * Si la dirección del cliente está siendo usada por otro cliente,
 * entonces se crea una nueva dirección y se le asigna a ese cliente
 * En caso contrario, se modifica la dirección existente.
 *
 * PARÁMETROS:
 *   @p_id_usuario BIGINT: ID del usuario cuya dirección se desea modificar.
 *   @p_pais VARCHAR(255): Nombre del país donde se encuentra la nueva dirección.
 *   @p_region VARCHAR(255): Nombre de la región donde se encuentra la nueva dirección.
 *   @p_provincia VARCHAR(255): Nombre de la provincia donde se encuentra la nueva dirección.
 *   @p_distrito VARCHAR(255): Nombre del distrito donde se encuentra la nueva dirección.
 *   @p_direccion VARCHAR(255): La nueva dirección que se desea registrar o modificar.
 *
 * EXCEPCIONES:
 *   Si ocurre un error durante el proceso, se realiza un ROLLBACK y se genera un mensaje
 *   de aviso que notifica el error.
 *
 * NOTA IMPORTANTE:
 *  - Al llamar al procedimiento almacenado, debe usarse de la siguiente manera:
 *    CALL sp_modificar_direccion(1::BIGINT, 'Perú', 'Lima', 'Lima', 'Miraflores', 'Av. José Larco 123');
 *    Este es un ejemplo de cómo se debe llamar el procedimiento almacenado.
 */
CREATE OR REPLACE PROCEDURE sp_modificar_direccion (
    p_id_usuario BIGINT,
    p_pais VARCHAR(255),
    p_region VARCHAR(255),
    p_provincia VARCHAR(255),
    p_distrito VARCHAR(255),
    p_direccion VARCHAR(255)
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_id_direccion BIGINT;
    v_id_distrito BIGINT;
    v_cant_direccion_cliente BIGINT;
BEGIN

    BEGIN

        START TRANSACTION;

        v_id_direccion := (
            SELECT DC.dicl_id FROM tb_usuario AS U
                                       INNER JOIN tb_cliente AS CL ON U.usua_id = CL.clie_usuario_id
                                       INNER JOIN tb_direccion_cliente AS DC ON DC.dicl_id = CL.clie_direccion_id
            WHERE U.usua_id = p_id_usuario
        );

        v_cant_direccion_cliente := (
            SELECT COUNT(clie_direccion_id) FROM tb_cliente WHERE clie_direccion_id = v_id_direccion
        );

        IF v_cant_direccion_cliente >= 2 THEN
            CALL sp_registrar_direccion(p_pais, p_region, p_provincia, p_distrito, p_direccion, v_id_direccion);

            UPDATE tb_cliente SET clie_direccion_id = v_id_direccion
            FROM tb_usuario WHERE tb_cliente.clie_usuario_id = tb_usuario.usua_id
            AND tb_usuario.usua_id = p_id_usuario;

            RETURN;
        END IF;

        CALL sp_registrar_localizacion(p_pais, p_region, p_provincia, p_distrito, v_id_distrito);

        IF v_id_distrito IS NULL THEN
            RAISE EXCEPTION 'ID de distrito nulo.';
        END IF;

        UPDATE tb_direccion_cliente SET dicl_distrito_id = v_id_distrito, dicl_direccion = p_direccion
        WHERE dicl_id = v_id_direccion;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE NOTICE 'Falló al modificar la dirección del cliente: %s', SQLERRM;
            RAISE;

    END;
END;
$$;

/*
 * PROCEDURE: sp_registrar_clientes
 *
 * DESCRIPCIÓN:
 * Registra un nuevo cliente en la base de datos junto con su dirección y su carnet.
 * También se registra al cliente en la tabla de usuarios.
 * Se debe considerar la encriptación del documento del cliente antes de almacenarlo.
 *
 * PARÁMETROS:
 *   @p_nombre VARCHAR(255): Nombre del cliente.
 *   @p_apellido_paterno VARCHAR(255): Apellido paterno del cliente.
 *   @p_apellido_materno VARCHAR(255): Apellido materno del cliente.
 *   @p_genero_id SMALLINT: ID del género del cliente.
 *   @p_documento VARCHAR(20): Documento de identificación del cliente (debe ser encriptado).
 *   @p_tipo_documento_id SMALLINT: ID del tipo de documento del cliente.
 *   @p_telefono CHAR(9): Número de teléfono del cliente.
 *   @p_correo VARCHAR(255): Correo electrónico del cliente.
 *   @p_nivel_educativo_id SMALLINT: ID del nivel educativo del cliente.
 *   @p_pais VARCHAR(255): Nombre del país donde vive el cliente.
 *   @p_region VARCHAR(255): Nombre de la región donde vive el cliente.
 *   @p_provincia VARCHAR(255): Nombre de la provincia donde vive el cliente.
 *   @p_distrito VARCHAR(255): Nombre del distrito donde vive el cliente.
 *   @p_direccion VARCHAR(255): Dirección específica del cliente.
 *
 * EXCEPCIONES:
 *   Si ocurre un error durante el proceso, se realiza un ROLLBACK y se genera un mensaje
 *   de aviso que notifica el error.
 *
 * NOTA IMPORTANTE:
 *  - Antes de llamar a este procedimiento, se debe implementar una función para encriptar
 *    el documento del cliente, que será utilizada antes de insertarlo en la tabla tb_usuario.
 *  - Al llamar al procedimiento almacenado, debe usarse de la siguiente manera:
 *    CALL sp_registrar_clientes('Juan', 'Pérez', 'García', 1, '12345678', 1,
 *                                 '987654321', 'juan.perez@example.com', 1,
 *                                 'Perú', 'Lima', 'Lima', 'Miraflores',
 *                                 'Av. José Larco 123');
 *  - Se supone que el rol de cliente es de id = 2
 */
CREATE OR REPLACE PROCEDURE sp_registrar_clientes (
    p_nombre VARCHAR(255),
    p_apellido_paterno VARCHAR(255),
    p_apellido_materno VARCHAR(255),
    p_genero_id SMALLINT,
    p_documento VARCHAR(20),
    p_tipo_documento_id SMALLINT,
    p_telefono CHAR(9),
    p_correo VARCHAR(255),
    p_nivel_educativo_id SMALLINT,
    p_psk VARCHAR(255),
    p_pais VARCHAR(255),
    p_region VARCHAR(255),
    p_provincia VARCHAR(255),
    p_distrito VARCHAR(255),
    p_direccion VARCHAR(255)
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_id_carnet BIGINT;
    v_id_direccion BIGINT;
    v_id_usuario BIGINT;
BEGIN

    BEGIN

        START TRANSACTION;

        CALL sp_registrar_direccion(p_pais, p_region, p_provincia, p_distrito, p_direccion, v_id_direccion);

        IF v_id_direccion IS NULL THEN
            RAISE EXCEPTION 'No se logró registrar la direccion: %s', SQLERRM;
        END IF;

        INSERT INTO tb_usuario(usua_rol_usuario_id, usua_documento, usua_tipo_documento_id, usua_psk)
        VALUES (2, p_documento,
                p_tipo_documento_id, p_psk)
        RETURNING usua_id INTO v_id_usuario;

        INSERT INTO tb_carnet(carn_tipo_estado_id, carn_codigo, carn_fec_emision, carn_fec_vencimiento)
        VALUES (1, CONCAT('BMPCH','-',v_id_usuario), DEFAULT, DEFAULT)
        RETURNING carn_id INTO v_id_carnet;

        INSERT INTO tb_cliente(clie_nombre, clie_usuario_id, clie_apellido_paterno, clie_apellido_materno,
                               clie_genero_id, clie_direccion_id, clie_telefono, clie_correo,
                               clie_carnet_id, clie_nivel_educativo_id)
        VALUES (p_nombre, v_id_usuario,p_apellido_paterno, p_apellido_materno,
                p_genero_id, v_id_direccion, p_telefono,
                p_correo, v_id_carnet, p_nivel_educativo_id);

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE NOTICE 'Falló al registrar a un cliente: %s', SQLERRM;
            RAISE;

    END;

END;
$$;

/*
 * PROCEDURE: sp_registrar_autor
 *
 * DESCRIPCIÓN:
 * Registra un nuevo autor en la base de datos.
 * Este procedimiento inserta los datos del autor en la tabla 'tb_autor'.
 *
 * PARÁMETROS:
 *   @p_seudonimo VARCHAR(255): Seudónimo del autor.
 *   @p_nombre VARCHAR(255): Nombre del autor.
 *   @p_apellido_paterno VARCHAR(255): Apellido paterno del autor.
 *   @p_apellido_materno VARCHAR(255): Apellido materno del autor.
 *
 * EXCEPCIONES:
 *   Si ocurre un error durante el proceso de inserción, se realiza un ROLLBACK y
 *   se genera un mensaje de aviso que notifica el error.
 *
 */
CREATE OR REPLACE PROCEDURE sp_registrar_autor(
    p_seudonimo VARCHAR(255),
    p_nombre VARCHAR(255),
    p_apellido_paterno VARCHAR(255),
    p_apellido_materno VARCHAR(255)
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN

    BEGIN

        INSERT INTO tb_autor(auto_seudonimo, auto_nombre, auto_apellido_paterno, auto_apellido_materno)
        VALUES(p_seudonimo, p_nombre, p_apellido_paterno,
               p_apellido_materno);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Falló al crear el autor: %s', SQLERRM;
            RAISE;

    END;

END;


$$;

/*
 * PROCEDURE: sp_registrar_recurso_textual
 *
 * DESCRIPCIÓN:
 * Registra un nuevo recurso textual en la base de datos junto con su autor y su código.
 * Este procedimiento inserta los datos en las tablas 'tb_recurso_textual',
 * 'tb_recurso_textual_autor' y 'tb_recurso_textual_codigo'.
 *
 * PARÁMETROS:
 *   @p_titulo VARCHAR(255): Título del recurso textual.
 *   @p_fecha_publicacion DATE: Fecha de publicación del recurso.
 *   @p_numero_paginas SMALLINT: Número de páginas del recurso textual.
 *   @p_edicion SMALLINT: Edición del recurso textual.
 *   @p_volumen SMALLINT: Volumen del recurso textual.
 *   @p_codigo VARCHAR(255): Código del recurso textual.
 *   @p_tipo_texto_id BIGINT: ID del tipo de texto.
 *   @p_editorial_id BIGINT: ID de la editorial del recurso.
 *   @p_id_autor BIGINT: ID del autor del recurso textual.
 *
 * EXCEPCIONES:
 *   Si ocurre un error durante el proceso de inserción, se realiza un ROLLBACK y
 *   se genera un mensaje de aviso que notifica el error.
 *
 */
CREATE OR REPLACE PROCEDURE sp_registrar_recurso_textual (
    p_titulo VARCHAR(255),
    p_fecha_publicacion DATE,
    p_numero_paginas SMALLINT,
    p_edicion SMALLINT,
    p_volumen SMALLINT,
    p_codigo VARCHAR(255),
    p_tipo_texto_id BIGINT,
    p_editorial_id BIGINT,
    p_id_autor BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_id_recurso_textual BIGINT;
BEGIN

    BEGIN

        INSERT INTO tb_recurso_textual(rete_tipo_texto_id, rete_editorial_id,
                                       rete_titulo, rete_fec_publicacion, rete_num_paginas,
                                       rete_edicion, rete_volumen)
        VALUES (p_tipo_texto_id, p_editorial_id, p_titulo, p_fecha_publicacion,
                p_numero_paginas, p_edicion, p_volumen)
        RETURNING rete_id INTO v_id_recurso_textual;

        IF v_id_recurso_textual IS NULL THEN
            RAISE EXCEPTION 'No se pudo registrar el recursos textual: %s', SQLERRM;
        END IF;

        INSERT INTO tb_recurso_textual_autor(reau_recurso_textual_id, reau_autor_id)
        VALUES (v_id_recurso_textual, p_id_autor);

        INSERT INTO tb_recurso_textual_codigo(reco_recurso_textual_id, reco_codigo, reco_disponible)
        VALUES (v_id_recurso_textual, p_codigo, TRUE);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Falló al registrar el recurso textual: %s', SQLERRM;
            RAISE;

    END;
END;
$$;

/*
 * PROCEDURE: sp_registrar_codigo_recurso_textual
 *
 * DESCRIPCIÓN:
 * Registra un código para un recurso textual existente en la base de datos.
 * Este procedimiento inserta el código en la tabla 'tb_recurso_textual_codigo'
 * asociándolo con un recurso textual ya existente.
 *
 * PARÁMETROS:
 *   @p_id_recurso_textual BIGINT: ID del recurso textual existente.
 *   @p_codigo VARCHAR(255): Código que se asignará al recurso textual.
 *
 * EXCEPCIONES:
 *   Si ocurre un error durante el proceso de inserción, se realiza un ROLLBACK y
 *   se genera un mensaje de aviso que notifica el error.
 *
 */
CREATE OR REPLACE PROCEDURE sp_registrar_codigo_recurso_textual(
    p_id_recurso_textual BIGINT,
    p_codigo VARCHAR(255)
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
   BEGIN

        INSERT INTO tb_recurso_textual_codigo(reco_recurso_textual_id, reco_codigo, reco_disponible)
        VALUES(p_id_recurso_textual, p_codigo, TRUE);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Falló al registrar un recurso textual existente: %s', SQLERRM;
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
BEGIN

    BEGIN

        v_id_carnet := (SELECT C.clie_carnet_id FROM tb_usuario AS U
                        INNER JOIN tb_cliente AS C ON U.usua_id = C.clie_usuario_id
                        WHERE U.usua_documento = p_documento);

        IF v_id_carnet IS NULL THEN
            RAISE EXCEPTION 'No se pudo obtener el id del carnet: %s', SQLERRM;
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


