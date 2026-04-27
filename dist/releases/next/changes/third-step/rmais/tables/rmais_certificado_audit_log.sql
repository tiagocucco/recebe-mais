-- liquibase formatted sql
-- changeset RMAIS:1777295650416 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_certificado_audit_log.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_certificado_audit_log.sql:null:f3b4103f74b0b4d112e12ae439dfd81b226cf31a:create

create table rmais_certificado_audit_log (
    id            number,
    action_type   varchar2(10 byte),
    deleted_at    date,
    deleted_by    varchar2(200 byte),
    cert_filename varchar2(1000 byte),
    receiver_name varchar2(120 byte),
    obs           varchar2(2000 byte)
);

