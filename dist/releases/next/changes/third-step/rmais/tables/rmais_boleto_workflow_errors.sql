-- liquibase formatted sql
-- changeset RMAIS:1777295650324 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_boleto_workflow_errors.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_boleto_workflow_errors.sql:null:2c94a1f9a9fec1cea30aa857a9758539d9273170:create

create table rmais_boleto_workflow_errors (
    id            number,
    source        clob,
    msg           varchar2(1000 byte),
    created_by    varchar2(1000 byte),
    creation_date date
);

alter table rmais_boleto_workflow_errors
    add constraint rmais_boleto_workflow_errors_pk primary key ( id )
        using index enable;

