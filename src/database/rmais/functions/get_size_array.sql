create or replace function get_size_array (
    p_clob clob
) return number as
 -- l_clob         CLOB;
    l_top_obj json_object_t;
 -- l_dept_obj     JSON_OBJECT_T;
 -- l_emp_arr      JSON_ARRAY_T;
 -- l_emp_obj      JSON_OBJECT_T;
begin
  --
    l_top_obj := json_object_t(p_clob);
    return l_top_obj.get_size - 1;
exception
    when others then
        return -1;
end;
/


-- sqlcl_snapshot {"hash":"2e9f0b09d7fe262254e8713d5c46cb618421c238","type":"FUNCTION","name":"GET_SIZE_ARRAY","schemaName":"RMAIS","sxml":""}