create index rmais_log_passagem_por_email_idx on
    rmais_log_passagem_por_email (
        efd_header_id,
        status
    );


-- sqlcl_snapshot {"hash":"188c7be3f1eb52dfc2adaa3ff9ee0c7b72e9c404","type":"INDEX","name":"RMAIS_LOG_PASSAGEM_POR_EMAIL_IDX","schemaName":"RMAIS","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_LOG_PASSAGEM_POR_EMAIL_IDX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>RMAIS</SCHEMA>\n         <NAME>RMAIS_LOG_PASSAGEM_POR_EMAIL</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>EFD_HEADER_ID</NAME>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>STATUS</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n   </TABLE_INDEX>\n</INDEX>"}