-- liquibase formatted sql
-- changeset RMAIS:1777295650338 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_boletos_log.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_boletos_log.sql:null:252e321de5af67c9418710be145a7ab6bf3a626f:create

create table rmais_boletos_log (
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

create unique index rmais_boletos_log_pk on
    rmais_boletos_log (
        id
    );

create unique index rmais_boletos_log_uk1 on
    rmais_boletos_log (
        efd_header_id
    );

alter table rmais_boletos_log
    add constraint rmais_boletos_log_pk primary key ( id )
        using index rmais_boletos_log_pk enable;

alter table rmais_boletos_log
    add constraint rmais_boletos_log_uk1 unique ( efd_header_id )
        using index rmais_boletos_log_uk1 enable;

