create table tb_grupo_acesso_dados (
    id_grupo_acesso_dados number not null enable,
    desc_grupo            varchar2(50 byte)
);

create unique index tb_grupo_acesso_view_pk on
    tb_grupo_acesso_dados (
        id_grupo_acesso_dados
    );

alter table tb_grupo_acesso_dados
    add constraint tb_grupo_acesso_dados_pk primary key ( id_grupo_acesso_dados )
        using index tb_grupo_acesso_view_pk enable;


-- sqlcl_snapshot {"hash":"b36bc7e2b9060213184a0481a1053b76478ee503","type":"TABLE","name":"TB_GRUPO_ACESSO_DADOS","schemaName":"RMAIS","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>TB_GRUPO_ACESSO_DADOS</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>ID_GRUPO_ACESSO_DADOS</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DESC_GRUPO</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>50</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>TB_GRUPO_ACESSO_DADOS_PK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>ID_GRUPO_ACESSO_DADOS</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n   </RELATIONAL_TABLE>\n</TABLE>"}