-- liquibase formatted sql
-- changeset RMAIS:1777295649947 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_define_roles_entry_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_define_roles_entry_seq.sql:null:70c3d2966d988049eb50522b8532464a979d414e:create

create sequence rmais_define_roles_entry_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache
20 noorder nocycle nokeep noscale global;

