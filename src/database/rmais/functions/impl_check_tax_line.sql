create or replace function impl_check_tax_line (
    p_efd_line_id number
) return varchar2 as
    l_model varchar2(10);
begin
    --
    select
        model
    into l_model
    from
        rmais_efd_headers rh,
        rmais_efd_lines   rl
    where
            rh.efd_header_id = rl.efd_header_id
        and rl.efd_line_id = p_efd_line_id;
    --    
    for reg in (
        with pline (
            shuttle_item,
            receipt_num
                                --,utilization_code ROBSON
        ) as (
            select
                nvl(rh.inss_amount, 0)
                || ':'
                || nvl(
                    nvl(rl.ipi_amount, rh.ipi_amount),
                    0
                )
                || ':'
                ||
                case
                    when rh.model = '55' then
                            nvl(rl.pis_amount, 0)
                    else
                        nvl(
                                nvl(rl.pis_amount, rh.pis_amount),
                                0
                            )
                end
                || ':'
                ||
                case
                    when rh.model = '55' then
                            nvl(rl.cofins_amount, 0)
                    else
                        nvl(
                                nvl(rl.cofins_amount, rh.cofins_amount),
                                0
                            )
                end
                || ':'
                ||
                case
                    when rh.model = '55' then
                            nvl(rl.fcp_amount, 0)
                    else
                        nvl(
                                nvl(rl.fcp_amount, rh.total_fcp_amount),
                                0
                            )
                end
                || ':'
                || nvl(rh.ir_amount, 0)
                || ':'
                || nvl(rh.iss_amount, 0)
                || ':'
                || nvl(rh.csll_amount, 0)
                || ':'
                || to_char(nvl(
                    nvl(rl.pis_amount, rh.pis_amount),
                    0
                ) + nvl(
                    nvl(rl.cofins_amount, rh.cofins_amount),
                    0
                ) + nvl(rh.csll_amount, 0))
                || ':'
                || nvl(rl.icms_amount, 0)
                || ':'
                || nvl(rl.icms_st_amount, 0),
                'INSS:IPI:PIS:COFINS:FCP:IR:ISS:CSLL:CSRF:ICMS:ICMS_ST'
                                    --,utilization_code ROBSON
            from
                rmais_efd_headers rh,
                rmais_efd_lines   rl
            where
                    rl.efd_header_id = rh.efd_header_id
                and efd_line_id = p_efd_line_id--4394761
        ), line as (
            select distinct
                rtx.efd_line_id,
                rtx.condition_group_code                                                grupo_condicao,
                rtx.tax_rate_code                                                       codigo_imposto,
                rtx.tax_regime_code                                                     codigo_regime,
                rtx.tax_rate_code                                                       tipo_taxa,
                rtx.percentage_rate                                                     taxa
                           --,rmh.total_amount  base
                           --,ROUND((rmh.total_amount)*(rtx.percentage_rate/100),2)  valor
                                  --,(rmh.total_amount) + ((rmh.total_amount * nvl(base_rate,0))/100)  base
       --,ROUND(((rmh.total_amount) + ((rmh.total_amount * nvl(base_rate,0))/100))*(rtx.percentage_rate/100),2)  valor
                ,
                ( rml.line_amount ) + ( ( rml.line_amount * nvl(base_rate, 0) ) / 100 ) base,
                round(((rml.line_amount) +((rml.line_amount * nvl(base_rate, 0)) / 100)) *(rtx.percentage_rate / 100),
                      2)                                                                valor
       --,rml.utilization_code utilization_code2 ROBSON
            from
                rmais_efd_taxes   rtx,
                rmais_efd_lines   rml,
                rmais_efd_headers rmh
            where
                    rml.efd_line_id = rtx.efd_line_id
                and rml.efd_header_id = rmh.efd_header_id
                and rml.efd_line_id = p_efd_line_id
        )
        select
            *
        from
            (
                select
                    case
                        when nvl(valor, 0) between nvl(valor_nf, 0) - 0.1 and nvl(valor_nf, 0) + 0.1 then
                            'Ok'
                        else
                            'Error'
                    end   status,
                    tax_nf,
                    valor valor,
                    valor_nf
                           --utilization_code ROBSON
                from
                    (
                        select -- l.*
                            l.efd_line_id,
                            l.grupo_condicao,
                            l.codigo_imposto,
                            l.codigo_regime,
                            l.tipo_taxa,
                            l.taxa,
                            l.base,
                            l.valor,
                            imp.tax               tax_nf,
                            to_number(imp.amount) valor_nf 
       --, utilization_code ROBSON
                        from
                            line l,
                            (
                                select
                                    nvl(
                                        regexp_substr(receipt_num, '[^:]+', 1, level),
                                        'NA'
                                    )                                              tax,
                                    regexp_substr(shuttle_item, '[^:]+', 1, level) amount
                                                     --,utilization_code  utilization_code ROBSON
                                from
                                    pline
                                connect by
                                    level <= regexp_count(shuttle_item, ':') + 1
                                order by
                                    2 desc
                            )    imp
                        where
                            l.codigo_imposto like '%'
                                                  || imp.tax
                                                  || '%'
                        union
                        select
                            to_number(p_efd_line_id) --id
                            ,
                            cast(null as varchar2(100)) --GP
                            ,
                            cast(null as varchar2(100)) --CI
                            ,
                            cast(null as varchar2(100)) --CR
                            ,
                            cast(null as varchar2(100)) --TT
                            ,
                            cast(null as number) --T
                            ,
                            cast(null as number) --B
                            ,
                            cast(null as number) --valor
                            ,
                            imp.tax               tax_nf,
                            to_number(imp.amount) valor_nf
                                 --, utilization_code ROBSON
                        from
                            (
                                select
                                    nvl(
                                        regexp_substr(receipt_num, '[^:]+', 1, level),
                                        'NA'
                                    )                                              tax,
                                    regexp_substr(shuttle_item, '[^:]+', 1, level) amount
                                                     --utilization_code ROBSON
                                from
                                    pline
                                connect by
                                    level <= regexp_count(shuttle_item, ':') + 1
                                order by
                                    2 desc
                            ) imp
                        where
                            not exists (
                                select
                                    1
                                from
                                    line l1
                                where
                                    l1.codigo_imposto like '%'
                                                           || imp.tax
                                                           || '%'
                            )
                    ) bs
                where
                    ( nvl(bs.valor, 0) > 0 )
                    or ( nvl(bs.valor_nf, 0) > 0 )
                    and ( ( l_model = '00'
                            and tax_nf not in ( 'PIS', 'COFINS', 'CSRF', 'FCP', 'IPI',
                                                'CSLL' ) )
                          or ( l_model <> '00'
                               and tax_nf not in ( 'CSRF', 'PIS', 'COFINS' ) ) )
                    and tax_nf <> 'ISS'
                order by
                    case
                        when codigo_imposto is not null then
                            1
                        else
                            2
                    end,
                    tax_nf asc
            )
                           --WHERE ((upper(utilization_code) IN ('MATERIAL USO CONSUMO/APLICADO','CTE - TRANSPORTE DE CARGAS','REFEIÇÃO/ALIMENTAÇÃO') and UPPER(Tax_nf) not like '%ICMS%') 
                           --or (upper(utilization_code) not IN ('MATERIAL USO CONSUMO/APLICADO','CTE - TRANSPORTE DE CARGAS','REFEIÇÃO/ALIMENTAÇÃO')))
    ) loop
                  /*print('reg.tax_nf  : '||reg.tax_nf);
                  print('reg.valor   : '||reg.valor);
                  print('reg.valor_nf: '||reg.valor_nf);
                  print('reg.status:   '||reg.status); ROBSON */
                  --
        if reg.status = 'Error' then
                    --
            return 'F'; --return false para impostos que não batem
                    --
        end if;
                  --
    end loop;
                --
    return 'V';
                --
end impl_check_tax_line;
/


-- sqlcl_snapshot {"hash":"45ad9bf48140b378274dee22354e14ac7ad3ffed","type":"FUNCTION","name":"IMPL_CHECK_TAX_LINE","schemaName":"RMAIS","sxml":""}