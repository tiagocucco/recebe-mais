-- liquibase formatted sql
-- changeset RMAIS:1777295649978 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_efd_headers_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_efd_headers_s.sql:null:8bb24cab7f0b50073ee3fd4012a5c18a5e678f1d:create

create sequence rmais_efd_headers_s minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep noscale
global;

