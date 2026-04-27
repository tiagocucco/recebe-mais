-- liquibase formatted sql
-- changeset RMAIS:1777295649676 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\emp.dept.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/emp.dept.sql:null:747bcb73bb89bd9968f6c29c75b6166fb815e76a:create

alter table emp
    add
        foreign key ( deptno )
            references dept ( deptno )
        enable;

