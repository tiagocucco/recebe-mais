-- liquibase formatted sql
-- changeset RMAIS:1777295650299 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_black_list_cancel.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_black_list_cancel.sql:null:8c67196131bf62635ab103f4900c07a0899bdd57:create

create table rmais_black_list_cancel (
    access_key_number varchar2(50 byte) not null enable,
    creation_date     date not null enable
);

alter table rmais_black_list_cancel add unique ( access_key_number )
    using index enable;

