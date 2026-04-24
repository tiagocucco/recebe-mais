create or replace editionable trigger trg_rmais_certificado_delete after
    delete on rmais_certificado_digital
    for each row
begin
    insert into rmais_certificado_audit_log (
        id,
        action_type,
        deleted_at,
        deleted_by,
        cert_filename,
        receiver_name,
        obs
    ) values ( :old.id,
               'DELETE',
               sysdate,
               nvl(
                   v('APP_USER'),
                   user
               ),
               :old.cert_filename,
               :old.receiver_name,
               :old.obs );

end;
/

alter trigger trg_rmais_certificado_delete enable;


-- sqlcl_snapshot {"hash":"37f6d0249ff709d1b143cb21dca4856379cf7096","type":"TRIGGER","name":"TRG_RMAIS_CERTIFICADO_DELETE","schemaName":"RMAIS","sxml":""}