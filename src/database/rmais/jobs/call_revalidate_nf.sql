begin
    dbms_scheduler.create_job(
        job_name            => '"CALL_REVALIDATE_NF"',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'BEGIN RMAIS_JOB_REVALIDAR; END;',
        start_date          => timestamp '2023-06-26 12:39:39.0',
        repeat_interval     => 'FREQ=SECONDLY;INTERVAL=180',
        end_date            => null,
        job_class           => 'DEFAULT_JOB_CLASS',
        comments            => null,
        auto_drop           => true,
        number_of_arguments => 0
    );

    dbms_scheduler.set_attribute(
        name      => '"CALL_REVALIDATE_NF"',
        attribute => 'logging_level',
        value     => dbms_scheduler.logging_off
    );

    dbms_scheduler.set_attribute(
        name      => '"CALL_REVALIDATE_NF"',
        attribute => 'job_priority',
        value     => 3
    );

    dbms_scheduler.enable('"CALL_REVALIDATE_NF"');
end;
/


-- sqlcl_snapshot {"hash":"86d77fd794d05aed5fc698066e8fe1924c849d72","type":"JOB","name":"CALL_REVALIDATE_NF","schemaName":"RMAIS","sxml":""}