-- liquibase formatted sql
-- changeset RMAIS:1777295649695 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\rmais_combinacao_guias_con.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/rmais_combinacao_guias_con.sql:null:554f30def65bd84f1dd5d6a6d59cfea51053d887:create

alter table rmais_combinacao_guias
    add constraint rmais_combinacao_guias_con
        foreign key ( fk_site )
            references rmais_suplier_site_guias ( id_site )
        enable;

