-- liquibase formatted sql
-- changeset RMAIS:1777295651603 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_split_details_tmp.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_split_details_tmp.sql:null:d8a6ed51649fbd2ef9ab5d7ffa1a2dd7bed2e1ef:create

create table rmais_split_details_tmp (
    transaction_id         number,
    linha                  number,
    pedido                 varchar2(4000 byte),
    item_description       varchar2(4000 byte),
    uom_code               varchar2(4000 byte),
    unit_price             varchar2(4000 byte),
    unit_price_po_s_t      varchar2(4000 byte),
    quantity_line          varchar2(4000 byte),
    line_quantity_po_s_t   varchar2(4000 byte),
    line_location_id       number,
    need_by_date           varchar2(4000 byte),
    promised_date          varchar2(4000 byte),
    po_line_id             number,
    line_num               number,
    po_header_id           number,
    info_po                varchar2(4000 byte),
    item_number            varchar2(4000 byte),
    description            varchar2(4000 byte),
    term_info              varchar2(4000 byte),
    item_info              varchar2(4000 byte),
    task_number            varchar2(4000 byte),
    receipt_num            varchar2(4000 byte),
    receipt_line_num       varchar2(4000 byte),
    receipt_quantity_deliv varchar2(4000 byte),
    tax_classification     varchar2(4000 byte),
    tax                    varchar2(4000 byte),
    quant_line_original    number,
    creation_date          date,
    quant_receb            number,
    tax_rate               number,
    tax_amount_original    number,
    pedido_rm              varchar2(10 byte),
    numero_nf              number
);

