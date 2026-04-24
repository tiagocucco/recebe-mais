create or replace procedure send_mail_v2 (
    pr_efd_header_id in number,
    pr_mail          in varchar2 default null,
    pr_title         in varchar2 default null
) is

    l_url              varchar2(200);
    l_link_verificar   varchar2(500);
    l_body_html        varchar2(32000);
    l_mail_id          number;
    l_mail_blob        blob;
    l_file_name        varchar2(4000);
    l_mimetype         varchar2(400);
    l_header           rmais_efd_headers%rowtype;
    l_lines            clob := null;
    l_last_update_user varchar2(500);
    l_hash             clob;
    l_mail_clob        clob;
    l_erro             clob;
    lrequester         varchar2(300) := substr(pr_mail,
                                       0,
                                       instr(pr_mail, ',') - 1);
    lcreator           varchar2(300) := substr(pr_mail,
                                     instr(pr_mail, ',') + 1);
    type style_type is
        table of varchar2(400) index by varchar2(30);
    style_array        style_type;
    titulo             varchar2(600);
    lstatus            varchar2(2) := '04';
begin
    begin
        select
            *
        into l_header
        from
            rmais_efd_headers
        where
            efd_header_id = pr_efd_header_id;

    exception
        when others then
            begin
                l_erro := sqlerrm;
                insert into rmais_log_passagem_por_email (
                    efd_header_id,
                    email,
                    data_tentativa,
                    document_number,
                    status,
                    log_errm
                ) values ( pr_efd_header_id,
                           pr_mail,
                           sysdate,
                           l_header.document_number,
                           '05',
                           l_erro );

            exception
                when others then
                    null;
            end;
    end;
    --
    begin
        l_hash := crypt_hash(pr_efd_header_id
                             || '|' || to_char(current_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));

    exception
        when others then
            begin
                l_erro := sqlerrm;
                insert into rmais_log_passagem_por_email (
                    efd_header_id,
                    email,
                    data_tentativa,
                    document_number,
                    status,
                    log_errm
                ) values ( pr_efd_header_id,
                           pr_mail,
                           sysdate,
                           l_header.document_number,
                           '06',
                           l_erro );

            exception
                when others then
                    null;
            end;
    end;

    begin
        l_url := 'https://pacaembu-test.rm.digital:8443/ords/';
    exception
        when others then
            begin
                l_erro := sqlerrm;
                insert into rmais_log_passagem_por_email (
                    efd_header_id,
                    email,
                    data_tentativa,
                    document_number,
                    status,
                    log_errm
                ) values ( pr_efd_header_id,
                           pr_mail,
                           sysdate,
                           l_header.document_number,
                           '07',
                           l_erro );

            exception
                when others then
                    null;
            end;
    end;

    begin
        l_link_verificar := apex_util.prepare_url(l_url
                                                  || 'f?p='
                                                  || '100'
                                                  || ':47::::47:P47_EFD_HEADER_ID:'
                                                  || l_hash,
                                                  p_checksum_type => 'SESSION');
    exception
        when others then
            begin
                l_erro := sqlerrm;
                insert into rmais_log_passagem_por_email (
                    efd_header_id,
                    email,
                    data_tentativa,
                    document_number,
                    status,
                    log_errm
                ) values ( pr_efd_header_id,
                           pr_mail,
                           sysdate,
                           l_header.document_number,
                           '08',
                           l_erro );

            exception
                when others then
                    null;
            end;
    end;

    begin
        l_last_update_user :=
            case
                when nvl(l_header.last_updated_by, 'Sistema') = '-1' then
                    'Sistema'
                else
                    nvl(l_header.last_updated_by, 'Sistema')
            end;
    exception
        when others then
            begin
                l_erro := sqlerrm;
                insert into rmais_log_passagem_por_email (
                    efd_header_id,
                    email,
                    data_tentativa,
                    document_number,
                    status,
                    log_errm
                ) values ( pr_efd_header_id,
                           pr_mail,
                           sysdate,
                           l_header.document_number,
                           '09',
                           l_erro );

            exception
                when others then
                    null;
            end;
    end;

    begin
        --carragando os styles
        style_array('corpo') := 'padding-left:4em;color:black';
        style_array('cor_azul') := 'color:blue;font-size:14px';
        style_array('table_th_td') := 'border: 1px solid gray;border-collapse: collapse;';
        style_array('cor_importante') := 'color:#9B1323;text-decoration: underline;';
        style_array('cor_bizzara') := 'color:#81848A;';
        style_array('negrito') := 'font-weight: 900;';
        style_array('td_tr_th') := 'text-align: center;';
        style_array('body') := 'font-family:Arial;';
        style_array('linhas_th') := 'color:white;background :black;padding:5px;';
        style_array('padding_5px') := 'padding: 5px;';
        style_array('justificado') := 'text-align: justify;';
        style_array('botao_td') := '-webkit-border-radius: 15px;-moz-border-radius: 15px;border-radius: 15px;color: #ffffff;display: block;"'
        ;
        style_array('image-container') := 'width: 100%; overflow: hidden; position: relative;';
        style_array('image-container-img') := 'width: 100%; height: auto;position: relative; left: 50%;transform: translateX(-50%); display: block; '
        ;
        style_array('titulo') := 'font-size:20px;font-weight: bold;text-align: center;color:blue;'; 
        --style_array('') :=''; 
    end;

    for rw in (
        select
            *
        from
            rmais_efd_lines
        where
            efd_header_id = pr_efd_header_id
    ) loop
        l_lines := l_lines
                   || '<tr>'
                   || '<td style="'
                   || style_array('td_tr_th')
                   || style_array('table_th_td')
                   || style_array('padding_5px')
                   || '">'
                   || rw.line_number
                   || '</td>'
                   || '<td style="'
                   || style_array('td_tr_th')
                   || style_array('table_th_td')
                   || style_array('padding_5px')
                   || '">'
                   || rw.source_doc_number
                   || '</td>'
                   || '<td style="'
                   || style_array('td_tr_th')
                   || style_array('table_th_td')
                   || style_array('padding_5px')
                   || '">'
                   || rw.item_code_efd
                   || '</td>'
                   || '<td style="'
                   || style_array('td_tr_th')
                   || style_array('table_th_td')
                   || style_array('padding_5px')
                   || '">'
                   || rw.item_description
                   || '</td>'
                   || '<td style="'
                   || style_array('td_tr_th')
                   || style_array('table_th_td')
                   || style_array('padding_5px')
                   || '">'
                   || rw.line_amount
                   || '</td>'
                   || '<td style="'
                   || style_array('td_tr_th')
                   || style_array('table_th_td')
                   || style_array('padding_5px')
                   || '">'
                   || rw.line_quantity
                   || '</td>'
                   || '</tr>';
    end loop;  
    --    
    if pr_title is not null then
        titulo := '<div style="'
                  || style_array('titulo')
                  || '">
                    '
                  || pr_title
                  ||--' - <span class="cor_vermelha"> Homologação</span>
                   '</div>';
    else
        titulo := '<div>
                    <img style="'
                  || style_array('image-container-img')
                  || '" src="https://pacaembu-test.rm.digital:8443/ords/r/rmais/100/files/static/v101/pacaembu.png" alt="Logo">
                </div>';
    end if;
    --
    l_body_html := '
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="widtd=device-widtd, initial-scale=1.0">
            <meta http-equiv="X-UA-Compatible" content="ie=edge">
        </head>
        <body>
            
            <div style="'
                   || style_array('corpo')
                   || '">
                '
                   || titulo
                   || '
                <p>Hello Wilder '
                   || initcap(substr(lrequester,
                                     0,
                                     least(
                                      instr(lrequester, '.'),
                                      instr(lrequester, '@')
                                  ) - 1))
                   || ' & '
                   || initcap(substr(lcreator,
                                     0,
                                     least(
                                      instr(lcreator, '.'),
                                      instr(lcreator, '@')
                                  ) - 1))
                   || '</p>
                <p style="'
                   || style_array('justificado')
                   || '">Your invoice attached has been integrated on Oracle and will follow for tax validation and
                    payment. Please take a look at the details and make sure everything is alright.</p>
                <p style="'
                   || style_array('cor_azul')
                   || '">Invoice Details</p>
                <p>'
                   || '
                    <table style="width:100%;'
                   || style_array('table_th_td')
                   || '">
                        <tr>
                            <td style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">Supplier Name: <span style="'
                   || style_array('negrito')
                   || '">'
                   || l_header.issuer_name
                   || '</span></td>
                            <td colspan="2" style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">Invoice#  : <span style="'
                   || style_array('negrito')
                   || '">'
                   || l_header.document_number
                   || '</span></td>
                        </tr>
                        <tr>
                            <td style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">Supplier Site: <span style="'
                   || style_array('negrito')
                   || '">'
                   || l_header.issuer_document_number
                   || '</span></td>
                            <td colspan="2" style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">Issue date: <span style="'
                   || style_array('negrito')
                   || '">'
                   || to_char(l_header.issue_date, 'DD-MON-YYYY')
                   || '</span></td>
                        </tr>
                        <tr>
                            <td style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">Ship to Business Unit: <span style="'
                   || style_array('negrito')
                   || '">'
                   || l_header.receiver_name
                   || '</span></td>
                            <td style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">
                                <div>Total amount:</div>
                                <div> <span style="'
                   || style_array('negrito')
                   || '">'
                   || l_header.total_amount
                   || '</span></div>                                    
                            </td>
                            <td style"'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || '">
                                <span style="'
                   || style_array('negrito')
                   || '">Curr.: '
                   || l_header.currency_code
                   || '</span>
                            </td>
                        </tr>
                        <tr>
                            <td style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">Status       : <span style="'
                   || style_array('negrito')
                   || '">Sent to ERP - Following to payment process</span></td>
                            <td colspan="2" style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">User         : <span style="'
                   || style_array('negrito')
                   || '">'
                   ||
        case
            when l_last_update_user not like '%@wildlife%' then
                'Sistema'
            else
                l_last_update_user
        end
                   || '</span></td>
                        </tr>
                    </table>
                </p>
                <p style="'
                   || style_array('cor_azul')
                   || '">Line Description</p>
                <p>
                        <table class="tab_linhas" style="'
                   || style_array('table_th_td')
                   || 'width:100%">
                            <tr>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">Line</th>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">PO</th>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">ERP Code</th>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">Description ERP</th>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">Amount</th>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">Quantity</th>
                            </tr>'
                   || l_lines
                   || '</table>
                </p>
                
                <p> '
                   || l_header.additional_information
                   || '<br/>
                    <span style="'
                   || style_array('negrito')
                   || '">Integration date:</span> '
                   || to_char(l_header.issue_date, 'DD-MON-YYYY')
                   || '
                </p>                    
                ';
        --style="background:#CAD2D9;color:black;"
    if pr_title is null then
        l_body_html := l_body_html
                       || '
                <p style="'
                       || style_array('justificado')
                       || '">
                    ⚠️<span style="'
                       || style_array('negrito')
                       || style_array('cor_importante')
                       || '">Important</span>: If this service or material has not been provided or completed and this invoice
                    should not be paid, click the Reject button to request a payment block.<span style="'
                       || style_array('negrito')
                       || '"> You will have 48 hours to
                    reject this invoice. Otherwise, the payment will be processed according to the payment terms defined in the purchase order.</span>
                </p>
                <p>If you need any further assistance, please contact the Order Experience team via <a href="https://wildlifestudios.atlassian.net/servicedesk/customer/portal/8">Jira</a></p>                    
                <table class="botao" cellspacing="0" cellpadding="0" style="border: 0px;"> 
                    <tr>
                        <td style="'
                       || style_array('botao_td')
                       || '" align="center" width="120" height="40" bgcolor="#CC0000">
                            <center>
                            <a href="'
                       || replace(l_link_verificar, '//ords', '')
                       || '" style="color: #fff; font-size:12px; font-family:Arial; text-decoration: none; line-height:40px; width:100%; display:inline-block">
                                Reject Invoice
                            </a>
                            </center>
                        </td>
                    </tr> 
                </table>';
    end if;

    l_body_html := l_body_html || '</div></body></html>';
    l_mail_id := apex_mail.send(
        p_from      => 'naoresponda@rm.digital',
        p_to        => pr_mail,
        p_cc        => l_header.email_approve,--'erickson.mattos@rm.digital',
            --p_bcc => '',

        p_subj      => 'Nota Número: '
                  || l_header.document_number
                  ||
                  case
                      when pr_title is null then
                          ' Integrada'
                      else
                          ' Rejeitada'
                  end,
        p_body      => 'Email de integração de nota.',
        p_body_html => l_body_html
    );

    begin
        select
            clob_file,
            blob_file,
            filename
        into
            l_mail_clob,
            l_mail_blob,
            l_file_name
        from
            rmais_attachments
        where
            efd_header_id = pr_efd_header_id;                        
        --select PDF_FILE,PDF_FILENAME INTO l_mail_blob,l_file_name FROM rmais_efd_headers where efd_header_id = pr_efd_header_id and PDF_FILE is not null;
    exception
        when others then
            begin
                rmais_process_pkg.generate_attachments(pr_efd_header_id);
                select
                    clob_file,
                    blob_file,
                    filename
                into
                    l_mail_clob,
                    l_mail_blob,
                    l_file_name
                from
                    rmais_attachments
                where
                    efd_header_id = pr_efd_header_id;

            exception
                when others then
                    begin
                        insert into rmais_log_passagem_por_email (
                            efd_header_id,
                            email,
                            data_tentativa,
                            document_number,
                            status
                        ) values ( pr_efd_header_id,
                                   pr_mail,
                                   sysdate,
                                   l_header.document_number,
                                   '01' );

                    exception
                        when others then
                            null;
                    end;
            end;
    end;

    if l_mail_blob is null then
        l_mail_blob := xxrmais_util_v2_pkg.base64decodeclobtoblob(l_mail_clob);
    end if;
    begin
        apex_mail.add_attachment(
            p_mail_id    => l_mail_id,
            p_attachment => l_mail_blob,
            p_filename   => l_file_name,
            p_mime_type  => 'application/pdf'
        );
    exception
        when others then
            begin
                insert into rmais_log_passagem_por_email (
                    efd_header_id,
                    email,
                    data_tentativa,
                    document_number,
                    status
                ) values ( pr_efd_header_id,
                           pr_mail,
                           sysdate,
                           l_header.document_number,
                           '02' );

            exception
                when others then
                    null;
            end;
    end;

    apex_mail.push_queue();
    begin
        insert into rmais_log_passagem_por_email (
            efd_header_id,
            email,
            data_tentativa,
            document_number,
            status,
            log_errm
        ) values ( pr_efd_header_id,
                   pr_mail,
                   sysdate,
                   l_header.document_number,
                   '04',
                   'ENVIOU' );

    exception
        when others then
            null;
    end;

exception
    when others then
        begin
            l_erro := sqlerrm;
            insert into rmais_log_passagem_por_email (
                efd_header_id,
                email,
                data_tentativa,
                document_number,
                status,
                log_errm
            ) values ( pr_efd_header_id,
                       pr_mail,
                       sysdate,
                       l_header.document_number,
                       '00',
                       l_erro );

        exception
            when others then
                null;
        end;
end send_mail_v2;
/


-- sqlcl_snapshot {"hash":"b6b85b5113fa8db8829f1d6d6067835178652756","type":"PROCEDURE","name":"SEND_MAIL_V2","schemaName":"RMAIS","sxml":""}