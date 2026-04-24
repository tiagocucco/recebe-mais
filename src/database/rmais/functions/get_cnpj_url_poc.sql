create or replace function get_cnpj_url_poc (
    pcnpj in varchar2
) return clob as
    l_return clob;
begin
    select
            json_object(
                'items' value json_arrayagg(
                    json_object(
                        'ISSUER_NAME' is issuer_name,
                                'ISSUER_ADDRESS' is issuer_address,
                                'ISSUER_ADDRESS_NUMBER' is issuer_address_number,
                                'ISSUER_ADDRESS_COMPLEMENT' is issuer_address_complement,
                                'ISSUER_ADDRESS_STATE' is issuer_address_state,
                                'ISSUER_ADDRESS_ZIP_CODE' is regexp_replace(issuer_address_zip_code, '[^0-9]'),
                                'ISSUER_ADDRESS_CITY_NAME' is issuer_address_city_name
                    )
                returning clob)
            )
        endereco
    into l_return
    from
        json_table ( rmais_process_pkg.get_response_v3('http://receitaws.com.br/v1/cnpj/' || pcnpj, null, 'GET'), '$'
            columns (
                issuer_name varchar2 ( 400 ) path '$.nome',
                issuer_address varchar2 ( 400 ) path '$.logradouro',
                issuer_address_number varchar2 ( 400 ) path '$.numero',
                issuer_address_complement varchar2 ( 400 ) path '$.complemento',
                issuer_address_state varchar2 ( 400 ) path '$.uf',
                issuer_address_zip_code varchar2 ( 400 ) path '$.cep',
                issuer_address_city_name varchar2 ( 400 ) path '$.municipio'
            )
        );

    return l_return;
end;
/


-- sqlcl_snapshot {"hash":"0b74d95973b76fdd977671c539b58664b65c1f48","type":"FUNCTION","name":"GET_CNPJ_URL_POC","schemaName":"RMAIS","sxml":""}