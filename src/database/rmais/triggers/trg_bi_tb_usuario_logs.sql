create or replace editionable trigger trg_bi_tb_usuario_logs before
    insert on tb_usuario_logs
    for each row
begin
    if :new.num_log is null then
        select
            nvl(
                max(a.num_log),
                0
            ) + 1
        into :new.num_log
        from
            tb_usuario_logs a
        where
            a.id_usuario = :new.id_usuario;

    end if;
end;
/

alter trigger trg_bi_tb_usuario_logs enable;


-- sqlcl_snapshot {"hash":"f0e4bf4a0d1aa24929aa9a708ce67d5084dd752c","type":"TRIGGER","name":"TRG_BI_TB_USUARIO_LOGS","schemaName":"RMAIS","sxml":""}