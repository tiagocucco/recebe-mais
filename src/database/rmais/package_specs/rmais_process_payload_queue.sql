create or replace package rmais_process_payload_queue as

  -- Tipo de retorno padrão
    type t_result is record (
            success     boolean,
            id          number,
            status_code number,        -- 201, 500, etc.
            result_msg  varchar2(4000)
    );

  -- Constantes de STATUS
    c_status_recebido constant varchar2(30) := 'RECEBIDO';
    c_status_erro_validacao constant varchar2(30) := 'ERRO_VALIDACAO';
    c_status_erro_organizacao constant varchar2(30) := 'ERRO_ORGANIZACAO';
    c_status_processando constant varchar2(30) := 'PROCESSANDO';
    c_status_processado constant varchar2(30) := 'PROCESSADO';
    c_status_erro constant varchar2(30) := 'ERRO';

  -- Procedure principal: recebe o JSON e processa
    procedure process_payload (
        p_payload_json in clob,
        p_created_by   in varchar2 default user,
        o_result       out t_result
    );

  -- Validação de campos obrigatórios
    function validate_required_fields (
        p_payload_json in clob
    ) return t_result;

  -- Validação de organização (stub, você implementa a lógica real depois)
    function validate_organization (
        p_organization in varchar2
    ) return boolean;

  -- Extrai campo do JSON
    function get_json_value (
        p_json       in clob,
        p_field_name in varchar2
    ) return varchar2;

end rmais_process_payload_queue;
/


-- sqlcl_snapshot {"hash":"b5bc154a14b94b04ce7e6af4884f400cfdeca450","type":"PACKAGE_SPEC","name":"RMAIS_PROCESS_PAYLOAD_QUEUE","schemaName":"RMAIS","sxml":""}