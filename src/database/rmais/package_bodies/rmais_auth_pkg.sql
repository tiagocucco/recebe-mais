create or replace package body rmais_auth_pkg as

    function get_callback_url (
        p_x01           in varchar2 default null,
        p_x02           in varchar2 default null,
        p_x03           in varchar2 default null,
        p_x04           in varchar2 default null,
        p_x05           in varchar2 default null,
        p_x06           in varchar2 default null,
        p_x07           in varchar2 default null,
        p_x08           in varchar2 default null,
        p_x09           in varchar2 default null,
        p_x10           in varchar2 default null,
        p_callback_name in varchar2 default null
    ) return varchar2 as
    begin
        return null;
       
       /*
       RETURN apex_210100.WWV_FLOW_UTILITIES.HOST_URL('APEX_PATH')||
              COALESCE (
                  P_CALLBACK_NAME,
                  'apex_authentication.callback' )||
              '?p_session_id='|| apex_210100.WWV_FLOW_SECURITY.G_INSTANCE||
              '&p_app_id='||apex_210100.WWV_FLOW.G_FLOW_ID||
              '&p_ajax_identifier='||apex_210100.WWV_FLOW_UTILITIES.URL_ENCODE2(apex_210100.WWV_FLOW_PLUGIN.GET_AJAX_IDENTIFIER)||
              '&p_page_id='||apex_210100.WWV_FLOW.G_FLOW_STEP_ID||
              CASE WHEN P_X01 IS NOT NULL THEN '&p_x01='||apex_210100.WWV_FLOW_UTILITIES.URL_ENCODE2(P_X01) END||
              CASE WHEN P_X02 IS NOT NULL THEN '&p_x02='||apex_210100.WWV_FLOW_UTILITIES.URL_ENCODE2(P_X02) END||
              CASE WHEN P_X03 IS NOT NULL THEN '&p_x03='||apex_210100.WWV_FLOW_UTILITIES.URL_ENCODE2(P_X03) END||
              CASE WHEN P_X04 IS NOT NULL THEN '&p_x04='||apex_210100.WWV_FLOW_UTILITIES.URL_ENCODE2(P_X04) END||
              CASE WHEN P_X05 IS NOT NULL THEN '&p_x05='||apex_210100.WWV_FLOW_UTILITIES.URL_ENCODE2(P_X05) END||
              CASE WHEN P_X06 IS NOT NULL THEN '&p_x06='||apex_210100.WWV_FLOW_UTILITIES.URL_ENCODE2(P_X06) END||
              CASE WHEN P_X07 IS NOT NULL THEN '&p_x07='||apex_210100.WWV_FLOW_UTILITIES.URL_ENCODE2(P_X07) END||
              CASE WHEN P_X08 IS NOT NULL THEN '&p_x08='||apex_210100.WWV_FLOW_UTILITIES.URL_ENCODE2(P_X08) END||
              CASE WHEN P_X09 IS NOT NULL THEN '&p_x09='||apex_210100.WWV_FLOW_UTILITIES.URL_ENCODE2(P_X09) END||
              CASE WHEN P_X10 IS NOT NULL THEN '&p_x10='||apex_210100.WWV_FLOW_UTILITIES.URL_ENCODE2(P_X10) END;
       */
    end get_callback_url;

    procedure callback as
    begin
    --htp.p('aeeeee');
        null;
    end;

end rmais_auth_pkg;
/


-- sqlcl_snapshot {"hash":"b50ea32f59e820758fc16b5b452da6826dbc5e22","type":"PACKAGE_BODY","name":"RMAIS_AUTH_PKG","schemaName":"RMAIS","sxml":""}