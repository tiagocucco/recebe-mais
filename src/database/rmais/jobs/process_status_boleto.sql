begin
    dbms_scheduler.create_job(
        job_name            => '"PROCESS_STATUS_BOLETO"',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'BEGIN RMAIS_PROCESS_PKG.STATUS_BOLETO(); COMMIT; END;',
        start_date          => timestamp '2022-12-28 08:48:51.0',
        repeat_interval     => 'FREQ=MINUTELY;INTERVAL=2',
        end_date            => null,
        job_class           => 'DEFAULT_JOB_CLASS',
        comments            => null,
        auto_drop           => true,
        number_of_arguments => 0
    );

    dbms_scheduler.set_attribute(
        name      => '"PROCESS_STATUS_BOLETO"',
        attribute => 'logging_level',
        value     => dbms_scheduler.logging_off
    );

    dbms_scheduler.set_attribute(
        name      => '"PROCESS_STATUS_BOLETO"',
        attribute => 'job_priority',
        value     => 3
    );

    dbms_scheduler.enable('"PROCESS_STATUS_BOLETO"');
end;
/


-- sqlcl_snapshot {"hash":"5c6e427caf8c065aa0492dd571aec708e0d29935","type":"JOB","name":"PROCESS_STATUS_BOLETO","schemaName":"RMAIS","sxml":""}