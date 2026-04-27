-- liquibase formatted sql
-- changeset RMAIS:1777295651257 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_invoices_workflow.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_invoices_workflow.sql:null:9567d950f639570778a8eadae094ce25bb438c4b:create

create table rmais_invoices_workflow (
    efd_header_id          number not null enable,
    status                 varchar2(4 byte) not null enable,
    descricao              varchar2(400 byte) not null enable,
    usuario                varchar2(500 byte),
    data_atualizacao       date not null enable,
    invoice_number         number,
    issuer_document_number varchar2(30 byte),
    invoice_amount         number
);

