create or replace function base64decode_to_blob_poc (
    p_clob clob
) return blob is

    l_blob   blob;
    l_raw    raw(32767);
    l_amt    number := 7700;
    l_offset number := 1;
   -- l_temp    VARCHAR2(32767);
    l_temp   clob;
begin
    begin
        dbms_lob.createtemporary(l_blob, false, dbms_lob.call);
        loop
            dbms_lob.read(p_clob, l_amt, l_offset, l_temp);
            l_offset := l_offset + l_amt;
            l_raw := utl_encode.base64_decode(utl_raw.cast_to_raw(l_temp));
            dbms_lob.append(l_blob,
                            to_blob(l_raw));
        end loop;

    exception
        when no_data_found then
            null;
    end;
    --print(utl_raw.cast_to_varchar2(l_blob));
    return l_blob;
end;
/


-- sqlcl_snapshot {"hash":"17e32d4eafc9530fc4b1022c4f0b788d74114feb","type":"FUNCTION","name":"BASE64DECODE_TO_BLOB_POC","schemaName":"RMAIS","sxml":""}