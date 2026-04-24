create or replace editionable trigger bi_rmais_define_roles_entry before
    insert on rmais_define_roles_entry
    for each row
begin
    if :new.id is null then
        select
            rmais_define_roles_entry_seq.nextval
        into :new.id
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_define_roles_entry enable;


-- sqlcl_snapshot {"hash":"30a3528f3ccb61b61f55af5b55e79637fc0f66a4","type":"TRIGGER","name":"BI_RMAIS_DEFINE_ROLES_ENTRY","schemaName":"RMAIS","sxml":""}