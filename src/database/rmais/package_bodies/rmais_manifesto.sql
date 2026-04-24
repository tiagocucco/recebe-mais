create or replace package body rmais_manifesto as
  --
    procedure print (
        p_msg varchar2
    ) as
    --
    begin
      --
        if g_test is not null then
        --
            dbms_output.put_line(p_msg);
        --      
        end if;
    --
    end print;
  --
    procedure create_manifest (
        p_chave varchar2,
        p_date  in out date,
        p_tipo  varchar2 default '210200'
    ) as
    begin
      --
        p_date := nvl(p_date, sysdate);
      --
        insert into rmais_manifest_event values ( p_chave,
                                                  'N',
                                                  '',
                                                  p_date,
                                                  p_tipo );

        print('Inserindo manifeto');
      --
    end create_manifest;
  --
    procedure process_conclusao (
        p_danfe varchar2 default null,
        p_date  date default null
    ) as
    begin
        print('Processo Conclusão');
        for nf in (
            select distinct
                danfe,
                status,
                efd_header_id
            from
                rmais_manifest_event ev,
                rmais_efd_headers    rh
            where
                status in ( 'N', 'E' )
                and tipo_doc = 210200
                and danfe = nvl(p_danfe, danfe)
                and model = '55'
                and ev.creation_date = nvl(p_date, ev.creation_date)
                and document_status not in ( 'RW', 'R' )
                and ev.danfe = rh.access_key_number
                and ( ( p_date is null
                        and not exists (
                    select
                        1
                    from
                        rmais_manifest_event ev1
                    where
                            ev1.danfe = ev.danfe
                        and status = 'P'
                        and tipo_doc = 210200
                    union
                    select
                        1
                    from
                        rmais_manifest_event ev1
                    where
                            ev1.danfe = ev.danfe
                        and status = 'E'
                        and tipo_doc = 210200
                    group by
                        danfe
                    having
                        count(*) <= 5
                ) )
                      or p_date is not null )--)
        ) loop
            print('Danfe: ' || nf.danfe);
            declare
                l_cnpj   varchar2(15);
                l_return clob;
            begin
          --
                select
                    receiver_document_number
                into l_cnpj
                from
                    rmais_efd_headers
                where
                    access_key_number = nf.danfe;
          --
                manifest_conclusao(nf.danfe, l_cnpj, l_return);
          --
                print('l_return: ' || l_return);
          --
          --
                if nvl(
                    json_value(l_return, '$.data.retorno.msg'),
                    'x'
                ) like 'Evento registrado e vinculado a NF-e%' then
            --
                    print('Chamada de WS: SUCCESS');
            --
                    if nf.status = 'N' then
              --
                        update rmais_manifest_event
                        set
                            status = decode(status, 'N', 'P', status)
                        where
                                danfe = nf.danfe
                            and tipo_doc = '210200';
              --
                    elsif nf.status = 'E' then
              --
                        insert into rmais_manifest_event values ( nf.danfe,
                                                                  'P',
                                                                  l_return,
                                                                  sysdate,
                                                                  210200 );
              --
                    end if;
            --
            --
                    xxrmais_util_v2_pkg.create_event(nf.efd_header_id, 'Manifestação', 'Conclusão de Operação Realizada', 'SISTEMA');
            --
                    begin
                        apex_application.g_print_success_message := 'Documento Manifestado: "Conclusão de Operação"';
                    exception
                        when others then
                            null;
                    end;
                    print('Log inserido: SUCCESS');
                    print('');
            --
                else
            --
                    print('Chamada de WS: ERROR');
            --
            --
                    if nf.status = 'N' then
                        update rmais_manifest_event
                        set
                            status = 'E'
                        where
                                danfe = nf.danfe
                            and tipo_doc = '210200';
              --
                    else
              --
                        insert into rmais_manifest_event values ( nf.danfe,
                                                                  'E',
                                                                  l_return,
                                                                  sysdate,
                                                                  210200 );
              --
                        print('Log inserido: SUCCESS');
                        print('');
              --
                    end if;
            --
                    xxrmais_util_v2_pkg.create_event(nf.efd_header_id,
                                                     'Manifestação',
                                                     'Erro: Não foi possível fazer a manifestação de "Conclusão de Operação Realizada" ERROR: '
                                                     || nvl(
                                     json_value(l_return, '$.data.retorno.msg')
            --nvl(NULL 
                                     ,
                                     'INDEFINIDO'
                                 ),
                                                     'SISTEMA');
            --
                    print('Criado evento');
            --
                    begin
                        apex_error.add_error(
                            p_message          => 'Erro: Não foi possível fazer a manifestação de "Conclusão de Operação Realizada" ERROR: '
                                         || nvl(
                                json_value(l_return, '$.data.retorno.msg'),
                                'INDEFINIDO'
                            ),
                            p_additional_info  => null,
                            p_display_location => apex_error.c_inline_in_notification
                        );
                    exception
                        when others then
                            null;
                            print('Error: ' || sqlerrm);
                    end;
            --
                end if;

            end;

            commit;
        end loop;

    end;
  --
    procedure manifest_conclusao (
        p_danfe varchar2,
        p_cnpj  varchar2,
        p_log   out clob
    ) as
  --
        l_url   varchar2(400) := rmais_process_pkg.get_parameter('URL_MENSAGERIA');
  --
        req     utl_http.req;
  --
        resp    utl_http.resp;
  --
        buffer  varchar2(4000);
  --
        content varchar2(4000) := '{"tipo_evento": "210200","num_seq_evento": "1","justificativa": " ","chave": "'
                                  || p_danfe
                                  || '","cnpj": "'
                                  || p_cnpj
                                  || '"}';
  --
    begin
    --
    --req := utl_http.begin_request( l_url );
        req := utl_http.begin_request(l_url, 'POST', 'HTTP/1.1');
        utl_http.set_header(req,
                            'Authorization',
                            'Basic ' || rmais_process_pkg.get_parameter('AUTHORIZATION_BASIC'));

        utl_http.set_header(req, 'user-agent', 'mozilla/4.0');
        utl_http.set_header(req, 'content-type', 'application/json; charset=iso-8859-1');
        utl_http.set_header(req,
                            'Content-Length',
                            length(content));
    --
        utl_http.write_text(req, content);
        resp := utl_http.get_response(req);
    -- process the response from the HTTP call
        begin
      --
            loop
        --
                utl_http.read_line(resp, buffer);
        --
                p_log :=
                    case
                        when p_log is null then
                            buffer
                        else
                            p_log
                            || chr(10)
                            || buffer
                    end;
        --
        --
                if buffer is not null then
          --
                    print(buffer);
          --
                end if;
        --
            end loop;
        --
        --
            utl_http.end_response(resp);
        --
        --utl_http.destroy_request_context(request_context);
        --
        exception
            when utl_http.end_of_body then
                utl_http.end_response(resp);
            when others then
                utl_http.end_response(resp);
        end;
      --
      --
    exception
        when others then
      --
            print('Erro ao chamar WS: ' || sqlerrm);
      --
      --p_log := 'ERRO';
      --
    end manifest_conclusao;
  --
    procedure manifest_status_ap_v0 (
        l_id number default null
    ) as
    --l_row_e NUMBER := 5;
    begin
        for nf_reg in (
            select
                id,
                body_ws,
                json_value(body_ws, '$.updated_at')            updated_at,
                json_value(body_ws, '$.invoice_id')            invoice_id,
                json_value(body_ws, '$.fiscal_doc_access_key') fiscal_doc_access_key,
                json_value(body_ws, '$.invoice_number')        invoice_number,
                json_value(body_ws, '$.invoice_status')        invoice_status,
                json_value(body_ws, '$.pagador')               pagador,
                json_value(body_ws, '$.pagador_cnpj')          pagador_cnpj,
                json_value(body_ws, '$.fornecedor')            fornecedor,
                json_value(body_ws, '$.fornecedor_cnpj')       fornecedor_cnpj,
                json_value(body_ws, '$.created_at')            created_at,
                json_value(body_ws, '$.valor_nf')              valor_nf,
                json_value(body_ws, '$.valor_pago')            valor_pago,
                to_char(to_date(json_value(body_ws, '$.data_nf'),
                        'YYYY-MM-DD'),
                        'DD/MM/YYYY')                          data_nf,
                json_value(body_ws, '$.data_pgto')             data_pgto,
                json_value(body_ws, '$.data_cancel')           data_cancel,
                json_value(body_ws, '$.data_atualizacao')      data_atualizacao,
                json_value(body_ws, '$.org_id')                org_id,
                json_value(body_ws, '$.vendor_id')             vendor_id,
                json_value(body_ws, '$.vendor_site_id')        vendor_site_id,
                rh.efd_header_id,
                rh.document_status                             status_rm,
                rh.last_update_date,
                rh.last_updated_by,
                rh.model
            from
                rmais_ws_nf_info_ap ws,
                rmais_efd_headers   rh
            where
                    1 = 1--ID = 122rh
                        --AND ROWNUM = 1
                and ws.id = nvl(l_id, ws.id)
                and ws.status in ( 'N' )
                and rh.access_key_number = json_value(body_ws, '$.fiscal_doc_access_key')
                and json_value(body_ws, '$.fiscal_doc_access_key') is not null
                and body_ws is not null
                and 1 = 1--trunc(ws.creation_date) = TRUNC(SYSDATE)
                and exists (
                    select
                        1
                    from
                        rmais_efd_headers
                    where
                        access_key_number = json_value(ws.body_ws, '$.fiscal_doc_access_key')
                                     --AND MODEL = '55'
                )
                         /*AND NOT EXISTS (SELECT 1
                                           FROM rmais_manifest_event event
                                           WHERE event.danfe = json_value(ws.body_ws,'$.fiscal_doc_access_key')
                                             AND status = 'P'
                                             AND tipo_doc = '210200'
                                         UNION ALL 
                                         SELECT 1
                                           FROM rmais_manifest_event event2
                                          WHERE danfe = json_value(ws.body_ws,'$.fiscal_doc_access_key')
                                            AND status = 'E'
                                            AND tipo_doc = '210200'
                                          GROUP BY event2.danfe
                                         HAVING COUNT(*) <= l_row_e
                                         )*/
        ) loop
      --
      
      --
            begin
        --
                print('NF localizado no R+ Chave: '
                      || nf_reg.fiscal_doc_access_key
                      || ' STATUS: '
                      || nf_reg.invoice_status
                      || ' Modelo: ' || nf_reg.model);
        --
                if nf_reg.invoice_status in ( 'VALIDATION', 'CAPTURED' ) then
          --
                    if nf_reg.model = '55' then
            --
                        insert into rmais_manifest_event values ( nf_reg.fiscal_doc_access_key,
                                                                  'N',
                                                                  '',
                                                                  sysdate,
                                                                  '210200' );
            --
                    end if;
          --
                    xxrmais_util_v2_pkg.create_event(nf_reg.efd_header_id, 'NF Aprovada', 'NF aprovada no AP'
                                                                                          ||
                        case
                            when nf_reg.model = '55' then
                                ', liberada para manifestação'
                            else
                                ''
                        end, 'SISTEMA');
          --
                    update rmais_ws_nf_info_ap
                    set
                        status = 'P'
                    where
                        id = nf_reg.id;
          --
                    update rmais_efd_headers
                    set
                        document_status =
                            case
                                when document_status <> 'T' then
                                    'M'
                                else
                                    document_status
                            end
                    where
                        efd_header_id = nf_reg.efd_header_id;
          -- 
                elsif nf_reg.invoice_status = 'CANCELLED' then
          --
                    print('NF cancelada Chave: ' || nf_reg.fiscal_doc_access_key);
          --
                    update rmais_efd_headers
                    set
                        document_status = 'W' --NF INUTILIZADA
                    where
                        efd_header_id = nf_reg.efd_header_id; 
          --
                    xxrmais_util_v2_pkg.create_event(nf_reg.efd_header_id, 'NF Cancelada', 'NF Cancelada no AP'
                                                                                           ||
                        case
                            when nf_reg.model = '55' then
                                ', liberada para rejeição'
                            else
                                ''
                        end, 'SISTEMA');
          --
                    update rmais_ws_nf_info_ap
                    set
                        status = 'P'
                    where
                        id = nf_reg.id;
          --
                end if;
        --
            exception
                when others then
        --
                    declare
                        l_aux clob := sqlerrm;
                    begin
                        update rmais_ws_nf_info_ap
                        set
                            status = 'E',
                            body_ws = body_ws
                                      || ' Error de integração: '
                                      || l_aux
                        where
                            id = nf_reg.id;

                    end;
        --
            end;
        -- 
        end loop;
    --
    --deletando registro que não estão no R+
        for nf_reg in (
            select
                id,
                json_value(body_ws, '$.fiscal_doc_access_key') fiscal_doc_access_key
            from
                rmais_ws_nf_info_ap ws
            where
                    1 = 1--ID = 122rh
                        --AND ROWNUM = 1
                and ws.status in ( 'N' )
                        -- AND json_value(body_ws,'$.fiscal_doc_access_key') IS NOT NULL
                and ws.id = nvl(l_id, ws.id)
                and not exists (
                    select
                        1
                    from
                        rmais_efd_headers
                    where
                        access_key_number = json_value(ws.body_ws, '$.fiscal_doc_access_key')
                )
        ) loop
        --
            print('Tratando Documento não localizado no R+  Chave: ' || nf_reg.fiscal_doc_access_key);
        --
            update rmais_ws_nf_info_ap
            set
                body_ws = body_ws,
                status = 'X' --status de descarte de documento 
            where
                id = nf_reg.id;
        --   
        --deletando documentos descartador após 7 dias
            print('Documentos deletados: ' || sql%rowcount);
        --
        end loop;
      --
        delete rmais_ws_nf_info_ap
        where
                status = 'X'
            and trunc(creation_date) < trunc(sysdate - 7);
      --
    end manifest_status_ap_v0;
   --
    procedure manifest_status_ap (
        l_id number default null
    ) as 
    --l_row_e NUMBER := 5; 
        l_access_key_number   varchar2(100) := null;
        l_body                clob := null;
        l_invoice_status      varchar2(50);
        l_status              varchar2(2);
        l_model_rm            varchar2(10);
        l_efd_header_id       number;
        l_aux                 clob;
        l_dec_document_number number(6, 4);
        l_dec_invoice_number  number(6, 4);
        l_new_document_number rmais_efd_headers.efd_header_id%type;
        l_document_status     rmais_efd_headers.document_status%type;
    begin
        print('Iniciando.'); 
      -- 
        execute immediate 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/YYYY''';
        begin
        --Localizando o body com dados do erp, verificando o status do erp e o status da situação.
            select
                body_ws,
                json_value(body_ws, '$.invoice_status'),
                status
            into
                l_body,
                l_invoice_status,
                l_status
            from
                rmais_ws_nf_info_ap
            where
                id = l_id;
        --Verificação se o body possui conteúdo e se o status é N, 
        --se sim ele captura a chave da nf e inicia o processo de troca de status
            if
                l_body is not null
                and l_status = 'N'
            then
                l_access_key_number := nvl(--json_value(l_body,'$.fiscal_doc_access_key')
                    case
                        when length(json_value(l_body, '$.fiscal_doc_access_key')) = 47 then --validando se chave foi reprocessada
                            substr(
                                json_value(l_body, '$.fiscal_doc_access_key'),
                                4
                            )
                        else
                            json_value(l_body, '$.fiscal_doc_access_key')
                    end,
                    xxrmais_util_v2_pkg.get_access_key_number(
                                    json_value(l_body, '$.pagador_cnpj'),
                                    json_value(l_body, '$.fornecedor_cnpj'),
                                    to_date(json_value(l_body, '$.data_nf'),
                                        'YYYY-MM-DD'),
                                    trunc(regexp_replace(
                                        json_value(l_body, '$.invoice_number'),
                                        '[^0-9.]'
                                    ))
                                               -- regexp_replace(json_value(l_body,'$.invoice_number'),'[^0-9]')
                                ));
            --
                print('Chave: ' || l_access_key_number);
            --                                
            end if;
        --Faz a captura do modelo da nf e o header_id, seu parametro de procura é o acess_key_number,
        --Caso não seja possível encontrar esta NF, ele pula para a exception NO_DATA_FOUND
            select distinct
                efd.model,
                efd.efd_header_id,
                -- Robson 08/04/2023 start
                nls_num_char(regexp_replace(
                    json_value(l_body, '$.invoice_number'),
                    '[^0-9.]'
                ))                                               new_document_number,
                efd.document_number - trunc(efd.document_number) dec_document_number,
                nls_num_char(regexp_replace(
                    json_value(l_body, '$.invoice_number'),
                    '[^0-9.]'
                )) - trunc(nls_num_char(regexp_replace(
                    json_value(l_body, '$.invoice_number'),
                    '[^0-9.]'
                )))                                              dec_invoice_number,
                /*    
                to_number(json_value(l_body,'$.invoice_number'), '99999999999999D9999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''') new_document_number,
                efd.document_number - trunc(efd.document_number) dec_document_number,
                to_number(json_value(l_body,'$.invoice_number'), '99999999999999D9999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''') - 
                    trunc(to_number(json_value(l_body,'$.invoice_number'), '99999999999999D9999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''')) dec_invoice_number
                */
                -- Robson 08/04/2023 end
                efd.document_status
            into
                l_model_rm,
                l_efd_header_id,
                -- Robson 08/04/2023 start
                l_new_document_number,
                l_dec_document_number,
                l_dec_invoice_number,
                -- Robson 08/04/2023 end
                l_document_status
            from
                rmais_efd_headers efd
            where
                l_access_key_number is not null
                and access_key_number = l_access_key_number;
        -- Processo é iniciado ao encontrar a chave no recebe mais.
            print('NF localizado no R+ Chave: '
                  || l_access_key_number
                  || ' STATUS: '
                  || l_invoice_status
                  || ' Modelo: ' || l_model_rm); 
        --Robson 08/04/2023 start
            if l_dec_invoice_number > l_dec_document_number then
                update rmais_efd_headers a
                set
                    a.original_document_number = a.document_number,
                    a.document_number = l_new_document_number
                where
                    a.efd_header_id = l_efd_header_id;

                commit;
            --
                rmais_process_pkg.update_invoice(l_efd_header_id);
            --
            end if;
        --Robson 08/04/2023 end
        --
            if l_invoice_status in ( 'VALIDATION', 'CAPTURED' ) then --nota foi aprovada no oracle.

            -- 
                if l_model_rm = '55' then 
            -- 
                    insert into rmais_manifest_event values ( l_access_key_number,
                                                              'N',
                                                              '',
                                                              sysdate,
                                                              '210200' ); 
            -- 
                end if; 
            -- 
                xxrmais_util_v2_pkg.create_event(l_efd_header_id, 'NF Aprovada', 'NF aprovada no AP'
                                                                                 ||
                    case
                        when l_model_rm = '55' then
                            ', liberada para manifestação'
                        else
                            ''
                    end, 'SISTEMA'); 
            -- 
                update rmais_ws_nf_info_ap
                set
                    status = 'P'
                where
                    id = l_id; --processou
            -- 
                update rmais_efd_headers
                set
                    document_status =
                        case
                            when document_status <> 'T' then
                                'M'
                            else
                                document_status
                        end
                where
                    efd_header_id = l_efd_header_id;

                rmais_process_pkg.set_workflow(l_efd_header_id,
                                               'NF aprovada no AP',
                                               json_value(l_body, '$.atualizado_por'));
          --  
            elsif l_invoice_status in ( 'CANCELLED', 'CANCELED' ) then 
          -- 
                print('NF cancelada Chave: ' || l_access_key_number); 
            -- 
                update rmais_efd_headers  
                   --Robson em 08/04/2023 SET document_status = 'CE' -- NF INUTILIZADA
                set
                    document_status =
                        case
                            when document_status = 'UP' then
                                'CC'
                            else
                                'CE'
                        end --Robson 08/04/2023
                where
                    efd_header_id = l_efd_header_id;  
            -- 
                xxrmais_util_v2_pkg.create_event(l_efd_header_id, 'NF Cancelada', 'NF Cancelada no AP'
                                                                                  ||
                    case
                        when l_model_rm = '55' then
                            ', liberada para rejeição'
                        else
                            ''
                    end, 'SISTEMA'); 
            -- 
                rmais_process_pkg.set_workflow(l_efd_header_id,
                                               'Nota Cancelada ERP',
                                               json_value(l_body, '$.atualizado_por'));
            --
                update rmais_ws_nf_info_ap
                set
                    status = 'P'
                where
                    id = l_id; 
          -- 
        -- Robson 13/07/2023 start
            elsif
                l_invoice_status = 'NEEDS REAPPROVAL'
                and l_document_status = 'CC'
            then
                rmais_process_pkg.update_invoice(l_efd_header_id);
                update rmais_ws_nf_info_ap
                set
                    status = 'P'
                where
                    id = l_id;
        -- Robson 13/07/2023 end
            end if; 
        --
        exception
            when no_data_found then
                print('Tratando Documento não localizado no R+  Chave: ' || l_access_key_number); 
                -- 
                update rmais_ws_nf_info_ap
                set
                    body_ws = body_ws,
                    status = 'X' --status de descarte de documento  
                where
                    id = l_id;

            when others then
            --DECLARE
                l_aux := sqlerrm;
                update rmais_ws_nf_info_ap
                set
                    status = 'E',
                    body_ws = body_ws
                              || ' Error de integração: '
                              || l_aux
                where
                    id = l_id; 
        -- 
        end;
    -- efetua a deleção dos documentos da tabela com os dados vindos da api que não foram processados e estão a mais de 7 dias.
        delete rmais_ws_nf_info_ap
        where
                status = 'X'
            and trunc(creation_date) < trunc(sysdate - 7);

        print('Documentos deletados: ' || sql%rowcount); 
    --
    end manifest_status_ap; 
   --

    procedure manifest_cancel (
        p_danfe         varchar2,
        p_cnpj          varchar2,
        p_reason        varchar2 -- Crystian 25/06/2020
        ,
        p_justif        varchar2 -- Crystian 25/06/2020
        ,
        p_return        out varchar2,
        p_efd_header_id in number,
        p_user          in varchar2
    ) as
  --
        p_log   clob;
  --
        e_error exception;
  --
        l_url   varchar2(400) := rmais_process_pkg.get_parameter('URL_MENSAGERIA');--APPS.xxrmais_recebemais_util.get_parameter('TEXT_VALUE','CONTROL','XXRMAIS_WS_MENSAGERIA');
  --                    
        req     utl_http.req;
  --
        resp    utl_http.resp;
  --
        buffer  varchar2(4000);
  --
        content varchar2(4000) := '{'
                                  || chr(10)
                                  || '"tipo_evento": "210240",'
                                  || chr(10)
                                  || '"num_seq_evento": "2",'
                                  || chr(10)
                                  || '"justificativa": "'
                                  || regexp_replace(
            translate(p_justif, 'áàãâäéèêëíìîïóòõôöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇ', 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'),
            '[^0-9A-Za-z ]+',
            ''
        )
                                  || '",'
                                  || chr(10)
                                  || '"chave": "'
                                  || p_danfe
                                  || '",'
                                  || chr(10)
                                  || '"cnpj": "'
                                  || p_cnpj
                                  || '"'
                                  || chr(10)
                                  || '}';
  --
        l_msg   clob;
  --
    begin
    --
        print('Iniciando chamada');
        print('Content: ' || content);
    --req := utl_http.begin_request( l_url );
        req := utl_http.begin_request(l_url, 'POST', 'HTTP/1.1');
        utl_http.set_header(req,
                            'Authorization',
                            'Basic ' || rmais_process_pkg.get_parameter('AUTHORIZATION_BASIC'));

        utl_http.set_header(req, 'user-agent', 'mozilla/4.0');
        utl_http.set_header(req, 'content-type', 'application/json; charset=iso-8859-1');
        utl_http.set_header(req,
                            'Content-Length',
                            length(content));
    --
        utl_http.write_text(req, content);
        resp := utl_http.get_response(req);
    -- process the response from the HTTP call
        begin
      --
            loop
        --
                utl_http.read_line(resp, buffer);
        --
                p_log :=
                    case
                        when p_log is null then
                            buffer
                        else
                            p_log
                            || chr(10)
                            || buffer
                    end;
        --
                p_return := nvl(p_return, '')
                            || p_log;
        --
                if buffer is not null then
          --
          --
          --
                    l_msg := buffer;
          --
                    print(buffer);
                end if;
        --
            end loop;
        --
        --
            utl_http.end_response(resp);
        --
        --utl_http.destroy_request_context(request_context);
        --
        -- Fazer validação de reposta de jason após teste unitário
        --
         --:= 'Documento cancelado no Sefaz';
        exception
            when utl_http.end_of_body then
                utl_http.end_response(resp);
            when others then
          --
                print('ERROR: ' || sqlerrm);
          --
                utl_http.end_response(resp);
          --
                p_log := p_log
                         || chr(10)
                         || 'Erro Exception UTL_HTTP';
          --
                insert into rmais_manifest_event values ( p_danfe,
                                                          'E',
                                                          p_log,
                                                          sysdate,
                                                          210240 );
          --
        end;
      --
        begin
      --
            print('MENSAGEM DE RETORNO: ' || l_msg);
      --
            if ( ( nvl(
                upper(l_msg),
                'ERRO'
            ) like '%REJEICAO%' ) 
        --OR (nvl(upper(l_msg),'ERRO') LIKE '%REJEICAO%' AND nvl(upper(l_msg),'ERRO') NOT  LIKE '%DUPLICIDADE DE EVENTO%') 
        --OR (nvl(upper(l_msg),'ERRO') LIKE '%REJEICAO%' AND nvl(upper(l_msg),'ERRO') NOT  LIKE '%SCHEMA XML%')
            or nvl(
                upper(l_msg),
                'ERRO'
            ) like '%PARALISADO%'
            or nvl(
                upper(l_msg),
                'ERRO'
            ) like '%ERRO%'
            or l_msg is null ) then
        --
                print('Não foi possível fazer a rejeição');
          --
                insert into rmais_manifest_event values ( p_danfe,
                                                          'E',
                                                          p_log,
                                                          sysdate,
                                                          210240 );
          --
                xxrmais_util_v2_pkg.create_event(p_efd_header_id, 'Rejeição', 'Não foi possível rejeitar NF', p_user);
          --
                commit;
          --
                if l_msg like '%"msg"%'
                   or l_msg is null then
          --
                    if l_msg is not null then
            --
                        p_return := json_value(l_msg, '$.data.retorno.msg');
            --
                    end if;
          --
                    apex_error.add_error(
                        p_message          => nvl(
                            nvl(p_return, l_msg),
                            'ERROR FATAL!'
                        ),
                        p_additional_info  => null,
                        p_display_location => apex_error.c_inline_in_notification
                    );
          --                                                                           
                end if;
        --
            else
        --
                print('Registro r+ atualizados');
        -- 
                reject_nf(p_justif, p_efd_header_id, p_user);
        --
                insert into rmais_manifest_event values ( p_danfe,
                                                          'P',
                                                          p_log,
                                                          sysdate,
                                                          210240 );
        --
            end if;
      --
        exception
            when others then
        --
                print('Erro ao inserindo e atualizando registro: ' || sqlerrm);
        --
        end; 
      --
    exception
        when others then
      --
            print('Erro ao chamar WS: ' || sqlerrm);
      --
            p_return := 'Erro na submisão de cancelamento Erro: ' || sqlerrm;
      --
            p_log := p_log
                     || chr(10)
                     || ' Erro: Geral para WS Cancelamento';
      --
            insert into rmais_manifest_event values ( p_danfe,
                                                      'E',
                                                      p_log,
                                                      sysdate,
                                                      210240 );
      --
            declare
                l_ms clob := sqlerrm;
            begin
        --
                xxrmais_util_v2_pkg.create_event(p_efd_header_id, 'Rejeição', 'Não foi possível rejeitar NF ERROR: ' || l_ms, p_user)
                ;
        --
            end;
      --
    end manifest_cancel;
  --
    procedure reject_nf (
        p_msg           varchar2,
        p_efd_header_id number,
        p_user          varchar2
    ) as
        l_nf rmais_efd_headers%rowtype;
    begin
      --
        select
            *
        into l_nf
        from
            rmais_efd_headers
        where
            efd_header_id = p_efd_header_id; 
      --
        begin
      --
            update rmais_efd_headers
            set
                document_status = decode(document_status, 'W', 'RW', 'R'),
                reject_justification = p_msg
            where
                efd_header_id = l_nf.efd_header_id;
      --
            xxrmais_util_v2_pkg.create_event(l_nf.efd_header_id, 'Rejeição', 'NF Rejeitada', p_user);
      --
        exception
            when others then
                raise_application_error(-20033, 'Não foi possível inserir mensagem de rejeição');
        end;
      --
    end reject_nf;
  --
end rmais_manifesto;
/


-- sqlcl_snapshot {"hash":"25a1fdb63346620c1a591bac3830777880678b29","type":"PACKAGE_BODY","name":"RMAIS_MANIFESTO","schemaName":"RMAIS","sxml":""}