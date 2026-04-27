-- liquibase formatted sql
-- changeset RMAIS:1777295650183 stripComments:false  logicalFilePath:third-step\rmais\tables\databasechangelog_export.sql
-- sqlcl_snapshot src/database/rmais/tables/databasechangelog_export.sql:null:a51764f891f206dabe4cb82c8683dd80af7dec7c:create

create table databasechangelog_export (
    object_rank     number not null enable,
    object_sequence number,
    object_name     varchar2(2000 byte),
    object_deps     varchar2(4000 byte),
    object_type     varchar2(2000 byte),
    object_doc      clob,
    file_name       varchar2(2000 byte),
    written         number default 0
);

alter table databasechangelog_export
    add constraint databasechangelog_export_pk primary key ( object_name,
                                                             object_type )
        using index enable;

