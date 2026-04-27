-- liquibase formatted sql
-- changeset RMAIS:1777295651211 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_integrated_erp.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_integrated_erp.sql:null:5f553a70f1bdb1da96f6d88bcf5b39c72f943455:create

create table rmais_integrated_erp (
    integration_id    number not null enable,
    access_key_number varchar2(48 byte),
    efd_header_id     number,
    document_number   varchar2(50 byte),
    doc_destination   varchar2(50 byte),
    ucm_status        varchar2(50 byte),
    ucm_id            number,
    fdc_status        varchar2(50 byte),
    fdc_id            number,
    fdc_created_by    varchar2(50 byte),
    ap_status         varchar2(50 byte),
    ap_id             number,
    ap_created_by     varchar2(50 byte),
    bol_status        varchar2(50 byte),
    bol_id            number,
    bol_created_by    varchar2(50 byte),
    creation_date     date,
    created_by        varchar2(100 byte),
    last_event_date   date,
    event_by          varchar2(100 byte)
);

