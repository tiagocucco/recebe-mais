create or replace procedure display_raw (
    rdata raw
) is
    pos    pls_integer;
    length pls_integer;
begin
    pos := 1;
    length := utl_raw.length(rdata);
    while pos <= length loop
        if pos + 20 > length + 1 then
            dbms_output.put_line(utl_raw.substr(rdata, pos, length - pos + 1));
        else
            dbms_output.put_line(utl_raw.substr(rdata, pos, 20));
        end if;

        pos := pos + 20;
    end loop;

end display_raw;
/


-- sqlcl_snapshot {"hash":"aa289387b8a8cd9cb9b79d685db39c69d45272ac","type":"PROCEDURE","name":"DISPLAY_RAW","schemaName":"RMAIS","sxml":""}