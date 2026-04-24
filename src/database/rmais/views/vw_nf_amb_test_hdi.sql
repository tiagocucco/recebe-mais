create or replace force editionable view vw_nf_amb_test_hdi (
    body,
    efd_header_id
) as
    select
            json_object(
                'ORG_ID' value a.org_id,--
                        'DOCUMENT_TYPE' value a.document_type,--
                        'ACCESS_KEY_NUMBER' value a.access_key_number,
                        'DOCUMENT_NUMBER' value a.document_number,
                        'MODEL' value a.model,
                        'ISSUE_DATE' value a.issue_date,
                        'TOTAL_AMOUNT' value a.total_amount,
                        'DOCUMENT_STATUS' value a.document_status,
                        'ADDITIONAL_INFORMATION' value a.additional_information,--
                        'ISSUER_NAME' value a.issuer_name,
                        'ISSUER_DOCUMENT_NUMBER' value a.issuer_document_number,
                        'ISSUER_ADDRESS_STREET' value a.issuer_address,
                        'ISSUER_ADDRESS_NUMBER' value a.issuer_address_number,
                        'ISSUER_ADDRESS_STATE' value a.issuer_address_state,
                        'ISSUER_ADDRESS_COMPLEMENT' value a.issuer_address_complement,
                        'ISSUER_ADDRESS_ZIP_CODE' value a.issuer_address_zip_code,
                        'ISSUER_ADDRESS_CITY_CODE' value a.issuer_address_city_code,
                        'ISSUER_ADDRESS_CITY_NAME' value a.issuer_address_city_name,
                        'RECEIVER_NAME' value a.receiver_name,
                        'RECEIVER_DOCUMENT_NUMBER' value a.receiver_document_number,
                        'RECEIVER_ADDRESSSTREET' value a.receiver_address,
                        'RECEIVER_ADDRESSNUMBER' value a.receiver_address_number,
                        'RECEIVER_ADDRESSCITY_CODE' value a.receiver_address_city_code,
                        'RECEIVER_ADDRESSCITY_NAME' value a.receiver_address_city_name,
                        'RECEIVER_ADDRESSSTATE' value a.receiver_address_state,
                        'RECEIVER_ADDRESSCOMPLEMENT' value a.receiver_address_complement,
                        'RECEIVER_ADDRESSZIP_CODE' value a.receiver_address_zip_code,
                        'PIS_AMOUNT' value a.pis_amount,
                        'COFINS_AMOUNT' value a.cofins_amount,
                        'CREATION_DATE' value a.creation_date,--
                        'LAST_UPDATE_DATE' value a.last_update_date,----
                        'LAST_UPDATED_BY' value a.last_updated_by,
                        'SIMPLE_NATIONAL_INDICATOR' value a.simple_national_indicator,--
                        'INSS_AMOUNT' value a.inss_amount,
                        'NET_AMOUNT' value a.net_amount,--
                        'IR_AMOUNT' value a.ir_amount,
                        'ISS_AMOUNT' value a.iss_amount,
                        'ISS_BASE' value a.iss_base,
                        'COD_VERIF_NFS' value a.cod_verif_nfs,
                        'CURRENCY_CODE' value a.currency_code,
                        'ISSUER_INFO' value a.issuer_info,    --
                        'RECEIVER_INFO' value a.receiver_info,    ----
                        'CSLL_AMOUNT' value a.csll_amount,
                        'MUNICIPIO_INCIDENCIA' value a.municipio_incidencia,    --
                        'BU_NAME' value a.bu_name,
                        'WITHHOLDING' value a.withholding,  --
                        'ISS_RET_FLAG' value a.iss_ret_flag,  ----
                        'BOLETO_COD' value a.boleto_cod,  ----BOLETO_COD--
                        'FLAG_VALID_BOLETO' value a.flag_valid_boleto,
                        'DEFINE_DET_ENTRY_TYPE' value a.define_det_entry_type,--
                        'PARTY_NAME' value a.party_name,--
                        'INTEGRATED' value a.integrated,--
                        'RECEIVER_MUN_REGISTRATION' value a.receiver_mun_registration,--
                        'ORIGINAL_DOCUMENT_NUMBER' value a.original_document_number,--
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
                                'SOURCE_DOCUMENT_TYPE' value b.source_document_type,
                                        'SOURCE_DOC_NUMBER' value b.source_doc_number,
                                'SOURCE_DOC_LINE_NUM' value b.source_doc_line_num
                            )
                        )
                    from
                        rmais_efd_lines_hdi b
                    where
                        a.efd_header_id = b.efd_header_id
                )
    --,'PDF_FILE' VALUE case when a.pdf_file is null then null else replace(replace(replace(replace(xxrmais_util_pkg.base64encode(nvl(a.pdf_file,'[]')), chr(10),''),chr(13),''), chr(09), '') ,' ','') end
                ,
                        'PDF_FILENAME' value a.pdf_filename
    -- ,'BLOB_FILE' VALUE case when a.BLOB_FILE is null then null else replace(replace(replace(replace(xxrmais_util_pkg.base64encode(nvl(a.BLOB_FILE,'')), chr(10),''),chr(13),''), chr(09), '') ,' ','') end
    -- ,'BLOB_FILENAME' VALUE a.BLOB_FILENAME
            returning clob)
        body,
            a.efd_header_id
    from
        rmais_efd_headers_hdi a;


-- sqlcl_snapshot {"hash":"58c897bf5bf9ad9b2c870655fdd8f8aaca9845af","type":"VIEW","name":"VW_NF_AMB_TEST_HDI","schemaName":"RMAIS","sxml":""}