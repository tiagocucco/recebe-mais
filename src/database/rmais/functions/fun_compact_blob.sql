create or replace function fun_compact_blob (
    pblob_orig    blob,
    pnivel_compac number default 9
) return blob as
    bcompress blob;
begin
    bcompress := to_blob('1');
    utl_compress.lz_compress(
        src     => pblob_orig,
        dst     => bcompress,
        quality => pnivel_compac
    );

    return bcompress;
end fun_compact_blob;
/


-- sqlcl_snapshot {"hash":"a8c42b4dec4deb9dbd2cbfdbfa7cb0272f25f9fb","type":"FUNCTION","name":"FUN_COMPACT_BLOB","schemaName":"RMAIS","sxml":""}