create or replace package rmais_pkg_auth is
    function gerador_cod_confirma return varchar2;

    function gerador_senha return varchar2;

    function obfuscate (
        text_in in varchar2
    ) return raw;

    function authenticate (
        p_username in varchar2,
        p_password in varchar2
    ) return boolean;

    function ctrlacessopage return boolean;

    function ctrlac (
        ppageid number default v('APP_PAGE_ID')
    ) return number;

end rmais_pkg_auth;
/


-- sqlcl_snapshot {"hash":"0688545d32d92164d89439266baa7dd02ed58a9c","type":"PACKAGE_SPEC","name":"RMAIS_PKG_AUTH","schemaName":"RMAIS","sxml":""}