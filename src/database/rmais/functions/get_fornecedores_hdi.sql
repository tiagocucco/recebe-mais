create or replace function get_fornecedores_hdi (
    in_issuer_document_number in varchar2,
    bu_name                   in varchar2 default null,
    efd_header_id             in varchar2 default null,
    chamada_api               in varchar2
) return tp_fornecedores_table
    pipelined
is

    l_url      varchar2(300) := '/api/report/fornecedor/getFornecedor/';
    l_response clob;
    l_ctrl     varchar2(300);
    l_body     varchar2(600);
    l_bu       varchar2(400);
--
begin
    begin
        << verifica_bu >> if chamada_api = 0 then
            << chamada_via_api >> l_body := '{"cnpj": "'
                                            || in_issuer_document_number
                                            || '","bu": "$BU$"}';
            if bu_name is null then
                << if_bu_nulo >>
            --
                 select
                                                      json_value(receiver_info, '$.DATA.BU_NAME')
                                                  into l_bu
                                                  from
                                                      rmais_efd_headers
                                 where
                                     efd_header_id = efd_header_id;
            --
                l_body := replace(l_body, '$BU$', l_bu);
            --
            else
          --
                l_body := replace(l_body, '$BU$', bu_name);
          --
            end if "if_bu_nulo";
        --
            null;
        --
        else
            l_body := '{"cnpj": "'
                      || in_issuer_document_number
                      || '","bu": ""}';
        end if "chamada_via_api";
    exception
        when others then
            l_body := replace(l_body, '$BU$', bu_name);
    end "verifica_bu";
  --
    l_response := rmais_process_pkg.get_response(l_url, l_body);
  --
    if l_response not like '%PARTY_NAME%' then
        << localizado_oracle >>
    --
         begin
            for rw in (
                select
                    issuer_document_number,
                    issuer_name,
                    issuer_name2,--l_ctrl,
                    issuer_address,
                    issuer_address_number,
                    issuer_address_complement,
                    issuer_address_city_code,
                    issuer_address_city_name,
                    issuer_address_zip_code,
                    issuer_address_state
                from
                    (
                        select
                            issuer_document_number,
                            issuer_name,
                            issuer_name                               issuer_name2,
                            issuer_address,
                            issuer_address_number,
                            issuer_address_complement,
                            issuer_address_city_code,
                            issuer_address_city_name,
                            replace(issuer_address_zip_code, '-', '') issuer_address_zip_code,
                            issuer_address_state
                        from
                            rmais_efd_headers
                        where
                            issuer_document_number = regexp_replace(in_issuer_document_number, '[^0-9]', '')
                        order by
                            creation_date desc
                    )
                where
                    rownum = 1
            ) loop
                pipe row ( tp_fornecedores_obj(rw.issuer_document_number, rw.issuer_name, rw.issuer_name2, rw.issuer_address, rw.issuer_address_number
                ,
                                               rw.issuer_address_complement, rw.issuer_address_city_code, rw.issuer_address_city_name
                                               , rw.issuer_address_zip_code, rw.issuer_address_state) );
            end loop;
        end;
    else -- quando não localizado ele busca os dados na tabela headers
        for rw in (
            select distinct
                issuer_document_number,
                issuer_name,
                issuer_name2,
                issuer_address,
                issuer_address_number,
                issuer_address_complement,
                issuer_address_city_code,
                issuer_address_city_name,
                issuer_address_zip_code,
                issuer_address_state
            from
                json_table ( replace(
                    replace(l_response, '"DATA":{', '"DATA": [{'),
                    '}}}',
                    '}}]}'
                ), '$'
                    columns (
                        issuer_document_number varchar2 ( 4000 ) path '$.P_TAX_PAYER_NUMBER',
                        nested path '$.DATA'
                            columns (
                                issuer_name varchar2 ( 4000 ) path '$.PARTY_NAME',
                                issuer_name2 varchar2 ( 4000 ) path '$.PARTY_NAME',
                                nested path '$.ADDRESS[*]'
                                    columns (
                                        issuer_address varchar2 ( 4000 ) path '$.ADDRESS1',
                                        issuer_address_number varchar2 ( 4000 ) path '$.ADDRESS2',
                                        issuer_address_complement varchar2 ( 4000 ) path '$.ADDRESS3',
                                        issuer_address_city_code varchar2 ( 4000 ) path '$.ADDRESS4',
                                        issuer_address_city_name varchar2 ( 4000 ) path '$.CITY',
                                        issuer_address_zip_code varchar2 ( 4000 ) path '$.POSTAL_CODE',
                                        issuer_address_state varchar2 ( 4000 ) path '$.STATE',
                                        vendor_site_code varchar2 ( 4000 ) path '$.VENDOR_SITE_CODE'
                                    )
                            )
                    )
                )
            where --vendor_site_code = IN_ISSUER_DOCUMENT_NUMBER and 
                rownum = 1
        ) loop
            pipe row ( tp_fornecedores_obj(rw.issuer_document_number, rw.issuer_name, rw.issuer_name2, rw.issuer_address, rw.issuer_address_number
            ,
                                           rw.issuer_address_complement, rw.issuer_address_city_code, rw.issuer_address_city_name, rw.issuer_address_zip_code
                                           , rw.issuer_address_state) );
        end loop;
    --
    end if "localizado_oracle";
  --
/*exception when others then
  raise_application_error(-20011,'Não foi possível consumir WS para busca de fornecedor');*/
end;
/


-- sqlcl_snapshot {"hash":"8c212dacb151ba2e4b6b8cc8107e722705d68149","type":"FUNCTION","name":"GET_FORNECEDORES_HDI","schemaName":"RMAIS","sxml":""}