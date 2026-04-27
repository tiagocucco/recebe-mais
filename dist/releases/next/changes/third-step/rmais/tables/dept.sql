-- liquibase formatted sql
-- changeset RMAIS:1777295650196 stripComments:false  logicalFilePath:third-step\rmais\tables\dept.sql
-- sqlcl_snapshot src/database/rmais/tables/dept.sql:null:4b8722a19f1930137201fd47ba0be7810bdf692b:create

create table dept (
    deptno number(2, 0),
    dname  varchar2(14 byte),
    loc    varchar2(13 byte),
    teste  varchar2(1000 byte)
);

alter table dept add primary key ( deptno )
    using index enable;

