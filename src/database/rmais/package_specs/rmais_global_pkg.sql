create or replace package rmais_global_pkg is
  --
  /*=========================================================================+
  |                                                                          |
  | Packate:   rmais_global_pkg                                                   |
  |                                                                          |
  | Description: Esta package é utilizada para controlar informações globais |
  |              do processo de Integração DFE-Receiver X Oracle EBS         |
  |                                                                          |
  |  Criado por Crystian S. Bezerra - 01/08/2016                             |
  |                                                                          |
  |  Alterado por Crystian S. Bezerra - 21/02/2019                           |
  |  #001 Ajuste da package para corrigir problemas de ENCODING no ambiente  |
  |                                                                          |
  |                                                                          |
  +=========================================================================*/
  ---
    c_ctrl varchar2(10) := '$98765$';
    g_clob clob;
    g_blob blob;
  --g_dir_list dir_array  := dir_array();
    g_pad_chr varchar2(1) := '~';
    g_key raw(32767);
  --
  --#001 Inicio
    g_default_type pls_integer;-- := g_des_cbc_pkcs5;
  --
    type t$string is
        table of varchar2(32767);
  --
    g_enable_log char;
  --
    g_charset_id number;
  --
    g_reply t$string := t$string();
  --
    g_convert_crlf boolean := true;
  --
    is_binary boolean := false;
  --
    g_ftp_host varchar2(1000);
    g_ftp_port varchar2(10);
    g_ftp_user varchar2(50);
    g_ftp_pwd varchar2(1000);
    g_ftp_root varchar2(1000);
  --
    g_src clob;
    g_log clob;
    g_serie varchar2(100); --Código que representa a Serie da NF em branco para um determinado cliente.
    g_dir_name varchar2(255); --DIRECTORY NAME do Diretório de processamento
    g_dir_path varchar2(900); --Diretório de processamento
    g_dir_path_temp varchar2(900); --Diretório temporário
    g_dir_path_even varchar2(900); --Diretório de mensageria
    g_dir_path_proc varchar2(900); --Diretório de arquivos processados
    g_dir_path_pend varchar2(900); --Diretório de arquivos com erro
    g_dir_invalid varchar2(900); --Diretório de documentos inválidos ou com erros de leitura
    g_dir_noxml varchar2(900); --Diretório de documentos diferentes de XML
    g_dir_dflt_pend varchar2(900); --Diretório de processamento default
    g_dir_dflt_proc varchar2(900); --Diretório de arquivos processados default
  --
    g_errbuf varchar2(4000);
    g_retcode varchar2(10);
  -------------------------------------------
  -- Tipo de Processo (NFe, CTe, NFSe      --
  -------------------------------------------
    g_tipo varchar2(50);
  --
    g_event_default varchar2(4000);
  -------------------------------------------
  -- Informações dos Diretórios de XML     --
  -------------------------------------------
    g_error_found number := 0;
    g_error_tot number := 0;
  --
    g_teste varchar2(32000);
  --
    procedure print (
        p_msg clob
    );
  --
    procedure info (
        pmsg varchar2
    );
  --
    function get_nls (
        pget varchar2 default 'NLS_CHARACTERSET'
    ) return varchar2;
  --
    function get_charset (
        pchrset varchar2 default null
    ) return number;
  --
    procedure clearglobal;
  --
    procedure init (
        ptipo varchar2
    );
  --
    function getclob return clob;
  --
    function getblob return blob;
  --
    function gerador_cod_confirma return varchar2;
  --
end rmais_global_pkg;
/


-- sqlcl_snapshot {"hash":"f405e23cee8f81cdf312ce0e56c6b82c5571ee84","type":"PACKAGE_SPEC","name":"RMAIS_GLOBAL_PKG","schemaName":"RMAIS","sxml":""}