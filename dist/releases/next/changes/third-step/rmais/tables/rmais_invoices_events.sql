-- liquibase formatted sql
-- changeset RMAIS:1777295651246 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_invoices_events.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_invoices_events.sql:null:5fbd251381e8b9af336d62da67b78bac7b434319:create

create table rmais_invoices_events (
    efd_header_id     number,
    evento            varchar2(80 byte),
    mensagem          varchar2(1000 byte),
    creation_date     date,
    user_name         varchar2(1000 byte),
    access_key_number varchar2(50 byte)
);

