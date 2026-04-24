create or replace procedure json_array_traversal (
    json_document_in in clob,
    leaf_action_in   in varchar2,
    level_in         in integer default 0
)
    authid definer
is
    l_array   json_array_t;
    l_object  json_object_t;
    l_keys    json_key_list;
    l_element json_element_t;
begin
    l_array := json_array_t.parse(json_document_in);
    put_line('Traverse: ' || l_array.stringify(),
             level_in);
    for indx in 0..l_array.get_size - 1 loop
        put_line('Index: ' || indx, level_in);
        case
            when l_array.get(indx).is_string then
                execute immediate leaf_action_in
                    using l_array.get_string(indx), level_in;
            when l_array.get(indx).is_object then
                l_object := treat(l_array.get(indx) as json_object_t);
                l_keys := l_object.get_keys;
                for k_index in 1..l_keys.count loop
                    execute immediate leaf_action_in
                        using l_keys(k_index), level_in;
                end loop;

            when l_array.get(indx).is_array then
                json_array_traversal(
                    treat(l_array.get(indx) as json_array_t).stringify(),
                    leaf_action_in,
                    level_in + 1
                );
            else
                dbms_output.put_line('*** No match for type on array index ' || indx);
        end case;

    end loop;

end;
/


-- sqlcl_snapshot {"hash":"c28abe78da7f14d324cdda7ec5ada97d2ad64b93","type":"PROCEDURE","name":"JSON_ARRAY_TRAVERSAL","schemaName":"RMAIS","sxml":""}