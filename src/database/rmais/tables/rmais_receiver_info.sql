create global temporary table rmais_receiver_info (
    cnpj varchar2(100 byte),
    info clob,
    type varchar2(20 byte)
) on commit delete rows;

alter table rmais_receiver_info add check ( info is json ) enable;


-- sqlcl_snapshot {"hash":"294b947fe68373c02bef4a4694ee2895f30256c0","type":"TABLE","name":"RMAIS_RECEIVER_INFO","schemaName":"RMAIS","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <GLOBAL_TEMPORARY></GLOBAL_TEMPORARY>\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_RECEIVER_INFO</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CNPJ</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>100</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>INFO</NAME>\n            <DATATYPE>CLOB</DATATYPE>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>TYPE</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>20</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <CHECK_CONSTRAINT_LIST>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <CONDITION>INFO IS JSON</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n      </CHECK_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <ON_COMMIT>DELETE</ON_COMMIT>\n   </RELATIONAL_TABLE>\n</TABLE>"}