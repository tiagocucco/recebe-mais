-- liquibase formatted sql
-- changeset RMAIS:1777295651103 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_empresas_poc.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_empresas_poc.sql:null:01a7da5954945c3fd72592e78c5cc1130f7eaf7d:create

create table rmais_empresas_poc (
    id           number,
    nome_empresa varchar2(20 byte)
);

alter table rmais_empresas_poc
    add constraint rmais_empresas_poc_pk primary key ( id )
        using index enable;

