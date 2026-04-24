create unique index rmais_integrated_docs_idx on
    rmais_integrated_docs (
        id
    );


-- sqlcl_snapshot {"hash":"66274617403040698c2922cb3002dc7645cfd74d","type":"INDEX","name":"RMAIS_INTEGRATED_DOCS_IDX","schemaName":"RMAIS","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <UNIQUE></UNIQUE>\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_INTEGRATED_DOCS_IDX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>RMAIS</SCHEMA>\n         <NAME>RMAIS_INTEGRATED_DOCS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n   </TABLE_INDEX>\n</INDEX>"}