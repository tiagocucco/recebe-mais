create or replace package body rmais_management_tool as

    procedure prc_backup_user_rules as
    begin
        insert into rmais_backup_user_rules
            select
                b.application_id,
                a.user_name,
                b.role_name,
                to_date(current_date, 'DD/MM/RRRR') data
            from
                apex_workspace_apex_users a,
                apex_appl_acl_user_roles  b,
                apex_applications         c
            where
                    a.workspace_name = b.workspace
                and a.user_name = b.user_name
                and b.application_id = c.application_id
                and c.alias = 'RECEBE-MAIS'
                and not exists (
                    select
                        1
                    from
                        rmais_backup_user_rules d
                    where
                            d.user_name = b.user_name
                        and d.id_app = b.application_id
                        and d.rules = b.role_name
                        and d.data = to_date(current_date, 'DD/MM/RRRR')
                );

        delete rmais_backup_user_rules d
        where
            d.data <= to_date(current_date, 'DD/MM/RRRR') - 2;

    end prc_backup_user_rules;
    --
    procedure prc_rest_backup (
        pdata        date,
        pid_app_dest number
    ) as
        nid_workspace number;
        nc            number;
    begin
        nid_workspace := apex_util.find_security_group_id(p_workspace => 'RMAIS');
        apex_util.set_security_group_id(p_security_group_id => nid_workspace);
        for x in (
            with tp_roles as (
                select
                    b.user_name,
                    b.role_name
                from
                    apex_appl_acl_user_roles b
                where
                    b.application_id = pid_app_dest
            )
            select
                a.user_name,
                a.rules
            from
                rmais_backup_user_rules a,
                tp_roles                b
            where
                    a.user_name = b.user_name (+)
                and a.rules = b.role_name (+)
                and b.user_name is null
                and a.data = to_date(pdata, 'DD/MM/YYYY')
        ) loop
            /*select  count(*)
            into    nC
            from    APEX_APPL_ACL_ROLES C
            where   C.APPLICATION_ID = pID_APP_DEST
            and     C.ROLE_NAME = X.RULES;
            if nC = 0 then
                APEX_UTIL.CREATE_USER_GROUP (
                    p_id                => pID_APP_DEST,         -- trigger will assign PK
                    p_group_name        => X.RULES,
                    p_security_group_id => null,--nID_WORKSPACE,         -- defaults to current workspace ID
                    p_group_desc        => X.RULES);
                --NULL;
            end if;*/
            apex_acl.add_user_role(
                p_application_id => pid_app_dest,
                p_user_name      => x.user_name,
                p_role_static_id => upper(x.rules)
            );
            --NULL;
        end loop;

    end prc_rest_backup;
    --
    procedure prc_import_roles (
        pid_app_orig number,
        pid_app_dest number
    ) as
        nid_workspace number;
        nc            number;
    begin
        nid_workspace := apex_util.find_security_group_id(p_workspace => 'RMAIS');
        apex_util.set_security_group_id(p_security_group_id => nid_workspace);
        for x in (
            select
                a.user_name,
                b.role_name
            from
                apex_workspace_apex_users a,
                apex_appl_acl_user_roles  b
            where
                    a.workspace_name = b.workspace
                and a.user_name = b.user_name
                and b.application_id = pid_app_orig
                and a.workspace_name = 'RMAIS'
                and not exists (
                    select
                        1
                    from
                        apex_appl_acl_user_roles c
                    where
                            c.workspace = b.workspace
                        and c.user_name = b.user_name
                        and c.application_id = pid_app_dest
                )
        ) loop
            /*select  count(*)
            into    nC
            from    APEX_APPL_ACL_ROLES C
            where   C.APPLICATION_ID = pID_APP_DEST
            and     C.ROLE_NAME = X.RULES;
            if nC = 0 then
                APEX_UTIL.CREATE_USER_GROUP (
                    p_id                => pID_APP_DEST,         -- trigger will assign PK
                    p_group_name        => X.RULES,
                    p_security_group_id => null,--nID_WORKSPACE,         -- defaults to current workspace ID
                    p_group_desc        => X.RULES);
                --NULL;
            end if;*/
            apex_acl.add_user_role(
                p_application_id => pid_app_dest,
                p_user_name      => x.user_name,
                p_role_static_id => upper(x.role_name)
            );
            --NULL;
        end loop;

    end prc_import_roles;

end rmais_management_tool;
/


-- sqlcl_snapshot {"hash":"494166ceb2840020a9d607cfb5e6b1069a4148a6","type":"PACKAGE_BODY","name":"RMAIS_MANAGEMENT_TOOL","schemaName":"RMAIS","sxml":""}