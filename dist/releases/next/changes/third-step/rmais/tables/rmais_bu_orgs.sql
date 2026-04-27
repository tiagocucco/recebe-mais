-- liquibase formatted sql
-- changeset RMAIS:1777295650382 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_bu_orgs.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_bu_orgs.sql:null:93a5b4d40cb4282b747425f9d578623c8f560096:create

create table rmais_bu_orgs (
    cnpj_bu       varchar2(44 byte),
    cnpj_lru      varchar2(44 byte),
    creation_date date
);

