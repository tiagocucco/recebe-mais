-- liquibase formatted sql
-- changeset RMAIS:1777295651429 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_notas_devolucao.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_notas_devolucao.sql:null:1485680e568d91332ab9188f4e09b3219d0cfdbf:create

create table rmais_notas_devolucao (
    access_key_number_purchase   varchar2(44 byte),
    access_key_number_devolution varchar2(44 byte),
    status                       varchar2(2 byte),
    id_nd                        number,
    data_criacao                 date,
    data_update                  date
);

