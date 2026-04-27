-- liquibase formatted sql
-- changeset RMAIS:1777295651920 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_log_envio_sp.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_log_envio_sp.sql:null:d34daf59ef7d13c6cf2f2ad56b786e0c4fd10ee2:create

create table tb_log_envio_sp (
    local varchar2(100 char),
    erro  clob
);

