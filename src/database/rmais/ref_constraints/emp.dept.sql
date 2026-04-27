alter table emp
    add
        foreign key ( deptno )
            references dept ( deptno )
        enable;


-- sqlcl_snapshot {"hash":"747bcb73bb89bd9968f6c29c75b6166fb815e76a","type":"REF_CONSTRAINT","name":"EMP.DEPT","schemaName":"RMAIS","sxml":""}