alter table tb_usuario
    add constraint tb_usuario_fk1
        foreign key ( id_grupo_acesso_dados )
            references tb_grupo_acesso_dados ( id_grupo_acesso_dados )
        enable;


-- sqlcl_snapshot {"hash":"ff823da4aee58899e3112e759466e08e594a7fe1","type":"REF_CONSTRAINT","name":"TB_USUARIO_FK1","schemaName":"RMAIS","sxml":""}