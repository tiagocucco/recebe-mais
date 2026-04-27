-- liquibase formatted sql
-- changeset RMAIS:1777295650880 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_efd_lin_valid.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_efd_lin_valid.sql:null:49e3eb57ad6a4d0685fe0060e7a7f76dd0015266:create

create table rmais_efd_lin_valid (
    efd_header_id number,
    efd_line_id   number,
    type          varchar2(100 byte),
    message_text  varchar2(2000 byte) not null enable,
    creation_date date not null enable,
    update_date   date
);

