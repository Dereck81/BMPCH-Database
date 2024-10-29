\c db_biblioteca;

CREATE OR REPLACE PROCEDURE sp_modificar_recurso_textual (
    p_recurso_textual_id BIGINT,
    p_titulo VARCHAR(255),
    p_fecha_publicacion DATE,
    p_numero_paginas SMALLINT,
    p_edicion SMALLINT,
    p_volumen SMALLINT,
    p_codigo_base VARCHAR(15),
    p_tipo_texto_id BIGINT,
    p_editorial_id BIGINT,
    p_stock BIGINT,
    p_activo BOOLEAN,
    p_ids_autor BIGINT[],
    p_ids_categorias BIGINT[]
)
    LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_stock BIGINT;
    v_codigo_base BIGINT;
BEGIN

    BEGIN

        IF p_stock >= 1 THEN
            RAISE EXCEPTION 'El stock no puede ser 0';
        END IF;

        v_codigo_base := (
            SELECT rete_codigo_base FROM tb_recurso_textual WHERE rete_id = p_recurso_textual_id
        );

        v_stock := (
            SELECT COUNT(reco_rete_codigo_base) FROM tb_recurso_textual_codigo WHERE reco_rete_codigo_base = v_codigo_base
        );

        UPDATE tb_recurso_textual
        SET rete_tipo_texto_id = p_tipo_texto_id, rete_editorial_id = p_editorial_id,
            rete_titulo = p_titulo, rete_codigo_base = p_codigo_base, rete_fec_publicacion = p_fecha_publicacion,
            rete_num_paginas = p_numero_paginas, rete_edicion = p_edicion, rete_volumen = p_volumen, rete_activo = p_activo
        WHERE rete_id = p_recurso_textual_id;

        IF v_id_recurso_textual IS NULL THEN
            RAISE EXCEPTION 'No se pudo registrar el recursos textual';
        END IF;

        DELETE FROM tb_recurso_textual_autor WHERE reau_recurso_textual_id = p_recurso_textual_id;

        FOR i IN 1..array_length(p_ids_autor, 1) LOOP
                INSERT INTO tb_recurso_textual_autor(reau_recurso_textual_id, reau_autor_id)
                VALUES (p_recurso_textual_id,p_ids_autor[i]);
        END LOOP;

        IF p_stock > v_stock THEN
            FOR i IN p_stock+1..v_stock LOOP
                    INSERT INTO tb_recurso_textual_codigo(reco_rete_codigo_base, reco_codigo_ejemplar, reco_disponible)
                    VALUES (p_codigo_base, i, TRUE);
                END LOOP;
        ELSE
            FOR i IN (p_stock+1)..v_stock LOOP
                BEGIN
                    DELETE FROM tb_recurso_textual_codigo WHERE reco_codigo_ejemplar = i;
                EXCEPTION
                    WHEN OTHERS THEN
                    -- REVISAR ESTA PARTE
                    UPDATE tb_recurso_textual_codigo SET reco_disponible = FALSE WHERE reco_codigo_ejemplar = i;
                END;
            END LOOP;
        END IF;

        DELETE FROM tb_categoria_recurso_textual WHERE care_recurso_textual_id = p_recurso_textual_id;

        FOR i IN 1..array_length(p_ids_categorias, 1) LOOP
                INSERT INTO tb_categoria_recurso_textual(care_recurso_textual_id, care_categoria_id)
                VALUES (p_recurso_textual_id, p_ids_categorias[i]);
        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Falló al registrar el recurso textual: %s', SQLERRM;
            RAISE;

    END;
END;
$$;