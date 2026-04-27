-- liquibase formatted sql
-- changeset RMAIS:1777295649744 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\tb_grupo_ac_dados_org_fk2.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/tb_grupo_ac_dados_org_fk2.sql:null:fcf7c05a7d1768d99063205dd179e8ca85dd2d2b:create

alter table tb_grupo_ac_dados_org
    add constraint tb_grupo_ac_dados_org_fk2
        foreign key ( id_org )
            references rmais_organizations ( id )
                on delete cascade
        enable;

