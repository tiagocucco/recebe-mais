create table tb_grupo_usuario_ac (
    id_grupo_usuario     number not null enable,
    num_grupo_usuario_ac number not null enable,
    id_acesso            number
);

create unique index tb_grupo_usuario_ac_pk on
    tb_grupo_usuario_ac (
        id_grupo_usuario,
        num_grupo_usuario_ac
    );

alter table tb_grupo_usuario_ac
    add constraint tb_grupo_usuario_ac_pk
        primary key ( id_grupo_usuario,
                      num_grupo_usuario_ac )
            using index tb_grupo_usuario_ac_pk enable;


-- sqlcl_snapshot {"hash":"3b6a4ffcd6de4069e5f513cc74ae03db0bf21a15","type":"TABLE","name":"TB_GRUPO_USUARIO_AC","schemaName":"RMAIS","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>TB_GRUPO_USUARIO_AC</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>ID_GRUPO_USUARIO</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>NUM_GRUPO_USUARIO_AC</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>ID_ACESSO</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>TB_GRUPO_USUARIO_AC_PK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>ID_GRUPO_USUARIO</NAME>\n               </COL_LIST_ITEM>\n               <COL_LIST_ITEM>\n                  <NAME>NUM_GRUPO_USUARIO_AC</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n   </RELATIONAL_TABLE>\n</TABLE>"}