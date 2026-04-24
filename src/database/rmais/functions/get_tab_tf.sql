create or replace function get_tab_tf (
    p_rows in number
) return t_tf_tab as
    l_tab t_tf_tab := t_tf_tab();
begin
    for i in 1..p_rows loop
        l_tab.extend;
        l_tab(l_tab.last) := t_tf_row(i, 'Description for ' || i);
    end loop;

    return l_tab;
end;
/


-- sqlcl_snapshot {"hash":"15f6fc545b90ff2b9ab5597ae95a824962d62233","type":"FUNCTION","name":"GET_TAB_TF","schemaName":"RMAIS","sxml":""}