create or replace editionable trigger bi_rmais_hold_setup before
    insert on rmais_hold_setup
    for each row
begin
    if :new.id is null then
        select
            rmais_hold_setup_seq.nextval
        into :new.id
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_hold_setup enable;


-- sqlcl_snapshot {"hash":"84c3c3fb79ef0bc2f3e8339e94bbaecc9bf1782f","type":"TRIGGER","name":"BI_RMAIS_HOLD_SETUP","schemaName":"RMAIS","sxml":""}