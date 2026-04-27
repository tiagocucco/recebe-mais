-- liquibase formatted sql
-- changeset RMAIS:1777295649921 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_conf_orig_doc_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_conf_orig_doc_seq.sql:null:0c5db26b0fb70c7964315b805714ecd82846f9b6:create

create sequence rmais_conf_orig_doc_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder
nocycle nokeep noscale global;

