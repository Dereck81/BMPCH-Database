USE bmpch;

-- Insertar tipos de estados
INSERT INTO tipos_estados (tipo_estado, activo)
VALUES ('Activo', TRUE),
       ('Vencido', FALSE),
       ('Suspendido', FALSE);

-- Insertar tipos de textos
INSERT INTO tipos_textos (tipo_texto)
VALUES ('Libro'),
       ('Revista'),
       ('Artículo'),
       ('Informe'),
       ('Tesis');

-- Insertar autores
INSERT INTO autores (seudonimo, nombre, apellido_paterno, apellido_materno)
VALUES ('Autor1', 'Juan', 'Pérez', 'Gómez'),
       ('Autor2', 'Ana', 'López', 'Martínez'),
       ('Autor3', 'Carlos', 'Ramírez', 'Sánchez'),
       ('Autor4', 'Laura', 'Torres', 'Díaz'),
       ('Autor5', 'Marta', 'Fernández', 'Rojas'),
       ('Autor6', 'Pedro', 'Gutiérrez', 'Cruz'),
       ('Autor7', 'Sofía', 'Hernández', 'Castillo'),
       ('Autor8', 'Javier', 'Martín', 'Mendoza'),
       ('Autor9', 'Lucía', 'Salazar', 'Cordero'),
       ('Autor10', 'Diego', 'Jiménez', 'Pizarro'),
       ('Autor11', 'Clara', 'Vásquez', 'Quispe'),
       ('Autor12', 'Fernando', 'Luna', 'Salinas'),
       ('Autor13', 'Ricardo', 'Ríos', 'Cano'),
       ('Autor14', 'Isabel', 'Vega', 'Alvarado'),
       ('Autor15', 'Felipe', 'Marín', 'Bravo');

-- Insertar editoriales
INSERT INTO editoriales (nombre)
VALUES ('Editorial A'),
       ('Editorial B'),
       ('Editorial C'),
       ('Editorial D'),
       ('Editorial E');

-- Insertar países
INSERT INTO paises (pais)
VALUES ('Perú'),
       ('Chile'),
       ('Argentina'),
       ('Colombia'),
       ('México');

-- Insertar regiones
INSERT INTO regiones (pais_id, region)
VALUES (1, 'Lima'),
       (1, 'Cusco'),
       (2, 'Santiago'),
       (3, 'Buenos Aires'),
       (4, 'Bogotá'),
       (5, 'Ciudad de México'),
       (1, 'Arequipa'),
       (2, 'Valparaíso'),
       (3, 'Córdoba'),
       (4, 'Medellín'),
       (5, 'Guadalajara');

-- Insertar provincias
INSERT INTO provincias (region_id, provincia)
VALUES (1, 'Lima'),
       (1, 'Callao'),
       (2, 'Cusco'),
       (3, 'Santiago'),
       (4, 'La Plata'),
       (5, 'Bogotá'),
       (6, 'Arequipa'),
       (7, 'Valparaíso'),
       (8, 'Córdoba'),
       (9, 'Antioquia'),
       (10, 'Jalisco');

-- Insertar distritos
INSERT INTO distritos (provincia_id, distrito)
VALUES (1, 'Miraflores'),
       (1, 'San Isidro'),
       (2, 'Cusco'),
       (3, 'Las Condes'),
       (4, 'La Plata'),
       (5, 'Chapinero'),
       (6, 'Cayma'),
       (7, 'Viña del Mar'),
       (8, 'Río Cuarto'),
       (9, 'Medellín'),
       (10, 'Zapopan');

-- Insertar direcciones de clientes
INSERT INTO direcciones_clientes (distrito_id, direccion)
VALUES (1, 'Av. José Larco 123'),
       (2, 'Calle del Medio 456'),
       (3, 'Av. Sol 789'),
       (4, 'Calle de la Luz 101'),
       (5, 'Av. Ciudad 202'),
       (6, 'Calle 45 303'),
       (7, 'Av. Libertad 404'),
       (8, 'Calle San Martín 505'),
       (9, 'Calle A 606'),
       (10, 'Calle B 707');

-- Insertar tipos de préstamos
INSERT INTO tipos_prestamos (tipo_prestamo)
VALUES ('Normal'),
       ('Urgente'),
       ('Extensivo'),
       ('Corto plazo'),
       ('Largo plazo');

-- Insertar tipos de documentos
INSERT INTO tipos_documentos (tipo_documento)
VALUES ('DNI'),
       ('Pasaporte'),
       ('Carnet de extranjería'),
       ('Licencia de conducir');

-- Insertar roles de usuarios
INSERT INTO roles_usuarios (rol_usuario)
VALUES ('Admin'),
       ('Usuario'),
       ('Editor'),
       ('Moderador'),
       ('Colaborador');

-- Insertar categorías
INSERT INTO categorias (categoria)
VALUES ('Ficción'),
       ('No ficción'),
       ('Ciencia'),
       ('Historia'),
       ('Arte'),
       ('Tecnología'),
       ('Salud'),
       ('Literatura Infantil');

-- Insertar niveles educativos
INSERT INTO niveles_educativos (nivel_educativo)
VALUES ('Primaria'),
       ('Secundaria'),
       ('Universidad'),
       ('Postgrado'),
       ('Doctorado');

-- Insertar géneros
INSERT INTO generos (genero)
VALUES ('Masculino'),
       ('Femenino'),
       ('Otro');

-- Insertar estados de préstamos
INSERT INTO estados_prestamos (estado_prestamo)
VALUES ('Activo'),
       ('Finalizado'),
       ('Cancelado'),
       ('Pendiente'),
       ('En Proceso');

-- Insertar carnets
INSERT INTO carnets (tipo_estado_id, codigo, fecha_emision, fecha_vencimiento)
VALUES (1, 'CARNET001', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR)),
       (1, 'CARNET002', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR)),
       (2, 'CARNET003', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR)),
       (3, 'CARNET004', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR)),
       (1, 'CARNET005', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR)),
        (1, 'CARNET006', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR)),
        (1, 'CARNET007', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR)),
        (1, 'CARNET008', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR)),
        (1, 'CARNET009', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR)),
        (1, 'CARNET010', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR));

-- Insertar recursos textuales
INSERT INTO recursos_textuales (titulo, fecha_publicacion, stock, numero_paginas, edicion, volumen, codigo,
                                tipo_texto_id, editorial_id)
VALUES ('El poder de los hábitos', '2020-01-01', 10, 300, 1, 1, '978-1234567890', 1, 1),
       ('La magia del orden', '2018-05-15', 5, 250, 1, 1, '978-1234567891', 1, 2),
       ('Educación financiera', '2021-08-20', 7, 400, 1, 1, '978-1234567892', 1, 1),
       ('Ciencia en casa', '2019-03-12', 15, 200, 1, 1, '978-1234567893', 2, 1),
       ('El arte de la guerra', '2022-06-30', 12, 150, 1, 1, '978-1234567894', 1, 2),
       ('La historia de la ciencia', '2020-09-09', 8, 280, 1, 1, '978-1234567895', 3, 1),
       ('Física cuántica para todos', '2021-10-10', 20, 320, 1, 1, '978-1234567896', 1, 1),
       ('Cocina saludable', '2022-02-02', 5, 180, 1, 1, '978-1234567897', 4, 2),
       ('Cuentos de hadas', '2023-03-03', 25, 120, 1, 1, '978-1234567898', 2, 1),
       ('Tecnología del futuro', '2020-12-01', 30, 500, 1, 1, '978-1234567899', 3, 1);

-- Insertar clientes
INSERT INTO clientes (nombre, apellido_paterno, apellido_materno, genero_id, direccion_cliente_id, telefono, correo,
                      carnet_id, nivel_educativo_id)
VALUES ('Luis', 'García', 'Alvarez', 1, 1, '987654321', 'luis.garcia@example.com', 1, 3),
       ('Ana', 'Martinez', 'Lopez', 2, 2, '987654322', 'ana.martinez@example.com', 2, 4),
       ('Carlos', 'Ramirez', 'Sanchez', 1, 3, '987654323', 'carlos.ramirez@example.com', 3, 2),
       ('Laura', 'Torres', 'Díaz', 2, 4, '987654324', 'laura.torres@example.com', 4, 1),
       ('Marta', 'Fernández', 'Rojas', 1, 5, '987654325', 'marta.fernandez@example.com', 5, 1),
       ('Pedro', 'Gutiérrez', 'Cruz', 1, 6, '987654326', 'pedro.gutierrez@example.com', 6, 3),
       ('Sofía', 'Hernández', 'Castillo', 2, 7, '987654327', 'sofia.hernandez@example.com', 7, 5),
       ('Javier', 'Martín', 'Mendoza', 1, 8, '987654328', 'javier.martin@example.com', 8, 4),
       ('Lucía', 'Salazar', 'Cordero', 2, 9, '987654329', 'lucia.salazar@example.com', 9, 3),
       ('Diego', 'Jiménez', 'Pizarro', 1, 10, '987654330', 'diego.jimenez@example.com', 10, 2);
