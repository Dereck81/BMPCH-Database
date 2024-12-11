-- Conectarse a la base de datos
\c db_biblioteca;

-- No cambiar
INSERT INTO public.tb_tipo_estado (ties_tipo, ties_activo) VALUES ('Activo', true);
INSERT INTO public.tb_tipo_estado (ties_tipo, ties_activo) VALUES ('Vencido', false);
INSERT INTO public.tb_tipo_estado (ties_tipo, ties_activo) VALUES ('Suspendido', false);

INSERT INTO public.tb_categoria (cate_nombre) VALUES ('Ficción');
INSERT INTO public.tb_categoria (cate_nombre) VALUES ('No ficción');
INSERT INTO public.tb_categoria (cate_nombre) VALUES ('Ciencia');
INSERT INTO public.tb_categoria (cate_nombre) VALUES ('Historia');
INSERT INTO public.tb_categoria (cate_nombre) VALUES ('Tecnología');

INSERT INTO public.tb_editorial (edit_nombre) VALUES ('Editorial Planeta');
INSERT INTO public.tb_editorial (edit_nombre) VALUES ('Penguin Random House');
INSERT INTO public.tb_editorial (edit_nombre) VALUES ('Santillana');
INSERT INTO public.tb_editorial (edit_nombre) VALUES ('Anagrama');

INSERT INTO public.tb_tipo_texto (tite_tipo) VALUES ('Libro');
INSERT INTO public.tb_tipo_texto (tite_tipo) VALUES ('Revista');
INSERT INTO public.tb_tipo_texto (tite_tipo) VALUES ('Periódico');
INSERT INTO public.tb_tipo_texto (tite_tipo) VALUES ('Tesis');

INSERT INTO public.tb_pais (pais_nombre) VALUES ('Argentina');
INSERT INTO public.tb_pais (pais_nombre) VALUES ('Brasil');
INSERT INTO public.tb_pais (pais_nombre) VALUES ('Chile');
INSERT INTO public.tb_pais (pais_nombre) VALUES ('Perú');

INSERT INTO public.tb_region (regi_pais_id, regi_nombre) VALUES (1, 'Buenos Aires');
INSERT INTO public.tb_region (regi_pais_id, regi_nombre) VALUES (1, 'Córdoba');
INSERT INTO public.tb_region (regi_pais_id, regi_nombre) VALUES (2, 'São Paulo');
INSERT INTO public.tb_region (regi_pais_id, regi_nombre) VALUES (2, 'Rio de Janeiro');
INSERT INTO public.tb_region (regi_pais_id, regi_nombre) VALUES (3, 'Santiago');
INSERT INTO public.tb_region (regi_pais_id, regi_nombre) VALUES (3, 'Valparaíso');
INSERT INTO public.tb_region (regi_pais_id, regi_nombre) VALUES (4, 'Lima');
INSERT INTO public.tb_region (regi_pais_id, regi_nombre) VALUES (4, 'Arequipa');

INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (1, 'La Plata');
INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (1, 'Mar del Plata');
INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (2, 'Villa Carlos Paz');
INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (3, 'Campinas');
INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (3, 'Sorocaba');
INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (4, 'Niterói');
INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (5, 'Maipú');
INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (5, 'Viña del Mar');
INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (7, 'Miraflores');
INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (7, 'San Isidro');
INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (8, 'Cayma');
INSERT INTO public.tb_provincia (prov_region_id, prov_nombre) VALUES (8, 'Yanahuara');

INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (1, 'Centro');
INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (2, 'Los Troncos');
INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (3, 'San Roque');
INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (4, 'Barão Geraldo');
INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (5, 'Éden');
INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (6, 'Santa Rosa');
INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (7, 'Avenida Principal');
INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (8, 'Paseo Costero');
INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (9, 'San Miguel');
INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (9, 'Surco');
INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (10, 'Cerro Colorado');
INSERT INTO public.tb_distrito (dist_provincia_id, dist_nombre) VALUES (11, 'Andenes');

INSERT INTO public.tb_direccion_cliente (dicl_distrito_id, dicl_direccion) VALUES (1, 'Calle 123, Centro, La Plata');
INSERT INTO public.tb_direccion_cliente (dicl_distrito_id, dicl_direccion) VALUES (2, 'Avenida Atlántica, Los Troncos, Mar del Plata');
INSERT INTO public.tb_direccion_cliente (dicl_distrito_id, dicl_direccion) VALUES (4, 'Rua das Flores, Barão Geraldo, Campinas');
INSERT INTO public.tb_direccion_cliente (dicl_distrito_id, dicl_direccion) VALUES (7, 'Alameda Peñablanca, Avenida Principal, Maipú');
INSERT INTO public.tb_direccion_cliente (dicl_distrito_id, dicl_direccion) VALUES (9, 'Jirón El Sol, San Miguel, Miraflores');
INSERT INTO public.tb_direccion_cliente (dicl_distrito_id, dicl_direccion) VALUES (11, 'Pasaje Los Pinos, Andenes, Yanahuara');
INSERT INTO public.tb_direccion_cliente (dicl_distrito_id, dicl_direccion) VALUES (11, 'Calle Olivares #353 2do Piso');
INSERT INTO public.tb_direccion_cliente (dicl_distrito_id, dicl_direccion) VALUES (11, 'Calle Olivares #303 2do Piso');

INSERT INTO public.tb_genero (gene_nombre) VALUES ('Masculino');
INSERT INTO public.tb_genero (gene_nombre) VALUES ('Femenino');
INSERT INTO public.tb_genero (gene_nombre) VALUES ('No binario');

INSERT INTO public.tb_nivel_educativo (nied_nombre) VALUES ('Primaria');
INSERT INTO public.tb_nivel_educativo (nied_nombre) VALUES ('Secundaria');
INSERT INTO public.tb_nivel_educativo (nied_nombre) VALUES ('Superior');
INSERT INTO public.tb_nivel_educativo (nied_nombre) VALUES ('Postgrado');

-- No cambiar
INSERT INTO public.tb_rol_usuario (rolu_nombre) VALUES ('Administrador');
INSERT INTO public.tb_rol_usuario (rolu_nombre) VALUES ('Cliente');
INSERT INTO public.tb_rol_usuario (rolu_nombre) VALUES ('Bibliotecario');

-- No cambiar
INSERT INTO public.tb_tipo_documento (tido_tipo) VALUES ('DNI');
INSERT INTO public.tb_tipo_documento (tido_tipo) VALUES ('Pasaporte');
INSERT INTO public.tb_tipo_documento (tido_tipo) VALUES ('Carné de extranjería');

INSERT INTO public.tb_usuario (usua_rol_usuario_id, usua_tipo_documento_id, usua_documento, usua_psk, usua_nombre, usua_apellido_paterno, usua_apellido_materno, usua_telefono, usua_genero_id) VALUES (1, 1, '73266267', '$2a$10$ekueVm6N0ky1JRzpnE8eJuVv6wbjlmgn2nbn11Gv6Ej46Jo0LcpQu', 'Diego Alexis', 'Llacsahuanga', 'Buques', '976849906', 1);
INSERT INTO public.tb_usuario (usua_rol_usuario_id, usua_tipo_documento_id, usua_documento, usua_psk, usua_nombre, usua_apellido_paterno, usua_apellido_materno, usua_telefono, usua_genero_id) VALUES (1, 1, '75101157', '$2a$10$j/U3SsUH9YxRq8kTE8XC4uiyaqRVF22TQlX9YVJxVPc0Q8Wuv9qb2', 'Kevin', 'Huanca', 'Fernandez', '968370197', 1);

-- No cambiar
INSERT INTO public.tb_estado_prestamo (espr_nombre) VALUES ('Activo');
INSERT INTO public.tb_estado_prestamo (espr_nombre) VALUES ('Devuelto');
INSERT INTO public.tb_estado_prestamo (espr_nombre) VALUES ('Vencido');

INSERT INTO public.tb_tipo_prestamo (tipr_tipo) VALUES ('Préstamo en sala');
INSERT INTO public.tb_tipo_prestamo (tipr_tipo) VALUES ('Préstamo a domicilio');
