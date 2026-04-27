-- liquibase formatted sql
-- changeset RMAIS:1777295651332 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_log_anexo_excluir.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_log_anexo_excluir.sql:null:fb3e1281208462f1a3fbd3bad5fbdd0407b1d9c7:create

create table rmais_log_anexo_excluir (
    efd_header_id number,
    passo         varchar2(50 byte),
    erros         clob
);

