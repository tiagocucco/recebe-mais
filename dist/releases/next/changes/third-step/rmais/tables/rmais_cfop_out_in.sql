-- liquibase formatted sql
-- changeset RMAIS:1777295650464 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_cfop_out_in.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_cfop_out_in.sql:null:564daf08662cde62a17834233b7d6fec6a5241f5:create

create table rmais_cfop_out_in (
    id             number,
    cfop_out       varchar2(4 byte) not null enable,
    cfop_in        varchar2(4 byte) not null enable,
    utilization_id number not null enable,
    inactive       varchar2(1 byte),
    creation_date  date,
    creation_by    varchar2(100 byte)
);

alter table rmais_cfop_out_in add unique ( id )
    using index enable;

