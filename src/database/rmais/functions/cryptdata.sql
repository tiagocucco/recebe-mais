create or replace function cryptdata (
    param in varchar2
) return varchar2 as
    language java name 'CryptData.getEncrypted(java.lang.String) return String';
/


-- sqlcl_snapshot {"hash":"1cc9354a9d29e3337d966409973a2043e61631a4","type":"FUNCTION","name":"CRYPTDATA","schemaName":"RMAIS","sxml":""}