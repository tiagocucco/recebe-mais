-- liquibase formatted sql
-- changeset RMAIS:1777295649913 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_combinacao_guias_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_combinacao_guias_seq.sql:null:03bb11b29633c9ffe686c1c5e73fac5c7c55576c:create

create sequence rmais_combinacao_guias_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20
noorder nocycle nokeep noscale global;

