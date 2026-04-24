create or replace package rmais_manifesto as
  --
    g_test varchar2(30);
  --
    g_log clob;
  --
    procedure create_manifest (
        p_chave varchar2,
        p_date  in out date,
        p_tipo  varchar2 default '210200'
    );
  --
    procedure manifest_cancel (
        p_danfe         varchar2,
        p_cnpj          varchar2,
        p_reason        varchar2 -- Crystian 25/06/2020
        ,
        p_justif        varchar2 -- Crystian 25/06/2020
        ,
        p_return        out varchar2,
        p_efd_header_id in number,
        p_user          varchar2
    );
  --
    procedure reject_nf (
        p_msg           varchar2,
        p_efd_header_id number,
        p_user          varchar2
    );
  --
    procedure manifest_status_ap (
        l_id number default null
    );
  --
    procedure manifest_conclusao (
        p_danfe varchar2,
        p_cnpj  varchar2,
        p_log   out clob
    );
  --
    procedure process_conclusao (
        p_danfe varchar2 default null,
        p_date  date default null
    );
  --
    procedure print (
        p_msg varchar2
    );
  --
end rmais_manifesto;
/


-- sqlcl_snapshot {"hash":"fd6af1504b10e41b5f5380acf99d3ada236a0b84","type":"PACKAGE_SPEC","name":"RMAIS_MANIFESTO","schemaName":"RMAIS","sxml":""}