-- liquibase formatted sql
-- changeset RMAIS:1777295649769 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\tb_grupo_usuario_fornec_fk1.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/tb_grupo_usuario_fornec_fk1.sql:null:b61f2501d022535dce8e2515a4495663e84d1f4d:create

alter table tb_grupo_usuario_fornec
    add constraint tb_grupo_usuario_fornec_fk1
        foreign key ( id_grupo_usuario )
            references tb_grupo_usuario ( id_grupo_usuario )
                on delete cascade
        enable;

