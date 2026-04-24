create or replace procedure get_nf_relac_bol (
    phea in out nocopy rmais_efd_headers%rowtype
) as
    vr      number;
    nid     rmais_efd_headers.efd_header_id%type;
    vstatus rmais_efd_headers.document_status%type;
    nc      number;
begin
    with tp_bol as (
        select
            to_number(
                case
                    when instr(assoc, ':') = 0 then
                        assoc
                    else
                        substr(assoc,
                               1,
                               instr(assoc, ':') - 1)
                end
            )   efd_header_id,
            case
                when instr(assoc, ':') = 0 then
                    1
            end ctrl
        from
            rmais_efd_boletos_v
        where
            efd_header_id = phea.efd_header_id
    )
    select
        max(b.efd_header_id),
        max(b.document_status),
        max(a.ctrl)
    into
        nid,
        vstatus,
        nc
    from
        tp_bol            a,
        rmais_efd_headers b
    where
        a.efd_header_id = b.efd_header_id;

    if nid is null then
        phea.document_status := 'BC'; -- Boleto Aguardando NF chega ao RMAIS
    elsif nc is null then
        phea.document_status := 'BM'; -- Boleto Aguardando Seleção Manual das NFs
    elsif
        vstatus = 'T'
        and xxrmais_util_v2_pkg.get_send_invoice_exception(phea.efd_header_id)
    then
        phea.document_status := 'BA'; -- Bolete Associado

        update_invoice_v2(phea);
        
        -- Chamar procedure para atualizar os anexos da NF no oracle, adicionando o anexo do boleto da NF no oracle
        update rmais_efd_headers
        set
            id_boleto = phea.efd_header_id
        where
            efd_header_id = nid;

    else
        phea.document_status := 'BS'; -- Boleto Aguardando NF subir para o ERP

        update rmais_efd_headers
        set
            id_boleto = phea.efd_header_id
        where
            efd_header_id = nid;
        --commit;
    end if;

end;
/


-- sqlcl_snapshot {"hash":"082926635151be0b40f90335d0a0b0d816eb30af","type":"PROCEDURE","name":"GET_NF_RELAC_BOL","schemaName":"RMAIS","sxml":""}