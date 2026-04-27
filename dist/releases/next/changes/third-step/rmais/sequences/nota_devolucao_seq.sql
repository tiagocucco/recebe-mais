-- liquibase formatted sql
-- changeset RMAIS:1777295649858 stripComments:false  logicalFilePath:third-step\rmais\sequences\nota_devolucao_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/nota_devolucao_seq.sql:null:aeb7a37acab49ccaeff51e650f0b6065544659b3:create

create sequence nota_devolucao_seq minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder nocycle nokeep noscale
global;

