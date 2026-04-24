alter table tb_grupo_ac_dados_fornec
    add constraint tb_grupo_ac_dados_fornec_fk1
        foreign key ( id_grupo_acesso_dados )
            references tb_grupo_acesso_dados ( id_grupo_acesso_dados )
                on delete cascade
        enable;


-- sqlcl_snapshot {"hash":"ff804fb65571f4922c484fe0c923ae4e24daa654","type":"REF_CONSTRAINT","name":"TB_GRUPO_AC_DADOS_FORNEC_FK1","schemaName":"RMAIS","sxml":""}