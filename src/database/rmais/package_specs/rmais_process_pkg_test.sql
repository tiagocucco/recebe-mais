create or replace package rmais_process_pkg_test as
  --
    g_po_find boolean := false;
  --
    type r$char is record (
            cod varchar2(32000),
            val varchar2(32000)
    );
  --
    type t$char is
        table of r$char index by varchar2(4000);
  --
    type tt$dis is
        table of rmais_efd_distributions%rowtype index by binary_integer;
  --
    type t$dis is
        table of tt$dis index by binary_integer;
  --
    type t$shp is
        table of rmais_efd_shipments%rowtype index by binary_integer;
  --
    type t$po is
        table of rmais_issuer_info_v%rowtype;
  --
    type t$po_line is
        table of rmais_get_po_line_vw%rowtype;
  --
    type t$po2 is
        table of rmais_get_ws_po_base64%rowtype;
  --
    type r$iss is record (
            establishment_name  varchar2(300),
            establishment_id    number,
            legal_entity_id     number,
            registration_number varchar2(20),
            party_id            number,
            location_id         number,
            location_name       varchar2(300)
    );
  --
    type t$iss is
        table of r$iss index by varchar2(100);
  --
    type r$rec is record (
            party_name          varchar2(300),
            tax_payer_number    varchar2(20),
            reporting_type_code varchar2(50),
            party_id            number,
            supplier_flag       varchar2(5)
    );
  --
    type t$rec is
        table of r$rec index by varchar2(100);
  --
    type r$lines is record (
            rlin         rmais_efd_lines%rowtype,
            rshp         t$shp,
            rdis         t$dis,
            chave        varchar2(500),
            cod_produto  varchar2(500),
            xcod_produto varchar2(500),
            des_produto  varchar2(1500),
            xdes_produto varchar2(1500),
            cod_barras   varchar2(500),
            qtd_orig     number,
            ocurr_seq    number,
            ocurr_tot    number,
            organization varchar2(100),
            cfo_saida    varchar2(100),
            cst_origem   varchar2(1),
            cst_pis      varchar2(10),
            cst_cofins   varchar2(10),
            cst_icms     varchar2(10),
            cst_ipi      varchar2(10),
            ship_via     varchar2(500)
    );
  --
    type t$lines is
        table of r$lines index by binary_integer;
  --
    type r$source is record (
            rctrl rmais_ctrl_docs%rowtype,
            rrec  r$rec,
            riss  r$iss,
            rhea  rmais_efd_headers%rowtype,
            rlin  t$lines
    );
  --
    type t$source is
        table of r$source index by binary_integer;
  --
    x_sysdate date := sysdate;
  --
    g_shipments t$char;
  --
    procedure delete_efd (
        p_key varchar2
    );
  --
    function get_ws return varchar2
        result_cache;
  --
    function ins_ws_info (
        p_trx_method in varchar2 default null
    ) return number;
  --
  --PROCEDURE Set_ws_info (p_trx_id IN NUMBER, p_trx_info IN CLOB, p_trx_return OUT NOCOPY NUMBER);
  --
    procedure set_ws_info (
        p_trx_id   in number,
        p_trx_info in clob default null--, p_trx_return OUT NOCOPY NUMBER
    );
  --
    function get_item_na (
        p_cnpj_fornecedor varchar2,
        p_item_code       varchar2
    ) return varchar2;
  --
    function text2base64 (
        p_txt   in varchar2,
        p_encod in varchar2 default null
    ) return varchar2;
  --
    function base642text (
        p_txt   in varchar2,
        p_encod in varchar2 default null
    ) return varchar2;
  --
    function get_parameter (
        p_control   in varchar2,
        p_field     varchar2 default 'TEXT_VALUE',
        p_condition varchar2 default null
    ) return varchar2
        result_cache;
  --
    function get_response (
        p_url     in varchar2,
        p_content in clob default null,
        p_type    in varchar2 default 'GET'
    ) return clob;
  --
    function get_response2 (
        p_url     in varchar2,
        p_content in clob default null,
        p_type    in varchar2 default 'GET'
    ) return clob;
  --
/*  PROCEDURE insert_crtl(
            p_document_number IN NUMBER
          , p_key IN VARCHAR2
          , p_issuer_document_number IN NUMBER
          , p_org_id IN NUMBER
          , p_organization_id IN NUMBER
          , p_last_update IN DATE
          , p_log IN CLOB
          , p_status IN VARCHAR2
          , p_invoice_param IN NUMBER DEFAULT NULL);
  --
  PROCEDURE Log_Efd(
            p_efd_validation_id NUMBER
          , p_message_code     VARCHAR2
          , p_efd_line_number  NUMBER
          , p_entity_name      VARCHAR2
          , p_event_type       NUMBER
          , p_token1           VARCHAR2 DEFAULT NULL
          , p_token1Val        VARCHAR2 DEFAULT NULL
          , p_token2           VARCHAR2 DEFAULT NULL
          , p_token2Val        VARCHAR2 DEFAULT NULL
          , p_token3           VARCHAR2 DEFAULT NULL
          , p_token3Val        VARCHAR2 DEFAULT NULL
          , p_token4           VARCHAR2 DEFAULT NULL
          , p_token4Val        VARCHAR2 DEFAULT NULL
          , p_token5           VARCHAR2 DEFAULT NULL
          , p_token5Val        VARCHAR2 DEFAULT NULL
          , p_token6           VARCHAR2 DEFAULT NULL
          , p_token6Val        VARCHAR2 DEFAULT NULL);*/
  --
    procedure main (
        p_header_id in number default null,
        p_acces_key in varchar2 default null,
        p_flag_auto in varchar2 default 'N' --processo automatico ou debug Y  
        ,
        p_send_erp  in varchar2 default null
    );
  --
    procedure set_po_array (
        p_fornec in varchar2,
        p_receiv in varchar2,
        p_po     in out nocopy t$po
    );
  --
    procedure set_po_array (
        p_fornec in varchar2,
        p_receiv in varchar2
    );
  --
    function set_transaction_po_arrays (
        p_fornec         in varchar2,
        p_receiv         in varchar2,
        p_trasanction_id number
    ) return number;
  --
    function get_po_list_v2 (
        p_parameter in varchar2
    ) return number;
  --
    procedure insert_ws_info (
        p_id     in out number,
        p_method varchar2 default 'GET_PO',
        p_clob   clob default null
    );
  --
    procedure ins_issuer (
        p_taxpayer rmais_issuer_info%rowtype
    );
  --
    procedure ins_receiv (
        p_taxpayer rmais_receiver_info%rowtype
    );
  --
    function get_po_list (
        p_parameter in varchar2
    ) return clob;
  --
    function get_taxpayer (
        p_cnpj in varchar2,
        p_type in varchar2
    ) return clob;
  --
    function get_po_array (
        p_fornec in varchar2,
        p_receiv in varchar2
    ) return t$po
        pipelined;
  --
    function get_po_array_v2 (
        p_transaction_id number
    ) return t$po2
        pipelined;
  --
    procedure send_invoice (
        p_header_id in number
    );
  --
    procedure send_invoice_v2 (
        p_header_id      in number,
        p_flag_retention in varchar2 default 'Y'
    );
  --
    function get_invoice (
        p_header_id in number
    ) return clob;
  --
    function get_invoice_v2 (
        p_header_id in number
    ) return clob;
  --
    function get_itens (
        p_transaction_id number,
        p_item           varchar2,
        p_item_descr     varchar2
    ) return number;
  --
    function get_bu_cnpj (
        p_cnpj varchar2
    ) return varchar2;
  --
    function get_registrationid (
        p_cnpj varchar2
    ) return varchar2;
  --
--PROCEDURE insert_ship(p_ship IN OUT NOCOPY rmais_efd_shipments%ROWTYPE);
  --
    procedure generate_attachments (
        p_efd_header_id number
    );
  --
    procedure get_definition_type (
        p_efd_header_id    number default null,
        p_model            varchar2 default '00',
        p_source_type      in out varchar2,
        p_item             in out varchar2,
        p_role_application out varchar2,
        p_defined_role     out varchar2
    );
  --
    function return_filename_croped (
        p_filename       varchar2,
        p_extension_flag varchar2 default 'Y'
    ) return varchar2;
  --   
    procedure get_taxes_v2 (
        p_efd_line_id number
    );
  --             
    procedure send_hold_invoice_ap (
        p_nf            in out clob,
        p_efd_header_id number
    );
  --  
    procedure send_boleto (
        p_efd_header_id in number
    );
  --
    procedure status_boleto (
        p_count number default 3
    );
  --
    procedure update_invoice (
        p_header_id in number
    );
  --
    procedure reprocess_waiting_crete_doc_run;
  --
    function cursor_po_line (
        p_transaction_id number
    ) return t$po_line;
  --
    function cancel_nf_erp (
        p_header_id in number
    ) return varchar2;
  --
    function validate_line_selection (
        p_model          varchar2,
        p_type_lin       varchar2,
        p_unit_prince_po varchar2,
        p_quant_po       varchar2,
        p_quant_lin      varchar2,
        p_unit_price_lin varchar2,
        p_flag_acao      out number
    ) return varchar2;
  --
    procedure reprocess_header (
        p_efd_header_id number
    );
  --
    procedure split_line (
        p_line_id number,
        p_arr     varchar2
    );
  --
end rmais_process_pkg_test;
/


-- sqlcl_snapshot {"hash":"eb8ef60a7b39a5daf74b5973d1c1e928a46b982c","type":"PACKAGE_SPEC","name":"RMAIS_PROCESS_PKG_TEST","schemaName":"RMAIS","sxml":""}