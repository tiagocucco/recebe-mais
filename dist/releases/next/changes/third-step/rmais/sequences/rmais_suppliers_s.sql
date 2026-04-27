-- liquibase formatted sql
-- changeset RMAIS:1777295650094 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_suppliers_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_suppliers_s.sql:null:053f70c4749baa8f030a32944c2805c652ec7589:create

create sequence rmais_suppliers_s minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep noscale
global;

