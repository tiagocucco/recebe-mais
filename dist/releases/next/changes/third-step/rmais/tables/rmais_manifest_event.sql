-- liquibase formatted sql
-- changeset RMAIS:1777295651361 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_manifest_event.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_manifest_event.sql:null:0496dcda89147e337d4a4af3ca31120ab2c12bb3:create

create table rmais_manifest_event (
    danfe         varchar2(50 byte),
    status        varchar2(1 byte),
    log           clob,
    creation_date date,
    tipo_doc      number
);

