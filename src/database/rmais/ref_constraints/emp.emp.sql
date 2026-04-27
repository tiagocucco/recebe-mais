alter table emp
    add
        foreign key ( mgr )
            references emp ( empno )
        enable;


-- sqlcl_snapshot {"hash":"933048d09faf54f7ab495df83e85de1909ee2b1b","type":"REF_CONSTRAINT","name":"EMP.EMP","schemaName":"RMAIS","sxml":""}