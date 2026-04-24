create or replace function fun_compact_un_blob (
    pblob_compact blob
) return blob as
    bcompress blob;
begin
    bcompress := to_blob('1');
    utl_compress.lz_uncompress(
        src => pblob_compact,
        dst => bcompress
    );
    return bcompress;
end fun_compact_un_blob;
/


-- sqlcl_snapshot {"hash":"e99f6214f8810f760481babbdbdee2e2282e353d","type":"FUNCTION","name":"FUN_COMPACT_UN_BLOB","schemaName":"RMAIS","sxml":""}