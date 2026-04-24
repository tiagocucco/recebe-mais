create or replace function decrypt_hash (
    ptexto in varchar2
) return varchar2 is

    v_key raw(32) := utl_raw.cast_to_raw('o6C71E7JNatpqc4L');  -- Chave de 16 bytes
    v_iv  raw(16) := utl_raw.cast_to_raw('o6$<iYqO0dd+&q5L'); -- Vetor de inicialização
begin
    return utl_i18n.raw_to_char(
        dbms_crypto.decrypt(
            src => ptexto,
            typ => dbms_crypto.encrypt_aes + dbms_crypto.chain_cbc + dbms_crypto.pad_pkcs5,
            key => v_key,
            iv  => v_iv
        ),
        'AL32UTF8'
    );
end;
/


-- sqlcl_snapshot {"hash":"1a195199fcc60c6d6488a1b94c29b0ac95d2289d","type":"FUNCTION","name":"DECRYPT_HASH","schemaName":"RMAIS","sxml":""}