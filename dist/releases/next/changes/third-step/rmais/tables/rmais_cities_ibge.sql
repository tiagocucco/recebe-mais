-- liquibase formatted sql
-- changeset RMAIS:1777295650479 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_cities_ibge.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_cities_ibge.sql:null:8101781db7bce2eb20b5e5836c273e87026b61ce:create

create table rmais_cities_ibge (
    cod_muni      varchar2(7 byte),
    municipio     varchar2(50 byte),
    estado        varchar2(2 byte),
    layout_nfse   varchar2(60 byte),
    creation_by   number,
    creation_date date
);

alter table rmais_cities_ibge add unique ( cod_muni )
    using index enable;

