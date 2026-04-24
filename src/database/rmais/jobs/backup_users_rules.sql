begin
    dbms_scheduler.create_job(
        job_name            => '"BACKUP_USERS_RULES"',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'BEGIN RMAIS_MANAGEMENT_TOOL.PRC_BACKUP_USER_RULES; END;',
        start_date          => timestamp '2023-09-18 18:30:00.0',
        repeat_interval     => 'FREQ=DAILY',
        end_date            => null,
        job_class           => 'DEFAULT_JOB_CLASS',
        comments            => null,
        auto_drop           => false,
        number_of_arguments => 0
    );

    dbms_scheduler.set_attribute(
        name      => '"BACKUP_USERS_RULES"',
        attribute => 'logging_level',
        value     => dbms_scheduler.logging_off
    );

    dbms_scheduler.set_attribute(
        name      => '"BACKUP_USERS_RULES"',
        attribute => 'job_priority',
        value     => 3
    );

    dbms_scheduler.enable('"BACKUP_USERS_RULES"');
end;
/


-- sqlcl_snapshot {"hash":"90304021a1003f78f30eab910dda9d0221a7e38e","type":"JOB","name":"BACKUP_USERS_RULES","schemaName":"RMAIS","sxml":""}