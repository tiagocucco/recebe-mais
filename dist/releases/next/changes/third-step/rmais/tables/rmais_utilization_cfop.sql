-- liquibase formatted sql
-- changeset RMAIS:1777295651731 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_utilization_cfop.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_utilization_cfop.sql:null:31f97dae361d66d198101963147d1839aa924e97:create

create table rmais_utilization_cfop (
    id               number,
    utilization_name varchar2(150 byte),
    match_erp        varchar2(400 byte),
    creation_date    date,
    creation_by      varchar2(100 byte)
);

alter table rmais_utilization_cfop add unique ( id )
    using index enable;

alter table rmais_utilization_cfop add unique ( utilization_name )
    using index enable;

