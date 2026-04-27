-- liquibase formatted sql
-- changeset RMAIS:1777295650547 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_ctrl_docs_poc.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_ctrl_docs_poc.sql:null:2cf4be8373fda52488772cc270e029aa256499af:create

create table rmais_ctrl_docs_poc (
    id                    number not null enable,
    process               varchar2(100 byte),
    cnpj_fornecedor       varchar2(20 byte),
    filename              varchar2(500 byte),
    cnpj_forn             varchar2(30 byte),
    numero                number,
    serie                 varchar2(10 byte),
    source_doc_orig       clob,
    source_doc_decr       clob,
    layout                varchar2(200 byte),
    eletronic_invoice_key varchar2(44 byte),
    tipo_fiscal           varchar2(100 byte),
    status                varchar2(1 byte),
    log_process           clob,
    creation_date         date,
    process_date          date,
    id_doc                number
);

