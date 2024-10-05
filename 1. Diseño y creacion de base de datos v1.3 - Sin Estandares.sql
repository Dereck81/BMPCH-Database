CREATE DATABASE bmpch;

\c bmpch;

-- Tabla tipo_estado
CREATE TABLE IF NOT EXISTS tipo_estado (
    id_tipo_estado BIGINT PRIMARY KEY NOT NULL,
    tipo_estado VARCHAR(255) UNIQUE NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT FALSE
);

-- Tabla tipo_texto
CREATE TABLE IF NOT EXISTS tipo_texto (
    id_tipo_texto BIGINT PRIMARY KEY NOT NULL,
    tipo_texto VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla autores
CREATE TABLE IF NOT EXISTS autores (
    id_autor BIGINT PRIMARY KEY NOT NULL,
    seudonimo VARCHAR(255) NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    apellido_paterno VARCHAR(255) NOT NULL,
    apellido_materno VARCHAR(255) NOT NULL
);

-- Tabla editoriales
CREATE TABLE IF NOT EXISTS editoriales (
    id_editorial BIGINT PRIMARY KEY NOT NULL,
    nombre VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla paises
CREATE TABLE IF NOT EXISTS paises (
    id_pais BIGINT PRIMARY KEY NOT NULL,
    pais_nombre VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla regiones
CREATE TABLE IF NOT EXISTS regiones (
    id_region BIGINT PRIMARY KEY NOT NULL,
    id_pais BIGINT NOT NULL,
    region_nombre VARCHAR(255) UNIQUE NOT NULL,
    FOREIGN KEY (id_pais) REFERENCES paises(id_pais)
);

-- Tabla provincias
CREATE TABLE IF NOT EXISTS provincias (
    id_provincia BIGINT PRIMARY KEY NOT NULL,
    region_id BIGINT NOT NULL,
    provincia_nombre VARCHAR(255) UNIQUE NOT NULL,
    FOREIGN KEY (region_id) REFERENCES regiones(id_region)
);

-- Tabla distritos
CREATE TABLE IF NOT EXISTS distritos (
    id_distrito BIGINT PRIMARY KEY NOT NULL,
    provincia_id BIGINT NOT NULL,
    distrito_nombre VARCHAR(255) UNIQUE NOT NULL,
    FOREIGN KEY (provincia_id) REFERENCES provincias(id_provincia)
);

-- Tabla direcciones_clientes
CREATE TABLE IF NOT EXISTS direcciones_clientes (
    id_direccion_cliente BIGINT PRIMARY KEY NOT NULL,
    distrito_id BIGINT NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    FOREIGN KEY (distrito_id) REFERENCES distritos(id_distrito)
);

-- Tabla tipo_prestamo
CREATE TABLE IF NOT EXISTS tipo_prestamo (
    id_tipo_prestamo BIGINT PRIMARY KEY NOT NULL,
    tipo_prestamo VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla tipo_documento
CREATE TABLE IF NOT EXISTS tipo_documento (
    id_tipo_documento BIGINT PRIMARY KEY NOT NULL,
    tipo_documento VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla rol_usuario
CREATE TABLE IF NOT EXISTS rol_usuario (
    id_rol_usuario BIGINT PRIMARY KEY NOT NULL,
    rol_usuario VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla categorias
CREATE TABLE IF NOT EXISTS categorias (
    id_categoria BIGINT PRIMARY KEY NOT NULL,
    categoria VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla niveles_educativos
CREATE TABLE IF NOT EXISTS niveles_educativos (
    id_nivel_educativo BIGINT PRIMARY KEY NOT NULL,
    nivel_educativo VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla generos
CREATE TABLE IF NOT EXISTS generos (
    id_genero BIGINT PRIMARY KEY NOT NULL,
    genero VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla estados_prestamos
CREATE TABLE IF NOT EXISTS estados_prestamos (
    id_estado_prestamo BIGINT PRIMARY KEY NOT NULL,
    estado_prestamo VARCHAR(255) UNIQUE NOT NULL
);

-- Tabla carnets
CREATE TABLE IF NOT EXISTS carnets (
    id_carnet BIGINT PRIMARY KEY NOT NULL,
    tipo_estado_id BIGINT NOT NULL,
    codigo VARCHAR(255) UNIQUE NOT NULL,
    fecha_emision DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_vencimiento DATE NOT NULL DEFAULT (fecha_emision + INTERVAL '1 YEAR'),
    FOREIGN KEY (tipo_estado_id) REFERENCES tipo_estado(id_tipo_estado),
    CONSTRAINT chk_fec_vencimiento CHECK (fecha_vencimiento > fecha_emision)
);

-- Tabla recursos_textuales
CREATE TABLE IF NOT EXISTS recursos_textuales (
    id_recurso_textual BIGINT PRIMARY KEY NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    fecha_publicacion DATE NOT NULL,
    numero_paginas SMALLINT NOT NULL,
    edicion SMALLINT DEFAULT 0,
    volumen SMALLINT DEFAULT 0,
    tipo_texto_id BIGINT NOT NULL,
    editorial_id BIGINT NOT NULL,
    FOREIGN KEY (tipo_texto_id) REFERENCES tipo_texto(id_tipo_texto),
    FOREIGN KEY (editorial_id) REFERENCES editoriales(id_editorial),
    CONSTRAINT chk_numero_paginas CHECK (numero_paginas > 0)
);

-- Tabla usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario BIGINT PRIMARY KEY NOT NULL,
    id_cliente BIGINT UNIQUE NOT NULL,
    rol_usuario_id BIGINT NOT NULL,
    tipo_documento_id BIGINT NOT NULL,
    documento VARCHAR(20) UNIQUE NOT NULL,
    psk VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (rol_usuario_id) REFERENCES rol_usuario(id_rol_usuario),
    FOREIGN KEY (tipo_documento_id) REFERENCES tipo_documento(id_tipo_documento),
    CONSTRAINT chk_documento CHECK (documento ~ '^\\d{8,20}$')
);

-- Tabla clientes
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente BIGINT PRIMARY KEY NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    apellido_paterno VARCHAR(255) NOT NULL,
    apellido_materno VARCHAR(255) NOT NULL,
    genero_id BIGINT NOT NULL,
    direccion_id BIGINT NOT NULL,
    telefono CHAR(9) UNIQUE NOT NULL,
    correo VARCHAR(255) UNIQUE NOT NULL,
    carnet_id BIGINT UNIQUE NOT NULL,
    nivel_educativo_id BIGINT NOT NULL,
    FOREIGN KEY (genero_id) REFERENCES generos(id_genero),
    FOREIGN KEY (direccion_id) REFERENCES direcciones_clientes(id_direccion_cliente),
    FOREIGN KEY (carnet_id) REFERENCES carnets(id_carnet),
    FOREIGN KEY (nivel_educativo_id) REFERENCES niveles_educativos(id_nivel_educativo),
    CONSTRAINT chk_cliente_correo CHECK (correo ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$'),
    CONSTRAINT chk_cliente_telefono CHECK (telefono ~ '^\\d{9}$')
);

-- Tabla recursos_textuales_codigos
CREATE TABLE IF NOT EXISTS recursos_textuales_codigos (
    id_recurso_textual_codigo BIGINT PRIMARY KEY NOT NULL,
    id_recurso_textual BIGINT NOT NULL,
    codigo VARCHAR(255) UNIQUE NOT NULL,
    disponible BOOLEAN NOT NULL,
    FOREIGN KEY (id_recurso_textual) REFERENCES recursos_textuales(id_recurso_textual)
);


-- Tabla prestamos
CREATE TABLE IF NOT EXISTS prestamos (
    id_prestamo BIGINT PRIMARY KEY NOT NULL,
    usuario_id BIGINT NOT NULL,
    recurso_textual_id BIGINT NOT NULL,
    tipo_prestamo_id BIGINT NOT NULL,
    estado_prestamo_id BIGINT NOT NULL,
    fecha_inicial DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_final DATE DEFAULT NULL,
    fecha_programada DATE NOT NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (recurso_textual_id) REFERENCES recursos_textuales(id_recurso_textual),
    FOREIGN KEY (tipo_prestamo_id) REFERENCES tipo_prestamo(id_tipo_prestamo),
    FOREIGN KEY (estado_prestamo_id) REFERENCES estados_prestamos(id_estado_prestamo),
    CONSTRAINT chk_fecha_programada CHECK (fecha_programada >= fecha_inicial),
    CONSTRAINT chk_fecha_final CHECK (fecha_final >= fecha_inicial OR fecha_final IS NULL)
);

-- Tabla recursos_textuales_autores
CREATE TABLE IF NOT EXISTS recursos_textuales_autores (
    id_recurso_textual BIGINT NOT NULL,
    id_autor BIGINT NOT NULL,
    PRIMARY KEY (id_recurso_textual, id_autor),
    FOREIGN KEY (id_recurso_textual) REFERENCES recursos_textuales(id_recurso_textual),
    FOREIGN KEY (id_autor) REFERENCES autores(id_autor)
);

-- Tabla registro_acciones_usuarios
CREATE TABLE IF NOT EXISTS registro_acciones_usuarios (
    usuario_id BIGINT NOT NULL,
    accion_id BIGINT NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT NOW(),
    direccion_ip VARCHAR(255) NOT NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id_usuario),
    CONSTRAINT chk_direccion_ip CHECK (
        direccion_ip ~ '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
            OR direccion_ip ~ '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))'
        )
);

-- Tabla categorias_recursos_textuales
CREATE TABLE IF NOT EXISTS categorias_recursos_textuales (
    id_recurso_textual BIGINT NOT NULL,
    id_categoria BIGINT NOT NULL,
    PRIMARY KEY (id_recurso_textual, id_categoria),
    FOREIGN KEY (id_recurso_textual) REFERENCES recursos_textuales(id_recurso_textual),
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
);