create or replace editionable trigger bi_rmais_inv_pay_group before
    insert on rmais_inv_pay_group
    for each row
begin
    if :new.id_inv_pay_group is null then
        select
            rmais_inv_pay_group_seq.nextval
        into :new.id_inv_pay_group
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_inv_pay_group enable;


-- sqlcl_snapshot {"hash":"a8c3480df28f4d0a1efd0a2bf91070258e9346b3","type":"TRIGGER","name":"BI_RMAIS_INV_PAY_GROUP","schemaName":"RMAIS","sxml":""}