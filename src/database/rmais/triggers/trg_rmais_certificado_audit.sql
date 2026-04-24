create or replace editionable trigger trg_rmais_certificado_audit before
    insert or update on rmais_certificado_digital
    for each row
begin
    if inserting then
    -- Preenche criação
        :new.creation_date := sysdate;
        :new.created_by := nvl(
            v('APP_USER'),
            user
        );

    -- Também preenche como se fosse última atualização
        :new.last_updated_date := sysdate;
        :new.last_updated_by := nvl(
            v('APP_USER'),
            user
        );
    elsif updating then
    -- Atualiza apenas os dados de modificação
        :new.last_updated_date := sysdate;
        :new.last_updated_by := nvl(
            v('APP_USER'),
            user
        );
    end if;
end;
/

alter trigger trg_rmais_certificado_audit enable;


-- sqlcl_snapshot {"hash":"75d6f67d684d079dccf2f38ae9ef061f20300ecb","type":"TRIGGER","name":"TRG_RMAIS_CERTIFICADO_AUDIT","schemaName":"RMAIS","sxml":""}