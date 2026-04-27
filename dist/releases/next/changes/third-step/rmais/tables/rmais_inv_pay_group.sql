-- liquibase formatted sql
-- changeset RMAIS:1777295651221 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_inv_pay_group.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_inv_pay_group.sql:null:36eccd88d3eb4759b014c7adcc448790cc5ea60e:create

create table rmais_inv_pay_group (
    id_inv_pay_group number,
    item             varchar2(100 byte),
    payment_group    varchar2(100 byte)
);

alter table rmais_inv_pay_group
    add constraint rmais_inv_pay_group_pk primary key ( id_inv_pay_group )
        using index enable;

alter table rmais_inv_pay_group add constraint rmais_inv_pay_group_uk1 unique ( item )
    using index enable;

