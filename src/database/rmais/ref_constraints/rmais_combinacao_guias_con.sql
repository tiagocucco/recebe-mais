alter table rmais_combinacao_guias
    add constraint rmais_combinacao_guias_con
        foreign key ( fk_site )
            references rmais_suplier_site_guias ( id_site )
        enable;


-- sqlcl_snapshot {"hash":"554f30def65bd84f1dd5d6a6d59cfea51053d887","type":"REF_CONSTRAINT","name":"RMAIS_COMBINACAO_GUIAS_CON","schemaName":"RMAIS","sxml":""}