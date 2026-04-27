-- liquibase formatted sql
-- changeset RMAIS:1777295649797 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\tb_usuario_fk1.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/tb_usuario_fk1.sql:null:ff823da4aee58899e3112e759466e08e594a7fe1:create

alter table tb_usuario
    add constraint tb_usuario_fk1
        foreign key ( id_grupo_acesso_dados )
            references tb_grupo_acesso_dados ( id_grupo_acesso_dados )
        enable;

