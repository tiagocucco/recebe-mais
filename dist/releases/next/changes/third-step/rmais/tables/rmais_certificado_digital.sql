-- liquibase formatted sql
-- changeset RMAIS:1777295650428 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_certificado_digital.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_certificado_digital.sql:null:cf2bf06be35ae86d51c0b6dd8495b00fd4f5dc16:create

create table rmais_certificado_digital (
    id                       number,
    cert_file                blob,
    cert_filename            varchar2(1000 byte),
    cert_mime_type           varchar2(1000 byte),
    password                 varchar2(1000 byte),
    receiver_document_number varchar2(30 byte),
    receiver_name            varchar2(120 byte),
    expiration_date          date,
    creation_date            date,
    created_by               varchar2(200 byte),
    obs                      varchar2(2000 byte),
    last_updated_date        date,
    last_updated_by          varchar2(200 byte)
);

create index rmais_certificado_digital_idx on
    rmais_certificado_digital (
        id
    );

alter table rmais_certificado_digital
    add constraint rmais_certificado_digital_pk primary key ( id )
        using index rmais_certificado_digital_idx enable;

