-- liquibase formatted sql
-- changeset RMAIS:1777295650583 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_define_roles_entry.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_define_roles_entry.sql:null:f0999051f0d033863d9607bd7e29d20e24f80e21:create

create table rmais_define_roles_entry (
    id               number not null enable,
    model            varchar2(10 byte) not null enable,
    type             varchar2(2 byte) not null enable,
    created_by       varchar2(300 byte),
    creation_date    date,
    updated_by       varchar2(300 byte),
    last_update_date date
);

alter table rmais_define_roles_entry add constraint rmais_define_roles_entry_con unique ( model )
    using index enable;

alter table rmais_define_roles_entry
    add constraint rmais_define_roles_entry_pk primary key ( id )
        using index enable;

