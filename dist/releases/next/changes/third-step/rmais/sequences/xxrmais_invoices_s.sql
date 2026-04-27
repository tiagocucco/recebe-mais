-- liquibase formatted sql
-- changeset RMAIS:1777295650173 stripComments:false  logicalFilePath:third-step\rmais\sequences\xxrmais_invoices_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/xxrmais_invoices_s.sql:null:0673c0a6072644edcad8189951dfe0a4a4d4a102:create

create sequence xxrmais_invoices_s minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep noscale
global;

