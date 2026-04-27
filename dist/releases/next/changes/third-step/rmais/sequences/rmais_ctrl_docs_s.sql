-- liquibase formatted sql
-- changeset RMAIS:1777295649930 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_ctrl_docs_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_ctrl_docs_s.sql:null:43fee2ffe46545d6a616e36b5d2605288d6f4045:create

create sequence rmais_ctrl_docs_s minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep noscale
global;

