create or replace function return_filename_croped (
    p_filename       varchar2,
    p_extension_flag varchar2 default 'Y'
) return varchar2 is
    l_return varchar2(100);
begin
    select
        case
            when length(p_filename) < 50 then
                p_filename
            else
                substr(p_filename,
                       length(p_filename) - 50)
        end filename
    into l_return
    from
        dual;

    if p_extension_flag = 'N' then
        l_return := substr(l_return,
                           1,
                           instr(l_return, '.', -1) - 1);

    end if;

    return l_return;
exception
    when others then
        return p_filename;
end return_filename_croped;
/


-- sqlcl_snapshot {"hash":"17729c700fff8fc034a4f515a0ec2e520c839973","type":"FUNCTION","name":"RETURN_FILENAME_CROPED","schemaName":"RMAIS","sxml":""}