-- liquibase formatted sql
-- changeset RMAIS:1777295651173 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_hold_setup.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_hold_setup.sql:null:7ee1dfc82aa94eaa027357d45bc4b27328c937ae:create

create table rmais_hold_setup (
    id                number not null enable,
    hold_name         varchar2(500 byte),
    user_name         varchar2(1000 byte),
    creation_date     date,
    last_updated_user varchar2(1000 byte),
    last_update_date  date
);

alter table rmais_hold_setup
    add constraint rmais_hold_setup_pk primary key ( id )
        using index enable;

