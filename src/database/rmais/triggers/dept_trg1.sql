create or replace editionable trigger dept_trg1 before
    insert on dept
    for each row
begin
    if :new.deptno is null then
        select
            dept_seq.nextval
        into :new.deptno
        from
            sys.dual;

    end if;
end;
/

alter trigger dept_trg1 enable;


-- sqlcl_snapshot {"hash":"b128e5203df7f63e0ba435ebf5aefc4f3b4f3f21","type":"TRIGGER","name":"DEPT_TRG1","schemaName":"RMAIS","sxml":""}