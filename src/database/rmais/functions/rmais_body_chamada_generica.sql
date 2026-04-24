create or replace function rmais_body_chamada_generica (
    p_url      in varchar2,
    p_metodo   in varchar2,
    p_body     in clob,
    p_user     in varchar2,
    p_password in varchar2
) return clob is
    l_body_ws clob := empty_clob();
    l_body    clob := empty_clob();
begin
    select
            json_object(
                'body' value replace(
                    replace(
                        replace(
                            replace(
                                xxrmais_util_pkg.base64encode(xxrmais_util_pkg.clob_to_blob(p_body)),
                                chr(10),
                                ''
                            ),
                            chr(13),
                            ''
                        ),
                        chr(09),
                        ''
                    ),
                    ' ',
                    ''
                ),
                        'url' value cryptdata(p_url),
                        'user' value cryptdata(p_user),
                        'pass' value cryptdata(p_password),
                        'method' value cryptdata(p_metodo)
            absent on null returning clob)
        body_ws
    into l_body_ws
    from
        dual;

    return l_body_ws;
exception
    when others then
        return sqlerrm;
end;
/


-- sqlcl_snapshot {"hash":"41da2cea9c549ed89491ed5f589ba111e06f522f","type":"FUNCTION","name":"RMAIS_BODY_CHAMADA_GENERICA","schemaName":"RMAIS","sxml":""}