create or replace package rmais_auth_pkg as
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
    ) return varchar2;

    procedure callback;

end rmais_auth_pkg;
/


-- sqlcl_snapshot {"hash":"d1357f10ef8c21dd8ca0ae0d2d95083701ea112f","type":"PACKAGE_SPEC","name":"RMAIS_AUTH_PKG","schemaName":"RMAIS","sxml":""}