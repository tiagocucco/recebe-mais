create or replace procedure update_invoice_v2 (
    phea in out nocopy rmais_efd_headers%rowtype
) as
    --l_url_att constant varchar2(1000) := RMAIS_PROCESS_PKG.Get_ws||RMAIS_PROCESS_PKG.Get_parameter('GET_URL_UPDATE_ATTACH');
    l_url_att        constant varchar2(1000) := rmais_process_pkg.get_parameter('GET_URL_UPDATE_ATTACH');
    l_body_att       clob;
    l_response       clob;
    l_transaction_id number;
begin
    rmais_process_pkg.generate_attachments(phea.efd_header_id);
    with tp_efd as (
        select
            b.document_number                       invoicenumber,
            b.bu_code                               businessunit,
            coalesce((
                select distinct
                    party_name
                from
                    json_table(a.issuer_info,
                     '$'
                        columns(
                            nested path '$.DATA[*]'
                                columns(
                                    party_name varchar2(400) path '$.PARTY_NAME'
                                )
                        )
                    )
            ),
                     upper(a.issuer_name))          supplier,
            nvl(
                nvl(a.issuer_info.data.address.vendor_site_code,
                    a.vendor_site_code),
                '0001'
            )                                       suppliersite,
            a.boleto_cod                            codigodebarras,
            return_filename_croped(c.filename)      filename,
            return_filename_croped(c.filename, 'N') title,
            return_filename_croped(c.filename, 'N') description,
            case
                when c.filename is not null then
                    'From Supplier'
            end                                     category,
            c.clob_file                             filecontents
        from
            rmais_efd_headers   a,
            rmais_efd_headers_v b,
            rmais_attachments   c
        where
                a.efd_header_id = b.id_boleto
            and a.efd_header_id = c.efd_header_id
            and a.efd_header_id = phea.efd_header_id
    )
    select
            json_object(
                'InvoiceNumber' value to_char(c.invoicenumber),
                        'BusinessUnit' value c.businessunit,
                        'Supplier' value c.supplier,
                        'SupplierSite' value c.suppliersite,
                --'codigoDeBarras'value C.codigoDeBarras,
                        'FileName' value c.filename,
                        'Title' value c.title,
                        'Description' value c.description,
                        'Category' value c.category,
                        'FileContents' value replace(
                    replace(
                        replace(
                            replace(c.filecontents,
                                    chr(10),
                                    ''),
                            chr(13),
                            ''
                        ),
                        chr(09),
                        ''
                    ),
                    ' ',
                    ''
                )
            returning clob)
        b
    into l_body_att
    from
        tp_efd c;

    if rmais_process_pkg.get_parameter('DEBBUG_LOG') = '1' then
        insert into rmais_upload_log (
            id,
            creation_date,
            log,
            efd_header_id,
            file_name,
            job_name
        ) values ( rmais_upload_log_seq.nextval,
                   sysdate,
                   l_body_att,
                   phea.efd_header_id,
                   'L_BODY',
                   'update_invoice_v2' );
        
        --commit;
    end if;

    rmais_process_pkg.insert_ws_info_v2(
        p_id        => l_transaction_id,
        p_method    => 'DEBBUG_BOLETO',
                                     --P_CLOB     => replace(replace(replace(replace(l_body_att, chr(10),''),chr(13),''), chr(09), '') ,' ',''),
        p_clob      => l_body_att,
        p_header_id => phea.efd_header_id
    );

    if rmais_global_pkg.g_enable_log = 'Y' then
        xxrmais_util_v2_pkg.g_test := 'CLOB';
    end if;
    
    --l_response := rmais_process_pkg.Get_response2(l_url_att,l_body_att,'POST');
    l_response := rmais_process_pkg.get_response_v3(l_url_att, l_body_att, 'POST');
    if rmais_process_pkg.get_parameter('DEBBUG_LOG') = '1' then
        insert into rmais_upload_log (
            id,
            creation_date,
            log,
            efd_header_id,
            file_name,
            job_name
        ) values ( rmais_upload_log_seq.nextval,
                   sysdate,
                   l_response,
                   phea.efd_header_id,
                   'L_RESPONSE',
                   'update_invoice_v2' );
        --
        --COMMIT;
        --
    end if;

    for r in (
        select
            json_value(l_response, '$.AttachedDocumentId') attachment_id
        from
            dual
    ) loop
        if r.attachment_id is not null then
            --
            --print('Boleto enviado com sucesso! Attachment_id: '||r.attachment_id);
            --
            dbms_output.put_line('Boleto enviado com sucesso! Attachment_id: ' || r.attachment_id);
            phea.document_status := 'UP';
            --
            xxrmais_util_v2_pkg.create_event(phea.efd_header_id, 'Submissão ERP (AP)', 'Id: '
                                                                                       || phea.efd_header_id
                                                                                       || ' - Attachment_id: '
                                                                                       || r.attachment_id, 'SISTEMA'); -- Criando Evento
            --
        elsif r.attachment_id is null then
            --
            --print('Erro ao enviar o Boleto.');
            --
            dbms_output.put_line('Erro ao enviar o Boleto.');
            phea.document_status := 'E';

            --
            rmais_process_pkg.log_efd('Erro ao atualizar anexo do documento: ('
                                      || l_response
                                      || ')', '', phea.efd_header_id, 'Erro');
            --
        end if;
        --
        --commit;
        --
    end loop;

end update_invoice_v2;
/


-- sqlcl_snapshot {"hash":"b63469ef4c56b467342af02f126d3ab6326bd13c","type":"PROCEDURE","name":"UPDATE_INVOICE_V2","schemaName":"RMAIS","sxml":""}