-- liquibase formatted sql
-- changeset RMAIS:1777295650030 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_hold_setup_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_hold_setup_seq.sql:null:b939edde7aa1caea0d0a6c2d64bf2809a09be80c:create

create sequence rmais_hold_setup_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder
nocycle nokeep noscale global;

