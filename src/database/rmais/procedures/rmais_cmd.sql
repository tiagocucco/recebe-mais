create or replace procedure rmais_cmd (
    p_command in varchar2
) as
    language java name 'RMais_Host.executeCommand (java.lang.String)';
/


-- sqlcl_snapshot {"hash":"d95f51b10ee1d890dfdd3703dd0781d5a211b7d6","type":"PROCEDURE","name":"RMAIS_CMD","schemaName":"RMAIS","sxml":""}