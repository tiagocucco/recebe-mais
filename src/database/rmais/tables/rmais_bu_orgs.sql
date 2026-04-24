create table rmais_bu_orgs (
    cnpj_bu       varchar2(44 byte),
    cnpj_lru      varchar2(44 byte),
    creation_date date
);


-- sqlcl_snapshot {"hash":"93a5b4d40cb4282b747425f9d578623c8f560096","type":"TABLE","name":"RMAIS_BU_ORGS","schemaName":"RMAIS","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_BU_ORGS</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CNPJ_BU</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>44</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CNPJ_LRU</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>44</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATION_DATE</NAME>\n            <DATATYPE>DATE</DATATYPE>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n   </RELATIONAL_TABLE>\n</TABLE>"}