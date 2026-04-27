-- liquibase formatted sql
-- changeset RMAIS:1777295650111 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_utilization_cfop_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_utilization_cfop_seq.sql:null:9e61aafa97ce8799026a350451ac03b23249cd3f:create

create sequence rmais_utilization_cfop_seq minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep
noscale global;

