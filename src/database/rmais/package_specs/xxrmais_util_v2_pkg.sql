create or replace package xxrmais_util_v2_pkg as
  --
    g_test varchar2(30);
  --
    g_log clob;
  --
    type tp_fornecedores_obj is record (
            issuer_document_number    varchar2(15),
            issuer_name               varchar2(120),
            l_ctrl                    varchar2(300),
            issuer_address            varchar2(255),
            issuer_address_number     varchar2(60),
            issuer_address_complement varchar2(60),
            issuer_address_city_code  varchar2(60),
            issuer_address_city_name  varchar2(60),
            issuer_address_zip_code   number,
            issuer_address_state      varchar2(2)
    );
  --
    type tp_fornecedores_table is
        table of tp_fornecedores_obj;
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
    function get_fornecedores (
        in_issuer_document_number in varchar2,
        bu_name                   in varchar2 default null,
        efd_header_id             in varchar2 default null,
        chamada_api               in varchar2
    ) return tp_fornecedores_table
        pipelined;
  --
    procedure print_clob_to_output (
        p_clob in clob
    );
  --
    function get_filial (
        p_header_id                in varchar2,
        p_receiver_document_number in varchar2,
        p_role                     varchar2 default null
    ) return varchar2;
  --
    function get_metodo_pagamento (
        p_header_id in varchar2
    ) return varchar2;
  --
    --
    procedure alterar_senha (
        p_usuario   in varchar2,
        p_workspace in varchar2,
        p_texto     in varchar2
    );
    --
    procedure set_workflow (
        p_efd_header_id in varchar2,
        p_descricao     in varchar2,
        p_usuario       in varchar2
    );
    --
    procedure refresh_status_bancada (
        pr_doc_id       in varchar2,
        pr_status       in varchar2,
        pr_id_ctrl_docs in number,
        pr_descricao    in varchar2
    );
    --
end xxrmais_util_v2_pkg;
/


-- sqlcl_snapshot {"hash":"f4d1c2369841fb46bb03aabd7702d9306feedd3c","type":"PACKAGE_SPEC","name":"XXRMAIS_UTIL_V2_PKG","schemaName":"RMAIS","sxml":""}