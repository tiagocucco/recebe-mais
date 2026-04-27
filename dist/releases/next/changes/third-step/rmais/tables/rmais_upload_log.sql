-- liquibase formatted sql
-- changeset RMAIS:1777295651717 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_upload_log.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_upload_log.sql:null:12f3a11e8bf1ed51921f2e75adcd2a09ee9d2daa:create

create table rmais_upload_log (
    id               number,
    file_name        varchar2(255 byte),
    mime_type        varchar2(255 byte),
    excel_file       blob,
    creation_date    date default sysdate,
    created_by       varchar2(255 byte),
    last_update_date date default sysdate,
    updated_by       varchar2(255 byte),
    status           varchar2(20 byte),
    log              clob,
    job_name         varchar2(255 byte),
    efd_header_id    number
);

alter table rmais_upload_log add primary key ( id )
    using index enable;

