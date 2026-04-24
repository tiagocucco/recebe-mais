create or replace editionable trigger bi_rmais_ws_nf_info_ap before
    insert on rmais_ws_nf_info_ap
    for each row
begin
    if :new.id is null then
        select
            rmais_ws_nf_info_ap_seq.nextval
        into :new.id
        from
            sys.dual;

    end if;
end;
/

alter trigger bi_rmais_ws_nf_info_ap enable;


-- sqlcl_snapshot {"hash":"742be35529dd5be9ec30e26513acb874f2d7c48d","type":"TRIGGER","name":"BI_RMAIS_WS_NF_INFO_AP","schemaName":"RMAIS","sxml":""}