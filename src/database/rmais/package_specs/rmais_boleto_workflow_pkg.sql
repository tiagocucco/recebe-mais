create or replace package rmais_boleto_workflow_pkg as
  --
    g_test varchar2(30);
  --
    g_log clob;
  --
    g_stat_ok constant integer := 200;
    g_stat_created constant integer := 201;
    g_stat_bad_request constant integer := 400;
    g_stat_unauthorized constant integer := 401;
    g_stat_inter_server_error constant integer := 500;
  --
    procedure create_event_boleto (
        p_body    in blob,
        p_stat    out integer,
        p_forward out varchar2
    );
  --                              
end rmais_boleto_workflow_pkg;
/


-- sqlcl_snapshot {"hash":"009d3619f3fce674ed359ddb2356685f3107fb63","type":"PACKAGE_SPEC","name":"RMAIS_BOLETO_WORKFLOW_PKG","schemaName":"RMAIS","sxml":""}