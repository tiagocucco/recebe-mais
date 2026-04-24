create or replace function xml_processs (
    l_clob in clob
) return varchar2 is
    l_numero varchar2(44);
begin
    select
        danfe
    into l_numero
    from
        xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/nfe' ),
        '/nfeProc'
                passing xmltype(l_clob)
            columns
                danfe varchar2(200) path '/nfeProc/NFe/infNFe/ide/NFref/refNFe/text()'----/nfeProc/protNFe/infProt/chNFe/text()
                ,
                serie varchar2(150) path '/nfeProc/NFe/infNFe/ide/serie/text()',
                num_nf varchar2(150) path '/nfeProc/NFe/infNFe/ide/nNF/text()',
                cnpj_for varchar2(200) path '/nfeProc/NFe/infNFe/emit/CNPJ/text()',
                cpf_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/CPF/text()'
        );--nfeProc/NFe/infNFe/ide/NFref/refNFe
    return l_numero;
end;
/


-- sqlcl_snapshot {"hash":"06a28aacad972d78b2235d4a427256125939abe8","type":"FUNCTION","name":"XML_PROCESSS","schemaName":"RMAIS","sxml":""}