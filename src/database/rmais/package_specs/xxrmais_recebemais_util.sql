create or replace package xxrmais_recebemais_util as
  --
    function get_parameter (
        pfield      varchar2,
        p_condition varchar2,
        p_compare   varchar2
    ) return varchar2;
  --
    procedure insert_crtl (
        p_document_number        in number,
        p_key                    in varchar2,
        p_issuer_document_number in number,
        p_org_id                 in number,
        p_organization_id        in number,
        p_last_update            in date,
        p_log                    in clob,
        p_status                 in varchar2,
        p_invoice_param          in number default null
    );
  --
    procedure log_efd (
        p_efd_validation_id number,
        p_message_code      varchar2,
        p_efd_line_number   number,
        p_entity_name       varchar2,
        p_event_type        number,
        p_token1            varchar2 default null,
        p_token1val         varchar2 default null,
        p_token2            varchar2 default null,
        p_token2val         varchar2 default null,
        p_token3            varchar2 default null,
        p_token3val         varchar2 default null,
        p_token4            varchar2 default null,
        p_token4val         varchar2 default null,
        p_token5            varchar2 default null,
        p_token5val         varchar2 default null,
        p_token6            varchar2 default null,
        p_token6val         varchar2 default null
    );
  --
    procedure recebe_mais_process (
        p_retcode    out varchar2,
        p_errbuf     out varchar2,
        p_efd_header in number default null,
        p_key        in varchar2 default null
    );
  --
    procedure reprocess_invalid (
        p_errbuf  in out varchar2,
        p_retcode in out varchar2,
        p_days    in number
    );
  --
    procedure insert_row_rmais_shipments (
        x_source_doc_type     in varchar2, -- 02/03/2016
        x_model               in varchar2, -- 23/03/2016
        x_issuing_purpose     in number,   -- 23/03/2016
        x_issuing_type        in number,
        x_efd_line_id         in number,
        x_source_doc_line_id  in number,
        x_po_release_id       in number,
        x_organization_id     in number,
        x_ship_to_location_id in number,
        x_quantity_to_receive in number,
        x_last_update_date    in date,
        x_last_updated_by     in number,
        x_last_update_login   in number
    );

end xxrmais_recebemais_util;
/


-- sqlcl_snapshot {"hash":"f1200c8ab333a19880da732b328e4e6dbb1db288","type":"PACKAGE_SPEC","name":"XXRMAIS_RECEBEMAIS_UTIL","schemaName":"RMAIS","sxml":""}