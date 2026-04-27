-- liquibase formatted sql
-- changeset RMAIS:1777295651373 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_match_bu_types.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_match_bu_types.sql:null:42835fdcbb0860298b4376db1e22bdbba18e1090:create

create table rmais_match_bu_types (
    id               number not null enable,
    id_bu            number,
    type             varchar2(200 byte),
    cod1             varchar2(200 byte),
    cod2             varchar2(200 byte),
    creation_user    varchar2(400 byte),
    creation_date    date,
    last_update_by   varchar2(400 byte),
    last_update_date date,
    cod3             varchar2(100 byte),
    cod4             varchar2(100 byte),
    cod5             varchar2(100 byte)
);

create unique index rmais_match_bu_types_con on
    rmais_match_bu_types (
        type,
        cod1,
        cod5
    );

create unique index rmais_match_bu_types_pk on
    rmais_match_bu_types (
        id
    );

alter table rmais_match_bu_types
    add constraint rmais_match_bu_types_con
        unique ( type,
                 cod1,
                 cod5 )
            using index rmais_match_bu_types_con enable;

alter table rmais_match_bu_types
    add constraint rmais_match_bu_types_pk primary key ( id )
        using index rmais_match_bu_types_pk enable;

