create or replace procedure put_line (
    string_in in varchar2,
    pad_in    in integer default 0
) is
begin
    dbms_output.put_line(lpad(' ', pad_in * 3) || string_in);
end;
/


-- sqlcl_snapshot {"hash":"b56ec17271406347f5ea92245c3eefb838d1b829","type":"PROCEDURE","name":"PUT_LINE","schemaName":"RMAIS","sxml":""}