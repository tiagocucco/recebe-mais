create or replace function crypt_hash (
    ptexto in varchar2
) return varchar2 is

    v_key raw(32) := utl_raw.cast_to_raw('o6C71E7JNatpqc4L');  -- Chave de 16 bytes
    v_iv  raw(16) := utl_raw.cast_to_raw('o6$<iYqO0dd+&q5L'); -- Vetor de inicialização
begin
    return dbms_crypto.encrypt(
        src => utl_i18n.string_to_raw(ptexto, 'AL32UTF8'),
        typ => dbms_crypto.encrypt_aes + dbms_crypto.chain_cbc + dbms_crypto.pad_pkcs5,
        key => v_key,
        iv  => v_iv
    );
end;
/


-- sqlcl_snapshot {"hash":"f9abf16e295b6156a27dde5fdf772643316b03a9","type":"FUNCTION","name":"CRYPT_HASH","schemaName":"RMAIS","sxml":""}