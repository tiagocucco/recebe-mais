create or replace force editionable view rmais_get_util_item (
    fornecedor,
    tomador,
    item_description,
    seq_util,
    last_update_date,
    item_code_efd,
    item_descr_efd,
    uom_to,
    uom_to_desc,
    item_type,
    catalog_code_ncm,
    fiscal_classification_to
) as
    (
        select
            fornecedor,
            tomador,
            item_description,
            seq_util,
            last_update_date,
            item_code_efd,
            item_descr_efd,
            uom_to,
            uom_to_desc,
            item_type,
            catalog_code_ncm,
            fiscal_classification_to
        from
            (
                select
                    h.issuer_document_number              fornecedor,
                    h.receiver_document_number            tomador,
                    l.item_description,
                    max(l.last_update_date)
                    over(partition by l.item_description) seq_util,
                    l.last_update_date,
                    l.item_code_efd,
                    item_descr_efd,
                    l.uom_to,
                    l.uom_to_desc,
                    l.item_type,
                    l.catalog_code_ncm,
                    fiscal_classification_to
                from
                    rmais_efd_lines   l,
                    rmais_efd_headers h
                where
                        h.efd_header_id = l.efd_header_id
                    and l.uom_to_desc is not null
   -- AND issuer_document_number = '03246317001253'
    --AND receiver_document_number = '09296295003428'
                    and document_status = 'T'
    --AND l.item_description = 'CALCA PROFISSIONAL FEMININA 13322 AZUL NAVAL 000004 G ADP-UNI-2436'
                    and l.item_code_efd is not null
            )
        where
            seq_util = last_update_date
--AND ROWNUM = 1
    );


-- sqlcl_snapshot {"hash":"32090c4d722dd879029176a10dc3e32d052532d5","type":"VIEW","name":"RMAIS_GET_UTIL_ITEM","schemaName":"RMAIS","sxml":""}