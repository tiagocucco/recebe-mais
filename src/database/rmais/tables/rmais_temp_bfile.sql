create global temporary table rmais_temp_bfile (
    b_file bfile
) on commit delete rows;


-- sqlcl_snapshot {"hash":"99fc1f64213569fca1f1a4ab0a6685b76be4028e","type":"TABLE","name":"RMAIS_TEMP_BFILE","schemaName":"RMAIS","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <GLOBAL_TEMPORARY></GLOBAL_TEMPORARY>\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_TEMP_BFILE</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>B_FILE</NAME>\n            <DATATYPE>BFILE</DATATYPE>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <ON_COMMIT>DELETE</ON_COMMIT>\n   </RELATIONAL_TABLE>\n</TABLE>"}