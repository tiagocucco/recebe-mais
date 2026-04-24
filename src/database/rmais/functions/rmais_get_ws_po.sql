create or replace function rmais_get_ws_po (
    p_clob in clob default null
) return t_tf_tab as

    l_count_array number;
    l_reg         t_tf_row;
    l_sql         varchar2(400);
    l_clob        clob;
    l_count       number := 0;
    type rep_cnts is record ( -- NEWLY INCLUDED RECORD DECLARATION
            po_header_id number,               -- NEWLY INCLUDED RECORD DECLARATION
            po_no        varchar2(100)
    );                     -- NEWLY INCLUDED RECORD DECLARATION
    type repcnt is
        table of rep_cnts;
    l_tab         repcnt := repcnt();
begin
    select
        get_size_array(data)
    into l_count_array
    from
        rmais_test_json_documents;
 --l_count_array := GET_SIZE_ARRAY(P_CLOB);
    dbms_output.put_line('Atribuido arrays n: ' || l_count_array);
    for x in 1..l_count_array loop
        l_sql := 'SELECT to_number(JSON_VALUE(d.header, '''
                 || '$'
                 || ''
                 || '['
                 || l_count
                 || '].PO_HEADER_ID'''
                 || '))       "PO_HEADER_ID",
       JSON_VALUE(d.header, '''
                 || '$['
                 || l_count
                 || '].PO_NUM'''
                 || ')             "PO_NUM"
       FROM
    (SELECT JSON_QUERY(a.data, '''
                 || '$.HEADER'''
                 || ' RETURNING CLOB  ) HEADER
       FROM RMAIS_TEST_JSON_DOCUMENTS a) d';

        dbms_output.put_line('L_SQL: ' || l_sql);
        execute immediate l_sql
        into
            l_reg.po_header_id,
            l_reg.po_num;
        dbms_output.put_line('PO_HEADER_ID: ' || l_reg.po_header_id);
        l_tab.extend;
        l_tab(l_tab.last) := rep_cnts(l_reg.po_header_id, l_reg.po_num);

        l_count := l_count + 1;
        l_reg := null;
    end loop;
  --RETURN l_tab;
end;
/


-- sqlcl_snapshot {"hash":"804b5fc368d7603bb8c5dfc5514dad11107f9454","type":"FUNCTION","name":"RMAIS_GET_WS_PO","schemaName":"RMAIS","sxml":""}