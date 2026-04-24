create or replace package body authentication_util is
  --used on action central app for authentication using email
    procedure process_recaptcha_reply (
        p_token       varchar2,
        p_message_out out varchar2
    ) is

        l_private_key     varchar2(4000) := apex_app_setting.get_value(p_name => 'RECAPTCHAV3_SECRET_KEY');
        l_wallet_path     varchar2(4000) := '';
        l_wallet_pwd      varchar2(4000) := '';
        l_error_msg       varchar2(4000) := 'Please Check the reCaptcha before proceeding.';
        l_parm_name_list  apex_application_global.vc_arr2;
        l_parm_value_list apex_application_global.vc_arr2;
        l_rest_result     varchar2(32767);
        l_result          apex_plugin.t_page_item_validation_result;
    begin
      -- Check if plug-in private key is set
        if l_private_key is null then
            raise_application_error(-20999, 'No Private Key has been set for the reCaptcha plug-in! Get one at https://www.google.com/recaptcha/admin/create'
            );
        end if;
      -- Has the user checked the reCaptcha Box and responded to the challenge?
        if p_token is null then
            l_result.message := l_error_msg;
        --return l_result;
        end if;
      -- Build the parameters list for the post action.
      -- See https://developers.google.com/recaptcha/docs/verify?csw=1 for more details
        l_parm_name_list(1) := 'secret';
        l_parm_value_list(1) := l_private_key;
        l_parm_name_list(2) := 'response';
        l_parm_value_list(2) := p_token;
        l_parm_name_list(3) := 'remoteip';
        l_parm_value_list(3) := owa_util.get_cgi_env('REMOTE_ADDR');
      -- Set web service header rest request
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded';
      -- Call the reCaptcha REST service to verify the response against the private key
        l_rest_result := wwv_flow_utilities.clob_to_varchar2(apex_web_service.make_rest_request(
            p_url         => 'http://www.google.com/recaptcha/api/siteverify',
            p_http_method => 'POST',
            p_parm_name   => l_parm_name_list,
            p_parm_value  => l_parm_value_list,
            p_wallet_path => l_wallet_path,
            p_wallet_pwd  => l_wallet_pwd
        ));
      -- Delete the request header
        apex_web_service.g_request_headers.delete;
      -- Check the HTTPS status call
        if apex_web_service.g_status_code = '200' then -- sucessful call
        -- Check the returned json for successfull validation
            apex_json.parse(l_rest_result);
            if apex_json.get_varchar2(p_path => 'success') = 'false' then
                l_result.message := l_rest_result;
                apex_error.add_error(
                    p_message          => 'Failed to verify your request!',
                    p_display_location => apex_error.c_inline_in_notification
                );
          /* possible errors are :
             Error code              Description
             ---------------------- ------------------------------------------------
             missing-input-secret   The secret parameter is missing.
             invalid-input-secret   The secret parameter is invalid or malformed.
             missing-input-response   The response parameter is missing.
             invalid-input-response   The response parameter is invalid or malformed.
             bad-request   The request is invalid or malformed.
          */
            else -- success = 'true'
                l_result.message := 'VERIFIED'; --null
          --l_result.message := l_rest_result;
            end if;

        else -- unsucessful call
            l_result.message := 'reCaptcha HTTPS request status : ' || apex_web_service.g_status_code;
            apex_error.add_error(
                p_message          => 'Failed to verify your request!',
                p_display_location => apex_error.c_inline_in_notification
            );
        end if;

        p_message_out := l_result.message;
    end process_recaptcha_reply;

end;
/


-- sqlcl_snapshot {"hash":"6ffa9041ea97e6ead823e87cfd0583db1603adf0","type":"PACKAGE_BODY","name":"AUTHENTICATION_UTIL","schemaName":"RMAIS","sxml":""}