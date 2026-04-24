create index rmais_notas_devolucao_idx1 on
    rmais_notas_devolucao (
        access_key_number_purchase
    );


-- sqlcl_snapshot {"hash":"40cf480c4d13980cece02a5b66151c4a98eb56e1","type":"INDEX","name":"RMAIS_NOTAS_DEVOLUCAO_IDX1","schemaName":"RMAIS","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_NOTAS_DEVOLUCAO_IDX1</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>RMAIS</SCHEMA>\n         <NAME>RMAIS_NOTAS_DEVOLUCAO</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>ACCESS_KEY_NUMBER_PURCHASE</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n   </TABLE_INDEX>\n</INDEX>"}