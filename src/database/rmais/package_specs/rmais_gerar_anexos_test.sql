create or replace package rmais_gerar_anexos_test as
    --
    function base64decode_to_blob (
        p_clob clob
    ) return blob;
    --
    function blob_danf (
        p_efd_header_id number
    ) return blob;
    --
    function clob_prefeitura (
        p_efd_header_id            number,
        p_issuer_address_city_code in rmais_efd_headers_hdi.issuer_address_city_code%type,
        p_origem_chamada           number default 0
    ) return clob;
    --
    procedure get_anexo_file (
        p_type          in varchar2,
        p_efd_header_id in number
    );
    --
end rmais_gerar_anexos_test;
/


-- sqlcl_snapshot {"hash":"93227ce28a907332b281b9b12ce57b582fae5445","type":"PACKAGE_SPEC","name":"RMAIS_GERAR_ANEXOS_TEST","schemaName":"RMAIS","sxml":""}