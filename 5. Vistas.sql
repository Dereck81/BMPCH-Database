USE BMPCH;

-- VERIFICAR VISTA
/*
CREATE VIEW total_prestamos_devueltos_prestados AS
SELECT COUNT(devuelto) AS total_devueltos, COUNT(id_prestamo) AS total_prestados
FROM prestamos;*/

-- VERIFICAR VISTA
CREATE VIEW v_cliente_mayor_prestamos AS
SELECT COUNT(*) AS numero_prestamos, usuario_id FROM prestamos
GROUP BY usuario_id
ORDER BY numero_prestamos DESC
LIMIT 1;

