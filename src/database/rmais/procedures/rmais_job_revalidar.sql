create or replace procedure rmais_job_revalidar is
    nc          number;
    ncount      number := 0;
    dstart_date date;
begin
    select
        count(*)
    into nc
    from
        rmais_ctrl_job b
    where
        b.num_ctrl_job = 1;
    --
    if nc = 0 then
        insert into rmais_ctrl_job ( num_ctrl_job ) values ( 1 );

        commit;
        for x in (
            with tp_headers as (
                select
                    a.efd_header_id
                from
                    rmais_efd_headers_v a,
                    rmais_nf_reval      b
                where
                        nvl(a.document_status_cod, 'I') = 'I'
                    and b.efd_header_id is null
                    and a.efd_header_id = b.efd_header_id (+)
                order by
                    a.issue_date asc,
                    1 desc
            )
            select
                efd_header_id
            from
                tp_headers
            where
                rownum <= 1
        ) loop
            ncount := ncount + 1;
            dstart_date := current_date;
            rmais_process_pkg.main(
                p_header_id => x.efd_header_id,
                p_flag_auto => 'Y',
                p_send_erp  => 'Y'
            );

            insert into rmais_nf_reval values ( x.efd_header_id,
                                                dstart_date,
                                                current_date );

            commit;
        end loop;

        if ncount = 0 then
            delete from rmais_nf_reval;

        end if;
        delete rmais_ctrl_job
        where
            num_ctrl_job = 1;

        commit;
    end if;

end rmais_job_revalidar;
/


-- sqlcl_snapshot {"hash":"58cb3d8d194b90ba3f925cb4a0c3748844c7e7a8","type":"PROCEDURE","name":"RMAIS_JOB_REVALIDAR","schemaName":"RMAIS","sxml":""}