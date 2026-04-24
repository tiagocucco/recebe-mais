create or replace procedure get_anexo_file_poc (
    p_type          in varchar2,
    p_efd_header_id in number
) is

    l_blob_content blob;
    l_clob_content clob;
    l_mime_type    varchar2(50);
    l_filename     varchar2(500);
    l_model        varchar2(10);
    l_url_nfe      varchar2(500) := rmais_process_pkg.get_parameter('URL_PDF_DANFE');
    l_url_cte      varchar2(500) := rmais_process_pkg.get_parameter('URL_PDF_DACTE');
    l_url          varchar2(500) := '';
    l_blob         blob;
    l_body         clob;
    l_data         varchar2(1000) := to_char(sysdate, 'DDMONRRRRHH24MISS');
    l_base64       long := null;
    l_url_pref     varchar2(4000) := null;
    l_clob_len     number;
    l_soma         number := 4000;
begin
    execute immediate 'truncate table RMAIS_LOG_ANEXO_EXCLUIR';
    if ( p_type = 'PDF' ) then
        select
            nvl(blob_file, pdf_file),
            nvl(blob_filename, pdf_filename),
            case
                when upper(nvl(blob_filename, pdf_filename)) like '%.PDF%' then
                    'application/pdf'
                when upper(nvl(blob_filename, pdf_filename)) like '%.JPG%' then
                    'image/jpg'
                when upper(nvl(blob_filename, pdf_filename)) like '%.PNG%' then
                    'image/png'
                when upper(nvl(blob_filename, pdf_filename)) like '%.GIF%' then
                    'image/gif'
                else
                    'image/jpeg'
            end,
            model
        into
            l_blob_content,
            l_filename,
            l_mime_type,
            l_model
        from
            rmais_efd_headers_hdi
        where
            efd_header_id = p_efd_header_id;

        insert into rmais_log_anexo_excluir values ( p_efd_header_id,
                                                     'Anexo',
                                                     'null' );

    end if;

    if ( p_type = 'XML' ) then
     /* SELECT xml_file,
             xml_filename,
             'text/xml',
             model
      INTO   l_blob_content,
             l_filename,
             l_mime_type,
             l_model
      FROM   RMAIS_EFD_HEADERS
      WHERE  efd_header_id = p_efd_header_id;*/
        select
            xxrmais_util_pkg.clob_to_blob(a.source_doc_decr),
            a.filename,
            'text/xml',
            tipo_fiscal
        into
            l_blob_content,
            l_filename,
            l_mime_type,
            l_model
        from
            rmais_ctrl_docs_poc   a,
            rmais_efd_headers_hdi h
        where
                id = h.doc_id
            and h.efd_header_id = p_efd_header_id;

    end if;

    if ( p_type = 'XMLF' ) then
        begin
            select
                decode(b.model,
                       '67',
                       xxrmais_util_v2_pkg.process_cteos_link(a.source_doc_decr),
                       to_clob(a.source_doc_decr)),
                a.eletronic_invoice_key || '.pdf',
                'application/pdf',
                b.model
            into
                l_clob_content,
                l_filename,
                l_mime_type,
                l_model
            from
                rmais_ctrl_docs_poc   a,
                rmais_efd_headers_hdi b
            where
                    a.id = b.doc_id
                and b.efd_header_id = p_efd_header_id;

            l_clob_len := dbms_lob.getlength(l_clob_content);
        exception
            when others then
                raise_application_error(-20002, 'Erro ao selecionar dados tipo XMLF ' || sqlerrm);
        end;

        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'multipart/form-data; boundary=----LuzConPDF' || l_data;
        l_body := to_clob('------LuzConPDF'
                          || l_data
                          || '
Content-Disposition: form-data; name="xml"
'
                          || chr(10)
                          || l_clob_content
                          || chr(10)
                          || '
------LuzConPDF' || l_data);

        if ( l_model = '55' ) then
          --l_url := l_url_nfe;
            select
                text_value
            into l_url
            from
                rmais_source_ctrl
            where
                control = 'URL_PDF_DANFE';

        end if;

        if ( l_model = '57' ) then
            select
                text_value
            into l_url
            from
                rmais_source_ctrl
            where
                control = 'URL_PDF_DACTE';

        end if;
      --
        if ( l_model = '67' ) then
        --
            select
                text_value
            into l_url
            from
                rmais_source_ctrl
            where
                control = 'URL_PDF_DACTEOS';
        --
        end if;
      --
        l_blob_content := apex_web_service.make_rest_request_b(
            p_url              => l_url,
            p_http_method      => 'POST',
            p_body             => l_body,
            p_transfer_timeout => 3600
        );
      --delete from http_blob_test;
      --INSERT INTO http_blob_test (id, url, data) VALUES (http_blob_test_seq.NEXTVAL, (l_clob_content ), l_blob_content);
    end if;

    if ( p_type = 'XMLP' ) then
        l_url_pref := xxrmais_util_v2_pkg.get_link_nfse(p_efd_header_id);
        apex_util.redirect_url(p_url => l_url_pref);
        return;
    end if;
  --l_mime_type := 'text/html';
    sys.htp.init;
    sys.owa_util.mime_header(l_mime_type, false);
    sys.htp.p('Content-Length: ' || dbms_lob.getlength(l_blob_content));
    sys.htp.p('Content-Disposition: filename="'
              || l_filename || '"');
    sys.owa_util.http_header_close;
    sys.wpg_docload.download_file(l_blob_content);
    apex_application.stop_apex_engine;
exception
    when apex_application.e_stop_apex_engine then
        declare
            l_erro clob := sqlerrm;
        begin
            insert into rmais_log_anexo_excluir values ( p_efd_header_id,
                                                         'erro',
                                                         l_erro );

            null;
        end;
    when others then
        raise;
end;
/


-- sqlcl_snapshot {"hash":"c156ed9caed1721501ae047558a5493cec6783f9","type":"PROCEDURE","name":"GET_ANEXO_FILE_POC","schemaName":"RMAIS","sxml":""}