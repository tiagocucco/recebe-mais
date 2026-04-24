begin
    dbms_scheduler.create_job(
        job_name            => '"RMAIS_REPROCESS_PROGRAMADO"',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'BEGIN
FOR NFS IN (SELECT EFD_HEADER_ID FROM (
            SELECT * FROM RMAIS_EFD_HEADERS 
            WHERE DOCUMENT_STATUS IN (''N'', ''I'')
            ORDER BY 1 ASC)
            WHERE ROWNUM <= 5
            )
LOOP
BEGIN
EXECUTE IMMEDIATE 'Q'[ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,']'';
 RMAIS_GLOBAL_PKG.G_ENABLE_LOG := NULL;
 RMAIS_PROCESS_PKG.MAIN(P_HEADER_ID =>  NFS.EFD_HEADER_ID
                         ,P_FLAG_AUTO => ''Y''
                        , P_SEND_ERP => ''Y''
                          );
END;
END LOOP;
END;
',
        start_date          => null,
        repeat_interval     => 'FREQ=SECONDLY;INTERVAL=5',
        end_date            => null,
        job_class           => 'DEFAULT_JOB_CLASS',
        comments            => null,
        auto_drop           => false,
        number_of_arguments => 0
    );

    dbms_scheduler.set_attribute(
        name      => '"RMAIS_REPROCESS_PROGRAMADO"',
        attribute => 'logging_level',
        value     => dbms_scheduler.logging_off
    );

    dbms_scheduler.set_attribute(
        name      => '"RMAIS_REPROCESS_PROGRAMADO"',
        attribute => 'job_priority',
        value     => 3
    );

end;
/


-- sqlcl_snapshot {"hash":"329aa6e09149a8be15b748e995bd60cd623d9ca1","type":"JOB","name":"RMAIS_REPROCESS_PROGRAMADO","schemaName":"RMAIS","sxml":""}