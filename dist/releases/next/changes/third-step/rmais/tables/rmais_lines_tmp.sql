-- liquibase formatted sql
-- changeset RMAIS:1777295651301 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_lines_tmp.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_lines_tmp.sql:null:89fe3447454610583093970deea7d99eaaff79b0:create

create table rmais_lines_tmp (
    descricao  varchar2(220 byte),
    quantidade number,
    unit       number
);

