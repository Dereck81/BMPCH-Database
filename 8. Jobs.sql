\c db_biblioteca;

-- IMPORTANT: You need to have pg_cron installed

CREATE EXTENSION pg_cron;

SELECT cron.schedule(
               'job_actualizar_carnets',
               schedule => '0 0 * * *',
               command => 'SELECT fn_actualizar_carnets();'
);

SELECT cron.schedule(
               'job_limpiar_registro_jobs',
               schedule => '0 0 * * *',
               command => $$DELETE
    FROM cron.job_run_details
    WHERE end_time < now() - interval '7 days'$$
);

SELECT cron.schedule(
               'job_actualizar_prestamos',
               schedule => '0 0 * * *',
               command => 'SELECT fn_actualizar_prestamos();'
);

UPDATE cron.job SET nodename = ''
WHERE database = 'db_biblioteca' AND username = 'postgres';

-- SELECT * FROM cron.job;

-- SELECT * FROM cron.job_run_details;

-- SELECT cron.unschedule(jobid);