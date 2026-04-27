-- liquibase formatted sql
-- changeset RMAIS:1777295650374 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_boletos_log_hdi.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_boletos_log_hdi.sql:null:f7910155c95c8e5ec8c8c375e06e55e2c6fbef02:create

create table rmais_boletos_log_hdi (
    id               number not null enable,
    efd_header_id    number not null enable,
    count_process    number not null enable,
    log              clob,
    creation_date    date,
    create_user      varchar2(500 byte),
    last_update_date date,
    last_user        varchar2(500 byte),
    id_transaction   number,
    status           varchar2(8 byte)
);

