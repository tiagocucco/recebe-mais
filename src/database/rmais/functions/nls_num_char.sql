create or replace function nls_num_char (
    p_num varchar2
) return varchar2 as
    l_nls varchar2(4000);
begin
  --
    select
        value
    into l_nls
    from
        nls_session_parameters
    where
        parameter = 'NLS_NUMERIC_CHARACTERS';
  --
    if l_nls = ',.' then
        return replace(p_num, '.', ',');
    else
        return replace(p_num, ',', '.');
    end if;

    dbms_output.put_line('NLS: ' || l_nls);
  --
end nls_num_char;
/


-- sqlcl_snapshot {"hash":"a0e37d3d84db7aaaf264f2f6fd42694f011f54d6","type":"FUNCTION","name":"NLS_NUM_CHAR","schemaName":"RMAIS","sxml":""}