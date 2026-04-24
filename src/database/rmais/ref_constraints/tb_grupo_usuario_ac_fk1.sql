alter table tb_grupo_usuario_ac
    add constraint tb_grupo_usuario_ac_fk1
        foreign key ( id_grupo_usuario )
            references tb_grupo_usuario ( id_grupo_usuario )
        enable;


-- sqlcl_snapshot {"hash":"48402b3ec7520949cc5197dfbb996485f036a5d0","type":"REF_CONSTRAINT","name":"TB_GRUPO_USUARIO_AC_FK1","schemaName":"RMAIS","sxml":""}