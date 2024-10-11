
INSERT INTO tb_tipo_estado (ties_tipo, ties_activo) VALUES
                                                        ('Activo', TRUE),
                                                        ('Inactivo', FALSE);


INSERT INTO tb_tipo_texto (tite_tipo) VALUES
                                          ('Novela'),
                                          ('Ensayo'),
                                          ('Cuento');


CALL sp_registrar_autor('J.K. Rowling', 'Joanne', 'Rowling', 'Murray');
CALL sp_registrar_autor('Gabriel García Márquez', 'Gabriel', 'García', 'Márquez');
CALL sp_registrar_autor('George Orwell', 'Eric', 'Arthur', 'Blair');

INSERT INTO tb_editorial (edit_nombre) VALUES
                                           ('Penguin Random House'),
                                           ('HarperCollins'),
                                           ('Simon & Schuster');



INSERT INTO tb_tipo_prestamo (tipr_tipo) VALUES
                                             ('Corto Plazo'),
                                             ('Largo Plazo');


INSERT INTO tb_tipo_documento (tido_tipo) VALUES
                                              ('DNI'),
                                              ('Pasaporte');


INSERT INTO tb_rol_usuario (rolu_nombre) VALUES
                                             ('Administrador'),
                                             ('Cliente');


INSERT INTO tb_categoria (cate_nombre) VALUES
                                           ('Ficción'),
                                           ('No Ficción');


INSERT INTO tb_nivel_educativo (nied_nombre) VALUES
                                                 ('Primaria'),
                                                 ('Secundaria'),
                                                 ('Universitaria');


INSERT INTO tb_genero (gene_nombre) VALUES
                                        ('Masculino'),
                                        ('Femenino');


INSERT INTO tb_estado_prestamo (espr_nombre) VALUES
                                                 ('Activo'),
                                                 ('Finalizado');


CALL sp_registrar_clientes('Juan', 'Pérez', 'García', 1, '12345678', 1, '987654321', 'juan.perez@example.com', 1, 'Perú', 'Lima', 'Lima', 'Miraflores', 'Av. José Larco 123');
CALL sp_registrar_clientes('María', 'López', 'Fernández', 2, '87654321', 1, '912345678', 'maria.lopez@example.com', 2, 'Colombia', 'Bogotá', 'Cundinamarca', 'Chapinero', 'Calle 85 #12-34');


CALL sp_realizar_prestamos(1, 1, 1, '2024-10-10');
CALL sp_realizar_prestamos(2, 2, 2, '2024-11-15');


INSERT INTO tb_categoria_recurso_textual (care_recurso_textual_id, care_categoria_id) VALUES
                                                                                          (1, 1),
                                                                                          (2, 2);

CALL sp_registrar_recurso_textual('Cien Años de Soledad', '1967-05-30', 417, 1, 1, 'RECURSO001', 1, 1, 2);
CALL sp_registrar_recurso_textual('1984', '1949-06-08', 328, 1, 1, 'RECURSO002', 1, 2, 3);

INSERT INTO tb_registro_accion_usuario (reau_usuario_id, reau_accion_id, reau_direccion_ip) VALUES
                                                                                                (1, 1, '192.168.1.1'),
                                                                                                (2, 2, '192.168.1.2');