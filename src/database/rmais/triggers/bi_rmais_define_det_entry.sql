create or replace editionable trigger bi_rmais_define_det_entry before
    insert on rmais_define_det_entry
    for each row
begin
    if :new.id is null then
        select
            rmais_define_det_entry_seq.nextval
        into :new.id
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_define_det_entry enable;


-- sqlcl_snapshot {"hash":"84e51f5d683f334cf4ae44f3df375945ff917107","type":"TRIGGER","name":"BI_RMAIS_DEFINE_DET_ENTRY","schemaName":"RMAIS","sxml":""}