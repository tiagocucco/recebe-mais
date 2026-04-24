create or replace force editionable view rmais_taxes_errors_v (
    access_key_number,
    line_number,
    efd_line_id,
    efd_header_id,
    imposto,
    valor,
    grupo_condicao,
    codigo_imposto,
    codigo_regime,
    tipo_taxa,
    base,
    taxa,
    valor_imp,
    valor_nf
) as
    with tp_lin_a as (
        select
            rh.document_number
            || ' - Emissão: '
            || rh.issue_date
            || ' - Modelo: '
            || rh.model
            || ' - Fornecedor: '
            || issuer_name             access_key_number,
            rl.efd_header_id,
            rl.efd_line_id,
            nvl(rh.inss_amount, 0)     inss_amount,
            nvl(
                nvl(rl.ipi_amount, rh.ipi_amount),
                0
            )                          ipi_amount,
            case
                when rh.model = '55' then
                    nvl(rl.pis_amount, 0)
                else
                    nvl(
                        nvl(rl.pis_amount, rh.pis_amount),
                        0
                    )
            end                        pis_amount,
            case
                when rh.model = '55' then
                    nvl(rl.cofins_amount, 0)
                else
                    nvl(
                        nvl(rl.cofins_amount, rh.cofins_amount),
                        0
                    )
            end                        cofins_amount,
            case
                when rh.model = '55' then
                    nvl(rl.fcp_amount, 0)
                else
                    nvl(
                        nvl(rl.fcp_amount, rh.total_fcp_amount),
                        0
                    )
            end                        fcp_amount,
            nvl(rh.ir_amount, 0)       ir_amount,
            nvl(rh.iss_amount, 0)      iss_amount,
            nvl(rh.csll_amount, 0)     csll_amount,
            nvl(
                nvl(rl.pis_amount, rh.pis_amount),
                0
            ) + nvl(
                nvl(rl.cofins_amount, rh.cofins_amount),
                0
            ) + nvl(rh.csll_amount, 0) crfs,
            nvl(rl.icms_amount, 0)     icms_amount,
            nvl(rl.icms_st_amount, 0)  icms_st_amount,
            rl.line_number
        from
            rmais_efd_lines   rl,
            rmais_efd_headers rh
        where
            rl.efd_header_id = rh.efd_header_id --and rl.efd_header_id = 522926
        --and     rh.document_status IN ('V','T')
        --and     nvl(rl.source_document_type,'PO') = 'PO' 
        --and     (rl.source_doc_line_id is not null) 
        --and     rl.cfop_to is not null
    ), lin as (
        select
            a.access_key_number,
            a.line_number,
            a.efd_line_id,
            a.efd_header_id,
            a.inss_amount,
            a.ipi_amount,
            case
                when nvl(a.csll_amount, 0) > 0
                     and nvl(a.cofins_amount, 0) > 0
                     and nvl(a.pis_amount, 0) > 0 then
                    0
                else
                    a.pis_amount
            end pis_amount,
            case
                when nvl(a.csll_amount, 0) > 0
                     and nvl(a.cofins_amount, 0) > 0
                     and nvl(a.pis_amount, 0) > 0 then
                    0
                else
                    a.cofins_amount
            end cofins_amount,
            case
                when nvl(a.csll_amount, 0) > 0
                     and nvl(a.cofins_amount, 0) > 0
                     and nvl(a.pis_amount, 0) > 0 then
                    0
                else
                    a.csll_amount
            end csll_amount,
            a.fcp_amount,
            a.ir_amount,
            a.iss_amount,
            case
                when nvl(a.csll_amount, 0) > 0
                     and nvl(a.cofins_amount, 0) > 0
                     and nvl(a.pis_amount, 0) > 0 then
                    a.crfs
                else
                    0
            end crfs,
            a.icms_amount,
            a.icms_st_amount
        from
            tp_lin_a a
        where
            1 = 1--A.EFD_HEADER_ID not in (522669,521806,522448,522326)
    ), tp_lin_b as (
        select
            a.access_key_number,
            a.line_number,
            a.efd_line_id,
            a.efd_header_id,
            case b.ln
                when 1  then
                    a.inss_amount
                when 2  then
                    a.ipi_amount
                when 3  then
                    a.pis_amount
                when 4  then
                    a.cofins_amount
                when 5  then
                    a.fcp_amount
                when 6  then
                    a.ir_amount
                when 7  then
                    a.iss_amount
                when 8  then
                    a.csll_amount
                when 9  then
                    a.crfs
                when 10 then
                    a.icms_amount
                when 11 then
                    a.icms_st_amount
            end valor,
            case b.ln
                when 1  then
                    'INSS'
                when 2  then
                    'IPI'
                when 3  then
                    'PIS'
                when 4  then
                    'COFINS'
                when 5  then
                    'FCP'
                when 6  then
                    'IR'
                when 7  then
                    'ISS'
                when 8  then
                    'CSLL'
                when 9  then
                    'CSRF'
                when 10 then
                    'ICMS'
                when 11 then
                    'ICMS_ST'
            end imposto
        from
            lin a,
            (
                select
                    level ln
                from
                    dual
                connect by
                    level <= 11
            )   b
        /*where   case B.LN
                    when 1 then A.inss_amount
                    when 2 then A.ipi_amount
                    when 3 then A.pis_amount
                    when 4 then A.cofins_amount
                    when 5 then A.fcp_amount
                    when 6 then A.IR_AMOUNT
                    when 7 then A.ISS_AMOUNT
                    when 8 then A.CSLL_AMOUNT
                    when 9 then A.CRFS 
                    when 10 then A.icms_amount
                    when 11 then A.icms_st_amount
                end > 0*/
    ), tp_taxes as (
        select distinct
            rtx.efd_line_id,
            rmh.efd_header_id,
            rtx.condition_group_code                                                                                              grupo_condicao
            ,
            rtx.tax_rate_code                                                                                                     codigo_imposto
            ,
            rtx.tax_regime_code                                                                                                   codigo_regime
            ,
            rtx.tax_rate_code                                                                                                     tipo_taxa
            ,
            rtx.percentage_rate                                                                                                   taxa
            ,
            ( nvl(rml.line_amount, rmh.total_amount) ) + ( ( nvl(rml.line_amount, rmh.total_amount) * nvl(base_rate, 0) ) / 100 ) base
            ,
            round(((nvl(rml.line_amount, rmh.total_amount)) +((nvl(rml.line_amount, rmh.total_amount) * nvl(base_rate, 0)) / 100)) *(
            rtx.percentage_rate / 100),
                  2)                                                                                                              valor_imp
                  ,
            rmh.document_status
        from
            rmais_efd_taxes   rtx,
            rmais_efd_lines   rml,
            rmais_efd_headers rmh
        where
                rml.efd_line_id = rtx.efd_line_id
            and rml.efd_header_id = rmh.efd_header_id --and rmh.efd_header_id = 522926
    ), tp_lin_taxes as (
        select
            a.access_key_number,
            a.line_number,
            a.efd_line_id,
            a.efd_header_id,
            a.imposto,
            a.valor,
            b.grupo_condicao,
            b.codigo_imposto,
            b.codigo_regime,
            b.tipo_taxa,
            b.base,
            b.taxa,
            b.valor_imp
        from
            tp_lin_b a,
            (
                select
                    b1.*
                from
                    tp_taxes b1
                where
                    1 = 1
            )        b --B1.document_status IN ('V','T')
        where
                a.efd_line_id = b.efd_line_id (+)
            and ( ( b.codigo_imposto like '%'
                                          || a.imposto
                                          || '%' ) )
            and a.imposto not in ( 'COFINS', 'PIS', 'CFRS' )
    )
    select
        a.access_key_number,
        a.line_number,
        a.efd_line_id,
        a.efd_header_id,
        a.imposto,
        a.valor,
        a.grupo_condicao,
        a.codigo_imposto,
        a.codigo_regime,
        a.tipo_taxa,
        a.base,
        a.taxa,
        a.valor_imp,
        a.valor_nf
    from
        (
            select
                a.access_key_number,
                a.line_number,
                a.efd_line_id,
                a.efd_header_id,
                a.imposto,
                a.valor,
                a.grupo_condicao,
                a.codigo_imposto,
                a.codigo_regime,
                a.tipo_taxa,
                a.base,
                a.taxa,
                a.valor_imp,
                a.valor valor_nf
            from
                tp_lin_taxes a
            union all
            select
                a.access_key_number,
                a.line_number,
                a.efd_line_id,
                a.efd_header_id,
                a.imposto,
                a.valor,
                null    grupo_condicao,
                null    codigo_imposto,
                null    codigo_regime,
                null    tipo_taxa,
                null    base,
                null    taxa,
                null    valor_imp,
                a.valor valor_nf
            from
                tp_lin_b a
            where
                a.imposto not in ( 'COFINS', 'PIS' )
                and nvl(a.valor, 0) > 0
                and not exists (
                    select
                        1
                    from
                        tp_taxes b
                    where
                            a.efd_line_id = b.efd_line_id (+)
                        and ( ( b.codigo_imposto like '%'
                                                      || a.imposto
                                                      || '%' ) )
                )
        ) a
    where
        1 = 1--A.efd_header_id = 522926
--and     nvl(A.valor,0) not between nvl(A.valor_imp,0) - 0.1 and nvl(A.valor_imp,0) + 0.1
    order by
        a.access_key_number,
        a.line_number;


-- sqlcl_snapshot {"hash":"be1de110856ac1d9b5f2590a652190c8034102d8","type":"VIEW","name":"RMAIS_TAXES_ERRORS_V","schemaName":"RMAIS","sxml":""}