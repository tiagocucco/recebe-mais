create or replace package body rmais_gerar_anexos as
    --
    function base64decode_to_blob (
        p_clob clob
    ) return blob is

        l_blob   blob;
        l_raw    raw(32767);
        l_amt    number := 7700;
        l_offset number := 1;
        l_temp   clob;
    begin
        begin
            dbms_lob.createtemporary(l_blob, false, dbms_lob.call);
            loop
                dbms_lob.read(p_clob, l_amt, l_offset, l_temp);
                l_offset := l_offset + l_amt;
                l_raw := utl_encode.base64_decode(utl_raw.cast_to_raw(l_temp));
                dbms_lob.append(l_blob,
                                to_blob(l_raw));
            end loop;

        exception
            when no_data_found then
                null;
        end;

        return l_blob;
    end;
    --
    function blob_danf (
        p_efd_header_id number
    ) return blob is

        vmimetype      varchar2(200);
        l_clob_content clob := empty_clob();
        l_filename     varchar2(100);
        l_model        varchar2(10);
        l_data         varchar2(1000) := to_char(sysdate, 'DDMONRRRRHH24MISS');
        l_body         clob := empty_clob();
        l_url          varchar2(100);
        l_clob_len     number;
        l_mime_type    varchar2(4000);
    begin
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
                rmais_ctrl_docs   a,
                rmais_efd_headers b
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

        if ( l_model in ( '55', '57', '67' ) ) then
            select
                text_value
            into l_url
            from
                rmais_source_ctrl
            where
                control = decode(l_model, '55', 'URL_PDF_DANFE', '57', 'URL_PDF_DACTE',
                                 'URL_PDF_DACTEOS');

        end if;
        --
        return apex_web_service.make_rest_request_b(
            p_url              => l_url,
            p_http_method      => 'POST',
            p_body             => l_body,
            p_transfer_timeout => 3600
        );

    end;
    --
    function clob_prefeitura (
        p_efd_header_id            number,
        p_issuer_address_city_code in rmais_efd_headers.issuer_address_city_code%type,
        p_origem_chamada           number default 0
    ) return clob is

        l_clob           clob;
        l_transaction_id number;
        l_reponse        clob;
        l_link           varchar2(1000) := xxrmais_util_v2_pkg.get_link_nfse(p_efd_header_id);
        l_body           clob;
        l_url            varchar2(300) := rmais_process_pkg.get_parameter('URL_GET_PDF'); --parametrizar endereço
        --Variáveis para teste para evitar chamadas desnecessárias.
    begin
        begin
            select
                transaction_id
            into l_transaction_id
            from
                rmais_anexos_prefeitura
            where
                    efd_header_id = p_efd_header_id
                and transaction_method = 'REPORT_NFSE';

            select
                clob_info
            into l_clob
            from
                rmais_ws_info
            where
                    transaction_id = l_transaction_id
                and clob_info is not null;

        exception
            when others then
                --chamada WS para gerar report   
                l_transaction_id := null;
                rmais_process_pkg.insert_ws_info(l_transaction_id, 'REPORT_NFSE', l_clob);
                --
                begin
                    --
                    if p_origem_chamada = 0 then
                        delete from rmais_anexos_prefeitura
                        where
                            efd_header_id = p_efd_header_id;

                        insert into rmais_anexos_prefeitura values ( p_efd_header_id,
                                                                     l_transaction_id,
                                                                     'REPORT_NFSE' );

                    end if;
                    --
                    l_body :=
                        json_object(
                            'transaction_id' value l_transaction_id,
                            'method' value p_issuer_address_city_code,
                            'url' value l_link
                        );
                    --
                    l_reponse := rmais_process_pkg.get_response_v3(l_url, l_body, 'POST');
                    --
                    if nvl(
                        json_value(l_reponse, '$.status'),
                        'ERROR'
                    ) = 'success' then
                        begin
                            --
                            select
                                clob_info
                            into l_clob
                            from
                                rmais_ws_info
                            where
                                transaction_id = l_transaction_id;                    
                            --
                        end;
                        ---
                    end if;
                    --
                end;

        end;
        --
        return l_clob;
        --return BASE64DECODE_TO_BLOB(l_clob);
    end;  
    --
    function clob_prefeitura_prod (
        p_link in varchar2
    ) return clob is

        l_clob           clob;
        l_transaction_id number;
        l_reponse        clob;
        --l_link VARCHAR2(1000) := xxrmais_util_v2_pkg.get_link_nfse(p_efd_header_id);
        l_body           clob;
        l_url            varchar2(300) := rmais_process_pkg.get_parameter('URL_GET_PDF'); --parametrizar endereço
        --Variáveis para teste para evitar chamadas desnecessárias.
    begin
        htp.p(l_url);
        begin
            l_transaction_id := null;
            rmais_process_pkg.insert_ws_info(l_transaction_id, 'REPORT_NFSE', l_clob);
            htp.p(l_transaction_id);
            begin
                --
                l_body :=
                    json_object(
                        'transaction_id' value l_transaction_id,
                        'method' value '3550308',
                        'url' value p_link
                    );
                --
                l_reponse := rmais_process_pkg.get_response_v3(l_url, l_body, 'POST');
                --
                if nvl(
                    json_value(l_reponse, '$.status'),
                    'ERROR'
                ) = 'success' then
                    begin
                        --
                        select
                            clob_info
                        into l_clob
                        from
                            rmais_ws_info
                        where
                            transaction_id = l_transaction_id;                    
                        --
                    end;
                    ---
                end if;
                --
            end;

        end;
        --
        return l_clob;
        --return BASE64DECODE_TO_BLOB(l_clob);
    end;  
    --
    procedure get_anexo_file (
        p_type          in varchar2,
        p_efd_header_id in number,
        p_numero_anexo  in number default 1
    ) is

        l_blob_content blob;
        l_clob_content clob;
        l_mime_type    varchar2(150);
        l_filename     varchar2(500);
        l_model        varchar2(10);
        l_url_nfe      varchar2(500) := rmais_process_pkg.get_parameter('URL_PDF_DANFE');
        --                                  
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
        --
        if ( p_type = 'PDF' ) then
            select
                pdf_file,
                pdf_filename,
                'application/pdf',
                model
            into
                l_blob_content,
                l_filename,
                l_mime_type,
                l_model
            from
                rmais_efd_headers
            where
                efd_header_id = p_efd_header_id;
        --
        elsif ( p_type = 'PDFP' ) then
            select
                fun_compact_un_blob(blob_file),
                filename,
                mime_type--'application/pdf'
            into
                l_blob_content,
                l_filename,
                l_mime_type
            from
                rmais_anexos_complementares
            where
                    efd_header_id = p_efd_header_id
                and numero_anexo = p_numero_anexo;        
        --
        elsif ( p_type = 'XLS' ) then
            select
                xls_file,
                xls_filename,
                'application/xls',
                model
            into
                l_blob_content,
                l_filename,
                l_mime_type,
                l_model
            from
                rmais_efd_headers
            where
                efd_header_id = p_efd_header_id;

        elsif ( p_type = 'XML' ) then
            select
                xxrmais_util_v2_pkg.clob_to_blob(a.source_doc_decr),
                a.filename,
                'text/xml',
                tipo_fiscal
            into
                l_blob_content,
                l_filename,
                l_mime_type,
                l_model
            from
                rmais_ctrl_docs   a,
                rmais_efd_headers h
            where
                    id = h.doc_id
                and h.efd_header_id = p_efd_header_id;

        elsif ( p_type = 'XMLF' ) then
            l_blob_content := rmais_gerar_anexos.blob_danf(p_efd_header_id);
            l_mime_type := 'application/pdf';
            /*
            BEGIN
                SELECT 
                    decode (b.model,'67',RMAIS_UTIL_PKG.process_cteos_link(a.source_doc_decr),TO_CLOB(a.source_doc_decr)),
                    a.eletronic_invoice_key || '.pdf',
                    'application/pdf',
                    b.model
                INTO 
                    l_clob_content,
                    l_filename,
                    l_mime_type,
                    l_model
                FROM 
                    rmais_ctrl_docs a
                    , rmais_efd_headers b
                WHERE 
                    a.id = b.doc_id
                    AND b.efd_header_id = p_efd_header_id;
                l_clob_len := dbms_lob.getlength(l_clob_content);
                EXCEPTION
                WHEN OTHERS THEN
                    raise_application_error(-20002, 'Erro ao selecionar dados tipo XMLF ' || SQLERRM);
            END;
            apex_web_service.g_request_headers(1).name := 'Content-Type';
            apex_web_service.g_request_headers(1).value := 'multipart/form-data; boundary=----LuzConPDF' || l_data;
      l_body := TO_CLOB('------LuzConPDF' || l_data || '
Content-Disposition: form-data; name="xml"
' || l_clob_content || '
------LuzConPDF' || l_data);
            if ( l_model = '55' )
            then
                  --l_url := l_url_nfe;
                  SELECT TEXT_VALUE
                    INTO l_url
                    FROM RMAIS_SOURCE_CTRL
                   WHERE CONTROL = 'URL_PDF_DANFE';
            end if;
            if ( l_model = '57' )
                then
                  SELECT TEXT_VALUE
                    INTO l_url
                    FROM RMAIS_SOURCE_CTRL
                   WHERE CONTROL = 'URL_PDF_DACTE';
            end if;
            --
            IF (l_model = '67') THEN
                --
                SELECT TEXT_VALUE
                    INTO l_url
                    FROM RMAIS_SOURCE_CTRL
                   WHERE CONTROL = 'URL_PDF_DACTEOS';
                --
            END IF;
            --
            l_blob_content := apex_web_service.make_rest_request_b(
                p_url => l_url,
                p_http_method => 'POST',
                p_body => l_body,
                p_transfer_timeout => 3600
            );
            */
        elsif ( p_type = 'XMLP' ) then
            l_url_pref := xxrmais_util_pkg.get_link_nfse(p_efd_header_id);
            apex_util.redirect_url(p_url => l_url_pref);
            return;
        end if;
        --l_mime_type := 'text/html';
        if p_type <> 'XLS' then
            sys.htp.init;
            sys.owa_util.mime_header(l_mime_type, false);
            sys.htp.p('Content-Length: ' || dbms_lob.getlength(l_blob_content));
            sys.htp.p('Content-Disposition: filename="'
                      || l_filename || '"');
            sys.owa_util.http_header_close;
            sys.wpg_docload.download_file(l_blob_content);
            apex_application.stop_apex_engine;
        else
            sys.htp.init;
            sys.owa_util.mime_header(l_mime_type, false);
            sys.htp.p('Content-Length: ' || dbms_lob.getlength(l_blob_content));
            sys.htp.p('Content-Disposition: filename="'
                      || l_filename || '"');
            sys.wpg_docload.download_file(l_blob_content);
            apex_application.stop_apex_engine;
        end if;

    exception
        when apex_application.e_stop_apex_engine then
            null;
        when others then
            raise;
    end;
    --
end rmais_gerar_anexos;
/


-- sqlcl_snapshot {"hash":"fcdf05334d20cb4929b3efe6d552d76b069302b9","type":"PACKAGE_BODY","name":"RMAIS_GERAR_ANEXOS","schemaName":"RMAIS","sxml":""}