-- liquibase formatted sql
-- changeset RMAIS:1777295651117 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_error_anexos.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_error_anexos.sql:null:2410ab34f41d1f522418475ef6f16b4166883788:create

create table rmais_error_anexos (
    efd_header_id number,
    details       blob
);

