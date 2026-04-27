-- liquibase formatted sql
-- changeset RMAIS:1777295651629 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_suppliers.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_suppliers.sql:null:30a4c473407812563c96125b3ecad85bda063ee8:create

create table rmais_suppliers (
    id           number not null enable,
    domain_id    number,
    nome         varchar2(180 byte) not null enable,
    data_inicial date not null enable,
    data_final   date
);

