begin
    dbms_scheduler.create_job(
        job_name            => '"REPROCESS_WAITING_CREATE_DOC"',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'BEGIN RMAIS_PROCESS_PKG.REPROCESS_WAITING_CRETE_DOC_RUN; END;',
        start_date          => timestamp '2023-01-15 15:55:33.0',
        repeat_interval     => 'FREQ=SECONDLY;INTERVAL=10',
        end_date            => null,
        job_class           => 'DEFAULT_JOB_CLASS',
        comments            => null,
        auto_drop           => true,
        number_of_arguments => 0
    );

    dbms_scheduler.set_attribute(
        name      => '"REPROCESS_WAITING_CREATE_DOC"',
        attribute => 'logging_level',
        value     => dbms_scheduler.logging_off
    );

    dbms_scheduler.set_attribute(
        name      => '"REPROCESS_WAITING_CREATE_DOC"',
        attribute => 'job_priority',
        value     => 3
    );

end;
/


-- sqlcl_snapshot {"hash":"ab2f577b347fae72efc1dbec5717fbf7a40d99c0","type":"JOB","name":"REPROCESS_WAITING_CREATE_DOC","schemaName":"RMAIS","sxml":""}