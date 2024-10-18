\c bd_Biblioteca;

-- Creación de vistas

CREATE VIEW vw_cliente_mayor_prestamos AS
SELECT COUNT(*) AS numero_prestamos, pres_usuario_id FROM tb_prestamo
GROUP BY pres_usuario_id
ORDER BY numero_prestamos DESC
LIMIT 1;

