-- liquibase formatted sql
-- changeset RMAIS:1777295649868 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_boleto_workflow_errors_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_boleto_workflow_errors_seq.sql:null:0d86c9e69f3649d65824756f9481f58a9a1f05d4:create

create sequence rmais_boleto_workflow_errors_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache
20 noorder nocycle nokeep noscale global;

