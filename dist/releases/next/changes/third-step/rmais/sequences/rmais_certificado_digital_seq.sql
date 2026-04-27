-- liquibase formatted sql
-- changeset RMAIS:1777295649894 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_certificado_digital_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_certificado_digital_seq.sql:null:bd1b8c6fe4d2a122532bee596e80c410e2f5d2a5:create

create sequence rmais_certificado_digital_seq minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep
noscale global;

