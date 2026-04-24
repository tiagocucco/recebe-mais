create or replace package rmais_process_pkg_email as
    --
    g_log_workflow clob := null;
    --
    g_first_main varchar2(10) := null;
    --
    g_set_workflow boolean := true;
    --
    type t$po_line is
        table of rmais_get_po_line_vw%rowtype;
    --
    cursor c$po (
        p_transaction number
    ) is
    select
        d.fornecedor_cnpj                                 cnpj,
        d.tomador_cnpj                                    receiver,
        sum(nvl(d.price_override * quantity_ship, d.unit_price * d.quantity_line))
        over(partition by po_header_id)                   total_po,
        po_header_id,
        po_num,
        po_type,
        tomador,
        tomador_cnpj,
        prc_bu_id,
        vendor_name,
        vendor_id,
        vendor_site_id,
        vendor_site_code,
        fornecedor_cnpj,
        currency_code,
        info_doc,
        info_term,
        po_seq,
        info_po,
        info_item,
        info_ship,
        po_line_id,
        line_type_id,
        line_num,
        item_id,
        category_id,
        item_description,
                --case when nvl(destination_type_code,destination_type_dist)  = 'EXPENSE' then nvl(UNIT_OF_MEASURE_PO,UOM_CODE2) ELSE nvl(UOM_CODE_PO,UOM_CODE)  end uom_code,
        primary_uom_code                                  uom_code,
        uom_code_po                                       uom_desc,
        unit_price,
        quantity_line,
        prc_bu_id_lin,
        req_bu_id_lin,
        taxable_flag_lin,
        order_type_lookup_code,
        purchase_basis,
        matching_basis,
        line_location_id,
        destination_type_code,
        trx_business_category,
        prc_bu_id_loc,
        req_bu_id_loc,
        product_type,
        assessable_value,
        quantity_ship,
        quantity_received,
        quantity_accepted,
        quantity_rejected,
        quantity_billed,
        quantity_cancelled,
        ship_to_location_id,
        need_by_date,
        promised_date,
        last_accept_date,
        price_override,
        taxable_flag,
        receipt_required_flag,
        ship_to_organization_id,
        shipment_num,
        shipment_type,
        funds_status,
        destination_type_dist,
        prc_bu_id_dist,
        req_bu_id_dist,
        encumbered_flag,
        unencumbered_quantity,
        amount_billed,
        amount_cancelled,
        quantity_financed,
        amount_financed,
        quantity_recouped,
        amount_recouped,
        retainage_withheld_amount,
        retainage_released_amount,
        tax_attribute_update_code,
        po_distribution_id,
        budget_date,
        close_budget_date,
        dist_intended_use,
        set_of_books_id,
        code_combination_id,
        quantity_ordered,
        quantity_delivered,
        consignment_quantity,
        req_distribution_id,
        deliver_to_location_id,
        deliver_to_person_id,
        rate_date,
        rate,
        accrued_flag,
        encumbered_amount,
        unencumbered_amount,
        destination_organization_id,
        pjc_task_id,
        task_number,
        task_id,
        location_id,
        country,
        postal_code,
        local_description,
        effective_start_date,
        effective_end_date,
        business_group_id,
        active_status,
        ship_to_site_flag,
        receiving_site_flag,
        bill_to_site_flag,
        office_site_flag,
        inventory_organization_id,
        action_occurrence_id,
        location_code,
        location_name,
        style,
        address_line_1,
        address_line_2,
        address_line_3,
        address_line_4,
        region_1,
        region_2,
        town_or_city,
        line_seq,
        inventory_item_id,
        primary_uom_code,
        item_type,
        inventory_item_flag,
        tax_code,
        enabled_flag,
        item_number,
        description,
        long_description,
        ncm,
        ''                                                catalog_code_ncm,
        nvl(destination_type_code, destination_type_dist) destination_type,
        segment1
        || '.'
        || segment2
        || '.'
        || segment3
        || '.'
        || segment4
        || '.'
        || segment5
        || '.'
        || segment6
        || '.'
        || segment7
        || '.'
        || segment8                                       cc_combination_name,
        row_number()
        over(partition by d.po_header_id, d.po_line_id
             order by
                 d.po_line_id, d.shipment_num
        )                                                 seq,
        email_approve
    from
        (
            select
                p.transaction_id,
                d.fornecedor_cnpj               cnpj,
                d.tomador_cnpj                  receiver,
                sum(nvl(d.price_override * quantity_ship, d.unit_price * d.quantity_line))
                over(partition by po_header_id) total_po,
                d.*,
                row_number()
                over(partition by d.po_header_id, d.po_line_id
                     order by
                         d.po_line_id, d.shipment_num
                )                               seq
            from
                rmais_ws_info p,
                json_table ( replace(
                        replace(
                            xxrmais_util_pkg.base64decode(clob_info),
                            '"LINES":{',
                            '"LINES":[{'
                        ),
                        '}}},{"PO_HEADER_ID"',
                        '}}]},{"PO_HEADER_ID"'
                    ), '$'
                        columns (
                            nested path '$.HEADER[*]'
                                columns (
                                    po_header_id number path '$.PO_HEADER_ID',
                                    po_num varchar2 ( 500 ) path '$.PO_NUM',
                                    po_type varchar2 ( 500 ) path '$.PO_TYPE',
                                    tomador varchar2 ( 300 ) path '$.TOMADOR',
                                    tomador_cnpj varchar2 ( 200 ) path '$.TOMADOR_CNPJ',
                                    prc_bu_id number path '$.PRC_BU_ID',
                                    vendor_name varchar2 ( 300 ) path '$.VENDOR_NAME',
                                    vendor_id number path '$.VENDOR_ID',
                                    vendor_site_id number path '$.VENDOR_SITE_ID',
                                    vendor_site_code varchar2 ( 100 ) path '$.VENDOR_SITE_CODE',
                                    fornecedor_cnpj varchar2 ( 200 ) path '$.FORNECEDOR_CNPJ',
                                    currency_code varchar2 ( 100 ) path '$.CURRENCY_CODE',
                                    info_doc varchar2 ( 4000 ) format json with wrapper path '$',
                                    info_term varchar2 ( 4000 ) format json with wrapper path '$.TERM',
                                    po_seq for ordinality,
                                    info_po clob format json with wrapper path '$',
                                    email_approve varchar2 ( 600 ) path '$.MAILS.EMAIL_ADDRESS',
                                    nested path '$.LINES[*]'
                                        columns (
                                            info_item varchar2 ( 4000 ) format json with wrapper path '$.ITEM',
                                            info_ship varchar2 ( 4000 ) format json with wrapper path '$.LINE_LOCATIONS',
                                            po_line_id number path '$.PO_LINE_ID',
                                            line_type_id number path '$.LINE_TYPE_ID',
                                            line_num number path '$.LINE_NUM',
                                            item_id number path '$.ITEM_ID',
                                            category_id number path '$.CATEGORY_ID',
                                            item_description varchar2 ( 300 ) path '$.ITEM_DESCRIPTION',
                                            uom_code_po varchar2 ( 100 ) path '$.UOM_CODE',
                                            unit_price number path '$.UNIT_PRICE',
                                            quantity_line number path '$.QUANTITY',
                                            prc_bu_id_lin number path '$.PRC_BU_ID',
                                            req_bu_id_lin number path '$.REQ_BU_ID',
                                            taxable_flag_lin varchar2 ( 100 ) path '$.TAXABLE_FLAG',
                                            order_type_lookup_code varchar2 ( 100 ) path '$.ORDER_TYPE_LOOKUP_CODE',
                                            purchase_basis varchar2 ( 100 ) path '$.PURCHASE_BASIS',
                                            matching_basis varchar2 ( 100 ) path '$.MATCHING_BASIS',
                                            line_seq for ordinality,
                                            nested path '$.ITEM'
                                                columns (
                                            --info_item CLOB FORMAT JSON PATH '$[*]',
                                                    inventory_item_id number path '$.INVENTORY_ITEM_ID',
                                                    primary_uom_code varchar2 ( 100 ) path '$.PRIMARY_UOM_CODE',
                                                    item_type varchar2 ( 900 ) path '$.ITEM_TYPE',
                                                    inventory_item_flag varchar2 ( 100 ) path '$.INVENTORY_ITEM_FLAG',
                                                    tax_code varchar2 ( 500 ) path '$.TAX_CODE',
                                                    enabled_flag varchar2 ( 100 ) path '$.ENABLED_FLAG',
                                                    item_number varchar2 ( 300 ) path '$.ITEM_NUMBER',
                                                    description varchar2 ( 300 ) path '$.DESCRIPTION',
                                                    long_description varchar2 ( 900 ) path '$.LONG_DESCRIPTION',
                                                    ncm varchar2 ( 100 ) path '$.NCM',
                                                    uom_code varchar ( 100 ) path '$.UNIT_OF_MEASURE'
                                                ),
                                            line_location_id number path '$.LINE_LOCATIONS.LINE_LOCATION_ID',
                                            destination_type_code varchar2 ( 900 ) path '$.LINE_LOCATIONS.DESTINATION_TYPE_CODE',
                                            trx_business_category varchar2 ( 900 ) path '$.LINE_LOCATIONS.TRX_BUSINESS_CATEGORY',
                                            prc_bu_id_loc number path '$.LINE_LOCATIONS.PRC_BU_ID',
                                            req_bu_id_loc number path '$.LINE_LOCATIONS.REQ_BU_ID',
                                            product_type varchar2 ( 100 ) path '$.LINE_LOCATIONS.PRODUCT_TYPE',
                                            assessable_value number path '$.LINE_LOCATIONS.ASSESSABLE_VALUE',
                                            quantity_ship number path '$.LINE_LOCATIONS.QUANTITY',
                                            quantity_received number path '$.LINE_LOCATIONS.QUANTITY_RECEIVED',
                                            quantity_accepted number path '$.LINE_LOCATIONS.QUANTITY_ACCEPTED',
                                            quantity_rejected number path '$.LINE_LOCATIONS.QUANTITY_REJECTED',
                                            quantity_billed number path '$.LINE_LOCATIONS.QUANTITY_BILLED',
                                            quantity_cancelled number path '$.LINE_LOCATIONS.QUANTITY_CANCELLED',
                                            ship_to_location_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION_ID',
                                            need_by_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.NEED_BY_DATE',
                                            promised_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.PROMISED_DATE',
                                            last_accept_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.LAST_ACCEPT_DATE',
                                            price_override number path '$.LINE_LOCATIONS.PRICE_OVERRIDE',
                                            taxable_flag varchar2 ( 10 ) path '$.LINE_LOCATIONS.TAXABLE_FLAG',
                                            receipt_required_flag varchar2 ( 10 ) path '$.LINE_LOCATIONS.RECEIPT_REQUIRED_FLAG',
                                            ship_to_organization_id number path '$.LINE_LOCATIONS.SHIP_TO_ORGANIZATION_ID',
                                            shipment_num varchar2 ( 10 ) path '$.LINE_LOCATIONS.SHIPMENT_NUM',
                                            shipment_type varchar2 ( 500 ) path '$.LINE_LOCATIONS.SHIPMENT_TYPE',
                                            funds_status varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.FUNDS_STATUS',
                                            destination_type_dist varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_TYPE_CODE'
                                            ,
                                            prc_bu_id_dist number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PRC_BU_ID',
                                            req_bu_id_dist number path '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_BU_ID',
                                            encumbered_flag varchar2 ( 10 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_FLAG',
                                            unencumbered_quantity number path '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_QUANTITY',
                                            amount_billed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_BILLED',
                                            amount_cancelled number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_CANCELLED',
                                            quantity_financed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_FINANCED',
                                            amount_financed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_FINANCED',
                                            quantity_recouped number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_RECOUPED',
                                            amount_recouped number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_RECOUPED',
                                            retainage_withheld_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_WITHHELD_AMOUNT'
                                            ,
                                            retainage_released_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_RELEASED_AMOUNT'
                                            ,
                                            tax_attribute_update_code varchar2 ( 100 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.TAX_ATTRIBUTE_UPDATE_CODE'
                                            ,
                                            po_distribution_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PO_DISTRIBUTION_ID',
                                            budget_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.BUDGET_DATE',
                                            close_budget_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CLOSE_BUDGET_DATE'
                                            ,
                                            dist_intended_use varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.DIST_INTENDED_USE'
                                            ,
                                            set_of_books_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.SET_OF_BOOKS_ID',
                                            code_combination_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.CODE_COMBINATION_ID',
                                            quantity_ordered number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_ORDERED',
                                            quantity_delivered number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_DELIVERED',
                                            consignment_quantity number path '$.LINE_LOCATIONS.DISTRIBUTIONS.CONSIGNMENT_QUANTITY',
                                            req_distribution_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_DISTRIBUTION_ID',
                                            deliver_to_location_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_LOCATION_ID'
                                            ,
                                            deliver_to_person_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_PERSON_ID',
                                            rate_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE_DATE',
                                            rate number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE',
                                            accrued_flag varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.ACCRUED_FLAG',
                                            encumbered_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_AMOUNT',
                                            unencumbered_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_AMOUNT',
                                            destination_organization_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_ORGANIZATION_ID'
                                            ,
                                            pjc_task_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PJC_TASK_ID',
                                            task_number varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_NUMBER',
                                            task_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_ID',
                                         --
                                            segment1 varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT1',
                                            segment2 varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT2',
                                            segment3 varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT3',
                                            segment4 varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT4',
                                            segment5 varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT5',
                                            segment6 varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT6',
                                            segment7 varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT7',
                                            segment8 varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT8',
                                        --
                                            location_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_ID',
                                            country varchar2 ( 500 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.COUNTRY',
                                            postal_code varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.POSTAL_CODE',
                                            local_description varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.DESCRIPTION',
                                            effective_start_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_START_DATE'
                                            ,
                                            effective_end_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_END_DATE'
                                            ,
                                            business_group_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BUSINESS_GROUP_ID',
                                            active_status varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTIVE_STATUS',
                                            ship_to_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.SHIP_TO_SITE_FLAG'
                                            ,
                                            receiving_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.RECEIVING_SITE_FLAG'
                                            ,
                                            bill_to_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BILL_TO_SITE_FLAG'
                                            ,
                                            office_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.OFFICE_SITE_FLAG'
                                            ,
                                            inventory_organization_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.INVENTORY_ORGANIZATION_ID'
                                            ,
                                            action_occurrence_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTION_OCCURRENCE_ID'
                                            ,
                                            location_code varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_CODE',
                                            location_name varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_NAME',
                                            style varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.STYLE',
                                            address_line_1 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_1',
                                            address_line_2 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_2',
                                            address_line_3 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_3',
                                            address_line_4 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_4',
                                            region_1 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_1',
                                            region_2 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_2',
                                            town_or_city varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.TOWN_OR_CITY'
                                        )
                                )
                        )
                    )
                d
            where
                p.transaction_id = p_transaction
        ) d;

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
    type t$t is record (
            line_location_id            number,
            cnpj                        varchar2(200),
            receiver                    varchar2(300),
            total_po                    number,
            po_header_id                number,
            po_num                      varchar2(500),
            po_type                     varchar2(500),
            tomador                     varchar2(300),
            tomador_cnpj                varchar2(200),
            prc_bu_id                   number,
            vendor_name                 varchar2(300),
            vendor_id                   number,
            vendor_site_id              number,
            vendor_site_code            varchar2(100),
            fornecedor_cnpj             varchar2(200),
            currency_code               varchar2(100),
            info_doc                    varchar2(4000),
            info_term                   varchar2(4000),
            po_seq                      number,
            info_po                     varchar2(4000),
            info_item                   varchar2(4000),
            info_ship                   varchar2(4000),
            po_line_id                  number,
            line_type_id                number,
            line_num                    number,
            item_id                     number,
            category_id                 number,
            item_description            varchar2(300),
            uom_code                    varchar2(100),
            uom_desc                    varchar2(100),
            unit_price                  number,
            quantity_line               number,
            prc_bu_id_lin               number,
            req_bu_id_lin               number,
            taxable_flag_lin            varchar2(100),
            order_type_lookup_code      varchar2(100),
            purchase_basis              varchar2(100),
            matching_basis              varchar2(100),
            destination_type_code       varchar2(900),
            trx_business_category       varchar2(900),
            prc_bu_id_loc               number,
            req_bu_id_loc               number,
            product_type                varchar2(100),
            assessable_value            number,
            quantity_ship               number,
            quantity_received           number,
            quantity_accepted           number,
            quantity_rejected           number,
            quantity_billed             number,
            quantity_cancelled          number,
            ship_to_location_id         number,
            need_by_date                varchar2(50),
            promised_date               varchar2(50),
            last_accept_date            varchar2(50),
            price_override              number,
            taxable_flag                varchar2(10),
            receipt_required_flag       varchar2(10),
            ship_to_organization_id     number,
            shipment_num                varchar2(10),
            shipment_type               varchar2(500),
            funds_status                varchar2(500),
            destination_type_dist       varchar2(500),
            prc_bu_id_dist              number,
            req_bu_id_dist              number,
            encumbered_flag             varchar2(10),
            unencumbered_quantity       number,
            amount_billed               number,
            amount_cancelled            number,
            quantity_financed           number,
            amount_financed             number,
            quantity_recouped           number,
            amount_recouped             number,
            retainage_withheld_amount   number,
            retainage_released_amount   number,
            tax_attribute_update_code   varchar2(100),
            po_distribution_id          number,
            budget_date                 varchar2(50),
            close_budget_date           varchar2(50),
            dist_intended_use           varchar2(500),
            set_of_books_id             number,
            code_combination_id         number,
            quantity_ordered            number,
            quantity_delivered          number,
            consignment_quantity        number,
            req_distribution_id         number,
            deliver_to_location_id      number,
            deliver_to_person_id        number,
            rate_date                   varchar2(50),
            rate                        number,
            accrued_flag                varchar2(50),
            encumbered_amount           number,
            unencumbered_amount         number,
            destination_organization_id number,
            pjc_task_id                 number,
            task_number                 varchar2(200),
            task_id                     number,
            location_id                 number,
            country                     varchar2(500),
            postal_code                 varchar2(50),
            local_description           varchar2(300),
            effective_start_date        varchar2(50),
            effective_end_date          varchar2(50),
            business_group_id           number,
            active_status               varchar2(100),
            ship_to_site_flag           varchar2(100),
            receiving_site_flag         varchar2(100),
            bill_to_site_flag           varchar2(100),
            office_site_flag            varchar2(100),
            inventory_organization_id   number,
            action_occurrence_id        number,
            location_code               varchar2(100),
            location_name               varchar2(300),
            style                       varchar2(100),
            address_line_1              varchar2(300),
            address_line_2              varchar2(300),
            address_line_3              varchar2(300),
            address_line_4              varchar2(300),
            region_1                    varchar2(300),
            region_2                    varchar2(300),
            town_or_city                varchar2(300),
            line_seq                    number,
            inventory_item_id           number,
            primary_uom_code            varchar2(100),
            item_type                   varchar2(900),
            inventory_item_flag         varchar2(100),
            tax_code                    varchar2(500),
            enabled_flag                varchar2(100),
            item_number                 varchar2(300),
            description                 varchar2(300),
            long_description            varchar2(900),
            ncm                         varchar2(100),
            catalog_code_ncm            varchar2(100),
            destination_type            varchar2(900),
            cc_cod_combination_name     varchar2(4000),
            receipt_num                 varchar2(900)
    );
  
  --
    type t$po is
        table of rmais_issuer_info_v%rowtype;
  --
  --TYPE t$po2 IS TABLE OF rmais_get_ws_po_base64%ROWTYPE;
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
    procedure log_efd (
        p_msg in varchar2,
        p_lin in number,
        p_hea in number,
        p_typ in varchar2 default null
    );
  --
    procedure main (
        p_header_id in number default null,
        p_acces_key in varchar2 default null,
        p_revalidar in varchar2 default null,
        p_user      in varchar2 default null
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
        p_cnpj    in varchar2,
        p_type    in varchar2,
        p_bu_name in varchar2 default null
    ) return clob;
  --
    function get_po_array (
        p_fornec in varchar2,
        p_receiv in varchar2
    ) return t$po
        pipelined;
  --
  --FUNCTION Get_PO_Array_v2 (p_transaction_id NUMBER) RETURN t$po2 PIPELINED;
  --
    procedure send_invoice_v2 (
        p_header_id in number
    );
  --
    function get_invoice_v2 (
        p_header_id in number
    ) return clob;
  --
    function get_itens (
        p_transaction_id number,
        p_item           varchar2,
        p_item_descr     varchar2,
        p_org_code       varchar2 default null
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
    function get_cc_concessionaria (
        p_efd_header_id number,
        p_efd_line_id   number
    ) return varchar2; 
  --
    function get_cc_cod_cliente (
        p_efd_header_id number
    ) return varchar2;
  --
    procedure generate_attachments (
        p_efd_header_id number
    );
  --
  --PROCEDURE send_boleto (p_efd_header_id IN NUMBER);
--PROCEDURE insert_ship(p_ship IN OUT NOCOPY rmais_efd_shipments%ROWTYPE);
  --
  --PROCEDURE status_boleto (p_count NUMBER DEFAULT 6);
  -- 
    function get_descr_concessionaria (
        p_efd_header_id number,
        p_efd_line_id   number
    ) return varchar2;
  --
    function get_bu_name (
        p_cnpj varchar2
    ) return varchar2;
  --
    procedure set_workflow (
        p_efd_header_id in varchar2,
        p_descricao     in varchar2,
        p_usuario       in varchar2
    );
    --
    function get_combinacao_concessionarias (
        pr_cliente_cod in rmais_efd_headers.cliente_cod%type
    ) return rmais_efd_lines.combination_descr%type;
    --
    --function get_combinacao(p_code_combination in varchar2) return varchar2;
    --
    function get_response_v3 (
        p_url    varchar2,
        p_body   clob,
        p_method varchar2 default 'GET'
    ) return clob;
    --
    function get_ship_to_location (
        p_cnpj varchar2
    ) return varchar2;
    --
    procedure set_po_lines_auto (
        p_linhas_nota  in varchar2,
        p_pedido       in varchar2,
        o_retorno      out varchar2,
        p_linha_pedido in varchar2
    );
    --
    function get_combinacao_guias (
        pr_vendor_site_code         in rmais_efd_headers.vendor_site_code%type,
        pr_receiver_document_number in rmais_efd_headers.receiver_document_number%type
    ) return rmais_efd_lines.combination_descr%type;
    --
    procedure send_invoice_v3 (
        p_header_id in number
    );
    --
    procedure reprocess_header (
        p_efd_header_id number
    );
    --
    procedure send_cert_dig_v2 (
        p_cnpj     in varchar2,
        p_tomador  in varchar2,
        p_file     in clob,
        p_pass     in varchar2,
        p_exp_date in out date
    );
    --
    procedure split_line (
        p_line_id    number,
        p_po_line_id varchar2,
        p_receipt    varchar2,
        p_discount   number default null,
        p_seq        varchar2
    );
    --
    procedure clear_split (
        p_line_id number
    );
    --
    procedure send_anexo (
        p_efd_header_id in number,
        p_invoice_id    in number,
        p_todos         in number default 1,
        p_resposta      out varchar2
    );
    --
    procedure insert_ws_info_v2 (
        p_id        in out number,
        p_header_id number default null,
        p_method    varchar2 default 'GET_PO',
        p_clob      clob default null
    );
    --
    procedure send_boleto (
        p_efd_header_id in number,
        p_user          varchar2 default null,
        p_destination   varchar2 default null,
        p_doc_number    varchar2 default null
    );
    --
    procedure status_boleto (
        p_count number default 6
    );
    --
    /*poc não apagar e não enviar para outro cliente*/
    function validate_line_selection (
        p_model          varchar2,
        p_type_lin       varchar2,
        p_unit_prince_po varchar2,
        p_quant_po       varchar2,
        p_quant_lin      varchar2,
        p_unit_price_lin varchar2,
        p_flag_acao      out number
    ) return varchar2;
    /*fim poc*/
end rmais_process_pkg_email;
/


-- sqlcl_snapshot {"hash":"13426bc8283240c6eb300d72741f919723ce9dae","type":"PACKAGE_SPEC","name":"RMAIS_PROCESS_PKG_EMAIL","schemaName":"RMAIS","sxml":""}