-- liquibase formatted sql
-- changeset RMAIS:1777295650222 stripComments:false  logicalFilePath:third-step\rmais\tables\log_status_bancada.sql
-- sqlcl_snapshot src/database/rmais/tables/log_status_bancada.sql:null:713820a85396f0821803f1c92935c718f9b3a4c6:create

create table log_status_bancada (
    id_doc_lsb     number not null enable,
    status_lsb     number,
    msg_lsb        clob,
    dt_process_lsb date
);

