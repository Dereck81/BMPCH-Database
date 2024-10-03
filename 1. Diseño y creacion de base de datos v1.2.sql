/*IMPORTANT: USE VERSION '8.0.39' > */

CREATE DATABASE bmpch;

USE bmpch;

CREATE TABLE IF NOT EXISTS tipo_estado (
	id_tipo_estado BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	ipo_estado VARCHAR(255) UNIQUE NOT NULL,
	activo BOOLEAN NOT NULL DEFAULT FALSE

);

CREATE TABLE IF NOT EXISTS tipo_texto (
	id_tipo_texto BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	tipo_texto VARCHAR(255) UNIQUE NOT NULL

);

CREATE TABLE IF NOT EXISTS autores (
	id_autor BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	seudonimo VARCHAR(255) UNIQUE NOT NULL,
	nombre VARCHAR(255) NOT NULL,
	apellido_paterno VARCHAR(255) NOT NULL,
	apellido_materno VARCHAR(255) NOT NULL

);

CREATE TABLE IF NOT EXISTS editoriales (
	id_editorial BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	editorial VARCHAR(255) UNIQUE NOT NULL

);

CREATE TABLE IF NOT EXISTS paises (
	id_pais BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	pais VARCHAR(255) UNIQUE NOT NULL

);

CREATE TABLE IF NOT EXISTS regiones (
	id_region BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	pais_id BIGINT UNSIGNED NOT NULL,
	region VARCHAR(255) UNIQUE NOT NULL,
	FOREIGN KEY (pais_id) REFERENCES paises(id_pais)

);

CREATE TABLE IF NOT EXISTS provincias (
	id_provincia BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	region_id BIGINT UNSIGNED NOT NULL,
	provincia VARCHAR(255) NOT NULL,
	FOREIGN KEY (region_id) REFERENCES regiones(id_region)

);

CREATE TABLE IF NOT EXISTS distritos (
	id_distrito BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	provincia_id BIGINT UNSIGNED NOT NULL,
	distrito VARCHAR(255) NOT NULL,
	FOREIGN KEY (provincia_id) REFERENCES provincias(id_provincia)

);

CREATE TABLE IF NOT EXISTS direcciones_clientes (
	id_direccion_cliente BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	distrito_id BIGINT UNSIGNED NOT NULL,
	direccion VARCHAR(255) NOT NULL,
	FOREIGN KEY (distrito_id) REFERENCES distritos(id_distrito)

);

CREATE TABLE IF NOT EXISTS tipos_prestamos (
	id_tipo_prestamo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	tipo_prestamo VARCHAR(255) UNIQUE NOT NULL

);

CREATE TABLE IF NOT EXISTS tipos_documentos (
	id_tipo_documento BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	tipo_documento VARCHAR(255) UNIQUE NOT NULL

);

CREATE TABLE IF NOT EXISTS roles_usuarios (
	id_rol_usuario BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	rol_usuario VARCHAR(255) UNIQUE NOT NULL

);

CREATE TABLE IF NOT EXISTS categorias (
	id_categoria BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	categoria VARCHAR(255) UNIQUE NOT NULL

);

CREATE TABLE IF NOT EXISTS niveles_educativos (
	id_nivel_educativo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	nivel_educativo VARCHAR(255) UNIQUE NOT NULL

);

CREATE TABLE IF NOT EXISTS generos (
	id_genero BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	genero VARCHAR(255) UNIQUE NOT NULL

);

CREATE TABLE IF NOT EXISTS estados_prestamos (
	id_estado_prestamo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	estado_prestamo VARCHAR(255) NOT NULL

);

CREATE TABLE IF NOT EXISTS carnets (
	id_carnet BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	tipo_estado_id BIGINT UNSIGNED NOT NULL,
	codigo VARCHAR(100) UNIQUE NOT NULL,
	fecha_emision DATE NOT NULL DEFAULT (CURRENT_DATE),
	fecha_vencimiento DATE NOT NULL DEFAULT (DATE_ADD(fecha_emision, INTERVAL 1 YEAR)),
	FOREIGN KEY (tipo_estado_id) REFERENCES tipo_estado (id_tipo_estado),
    CONSTRAINT chk_fecha_vencimiento CHECK (fecha_vencimiento > fecha_emision)

);

CREATE TABLE IF NOT EXISTS recursos_textuales (
	id_recurso_textual BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	titulo VARCHAR(255) NOT NULL,
	fecha_publicacion DATE NOT NULL,
	stock TINYINT UNSIGNED NOT NULL DEFAULT 1,
	numero_paginas SMALLINT UNSIGNED NOT NULL,
	edicion TINYINT UNSIGNED NOT NULL DEFAULT 0,
	volumen TINYINT UNSIGNED NOT NULL DEFAULT 0,
	codigo VARCHAR(50) UNIQUE NOT NULL,
	tipo_texto_id BIGINT UNSIGNED NOT NULL,
	editorial_id BIGINT UNSIGNED NOT NULL,
	FOREIGN KEY (tipo_texto_id) REFERENCES tipo_texto(id_tipo_texto),
	FOREIGN KEY (editorial_id) REFERENCES editoriales(id_editorial),
    CONSTRAINT chk_numero_paginas CHECK (numero_paginas > 0)

);

CREATE TABLE IF NOT EXISTS clientes (
	id_cliente BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	nombre VARCHAR(255) NOT NULL,
	apellido_paterno VARCHAR(255) NOT NULL,
	apellido_materno VARCHAR(255) NOT NULL,
	genero_id BIGINT UNSIGNED NOT NULL,
	direccion_cliente_id BIGINT UNSIGNED NOT NULL,
	telefono CHAR(9) UNIQUE NOT NULL,
	correo VARCHAR(255) UNIQUE NOT NULL,
	carnet_id BIGINT UNSIGNED UNIQUE NOT NULL,
	nivel_educativo_id BIGINT UNSIGNED NOT NULL,
	FOREIGN KEY (genero_id) REFERENCES generos(id_genero),
	FOREIGN KEY (direccion_cliente_id) REFERENCES direcciones_clientes(id_direccion_cliente),
	FOREIGN KEY (carnet_id) REFERENCES carnets(id_carnet),
	FOREIGN KEY (nivel_educativo_id) REFERENCES niveles_educativos(id_nivel_educativo),
	CONSTRAINT chk_correo_cliente CHECK (correo RLIKE '^[a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*@[a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*[.][a-zA-Z]{2,5}$'),
	CONSTRAINT chk_telefono CHECK (telefono RLIKE '^\\d{9}$')
);

CREATE TABLE IF NOT EXISTS usuarios (
	id_usuario BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	cliente_id BIGINT UNSIGNED UNIQUE NOT NULL,
	rol_usuario_id BIGINT UNSIGNED NOT NULL,
	documento VARCHAR(20) UNIQUE NOT NULL,
	tipo_documento_id BIGINT UNSIGNED NOT NULL,
	psk VARCHAR(255) NOT NULL,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id_cliente),
	FOREIGN KEY (rol_usuario_id) REFERENCES roles_usuarios(id_rol_usuario),
	FOREIGN KEY (tipo_documento_id) REFERENCES tipos_documentos(id_tipo_documento),
	CONSTRAINT chk_documento CHECK (documento RLIKE '^\\d{8,20}$')

);

CREATE TABLE IF NOT EXISTS prestamos (
	id_prestamo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	usuario_id BIGINT UNSIGNED NOT NULL,
	recurso_textual_id BIGINT UNSIGNED NOT NULL,
	tipo_prestamo_id BIGINT UNSIGNED NOT NULL,
	estado_prestamo_id BIGINT UNSIGNED NOT NULL,
	fecha_inicial DATETIME NOT NULL DEFAULT (CURRENT_DATE),
	fecha_final DATETIME DEFAULT NULL,
	fecha_programada DATETIME NOT NULL,
	FOREIGN KEY (usuario_id) REFERENCES usuarios(id_usuario),
	FOREIGN KEY (recurso_textual_id) REFERENCES recursos_textuales(id_recurso_textual),
	FOREIGN KEY (tipo_prestamo_id) REFERENCES tipos_prestamos(id_tipo_prestamo),
	FOREIGN KEY (estado_prestamo_id) REFERENCES estados_prestamos(id_estado_prestamo),
    CONSTRAINT chk_fecha_programada CHECK (fecha_programada >= fecha_inicial),
	CONSTRAINT chk_fecha_final CHECK (fecha_final >= fecha_inicial OR fecha_final IS NULL)

);

CREATE TABLE IF NOT EXISTS recursos_textuales_autores (
	recurso_textual_id BIGINT UNSIGNED NOT NULL,
	autor_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (recurso_textual_id, autor_id),
	FOREIGN KEY (recurso_textual_id) REFERENCES recursos_textuales(id_recurso_textual),
	FOREIGN KEY (autor_id) REFERENCES autores(id_autor)

);

CREATE TABLE IF NOT EXISTS registros_accesos_usuarios (
	id_registro_acceso BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
	usuario_id BIGINT UNSIGNED NOT NULL,
	fecha_ingreso DATETIME NOT NULL DEFAULT (NOW()),
	direccion_ip VARCHAR(255) NOT NULL,
	FOREIGN KEY (usuario_id) REFERENCES usuarios(id_usuario),
	CONSTRAINT chk_direccion_ip_admins CHECK (
		direccion_ip RLIKE '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
        OR direccion_ip RLIKE '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))'
    )

);

CREATE TABLE IF NOT EXISTS categorias_recursos_textuales (
	recurso_textual_id BIGINT UNSIGNED NOT NULL,
	categoria_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (recurso_textual_id, categoria_id),
	FOREIGN KEY (recurso_textual_id) REFERENCES recursos_textuales(id_recurso_textual),
	FOREIGN KEY (categoria_id) REFERENCES categorias(id_categoria)

);

