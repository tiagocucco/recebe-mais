create or replace function base64decode_v2 (
    p_clob clob
) return blob
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/base64decode.sql
-- Author       : Tim Hall
-- Description  : Decodes a Base64 CLOB into a BLOB
-- Last Modified: 09/11/2011
-- -----------------------------------------------------------------------------------
 is

    l_blob   blob;
    l_raw    raw(32767);
    l_amt    number := 7700;
    l_offset number := 1;
    l_temp   varchar2(32767);
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

    return l_blob;
end;
/


-- sqlcl_snapshot {"hash":"36afb12fd270f822701b0ac4f6ed6e8778d48f83","type":"FUNCTION","name":"BASE64DECODE_V2","schemaName":"RMAIS","sxml":""}