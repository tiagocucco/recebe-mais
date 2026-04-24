create or replace function loc_assoc (
    pchave_busca  number,
    ptotal_amount rmais_efd_headers.total_amount%type
) return varchar2 as

    type t_nf is
        table of rmais_efd_headers%rowtype;
    ta_nf t_nf;
    nt    number;
    vc    varchar2(4000);
begin
    select
        count(*)
    into nt
    from
        rmais_efd_headers
    where
            ora_hash(issuer_document_number
                     || '.' || receiver_document_number) = pchave_busca
        and model != 'BO'; --and efd_header_id != 524453;
    if nt = 0 then
        return null;
    else
        with tp_nf as (
            select
                *
            from
                rmais_efd_headers
            where
                    ora_hash(issuer_document_number
                             || '.' || receiver_document_number) = pchave_busca
                and model != 'BO' --and efd_header_id != 524453
        )
        select
            *
        bulk collect
        into ta_nf
        from
            tp_nf;

        for x in ta_nf.first..ta_nf.last loop
            nt := ta_nf(x).total_amount;
            vc := ta_nf(x).efd_header_id;
            for y in ta_nf.first..ta_nf.last loop
                if x != y then
                    if nt >= ptotal_amount then
                        exit;
                    end if;
                    nt := nt + ta_nf(y).total_amount;
                    vc := vc
                          || ':'
                          || ta_nf(y).efd_header_id;
                    if nt = ptotal_amount then
                        exit;
                    end if;
                end if;
            end loop;

            if nt = ptotal_amount then
                exit;
            else
                null;--vC := '';
            end if;
        end loop;

        return vc;
    end if;

end loc_assoc;
/


-- sqlcl_snapshot {"hash":"107d74366d0a50c722d5ca6e9bbe084f209b27d7","type":"FUNCTION","name":"LOC_ASSOC","schemaName":"RMAIS","sxml":""}