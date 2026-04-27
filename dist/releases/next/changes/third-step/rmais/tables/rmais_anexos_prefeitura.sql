-- liquibase formatted sql
-- changeset RMAIS:1777295650255 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_anexos_prefeitura.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_anexos_prefeitura.sql:null:b16bcf10c788d93f0f1e889f2ab7a86fe9b0f427:create

create table rmais_anexos_prefeitura (
    efd_header_id      number,
    transaction_id     number,
    transaction_method varchar2(30 byte)
);

