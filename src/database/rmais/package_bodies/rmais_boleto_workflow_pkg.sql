create or replace package body rmais_boleto_workflow_pkg as
  --
    procedure print (
        p_msg varchar2
    ) as
    --
    begin
      --
        if g_test is not null then
        --
            dbms_output.put_line(p_msg);
        --
        end if;
    --
    end print;
  --
    function get_invoice (
        p_receiver_document_number varchar2,
        p_issuer_document_number   varchar2,
        p_issue_date               date,
        p_total_amount             number,
        p_document_number          rmais_efd_headers.document_number%type
    ) return number as
        l_ret number;
   --
    begin
     --
        execute immediate 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/YYYY''';
     --
        select
            efd_header_id
        into l_ret
        from
            rmais_efd_headers rm
        where
                rm.document_number = p_document_number
            and rm.total_amount = p_total_amount
            and substr(rm.receiver_document_number, 1, 8) = substr(p_receiver_document_number, 1, 8)
            and rm.issuer_document_number = p_issuer_document_number
            and trunc(issue_date) = trunc(to_date(p_issue_date, 'DD/MM/YYYY'));
     --
        return l_ret;
     --
    exception
        when others then
     --
            return null;
     --
    end get_invoice;   
   --                  
    procedure create_event_boleto (
        p_body    in blob,
        p_stat    out integer,
        p_forward out varchar2
    ) as
    --                            
        l_reg  rmais_boleto_workflow%rowtype;
        l_body clob := xxrmais_util_pkg.blob_to_clob(p_body);                           
    --
    begin
      --
        execute immediate 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/YYYY''';
      --
        select
            *
        into
            l_reg.bank_collection_id,
            l_reg.invoice_id,
            l_reg.document_number,
            l_reg.file_control,
            l_reg.invoice_num,
            l_reg.amount,
            l_reg.tomador_cnpj,
            l_reg.fornecedor_cnpj,
            l_reg.invoice_date,
            l_reg.source,
            l_reg.status_lookup_code,
            l_reg.status_lookup_desc
        from
            json_table ( l_body, '$'
                columns (
                    bank_collection_id number path '$.BANK_COLLECTION_ID',
                    invoice_id number path '$.INVOICE_ID',
                    document_number number path '$.DOCUMENT_NUMBER',
                    file_control varchar2 ( 100 ) path '$.FILE_CONTROL',
                    invoice_num varchar2 ( 100 ) path '$.INVOICE_NUM',
                    amount number path '$.AMOUNT',
                    tomador_cnpj varchar2 ( 15 ) path '$.TOMADOR_CNPJ',
                    fornecedor_cnpj varchar2 ( 15 ) path '$.FORNECEDOR_CNPJ',
                    invoice_date date path '$.INVOICE_DATE',
                    source varchar2 ( 60 ) path '$.SOURCE',
                    status_lookup_code varchar2 ( 60 ) path '$.STATUS_LOOKUP_CODE',
                    status_lookup_desc varchar2 ( 300 ) path '$.STATUS_LOOKUP_DESC'
                )
            );
      --
        l_reg.created_by := v('APP_USER');
        l_reg.creation_date := sysdate;
        l_reg.efd_header_id := get_invoice(
            p_receiver_document_number => l_reg.tomador_cnpj,
            p_issuer_document_number   => l_reg.fornecedor_cnpj,
            p_issue_date               => l_reg.invoice_date,
            p_total_amount             => l_reg.amount,
            p_document_number          => l_reg.invoice_num
        );
      --                                       
        if l_reg.efd_header_id is not null then
        --
            insert into rmais_boleto_workflow values l_reg;
        --
            update rmais_efd_headers
            set
                flag_valid_boleto = 'Y'
            where
                efd_header_id = l_reg.efd_header_id;
        --
            p_stat := nvl(p_stat, g_stat_created);
            p_forward := 'Documento Criado';
        --
        else
       --
       --victor 20/03/2023
       --p_stat := g_stat_inter_server_error;
            p_stat := nvl(p_stat, g_stat_created);
            p_forward := 'Documento não localizado para associação '
                         || ' -  TOMADOR_CNPJ: '
                         || l_reg.tomador_cnpj
                         || '  FORNECEDOR_CNPJ: '
                         || l_reg.fornecedor_cnpj
                         || '  INVOICE_DATE: '
                         || l_reg.invoice_date
                         || '  AMOUNT: '
                         || l_reg.amount
                         || '  INVOICE_NUM: '
                         || l_reg.invoice_num;
       --
            insert into rmais_boleto_workflow_errors (
                id,
                source,
                msg,
                created_by,
                creation_date
            ) values ( rmais_boleto_workflow_errors_seq.nextval,
                       p_body,
                       p_stat
                       || ' - '
                       || p_forward,
                       v('APP_USER'),
                       sysdate );
       --
        end if;
      --
    exception
        when others then
      -- 
            p_stat := g_stat_inter_server_error;
            p_forward := 'Erro Indefinido ERROR: ' || sqlerrm;
      --
            insert into rmais_boleto_workflow_errors (
                id,
                source,
                msg,
                created_by,
                creation_date
            ) values ( rmais_boleto_workflow_errors_seq.nextval,
                       p_body,
                       p_stat
                       || ' - '
                       || p_forward,
                       v('APP_USER'),
                       sysdate );
    --
    end create_event_boleto;
  --
end rmais_boleto_workflow_pkg;
/


-- sqlcl_snapshot {"hash":"1018a5b1c90509dbda5f0149e9e958f78bb8d0a1","type":"PACKAGE_BODY","name":"RMAIS_BOLETO_WORKFLOW_PKG","schemaName":"RMAIS","sxml":""}