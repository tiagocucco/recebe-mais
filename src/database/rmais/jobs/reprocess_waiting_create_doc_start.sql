begin
    dbms_scheduler.create_job(
        job_name            => '"REPROCESS_WAITING_CREATE_DOC_START"',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'BEGIN DELETE RMAIS_REPROCESS_CTRL A WHERE A.FLAG_REPROCESS_CTRL = 1;COMMIT; END;',
        start_date          => timestamp '2023-01-15 15:57:47.0',
        repeat_interval     => 'FREQ=HOURLY;INTERVAL=2',
        end_date            => null,
        job_class           => 'DEFAULT_JOB_CLASS',
        comments            => null,
        auto_drop           => true,
        number_of_arguments => 0
    );

    dbms_scheduler.set_attribute(
        name      => '"REPROCESS_WAITING_CREATE_DOC_START"',
        attribute => 'logging_level',
        value     => dbms_scheduler.logging_off
    );

    dbms_scheduler.set_attribute(
        name      => '"REPROCESS_WAITING_CREATE_DOC_START"',
        attribute => 'job_priority',
        value     => 3
    );

    dbms_scheduler.enable('"REPROCESS_WAITING_CREATE_DOC_START"');
end;
/


-- sqlcl_snapshot {"hash":"22a346a999ca21000dc9a5dadefaade9f12cca0b","type":"JOB","name":"REPROCESS_WAITING_CREATE_DOC_START","schemaName":"RMAIS","sxml":""}