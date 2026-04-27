-- liquibase formatted sql
-- changeset RMAIS:1777295651197 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_integrated_docs.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_integrated_docs.sql:null:3024700731e3168bc87e1dcb3dca6f12d2d9f28f:create

create table rmais_integrated_docs (
    id                number not null enable,
    access_key_number varchar2(48 byte),
    efd_header_id     number,
    destination       varchar2(20 byte),
    ucm_id            number,
    fdc_id            number,
    fdc_status        varchar2(20 byte),
    ap_id             number,
    ap_status         varchar2(20 byte),
    creation_date     date,
    created_by        varchar2(100 byte),
    last_update_date  date,
    updated_by        varchar2(100 byte),
    bol_id            number,
    bol_status        varchar2(20 byte)
);

