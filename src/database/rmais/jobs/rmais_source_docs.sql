begin
    dbms_scheduler.create_job(
        job_name            => '"RMAIS_SOURCE_DOCS"',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'BEGIN
    EXECUTE IMMEDIATE ''ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''.,'''';
    XXRMAIS_UTIL_V2_PKG.SOURCE_DOCS();
    EXCEPTION WHEN OTHERS THEN
    NULL;
END;
------------------------------------------------------------------------
--EXECUÇÃO DA POC EM PARALELO.
BEGIN
    RMAIS_UTIL_PKG_POC.SOURCE_DOCS();
    EXCEPTION WHEN OTHERS THEN
    NULL;
END;',
        start_date          => timestamp '2023-08-22 19:08:45.184644',
        repeat_interval     => 'FREQ=MINUTELY',
        end_date            => null,
        job_class           => 'DEFAULT_JOB_CLASS',
        comments            => 'Processamentos de documentos XML enviados na API',
        auto_drop           => false,
        number_of_arguments => 0
    );

    dbms_scheduler.set_attribute(
        name      => '"RMAIS_SOURCE_DOCS"',
        attribute => 'logging_level',
        value     => dbms_scheduler.logging_off
    );

    dbms_scheduler.set_attribute(
        name      => '"RMAIS_SOURCE_DOCS"',
        attribute => 'job_priority',
        value     => 3
    );

    dbms_scheduler.enable('"RMAIS_SOURCE_DOCS"');
end;
/


-- sqlcl_snapshot {"hash":"ea13ae2e2e5153b9932a05484b4280a15e37fb39","type":"JOB","name":"RMAIS_SOURCE_DOCS","schemaName":"RMAIS","sxml":""}