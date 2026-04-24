create or replace editionable trigger trg_bi_tb_grupo_usuario before
    insert on tb_grupo_usuario
    for each row
begin
    if :new.id_grupo_usuario is null then
        select
            tb_grupo_usuario_seq.nextval
        into :new.id_grupo_usuario
        from
            dual;

    end if;
end;
/

alter trigger trg_bi_tb_grupo_usuario enable;


-- sqlcl_snapshot {"hash":"92fe0f58ede6774e679d5227e2bef8e75d1b964b","type":"TRIGGER","name":"TRG_BI_TB_GRUPO_USUARIO","schemaName":"RMAIS","sxml":""}