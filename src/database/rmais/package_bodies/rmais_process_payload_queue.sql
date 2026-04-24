create or replace package body rmais_process_payload_queue as

  --------------------------------------------------------------------
  -- Função auxiliar: extrai valor de campo do JSON
  --------------------------------------------------------------------
    function get_json_value (
        p_json       in clob,
        p_field_name in varchar2
    ) return varchar2 is
        v_value varchar2(32767);
    begin
        v_value := json_value(p_json, '$.' || p_field_name);
        return v_value;
    exception
        when others then
            return null;
    end get_json_value;

  --------------------------------------------------------------------
  -- Validação de campos obrigatórios
  --------------------------------------------------------------------
    function validate_required_fields (
        p_payload_json in clob
    ) return t_result is

        v_result       t_result;
        v_source       varchar2(500);
        v_organization varchar2(500);
        v_filename     varchar2(500);
        v_mime_type    varchar2(500);
        v_base64       clob;
    begin
        v_source := get_json_value(p_payload_json, 'SOURCE');
        v_organization := get_json_value(p_payload_json, 'ORGANIZATION');
        v_filename := get_json_value(p_payload_json, 'FILENAME');
        v_mime_type := get_json_value(p_payload_json, 'MIME_TYPE');
        v_base64 := json_value(p_payload_json, '$.BASE64');
        if v_source is null
           or v_organization is null
        or v_filename is null
        or v_mime_type is null
        or v_base64 is null then
            v_result.success := false;
            v_result.id := null;
            v_result.status_code := 500;
            v_result.result_msg := '{"RESULT":"Error: Identificado falta de informação em campo obrigatório"}';
            return v_result;
        end if;

        v_result.success := true;
        v_result.id := null;
        v_result.status_code := 200;
        v_result.result_msg := 'Campos obrigatórios validados com sucesso.';
        return v_result;
    exception
        when others then
            v_result.success := false;
            v_result.id := null;
            v_result.status_code := 500;
            v_result.result_msg := '{"RESULT":"Error: Erro ao validar campos obrigatórios - '
                                   || sqlerrm
                                   || '"}';
            return v_result;
    end validate_required_fields;

  --------------------------------------------------------------------
  -- Validação de organização (stub)
  --------------------------------------------------------------------
    function validate_organization (
        p_organization in varchar2
    ) return boolean is
    begin
        if upper(p_organization) = 'HDI' then
            return true;
        else
            return false;
        end if;
    exception
        when others then
            return false;
    end validate_organization;

  --------------------------------------------------------------------
  -- Procedure principal: processa o payload JSON
  -- Agora também chama xxrmais_util_pkg.create_document
  --------------------------------------------------------------------
    procedure process_payload (
        p_payload_json in clob,
        p_created_by   in varchar2 default user,
        o_result       out t_result
    ) is

        v_validation_result t_result;
        v_organization      varchar2(500);
        v_access_key        varchar2(255);
        v_status            varchar2(100);
        v_id                number;
        v_log               clob;

    -- Para chamada da create_document
        l_clob              clob;
        l_body              blob;
        l_doc_id            number;
        l_doc_stat          integer;
        l_doc_forward       varchar2(32767);
        l_dest_offset       integer;
        l_src_offset        integer;
        l_lang_context      integer;
        l_warning           integer;
        v_sqlerrm           varchar2(4000);
    begin
    ------------------------------------------------------------------
    -- 1) Validar campos obrigatórios
    ------------------------------------------------------------------
        v_validation_result := validate_required_fields(p_payload_json);
        if not v_validation_result.success then
            o_result := v_validation_result;
            return;
        end if;

    ------------------------------------------------------------------
    -- 2) Extrair ORGANIZATION e validar
    ------------------------------------------------------------------
        v_organization := get_json_value(p_payload_json, 'ORGANIZATION');
        if not validate_organization(v_organization) then
            o_result.success := false;
            o_result.id := null;
            o_result.status_code := 500;
            o_result.result_msg := '{"RESULT":"Error: Cadastro da Organização não encontrado, entre em contato com a área técnica"}';
            return;
        end if;

    ------------------------------------------------------------------
    -- 3) Extrair CODIGOVERIFICACAO para ACCESS_KEY_NUMBER
    ------------------------------------------------------------------
        v_access_key := get_json_value(p_payload_json, 'CODIGOVERIFICACAO');

    ------------------------------------------------------------------
    -- 4) Definir STATUS inicial
    ------------------------------------------------------------------
        v_status := c_status_recebido;

    ------------------------------------------------------------------
    -- 5) Inserir na fila
    ------------------------------------------------------------------
        begin
            insert into rmais.rmais_payload_queue (
                payload,
                status,
                access_key_number,
                log,
                creation_date,
                created_by,
                update_date,
                updated_by
            ) values ( p_payload_json,
                       v_status,
                       v_access_key,
                       null,
                       sysdate,
                       p_created_by,
                       sysdate,
                       p_created_by ) returning id into v_id;

            commit;

      ----------------------------------------------------------------
      -- 6) Após inserir na fila, buscar PAYLOAD e chamar create_document
      ----------------------------------------------------------------
            begin
        -- Garante NLS numéricos compatíveis com o JSON (ponto decimal)
                execute immediate 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
                execute immediate 'ALTER SESSION SET NLS_TERRITORY = ''AMERICA''';

        -- Busca o PAYLOAD (CLOB) recém inserido
                select
                    payload
                into l_clob
                from
                    rmais.rmais_payload_queue
                where
                    id = v_id;

        -- Inicializa parâmetros da conversão
                l_dest_offset := 1;
                l_src_offset := 1;
                l_lang_context := dbms_lob.default_lang_ctx;
                l_warning := 0;

        -- Converte CLOB -> BLOB
                dbms_lob.createtemporary(l_body, true);
                dbms_lob.converttoblob(
                    dest_lob     => l_body,
                    src_clob     => l_clob,
                    amount       => dbms_lob.lobmaxsize,
                    dest_offset  => l_dest_offset,
                    src_offset   => l_src_offset,
                    blob_csid    => dbms_lob.default_csid,
                    lang_context => l_lang_context,
                    warning      => l_warning
                );

        -- Chama a create_document
                rmais.xxrmais_util_pkg.create_document(
                    p_body    => l_body,
                    p_id      => l_doc_id,
                    p_stat    => l_doc_stat,
                    p_forward => l_doc_forward
                );

        -- Libera BLOB temporário
                dbms_lob.freetemporary(l_body);

        -- Atualiza status da fila conforme retorno da create_document
                if l_doc_forward like 'Error%' then
                    update rmais.rmais_payload_queue
                    set
                        status = 'ERRO',
                        log = l_doc_forward,
                        update_date = sysdate,
                        updated_by = p_created_by
                    where
                        id = v_id;

                else
                    update rmais.rmais_payload_queue
                    set
                        status = 'PROCESSADO',
                        log = l_doc_forward,
                        update_date = sysdate,
                        updated_by = p_created_by
                    where
                        id = v_id;

                end if;

                commit;
            exception
                when others then
                    v_sqlerrm := sqlerrm;

          -- Tenta marcar o registro da fila como ERRO
                    begin
                        update rmais.rmais_payload_queue
                        set
                            status = 'ERRO',
                            log = 'Erro ao processar documento: ' || v_sqlerrm,
                            update_date = sysdate,
                            updated_by = p_created_by
                        where
                            id = v_id;

                        commit;
                    exception
                        when others then
                            null; -- evita mascarar erro original
                    end;

                    if l_body is not null then
                        dbms_lob.freetemporary(l_body);
                    end if;

          -- Propaga para o EXCEPTION externo da procedure
                    raise;
            end;

      ----------------------------------------------------------------
      -- 7) Retorno de sucesso para o chamador
      ----------------------------------------------------------------
            o_result.success := true;
            o_result.id := v_id;
            o_result.status_code := 201;
            o_result.result_msg := '{"ID":'
                                   || v_id
                                   || ',"DOC_ID":'
                                   || nvl(
                to_char(l_doc_id),
                'null'
            )
                                   || ',"RESULT":"'
                                   || nvl(l_doc_forward, 'Documento Criado')
                                   || '"}';

        exception
            when others then
                rollback;
                v_sqlerrm := sqlerrm;
                o_result.success := false;
                o_result.id := null;
                o_result.status_code := 500;
                o_result.result_msg := '{"RESULT":"Error: Erro ao inserir na fila - '
                                       || v_sqlerrm
                                       || '"}';
        end;

    exception
        when others then
            rollback;
            v_sqlerrm := sqlerrm;
            o_result.success := false;
            o_result.id := null;
            o_result.status_code := 500;
            o_result.result_msg := '{"RESULT":"Error: Erro inesperado - '
                                   || v_sqlerrm
                                   || '"}';
    end process_payload;

end rmais_process_payload_queue;
/


-- sqlcl_snapshot {"hash":"7ac96e60b60a4acca183e5908d90a0870b149cf1","type":"PACKAGE_BODY","name":"RMAIS_PROCESS_PAYLOAD_QUEUE","schemaName":"RMAIS","sxml":""}