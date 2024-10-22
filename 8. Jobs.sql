\c db_biblioteca;

-- IMPORTANT: You need to have pg_cron installed

CREATE EXTENSION pg_cron;

SELECT cron.schedule('job_actualizar_carnets',
                     '0 0 * * *',  -- Ejecutar todos los días a las 12:00 am
                     'SELECT fn_actualizar_carnets();');
