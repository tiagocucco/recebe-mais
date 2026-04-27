-- liquibase formatted sql
-- changeset RMAIS:1777295651507 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_receiver_info.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_receiver_info.sql:null:bf8079175268c2374dd1c9baa83b64af6613a9fd:create

create global temporary table rmais_receiver_info (
    cnpj varchar2(100 byte),
    info clob,
    type varchar2(20 byte)
) on commit delete rows;

alter table rmais_receiver_info add check ( info is json ) enable;

