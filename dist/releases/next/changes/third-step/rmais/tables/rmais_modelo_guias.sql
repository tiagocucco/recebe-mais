-- liquibase formatted sql
-- changeset RMAIS:1777295651396 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_modelo_guias.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_modelo_guias.sql:null:287c4bfa8f1fe95f87ea186b66101eb26c7e6d7b:create

create table rmais_modelo_guias (
    modelo        varchar2(40 char),
    context       varchar2(100 char),
    display_value varchar2(100 char),
    cod_guia      varchar2(4 byte)
);

