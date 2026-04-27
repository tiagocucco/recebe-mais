-- liquibase formatted sql
-- changeset RMAIS:1777295650147 stripComments:false  logicalFilePath:third-step\rmais\sequences\tb_grupo_usuario_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/tb_grupo_usuario_seq.sql:null:c487eb1a37b690f65d5cece0680f92fede12fdf4:create

create sequence tb_grupo_usuario_seq minvalue 1 maxvalue 999999999999999999999999999 increment by 1 /* start with n */ nocache noorder
nocycle nokeep noscale global;

