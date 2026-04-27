-- liquibase formatted sql
-- changeset RMAIS:1777295651522 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_rejects.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_rejects.sql:null:9f8f776eaba4a8e96feff2e1d98f729365b886d9:create

create table rmais_rejects (
    efd_header_id     number not null enable,
    access_key_number varchar2(44 byte) not null enable,
    reason            varchar2(1000 byte) not null enable,
    creation_date     date not null enable,
    created_by        varchar2(800 byte) not null enable
);

alter table rmais_rejects add constraint rmais_rejects_uk1 unique ( efd_header_id )
    using index enable;

