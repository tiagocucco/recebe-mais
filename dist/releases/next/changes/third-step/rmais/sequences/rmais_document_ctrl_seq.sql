-- liquibase formatted sql
-- changeset RMAIS:1777295649961 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_document_ctrl_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_document_ctrl_seq.sql:null:6f93275e7d6326b989b3e8fe3b194cba03123f0b:create

create sequence rmais_document_ctrl_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ nocache noorder
nocycle nokeep noscale global;

