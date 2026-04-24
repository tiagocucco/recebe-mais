create or replace editionable trigger rmais_log_passagem_por_email_t before
    insert on rmais_log_passagem_por_email
    for each row
begin
    null;
    delete from rmais_log_passagem_por_email
    where
            efd_header_id = :new.efd_header_id
        and nvl(titulo, '-1') = nvl(:new.titulo,
                                    '-1');

end;
/

alter trigger rmais_log_passagem_por_email_t enable;


-- sqlcl_snapshot {"hash":"559d40c0f54db698a2dda3f8bef78391c45f23c7","type":"TRIGGER","name":"RMAIS_LOG_PASSAGEM_POR_EMAIL_T","schemaName":"RMAIS","sxml":""}