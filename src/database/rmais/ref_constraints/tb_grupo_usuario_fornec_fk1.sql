alter table tb_grupo_usuario_fornec
    add constraint tb_grupo_usuario_fornec_fk1
        foreign key ( id_grupo_usuario )
            references tb_grupo_usuario ( id_grupo_usuario )
                on delete cascade
        enable;


-- sqlcl_snapshot {"hash":"b61f2501d022535dce8e2515a4495663e84d1f4d","type":"REF_CONSTRAINT","name":"TB_GRUPO_USUARIO_FORNEC_FK1","schemaName":"RMAIS","sxml":""}