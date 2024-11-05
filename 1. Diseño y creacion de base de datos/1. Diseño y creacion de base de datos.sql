/*
 Base de datos hecha en PostgreSQL
*/

CREATE DATABASE db_biblioteca;

\c db_Biblioteca;

-- Tabla tipos_estados
CREATE TABLE IF NOT EXISTS tb_tipo_estado (
	ties_id SMALLSERIAL PRIMARY KEY NOT NULL,
	ties_tipo VARCHAR(255) UNIQUE NOT NULL,
	ties_activo BOOLEAN NOT NULL DEFAULT FALSE
);

-- Tabla tipos_textos
CREATE TABLE IF NOT EXISTS tb_tipo_texto (
	tite_id BIGSERIAL PRIMARY KEY NOT NULL,
	tite_tipo VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla autores
CREATE TABLE IF NOT EXISTS tb_autor (
	auto_id BIGSERIAL PRIMARY KEY NOT NULL,
	auto_nombre VARCHAR(255) NOT NULL,
	auto_apellido_paterno VARCHAR(255) NOT NULL,
	auto_apellido_materno VARCHAR(255) NOT NULL
);

-- Tabla editoriales
CREATE TABLE IF NOT EXISTS tb_editorial (
	edit_id BIGSERIAL PRIMARY KEY NOT NULL,
	edit_nombre VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla paises
CREATE TABLE IF NOT EXISTS tb_pais (
	pais_id SMALLSERIAL PRIMARY KEY NOT NULL,
	pais_nombre VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla regiones
CREATE TABLE IF NOT EXISTS tb_region (
    regi_id BIGSERIAL PRIMARY KEY NOT NULL,
    regi_pais_id SMALLINT NOT NULL,
    regi_nombre VARCHAR(255) UNIQUE NOT NULL,
    CONSTRAINT fk_region_pais FOREIGN KEY (regi_pais_id) REFERENCES tb_pais(pais_id)
);

-- Tabla provincias
CREATE TABLE IF NOT EXISTS tb_provincia (
	prov_id BIGSERIAL PRIMARY KEY NOT NULL,
	prov_region_id BIGINT NOT NULL,
	prov_nombre VARCHAR(255) UNIQUE NOT NULL,
	CONSTRAINT fk_provincia_region FOREIGN KEY (prov_region_id) REFERENCES tb_region(regi_id)
);

-- Tabla distritos
CREATE TABLE IF NOT EXISTS tb_distrito (
	dist_id BIGSERIAL PRIMARY KEY NOT NULL,
	dist_provincia_id BIGINT NOT NULL,
	dist_nombre VARCHAR(255) UNIQUE NOT NULL,
	CONSTRAINT fk_distrito_provincia FOREIGN KEY (dist_provincia_id) REFERENCES tb_provincia(prov_id)
);

-- Tabla direcciones_clientes
CREATE TABLE IF NOT EXISTS tb_direccion_cliente (
	dicl_id BIGSERIAL PRIMARY KEY NOT NULL,
	dicl_distrito_id BIGINT NOT NULL,
	dicl_direccion VARCHAR(255) NOT NULL,
	CONSTRAINT fk_direccion_cliente_distrito FOREIGN KEY (dicl_distrito_id) REFERENCES tb_distrito(dist_id)
);

-- Tabla tipos_prestamos
CREATE TABLE IF NOT EXISTS tb_tipo_prestamo (
	tipr_id SMALLSERIAL PRIMARY KEY NOT NULL,
	tipr_tipo VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla tipos_documentos
CREATE TABLE IF NOT EXISTS tb_tipo_documento (
	tido_id SMALLSERIAL PRIMARY KEY NOT NULL,
	tido_tipo VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla roles_usuarios
CREATE TABLE IF NOT EXISTS tb_rol_usuario (
	rolu_id SMALLSERIAL PRIMARY KEY NOT NULL,
	rolu_nombre VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla categorias
CREATE TABLE IF NOT EXISTS tb_categoria (
	cate_id BIGSERIAL PRIMARY KEY NOT NULL,
	cate_nombre VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla niveles_educativos
CREATE TABLE IF NOT EXISTS tb_nivel_educativo (
	nied_id SMALLSERIAL PRIMARY KEY NOT NULL,
	nied_nombre VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla generos
CREATE TABLE IF NOT EXISTS tb_genero (
	gene_id SMALLSERIAL PRIMARY KEY NOT NULL,
	gene_nombre VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla estados_prestamos
CREATE TABLE IF NOT EXISTS tb_estado_prestamo (
	espr_id SMALLSERIAL PRIMARY KEY NOT NULL,
	espr_nombre VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla carnets
CREATE TABLE IF NOT EXISTS tb_carnet (
	carn_id BIGSERIAL PRIMARY KEY NOT NULL,
	carn_tipo_estado_id SMALLINT NOT NULL,
	carn_codigo VARCHAR(255) UNIQUE NOT NULL,
	carn_fec_emision DATE NOT NULL DEFAULT CURRENT_DATE,
	carn_fec_vencimiento DATE NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '1 YEAR'),
	CONSTRAINT fk_carnet_tipo_estado FOREIGN KEY (carn_tipo_estado_id) REFERENCES tb_tipo_estado(ties_id),
    CONSTRAINT chk_fec_vencimiento_carnet CHECK (carn_fec_vencimiento > carn_fec_emision)
);

-- Tabla recursos_textuales
CREATE TABLE IF NOT EXISTS tb_recurso_textual (
	rete_id BIGSERIAL PRIMARY KEY NOT NULL,
	rete_tipo_texto_id BIGINT NOT NULL,
	rete_editorial_id BIGINT NOT NULL,
	rete_titulo VARCHAR(255) NOT NULL,
    rete_codigo_base VARCHAR(15) UNIQUE NOT NULL,
	rete_fec_publicacion DATE NOT NULL,
	rete_num_paginas SMALLINT NOT NULL,
	rete_edicion SMALLINT NOT NULL DEFAULT 0,
	rete_volumen SMALLINT NOT NULL DEFAULT 0,
    rete_activo BOOLEAN NOT NULL DEFAULT TRUE,
	CONSTRAINT fk_recurso_textual_tipo_texto FOREIGN KEY (rete_tipo_texto_id) REFERENCES tb_tipo_texto(tite_id),
	CONSTRAINT fk_recurso_textual_editorial FOREIGN KEY (rete_editorial_id) REFERENCES tb_editorial(edit_id),
	CONSTRAINT chk_recurso_textual_numero_paginas CHECK (rete_num_paginas > 0)
);

-- Tabla usuarios
CREATE TABLE IF NOT EXISTS tb_usuario (
	usua_id BIGSERIAL PRIMARY KEY NOT NULL,
	usua_rol_usuario_id SMALLINT NOT NULL,
	usua_tipo_documento_id SMALLINT NOT NULL,
	usua_documento VARCHAR(20) UNIQUE NOT NULL,
	usua_psk VARCHAR(255) NOT NULL,
    usua_nombre VARCHAR(255) NOT NULL,
    usua_apellido_paterno VARCHAR(255) NOT NULL,
    usua_apellido_materno VARCHAR(255) NOT NULL,
    usua_telefono CHAR(9) UNIQUE NOT NULL,
    usua_genero_id SMALLINT NOT NULL,
    usua_activo BOOLEAN NOT NULL DEFAULT TRUE,
	CONSTRAINT fk_usuario_rol_usuario FOREIGN KEY (usua_rol_usuario_id) REFERENCES tb_rol_usuario(rolu_id),
	CONSTRAINT fk_usuario_tipo_documento FOREIGN KEY (usua_tipo_documento_id) REFERENCES tb_tipo_documento(tido_id),
	CONSTRAINT chk_usuario_documento CHECK (usua_documento ~ '^\d{8,20}$'),
    CONSTRAINT fk_genero FOREIGN KEY (usua_genero_id) REFERENCES tb_genero(gene_id),
    CONSTRAINT chk_cliente_telefono CHECK (tb_usuario.usua_telefono ~ '^\d{9}$')
);

-- Tabla clientes
CREATE TABLE IF NOT EXISTS tb_cliente (
	clie_id BIGSERIAL PRIMARY KEY NOT NULL,
    clie_usuario_id BIGINT UNIQUE NOT NULL,
	clie_direccion_id BIGINT UNIQUE NOT NULL,
	clie_correo VARCHAR(255) UNIQUE NOT NULL,
	clie_carnet_id BIGINT UNIQUE NOT NULL,
	clie_nivel_educativo_id SMALLINT NOT NULL,
    CONSTRAINT fk_cliente_usuario FOREIGN KEY (clie_usuario_id) REFERENCES tb_usuario(usua_id),
	CONSTRAINT fk_cliente_direccion FOREIGN KEY (clie_direccion_id) REFERENCES tb_direccion_cliente(dicl_id),
	CONSTRAINT fk_cliente_carnet FOREIGN KEY (clie_carnet_id) REFERENCES tb_carnet(carn_id),
	CONSTRAINT fk_cliente_nivel_educativo FOREIGN KEY (clie_nivel_educativo_id) REFERENCES tb_nivel_educativo(nied_id),
    CONSTRAINT fk_cliente_direccion FOREIGN KEY (clie_direccion_id) REFERENCES tb_direccion_cliente(dicl_id),
	CONSTRAINT chk_cliente_correo CHECK (clie_correo ~ '^[a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*@[a-zA-Z0-9_]+([.][a-zA-Z0-9_]+)*[.][a-zA-Z]{2,5}$')
);

-- Tabla recursos_textuales_codigos
CREATE TABLE IF NOT EXISTS tb_recurso_textual_codigo (
	reco_id BIGSERIAL PRIMARY KEY NOT NULL,
    reco_rete_codigo_base VARCHAR(15) NOT NULL,
	reco_codigo_ejemplar INT NOT NULL,
	reco_disponible BOOLEAN NOT NULL,
	CONSTRAINT fk_recurso_textual_codigo_recurso FOREIGN KEY (reco_rete_codigo_base) REFERENCES tb_recurso_textual(rete_codigo_base) ON UPDATE CASCADE,
    CONSTRAINT unq_recurso_textual_codigo_base_ejemplar UNIQUE(reco_rete_codigo_base, reco_codigo_ejemplar)
);

-- Tabla prestamos
CREATE TABLE IF NOT EXISTS tb_prestamo (
	pres_id BIGSERIAL PRIMARY KEY NOT NULL,
	pres_usuario_id BIGINT NOT NULL,
	pres_recurso_textual_codigo_id BIGINT NOT NULL,
	pres_tipo_prestamo_id SMALLINT NOT NULL,
	pres_estado_prestamo_id SMALLINT NOT NULL,
	pres_fec_inicial DATE NOT NULL DEFAULT CURRENT_DATE,
	pres_fec_final DATE DEFAULT NULL,
	pres_fec_programada DATE NOT NULL,
	CONSTRAINT fk_prestamo_usuario FOREIGN KEY (pres_usuario_id) REFERENCES tb_usuario(usua_id),
	CONSTRAINT fk_prestamo_recurso_textual_codigo FOREIGN KEY (pres_recurso_textual_codigo_id) REFERENCES tb_recurso_textual_codigo(reco_id),
	CONSTRAINT fk_prestamo_tipo_prestamo FOREIGN KEY (pres_tipo_prestamo_id) REFERENCES tb_tipo_prestamo(tipr_id),
	CONSTRAINT fk_prestamo_estado_prestamo FOREIGN KEY (pres_estado_prestamo_id) REFERENCES tb_estado_prestamo(espr_id),
	CONSTRAINT chk_prestamo_fecha_programada CHECK (pres_fec_programada >= pres_fec_inicial),
	CONSTRAINT chk_prestamo_fecha_final CHECK (pres_fec_final >= pres_fec_inicial OR pres_fec_final IS NULL)
);

-- Tabla recursos_textuales_autores
CREATE TABLE IF NOT EXISTS tb_recurso_textual_autor (
	reau_recurso_textual_id BIGINT NOT NULL,
	reau_autor_id BIGINT NOT NULL,
	PRIMARY KEY (reau_recurso_textual_id, reau_autor_id),
	CONSTRAINT fk_recurso_textual_autor_recurso FOREIGN KEY (reau_recurso_textual_id) REFERENCES tb_recurso_textual(rete_id),
	CONSTRAINT fk_recurso_textual_autor_autor FOREIGN KEY (reau_autor_id) REFERENCES tb_autor(auto_id)
);

-- Tabla registro_acciones_usuarios
CREATE TABLE IF NOT EXISTS tb_registro_accion_usuario (
	reau_usuario_id BIGINT NOT NULL,
    reau_detalle VARCHAR NOT NULL,
	reau_fec_hora TIMESTAMP NOT NULL DEFAULT NOW(),
	reau_direccion_ip VARCHAR(255) NOT NULL,
	CONSTRAINT fk_registro_accion_usuario_usuario FOREIGN KEY (reau_usuario_id) REFERENCES tb_usuario(usua_id),
	CONSTRAINT chk_registro_accion_usuario_direccion_ip CHECK (
        reau_direccion_ip ~ '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
        OR reau_direccion_ip ~ '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))'
	)
);

-- Tabla categorias_recursos_textuales
CREATE TABLE IF NOT EXISTS tb_categoria_recurso_textual (
	care_recurso_textual_id BIGINT NOT NULL,
	care_categoria_id BIGINT NOT NULL,
	PRIMARY KEY (care_recurso_textual_id, care_categoria_id),
	CONSTRAINT fk_categoria_recurso_textual_recurso FOREIGN KEY (care_recurso_textual_id) REFERENCES tb_recurso_textual(rete_id),
	CONSTRAINT fk_categoria_recurso_textual_categoria FOREIGN KEY (care_categoria_id) REFERENCES tb_categoria(cate_id)
);