alter table tb_grupo_ac_dados_org
    add constraint tb_grupo_ac_dados_org_fk2
        foreign key ( id_org )
            references rmais_organizations ( id )
                on delete cascade
        enable;


-- sqlcl_snapshot {"hash":"fcf7c05a7d1768d99063205dd179e8ca85dd2d2b","type":"REF_CONSTRAINT","name":"TB_GRUPO_AC_DADOS_ORG_FK2","schemaName":"RMAIS","sxml":""}