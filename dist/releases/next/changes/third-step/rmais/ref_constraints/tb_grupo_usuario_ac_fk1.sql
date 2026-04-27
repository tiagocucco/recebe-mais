-- liquibase formatted sql
-- changeset RMAIS:1777295649754 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\tb_grupo_usuario_ac_fk1.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/tb_grupo_usuario_ac_fk1.sql:null:48402b3ec7520949cc5197dfbb996485f036a5d0:create

alter table tb_grupo_usuario_ac
    add constraint tb_grupo_usuario_ac_fk1
        foreign key ( id_grupo_usuario )
            references tb_grupo_usuario ( id_grupo_usuario )
        enable;

