begin
    dbms_scheduler.create_job(
        job_name            => '"REVALIDACAO_NFSE_DIGITADA"',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'BEGIN
  FOR NFS IN (SELECT EFD_HEADER_ID FROM RMAIS_EFD_HEADERS WHERE MODEL NOT IN (''55'',''57'',''67'') AND DOCUMENT_STATUS = ''N'' AND ROWNUM <= 3 ) LOOP

  EXECUTE IMMEDIATE 'Q'[ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,']'';

  RMAIS_PROCESS_PKG.MAIN(P_HEADER_ID => NFS.EFD_HEADER_ID  ,P_FLAG_AUTO =>''Y'', P_SEND_ERP => ''Y'');
  EXECUTE IMMEDIATE 'Q'[ALTER SESSION SET NLS_NUMERIC_CHARACTERS=',.']'';

 END LOOP;
EXCEPTION WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR (-20011,''ERRO AO REPROCESSAR DOCUMENTO ''||SQLERRM);
END;',
        start_date          => timestamp '2023-06-06 16:18:39.69828',
        repeat_interval     => 'FREQ=SECONDLY;INTERVAL=10',
        end_date            => null,
        job_class           => 'DEFAULT_JOB_CLASS',
        comments            => 'Processo de revalidação de notas digitadas',
        auto_drop           => false,
        number_of_arguments => 0
    );

    dbms_scheduler.set_attribute(
        name      => '"REVALIDACAO_NFSE_DIGITADA"',
        attribute => 'logging_level',
        value     => dbms_scheduler.logging_off
    );

    dbms_scheduler.set_attribute(
        name      => '"REVALIDACAO_NFSE_DIGITADA"',
        attribute => 'job_priority',
        value     => 3
    );

    dbms_scheduler.enable('"REVALIDACAO_NFSE_DIGITADA"');
end;
/


-- sqlcl_snapshot {"hash":"236dad381f5eb5443719e9a7f449f8255411ebc5","type":"JOB","name":"REVALIDACAO_NFSE_DIGITADA","schemaName":"RMAIS","sxml":""}