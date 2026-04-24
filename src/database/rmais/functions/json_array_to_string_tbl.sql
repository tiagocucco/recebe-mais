create or replace function json_array_to_string_tbl (
    p_json_array in varchar2
) return string_tbl_t is
    l_string_tbl string_tbl_t := string_tbl_t();
begin
    if
        p_json_array is not null
        and length(p_json_array) > 0
    then
        select
            value
        bulk collect
        into l_string_tbl
        from
            json_table ( p_json_array, '$[*]'
                columns (
                    value path '$'
                )
            );

    end if;

    return l_string_tbl;
end json_array_to_string_tbl;
/


-- sqlcl_snapshot {"hash":"7ebf47b5f461c0d324906d75b1412d0b650b7461","type":"FUNCTION","name":"JSON_ARRAY_TO_STRING_TBL","schemaName":"RMAIS","sxml":""}