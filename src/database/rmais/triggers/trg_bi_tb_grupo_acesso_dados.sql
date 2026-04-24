create or replace editionable trigger trg_bi_tb_grupo_acesso_dados before
    insert on tb_grupo_acesso_dados
    for each row
begin
    if :new.id_grupo_acesso_dados is null then
        select
            tb_grupo_acesso_dados_seq.nextval
        into :new.id_grupo_acesso_dados
        from
            dual;

    end if;
end;
/

alter trigger trg_bi_tb_grupo_acesso_dados enable;


-- sqlcl_snapshot {"hash":"0840f99183b0fce581fa064f530af57bfbe21e1f","type":"TRIGGER","name":"TRG_BI_TB_GRUPO_ACESSO_DADOS","schemaName":"RMAIS","sxml":""}