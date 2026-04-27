-- liquibase formatted sql
-- changeset RMAIS:1777295651929 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_notas_recusadas.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_notas_recusadas.sql:null:8fe229dcdbc8428a2911f60ece6983a7bb58deff:create

create table tb_notas_recusadas (
    efd_header_id number,
    justificativa varchar2(50 char),
    usuario       varchar2(100 byte),
    data          date
);

