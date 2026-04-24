begin
    dbms_scheduler.create_job(
        job_name            => '"REPROCESS_DOCS_ESPECIF"',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'BEGIN
 FOR Y IN (SELECT EFD_HEADER_ID
  FROM RMAIS_EFD_HEADERS RMH
  WHERE DOCUMENT_STATUS = ''AC'' 
  AND RMH.ORG_ID IS NULL
  AND ROWNUM <= 3
  AND NOT EXISTS (SELECT 1 FROM RMAIS_REPROCESS_CTRL RP WHERE RP.FLAG_REPROCESS_CTRL = 11 AND RP.EFD_HEADER_ID = RMH.EFD_HEADER_ID )) LOOP
  INSERT INTO RMAIS_REPROCESS_CTRL VALUES (11,Y.EFD_HEADER_ID);

 RMAIS_PROCESS_PKG.MAIN(P_HEADER_ID => Y.EFD_HEADER_ID--:P7_EFD_HEADER_ID
                          ,P_FLAG_AUTO => ''Y''
                          , P_SEND_ERP => ''Y'');
 END LOOP;
END;',
        start_date          => null,
        repeat_interval     => 'FREQ=SECONDLY;INTERVAL=5',
        end_date            => timestamp '2023-02-09 03:00:00.0',
        job_class           => 'DEFAULT_JOB_CLASS',
        comments            => null,
        auto_drop           => false,
        number_of_arguments => 0
    );

    dbms_scheduler.set_attribute(
        name      => '"REPROCESS_DOCS_ESPECIF"',
        attribute => 'logging_level',
        value     => dbms_scheduler.logging_off
    );

    dbms_scheduler.set_attribute(
        name      => '"REPROCESS_DOCS_ESPECIF"',
        attribute => 'job_priority',
        value     => 3
    );

end;
/


-- sqlcl_snapshot {"hash":"a26d25341175f452c03522306ad57e3b4cc7d047","type":"JOB","name":"REPROCESS_DOCS_ESPECIF","schemaName":"RMAIS","sxml":""}