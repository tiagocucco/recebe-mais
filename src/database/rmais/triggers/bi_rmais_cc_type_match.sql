create or replace editionable trigger bi_rmais_cc_type_match before
    insert on rmais_cc_type_match
    for each row
begin
    if :new.id is null then
        select
            rmais_cc_type_match_seq.nextval
        into :new.id
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_cc_type_match enable;


-- sqlcl_snapshot {"hash":"9ae97365d34b3d6a50d78f0bca0a9b9b7c150b09","type":"TRIGGER","name":"BI_RMAIS_CC_TYPE_MATCH","schemaName":"RMAIS","sxml":""}