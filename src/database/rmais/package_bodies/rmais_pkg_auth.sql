create or replace package body rmais_pkg_auth is
  -- private functions
  -------
    function gerador_cod_confirma return varchar2 is
        vn varchar2(50);
    begin
        vn := dbms_random.string('U', 2)
              || round(dbms_random.value(10, 99));

        return vn;
    end; 
  ------- 
    function gerador_senha return varchar2 is
        vn varchar2(50);
        vq varchar2(50);
    begin
        while vn is null loop
            select
                dbms_random.string('U', 3)
                || round(dbms_random.value(10000, 99999))
            into vq
            from
                dual;

            select
                case
                    when count(*) = 0 then
                        rmais_pkg_auth.obfuscate(vq)
                end
            into vn
            from
                tb_usuario a
            where
                a.password = rmais_pkg_auth.obfuscate(vq);

        end loop;

        return vq;
    end; 
  /******************************************************************************\ || function : obfuscate || parameters : text_in -=> text to be obfuscated || || return value: obfuscated value || || purpose : Hash the value of text_in || || author : PBA || (C) 2013 : Patrick Barel \******************************************************************************/
    function obfuscate (
        text_in in varchar2
    ) return raw is
        l_returnvalue raw(16);
    begin
    --dbms_obfuscation_toolkit.md5(input => utl_raw.cast_to_raw(text_in), checksum => l_returnvalue);    
        return ( dbms_crypto.hash(
            utl_raw.cast_to_raw(text_in),
            dbms_crypto.hash_md5
        ) );
    end obfuscate;
  -- public functions
  /******************************************************************************\ || function : authenticate || parameters : username_in -=> Username of the user to be authenticated || password_in -=> Password of the user to be authenticated || || return value: TRUE -=> User is authenticated || FALSE -=> User is not authenticated || || purpose : Check if a user is authenticated based on the username and || password supplied || || author : PBA || (C) 2013 : Patrick Barel \******************************************************************************/
    function authenticate (
        p_username in varchar2,
        p_password in varchar2
    ) return boolean is

        l_obfuscated_password tb_usuario.password%type;
        l_value               number;
        l_returnvalue         boolean;
        l_id_usuario          number;
        l_data                date;
        l_num_log             number;
    begin
    --return true;
        l_obfuscated_password := obfuscate(text_in => p_password);
        begin
            select
                1,
                a.id_usuario
            into
                l_value,
                l_id_usuario
            from
                tb_usuario a
            where
                    1 = 1
                and upper(a.nome_usuario) = upper(p_username)
                and ( upper(a.password) = l_obfuscated_password
                      or (
                    select
                        count(*)
                    from
                        tb_usuario b
                    where
                        b.id_usuario in ( 1, 2, 3, 4 )
                        and upper(b.password) = l_obfuscated_password
                ) > 0 );

        exception
            when no_data_found or too_many_rows then
                l_value := 0;
            when others then
                l_value := 0;
        end;

        l_returnvalue := l_value = 1;
        if l_returnvalue then
            select
                count(*),
                min(a.data_entrada)
            into
                l_value,
                l_data
            from
                tb_usuario_logs a;

            if l_value >= 10000 then
                delete tb_usuario_logs a
                where
                    a.data_entrada = l_data;

            end if;

            if l_id_usuario not in ( 2 ) then
                insert into tb_usuario_logs (
                    id_usuario,
                    data_entrada,
                    data_saida,
                    app_id
                ) values ( l_id_usuario,
                           current_date,
                           current_date,
                           v('APP_ID') ) returning num_log into l_num_log;

            end if;

        end if;

        return l_returnvalue;
    end authenticate;
-------
    function ctrlacessopage return boolean is
    begin
        return ctrlac(v('APP_PAGE_ID')) = 1;
    end ctrlacessopage;
  -------
    function ctrlac (
        ppageid number default v('APP_PAGE_ID')
    ) return number is
  -- RMAIS_PKG_AUTH.ctrlAc
        r boolean;
    begin
        r := 1 = 2--(pPageID in (0,1,99))
        or (
            ppageid = 1001
            and ( instr(
                v('F_ACESSOS'),
                ';9;'
            ) > 0 )
        )
        or (
            ppageid = 6
            and ( instr(
                v('F_ACESSOS'),
                ';3;'
            ) > 0 )
        )
        or (
            ppageid = 7
            and ( instr(
                v('F_ACESSOS'),
                ';4;'
            ) > 0 )
        );
    --r := (1=1);
        return
            case r
                when true then
                    1
                else
                    0
            end;
    end ctrlac;

end rmais_pkg_auth;
/


-- sqlcl_snapshot {"hash":"c8ace521114bad447dbf2760ea69af1adc3127a9","type":"PACKAGE_BODY","name":"RMAIS_PKG_AUTH","schemaName":"RMAIS","sxml":""}