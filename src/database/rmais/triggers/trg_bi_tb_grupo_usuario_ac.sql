create or replace editionable trigger trg_bi_tb_grupo_usuario_ac before
    insert on tb_grupo_usuario_ac
    for each row
begin
    if :new.num_grupo_usuario_ac is null then
        select
            nvl(
                max(a.num_grupo_usuario_ac),
                0
            ) + 1
        into :new.num_grupo_usuario_ac
        from
            tb_grupo_usuario_ac a
        where
            a.id_grupo_usuario = :new.id_grupo_usuario;

    end if;
end;
/

alter trigger trg_bi_tb_grupo_usuario_ac enable;


-- sqlcl_snapshot {"hash":"c52ff354ecdbeef78d937d90c8ad0147f16d7816","type":"TRIGGER","name":"TRG_BI_TB_GRUPO_USUARIO_AC","schemaName":"RMAIS","sxml":""}