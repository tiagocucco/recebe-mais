-- liquibase formatted sql
-- changeset RMAIS:1777295650273 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_attachments_bol.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_attachments_bol.sql:null:8dc23f408a2d923e5c39128a28a8b57c059dc52c:create

create table rmais_attachments_bol (
    efd_header_id number,
    blob_file     blob,
    filename      varchar2(300 byte),
    mime_type     varchar2(100 byte),
    creation_date date
);

