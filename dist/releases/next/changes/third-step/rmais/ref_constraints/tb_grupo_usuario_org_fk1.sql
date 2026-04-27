-- liquibase formatted sql
-- changeset RMAIS:1777295649778 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\tb_grupo_usuario_org_fk1.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/tb_grupo_usuario_org_fk1.sql:null:a589b7b69f7388468d71a86b249a0196aa63f058:create

alter table tb_grupo_usuario_org
    add constraint tb_grupo_usuario_org_fk1
        foreign key ( id_grupo_usuario )
            references tb_grupo_usuario ( id_grupo_usuario )
                on delete cascade
        enable;

