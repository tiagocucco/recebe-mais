create unique index rmais_integrated_erp_idx on
    rmais_integrated_erp (
        integration_id
    );


-- sqlcl_snapshot {"hash":"8d03f1d9e59b88de310bac1af6f8610b2e13e6df","type":"INDEX","name":"RMAIS_INTEGRATED_ERP_IDX","schemaName":"RMAIS","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <UNIQUE></UNIQUE>\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_INTEGRATED_ERP_IDX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>RMAIS</SCHEMA>\n         <NAME>RMAIS_INTEGRATED_ERP</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>INTEGRATION_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n   </TABLE_INDEX>\n</INDEX>"}