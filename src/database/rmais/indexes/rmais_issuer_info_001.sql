create index rmais_issuer_info_001 on
    rmais_issuer_info (
        cnpj
    );


-- sqlcl_snapshot {"hash":"e2703fa258af1bfce29c3af89f6b8baf18b9d47e","type":"INDEX","name":"RMAIS_ISSUER_INFO_001","schemaName":"RMAIS","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_ISSUER_INFO_001</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>RMAIS</SCHEMA>\n         <NAME>RMAIS_ISSUER_INFO</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CNPJ</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <INDEX_ATTRIBUTES></INDEX_ATTRIBUTES>\n   </TABLE_INDEX>\n</INDEX>"}