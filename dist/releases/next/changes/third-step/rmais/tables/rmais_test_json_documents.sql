-- liquibase formatted sql
-- changeset RMAIS:1777295651691 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_test_json_documents.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_test_json_documents.sql:null:58fa1309835916c9b34e57cf5369a460319f72d8:create

create table rmais_test_json_documents (
    id   raw(16) not null enable,
    data clob
);

alter table rmais_test_json_documents add constraint json_documents_json_chk check ( data is json ) enable;

alter table rmais_test_json_documents
    add constraint json_documents_pk primary key ( id )
        using index enable;

