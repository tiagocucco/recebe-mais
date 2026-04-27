-- liquibase formatted sql
-- changeset RMAIS:1777295650136 stripComments:false  logicalFilePath:third-step\rmais\sequences\tb_grupo_acesso_dados_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/tb_grupo_acesso_dados_seq.sql:null:8ae8c4539086430764983ab7c135032d8ea5fd83:create

create sequence tb_grupo_acesso_dados_seq minvalue 1 maxvalue 999999999999999999999999999 increment by 1 /* start with n */ nocache noorder
nocycle nokeep noscale global;

