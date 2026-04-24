create or replace force editionable view rmais_status_doc_ctrl (
    flag_status_docs,
    desc_status_docs_rmais,
    desc_status_docs_cliente
) as
    select
        case level
            when 1  then
                'N'
            when 2  then
                'I'
            when 3  then
                'P'
            when 4  then
                'A'
            when 5  then
                'D'
            when 6  then
                'U'
            when 7  then
                'DI'
            when 8  then
                'EI'
            when 9  then
                'PI'
            when 10 then
                'CD'
            when 11 then
                'PE'
            when 12 then
                'DD'
            when 13 then
                'E'
            when 14 then
                'Q'
        end flag_status_docs,
        case level
            when 1  then
                'Ação Manual'
            when 2  then
                'Parcialmente digitada'
            when 3  then
                'Submetida'
            when 4  then
                'Em Andamento'
            when 5  then
                'Descartada'
            when 6  then
                'Duplicada'
            when 7  then
                'Duplicada Integração'
            when 8  then
                'Descartada Integração'
            when 9  then
                'Processada Integração'
            when 10 then
                'Completamente Digitada'
            when 11 then
                'Pendente Envio'
            when 12 then
                'Descartada'
            when 13 then
                'Erro'
            when 14 then
                'Qualidade'
        end desc_status_docs_rmais,
        case level
            when 1  then
                'Processando'
            when 2  then
                'Processando'
            when 3  then
                'Processada'
            when 4  then
                'Processando'
            when 5  then
                'Descartada'
            when 6  then
                'Duplicada'
            when 7  then
                'Duplicada'
            when 8  then
                'Descartada'
            when 9  then
                'Processada'
            when 10 then
                'Processando'
            when 11 then
                'Pendente Envio'
            when 12 then
                'Descartada'
            when 13 then
                'Descartada'
            when 14 then
                'Processando'
        end desc_status_docs_cliente
    from
        dual
    connect by
        level <= 14;


-- sqlcl_snapshot {"hash":"b34899d0c80f28896c0e7a64ef3d9c506b9db0ae","type":"VIEW","name":"RMAIS_STATUS_DOC_CTRL","schemaName":"RMAIS","sxml":""}