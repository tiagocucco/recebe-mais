create or replace procedure rmais_gen_pdf (
    p_nf_key in varchar2
) is
    l_xml  varchar2(32767);
    l_file utl_file.file_type;
begin
    select
        '<?xml version="1.0" encoding="ISO-8859-1"?><nfeProc><NFe>'
        || substr(tbl.source_doc_decr,
                  instr(tbl.source_doc_decr, '<infNFe'),
                  length(tbl.source_doc_decr)) as nf
    into l_xml
    from
        rmais_ctrl_docs   tbl,
        rmais_efd_headers hdr
    where
            tbl.eletronic_invoice_key = hdr.access_key_number
        and tbl.eletronic_invoice_key = p_nf_key
        and hdr.model not in ( '00', '57' );

    l_file := utl_file.fopen(
        location     => 'RMAIS_PDF',
        filename     => p_nf_key || '.xml',
        open_mode    => 'w',
        max_linesize => 32767
    );

    utl_file.put_line(l_file, l_xml);
    utl_file.fclose(l_file);
    declare
        l_output dbms_output.chararr;
        l_lines  integer := 1000;
    begin
        dbms_output.enable(1000000);
        dbms_java.set_output(1000000);
        rmais_cmd('/bin/sh /opt/oracle/xmlp/APEXReports.sh '
                  || p_nf_key || '');
        dbms_output.get_lines(l_output, l_lines);
        for i in 1..l_lines loop
        -- Do something with the line.
        -- Data in the collection - l_output(i)
            dbms_output.put_line(l_output(i));
        end loop;

    end;

    insert into rmais_temp_bfile values ( bfilename('RMAIS_PDF', p_nf_key || '.pdf') );

    begin
        utl_file.fremove('RMAIS_PDF', p_nf_key || '.pdf');
        utl_file.fremove('RMAIS_PDF', p_nf_key || '.xml');
    end;

exception
    when others then
        utl_file.fclose(l_file);
        raise;
end;
/


-- sqlcl_snapshot {"hash":"bbc34449f093f8b72944238a15cdfb42c628d661","type":"PROCEDURE","name":"RMAIS_GEN_PDF","schemaName":"RMAIS","sxml":""}