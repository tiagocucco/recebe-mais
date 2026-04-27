-- liquibase formatted sql
-- changeset RMAIS:1777295650155 stripComments:false  logicalFilePath:third-step\rmais\sequences\tb_usuario_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/tb_usuario_seq.sql:null:d8681fd42a359ba874690921928490922e306f9d:create

create sequence tb_usuario_seq minvalue 1 maxvalue 999999999999999999999999999 increment by 1 /* start with n */ nocache noorder nocycle
nokeep noscale global;

