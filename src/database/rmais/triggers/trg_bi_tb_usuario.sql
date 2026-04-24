create or replace editionable trigger trg_bi_tb_usuario before
    insert on tb_usuario
    for each row
begin
    if :new.id_usuario is null then
        select
            tb_usuario_seq.nextval
        into :new.id_usuario
        from
            dual;

        :new.password := rmais_pkg_auth.obfuscate('rmais01');
    end if;
end;
/

alter trigger trg_bi_tb_usuario enable;


-- sqlcl_snapshot {"hash":"47fe8a967a5228b7db2a46f1f829dabc18cc6912","type":"TRIGGER","name":"TRG_BI_TB_USUARIO","schemaName":"RMAIS","sxml":""}