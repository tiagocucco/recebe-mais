-- liquibase formatted sql
-- changeset RMAIS:1777295649904 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_cfop_out_in_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_cfop_out_in_seq.sql:null:7e3bdc19812aa606289fe941c048a9acac896ed2:create

create sequence rmais_cfop_out_in_seq minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep noscale
global;

