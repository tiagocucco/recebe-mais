-- liquibase formatted sql
-- changeset RMAIS:1777295651351 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_log_passagem_por_email.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_log_passagem_por_email.sql:null:074e3436edbae1d14caa159f9a0c209650f102fd:create

create table rmais_log_passagem_por_email (
    efd_header_id   number,
    email           varchar2(500 byte),
    data_tentativa  date,
    document_number varchar2(50 byte),
    status          varchar2(4 byte),
    log_errm        clob,
    titulo          varchar2(40 byte)
);

