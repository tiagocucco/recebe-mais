create or replace procedure display_blob (
    bdata blob
) is
    pos    pls_integer;
    length pls_integer;
begin
    length := dbms_lob.getlength(bdata);
    pos := 1;
    while pos <= length loop
        display_raw(dbms_lob.substr(bdata, 2000, pos));
        pos := pos + 2000;
    end loop;

end display_blob;
/


-- sqlcl_snapshot {"hash":"47f87b9bf02651dad7d8e8a5d57b13f3bd980730","type":"PROCEDURE","name":"DISPLAY_BLOB","schemaName":"RMAIS","sxml":""}