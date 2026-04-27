-- liquibase formatted sql
-- changeset RMAIS:1777295651768 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_ws_defined_clasification.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_ws_defined_clasification.sql:null:db4460213bb683869b64de7c1cac54d8a1e351a2:create

create table rmais_ws_defined_clasification (
    classification_id        number,
    classification_code      varchar2(4000 byte),
    classification_name      varchar2(4000 byte),
    apex$sync_step_static_id varchar2(255 byte),
    apex$row_sync_timestamp  timestamp(6) with time zone
);

