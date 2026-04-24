create or replace editionable trigger rmais_suplier_site_guias_t before
    insert on rmais_suplier_site_guias
    for each row
begin
    if :new.id_site is null then
        :new.id_site := rmais_suplier_site_guias_seq.nextval;
    end if;
end;
/

alter trigger rmais_suplier_site_guias_t enable;


-- sqlcl_snapshot {"hash":"e2393f9ef5f53f5ffed719e215db3faf616c6c80","type":"TRIGGER","name":"RMAIS_SUPLIER_SITE_GUIAS_T","schemaName":"RMAIS","sxml":""}