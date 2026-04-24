create or replace editionable trigger rmais_upload_log_t before
    insert on rmais_upload_log
    for each row
begin
    if :new.id is null then
        :new.id := rmais_upload_log_seq.nextval;
    end if;
end;
/

alter trigger rmais_upload_log_t enable;


-- sqlcl_snapshot {"hash":"1cf7ff703f5a8d784c30ea6d1c51b138efe142a0","type":"TRIGGER","name":"RMAIS_UPLOAD_LOG_T","schemaName":"RMAIS","sxml":""}