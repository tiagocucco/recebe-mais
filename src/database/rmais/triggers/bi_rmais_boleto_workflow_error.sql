create or replace editionable trigger bi_rmais_boleto_workflow_error before
    insert on rmais_boleto_workflow_errors
    for each row
begin
    if :new.id is null then
        select
            rmais_boleto_workflow_errors_seq.nextval
        into :new.id
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_boleto_workflow_error enable;


-- sqlcl_snapshot {"hash":"da9bf3bc9ea289bb4c25bd29361f5219b5419d39","type":"TRIGGER","name":"BI_RMAIS_BOLETO_WORKFLOW_ERROR","schemaName":"RMAIS","sxml":""}