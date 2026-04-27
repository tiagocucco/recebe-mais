-- liquibase formatted sql
-- changeset RMAIS:1777295649885 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_cc_type_match_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_cc_type_match_seq.sql:null:5364d99333bbba5fefdfd27e011dace982183de6:create

create sequence rmais_cc_type_match_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder
nocycle nokeep noscale global;

