-- liquibase formatted sql
-- changeset RMAIS:1777295651267 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_issuer_info.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_issuer_info.sql:null:c6c3f6e28d1128bc04ae9d1b6e50d412cf00ac96:create

create global temporary table rmais_issuer_info (
    cnpj     varchar2(100 byte),
    docs     clob,
    info     clob,
    receiver varchar2(20 byte)
) on commit delete rows;

alter table rmais_issuer_info add check ( docs is json ) enable;

alter table rmais_issuer_info add check ( info is json ) enable;

