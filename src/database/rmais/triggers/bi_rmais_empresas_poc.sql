create or replace editionable trigger bi_rmais_empresas_poc before
    insert on rmais_empresas_poc
    for each row
begin
    if :new.id is null then
        select
            rmais_empresas_poc_seq.nextval
        into :new.id
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_empresas_poc enable;


-- sqlcl_snapshot {"hash":"ffd0b169a593ee80dc38f24ba88a2b8bf5a73b5d","type":"TRIGGER","name":"BI_RMAIS_EMPRESAS_POC","schemaName":"RMAIS","sxml":""}