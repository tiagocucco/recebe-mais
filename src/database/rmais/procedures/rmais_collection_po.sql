create or replace procedure rmais_collection_po (
    pr_tomador          in varchar2,
    pr_fornecedor       in varchar2,
    p_session           in varchar2,
    pr_g_transaction_id out varchar2
) as
    --
begin
    --
    execute immediate q'[alter session set NLS_NUMERIC_CHARACTERS='.,']';
    --
    pr_g_transaction_id := rmais_ws_info_s.nextval;
    delete processo_po
    where
        sessao = p_session;

    insert into processo_po values ( pr_g_transaction_id,
                                     p_session,
                                     current_date );

    commit;
    rmais_process_pkg.insert_ws_info(pr_g_transaction_id);
    pr_g_transaction_id := rmais_process_pkg.set_transaction_po_arrays(pr_fornecedor,
                                                                       rmais_process_pkg.get_bu_cnpj(pr_tomador),
                                                                       pr_g_transaction_id);

    begin
        select
            num_processo
        into pr_g_transaction_id
        from
            processo_po
        where
            num_processo = pr_g_transaction_id;

    exception
        when no_data_found then
            return;
    end;

    commit;
    --     
    begin
        --
        if apex_collection.collection_exists(p_collection_name => 'RMAIS_PO_OK') then
            --
            apex_collection.delete_collection(p_collection_name => 'RMAIS_PO_OK');
            apex_collection.create_collection(p_collection_name => 'RMAIS_PO_OK');
            --
        else
            apex_collection.create_collection(p_collection_name => 'RMAIS_PO_OK');
        end if;
    end;

    for x in (
        select
            po_num                                            pedido,
            po_line_id,
            line_num,
            item_description,
            primary_uom_code                                  uom_code,
            uom_code_po                                       uom_desc,
            unit_price,
            quantity_line,
            line_location_id,
            to_char(need_by_date)                             need_by_date,
            to_char(promised_date)                            promised_date,
            po_header_id,
            to_char(info_po)                                  po_info,
            item_number,
            description                                       descr,
            to_char(info_term)                                info_term,
            to_char(info_item)                                info_item,
            task_number,
            nvl(destination_type_code, destination_type_dist) destination_type,
            ncm
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
                                replace(
                                    replace(
                                        xxrmais_util_pkg.base64decode(clob_info),
                                        '"LINES":{',
                                        '"LINES":[{'
                                    ),
                                    '}}},{"PO_HEADER_ID"',
                                    '}}]},{"PO_HEADER_ID"'
                                ),
                                '}}}]}',
                                '}}]}]}'
                            ),
                            '}}}}',
                            '}}]}}'
                        ), '$.HEADER[*]'
                            columns (
                                po_header_id number path '$.PO_HEADER_ID',
                                po_num varchar2 ( 500 ) path '$.PO_NUM',
                                -- po_type VARCHAR2(500) PATH '$.PO_TYPE',
                                -- tomador VARCHAR2(300) PATH '$.TOMADOR',
                                tomador_cnpj varchar2 ( 200 ) path '$.TOMADOR_CNPJ',
                                -- prc_bu_id NUMBER PATH '$.PRC_BU_ID',
                                -- vendor_name VARCHAR2(300) PATH '$.VENDOR_NAME',
                                -- vendor_id NUMBER PATH '$.VENDOR_ID',
                                -- vendor_site_id NUMBER PATH '$.VENDOR_SITE_ID',
                                -- vendor_site_code VARCHAR2(100) PATH '$.VENDOR_SITE_CODE',
                                fornecedor_cnpj varchar2 ( 200 ) path '$.FORNECEDOR_CNPJ',
                                -- currency_code VARCHAR2(100) PATH '$.CURRENCY_CODE',
                                -- info_doc VARCHAR2(4000) FORMAT JSON WITH WRAPPER PATH '$',
                                info_term varchar2 ( 4000 ) format json with wrapper path '$.TERM',
                                po_seq for ordinality,
                                nested path '$.LINES[*]'
                                    columns (
                                        info_po varchar2 ( 4000 ) format json with wrapper path '$',
                                        info_item varchar2 ( 4000 ) format json with wrapper path '$.ITEM',
                                    -- info_ship VARCHAR2(4000) FORMAT JSON WITH WRAPPER PATH '$.LINE_LOCATIONS',
                                        po_line_id number path '$.PO_LINE_ID',
                                    -- line_type_id NUMBER PATH '$.LINE_TYPE_ID',
                                        line_num number path '$.LINE_NUM',
                                    -- item_id NUMBER PATH '$.ITEM_ID',
                                    -- category_id NUMBER PATH '$.CATEGORY_ID',
                                        item_description varchar2 ( 300 ) path '$.ITEM_DESCRIPTION',
                                        uom_code_po varchar2 ( 100 ) path '$.UOM_CODE',
                                        unit_price number path '$.UNIT_PRICE',
                                        quantity_line number path '$.QUANTITY',
                                    -- prc_bu_id_lin NUMBER PATH '$.PRC_BU_ID',
                                    -- req_bu_id_lin NUMBER PATH '$.REQ_BU_ID',
                                    -- taxable_flag_lin VARCHAR2(100) PATH '$.TAXABLE_FLAG',
                                    -- order_type_lookup_code VARCHAR2(100) PATH '$.ORDER_TYPE_LOOKUP_CODE',
                                    -- purchase_basis VARCHAR2(100) PATH '$.PURCHASE_BASIS',
                                    -- matching_basis VARCHAR2(100) PATH '$.MATCHING_BASIS',
                                    -- line_seq FOR ORDINALITY,
                                        nested path '$.ITEM'
                                            columns (
                                        -- inventory_item_id NUMBER PATH '$.INVENTORY_ITEM_ID',
                                                primary_uom_code varchar2 ( 100 ) path '$.PRIMARY_UOM_CODE',
                                        -- item_type VARCHAR2(900) PATH '$.ITEM_TYPE',
                                        -- inventory_item_flag VARCHAR2(100) PATH '$.INVENTORY_ITEM_FLAG',
                                        -- tax_code VARCHAR2(500) PATH '$.TAX_CODE',
                                        -- enabled_flag VARCHAR2(100) PATH '$.ENABLED_FLAG',
                                                item_number varchar2 ( 300 ) path '$.ITEM_NUMBER',
                                                description varchar2 ( 300 ) path '$.DESCRIPTION',
                                        -- long_description VARCHAR2(900) PATH '$.LONG_DESCRIPTION',
                                                ncm varchar2 ( 100 ) path '$.NCM'
                                        -- uom_code VARCHAR(100) PATH '$.UNIT_OF_MEASURE'
                                            ),
                                        line_location_id number path '$.LINE_LOCATIONS.LINE_LOCATION_ID',
                                        destination_type_code varchar2 ( 900 ) path '$.LINE_LOCATIONS.DESTINATION_TYPE_CODE',
                                    -- trx_business_category VARCHAR2(900) PATH '$.LINE_LOCATIONS.TRX_BUSINESS_CATEGORY',
                                    -- prc_bu_id_loc NUMBER PATH '$.LINE_LOCATIONS.PRC_BU_ID',
                                    -- req_bu_id_loc NUMBER PATH '$.LINE_LOCATIONS.REQ_BU_ID',
                                    -- product_type VARCHAR2(100) PATH '$.LINE_LOCATIONS.PRODUCT_TYPE',
                                    -- assessable_value NUMBER PATH '$.LINE_LOCATIONS.ASSESSABLE_VALUE',
                                        quantity_ship number path '$.LINE_LOCATIONS.QUANTITY',
                                    -- quantity_received NUMBER PATH '$.LINE_LOCATIONS.QUANTITY_RECEIVED',
                                    -- quantity_accepted NUMBER PATH '$.LINE_LOCATIONS.QUANTITY_ACCEPTED',
                                    -- quantity_rejected NUMBER PATH '$.LINE_LOCATIONS.QUANTITY_REJECTED',
                                    -- quantity_billed NUMBER PATH '$.LINE_LOCATIONS.QUANTITY_BILLED',
                                    -- quantity_cancelled NUMBER PATH '$.LINE_LOCATIONS.QUANTITY_CANCELLED',
                                    -- ship_to_location_id NUMBER PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION_ID',
                                        need_by_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.NEED_BY_DATE',
                                        promised_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.PROMISED_DATE',
                                    -- last_accept_date VARCHAR2(50) PATH '$.LINE_LOCATIONS.LAST_ACCEPT_DATE',
                                        price_override number path '$.LINE_LOCATIONS.PRICE_OVERRIDE',
                                    -- taxable_flag VARCHAR2(10) PATH '$.LINE_LOCATIONS.TAXABLE_FLAG',
                                    -- receipt_required_flag VARCHAR2(10) PATH '$.LINE_LOCATIONS.RECEIPT_REQUIRED_FLAG',
                                    -- ship_to_organization_id NUMBER PATH '$.LINE_LOCATIONS.SHIP_TO_ORGANIZATION_ID',
                                        shipment_num varchar2 ( 10 ) path '$.LINE_LOCATIONS.SHIPMENT_NUM',
                                    -- shipment_type VARCHAR2(500) PATH '$.LINE_LOCATIONS.SHIPMENT_TYPE',
                                    -- funds_status VARCHAR2(500) PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.FUNDS_STATUS',
                                        destination_type_dist varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_TYPE_CODE'
                                        ,
                                    -- prc_bu_id_dist NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.PRC_BU_ID',
                                    -- req_bu_id_dist NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_BU_ID',
                                    -- encumbered_flag VARCHAR2(10) PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_FLAG',
                                    -- unencumbered_quantity NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_QUANTITY',
                                    -- amount_billed NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_BILLED',
                                    -- amount_cancelled NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_CANCELLED',
                                    -- quantity_financed NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_FINANCED',
                                    -- amount_financed NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_FINANCED',
                                    -- quantity_recouped NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_RECOUPED',
                                    -- amount_recouped NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_RECOUPED',
                                    -- retainage_withheld_amount NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_WITHHELD_AMOUNT',
                                    -- retainage_released_amount NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_RELEASED_AMOUNT',
                                    -- tax_attribute_update_code VARCHAR2(100) PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.TAX_ATTRIBUTE_UPDATE_CODE',
                                    -- po_distribution_id NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.PO_DISTRIBUTION_ID',
                                    -- budget_date VARCHAR2(50) PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.BUDGET_DATE',
                                    -- close_budget_date VARCHAR2(50) PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.CLOSE_BUDGET_DATE',
                                    -- dist_intended_use VARCHAR2(500) PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.DIST_INTENDED_USE',
                                    -- set_of_books_id NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.SET_OF_BOOKS_ID',
                                    -- code_combination_id NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.CODE_COMBINATION_ID',
                                    -- quantity_ordered NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_ORDERED',
                                    -- quantity_delivered NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_DELIVERED',
                                    -- consignment_quantity NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.CONSIGNMENT_QUANTITY',
                                    -- req_distribution_id NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_DISTRIBUTION_ID',
                                    -- deliver_to_location_id NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_LOCATION_ID',
                                    -- deliver_to_person_id NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_PERSON_ID',
                                    -- rate_date VARCHAR2(50) PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE_DATE',
                                    -- rate NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE',
                                    -- accrued_flag VARCHAR2(50) PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.ACCRUED_FLAG',
                                    -- encumbered_amount NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_AMOUNT',
                                    -- unencumbered_amount NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_AMOUNT',
                                    -- destination_organization_id NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_ORGANIZATION_ID',
                                    -- pjc_task_id NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.PJC_TASK_ID',
                                        task_number varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_NUMBER'
                                    -- task_id NUMBER PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_ID',
                                    -- location_id NUMBER PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_ID',
                                    -- country VARCHAR2(500) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.COUNTRY',
                                    -- postal_code VARCHAR2(50) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.POSTAL_CODE',
                                    -- local_description VARCHAR2(300) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.DESCRIPTION',
                                    -- effective_start_date VARCHAR2(50) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_START_DATE',
                                    -- effective_end_date VARCHAR2(50) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_END_DATE',
                                    -- business_group_id NUMBER PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BUSINESS_GROUP_ID',
                                    -- active_status VARCHAR2(100) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTIVE_STATUS',
                                    -- ship_to_site_flag VARCHAR2(100) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.SHIP_TO_SITE_FLAG',
                                    -- receiving_site_flag VARCHAR2(100) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.RECEIVING_SITE_FLAG',
                                    -- bill_to_site_flag VARCHAR2(100) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BILL_TO_SITE_FLAG',
                                    -- office_site_flag VARCHAR2(100) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.OFFICE_SITE_FLAG',
                                    -- inventory_organization_id NUMBER PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.INVENTORY_ORGANIZATION_ID',
                                    -- action_occurrence_id NUMBER PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTION_OCCURRENCE_ID',
                                    -- location_code VARCHAR2(100) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_CODE',
                                    -- location_name VARCHAR2(300) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_NAME',
                                    -- style VARCHAR2(100) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.STYLE',
                                    -- address_line_1 VARCHAR2(300) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_1',
                                    -- address_line_2 VARCHAR2(300) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_2',
                                    -- address_line_3 VARCHAR2(300) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_3',
                                    -- address_line_4 VARCHAR2(300) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_4',
                                    -- region_1 VARCHAR2(300) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_1',
                                    -- region_2 VARCHAR2(300) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_2',
                                    --town_or_city VARCHAR2(300) PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.TOWN_OR_CITY'
                                    )
                            )
                        )
                    d
                where
                    p.transaction_id = pr_g_transaction_id
            )
        where
            seq = 1
        order by
            po_num,
            line_num
    ) loop
        apex_collection.add_member(
            p_collection_name => 'RMAIS_PO_OK',
            p_c001            => x.pedido,
            p_c002            => x.item_description,
            p_c003            => x.uom_code,
            p_c010            => to_char(x.unit_price),
            p_n004            => x.quantity_line,
            p_n005            => x.line_location_id,
            p_c004            => x.need_by_date,
            p_c005            => x.promised_date,
            p_n001            => x.po_line_id,
            p_n002            => x.line_num,
            p_c009            => to_char(x.po_header_id),
            p_c006            => x.po_info,
            p_c007            => x.item_number,
            p_c008            => x.descr,
            p_c011            => x.info_term,
            p_c012            => x.info_item,
            p_c013            => x.task_number,
            p_c014            => x.destination_type,
            p_c015            => x.ncm,
            p_c016            => x.uom_desc
        );
    end loop;
    --
    execute immediate q'[alter session set NLS_NUMERIC_CHARACTERS=',.']';
    --        
    apex_json.open_object;
    apex_json.write('success', true);
    apex_json.close_object;
exception
    when others then
        apex_json.open_object;
        apex_json.write('success', false);
        apex_json.write('message', sqlerrm);
        apex_json.close_object;
end;
/


-- sqlcl_snapshot {"hash":"ce488ccceda00aa29bbbde436f3879813d58c43d","type":"PROCEDURE","name":"RMAIS_COLLECTION_PO","schemaName":"RMAIS","sxml":""}