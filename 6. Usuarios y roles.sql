\c db_biblioteca;

-- Crear usuario owner para a db_biblioteca;
CREATE USER bmpch_user WITH PASSWORD 'Jd99E5;)ZJ$5+%(+';
ALTER DATABASE "db_Biblioteca" OWNER TO bmpch_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public to bmpch_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public to bmpch_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public to bmpch_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO bmpch_user;

ALTER DATABASE "db_Biblioteca" OWNER TO "Biblioteca";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public to "Biblioteca";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public to "Biblioteca";
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public to "Biblioteca";
GRANT ALL PRIVILEGES ON SCHEMA public TO "Biblioteca";

CREATE ROLE cliente NOLOGIN;

CREATE ROLE encargado_biblioteca NOLOGIN;

CREATE USER usuario_cliente PASSWORD 'bmpchCliente_!';

GRANT cliente TO usuario_cliente;

CREATE USER usuario_encargado PASSWORD 'bmpchEncargado_#';

GRANT encargado_biblioteca TO usuario_encargado;

GRANT SELECT ON TABLE tb_autor TO cliente;
GRANT SELECT ON TABLE tb_carnet TO cliente;
GRANT SELECT ON TABLE tb_categoria TO cliente;
GRANT SELECT ON TABLE tb_categoria_recurso_textual TO cliente;
GRANT SELECT ON TABLE tb_editorial TO cliente;
GRANT SELECT ON TABLE tb_recurso_textual TO cliente;
GRANT SELECT ON TABLE tb_recurso_textual_autor TO cliente;
GRANT SELECT ON TABLE tb_recurso_textual_codigo TO cliente;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_autor TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_carnet TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_categoria TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_categoria_recurso_textual TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_cliente TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_direccion_cliente TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_distrito TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_editorial TO encargado_biblioteca;
GRANT SELECT ON TABLE tb_estado_prestamo TO encargado_biblioteca;
GRANT SELECT ON TABLE tb_genero TO encargado_biblioteca;
GRANT SELECT ON TABLE tb_nivel_educativo TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_pais TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_prestamo TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_provincia TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_recurso_textual TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_recurso_textual_codigo TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_recurso_textual_autor TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_region TO encargado_biblioteca;
GRANT SELECT, INSERT ON TABLE tb_registro_accion_usuario TO encargado_biblioteca;
GRANT SELECT ON TABLE tb_rol_usuario TO encargado_biblioteca;
GRANT SELECT ON TABLE tb_tipo_documento TO encargado_biblioteca;
GRANT SELECT ON TABLE tb_tipo_estado TO encargado_biblioteca;
GRANT SELECT ON TABLE tb_tipo_prestamo TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_tipo_texto TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE ON TABLE tb_usuario TO encargado_biblioteca;