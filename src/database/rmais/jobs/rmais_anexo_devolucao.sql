begin
    dbms_scheduler.create_job(
        job_name            => '"RMAIS_ANEXO_DEVOLUCAO"',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'BEGIN
    RMAIS_PROCESS_PKG.INTEGRAR_ANEXO_DEVOLUCAO;
END;',
        start_date          => timestamp '2023-04-10 15:40:30.005016',
        repeat_interval     => 'FREQ=MINUTELY;INTERVAL=5;BYDAY=MON,TUE,WED,THU,FRI,SAT,SUN',
        end_date            => null,
        job_class           => 'DEFAULT_JOB_CLASS',
        comments            => null,
        auto_drop           => false,
        number_of_arguments => 0
    );

    dbms_scheduler.set_attribute(
        name      => '"RMAIS_ANEXO_DEVOLUCAO"',
        attribute => 'logging_level',
        value     => dbms_scheduler.logging_off
    );

    dbms_scheduler.set_attribute(
        name      => '"RMAIS_ANEXO_DEVOLUCAO"',
        attribute => 'job_priority',
        value     => 3
    );

    dbms_scheduler.enable('"RMAIS_ANEXO_DEVOLUCAO"');
end;
/


-- sqlcl_snapshot {"hash":"4a9b3eafee3a6be935c2fc16ad787c2816695a5d","type":"JOB","name":"RMAIS_ANEXO_DEVOLUCAO","schemaName":"RMAIS","sxml":""}