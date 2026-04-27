-- liquibase formatted sql
-- changeset RMAIS:1777295649825 stripComments:false  logicalFilePath:third-step\rmais\sequences\dept_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/dept_seq.sql:null:cafea7cd40349f6362a87a2381357cc3917f58a3:create

create sequence dept_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder nocycle nokeep
noscale global;

