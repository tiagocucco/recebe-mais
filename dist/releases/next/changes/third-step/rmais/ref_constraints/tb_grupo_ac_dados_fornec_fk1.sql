-- liquibase formatted sql
-- changeset RMAIS:1777295649724 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\tb_grupo_ac_dados_fornec_fk1.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/tb_grupo_ac_dados_fornec_fk1.sql:null:ff804fb65571f4922c484fe0c923ae4e24daa654:create

alter table tb_grupo_ac_dados_fornec
    add constraint tb_grupo_ac_dados_fornec_fk1
        foreign key ( id_grupo_acesso_dados )
            references tb_grupo_acesso_dados ( id_grupo_acesso_dados )
                on delete cascade
        enable;

