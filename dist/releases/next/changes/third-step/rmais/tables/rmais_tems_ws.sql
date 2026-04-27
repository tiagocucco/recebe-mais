-- liquibase formatted sql
-- changeset RMAIS:1777295651647 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_tems_ws.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_tems_ws.sql:null:cb32e8858cec4056eb1bb34ae10db9e7eda074c7:create

create table rmais_tems_ws (
    name                     varchar2(4000 byte),
    term_id                  number,
    due_days                 number,
    description              varchar2(4000 byte),
    due_percent              number,
    sequence_num             number,
    discount_days            number,
    discount_percent         number,
    apex$sync_step_static_id varchar2(255 byte),
    apex$row_sync_timestamp  timestamp(6) with time zone
);

alter table rmais_tems_ws
    add constraint rmais_tems_ws_pk primary key ( term_id )
        using index enable;

