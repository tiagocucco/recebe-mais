create index rmais_efd_lin_valid_idx2 on
    rmais_efd_lin_valid (
        efd_line_id
    );


-- sqlcl_snapshot {"hash":"e3cf87200c0a50d2d4d170dfb8db4db22d1b3117","type":"INDEX","name":"RMAIS_EFD_LIN_VALID_IDX2","schemaName":"RMAIS","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_EFD_LIN_VALID_IDX2</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>RMAIS</SCHEMA>\n         <NAME>RMAIS_EFD_LIN_VALID</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>EFD_LINE_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n   </TABLE_INDEX>\n</INDEX>"}