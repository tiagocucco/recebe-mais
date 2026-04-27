-- liquibase formatted sql
-- changeset RMAIS:1777295650164 stripComments:false  logicalFilePath:third-step\rmais\sequences\xxrmais_invoice_lines_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/xxrmais_invoice_lines_s.sql:null:b10bebcee25b1308c4fc334826500d31f7403d9c:create

create sequence xxrmais_invoice_lines_s minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep
noscale global;

