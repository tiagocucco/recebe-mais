create index rmais_efd_taxes_idx1 on
    rmais_efd_taxes (
        efd_line_id
    );


-- sqlcl_snapshot {"hash":"84a780f0f39d7718a7df06c914f3e074ce4e40e6","type":"INDEX","name":"RMAIS_EFD_TAXES_IDX1","schemaName":"RMAIS","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_EFD_TAXES_IDX1</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>RMAIS</SCHEMA>\n         <NAME>RMAIS_EFD_TAXES</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>EFD_LINE_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n   </TABLE_INDEX>\n</INDEX>"}