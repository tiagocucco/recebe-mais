create or replace function get_url return varchar2 is
begin
    return owa_util.get_cgi_env('HTTP_COOKIE');
end;
/


-- sqlcl_snapshot {"hash":"cafe25d1ead5f37e1c89cc4f89725d3d1342691c","type":"FUNCTION","name":"GET_URL","schemaName":"RMAIS","sxml":""}