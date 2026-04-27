-- liquibase formatted sql
-- changeset RMAIS:1777295651487 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_payload_queue.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_payload_queue.sql:null:1ad2c3ced4348b4e1c6f8b5fd88acfa4286a85d8:create

create table rmais_payload_queue (
    id                number default to_number(to_char(systimestamp, 'YYYYMMDDHH24MISSFF')),
    payload           clob,
    status            varchar2(100 byte) not null enable,
    access_key_number varchar2(255 byte),
    log               clob,
    creation_date     date not null enable,
    created_by        varchar2(100 byte),
    update_date       date not null enable,
    updated_by        varchar2(100 byte)
);

alter table rmais_payload_queue
    add constraint pk_rmais_payload_queue primary key ( id )
        using index enable;

