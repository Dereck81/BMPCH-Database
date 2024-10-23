\c db_biblioteca;

-- Crear usuario owner para a db_biblioteca;
CREATE USER bmpch_user WITH PASSWORD 'Jd99E5;)ZJ$5+%(+';
ALTER DATABASE db_biblioteca OWNER TO bmpch_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public to bmpch_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public to bmpch_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public to bmpch_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO bmpch_user;


-- Crear el rol para el cliente
CREATE ROLE cliente NOLOGIN;

-- Crear el rol para el encargado de la biblioteca
CREATE ROLE encargado_biblioteca NOLOGIN;


-- Crear el usuario para el cliente
CREATE USER usuario_cliente PASSWORD 'bmpchCliente_!';

-- Asignar el rol de cliente al usuario_cliente
GRANT cliente TO usuario_cliente;


-- Crear el usuario para el encargado de la biblioteca
CREATE USER usuario_encargado PASSWORD 'bmpchEncargado_#';

-- Asignar el rol de encargado de biblioteca al usuario_encargado
GRANT encargado_biblioteca TO usuario_encargado;


-- Conceder permisos sobre las tablas necesarias
GRANT SELECT ON TABLE tb_autor TO cliente;
GRANT SELECT ON TABLE tb_categoria TO cliente;
GRANT SELECT ON TABLE tb_categoria_recurso_textual TO cliente;
GRANT SELECT ON TABLE tb_editorial TO cliente;
GRANT SELECT ON TABLE tb_recurso_textual TO cliente;
GRANT SELECT ON TABLE tb_recurso_textual_autor TO cliente;

-- Conceder permisos completos sobre las tablas relacionadas con la biblioteca
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_recurso_textual TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_recurso_textual_autor TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_recurso_textual_codigo TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_cliente TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_categoria_recurso_textual TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_categoria TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_editorial TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_carnet TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_usuario TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_recurso_textual TO encargado_biblioteca;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE tb_prestamo TO encargado_biblioteca;

-- Si existen otros procedimientos almacenados que el encargado de la biblioteca necesita ejecutar:
GRANT EXECUTE ON PROCEDURE sp_registrar_recurso_textual TO encargado_biblioteca;
GRANT EXECUTE ON PROCEDURE sp_modificar_direccion TO encargado_biblioteca;
GRANT EXECUTE ON PROCEDURE sp_realizar_prestamos TO encargado_biblioteca;
GRANT EXECUTE ON PROCEDURE sp_registrar_autor TO encargado_biblioteca;
GRANT EXECUTE ON PROCEDURE sp_registrar_clientes TO encargado_biblioteca;
GRANT EXECUTE ON PROCEDURE sp_registrar_codigo_recurso_textual TO encargado_biblioteca;
GRANT EXECUTE ON PROCEDURE sp_registrar_direccion TO encargado_biblioteca;
GRANT EXECUTE ON PROCEDURE sp_registrar_localizacion TO encargado_biblioteca;
GRANT EXECUTE ON PROCEDURE sp_registrar_recurso_textual TO encargado_biblioteca;
GRANT EXECUTE ON PROCEDURE sp_renovar_carnet TO encargado_biblioteca;
