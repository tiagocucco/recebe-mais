create index rmais_json_idx on
    rmais_test_json_documents (
        data
    )
        indextype is ctxsys.context_v2 parameters ( 'SIMPLIFIED_JSON SEARCH_ON NONE DATAGUIDE ON' );


-- sqlcl_snapshot {"hash":"250d1d98fedc3bd4f4f37a5795e07a83770902ff","type":"INDEX","name":"RMAIS_JSON_IDX","schemaName":"RMAIS","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_JSON_IDX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>RMAIS</SCHEMA>\n         <NAME>RMAIS_TEST_JSON_DOCUMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>DATA</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <DOMAIN_INDEX_PROPERTIES>\n         <INDEXTYPE>\n            <SCHEMA>CTXSYS</SCHEMA>\n            <NAME>CONTEXT_V2</NAME>\n         </INDEXTYPE>\n         <PARAMETERS>SIMPLIFIED_JSON SEARCH_ON NONE DATAGUIDE ON</PARAMETERS>\n      </DOMAIN_INDEX_PROPERTIES>\n   </TABLE_INDEX>\n</INDEX>"}