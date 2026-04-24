create or replace editionable trigger bi_rmais_conf_orig_doc before
    insert on test_conf_orig_doc
    for each row
begin
    if :new.id_conf_orig_doc is null then
        select
            rmais_conf_orig_doc_seq.nextval
        into :new.id_conf_orig_doc
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_conf_orig_doc enable;


-- sqlcl_snapshot {"hash":"62cdfef844e2b8449bd64ee7adfe0b570aedc41c","type":"TRIGGER","name":"BI_RMAIS_CONF_ORIG_DOC","schemaName":"RMAIS","sxml":""}