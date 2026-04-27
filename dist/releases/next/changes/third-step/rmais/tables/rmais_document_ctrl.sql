-- liquibase formatted sql
-- changeset RMAIS:1777295650607 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_document_ctrl.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_document_ctrl.sql:null:09be0e43810c02bbb49c2f1cb03d7dc106b6104a:create

create table rmais_document_ctrl (
    id                number not null enable,
    source            varchar2(500 byte),
    organization      varchar2(500 byte),
    filename          varchar2(1000 byte),
    mime_type         varchar2(200 byte),
    base64            clob,
    fileblob          blob,
    status            varchar2(10 byte),
    creation_date     date,
    last_updated_user varchar2(500 byte),
    last_update_date  date,
    email_source      varchar2(400 byte),
    email_date        date,
    email_subject     varchar2(4000 byte),
    email_body        clob,
    body_request      clob,
    user_is_editing   varchar2(50 byte)
);

alter table rmais_document_ctrl add constraint rmais_document_ctrl_uk1 unique ( id )
    using index enable;

