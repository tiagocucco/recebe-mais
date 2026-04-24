create or replace function base64decode_to_blob_v2 (
    p_clob in clob
) return blob is

    l_blob   blob;
    l_offset integer := 1;
    l_temp   varchar2(32000); -- Aumentado o tamanho do buffer temporário
    l_raw    raw(32767); -- Aumentado o tamanho do buffer RAW para lidar com maiores conversões
    l_amt    integer;
begin
    dbms_lob.createtemporary(l_blob, false, dbms_lob.call);
    loop
        -- Leia um chunk do CLOB
        l_amt := least(dbms_lob.getlength(p_clob) - l_offset + 1,
                       32000); -- Ajuste para garantir que não leia além do final do CLOB
        exit when l_amt <= 0;
        dbms_lob.read(p_clob, l_amt, l_offset, l_temp);
        l_offset := l_offset + l_amt;
        -- Decodifique o chunk base64 e anexe ao BLOB
        l_raw := utl_encode.base64_decode(utl_raw.cast_to_raw(l_temp));
        dbms_lob.append(l_blob, l_raw);
    end loop;

    return l_blob;
end;
/


-- sqlcl_snapshot {"hash":"9e665e609bc94aaecc508ca316d4bec26b323ad8","type":"FUNCTION","name":"BASE64DECODE_TO_BLOB_V2","schemaName":"RMAIS","sxml":""}