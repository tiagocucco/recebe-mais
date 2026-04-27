-- liquibase formatted sql
-- changeset RMAIS:1777295650392 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_cc_type_match.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_cc_type_match.sql:null:9e77b9078199ff7c6a8db30377dea10a6a69aaa2:create

create table rmais_cc_type_match (
    id    number not null enable,
    type  varchar2(200 byte) not null enable,
    conta number not null enable
);

create unique index rmais_cc_type_match_con on
    rmais_cc_type_match (
        type
    );

create unique index rmais_cc_type_match_pk on
    rmais_cc_type_match (
        id
    );

alter table rmais_cc_type_match
    add constraint rmais_cc_type_match_con unique ( type )
        using index rmais_cc_type_match_con enable;

alter table rmais_cc_type_match
    add constraint rmais_cc_type_match_pk primary key ( id )
        using index rmais_cc_type_match_pk enable;

