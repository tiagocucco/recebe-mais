-- liquibase formatted sql
-- changeset RMAIS:1777295649876 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_boletos_log_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_boletos_log_seq.sql:null:50daf5071b8a9e69786fa8ffd93828f0161b959b:create

create sequence rmais_boletos_log_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder
nocycle nokeep noscale global;

