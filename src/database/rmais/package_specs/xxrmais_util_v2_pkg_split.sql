create or replace package xxrmais_util_v2_pkg_split as
  --
    g_test varchar2(30);
  --
    g_log clob;
  --
    type tt$rm_l is
        table of rmais_efd_lines%rowtype index by binary_integer;
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
    function base64encode_v2 (
        p_blob_in in blob
    ) return clob;
  --
    function base64encode (
        p_blob in blob
    ) return clob;
  --
    function process_cteos_link (
        p_clob in clob
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
    function get_destination (
        p_header_id number
    ) return varchar2;
  --
    function get_period_entry return varchar2;
  --
    function valid_org_func (
        p_cnpj varchar2
    ) return boolean;
  --
    function valid_source_model (
        p33_xml     apex_application_temp_files.name%type,
        p_parameter varchar2,
        p_mime_type varchar2 default null
    ) return varchar2;
  --
    function parse_xml_sefaz (
        p_id number
    ) return clob;
  --
    function get_ibge_code (
        p_citie varchar2,
        p_state varchar2
    ) return varchar2;
  --
    procedure process_xped (
        p_clob   in out clob,
        p_efd_id number
    );
  --
    procedure ws_process_return (
        p_body   in clob,
        p_status in out varchar,
        p_method in varchar2
    );
  --
    procedure create_event (
        p_efd_header_id number,
        p_event         varchar2,
        p_msg           varchar2,
        p_user          varchar2 default '-1'
    );
  --
    procedure get_cnpjs_erp;
  --
    function get_send_invoice_exception (
        p_efd_header_id number
    ) return boolean;--Falso para excecao 
  --
    procedure data_load_cod_cliente (
        p_user in varchar2
    );
  --
    procedure send_invoice_erp (
        p_efd_header_id number,
        p_payment       varchar2 default null
    );
  --
    procedure create_invoice_aluguel (
        p_p42_xlsx_worksheet varchar2,
        p_file               varchar2
    ); 
  --
    procedure generate_split_line_po (
        p_transaction_id number,
        p_type           varchar2 default 'GENERATE'
    );
  --
end xxrmais_util_v2_pkg_split;
/


-- sqlcl_snapshot {"hash":"e01be6f526f54fd874d55323716fe062c2dba095","type":"PACKAGE_SPEC","name":"XXRMAIS_UTIL_V2_PKG_SPLIT","schemaName":"RMAIS","sxml":""}