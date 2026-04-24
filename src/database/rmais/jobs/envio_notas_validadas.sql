begin
    dbms_scheduler.create_job(
        job_name            => '"ENVIO_NOTAS_VALIDADAS"',
        job_type            => 'PLSQL_BLOCK',
        job_action          => 'DECLARE
L_MODEL          VARCHAR2(100);
L_RET            VARCHAR2(100);
L_FLAG_RETENTION VARCHAR2(100);
L_FLAG_NF_OP     VARCHAR2(100);
BEGIN
FOR NFS IN (SELECT * 
              FROM (SELECT EFD_HEADER_ID , MODEL , DEFINE_DET_ENTRY_TYPE
                      FROM RMAIS_EFD_HEADERS RMH
                     WHERE RMH.DOCUMENT_STATUS = ''V''
                       AND RMH.DEFINE_DET_ENTRY_TYPE IS NOT NULL
                       AND RMH.DEFINE_DET_ENTRY_TYPE <> ''ITEM_DEFAULT'' 
                       AND RMH.LAST_UPDATE_DATE <= SYSDATE-(1/24/60)*30
                       /*AND EFD_HEADER_ID = 523661**/
                       ORDER BY 1 ASC) 
          WHERE ROWNUM <= 5)
LOOP
  --
  SELECT  MAX(A.FLAG_RETENTION),
                    NVL(MAX(A.FLAG_NF_OP),''Y'')
            INTO    L_FLAG_RETENTION,
                    L_FLAG_NF_OP
            FROM    RMAIS_DEFINE_DET_ENTRY A
            WHERE   A.MODEL = NFS.MODEL
            AND     A.TYPE = NFS.DEFINE_DET_ENTRY_TYPE;
  --
  RMAIS_PROCESS_PKG.SEND_INVOICE_V2(NFS.EFD_HEADER_ID, L_FLAG_RETENTION);
  --
END LOOP;               
END; ',
        start_date          => timestamp '2023-06-07 15:31:42.738337',
        repeat_interval     => 'FREQ=SECONDLY;INTERVAL=20',
        end_date            => null,
        job_class           => 'DEFAULT_JOB_CLASS',
        comments            => null,
        auto_drop           => false,
        number_of_arguments => 0
    );

    dbms_scheduler.set_attribute(
        name      => '"ENVIO_NOTAS_VALIDADAS"',
        attribute => 'logging_level',
        value     => dbms_scheduler.logging_off
    );

    dbms_scheduler.set_attribute(
        name      => '"ENVIO_NOTAS_VALIDADAS"',
        attribute => 'job_priority',
        value     => 3
    );

    dbms_scheduler.enable('"ENVIO_NOTAS_VALIDADAS"');
end;
/


-- sqlcl_snapshot {"hash":"a4efa0a9818c30dd68bd4e2342c95146a16e271a","type":"JOB","name":"ENVIO_NOTAS_VALIDADAS","schemaName":"RMAIS","sxml":""}