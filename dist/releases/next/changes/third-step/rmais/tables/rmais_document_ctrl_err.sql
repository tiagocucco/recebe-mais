-- liquibase formatted sql
-- changeset RMAIS:1777295650620 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_document_ctrl_err.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_document_ctrl_err.sql:null:292ab7adb79c9775a25bb61c04cf87d26b7befd3:create

create table rmais_document_ctrl_err (
    id          number,
    table_err   varchar2(100 byte),
    field_err   varchar2(100 byte),
    val_varchar varchar2(4000 byte),
    val_clob    clob,
    data        date
);

