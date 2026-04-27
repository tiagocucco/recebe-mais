-- liquibase formatted sql
-- changeset RMAIS:1777295649787 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\tb_grupo_usuario_org_fk2.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/tb_grupo_usuario_org_fk2.sql:null:9e4702a07abd07ab2874aa086fac53bec12ba94a:create

alter table tb_grupo_usuario_org
    add constraint tb_grupo_usuario_org_fk2
        foreign key ( id_org )
            references rmais_organizations ( id )
                on delete cascade
        enable;

