create sequence seq_rmais_users_access_id minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20
noorder nocycle nokeep noscale global;


-- sqlcl_snapshot {"hash":"3089474adbaef591eec6c4ee6cee006c0c7e0846","type":"SEQUENCE","name":"SEQ_RMAIS_USERS_ACCESS_ID","schemaName":"SCH_RMAIS_DEV","sxml":"\n  <SEQUENCE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>SCH_RMAIS_DEV</SCHEMA>\n   <NAME>SEQ_RMAIS_USERS_ACCESS_ID</NAME>\n   \n   <INCREMENT>1</INCREMENT>\n   <MINVALUE>1</MINVALUE>\n   <MAXVALUE>9999999999999999999999999999</MAXVALUE>\n   <CACHE>20</CACHE>\n   <SCALE>NOSCALE</SCALE>\n</SEQUENCE>"}