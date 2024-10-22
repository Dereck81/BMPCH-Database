#!/usr/bin/bash

export PGPASSWORD="devroot"

scripts=(\
    "2. Funciones/2.1 Funciones para triggers.sql"\
    "2. Funciones/2.2 Funciones para jobs.sql"\
    "2. Funciones/2.3 Funciones.sql"\
    "3. Triggers/3. Triggers.sql"\
    "4. Procedimientos almacenados/4. Procedimientos almacenados.sql"\
    "5. Vistas.sql"\
    "6. Usuarios y roles.sql"\
    "7. Llenado general AAAA-MM-DD.sql"\
    "8. Jobs.sql"
)

# Creando bd_biblioteca

psql -U postgres -h localhost -f "1. Diseño y creacion de base de datos/1. Diseño y creacion de base de datos.sql";

for script in "${scripts[@]}"; do
    echo "Ejecutando script ($script)...";
    psql -U postgres -h localhost -d db_biblioteca -f "$script";
done

unset PGPASSWORD