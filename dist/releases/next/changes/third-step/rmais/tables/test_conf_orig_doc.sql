-- liquibase formatted sql
-- changeset RMAIS:1777295651996 stripComments:false  logicalFilePath:third-step\rmais\tables\test_conf_orig_doc.sql
-- sqlcl_snapshot src/database/rmais/tables/test_conf_orig_doc.sql:null:458b80f88466e36f1ce1c87a67d4368a70397992:create

create table test_conf_orig_doc (
    id_conf_orig_doc   number,
    desc_conf_orig_doc varchar2(100 byte),
    identif_a          varchar2(200 byte),
    identif_b          varchar2(200 byte)
);

alter table test_conf_orig_doc
    add constraint rmais_conf_orig_doc_pk primary key ( id_conf_orig_doc )
        using index enable;

