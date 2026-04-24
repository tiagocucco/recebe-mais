create or replace editionable trigger rmais_cfop_out_in_t before
    insert on rmais_cfop_out_in
    for each row
begin
    if :new.id is null then
        :new.id := rmais_cfop_out_in_seq.nextval;
    end if;
end;
/

alter trigger rmais_cfop_out_in_t enable;


-- sqlcl_snapshot {"hash":"dd152fdea2d2f2eb65a29ef34053056faaccc25c","type":"TRIGGER","name":"RMAIS_CFOP_OUT_IN_T","schemaName":"RMAIS","sxml":""}