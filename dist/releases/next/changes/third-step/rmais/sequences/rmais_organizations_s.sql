-- liquibase formatted sql
-- changeset RMAIS:1777295650071 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_organizations_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_organizations_s.sql:null:a10e2ad635fe4ea54f95d99963aadc6ee2f735cb:create

create sequence rmais_organizations_s minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep noscale
global;

