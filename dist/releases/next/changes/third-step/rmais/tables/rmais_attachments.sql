-- liquibase formatted sql
-- changeset RMAIS:1777295650264 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_attachments.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_attachments.sql:null:34cfc327cf1e1816aa91856c252377a966f0831e:create

create table rmais_attachments (
    efd_header_id number,
    clob_file     clob,
    blob_file     blob,
    filename      varchar2(300 byte),
    mime_type     varchar2(100 byte),
    creation_date date
);

