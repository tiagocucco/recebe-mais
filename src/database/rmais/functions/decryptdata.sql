create or replace function decryptdata (
    param in varchar2
) return varchar2 as
    language java name 'CryptData.getDecrypted(java.lang.String) return String';
/


-- sqlcl_snapshot {"hash":"03b72431828d7dfa62edcc688cfcbeea4ca5c581","type":"FUNCTION","name":"DECRYPTDATA","schemaName":"RMAIS","sxml":""}