-- liquibase formatted sql
-- changeset RMAIS:1777295651794 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_ws_nf_info_ap.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_ws_nf_info_ap.sql:null:643f24f61e3796f9d3217053a1ac349e4f917000:create

create table rmais_ws_nf_info_ap (
    id            number not null enable,
    body_ws       clob,
    creation_date date,
    status        varchar2(1 byte)
);

alter table rmais_ws_nf_info_ap
    add constraint rmais_ws_nf_info_ap_pk primary key ( id )
        using index enable;

