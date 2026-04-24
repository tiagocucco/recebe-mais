create or replace force editionable view rmais_monta_lst_anexos (
    efd_header_id,
    pdf_file,
    pdf_filename,
    model,
    access_key_number,
    issuer_address_city_code,
    document_number,
    id_boleto
) as
    with tp_anexo_orig as (
        select
            efd_header_id,
            nvl(pdf_file, xls_file)         pdf_file,
            nvl(pdf_filename, xls_filename) pdf_filename,
            model,
            access_key_number,
            issuer_address_city_code,
            document_number,
            id_boleto
        from
            rmais_efd_headers
    ), tp_anexo_bol_x as (
        select
            b.efd_header_id,
            nvl(a.pdf_file, a.xls_file)         pdf_file,
            nvl(a.pdf_filename, a.xls_filename) pdf_filename,
            b.model,
            b.access_key_number,
            b.issuer_address_city_code,
            b.document_number,
            b.id_boleto
        from
            rmais_efd_headers a,
            rmais_efd_headers b
        where
            a.efd_header_id = b.id_boleto
    ), tp_anexo_bol_y as (
        select
            b.efd_header_id,
            nvl(a.pdf_file, a.xls_file)         pdf_file,
            nvl(a.pdf_filename, a.xls_filename) pdf_filename,
            b.model,
            b.access_key_number,
            b.issuer_address_city_code,
            b.document_number,
            a.efd_header_id                     id_boleto
        from
            rmais_efd_boletos_v a,
            rmais_efd_headers   b,
            tp_anexo_bol_x      c
        where
                instr(a.assoc, ':') = 0
            and a.assoc = b.efd_header_id
            and b.efd_header_id = c.efd_header_id (+)
            and a.efd_header_id = c.id_boleto (+)
            and c.id_boleto is null
    ), tp_union as (
        select
            *
        from
            tp_anexo_orig
        union all
        select
            *
        from
            tp_anexo_bol_x
        union all
        select
            *
        from
            tp_anexo_bol_y
    )
    select
        efd_header_id,
        pdf_file,
        pdf_filename,
        model,
        access_key_number,
        issuer_address_city_code,
        document_number,
        id_boleto
    from
        tp_union;


-- sqlcl_snapshot {"hash":"073dcc85fb8eb7b8a3b3fc6b7df22968fd369937","type":"VIEW","name":"RMAIS_MONTA_LST_ANEXOS","schemaName":"RMAIS","sxml":""}