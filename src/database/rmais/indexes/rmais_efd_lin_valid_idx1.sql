create index rmais_efd_lin_valid_idx1 on
    rmais_efd_lin_valid (
        efd_header_id
    );


-- sqlcl_snapshot {"hash":"3708fbe0f73c6c966ab09f1bb1f98d5965c9a682","type":"INDEX","name":"RMAIS_EFD_LIN_VALID_IDX1","schemaName":"RMAIS","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_EFD_LIN_VALID_IDX1</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>RMAIS</SCHEMA>\n         <NAME>RMAIS_EFD_LIN_VALID</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>EFD_HEADER_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n   </TABLE_INDEX>\n</INDEX>"}