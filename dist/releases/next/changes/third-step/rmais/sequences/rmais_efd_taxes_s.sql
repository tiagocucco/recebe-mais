-- liquibase formatted sql
-- changeset RMAIS:1777295650004 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_efd_taxes_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_efd_taxes_s.sql:null:4a2d2ed4c9443b3f7816dc5e49fccaa7c31280b6:create

create sequence rmais_efd_taxes_s minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep noscale
global;

