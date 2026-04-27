-- liquibase formatted sql
-- changeset RMAIS:1777295650869 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_efd_learning_v.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_efd_learning_v.sql:null:8a1defc361f2010a85eba1e0ade6f34ea2ca3d69:create

create table rmais_efd_learning_v (
    item_code                varchar2(60 byte),
    item_description         varchar2(220 byte),
    item_id                  number,
    item_code_efd            varchar2(100 byte),
    item_descr_efd           varchar2(300 byte),
    item_info                clob,
    cfop_from                number,
    cfop_to                  number,
    fiscal_classification    varchar2(15 byte),
    issuer_name              varchar2(120 byte),
    issuer_document_number   varchar2(15 byte),
    receiver_name            varchar2(60 byte),
    receiver_document_number varchar2(15 byte)
);

