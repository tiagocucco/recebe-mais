-- liquibase formatted sql
-- changeset RMAIS:1777295649733 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\tb_grupo_ac_dados_org_fk1.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/tb_grupo_ac_dados_org_fk1.sql:null:225f1f732234d97f144bb484e03e8944bec3854a:create

alter table tb_grupo_ac_dados_org
    add constraint tb_grupo_ac_dados_org_fk1
        foreign key ( id_grupo_acesso_dados )
            references tb_grupo_acesso_dados ( id_grupo_acesso_dados )
                on delete cascade
        enable;

