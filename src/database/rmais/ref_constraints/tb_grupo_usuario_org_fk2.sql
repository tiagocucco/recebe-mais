alter table tb_grupo_usuario_org
    add constraint tb_grupo_usuario_org_fk2
        foreign key ( id_org )
            references rmais_organizations ( id )
                on delete cascade
        enable;


-- sqlcl_snapshot {"hash":"9e4702a07abd07ab2874aa086fac53bec12ba94a","type":"REF_CONSTRAINT","name":"TB_GRUPO_USUARIO_ORG_FK2","schemaName":"RMAIS","sxml":""}