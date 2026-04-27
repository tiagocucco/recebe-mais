-- liquibase formatted sql
-- changeset RMAIS:1777295649685 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\emp.emp.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/emp.emp.sql:null:933048d09faf54f7ab495df83e85de1909ee2b1b:create

alter table emp
    add
        foreign key ( mgr )
            references emp ( empno )
        enable;

