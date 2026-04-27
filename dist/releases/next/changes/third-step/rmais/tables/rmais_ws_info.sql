-- liquibase formatted sql
-- changeset RMAIS:1777295651782 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_ws_info.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_ws_info.sql:null:9ec4d24614d2dfdb86aa1752d5d9f5be13e8198a:create

create table rmais_ws_info (
    transaction_id     number,
    transaction_method varchar2(4000 byte),
    clob_info          clob,
    blob_info          clob,
    creation_date      date,
    created_by         varchar2(50 byte),
    update_date        date,
    updated_by         varchar2(50 byte),
    efd_header_id      number
);

alter table rmais_ws_info add unique ( transaction_id )
    using index enable;

