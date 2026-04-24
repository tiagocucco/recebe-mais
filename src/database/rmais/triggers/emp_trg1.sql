create or replace editionable trigger emp_trg1 before
    insert on emp
    for each row
begin
    if :new.empno is null then
        select
            emp_seq.nextval
        into :new.empno
        from
            sys.dual;

    end if;
end;
/

alter trigger emp_trg1 enable;


-- sqlcl_snapshot {"hash":"21d10cc81a4042f5689d17f8c0e799e5a47d6842","type":"TRIGGER","name":"EMP_TRG1","schemaName":"RMAIS","sxml":""}