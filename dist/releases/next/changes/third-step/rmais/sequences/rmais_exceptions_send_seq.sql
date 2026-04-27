-- liquibase formatted sql
-- changeset RMAIS:1777295650021 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_exceptions_send_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_exceptions_send_seq.sql:null:3765b432bfd0bac72e6b7de7aab16396299ea48f:create

create sequence rmais_exceptions_send_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20
noorder nocycle nokeep noscale global;

