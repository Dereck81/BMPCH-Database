\c db_biblioteca;

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
 *   Si ocurre un error, se asigna NULL al parámetro de salida @p_id_distrito y se genera un mensaje de aviso
 *   que notifica el error. Además, se realiza un ROLLBACK.
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
                        WHERE D.dist_provincia_id = v_id_provincia_ AND D.dist_nombre = p_distrito);

        IF v_id_distrito_ IS NULL THEN
            INSERT INTO tb_distrito(dist_provincia_id, dist_nombre) VALUES (v_id_provincia_, p_distrito)
            RETURNING dist_id INTO p_id_distrito;
        ELSE
            p_id_distrito := v_id_distrito_;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
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

        CALL sp_registrar_localizacion(p_pais, p_region, p_provincia, p_distrito, v_id_distrito_);

        IF v_id_distrito_ IS NULL THEN
            RAISE EXCEPTION 'ID de distrito null';
        END IF;

        INSERT INTO tb_direccion_cliente(dicl_distrito_id, dicl_direccion) VALUES (v_id_distrito_, p_direccion)
        RETURNING dicl_id INTO p_id_direccion;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Falló al registrar la direccion: %s', SQLERRM;
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
 *                                 'Av. José Larco 123', 'mi_psk_secreta');
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

        CALL sp_registrar_direccion(p_pais, p_region, p_provincia, p_distrito, p_direccion, v_id_direccion);

        IF v_id_direccion IS NULL THEN
                    RAISE EXCEPTION 'No se logró registrar la direccion: id direccion nulo';
        END IF;

        INSERT INTO tb_usuario(usua_rol_usuario_id, usua_documento, usua_tipo_documento_id, usua_psk, usua_activo)
        VALUES (2, p_documento,
                p_tipo_documento_id, p_psk, DEFAULT)
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

    EXCEPTION
        WHEN OTHERS THEN
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
    p_nombre VARCHAR(255),
    p_apellido_paterno VARCHAR(255),
    p_apellido_materno VARCHAR(255)
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN

    BEGIN

        INSERT INTO tb_autor(auto_nombre, auto_apellido_paterno, auto_apellido_materno)
        VALUES(p_nombre, p_apellido_paterno,
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
 * 'tb_recurso_textual_autor', 'tb_recurso_textual_codigo' y
 * 'tb_categoria_recurso_textual'.
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
 *   @p_stock: Stock del recurso textual
 *   @p_ids_autor BIGINT[]: Arreglo de IDs de autores asociados al recurso textual.
 *   @p_ids_categorias BIGINT[]: Arreglo de IDs de categorías asociadas al recurso.
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
    p_codigo_base VARCHAR(15),
    p_tipo_texto_id BIGINT,
    p_editorial_id BIGINT,
    p_stock BIGINT,
    p_ids_autor BIGINT[],
    p_ids_categorias BIGINT[]
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_id_recurso_textual BIGINT;
BEGIN

    BEGIN

        IF p_stock >= 1 THEN
            RAISE EXCEPTION 'El stock no puede ser 0';
        END IF;

        INSERT INTO tb_recurso_textual(rete_tipo_texto_id, rete_editorial_id,
                                       rete_titulo, rete_codigo_base, rete_fec_publicacion, rete_num_paginas,
                                       rete_edicion, rete_volumen, rete_activo)
        VALUES (p_tipo_texto_id, p_editorial_id, p_titulo, p_codigo_base, p_fecha_publicacion,
                p_numero_paginas, p_edicion, p_volumen, DEFAULT)
        RETURNING rete_id INTO v_id_recurso_textual;

        IF v_id_recurso_textual IS NULL THEN
                    RAISE EXCEPTION 'No se pudo registrar el recursos textual';
        END IF;

        FOR i IN 1..array_length(p_ids_autor, 1) LOOP
            INSERT INTO tb_recurso_textual_autor(reau_recurso_textual_id, reau_autor_id)
            VALUES (v_id_recurso_textual,p_ids_autor[i]);
        END LOOP;

        FOR i IN 1..p_stock LOOP
            INSERT INTO tb_recurso_textual_codigo(reco_rete_codigo_base, reco_codigo_ejemplar, reco_disponible)
            VALUES (p_codigo_base, i, TRUE);
        END LOOP;

        FOR i IN 1..array_length(p_ids_categorias, 1) LOOP
            INSERT INTO tb_categoria_recurso_textual(care_recurso_textual_id, care_categoria_id)
            VALUES (v_id_recurso_textual, p_ids_categorias[i]);
        END LOOP;

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
    p_id_recurso_textual BIGINT
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