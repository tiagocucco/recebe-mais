-- liquibase formatted sql
-- changeset RMAIS:1777295650048 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_inv_pay_group_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_inv_pay_group_seq.sql:null:5c300e75ad4c8cf6bc5650b8422c9b2c4f7c58d3:create

create sequence rmais_inv_pay_group_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder
nocycle nokeep noscale global;

