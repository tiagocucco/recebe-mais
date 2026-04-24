create or replace force editionable view vw_get_invoice (
    doc,
    efd_header_id
) as
    with tp_lines as (
        select
            a.*,
            case
                when b.model = '55'
                     and sum(nvl(a.line_amount, a.line_quantity * a.unit_price))
                         over(partition by a.efd_header_id) != b.total_amount then
                    1
                else
                    0
            end                                flag_add_line,
            case
                when sum(
                    case
                        when a.item_code = 'Frete Destacado' then
                            1
                        else
                            0
                    end
                )
                     over(partition by a.efd_header_id) > 0 then
                    0
                else
                    1
            end                                flag_add_freight,
                -- temp remover
            sum(nvl(a.line_amount, a.line_quantity * a.unit_price))
            over(partition by a.efd_header_id) line_amount_sum,
            b.total_amount,
            b.access_key_number
                -- 
        from
            rmais_efd_lines   a,
            rmais_efd_headers b
        where
                1 = 1
            and a.efd_header_id = b.efd_header_id
    ), tp_lines_a as (
        select
            a.*,
            case
                when b.lh = 1 then
                    a.line_number
                else
                    max(a.line_number)
                    over() + b.lh - 1
            end line_number_esp,
            case
                when b.lh = 1 then
                    'Item'
                when b.lh = 2 then
                    'Miscellaneous'
                else
                    'Freight'
            end line_type_esp,
            case
                when a.flag_add_line = 1
                     and b.lh = 2
                     and nvl(a.discount_line_amount, 0) > 0 then
                    'Desconto referente linha ' || a.line_number
                when a.flag_add_line = 1
                     and b.lh = 3
                     and nvl(a.freight_line_amount, 0) > 0
                     and a.flag_add_freight = 1 then
                    'Frete referente linha ' || a.line_number
                when a.flag_add_line = 1
                     and b.lh = 4
                     and nvl(a.insurance_line_amount, 0) > 0 then
                    'Seguro referente linha ' || a.line_number
                when a.flag_add_line = 1
                     and b.lh = 5
                     and nvl(a.other_expenses_line_amount, 0) > 0 then
                    'Outras despesas referente linha ' || a.line_number
            end item_desc_esp,
            case
                when a.flag_add_line = 1
                     and b.lh = 2
                     and nvl(a.discount_line_amount, 0) > 0 then
                    a.discount_line_amount * ( - 1 )
                when a.flag_add_line = 1
                     and b.lh = 3
                     and nvl(a.freight_line_amount, 0) > 0 then
                    a.freight_line_amount
                when a.flag_add_line = 1
                     and b.lh = 4
                     and nvl(a.insurance_line_amount, 0) > 0 then
                    a.insurance_line_amount
                when a.flag_add_line = 1
                     and b.lh = 5
                     and nvl(a.other_expenses_line_amount, 0) > 0 then
                    a.other_expenses_line_amount
            end line_amount_esp
        from
            tp_lines a,
            (
                select
                    level lh
                from
                    dual
                connect by
                    level <= 5
            )        b
    ), tp_lines_b as (
        select
            a.*
        from
            tp_lines_a a
        where
            ( a.line_type_esp = 'Item'
              or ( a.line_type_esp in ( 'Freight', 'Miscellaneous' )
                   and a.item_desc_esp is not null ) )
        --order by a.line_number_esp
    ), l as (
        select
            l.efd_header_id,
            l.efd_line_id
       --, l.line_number
            ,
            nvl(l.line_number_esp, l.line_number)                                                                                                     line_number
            ,
            case
                when l.line_type_esp = 'Item' then
                    nvl(l.line_amount, l.line_quantity * l.unit_price)
                else
                    l.line_amount_esp
            end                                                                                                                                       line_amount
            ,
            nvl(l.ipi_amount, 0) + nvl(l.freight_line_amount, 0) - nvl(l.discount_line_amount, 0) + nvl(l.insurance_line_amount, 0) +
            nvl(l.icms_st_amount, 0) dif_nfe,
            nvl(l.uom_to_desc, uom_to)                                                                                                                uom_to
            ,
            l.fiscal_classification_to
       --, NVL(l.item_info.DESCRIPTION,l.item_descr_efd) item_desc
            ,
            nvl(l.item_desc_esp,
                nvl(l.item_info.description,
                    l.item_descr_efd))                                                                                                                item_desc
       --, NVL(l.item_info.ITEM_NUMBER,l.item_code_efd)  item_code
                    ,
            case
                when l.line_type_esp = 'Item' then
                    nvl(l.item_info.item_number,
                        l.item_code_efd)
            end                                                                                                                                       item_code -- Robson 15/06/2023
       --, l.line_quantity
            ,
            case
                when not l.line_type_esp = 'Item' then
                    1
                else
                    l.line_quantity
            end                                                                                                                                       line_quantity -- Robson 15/06/2023
       --, l.unit_price
            ,
            case
                when not l.line_type_esp = 'Item' then
                    l.line_amount_esp
                else
                    l.unit_price
            end                                                                                                                                       unit_price
            ,
            l.shipto_info.location_code                                                                                                               location_code
            ,
            l.shipto_info.location_name                                                                                                               location_name
            ,
            nvl(l.order_info.line_locations.assessable_value,
                l.line_amount)                                                                                                                        line_amt
                ,
            nvl(
                regexp_replace(l.item_info.item_type,
                               '{|}',
                               ''),
                'Services'
            )                                                                                                                                         item_type
            ,
            l.source_doc_number,
            l.source_doc_line_num,
            l.order_info.vendor_name                                                                                                                  vendor_name
            ,
            nvl(l.order_info.line_locations.shipment_num,
                1)                                                                                                                                    shipment_num
                ,
            l.fiscal_classification
       --, nvl(MAX((SELECT MAX(determining_factor) FROM rmais_efd_taxes tx WHERE tx.efd_line_id = l.efd_line_id)),rmais_process_pkg.Get_Parameter('DETERM_FACTOR')) determining_factor
            ,
            l.catalog_code_ncm,
            l.cfop_to,
            l.net_amount,
            l.source_document_type,
            l.destination_type,
            l.item_type                                                                                                                               item_type_na
            ,
            l.product_category,
            l.user_defined,
            ( l.intended_use )                                                                                                                        intended_use_descr
            ,
            (
                select distinct
                    c.classification_code
                from 
                --RMAIS_CFOP_OUT_IN a
                --inner join rmais_utilization_cfop b on a.utilization_id = b.id
                    rmais_utilizations_ws c
                where
                    c.classification_name = l.intended_use
            )                                                                                                                                         intended_use
            ,
            l.item_description,
            to_char(to_timestamp_tz(nvl(
                json_value(l.order_info, '$.CREATION_DATE'),
                json_value(l.order_info, '$.LINES.CREATION_DATE')
            ),
                    'RRRR-MM-DD"T"HH24:MI:SS TZR'),
                    'RRRR-MM-DD')                                                                                                                     cricao_po
                    ,
            l.combination_descr,
            l.line_type_esp,
            l.withholding
        from
            tp_lines_b l --adicionado busca WS 17/02/2022
        where
            1 = 1-- ROWNUM <=10
        group by
            l.efd_header_id,
            l.efd_line_id
       --, l.line_number
            ,
            nvl(l.line_number_esp, l.line_number),
            l.line_amount,
            l.ipi_amount,
            l.freight_line_amount,
            l.discount_line_amount,
            l.insurance_line_amount,
            l.icms_st_amount,
            nvl(l.uom_to_desc, uom_to),
            l.fiscal_classification_to,
            nvl(l.item_desc_esp,
                nvl(l.item_info.description,
                    l.item_descr_efd)),
            case
                when l.line_type_esp = 'Item' then
                        nvl(l.item_info.item_number,
                            l.item_code_efd)
            end,
            l.line_quantity,
            case
                when not l.line_type_esp = 'Item' then
                        l.line_amount_esp
                else
                    l.unit_price
            end,
            l.unit_price,
            l.shipto_info.location_code,
            l.shipto_info.location_name,
            nvl(l.order_info.line_locations.assessable_value,
                l.line_amount),
            nvl(
                regexp_replace(l.item_info.item_type,
                               '{|}',
                               ''),
                'Services'
            ),
            l.source_doc_number,
            l.source_doc_line_num,
            l.order_info.vendor_name,
            l.line_number,
            l.fiscal_classification,
            l.catalog_code_ncm,
            l.line_number,
            l.order_info.line_locations.shipment_num,
            l.cfop_to,
            l.net_amount,
            l.source_document_type,
            l.destination_type,
            l.item_type,
            l.product_category,
            l.user_defined,
            l.intended_use,
            l.item_description,
            to_char(to_timestamp_tz(nvl(
                json_value(l.order_info, '$.CREATION_DATE'),
                json_value(l.order_info, '$.LINES.CREATION_DATE')
            ),
                    'RRRR-MM-DD"T"HH24:MI:SS TZR'),
                    'RRRR-MM-DD'),
            l.combination_descr,
            case
                when not l.line_type_esp = 'Item' then
                        1
                else
                    l.line_quantity
            end,
            l.line_type_esp,
            case
                when l.line_type_esp = 'Item' then
                        nvl(l.line_amount, l.line_quantity * l.unit_price)
                else
                    l.line_amount_esp
            end,
            l.withholding
        order by
            nvl(l.line_number_esp, l.line_number)
    ), payload as (
        select
                json_object(
                    'InvoiceNumber' is h.document_number,
                            'InvoiceCurrency' is nvl(h.currency_code, 'BRL'),
                            'PaymentCurrency' is nvl(h.currency_code, 'BRL'),
                            'PaymentMethod' is
                        case
                            when h.model in('06', '22', '23', '24', '25') then
                                'CONCESSIONARIA'
                            else
                                null
                        end,
                            'PaymentTerms' is
                        case
                            when h.source_type = 'NA' then
                                'IMEDIATO'
                            else
                                (
                                    select
                                        json_value(order_info, '$.TERMS')
                                    from
                                        rmais_efd_lines
                                    where
                                            efd_header_id = h.efd_header_id
                                        and rownum = 1
                                )
                        end,
                            'InvoiceAmount' is h.total_amount,
                            'InvoiceDate' is to_char(h.issue_date, 'RRRR-MM-DD'),
                            'InvoiceReceivedDate' is to_char(sysdate, 'RRRR-MM-DD'),
                            'BusinessUnit' is
                        case
                            when nvl((
                                select
                                    source_document_type
                                from
                                    rmais_efd_lines l
                                where
                                        l.efd_header_id = h.efd_header_id
                                    and rownum = 1
                                    and l.source_document_type is not null
                            ), 'PO') = 'PO' then
                                rmais_process_pkg.get_bu_name(h.legal_entity_cnpj)
                            when h.model = '98'  then
                                rmais_process_pkg.get_bu_name(h.receiver_document_number)
                            when h.receiver_info.data[0].bu_name is null then
                                rmais_process_pkg.get_bu_name(h.receiver_document_number)
                            else
                                nvl(h.receiver_info.data[0].bu_name, h.receiver_name)
                        end,
                            'ProcurementBU' is 'PACAEMBU_CENTRALIZADORA_COMPRAS',
                            'Supplier' is nvl(h.party_name,
                                              nvl(
                                                                  nvl((
                                                                      select
                                                                          party_name
                                                                      from
                                                                          json_table(h.issuer_info,
                                                                      '$.DATA[*]'
                                                                              columns(
                                                                                  party_name varchar2(500) path '$.PARTY_NAME',
                                                                      tax_payer_number varchar2(500) path '$.TAX_PAYER_NUMBER'
                                                                              )
                                                                          )
                                                                      where
                                                                              rownum = 1
                                                                          and to_number(tax_payer_number) = to_number(h.issuer_document_number
                                                                          )
                                                                  ),
                                                                      nvl(
                                                                      nvl(h.issuer_info.data.party_name,
                                                                          (
                                                                          select
                                                                              max(l.order_info.vendor_name)
                                                                          from
                                                                              rmais_efd_lines l
                                                                          where
                                                                                  l.efd_header_id = h.efd_header_id
                                                                              and rownum = 1
                                                                      )), --h.issuer_name
                                                                      json_value(h.issuer_info, '$.PARTY_NAME')
                                                                  )),
                                                                  h.party_name
                                                              )),
                            'SupplierSite' is
                        case
                            when h.model = '980' then 
                                                --        h.issuer_document_number
                                (
                                    select
                                        supplier_site
                                    from
                                        rmais_suplier_site_guias
                                    where
                                        id_site = h.vendor_site_code
                                )
                            else
                                case
                                    when length(nvl(h.vendor_site_code, h.issuer_document_number)) = 11 then
                                            nvl(h.vendor_site_code, h.issuer_document_number)
                                    else
                                        nvl(h.vendor_site_code, h.issuer_document_number)
                                end
                        end,
                            'AccountingDate' is to_char(sysdate - 60, 'RRRR-MM-DD')              
           --,'PaymentTerms'                        IS null
                            ,
                            'TermsDate' is to_char(first_due_date, 'RRRR-MM-DD')
           --,'LegalEntity'                         IS h.LEGAL_ENTITY_NAME
                            ,
                            'LegalEntityIdentifier' is --CASE WHEN h.DOCUMENT_TYPE  = 'PO' then h.legal_entity_cnpj else h.receiver_document_number end
                        case
                            when(
                                select
                                    source_document_type
                                from
                                    rmais_efd_lines l
                                where
                                        l.efd_header_id = h.efd_header_id
                                    and rownum = 1
                                    and l.source_document_type is not null
                            ) = 'PO' then
                                h.legal_entity_cnpj
                            else
                                (h.receiver_document_number)
                        end,
                            'TaxationCountry' is 'Brazil',
                            'FirstPartyTaxRegistrationId' is h.org_id --buscar via api, ver com o nene.         
            --,'FirstPartyTaxRegistrationNumber'      IS h.receiver_document_number              
                            ,
                            'InvoiceSource' is
                        case
                            when h.model = '98' then
                                'RECEBEMAISGUIAS'
                            when h.model = '00' then
                                'RECEBEMAIS SERVICO'
                            else
                                'RECEBEMAIS'
                        end
            --,'Requester'                            is 'CONCESSIONARIAS RM'--'CONCESSIONARIAS RM'             
                        ,
                            'invoiceDff' is(
                        select
                            json_array(
                                json_object(
                                    '__FLEX_Context' is
                                        case
                                            when model = '00' then /*'ISVCLS_BRA'*/
                                                null
                                            else
                                                (
                                                    select
                                                        context
                                                    from
                                                        rmais_modelo_guias
                                                    where
                                                        cod_guia = h.context
                                                )
                                        end,
                                            '__FLEX_Context_DisplayValue' is
                                        case
                                            when model = '00' then /*'ISV Additional Information'*/
                                                null
                                            else
                                                (
                                                    select
                                                        display_value
                                                    from
                                                        rmais_modelo_guias
                                                    where
                                                        cod_guia = h.context
                                                )
                                        end,
                                            'isvModel' is null,--CASE when h.model = '00' then '39' else null end,
                                            'isvSerie' is null,--CASE when h.model = '00' then rmais_process_pkg.Get_Parameter('GET_SERIE_NFSE') else null end,
                                            'isvSubserie' is '',
                                            'isvAccessKey' is '',
                                            case
                                            when h.context in('FGTS', 'DARJ', 'DARF') then
                                                'codigoDaReceita'
                                            when h.context = 'GRU' then
                                                'codigoDeRecolhimento'
                                            else
                                                'NULO_CODE'
                                            end
                                    is
                                        case
                                            when h.context in('DARJ', 'FGTS', 'GRU', 'DARF') then
                                                h.codigo_guia
                                            else
                                                null
                                        end,
                                            'nomeContribuinte' is h.nome_contribuinte,
                                            case
                                                when h.context in('DARJ', 'DARF') then
                                                    'periodoApuracaoCompetencia'
                                                else
                                                    'NULO_PERIODO'
                                            end
                                    is
                                        case
                                            when h.context in('DARJ', 'DARF') then
                                                h.periodo
                                            else
                                                null
                                        end,
                                            'numeroDaInscricaoEstadual' is h.inscricao_estadual,
                                            'numeroDoDocumentoOrigem' is h.numero_documento,
                                            'numeroDeReferencia' is h.referencia,
                                            case
                                                when h.context in('FGTS', 'GRU', 'GUIA') then
                                                    'metodoDeEntrada'
                                                else
                                                    'NULO_MTH_BAR'
                                            end
                                    is
                                        case
                                            when h.context in('FGTS', 'GRU', 'GUIA') then
                                                'MANUAL'
                                            else
                                                null
                                        end,
                                            case
                                                when h.context in('FGTS', 'GRU', 'GUIA') then
                                                    'codigoDeBarras'
                                                else
                                                    'NULO_COD_BAR'
                                            end
                                    is
                                        case
                                            when h.context in('FGTS', 'GRU', 'GUIA') then
                                                regexp_replace(h.boleto_cod, '[^0-9]')
                                            else
                                                null
                                        end,
                                            'campoIdentificadorDoFgts' is h.id_recolhimento_fgts,
                                            'lacreDaConectividadeSocial' is h.conectividade_social_fgts,
                                            'dvDoLacreDaConectividadeSocial' is h.conectividade_social_dv_fgts,
                                            'numeroDeReferencia' is h.referencia_gru,
                                            'competencia' is h.competencia_gru,
                                            'tipoIdentificacaoDoContribuint' is h.idt_contribuinte,
                                            'nroIdentificacaoContribuinte' is h.numero_contribuinte
                        --'laclsBrReference'                    IS h.referencia
                                             absent on null)
                            absent on null)
                        from
                            dual
                        where
                            h.model = '98'
                    ),
                            'invoiceLines' is(
                    select
                        json_arrayagg(
                            json_object(
                                'LineNumber' is rownum--l.line_number
                                ,
                                        'LineAmount' is l.line_amount,
                                        'AccountingDate' is sysdate - 60--l.cricao_po
           --,'BudgetDate'                          IS l.cricao_po
                                        ,
                                        'ShipToLocation' is
                                    case
                                        when h.model in('55', '00') then
                                            rmais_process_pkg.get_ship_to_location(h.receiver_document_number)
                                        else
                                            null
                                    end,
                                        'UOM' is
                                    case
                                        when line_type_esp = 'Item' then
                                            l.uom_to
                                        else
                                            null
                                    end,
                                        'LineType' is l.line_type_esp,
                                        'Description' is l.item_desc,
                                        'Item' is
                                    case
                                        when h.model = '98' then
                                            null
                                        else
                                            l.item_code
                                    end,
                                        'Quantity' is
                                    case
                                        when line_type_esp = 'Item' then
                                            l.line_quantity
                                        else
                                            null
                                    end,
                                        'UnitPrice' is
                                    case
                                        when line_type_esp = 'Item' then
                                            l.unit_price
                                        else
                                            null
                                    end
           --, decode(l.source_document_type,'NA','ProductType','Withholding')          IS CASE WHEN l.source_document_type = 'NA' THEN l.item_type_na ELSE NULL END
                                    ,
                                        'UserDefinedFiscalClassification' is
                                    case
                                        when line_type_esp = 'Item' then
                                            l.user_defined
                                        else
                                            null
                                    end,
                                        'ProductFiscalClassification' is
                                    case
                                        when h.model = '00' then
                                            '|'
                                            || to_number(replace(l.fiscal_classification, '.', ''))
                                            || '|'
                                        else
                                            case
                                                when line_type_esp = 'Item' then
                                                        l.fiscal_classification
                                                else
                                                    null
                                            end
                                    end,
                                        'ProductFiscalClassificationCode' is
                                    case
                                        when h.model = '00' then
                                            '|'
                                            || to_number(replace(l.fiscal_classification, '.', ''))
                                            || '|'
                                        else
                                            case
                                                when line_type_esp = 'Item' then
                                                        l.fiscal_classification
                                                else
                                                    null
                                            end
                                    end,
                                        'ProductFiscalClassificationType' is /*case when h.model = '00' then null else*/
                                    case
                                        when line_type_esp = 'Item' then
                                                case
                                                    when h.model in('55', '00') then
                                                        'LACLS_NCM_SERVICE_CODE'
                                                    else
                                                        null
                                                end /*else null end*/
                                    end
           /*
           ,'ProductFiscalClassification'         IS case when h.model = '00' then null else case when LINE_TYPE_ESP = 'Item' then l.fiscal_classification else null end end
           ,'ProductFiscalClassificationCode'     IS case when h.model = '00' then null else case when LINE_TYPE_ESP = 'Item' then l.fiscal_classification else null end end
           ,'ProductFiscalClassificationType'     IS case when h.model = '00' then null else case when LINE_TYPE_ESP = 'Item' then case when h.model in ('55','00') then 'LACLS_NCM_SERVICE_CODE' else null end else null end end
           */,
                                        'ProductType' is
                                    case
                                        when line_type_esp = 'Item' then
                                                case
                                                    when h.model in('55') then
                                                        'Goods'
                                                    when h.model in('00') then
                                                        'Services'
                                                    else
                                                        null
                                                end
                                        else
                                            null
                                    end,
                                        'DistributionCombination' is
                                    case
                                        when h.document_type = 'NA' then
                                            l.combination_descr
                                        else
                                            null
                                    end
           --,'DistributionCombination'             IS trim(case when LINE_TYPE_ESP = 'Item' then l.COMBINATION_DESCR when LINE_TYPE_ESP = 'Miscellaneous' then replace(l.COMBINATION_DESCR,substr(substr(l.COMBINATION_DESCR,instr(l.COMBINATION_DESCR,'-',instr(l.COMBINATION_DESCR,'-')+1)+1),1,instr(substr(l.COMBINATION_DESCR,instr(l.COMBINATION_DESCR,'-',instr(l.COMBINATION_DESCR,'-')+1)+1),'-')-1),'422060001') else null end)
                                    ,
                                        'TransactionBusinessCategoryCodePath' is
                                    case
                                        when line_type_esp = 'Item' then
                                                case
                                                    when h.model in('55', '00') then
                                                        'PURCHASE_TRANSACTION/OPERATION FISCAL CODE/'
                                                        || nvl(l.cfop_to,
                                                               case
                                                                   when h.issuer_address_state = h.receiver_address_state then
                                                                       '1'
                                                                   else
                                                                       '2'
                                                               end
                                                               || '933')
                                                    else
                                                        null
                                                end
                                        else
                                            null
                                    end,
                                        'IntendedUseCode' is l.intended_use,
                                        'IntendedUse' is l.intended_use_descr 
            --comentado para tentar enviar para dentro.                                                                      --,'ProductFiscalClassification'         IS l.fiscal_classification
           --               
                                        ,
                                        'PurchaseOrderNumber' is
                                    case
                                        when nvl(l.source_document_type, 'PO') = 'NA' then
                                            null
                                        else
                                            l.source_doc_number
                                    end,
                                        'PurchaseOrderLineNumber' is
                                    case
                                        when nvl(l.source_document_type, 'PO') = 'NA' then
                                            null
                                        else
                                            l.source_doc_line_num
                                    end,
                                        'PurchaseOrderScheduleLineNumber' is
                                    case
                                        when nvl(l.source_document_type, 'PO') = 'NA' then
                                            null
                                        else
                                            l.shipment_num
                                    end,
                                        'ProductCategory' is l.product_category,
                                        'Withholding' is l.withholding absent on null)
                        absent on null returning clob)
                    from
                        l
                    where
                        l.efd_header_id = h.efd_header_id
                ) absent on null returning clob)
            doc,
                h.efd_header_id
        from
            rmais_efd_headers h
        where
            h.model != 'BO'
    ), pre_payload_bol as (
        select distinct
            efd_header_id,
            access_key_number,
            document_number,
            issue_date,
            first_due_date,
            total_amount,
            boleto_cod,
            bol_bank_id,
            bol_branch_id,
            bol_account_id,
            receiver_document_number,
            nvl(b.name, receiver_name)     receiver_name,
            issuer_document_number,
            nvl(a.party_name, issuer_name) issuer_name
        from
            rmais_efd_headers h,
            json_table ( h.issuer_info, '$'
                    columns (
                        tax_payer_number varchar2 ( 500 ) path '$.P_TAX_PAYER_NUMBER',
                        party_name varchar2 ( 500 ) path '$.DATA.PARTY_NAME',
                        nested path '$.DATA.ADDRESS[*]'
                            columns (
                                vendor_site_code varchar2 ( 100 ) path '$.VENDOR_SITE_CODE'
                            )
                    )
                )
            a,
            json_table ( replace(
                    replace(h.receiver_info, '"DATA":{', '"DATA":[{'),
                    '}}}',
                    '}}]}'
                ), '$'
                    columns (
                        party_name varchar2 ( 500 ) path '$.P_REGISTRATION_NUMBER',
                        party_name2 varchar2 ( 500 ) path '$.DATA.NAME',
                        nested path '$.DATA[*]'
                            columns (
                                name varchar2 ( 100 ) path '$.NAME'
                            )
                    )
                )
            b
        where
            h.model = 'BO'
    ), payload_bol as (
        select
                json_object(
                    'invoice_num' value document_number,
                            'invoice_date' value to_char(issue_date, 'YYYY-MM-DD'),
                            'due_date' value to_char(first_due_date, 'YYYY-MM-DD'),--verificar data de pagamento
                            'amount' value total_amount,
                            'barcode' value regexp_replace(boleto_cod, '[^[:digit:]]'),
                            'cnpj_paying' value receiver_document_number,
                            'name_paying' value receiver_name,
                            'cnpj_supplier' value issuer_document_number,
                            'name_supplier' value issuer_name,
                            'site_supplier' value null,
                            'banco' value bol_bank_id,
                            'agencia' value bol_branch_id,
                            'cc' value bol_account_id
                returning clob)
            doc,
                efd_header_id
        from
            pre_payload_bol
    )
    select
        doc,
        efd_header_id
    from
        payload
    union all
    select
        doc,
        efd_header_id
    from
        payload_bol;


-- sqlcl_snapshot {"hash":"bf48f9cb0289373e80b74a126ca7b25c592a000b","type":"VIEW","name":"VW_GET_INVOICE","schemaName":"RMAIS","sxml":""}