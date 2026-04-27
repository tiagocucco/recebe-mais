alter table tb_grupo_ac_dados_org
    add constraint tb_grupo_ac_dados_org_fk1
        foreign key ( id_grupo_acesso_dados )
            references tb_grupo_acesso_dados ( id_grupo_acesso_dados )
                on delete cascade
        enable;


-- sqlcl_snapshot {"hash":"225f1f732234d97f144bb484e03e8944bec3854a","type":"REF_CONSTRAINT","name":"TB_GRUPO_AC_DADOS_ORG_FK1","schemaName":"RMAIS","sxml":""}