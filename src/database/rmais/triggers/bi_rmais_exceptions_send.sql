create or replace editionable trigger bi_rmais_exceptions_send before
    insert on rmais_exceptions_send
    for each row
begin
    if :new.id is null then
        select
            rmais_exceptions_send_seq.nextval
        into :new.id
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_exceptions_send enable;


-- sqlcl_snapshot {"hash":"e7909db8fd118eda5c703ba1d30fbc4891d316e1","type":"TRIGGER","name":"BI_RMAIS_EXCEPTIONS_SEND","schemaName":"RMAIS","sxml":""}