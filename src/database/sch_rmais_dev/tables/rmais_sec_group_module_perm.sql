create table rmais_sec_group_module_perm (
    group_module_perm_id number,
    group_id             number not null enable,
    module_id            number not null enable,
    view_flag            char(1 byte) default 'N' not null enable,
    edit_flag            char(1 byte) default 'N' not null enable,
    process_flag         char(1 byte) default 'N' not null enable,
    delete_flag          char(1 byte) default 'N' not null enable,
    approve_flag         char(1 byte) default 'N' not null enable,
    admin_flag           char(1 byte) default 'N' not null enable,
    status               char(1 byte) default 'Y' not null enable,
    creation_date        timestamp(6) default systimestamp not null enable,
    created_by           varchar2(128 byte) not null enable,
    updated_date         timestamp(6) default systimestamp not null enable,
    updated_by           varchar2(128 byte) not null enable,
    inactive_date        timestamp(6)
);

alter table rmais_sec_group_module_perm
    add constraint chk_rmais_sec_gmp_admin
        check ( admin_flag in ( 'Y', 'N' ) ) enable;

alter table rmais_sec_group_module_perm
    add constraint chk_rmais_sec_gmp_approve
        check ( approve_flag in ( 'Y', 'N' ) ) enable;

alter table rmais_sec_group_module_perm
    add constraint chk_rmais_sec_gmp_delete
        check ( delete_flag in ( 'Y', 'N' ) ) enable;

alter table rmais_sec_group_module_perm
    add constraint chk_rmais_sec_gmp_edit
        check ( edit_flag in ( 'Y', 'N' ) ) enable;

alter table rmais_sec_group_module_perm
    add constraint chk_rmais_sec_gmp_process
        check ( process_flag in ( 'Y', 'N' ) ) enable;

alter table rmais_sec_group_module_perm
    add constraint chk_rmais_sec_gmp_status
        check ( status in ( 'Y', 'N' ) ) enable;

alter table rmais_sec_group_module_perm
    add constraint chk_rmais_sec_gmp_view
        check ( view_flag in ( 'Y', 'N' ) ) enable;

alter table rmais_sec_group_module_perm
    add constraint pk_rmais_sec_group_mod_perm primary key ( group_module_perm_id )
        using index enable;


-- sqlcl_snapshot {"hash":"30f605ec1c85658742d4f651e3bfed77dd954bd2","type":"TABLE","name":"RMAIS_SEC_GROUP_MODULE_PERM","schemaName":"SCH_RMAIS_DEV","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>SCH_RMAIS_DEV</SCHEMA>\n   <NAME>RMAIS_SEC_GROUP_MODULE_PERM</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>GROUP_MODULE_PERM_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>GROUP_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>MODULE_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>VIEW_FLAG</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT>'N'</DEFAULT>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>EDIT_FLAG</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT>'N'</DEFAULT>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>PROCESS_FLAG</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT>'N'</DEFAULT>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELETE_FLAG</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT>'N'</DEFAULT>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>APPROVE_FLAG</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT>'N'</DEFAULT>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>ADMIN_FLAG</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT>'N'</DEFAULT>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>STATUS</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT>'Y'</DEFAULT>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATION_DATE</NAME>\n            <DATATYPE>TIMESTAMP</DATATYPE>\n            <SCALE>6</SCALE>\n            <DEFAULT>SYSTIMESTAMP</DEFAULT>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>128</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_DATE</NAME>\n            <DATATYPE>TIMESTAMP</DATATYPE>\n            <SCALE>6</SCALE>\n            <DEFAULT>SYSTIMESTAMP</DEFAULT>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>128</LENGTH>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>INACTIVE_DATE</NAME>\n            <DATATYPE>TIMESTAMP</DATATYPE>\n            <SCALE>6</SCALE>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <CHECK_CONSTRAINT_LIST>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>CHK_RMAIS_SEC_GMP_VIEW</NAME>\n            <CONDITION>VIEW_FLAG IN ('Y', 'N')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>CHK_RMAIS_SEC_GMP_EDIT</NAME>\n            <CONDITION>EDIT_FLAG IN ('Y', 'N')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>CHK_RMAIS_SEC_GMP_PROCESS</NAME>\n            <CONDITION>PROCESS_FLAG IN ('Y', 'N')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>CHK_RMAIS_SEC_GMP_DELETE</NAME>\n            <CONDITION>DELETE_FLAG IN ('Y', 'N')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>CHK_RMAIS_SEC_GMP_APPROVE</NAME>\n            <CONDITION>APPROVE_FLAG IN ('Y', 'N')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>CHK_RMAIS_SEC_GMP_ADMIN</NAME>\n            <CONDITION>ADMIN_FLAG IN ('Y', 'N')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>CHK_RMAIS_SEC_GMP_STATUS</NAME>\n            <CONDITION>STATUS IN ('Y', 'N')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n      </CHECK_CONSTRAINT_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>PK_RMAIS_SEC_GROUP_MOD_PERM</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>GROUP_MODULE_PERM_ID</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n   </RELATIONAL_TABLE>\n</TABLE>"}