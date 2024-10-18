-- Conectarse a la base de datos
\c bd_Biblioteca;

-- Insertar tipos de estados
INSERT INTO tb_tipo_estado (ties_tipo, ties_activo) VALUES
                                                        ('Activo', true),
                                                        ('Inactivo', false),
                                                        ('Suspendido', false);

-- Insertar tipos de textos
INSERT INTO tb_tipo_texto (tite_tipo) VALUES
                                          ('Libro'),
                                          ('Revista'),
                                          ('Periódico'),
                                          ('Tesis');

-- Insertar géneros
INSERT INTO tb_genero (gene_nombre) VALUES
                                        ('Masculino'),
                                        ('Femenino'),
                                        ('No binario');

-- Insertar niveles educativos
INSERT INTO tb_nivel_educativo (nied_nombre) VALUES
                                                 ('Primaria'),
                                                 ('Secundaria'),
                                                 ('Superior'),
                                                 ('Postgrado');

-- Insertar roles de usuario
INSERT INTO tb_rol_usuario (rolu_nombre) VALUES
                                             ('Administrador'),
                                             ('Cliente'),
                                             ('Bibliotecario');

-- Insertar tipos de documentos
INSERT INTO tb_tipo_documento (tido_tipo) VALUES
                                              ('DNI'),
                                              ('Pasaporte'),
                                              ('Carné de extranjería');

-- Insertar editoriales
INSERT INTO tb_editorial (edit_nombre) VALUES
                                           ('Editorial Planeta'),
                                           ('Penguin Random House'),
                                           ('Santillana'),
                                           ('Anagrama');

-- Insertar categorías
INSERT INTO tb_categoria (cate_nombre) VALUES
                                           ('Ficción'),
                                           ('No ficción'),
                                           ('Ciencia'),
                                           ('Historia'),
                                           ('Tecnología');

-- Insertar tipos de préstamos
INSERT INTO tb_tipo_prestamo (tipr_tipo) VALUES
                                             ('Préstamo en sala'),
                                             ('Préstamo a domicilio'),
                                             ('Préstamo interbibliotecario');

-- Insertar estados de préstamos
INSERT INTO tb_estado_prestamo (espr_nombre) VALUES
                                                 ('Activo'),
                                                 ('Devuelto'),
                                                 ('Vencido'),
                                                 ('Renovado');

-- Registrar autores
CALL sp_registrar_autor('Gabriel García Márquez', 'Gabriel', 'García', 'Márquez');
CALL sp_registrar_autor('Isabel Allende', 'Isabel', 'Allende', 'Llona');
CALL sp_registrar_autor('Mario Vargas Llosa', 'Mario', 'Vargas', 'Llosa');
CALL sp_registrar_autor('Julio Cortázar', 'Julio', 'Cortázar', '');

-- Registrar clientes
CALL sp_registrar_clientes('Juan'::VARCHAR, 'Pérez'::VARCHAR, 'García'::VARCHAR, 1::SMALLINT, '12345678'::VARCHAR, 1::SMALLINT, '987654321'::VARCHAR, 'juan.perez@example.com'::VARCHAR, 3::SMALLINT, 'password123'::VARCHAR, 'Perú'::VARCHAR, 'Lima'::VARCHAR, 'Lima'::VARCHAR, 'Miraflores'::VARCHAR, 'Av. Larco 400'::VARCHAR);
CALL sp_registrar_clientes('María'::VARCHAR, 'González'::VARCHAR, 'López'::VARCHAR, 2::SMALLINT, '87654321'::VARCHAR, 1::SMALLINT, '123456789'::VARCHAR, 'maria.gonzalez@example.com'::VARCHAR, 4::SMALLINT, 'password456'::VARCHAR, 'Perú'::VARCHAR, 'Lima'::VARCHAR, 'Lima'::VARCHAR, 'San Isidro'::VARCHAR, 'Calle Las Flores 200'::VARCHAR);
CALL sp_registrar_clientes('Carlos'::VARCHAR, 'Rodríguez'::VARCHAR, 'Martínez'::VARCHAR, 1::SMALLINT, '56789012'::VARCHAR, 1::SMALLINT, '234567890'::VARCHAR, 'carlos.rodriguez@example.com'::VARCHAR, 3::SMALLINT, 'password789'::VARCHAR, 'Perú'::VARCHAR, 'Lima'::VARCHAR, 'Lima'::VARCHAR, 'Surco'::VARCHAR, 'Av. Primavera 300'::VARCHAR);

-- Registrar recursos textuales
CALL sp_registrar_recurso_textual('Cien años de soledad'::VARCHAR, '1967-05-30'::DATE, 471::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB001'::VARCHAR, 1::BIGINT, 1::BIGINT, 1::BIGINT);
CALL sp_registrar_recurso_textual('La casa de los espíritus'::VARCHAR, '1982-01-01'::DATE, 442::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB002'::VARCHAR, 1::BIGINT, 2::BIGINT, 2::BIGINT);
CALL sp_registrar_recurso_textual('La ciudad y los perros'::VARCHAR, '1963-10-10'::DATE, 382::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB003'::VARCHAR, 1::BIGINT, 3::BIGINT, 3::BIGINT);
CALL sp_registrar_recurso_textual('Rayuela'::VARCHAR, '1963-06-28'::DATE, 635::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB004'::VARCHAR, 1::BIGINT, 4, 4::BIGINT);

-- Registrar códigos adicionales para recursos textuales
CALL sp_registrar_codigo_recurso_textual(1::BIGINT, 'LIB001-2');
CALL sp_registrar_codigo_recurso_textual(1::BIGINT, 'LIB001-3');
CALL sp_registrar_codigo_recurso_textual(2::BIGINT, 'LIB002-2');
CALL sp_registrar_codigo_recurso_textual(3::BIGINT, 'LIB003-2');

-- Realizar préstamos
CALL sp_realizar_prestamos(1::BIGINT, 1::BIGINT, 2::SMALLINT, CURRENT_DATE::DATE);
CALL sp_realizar_prestamos(2::BIGINT, 2::BIGINT, 1::SMALLINT, CURRENT_DATE::DATE);
CALL sp_realizar_prestamos(3::BIGINT, 3::BIGINT, 2::SMALLINT, CURRENT_DATE::DATE);

-- Renovar carnet
CALL sp_renovar_carnet('12345678');

-- Modificar dirección de un cliente
CALL sp_modificar_direccion(1, 'Perú', 'Lima', 'Lima', 'San Borja', 'Primavera');