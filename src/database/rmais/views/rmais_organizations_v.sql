create or replace force editionable view rmais_organizations_v (
    id,
    cliente_id,
    nome,
    cnpj,
    endereco,
    numero,
    compl,
    bairro,
    cidade,
    estado,
    cep,
    bu_flag,
    bu_code,
    client_name
) as
    select
        rmo.id,
        rmo.cliente_id,
        rmo.nome,
        rmo.cnpj,
        rmo.endereco,
        rmo.numero,
        rmo.compl,
        rmo.bairro,
        rmo.cidade,
        rmo.estado,
        rmo.cep,
        rmo.bu_flag,
        rmo.bu_code,
        'HDI' client_name
    from
        rmais_organizations rmo;


-- sqlcl_snapshot {"hash":"393eae07f8e76e696026cb1f65b78a1382cd9210","type":"VIEW","name":"RMAIS_ORGANIZATIONS_V","schemaName":"RMAIS","sxml":""}