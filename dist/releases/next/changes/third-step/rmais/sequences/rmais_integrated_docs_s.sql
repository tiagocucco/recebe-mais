-- liquibase formatted sql
-- changeset RMAIS:1777295650038 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_integrated_docs_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_integrated_docs_s.sql:null:3facc2b8c0c5c505c20607a1a2550b50269a4920:create

create sequence rmais_integrated_docs_s minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep
noscale global;

