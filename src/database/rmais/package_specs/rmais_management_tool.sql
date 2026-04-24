create or replace package rmais_management_tool as
    procedure prc_backup_user_rules;
    --
    procedure prc_rest_backup (
        pdata        date,
        pid_app_dest number
    );
    --
    procedure prc_import_roles (
        pid_app_orig number,
        pid_app_dest number
    );

end rmais_management_tool;
/


-- sqlcl_snapshot {"hash":"5b53d9f02ea595b59fc4f18c8af0c4951921b106","type":"PACKAGE_SPEC","name":"RMAIS_MANAGEMENT_TOOL","schemaName":"RMAIS","sxml":""}