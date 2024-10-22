-- Conectarse a la base de datos
\c db_biblioteca;

-- Insertar tipos de estados
INSERT INTO tb_tipo_estado (ties_tipo, ties_activo) VALUES
                                                        ('Activo', true),
                                                        ('Vencido', false),
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
CALL sp_registrar_autor('Gabriel García Márquez', 'Gabriel', 'García', 'Márquez'); -- Ya existe
CALL sp_registrar_autor('Isabel Allende', 'Isabel', 'Allende', 'Llona'); -- Ya existe
CALL sp_registrar_autor('Mario Vargas Llosa', 'Mario', 'Vargas', 'Llosa'); -- Ya existe
CALL sp_registrar_autor('Julio Cortázar', 'Julio', 'Cortázar', ''); -- Ya existe
CALL sp_registrar_autor('J.K. Rowling', 'Joanne', 'Rowling', '');
CALL sp_registrar_autor('George Orwell', 'Eric', 'Blair', 'Orwell');
CALL sp_registrar_autor('Margaret Atwood', 'Margaret', 'Atwood', '');
CALL sp_registrar_autor('Friedrich Nietzsche', 'Friedrich', 'Nietzsche', '');
CALL sp_registrar_autor('Franz Kafka', 'Franz', 'Kafka', '');
CALL sp_registrar_autor('Haruki Murakami', 'Haruki', 'Murakami', '');

-- Registrar clientes
CALL sp_registrar_clientes('Juan'::VARCHAR, 'Pérez'::VARCHAR, 'García'::VARCHAR, 1::SMALLINT, '12345678'::VARCHAR, 1::SMALLINT, '987654321'::VARCHAR, 'juan.perez@example.com'::VARCHAR, 3::SMALLINT, 'password123'::VARCHAR, 'Perú'::VARCHAR, 'Lima'::VARCHAR, 'Lima'::VARCHAR, 'Miraflores'::VARCHAR, 'Av. Larco 400'::VARCHAR); -- Ya existe
CALL sp_registrar_clientes('María'::VARCHAR, 'González'::VARCHAR, 'López'::VARCHAR, 2::SMALLINT, '87654321'::VARCHAR, 1::SMALLINT, '123456789'::VARCHAR, 'maria.gonzalez@example.com'::VARCHAR, 4::SMALLINT, 'password456'::VARCHAR, 'Perú'::VARCHAR, 'Lima'::VARCHAR, 'Lima'::VARCHAR, 'San Isidro'::VARCHAR, 'Calle Las Flores 200'::VARCHAR); -- Ya existe
CALL sp_registrar_clientes('Carlos'::VARCHAR, 'Rodríguez'::VARCHAR, 'Martínez'::VARCHAR, 1::SMALLINT, '56789012'::VARCHAR, 1::SMALLINT, '234567890'::VARCHAR, 'carlos.rodriguez@example.com'::VARCHAR, 3::SMALLINT, 'password789'::VARCHAR, 'Perú'::VARCHAR, 'Lima'::VARCHAR, 'Lima'::VARCHAR, 'Surco'::VARCHAR, 'Av. Primavera 300'::VARCHAR); -- Ya existe
CALL sp_registrar_clientes('Ana'::VARCHAR, 'Torres'::VARCHAR, 'Sánchez'::VARCHAR, 1::SMALLINT, '11223344'::VARCHAR, 1::SMALLINT, '345678912'::VARCHAR, 'ana.torres@example.com'::VARCHAR, 2::SMALLINT, 'passwordAna123'::VARCHAR, 'Perú'::VARCHAR, 'Lima'::VARCHAR, 'Lima'::VARCHAR, 'Miraflores'::VARCHAR, 'Av. Pardo 500'::VARCHAR);
CALL sp_registrar_clientes('Pedro'::VARCHAR, 'Gómez'::VARCHAR, 'Martínez'::VARCHAR, 2::SMALLINT, '99887766'::VARCHAR, 1::SMALLINT, '654321789'::VARCHAR, 'pedro.gomez@example.com'::VARCHAR, 1::SMALLINT, 'passwordPedro456'::VARCHAR, 'Perú'::VARCHAR, 'Lima'::VARCHAR, 'Lima'::VARCHAR, 'San Isidro'::VARCHAR, 'Av. Javier Prado 700'::VARCHAR);
CALL sp_registrar_clientes('Laura'::VARCHAR, 'Martínez'::VARCHAR, 'López'::VARCHAR, 1::SMALLINT, '22334455'::VARCHAR, 1::SMALLINT, '987654320'::VARCHAR, 'laura.martinez@example.com'::VARCHAR, 3::SMALLINT, 'passwordLaura789'::VARCHAR, 'Perú'::VARCHAR, 'Lima'::VARCHAR, 'Lima'::VARCHAR, 'Surco'::VARCHAR, 'Calle La Encalada 300'::VARCHAR);
CALL sp_registrar_clientes('Ricardo'::VARCHAR, 'Salazar'::VARCHAR, 'Hernández'::VARCHAR, 2::SMALLINT, '44556677'::VARCHAR, 1::SMALLINT, '987604321'::VARCHAR, 'ricardo.salazar@example.com'::VARCHAR, 4::SMALLINT, 'passwordRicardo101'::VARCHAR, 'Perú'::VARCHAR, 'Lima'::VARCHAR, 'Lima'::VARCHAR, 'La Molina'::VARCHAR, 'Calle Las Flores 500'::VARCHAR);
CALL sp_registrar_clientes('Esteban'::VARCHAR, 'Cruz'::VARCHAR, 'Valenzuela'::VARCHAR, 1::SMALLINT, '55667788'::VARCHAR, 1::SMALLINT, '123450089'::VARCHAR, 'esteban.cruz@example.com'::VARCHAR, 3::SMALLINT, 'passwordEsteban102'::VARCHAR, 'Perú'::VARCHAR, 'Lima'::VARCHAR, 'Lima'::VARCHAR, 'Miraflores'::VARCHAR, 'Av. José Larco 700'::VARCHAR);

-- Registrar recursos textuales
CALL sp_registrar_recurso_textual('El Alquimista'::VARCHAR, '1988-05-01'::DATE, 208::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB005'::VARCHAR, 2::BIGINT, 1::BIGINT, 1::BIGINT);
CALL sp_registrar_recurso_textual('1984'::VARCHAR, '1949-06-08'::DATE, 328::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB006'::VARCHAR, 2::BIGINT, 2::BIGINT, 1::BIGINT);
CALL sp_registrar_recurso_textual('Cien años de soledad'::VARCHAR, '1967-05-30'::DATE, 471::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB007'::VARCHAR, 1::BIGINT, 1::BIGINT, 1::BIGINT);
CALL sp_registrar_recurso_textual('Crónica de una muerte anunciada'::VARCHAR, '1981-01-01'::DATE, 120::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB008'::VARCHAR, 1::BIGINT, 2::BIGINT, 2::BIGINT);
CALL sp_registrar_recurso_textual('Los ojos del perro siberiano'::VARCHAR, '1995-05-01'::DATE, 134::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB009'::VARCHAR, 2::BIGINT, 3::BIGINT, 3::BIGINT);
CALL sp_registrar_recurso_textual('El túnel'::VARCHAR, '1948-01-01'::DATE, 280::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB010'::VARCHAR, 2::BIGINT, 4::BIGINT, 4::BIGINT);
CALL sp_registrar_recurso_textual('El amor en los tiempos del cólera'::VARCHAR, '1985-03-25'::DATE, 368::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB011'::VARCHAR, 2::BIGINT, 1::BIGINT, 1::BIGINT);
CALL sp_registrar_recurso_textual('La sombra del viento'::VARCHAR, '2001-04-17'::DATE, 576::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB012'::VARCHAR, 2::BIGINT, 2::BIGINT, 2::BIGINT);
CALL sp_registrar_recurso_textual('Siete años en el Tíbet'::VARCHAR, '1997-10-01'::DATE, 256::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB013'::VARCHAR, 2::BIGINT, 3::BIGINT, 3::BIGINT);
CALL sp_registrar_recurso_textual('Moby Dick'::VARCHAR, '1851-10-18'::DATE, 635::SMALLINT, 1::SMALLINT, 1::SMALLINT, 'LIB014'::VARCHAR, 2::BIGINT, 1::BIGINT, 1::BIGINT);

-- Registrar códigos adicionales para recursos textuales
CALL sp_registrar_codigo_recurso_textual(1::BIGINT, 'LIB001-2');
CALL sp_registrar_codigo_recurso_textual(1::BIGINT, 'LIB001-3');
CALL sp_registrar_codigo_recurso_textual(2::BIGINT, 'LIB002-2');
CALL sp_registrar_codigo_recurso_textual(3::BIGINT, 'LIB003-2');
CALL sp_registrar_codigo_recurso_textual(4::BIGINT, 'LIB004-2');
CALL sp_registrar_codigo_recurso_textual(5::BIGINT, 'LIB005-2');
CALL sp_registrar_codigo_recurso_textual(6::BIGINT, 'LIB006-2');
CALL sp_registrar_codigo_recurso_textual(7::BIGINT, 'LIB007-2');
CALL sp_registrar_codigo_recurso_textual(8::BIGINT, 'LIB008-2');
CALL sp_registrar_codigo_recurso_textual(9::BIGINT, 'LIB009-2');
CALL sp_registrar_codigo_recurso_textual(10::BIGINT, 'LIB010-2');


-- Realizar préstamos
CALL sp_realizar_prestamos(1::BIGINT, 1::BIGINT, 2::SMALLINT, CURRENT_DATE::DATE);
CALL sp_realizar_prestamos(2::BIGINT, 2::BIGINT, 1::SMALLINT, CURRENT_DATE::DATE);
CALL sp_realizar_prestamos(3::BIGINT, 3::BIGINT, 2::SMALLINT, CURRENT_DATE::DATE);
CALL sp_realizar_prestamos(4::BIGINT, 4::BIGINT, 1::SMALLINT, CURRENT_DATE::DATE);
CALL sp_realizar_prestamos(5::BIGINT, 5::BIGINT, 2::SMALLINT, CURRENT_DATE::DATE);

-- Renovar carnet
CALL sp_renovar_carnet('12345678');

-- Modificar dirección de un cliente
CALL sp_modificar_direccion(1, 'Perú', 'Lima', 'Lima', 'San Borja', 'Calle Las Flores 200');