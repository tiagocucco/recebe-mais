-- liquibase formatted sql
-- changeset RMAIS:1777295650247 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_anexos_complementares.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_anexos_complementares.sql:null:11096ec0a3c6514db9d6f86057049733d4b9c5d5:create

create table rmais_anexos_complementares (
    efd_header_id number,
    blob_file     blob,
    filename      varchar2(300 byte),
    mime_type     varchar2(100 byte),
    creation_date date,
    id_anexo_ap   number,
    numero_anexo  number,
    invoice_id    number
);

