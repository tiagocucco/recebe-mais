-- liquibase formatted sql
-- changeset RMAIS:1777295649938 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_define_det_entry_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_define_det_entry_seq.sql:null:594289d4365d2e8491be9625037db615df133c11:create

create sequence rmais_define_det_entry_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20
noorder nocycle nokeep noscale global;

