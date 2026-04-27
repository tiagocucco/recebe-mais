-- liquibase formatted sql
-- changeset RMAIS:1777295651146 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_exceptions_send.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_exceptions_send.sql:null:1b07b530c99396af4e9f649658dfd0d90491d439:create

create table rmais_exceptions_send (
    id               number not null enable,
    type_ex          varchar2(300 byte) not null enable,
    value            varchar2(500 byte),
    creation_date    date,
    create_user      varchar2(500 byte),
    last_update_date date,
    last_update_by   varchar2(500 byte)
);

create unique index rmais_exceptions_send_con on
    rmais_exceptions_send (
        type_ex,
        value
    );

create unique index rmais_exceptions_send_pk on
    rmais_exceptions_send (
        id
    );

alter table rmais_exceptions_send
    add constraint rmais_exceptions_send_con unique ( type_ex,
                                                      value )
        using index rmais_exceptions_send_con enable;

alter table rmais_exceptions_send
    add constraint rmais_exceptions_send_pk primary key ( id )
        using index rmais_exceptions_send_pk enable;

