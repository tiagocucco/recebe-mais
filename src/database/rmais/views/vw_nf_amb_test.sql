create or replace force editionable view vw_nf_amb_test (
    body,
    efd_header_id
) as
    select
            json_object(
                'MODEL' value a.model,
                        'CURRENCY_CODE' value a.currency_code,
                        'DOCUMENT_NUMBER' value a.document_number,
                        'ACCESS_KEY_NUMBER' value a.access_key_number,
                        'ISSUE_DATE' value a.issue_date,
                        'TOTAL_AMOUNT' value a.total_amount,
                        'RECEIVER_DOCUMENT_NUMBER' value a.receiver_document_number,
                        'RECEIVER_NAME' value a.receiver_name,
                        'RECEIVER_ADDRESSSTREET' value a.receiver_address,
                        'RECEIVER_ADDRESSNUMBER' value a.receiver_address_number,
                        'RECEIVER_ADDRESSCITY_CODE' value a.receiver_address_city_code,
                        'RECEIVER_ADDRESSCITY_NAME' value a.receiver_address_city_name,
                        'RECEIVER_ADDRESSSTATE' value a.receiver_address_state,
                        'RECEIVER_ADDRESSCOMPLEMENT' value a.receiver_address_complement,
                        'RECEIVER_ADDRESSZIP_CODE' value a.receiver_address_zip_code,
                        'ISSUER_DOCUMENT_NUMBER' value a.issuer_document_number,
                        'ISSUER_NAME' value a.issuer_name,
                        'ISSUER_ADDRESS_STREET' value a.issuer_address,
                        'ISSUER_ADDRESS_NUMBER' value a.issuer_address_number,
                        'ISSUER_ADDRESS_CITY_CODE' value a.issuer_address_city_code,
                        'ISSUER_ADDRESS_CITY_NAME' value a.issuer_address_city_name,
                        'ISSUER_ADDRESS_STATE' value a.issuer_address_state,
                        'ISSUER_ADDRESS_COMPLEMENT' value a.issuer_address_complement,
                        'ISSUER_ADDRESS_ZIP_CODE' value a.issuer_address_zip_code,
                        'LANC_COM_IMPOSTO' value a.lanc_com_imposto,
                        'PIS_AMOUNT' value a.pis_amount,
                        'COFINS_AMOUNT' value a.cofins_amount,
                        'INSS_AMOUNT' value a.inss_amount,
                        'IR_AMOUNT' value a.ir_amount,
                        'ISS_AMOUNT' value a.iss_amount,
                        'CSLL_AMOUNT' value a.csll_amount,
                        'CODIGO_GUIA' value a.codigo_guia,
                        'ID_RECOLHIMENTO_FGTS' value a.id_recolhimento_fgts,
                        'CONECTIVIDADE_SOCIAL_FGTS' value a.conectividade_social_fgts,
                        'REFERENCIA_GRU' value a.referencia_gru,
                        'COMPETENCIA_GRU' value a.competencia_gru,
                        'IDT_CONTRIBUINTE' value a.idt_contribuinte,
                        'NUMERO_CONTRIBUINTE' value a.numero_contribuinte,
                        'NOME_CONTRIBUINTE' value a.nome_contribuinte,
                        'PERIODO' value a.periodo,
                        'REFERENCIA' value a.referencia,
                        'INSCRICAO_ESTADUAL' value a.inscricao_estadual,
                        'NUMERO_DOCUMENTO' value a.numero_documento,
                        'INVOICE_ID' value a.invoice_id,
                        'DOCUMENT_STATUS' value a.document_status,
                        'LINES' value(
                    select
                        json_arrayagg(
                            json_object(
                                'EFD_HEADER_ID' value b.efd_header_id,
                                'EFD_LINE_ID' value b.efd_line_id,
                                'CREATION_DATE' value b.creation_date,
                                'CREATED_BY' value b.created_by,
                                'LAST_UPDATE_DATE' value b.last_update_date,
                                        'LAST_UPDATED_BY' value b.last_updated_by,
                                'LINE_NUMBER' value b.line_number,
                                'FISCAL_CLASSIFICATION' value b.fiscal_classification,
                                'LINE_QUANTITY' value b.line_quantity,
                                'UNIT_PRICE' value b.unit_price,
                                        'LINE_AMOUNT' value b.line_amount,
                                'ITEM_DESCRIPTION' value b.item_description,
                                'CFOP_FROM' value b.cfop_from,
                                'FISCAL_CLASSIFICATION_TO' value b.fiscal_classification_to,
                                'COMBINATION_DESCR' value b.combination_descr,
                                        'SOURCE_DOCUMENT_TYPE' value b.source_document_type,
                                'SOURCE_DOC_NUMBER' value b.source_doc_number,
                                'SOURCE_DOC_LINE_NUM' value b.source_doc_line_num
                            )
                        )
                    from
                        rmais_efd_lines b
                    where
                        a.efd_header_id = b.efd_header_id
                ),
                        'PDF_FILE' value replace(
                    replace(
                        replace(
                            replace(
                                xxrmais_util_pkg.base64encode(a.pdf_file),
                                chr(10),
                                ''
                            ),
                            chr(13),
                            ''
                        ),
                        chr(09),
                        ''
                    ),
                    ' ',
                    ''
                ),
                        'PDF_FILENAME' value a.pdf_filename
            returning clob)
        body,
            a.efd_header_id
    from
        rmais_efd_headers a;


-- sqlcl_snapshot {"hash":"e9050ba7ef93c51ab2f8eee2342b61fdace18c10","type":"VIEW","name":"VW_NF_AMB_TEST","schemaName":"RMAIS","sxml":""}