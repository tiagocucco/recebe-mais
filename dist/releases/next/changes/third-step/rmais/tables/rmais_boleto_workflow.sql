-- liquibase formatted sql
-- changeset RMAIS:1777295650314 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_boleto_workflow.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_boleto_workflow.sql:null:8246ed4da12c5db9af9374c1ce3f46eb56159cd1:create

create table rmais_boleto_workflow (
    efd_header_id      number not null enable,
    bank_collection_id number,
    invoice_id         number,
    document_number    number,
    file_control       varchar2(300 byte),
    invoice_num        varchar2(300 byte),
    amount             number,
    tomador_cnpj       varchar2(15 byte),
    fornecedor_cnpj    varchar2(15 byte),
    invoice_date       date,
    source             varchar2(100 byte),
    status_lookup_code varchar2(60 byte),
    status_lookup_desc varchar2(300 byte),
    created_by         varchar2(300 byte),
    creation_date      date
);

