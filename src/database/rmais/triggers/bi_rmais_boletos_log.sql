create or replace editionable trigger bi_rmais_boletos_log before
    insert on rmais_boletos_log
    for each row
begin
    if :new.id is null then
        select
            rmais_boletos_log_seq.nextval
        into :new.id
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_boletos_log enable;


-- sqlcl_snapshot {"hash":"81573fc285781bcea62796362adb2523ea7404e8","type":"TRIGGER","name":"BI_RMAIS_BOLETOS_LOG","schemaName":"RMAIS","sxml":""}