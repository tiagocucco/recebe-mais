create or replace force editionable view rmais_status_docs (
    flag_status_docs,
    desc_status_docs
) as
    select
        case level
            when 1  then
                'N'
            when 2  then
                'V'
            when 3  then
                'I'
            when 4  then
                'E'
            when 5  then
                'T'
            when 6  then
                'C'
            when 7  then
                'M'
            when 8  then
                'X'
            when 9  then
                'R'
            when 10 then
                'RW'
            when 11 then
                'W'
            when 12 then
                'AC'
            when 13 then
                'UP'
            when 14 then
                'RA'
            when 15 then
                'CE'
            when 16 then
                'EE'
            when 17 then
                'FA'
            when 18 then
                'CC'
            when 19 then
                'AU'
            when 20 then
                'AP'
            when 21 then
                'AI'
            when 22 then
                'Y'
            when 23 then
                'AQ'
        end flag_status_docs,
        case level
            when 1  then
                'A Receber'
            when 2  then
                'Válido'
            when 3  then
                'Inválido'
            when 4  then
                'Erro'
            when 5  then
                'Enviado ERP'
            when 6  then
                'Cancelada'
            when 7  then
                'Manual'
            when 8  then
                'Cancelada Após Integração'
            when 9  then
                'Rejeitado'
            when 10 then
                'Rejeitado'
            when 11 then
                'Cancelada ERP'
            when 12 then
                'Aguardando criar NF no ERP'
            when 13 then
                'Atualizada no ERP'
            when 14 then
                'Erro ao transmitir anexo'
            when 15 then
                'NF Cancelada (ERP)'
            when 16 then
                'Erro ao cancelar NF no ERP'
            when 17 then
                'Aguardando Anexo'
            when 18 then
                'NF Cancelada (ERP)'
            when 19 then
                'Aguardando Update Devolução'
            when 20 then
                'Aguardando Nota Pai da Devolução'
            when 21 then
                'Anexo Devolução Incluído'
            when 22 then
                'Integrada ERP Manual'
            when 23 then
                'Aguardando Qualidade'
        end desc_status_docs
    from
        dual
    connect by
        level <= 23;


-- sqlcl_snapshot {"hash":"289a19245b695f6ee7e335f581e84a2cbf84b284","type":"VIEW","name":"RMAIS_STATUS_DOCS","schemaName":"RMAIS","sxml":""}