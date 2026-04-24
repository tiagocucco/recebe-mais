create sequence rmais_boleto_workflow_errors_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache
20 noorder nocycle nokeep noscale global;


-- sqlcl_snapshot {"hash":"0d86c9e69f3649d65824756f9481f58a9a1f05d4","type":"SEQUENCE","name":"RMAIS_BOLETO_WORKFLOW_ERRORS_SEQ","schemaName":"RMAIS","sxml":"\n  <SEQUENCE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>RMAIS</SCHEMA>\n   <NAME>RMAIS_BOLETO_WORKFLOW_ERRORS_SEQ</NAME>\n   \n   <INCREMENT>1</INCREMENT>\n   <MINVALUE>1</MINVALUE>\n   <MAXVALUE>9999999999999999999999999999</MAXVALUE>\n   <CACHE>20</CACHE>\n   <SCALE>NOSCALE</SCALE>\n</SEQUENCE>"}