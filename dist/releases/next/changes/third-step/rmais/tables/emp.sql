-- liquibase formatted sql
-- changeset RMAIS:1777295650210 stripComments:false  logicalFilePath:third-step\rmais\tables\emp.sql
-- sqlcl_snapshot src/database/rmais/tables/emp.sql:null:303ac78fbee80c939d84c9bc0442da96b70d4c0c:create

create table emp (
    empno    number(4, 0) not null enable,
    ename    varchar2(10 byte),
    job      varchar2(9 byte),
    mgr      number(4, 0),
    hiredate date,
    sal      number(7, 2),
    comm     number(7, 2),
    deptno   number(2, 0)
);

alter table emp add primary key ( empno )
    using index enable;

