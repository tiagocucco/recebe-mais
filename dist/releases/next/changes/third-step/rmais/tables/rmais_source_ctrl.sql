-- liquibase formatted sql
-- changeset RMAIS:1777295651581 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_source_ctrl.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_source_ctrl.sql:null:4a27badc1819b3d78849c4f5d5b5114dc443ac08:create

create table rmais_source_ctrl (
    control          varchar2(30 byte),
    source           clob,
    context          varchar2(4000 byte),
    text_value       varchar2(4000 byte),
    text_value2      varchar2(4000 byte),
    text_value3      varchar2(4000 byte),
    text_value4      varchar2(4000 byte),
    text_value5      varchar2(4000 byte),
    text_value6      varchar2(4000 byte),
    text_value7      varchar2(4000 byte),
    text_value8      varchar2(4000 byte),
    text_value9      varchar2(4000 byte),
    number_value     number,
    creation_date    date,
    created_by       number,
    last_update_date date,
    last_updated_by  number
);

alter table rmais_source_ctrl add unique ( control )
    using index enable;

