alter table tb_grupo_usuario_org
    add constraint tb_grupo_usuario_org_fk1
        foreign key ( id_grupo_usuario )
            references tb_grupo_usuario ( id_grupo_usuario )
                on delete cascade
        enable;


-- sqlcl_snapshot {"hash":"a589b7b69f7388468d71a86b249a0196aa63f058","type":"REF_CONSTRAINT","name":"TB_GRUPO_USUARIO_ORG_FK1","schemaName":"RMAIS","sxml":""}