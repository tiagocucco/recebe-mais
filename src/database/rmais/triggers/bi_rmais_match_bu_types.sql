create or replace editionable trigger bi_rmais_match_bu_types before
    insert on rmais_match_bu_types
    for each row
begin
    if :new.id is null then
        select
            rmais_match_bu_types_seq.nextval
        into :new.id
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_match_bu_types enable;


-- sqlcl_snapshot {"hash":"5617a35e07b8878339b870119f5286c6984401b6","type":"TRIGGER","name":"BI_RMAIS_MATCH_BU_TYPES","schemaName":"RMAIS","sxml":""}