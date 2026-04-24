create or replace function enviarnotatesteshdi (
    pefd_header_id in number
) return varchar2 is

    cbbody clob := empty_clob();
    vurl   varchar2(100) := 'https://apex.hdi.uat.a7on.ai/ords/XEPDB1/rmais/rmais/inbound';

    function execchamada return clob is
    begin
        apex_web_service.g_request_headers.delete;
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        return apex_web_service.make_rest_request(
            p_url         => 'http://144.22.253.165:9000/api/bancada/v1/call',
            p_http_method => 'POST',
            p_username    => 'admin',
            p_password    => 'admin',
            p_body        => cbbody
        );

    end;

begin
    begin
        select
            source_doc_orig
        into cbbody
        from
                 rmais_ctrl_docs
            inner join rmais_efd_headers_hdi on id = doc_id
        where
                1 = 0
            and efd_header_id = pefd_header_id;

    exception
        when others then
            vurl := 'https://apex.hdi.uat.a7on.ai/ords/XEPDB1/rmais/rmais/nota_digitadaa';
            select
                body
            into cbbody
            from
                vw_nf_amb_test_hdi
            where
                efd_header_id = pefd_header_id;

            rmais_global_pkg.print(substr(cbbody, 0, 4000));
    end;

    cbbody := rmais_body_chamada_generica(vurl, 'POST', cbbody, 'LUZCON.RM', 'LuzCon11@Ti');
    return ( execchamada() );
end;
/


-- sqlcl_snapshot {"hash":"9a250fadaf034c8527c8dd877d801586dbd3dd1e","type":"FUNCTION","name":"ENVIARNOTATESTESHDI","schemaName":"RMAIS","sxml":""}