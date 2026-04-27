-- liquibase formatted sql
-- changeset RMAIS:1777295650013 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_empresas_poc_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_empresas_poc_seq.sql:null:f2fcb15c5742b39dc52400fc4f8f21189f4fb52a:create

create sequence rmais_empresas_poc_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder
nocycle nokeep noscale global;

