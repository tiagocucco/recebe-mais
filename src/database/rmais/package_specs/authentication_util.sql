create or replace package authentication_util is
  --used on action central app for authentication using email
    procedure process_recaptcha_reply (
        p_token       varchar2,
        p_message_out out varchar2
    );

end;
/


-- sqlcl_snapshot {"hash":"62b5e61ba7adc36dea0d1a77666db2eb1de003e6","type":"PACKAGE_SPEC","name":"AUTHENTICATION_UTIL","schemaName":"RMAIS","sxml":""}