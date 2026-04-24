create or replace force editionable view rmais_report_nf_erros_vw (
    efd_header_id,
    cfop_from,
    source_document_type,
    access_key_number,
    document_number,
    series,
    model,
    model_orig,
    issue_date,
    total_amount,
    document_status,
    issuer_name,
    issuer_document_number,
    issuer_address,
    receiver_name,
    receiver_document_number,
    message_text,
    like_erro,
    modalidade_erro,
    creation_date
) as
    with -- AZUL PROD
     tp_erros as (
        select
            case level
                when 1  then
                    'Erro de envio ao Oracle'
                when 2  then
                    'Inválidas - Pedidos não localizados'
                when 3  then
                    'Erro de envio ao Oracle'
                when 4  then
                    'Erro de envio ao Oracle'
                when 5  then
                    'Erro de envio ao Oracle'
                when 6  then
                    'Inválidas - Mais de um pedido para escolha'
                when 7  then
                    'Inválidas - Pedido ou recebimento com divergencia de quantidade ou valor'
                when 8  then
                    'Inválidas - Pedido ou recebimento com divergencia de quantidade ou valor'
                when 9  then
                    'Inválidas - Pedido ou recebimento com divergencia de quantidade ou valor'
                when 10 then
                    'Inválidas - Pedido ou recebimento com divergencia de quantidade ou valor'
                when 11 then
                    'Email de fornecedor não localizado'
                when 12 then
                    'Divergência de imposto'
                when 13 then
                    'Inválidas - Pedido ultrapassou a tolerância'
                when 14 then
                    'Avisos'
                when 15 then
                    'Avisos'
                when 16 then
                    'Avisos'
                when 17 then
                    'Avisos'
                when 18 then
                    'Avisos'
                when 19 then
                    'Avisos'
            end modalidade_erro,
            case level
                when 1  then
                    '%(AP-%'
                when 2  then
                    '%PO%Não localizada.%'
                when 3  then
                    'The value of the attribute File Name isn%'
                when 4  then
                    'Error: Entre em contato com o adminitrador do sistema'
                when 5  then
                    '%Nota Fiscal%já foi disponíbilizado para pagamento!% '
                when 6  then
                    '%Mais de uma Ordem de Compra encontrada. Favor selecionar manualmente.%'
                when 7  then
                    '%Ordem de Compra%com divergência de quantidade%'
                when 8  then
                    '%Ordem de Compra %encontrada com divergência de valor%'
                when 9  then
                    '%Não foi possível fazer o split automático do recebimento físico, recebimento com valor divergênte da NF Quant de receb:%'
                when 10 then
                    '%Recebimento com valor divergênte da NF Quant de receb:%'
                when 11 then
                    '%Não foi localizado o email do fornecedor, verificar cadastro no ERP.%'
                when 12 then
                    '%Identificado divergência entre cálculo de imposto, verifique o detalhe da linha.%'
                when 13 then
                    '%Pedido ultrapassou a tolerância permitida.%'
                when 14 then
                    '%Ordem de Compra%utilizando tolerância%'
                when 15 then
                    '%Alterado quantidade e valor unitário seguindo o pedido.%'
                when 16 then
                    '%Encontrado recebimento físico do documento fiscal.%'
                when 17 then
                    '%Os pedidos escolhidos utilizaram %da tolerância de%'
                when 18 then
                    '%Ordem de Compra % sem utilização atrelada, utilização derivada pelo tipo fiscal.%'
                when 19 then
                    '%Documento inválido pela definição do CFOP do documento fiscal'
            end like_erro
        from
            dual
        connect by
            level <= 20
    ), tp_lines as (
        select distinct
            a.efd_header_id,
            nvl(c.cfop_from, '1111')                          cfop_from,
            a.source_document_type,
            a.access_key_number,
            a.document_number,
            a.series,
            decode(a.model, '55', 'NFe', '00', 'NFse',
                   'NF', 'NF', '57', 'Cte', '67',
                   'CTEos', '06', 'Energia', '21', 'Comunicação',
                   '22', 'Telecomunicação', '28', 'Gás', '29',
                   'Água', 'Modelo Não suportado')            as model,
            a.model                                           model_orig,
            a.issue_date,
            to_char(a.total_amount, '999G999G999G999G990D00') total_amount,
            decode(a.document_status, 'N', 'A Receber', 'V', 'Válido',
                   'I', 'Inválido', 'E', 'Erro', 'T',
                   'Enviado ERP', 'C', 'Cancelada', 'M', 'Manual',
                   'X', 'Cancelada Após Integração', 'R', 'Rejeitado', 'RW',
                   'Rejeitado', 'W', 'Z', 'Caixinha', 'Cancelada ERP',
                   'Status Desconhecido')                     document_status,
            initcap(a.issuer_name)                            issuer_name,
            a.issuer_document_number,
            a.issuer_address,
            initcap(b.nome)                                   receiver_name,
            a.receiver_document_number
        from
            rmais_efd_headers   a,
            rmais_organizations b,
            rmais_efd_lines     c
        where
                a.receiver_document_number = b.cnpj
            and a.efd_header_id = c.efd_header_id --AND h.efd_header_id = 654038 --count 329863
    ), tp_lin_valid as (
        select distinct
            a.efd_header_id,
            case
                when not ( b.type || b.message_text like '%Enviado para ERP%' ) then
                    a.line_number
            end line_number,
            b.message_text,
            b.creation_date
        from
            rmais_efd_lines     a,
            rmais_efd_lin_valid b
        where
                a.efd_header_id = b.efd_header_id
            and ( b.efd_line_id is null
                  or a.efd_line_id = b.efd_line_id )
            and b.message_text not in ( 'Setup de De/Para de CFOP não localizado.' )
            and b.message_text not like '%selecionada automaticamente pelo sistema%'
            and b.message_text not like '%Enviado para ERP%'
            and b.message_text not like 'Split de linhas efetuado automaticamento pelo sistema.'
            and b.message_text not like 'Split de linhas efetuado automaticamento pelo sistema seguindo recebimento físico.'
            and b.message_text not like 'Alterado quantidade e valor unitário seguindo o pedido.'
            and b.message_text not like '%Setup de De/Para de CFOP não localizado. Utilization_code:%'
    )
    select distinct
        a.efd_header_id,
        a.cfop_from,
        a.source_document_type,
        a.access_key_number,
        a.document_number,
        a.series,
        a.model,
        a.model_orig,
        a.issue_date,
        a.total_amount,
        a.document_status,
        a.issuer_name,
        a.issuer_document_number,
        a.issuer_address,
        a.receiver_name,
        a.receiver_document_number,
        b.message_text,
        c.like_erro,
        c.modalidade_erro,
        b.creation_date
    from
        tp_lines     a,
        tp_lin_valid b,
        tp_erros     c
    where
            a.efd_header_id = b.efd_header_id
        and a.document_status in ( 'Inválido', 'Erro', 'Válido' )
        and b.message_text like c.like_erro (+)
--and A.efd_header_id = 631


-- sqlcl_snapshot {"hash":"74cba8d490a392ff709b14b07c3818853c885108","type":"VIEW","name":"RMAIS_REPORT_NF_ERROS_VW","schemaName":"RMAIS","sxml":""}