-- liquibase formatted sql
-- changeset RMAIS:1777295649841 stripComments:false  logicalFilePath:third-step\rmais\sequences\dr$rmais_json_idx$dgsq.sql
-- sqlcl_snapshot src/database/rmais/sequences/dr$rmais_json_idx$dgsq.sql:null:d5e28de4af74daabba61f39298615b5ad8a32ff8:create

create sequence dr$rmais_json_idx$dgsq minvalue 1 maxvalue 9999 increment by 1 /* start with n */ cache 20 noorder cycle nokeep noscale
global;

