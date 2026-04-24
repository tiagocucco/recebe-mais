create or replace package rmais_gerar_anexos as
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
        p_issuer_address_city_code in rmais_efd_headers.issuer_address_city_code%type,
        p_origem_chamada           number default 0
    ) return clob;
    --
    procedure get_anexo_file (
        p_type          in varchar2,
        p_efd_header_id in number,
        p_numero_anexo  in number default 1
    );
    --
    function clob_prefeitura_prod (
        p_link in varchar2
    ) return clob;
    --
end rmais_gerar_anexos;
/


-- sqlcl_snapshot {"hash":"f9316d4719f3d3758853cac43d9a35a4744304c5","type":"PACKAGE_SPEC","name":"RMAIS_GERAR_ANEXOS","schemaName":"RMAIS","sxml":""}