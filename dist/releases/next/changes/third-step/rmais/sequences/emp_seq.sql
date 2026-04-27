-- liquibase formatted sql
-- changeset RMAIS:1777295649849 stripComments:false  logicalFilePath:third-step\rmais\sequences\emp_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/emp_seq.sql:null:c6b582d672dee66e42c00155b716e0731fef188f:create

create sequence emp_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder nocycle nokeep
noscale global;

