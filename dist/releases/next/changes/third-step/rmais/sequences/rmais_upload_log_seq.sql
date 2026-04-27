-- liquibase formatted sql
-- changeset RMAIS:1777295650102 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_upload_log_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_upload_log_seq.sql:null:c3cafee052067c2c585f339cd10e9769c4749077:create

create sequence rmais_upload_log_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder
nocycle nokeep noscale global;

