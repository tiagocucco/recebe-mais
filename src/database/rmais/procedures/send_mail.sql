create or replace procedure send_mail (
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
    lstatus            varchar2(2) := null;
    lpo                varchar2(20);
    lnome              rmais_organizations.nome%type;
    tpfluxorecusa      tb_notas_recusadas%rowtype;
    vintroducao        varchar2(4000) := 'Sua nota chegou até o Recebe Mais.';
begin
    lstatus := '05';
    select
        *
    into l_header
    from
        rmais_efd_headers
    where
        efd_header_id = pr_efd_header_id;    
    --
    select
        max(nome)
    into lnome
    from
        rmais_organizations
    where
        cnpj = l_header.receiver_document_number;
    --
    select
        max(source_doc_number)
    into lpo
    from
        rmais_efd_lines
    where
            efd_header_id = pr_efd_header_id
        and source_doc_number is not null
        and rownum <= 1;
    --
    lstatus := '06';
    l_hash := crypt_hash(pr_efd_header_id
                         || '|' || to_char(current_timestamp, 'DD/MM/YYYY HH24:MI:SS.FF3'));
    --
    lstatus := '07';
    l_url := 'https://pacaembu-test.rm.digital:8443/ords/';
    --
    lstatus := '08';
    l_link_verificar := apex_util.prepare_url(l_url
                                              || 'f?p='
                                              || '100'
                                              || ':64::::64:P64_HASH:'
                                              || l_hash,
                                              p_checksum_type => 'SESSION');
    --
    lstatus := '09';
    l_last_update_user :=
        case
            when nvl(l_header.last_updated_by, 'Sistema') = '-1' then
                'Sistema'
            else
                nvl(l_header.last_updated_by, 'Sistema')
        end;
    --
    lstatus := '00';
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
        begin
            select
                *
            into tpfluxorecusa
            from
                tb_notas_recusadas
            where
                    efd_header_id = pr_efd_header_id
                and usuario is not null
            order by
                data desc
            fetch first 1 row only;

        exception
            when others then
                null;
        end;

        vintroducao := '
            <div>Sua nota foi recusada conforme detalhes abaixo:</div>
            <div>
                Motivo : '
                       || tpfluxorecusa.justificativa
                       || '            
            </div>
            <div>
                Usuário:'
                       || tpfluxorecusa.usuario
                       || '
            </div>
            <div>
                Data   :'
                       || to_char(tpfluxorecusa.data, 'DD/MM/YYYY')
                       || '
            </div>
            ';

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
                <p>Olá '
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
                   || '">'
                   || vintroducao
                   || '</p>
                <p style="'
                   || style_array('cor_azul')
                   || '">Detalhes da nota</p>
                <p>'
                   || '
                    <table style="width:100%;'
                   || style_array('table_th_td')
                   || '">
                        <tr>
                            <td style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">Fornecedor: <span style="'
                   || style_array('negrito')
                   || '">'
                   || l_header.issuer_name
                   || '</span></td>
                            <td colspan="2" style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">Numero da nota#  : <span style="'
                   || style_array('negrito')
                   || '">'
                   || l_header.document_number
                   || '</span></td>
                        </tr>
                        <tr>
                            <td style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">CNPJ/CPF: <span style="'
                   || style_array('negrito')
                   || '">'
                   || l_header.issuer_document_number
                   || '</span></td>
                            <td colspan="2" style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">Emissão: <span style="'
                   || style_array('negrito')
                   || '">'
                   || to_char(l_header.issue_date, 'DD-MON-YYYY')
                   || '</span></td>
                        </tr>
                        <tr>
                            <td style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">Business Unit: <span style="'
                   || style_array('negrito')
                   || '">'
                   || l_header.receiver_name
                   || '</span></td>
                            <td style="'
                   || style_array('padding_5px')
                   || style_array('table_th_td')
                   || 'text-align: left">
                                <div>Valor Total:</div>
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
                   || '">Moeda: '
                   || l_header.currency_code
                   || '</span>
                            </td>
                        </tr>
                    </table>
                </p>
                <p style="'
                   || style_array('cor_azul')
                   || '">Linhas</p>
                <p>
                        <table class="tab_linhas" style="'
                   || style_array('table_th_td')
                   || 'width:100%">
                            <tr>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">Linha</th>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">PO</th>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">Item</th>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">Descrição</th>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">Total</th>
                                <th style="'
                   || style_array('table_th_td')
                   || style_array('linhas_th')
                   || '">Quantidade</th>
                            </tr>'
                   || l_lines
                   || '</table>
                </p>
                
                <p> '
                   || l_header.additional_information
                   || '<br/>
                    <span style="'
                   || style_array('negrito')
                   || '">Data entrada:</span> '
                   || to_char(l_header.creation_date, 'DD/MM/YYYY')
                   || '
                </p>                    
                ';
        --style="background:#CAD2D9;color:black;"
    if pr_title is null then
        l_body_html := l_body_html
                       || '
                <!--
                <p style="'
                       || style_array('justificado')
                       || '">
                    ⚠️<span style="'
                       || style_array('negrito')
                       || style_array('cor_importante')
                       || '">Importante</span>: Alguma Informação caso necessário.
                </p>
                -->
                
                <table class="botao" cellspacing="0" cellpadding="0" style="border: 0px;"> 
                    <tr>
                        <td style="'
                       || style_array('botao_td')
                       || '" align="center" width="120" height="40" bgcolor="#CC0000">
                            <center>
                            <a href="'
                       || replace(l_link_verificar, '//ords', '')
                       || '" style="color: #fff; font-size:12px; font-family:Arial; text-decoration: none; line-height:40px; width:100%; display:inline-block">
                                Rejeitar Nota
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
            --p_cc => l_header.email_approve,--'erickson.mattos@rm.digital',
            --p_bcc => '',

        p_subj      => 'Nota Número: '
                  || l_header.document_number
                  ||
                  case
                      when pr_title is null then
                          ' Integrada'
                      else
                          ' Recusada'
                  end
                  || ' na '
                  || l_header.requisition_number
                  || ' Empresa Pagadora '
                  || lnome,
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
                            status,
                            titulo
                        ) values ( pr_efd_header_id,
                                   pr_mail,
                                   sysdate,
                                   l_header.document_number,
                                   '01',
                                   pr_title );

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
                    status,
                    titulo
                ) values ( pr_efd_header_id,
                           pr_mail,
                           sysdate,
                           l_header.document_number,
                           '02',
                           pr_title );

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
            log_errm,
            titulo
        ) values ( pr_efd_header_id,
                   pr_mail,
                   sysdate,
                   l_header.document_number,
                   '04',
                   'ENVIOU',
                   pr_title );

    exception
        when others then
            null;
    end;

exception
    when others then
        begin
        --00
            l_erro := sqlerrm;
            insert into rmais_log_passagem_por_email (
                efd_header_id,
                email,
                data_tentativa,
                document_number,
                status,
                log_errm,
                titulo
            ) values ( pr_efd_header_id,
                       pr_mail,
                       sysdate,
                       l_header.document_number,
                       lstatus,
                       l_erro,
                       pr_title );

        exception
            when others then
                null;
        end;
end send_mail;
/


-- sqlcl_snapshot {"hash":"7b73f6b932c9daccb1a19e2326d499f81c2fb96d","type":"PROCEDURE","name":"SEND_MAIL","schemaName":"RMAIS","sxml":""}