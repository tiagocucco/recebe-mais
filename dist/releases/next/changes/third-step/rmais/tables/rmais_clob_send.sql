-- liquibase formatted sql
-- changeset RMAIS:1777295650497 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_clob_send.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_clob_send.sql:null:ff5005e2eee5a7c2bd7f405335f9973f8dcb39e9:create

create table rmais_clob_send (
    request clob
);

