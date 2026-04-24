create or replace package xxrmais_util_pkg as
  --
    g_test varchar2(30);
  --
    g_log clob;
  --
    procedure print (
        p_msg    varchar2,
        p_status number default null
    );
  --
    procedure back_list (
        p_status in out varchar2,
        p_chave  in varchar2
    );
  --
    function get_cod_serv_expecific (
        p_ibge_cidade number,
        p_serv_pref   varchar2,
        p_nome_cidade varchar2 default null
    ) return varchar2;
  --
    function base64decode (
        p_clob clob
    ) return clob;
  --
    function get_value_json (
        p_label  varchar2,
        p_source clob
    ) return clob;
  --
    function lpad (
        p varchar2,
        n number,
        c varchar2
    ) return varchar2;
  --
    function blob_to_clob (
        blob_in in blob
    ) return clob;
  --
    function clob_to_blob (
        p_data in clob
    ) return blob;
  --
    function base64encode (
        p_blob in blob
    ) return clob;
  --
    procedure send_danfe (
        p_id number
    );
  --
    function get_access_key_number (
        p_cnpj_dest  varchar2,
        p_cnpj       varchar2,
        p_issue_date date,
        p_numero_nff number
    ) return varchar2;
  --
    procedure source_docs (
        p_id in number default null
    );
  --
    procedure update_status_nfe (
        p_body clob
    );
  --
    function get_link_nfse (
        p_id number
    ) return varchar2;
  --
    procedure reprocess_doc (
        p_efd_header_id in number
    );
  --
    procedure download_blob (
        p_file_id in number
    );
  --
    procedure create_document (
        p_body    in blob,
        p_id      out number,
        p_stat    out integer,
        p_forward out varchar2
    );
  --
    function valid_field_docs (
        p_id           number,
        p_field_source varchar2,
        p_table        varchar2,
        p_field        varchar2,
        p_valor        varchar2 default null,
        p_clob         clob default null
    ) return number;
  --
    function verif_campo (
        p_table varchar2,
        p_field varchar2,
        p_valor varchar2 default null,
        p_clob  clob default null
    ) return number;
  --
    function modelo_nf (
        modelo in varchar2 default null
    ) return varchar2;

end xxrmais_util_pkg;
/


-- sqlcl_snapshot {"hash":"c2806e08580679111026845c928d3bd8701409ef","type":"PACKAGE_SPEC","name":"XXRMAIS_UTIL_PKG","schemaName":"RMAIS","sxml":""}