create or replace editionable trigger rmais_combinacao_guias_t before
    insert on rmais_combinacao_guias
    for each row
begin
    if :new.id_combinacao is null then
        :new.id_combinacao := rmais_combinacao_guias_seq.nextval;
    end if;
end;
/

alter trigger rmais_combinacao_guias_t enable;


-- sqlcl_snapshot {"hash":"598ef01afcb506345acc945bf4c42f5ee1a072ac","type":"TRIGGER","name":"RMAIS_COMBINACAO_GUIAS_T","schemaName":"RMAIS","sxml":""}