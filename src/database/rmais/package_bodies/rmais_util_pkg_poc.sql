create or replace package body rmais_util_pkg_poc as --CLL_F369_efd_send_ri_pkg
  --
    procedure print (
        p_msg    varchar2,
        p_status number default null
    ) as
    --
        l_status varchar2(20);
    --
    begin
      --
        if nvl(p_status, 3) = 1 then
        --
            l_status := 'ERROR: ';
        --
        elsif nvl(p_status, 3) = 2 then
        --
            l_status := 'WARNING: ';
        --
        end if;
      --
        if g_test is not null then
        --
            dbms_output.put_line(l_status || p_msg);
        --
        end if;
      --
        if g_log is null then
        --
            g_log := l_status || p_msg;
        --
        else
        --
            g_log := g_log
                     || chr(10)
                     || l_status
                     || p_msg;
        --
        end if;
      --
    exception
        when others then
            print('Error PRINT ' || sqlerrm);
    end print;
  --
    procedure print_clob_to_output (
        p_clob in clob
    ) is
        l_offset int := 1;
    begin
        dbms_output.put_line('Print CLOB');
        loop
            exit when l_offset > dbms_lob.getlength(p_clob);
            if nvl(g_test, 'Y') = 'CLOB' then
                dbms_output.put_line(dbms_lob.substr(p_clob, 255, l_offset));
            end if;

            l_offset := l_offset + 255;
        end loop;

    end print_clob_to_output;
  --
  
  --
    procedure back_list (
        p_status in out varchar2,
        p_chave  in varchar2
    ) as
        l_return varchar2(1);
    begin
        select
            'C'
        into l_return
        from
            rmais_black_list_cancel
        where
            access_key_number = p_chave;

        p_status := l_return;
    exception
        when others then
            p_status := 'N';
    end back_list;
  --
    function check_tomador_cte (
        p_cnpj_toma varchar2
    ) return boolean as
        l_aux number;
    begin
        select
            1
        into l_aux
        from
            rmais_suppliers         rs,
            rmais_organizations_hdi ro
        where
                ro.cliente_id = rs.id
            and trunc(nvl(rs.data_final, sysdate + 1)) >= trunc(sysdate)
            and cnpj = p_cnpj_toma;

        return true;
    exception
        when others then
            return true;
    end;  
  --
    function check_nf_exists (
        p_key number
    ) return boolean as --retornar falso para inserir
        l_return boolean;
        l_aux    number;
    begin
      --
        select
            1
        into l_aux
        from
            rmais_efd_headers_hdi
        where
            access_key_number = p_key;
      --
        return true;
      --
    exception
        when others then
      --
            return false;
      --
    end check_nf_exists;
  --
    function get_cod_serv_expecific (
        p_ibge_cidade number,
        p_serv_pref   varchar2,
        p_nome_cidade varchar2 default null
    ) return varchar2 as
        l_return varchar2(40);
  --l_cod_cidade_aux NUMBER;
    begin
    --
        select
            serv_num_univ
        into l_return
        from
            rmais_efd_serv_cod
        where
                cod_cidade = p_ibge_cidade
            and serv_num_pref = p_serv_pref;

        return l_return;
    exception
        when others then
            return p_serv_pref;
    end;
  --
    function clob_to_blob (
        p_data in clob
    ) return blob
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/clob_to_blob.sql
-- Author       : Tim Hall
-- Description  : Converts a CLOB to a BLOB.
-- Last Modified: 26/12/2016
-- -----------------------------------------------------------------------------------
     as

        l_blob         blob;
        l_dest_offset  pls_integer := 1;
        l_src_offset   pls_integer := 1;
        l_lang_context pls_integer := dbms_lob.default_lang_ctx;
        l_warning      pls_integer := dbms_lob.warn_inconvertible_char;
    begin
        dbms_lob.createtemporary(
            lob_loc => l_blob,
            cache   => true
        );
        dbms_lob.converttoblob(
            dest_lob     => l_blob,
            src_clob     => p_data,
            amount       => dbms_lob.lobmaxsize,
            dest_offset  => l_dest_offset,
            src_offset   => l_src_offset,
            blob_csid    => dbms_lob.default_csid,
            lang_context => l_lang_context,
            warning      => l_warning
        );

        return l_blob;
    end;
  --
    function base64encode (
        p_blob in blob
    ) return clob
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/base64encode.sql
-- Author       : Tim Hall
-- Description  : Encodes a BLOB into a Base64 CLOB.
-- Last Modified: 09/11/2011
-- -----------------------------------------------------------------------------------
     is
        l_clob clob;
        l_step pls_integer := 12000; -- make sure you set a multiple of 3 not higher than 24573
    begin
        for i in 0..trunc((dbms_lob.getlength(p_blob) - 1) / l_step) loop
            l_clob := l_clob
                      || utl_raw.cast_to_varchar2(utl_encode.base64_encode(dbms_lob.substr(p_blob, l_step, i * l_step + 1)));
        end loop;

        return l_clob;
    end;
  --
    function blob_to_clob (
        blob_in in blob
    ) return clob as

        v_clob    clob;
        v_varchar varchar2(32767);
        v_start   pls_integer := 1;
        v_buffer  pls_integer := 32767;
    begin
        dbms_lob.createtemporary(v_clob, true);
        for i in 1..ceil(dbms_lob.getlength(blob_in) / v_buffer) loop
            v_varchar := utl_raw.cast_to_varchar2(dbms_lob.substr(blob_in, v_buffer, v_start));

            dbms_lob.writeappend(v_clob,
                                 length(v_varchar),
                                 v_varchar);
            v_start := v_start + v_buffer;
        end loop;

        return v_clob;
    exception
        when others then
            return '';
    end blob_to_clob;

    function base64decode (
        p_clob clob
    ) return clob is

        l_blob   blob;
        l_raw    raw(32767);
        l_amt    number := 7700;
        l_offset number := 1;
   -- l_temp    VARCHAR2(32767);
        l_temp   clob;
    begin
        begin
            dbms_lob.createtemporary(l_blob, false, dbms_lob.call);
            loop
                dbms_lob.read(p_clob, l_amt, l_offset, l_temp);
                l_offset := l_offset + l_amt;
                l_raw := utl_encode.base64_decode(utl_raw.cast_to_raw(l_temp));
                dbms_lob.append(l_blob,
                                to_blob(l_raw));
            end loop;

        exception
            when no_data_found then
                null;
        end;
    --print(utl_raw.cast_to_varchar2(l_blob));
        return blob_to_clob(l_blob);
    end;
  --
    function get_value_json (
        p_label  varchar2,
        p_source clob
    ) return clob as
  --
        l_return clob;
  --
    begin
   /* RETURN
    SUBSTR(p_source,INSTR(upper(p_source),UPPER('"'||p_label||'"'))+LENGTH('"'||p_label||'"')+2,
                instr(SUBSTR(p_source,INSTR(upper(p_source),UPPER('"'||p_label||'"'))+LENGTH('"'||p_label||'"')+2),'"')-1
               ); */
   /*SELECT substr(trat2,1,instr(trat2,'"')-1) trat
      INTO l_return
      FROM (SELECT SUBSTR(p_source,INSTR(upper(p_source),UPPER('"'||p_label||'"'))+LENGTH('"'||p_label||'"')+3) trat2
              FROM dual
              );*/
        l_return := substr(p_source,
                           instr(
                                upper(p_source),
                                upper('"'
                                      || p_label || '"')
                            ) + length('"'
                                       || p_label || '"') + 2);

        l_return := substr(l_return,
                           1,
                           instr(l_return, '"') - 1);
    --
        return l_return;
    --
    exception
        when others then
            raise_application_error(-20001, 'Impossível obter resultado de campo ' || sqlerrm);
    end get_value_json;
  --
    function lpad (
        p varchar2,
        n number,
        c varchar2
    ) return varchar2 is
        x varchar2(32000);
    begin
    --
        select
            lpad(
                substr(p,
                       decode(
                    sign(length(p) - n),
                    1,
                    length(p) -(n - 1),
                    1
                )),
                n,
                c
            )
        into x
        from
            dual;
    --
        return x;
    --
    exception
        when others then
            return p;
    end;
  --
    function process_cteos_link (
        p_clob in clob
    ) return clob as

        l_marq1     number;
        l_marq2     number;
        l_marq3     number;
        l_marq4     number;
        l_clob_trat clob;
        l_return    clob := p_clob;
    begin
    --
        l_clob_trat := p_clob;
    --
    --
        l_marq1 := instr(l_clob_trat, '<qrCodCTe>', 1) + 10;
    --
        l_clob_trat := substr(l_clob_trat, l_marq1);
    --
        l_marq2 := instr(l_clob_trat, '</qrCodCTe>', 1) - 1;
    --
        l_clob_trat := substr(l_clob_trat, 1, l_marq2);
    --
    --dbms_output.put_line(l_clob_trat);
    --
        if l_clob_trat not like '%<![CDATA[%' then
      --
            l_return := replace(l_return, l_clob_trat, '<![CDATA['
                                                       || l_clob_trat
                                                       || ']]>');
      --
        end if;
    --
        return l_return;
    --
    exception
        when others then
            return p_clob;
    end process_cteos_link;
  
  --
    procedure process_cep (
        p_clob in out clob
    ) as
        l_marq1     number;
        l_marq2     number;
        l_marq3     number;
        l_marq4     number;
        l_clob_trat clob;
    begin
    --
        l_clob_trat := p_clob;
    --
    --
        l_marq1 := instr(l_clob_trat, '<CEP>', 1) + 5;
        l_marq2 := instr(l_clob_trat, '</CEP>', 1);
    --
        l_clob_trat := substr(l_clob_trat, 1, l_marq1)
                       || substr(
            substr(l_clob_trat, l_marq1 + 1, l_marq2 - l_marq1),
            1,
            4
        )
                       || '-'
                       || substr(
            substr(l_clob_trat, l_marq1, l_marq2 - l_marq1),
            6
        )
                       || substr(l_clob_trat, l_marq2);
    --
        l_marq3 := instr(l_clob_trat, '<CEP>', -1) + 5;
        l_marq4 := instr(l_clob_trat, '</CEP>', -1);
    --
        l_clob_trat := substr(l_clob_trat, 1, l_marq3)
                       || substr(
            substr(l_clob_trat, l_marq3 + 1, l_marq4 - l_marq3),
            1,
            4
        )
                       || '-'
                       || substr(
            substr(l_clob_trat, l_marq3, l_marq4 - l_marq3),
            6
        )
                       || substr(l_clob_trat, l_marq4);
  --END LOOP;
        p_clob := l_clob_trat;
    --
    end process_cep;
  --
  -- Alteração de XML FDC
  --
    procedure process_xped (
        p_clob   in out clob,
        p_efd_id number
    ) as
  --
        l_clob_trat clob;
  --
        l_xml       xmltype;
    begin
    --
        begin
      --
            l_xml := xmltype(p_clob);
      --
        exception
            when others then
      --
                print('Não foi possível converter em XML');
      --
        end;
    --
        if l_clob_trat is null then
            l_clob_trat := p_clob;
        end if;
        print('Entrada XML: ' || l_clob_trat);
        for xped in (            --
            select
                row_number()
                over(partition by pedido, line_num
                     order by
                         pedido, line_num
                )                                   ocurr_seq,
                count(*)
                over(partition by pedido, line_num) ocurr_tot,
                itm.line_num,
                itm.pedido                          xped,
                itm.line_num_ped,
                itm.des_produto,
                ''                                  compra_xped
            from --rmais_ctrl_docs_poc rm,
                xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/nfe' ),
                '/nfeProc/NFe/infNFe/det'
                        passing xmltype(p_clob)
                    columns
                        pedido varchar2(150) path '/det/prod/xPed/text()',
                        line_num number path '/det/@nItem',
                        line_num_ped number path '/det/prod/nItemPed/text()',
                        des_produto varchar2(255) path '/det/prod/xProd/text()'
                   -- , compra_xped            VARCHAR2(255) Path '/infNFe/compra/xPed/text()'
                ) itm
            where
                1 = 1--rm.tipo_fiscal = '55' AND rm.status = 'P' AND ROWNUM=1
                    --AND rm.eletronic_invoice_key  = '35201211425052000126550010000110981752918565'
            order by
                line_num,
                pedido,
                ocurr_seq
        ) loop
      --
            print('Loop XML Linha: ' || xped.line_num);
      --
            begin
       --
                for rml in (
                    select distinct
                        l.source_doc_number,
                        l.line_number,
                        l.efd_header_id,
                        nvl(
                            json_value(l.item_info, '$.DESCRIPTION'),
                            l.item_descr_efd
                        ) item_description,
                        nvl(
                            json_value(l.item_info, '$.ITEM_NUMBER'),
                            l.item_code_efd
                        ) item_code,
                        l.source_doc_line_num,
                        nvl(
                            json_value(l.order_info, '$.PRIMARY_UOM_CODE'),
                            l.uom_to
                        ) uom,
                        source_document_type
                    from
                        rmais_efd_lines_hdi l
                    where
                            efd_header_id = p_efd_id
                        and line_number = xped.line_num
                ) loop
                    if nvl(rml.source_document_type, 'PO') = 'PO' then
            ----
                        print('Tratamento XPED PO');
            --
                        if rml.source_doc_number is not null then
                            declare
                                l_marq1 number;
                                l_marq2 number;
                                l_marq3 number;
                                l_marq4 number;
                                l_marq5 number;--fim </xped>
              --
                            begin
                   --print('Tratamento XMLPED Line_num: '||xped.line_num|| 'EFD_HEADER_ID: '||p_efd_id);
                --
                                l_marq1 := instr(l_clob_trat, '<det nItem="'
                                                              || xped.line_num
                                                              || '">');
                                l_marq2 := instr(
                                    substr(l_clob_trat,
                                           instr(l_clob_trat, '<det nItem="'
                                                              || xped.line_num
                                                              || '">')),
                                    '</det>'
                                ) + 5;

                                l_marq3 := instr(
                                    substr(l_clob_trat, l_marq1, l_marq2),
                                    '</indTot>'
                                ) + 7;

                                l_marq4 := instr(
                                    substr(l_clob_trat, l_marq1, l_marq2),
                                    '<xPed>'
                                ) + 4;

                                l_marq5 := nvl(
                                    instr(
                                        substr(l_clob_trat, l_marq1, l_marq2),
                                        '</xPed>'
                                    ),
                                    0
                                );
                --
                                if l_marq5 = 0 then
                                    l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq3)
                                                   || '<xPed>'
                                                   || rml.source_doc_number
                                                   || '</xPed>'
                                                   || substr(l_clob_trat, l_marq1 + l_marq3 + 1);
                                else
                  --print('Alterando Xped: '||l_clob_trat);
                                    l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq4)
                                                   || rml.source_doc_number
                                                   || substr(l_clob_trat, l_marq1 + l_marq5 - 1);
                                end if;

                            exception
                                when others then
                                    print('Erro ao tratar XPED: ' || sqlerrm);
                            end;

                        end if;
            --Tratamento linha do PO
                        if rml.source_doc_line_num is not null then
                 --print('Tratamento doc_line_num');
                            declare
                                l_marq1 number;
                                l_marq2 number;
                                l_marq3 number;
                                l_marq4 number;
                                l_marq5 number;--fim </xped>
              --
                            begin
                --
                                l_marq1 := instr(l_clob_trat, '<det nItem="'
                                                              || xped.line_num
                                                              || '">');
                                l_marq2 := instr(
                                    substr(l_clob_trat,
                                           instr(l_clob_trat, '<det nItem="'
                                                              || xped.line_num
                                                              || '">')),
                                    '</det>'
                                ) + 5;

                                l_marq3 := instr(
                                    substr(l_clob_trat, l_marq1, l_marq2),
                                    '</xPed>'
                                ) + 5;

                                l_marq4 := instr(
                                    substr(l_clob_trat, l_marq1, l_marq2),
                                    '<nItemPed>'
                                ) + 8;

                                l_marq5 := nvl(
                                    instr(
                                        substr(l_clob_trat, l_marq1, l_marq2),
                                        '</nItemPed>'
                                    ),
                                    0
                                );
                --
                                if l_marq5 = 0 then
                                    l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq3)
                                                   || '<nItemPed>'
                                                   || rml.source_doc_line_num
                                                   || '</nItemPed>'
                                                   || substr(l_clob_trat, l_marq1 + l_marq3 + 1);
                                else
                  --print('Alterando Xped: '||l_clob_trat);
                                    l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq4)
                                                   || rml.source_doc_line_num
                                                   || substr(l_clob_trat, l_marq1 + l_marq5 - 1);
                  --
                                end if;

                            exception
                                when others then
                                    print('Erro ao tratar nItemPed: ' || sqlerrm);
                            end;
                        end if;
            --
                        print('xped.compra_xped: ' || xped.compra_xped);
            --
                        if
                            l_clob_trat like '%<compra>%'
                            and l_clob_trat like '%</compra>%'
                        then
              --
                            begin
                --
                                l_clob_trat := substr(l_clob_trat,
                                                      1,
                                                      instr(l_clob_trat, '<compra>') - 1)
                                               || substr(l_clob_trat,
                                                         instr(l_clob_trat, '</compra>') + 9);
                --
                            exception
                                when others then
                                    print('Erro ao tratar nItemPed: ' || sqlerrm);
                            end;
              --
                        end if;
            --  
                    else --tratamento sem pedido limpando xped
            --
                        print('Tratamento XPED SPO');
            --
                        if xped.xped is not null then
              --

                            declare
                                l_marq1 number;
                                l_marq2 number;
                                l_marq3 number;
                                l_marq4 number;
                                l_marq5 number;--fim </xped>
            --
                            begin
              --
                                print('Tratamento XPED SPO - xped Localizado Linha: ' || xped.line_num);
              --
                 --print('Tratamento XMLPED Line_num: '||xped.line_num|| 'EFD_HEADER_ID: '||p_efd_id);
              --
                                l_marq1 := instr(l_clob_trat, '<det nItem="'
                                                              || xped.line_num
                                                              || '">');
                                l_marq2 := instr(
                                    substr(l_clob_trat,
                                           instr(l_clob_trat, l_marq1)),
                                    '</det>'
                                ) + 6;

                                l_marq3 := instr(
                                    substr(l_clob_trat, l_marq1, l_marq2),
                                    '</indTot>'
                                ) + 7;

                                l_marq4 := instr(
                                    substr(l_clob_trat, l_marq1, l_marq2),
                                    '<xPed>'
                                ) - 1;

                                l_marq5 := nvl(
                                    instr(
                                        substr(l_clob_trat, l_marq1, l_marq2),
                                        '</xPed>'
                                    ),
                                    0
                                ) + 6;
              --
                                print('l_marq1: ' || l_marq1);
                                print('l_marq2: ' || l_marq2);
                                print('l_marq3: ' || l_marq3);
                                print('l_marq4: ' || l_marq4);
                                print('l_marq5: ' || l_marq5);
              --
                                l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq3)
                                               || substr(l_clob_trat, l_marq1 + l_marq5);
              --
                                print('Saída XML TIRANDO XPED  LINHA: ' || xped.line_num);
                                print_clob_to_output(l_clob_trat);
                                print('******************************');
                            exception
                                when others then
                                    print('Erro ao tratar XPED SEM PO: ' || sqlerrm);
                            end;
                
              --
                        end if;
            --
                        if xped.line_num_ped is not null then
                            declare
                                l_marq1 number;
                                l_marq2 number;
                                l_marq3 number;
                                l_marq4 number;
                                l_marq5 number;--fim </xped>
            --
                            begin
              -- 
                                print('Tratamento da linha do XPED localizado');
              --
                                l_marq1 := instr(l_clob_trat, '<det nItem="'
                                                              || xped.line_num
                                                              || '">');
                                l_marq2 := instr(
                                    substr(l_clob_trat,
                                           instr(l_clob_trat, '<det nItem="'
                                                              || xped.line_num
                                                              || '">')),
                                    '</det>'
                                ) + 6;

                                l_marq3 := instr(
                                    substr(l_clob_trat, l_marq1, l_marq2),
                                    '</indTot>'
                                ) + 8;

                                l_marq4 := instr(
                                    substr(l_clob_trat, l_marq1, l_marq2),
                                    '<nItemPed>'
                                ) - 1;

                                l_marq5 := nvl(
                                    instr(
                                        substr(l_clob_trat, l_marq1, l_marq2),
                                        '</nItemPed>'
                                    ),
                                    0
                                ) + 11;
              --
                                l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq3)
                                               || substr(l_clob_trat, l_marq1 + l_marq5);
              --
                                print('Saída XML TIRANDO nItemPed  LINHA: ' || xped.line_num);
                                print_clob_to_output(l_clob_trat);
              --
                            exception
                                when others then
                                    print('Erro ao tratar XPED SEM PO: ' || sqlerrm);
                            end;
              --
                        end if;
            --
                        print('Compra xPed: ' || xped.compra_xped);
            --
                        if
                            l_clob_trat like '%<compra>%'
                            and l_clob_trat like '%</compra>%'
                        then
                            begin
                --
                                l_clob_trat := substr(l_clob_trat,
                                                      1,
                                                      instr(l_clob_trat, '<compra>') - 1)
                                               || substr(l_clob_trat,
                                                         instr(l_clob_trat, '</compra>') + 9);
                --
                            exception
                                when others then
                                    print('Erro ao tratar <compra>: ' || sqlerrm);
                            end;
              --
                        end if; 
            --  
                    end if;
          
          -- Tratamento Item rml.item_code
                    if rml.item_code is not null then
                  --print('Tratamento ITem');
                        declare
                            l_marq1 number;
                            l_marq2 number;
                            l_marq3 number;
                            l_marq4 number;
                            l_marq5 number;--fim </xped>
            --
                        begin
              --
                            l_marq1 := instr(l_clob_trat, '<det nItem="'
                                                          || xped.line_num
                                                          || '">');
                            l_marq2 := instr(
                                substr(l_clob_trat,
                                       instr(l_clob_trat, '<det nItem="'
                                                          || xped.line_num
                                                          || '">')),
                                '</det>'
                            ) + 5;

                            l_marq3 := instr(
                                substr(l_clob_trat, l_marq1, l_marq2),
                                '<prod>'
                            ) + 4;

                            l_marq4 := instr(
                                substr(l_clob_trat, l_marq1, l_marq2),
                                '<cProd>'
                            ) + 5;

                            l_marq5 := nvl(
                                instr(
                                    substr(l_clob_trat, l_marq1, l_marq2),
                                    '</cProd>'
                                ),
                                0
                            );
              --
                            if l_marq5 = 0 then
                                l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq3)
                                               || '<cProd>'
                                               || rml.item_code
                                               || '</cProd>'
                                               || substr(l_clob_trat, l_marq1 + l_marq3 + 1);
                            else
                --print('Alterando Xped: '||l_clob_trat);
                                l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq4)
                                               || rml.item_code
                                               || substr(l_clob_trat, l_marq1 + l_marq5 - 1);
                            end if;

                            print('Saída XML TIRANDO cProd  LINHA: ' || xped.line_num);
                            print_clob_to_output(l_clob_trat);
                        exception
                            when others then
                                print('Erro ao tratar cProd: ' || sqlerrm);
                        end;

                        print('Tratamento item');
                    end if;
           -- tratamento UOM uCom
                    if rml.uom is not null then
              --print('Tratamento UOM');
                        declare
                            l_marq1 number;
                            l_marq2 number;
                            l_marq3 number;
                            l_marq4 number;
                            l_marq5 number;--fim </xped>
            --
                        begin
              --
                            l_marq1 := instr(l_clob_trat, '<det nItem="'
                                                          || xped.line_num
                                                          || '">');
                            l_marq2 := instr(
                                substr(l_clob_trat,
                                       instr(l_clob_trat, '<det nItem="'
                                                          || xped.line_num
                                                          || '">')),
                                '</det>'
                            ) + 5;

                            l_marq3 := instr(
                                substr(l_clob_trat, l_marq1, l_marq2),
                                '</CFOP>'
                            ) + 5;

                            l_marq4 := instr(
                                substr(l_clob_trat, l_marq1, l_marq2),
                                '<uCom>'
                            ) + 4;

                            l_marq5 := nvl(
                                instr(
                                    substr(l_clob_trat, l_marq1, l_marq2),
                                    '</uCom>'
                                ),
                                0
                            );
              --
                            if l_marq5 = 0 then
                                l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq3)
                                               || '<uCom>'
                                               || rml.uom
                                               || '</uCom>'
                                               || substr(l_clob_trat, l_marq1 + l_marq3 + 1);
                            else
                --print('Alterando Xped: '||l_clob_trat);
                                l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq4)
                                               || rml.uom
                                               || substr(l_clob_trat, l_marq1 + l_marq5 - 1);
                            end if;

                            print('Saída XML TIRANDO uCom LINHA: ' || xped.line_num);
                            print_clob_to_output(l_clob_trat);
                        exception
                            when others then
                                print('Erro ao tratar uCom: ' || sqlerrm);
                        end;

                        declare
                            l_marq1 number;
                            l_marq2 number;
                            l_marq3 number;
                            l_marq4 number;
                            l_marq5 number;--fim </xped>
            --
                        begin
                 --print('Tratamento uCom');
              --
                            l_marq1 := instr(l_clob_trat, '<det nItem="'
                                                          || xped.line_num
                                                          || '">');
                            l_marq2 := instr(
                                substr(l_clob_trat,
                                       instr(l_clob_trat, '<det nItem="'
                                                          || xped.line_num
                                                          || '">')),
                                '</det>'
                            ) + 5;

                            l_marq3 := instr(
                                substr(l_clob_trat, l_marq1, l_marq2),
                                '</cEANTrib>'
                            ) + 9;

                            l_marq4 := instr(
                                substr(l_clob_trat, l_marq1, l_marq2),
                                '<uTrib>'
                            ) + 5;

                            l_marq5 := nvl(
                                instr(
                                    substr(l_clob_trat, l_marq1, l_marq2),
                                    '</uTrib>'
                                ),
                                0
                            );
              --
                            if l_marq5 = 0 then
                                l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq3)
                                               || '<uTrib>'
                                               || rml.uom
                                               || '</uTrib>'
                                               || substr(l_clob_trat, l_marq1 + l_marq3 + 1);
                            else
                --print('Alterando Xped: '||l_clob_trat);
                                l_clob_trat := substr(l_clob_trat, 1, l_marq1 + l_marq4)
                                               || rml.uom
                                               || substr(l_clob_trat, l_marq1 + l_marq5 - 1);
                            end if;

                            print('Saída XML TIRANDO uTrib  LINHA: ' || xped.line_num);
                            print_clob_to_output(l_clob_trat);
                        exception
                            when others then
                                print('Erro ao tratar uTrib: ' || sqlerrm);
                        end;

                        print('Tratamento UOM');
                    end if;

                end loop;

            end;
      --
        end loop;
    --
        if g_test is not null then
            print('Clob Tratado');
       --print_clob_to_output(l_clob_trat);
            print(l_clob_trat);
        end if;
    --
        p_clob := l_clob_trat;
    --dbms_OUTPUT.PUT_LINE('Final do tratamento');        
    exception
        when others then
            raise_application_error(-20022, 'Não foi possível fazer a alteração no XML de envio ERRO:' || sqlerrm);
    end process_xped;
  --
    procedure send_danfe (
        p_id number
    ) as

        l_xml_send       clob;
        l_xml_encode     clob;
        l_body_send      clob;
        l_danfe          varchar2(44);
        l_num            number;
        l_cnpj_forn      varchar2(15);
        l_transaction_id number;
        l_model          varchar2(10);
    begin
    --
        select
            model
        into l_model
        from
            rmais_efd_headers_hdi
        where
            efd_header_id = p_id;
    --  
        if l_model in ( '55', '57', '67' ) then  
      --
            select
                *
            into
                l_xml_send,
                l_danfe,
                l_cnpj_forn,
                l_num
            from
                (
                    select
                        efdc.source_doc_decr aa,
                        efdh.access_key_number,
                        efdh.issuer_document_number,
                        efdh.document_number
                    from
                        rmais_efd_headers_hdi efdh,
                        rmais_ctrl_docs_poc   efdc
                    where
                        doc_id is not null
                        and model in ( '55', '57', '67' )
                        and efdh.doc_id = efdc.id
                        and efd_header_id = p_id
                );

        else
            select
                *
            into
                l_xml_send,
                l_danfe,
                l_cnpj_forn,
                l_num
            from
                (
                    select
                        rmais_util_pkg_poc.parse_xml_sefaz(efdh.efd_header_id),
                        efdh.access_key_number,
                        efdh.issuer_document_number,
                        efdh.document_number
                    from
                        rmais_efd_headers_hdi efdh
                    where
                            1 = 1
                        and efdh.model = '00'
                        and efdh.efd_header_id = p_id
                );

        end if;
    --
    --print(l_xml_send);
        process_xped(l_xml_send, p_id);
   -- process_cep(l_xml_send);
    --print(l_xml_send);
     --
    --print(l_xml_send);
        l_xml_encode := xxrmais_util_pkg.base64encode(xxrmais_util_pkg.clob_to_blob(replace(l_xml_send, '> <', '><')));
    --
    --print('ENCODE');
    --
        rmais_process_pkg.insert_ws_info(
            p_id     => l_transaction_id,
            p_method => 'SEND_NFE',
            p_clob   => replace(
                replace(
                    replace(
                        replace(l_xml_encode,
                                chr(10),
                                ''),
                        chr(13),
                        ''
                    ),
                    chr(09),
                    ''
                ),
                ' ',
                ''
            )
        );

        print('Transaction_id: ' || l_transaction_id);
    --
        commit;
    --
   -- print('BODY');
    --
  --replace(translate(v_clob, chr(10) || chr(13) || chr(09), ' ') ,' ','');
        l_body_send := '{"cnpj_emissor":"'
                       || l_cnpj_forn
                       || '","num_nf":"'
                       || l_num
                       || '","chave_eletronica":"'
                       || l_danfe
                       || '","transaction_id":'
                       || l_transaction_id
                       || '}';

        print(l_body_send);
    --
    --Processo de chamada WS
    --
    --
        if nvl(g_test, 'T') = 'T' then
      --
            declare
      --
                l_url      varchar2(400) := rmais_process_pkg.get_parameter('URL_SEND_FDC');--'http://144.22.236.32:9000/api/job/v2/sendDocToFDC';
      --
                req        utl_http.req;
      --
                resp       utl_http.resp;
      --
      --buffer varchar2(32000);
      --
                buffer     clob;
      --
                content    clob := l_body_send;
      --
                l_response clob;
      --
            begin
        --
        --print('Entrando na chamada WS');
        --
        --req := utl_http.begin_request( l_url );
        --
                req := utl_http.begin_request(l_url, 'POST', 'HTTP/1.1');
                utl_http.set_header(req, 'Authorization', 'Basic YWRtaW46YWRtaW4=');
                utl_http.set_header(req, 'user-agent', 'mozilla/4.0');
                utl_http.set_header(req, 'content-type', 'application/json; charset=utf-8');
                utl_http.set_header(req,
                                    'Content-Length',
                                    length(content));
        --
                utl_http.write_text(req, content);
        --
                resp := utl_http.get_response(req);
        --
                begin
          --
                    loop
            --
                        utl_http.read_line(resp, buffer);
            --
            --p_log := CASE WHEN p_log IS NULL THEN BUFFER ELSE p_log||chr(10)||BUFFER END;
            --
            --
                        if buffer is not null then
              --
                            print(buffer);
              --
                            l_response := l_response || buffer;
              --
                            if xxrmais_util_pkg.get_value_json('DocumentId', l_response) is null then
                --
                --print('Fazer update da status e erro no sumário de validação - ERROR');
                --
                                begin
                  --
                                    insert into rmais_efd_lin_valid (
                                        efd_header_id,
                                        type,
                                        message_text,
                                        creation_date
                                    ) values ( p_id,
                                               'Erro',
                                               l_response,
                                               sysdate );
                  --
                                    update rmais_efd_headers_hdi
                                    set
                                        document_status = 'E'
                                    where
                                        efd_header_id = p_id;
                  --
                                exception
                                    when others then
                                        print('Não foi possível inserir erros' || sqlerrm);
                                end;
                            else
                --
                                begin
                  --
                                    insert into rmais_efd_lin_valid (
                                        efd_header_id,
                                        type,
                                        message_text,
                                        creation_date
                                    ) values ( p_id,
                                               'Enviado para ERP (FDC)',
                                               'Documentid: '
                                               || xxrmais_util_pkg.get_value_json('DocumentId', l_response),
                                               sysdate );
                  --
                                    update rmais_efd_headers_hdi
                                    set
                                        document_status = 'T'
                                    where
                                        efd_header_id = p_id;
                  --
                                    print('Atualizado status integrado -- Sucesso');
                  --
                                exception
                                    when others then
                                        print('Não foi possível inserir erros' || sqlerrm);
                                end;
                            end if;
              --
                        end if;

                    end loop;

                    utl_http.end_response(resp);
            --
                exception
                    when utl_http.end_of_body then
                        utl_http.end_response(resp);
                    when others then
                        utl_http.end_response(resp);
                end;
          --
            exception
                when others then
          --adicionar erro sqerrm
                    print('Erro ao chamar WS: ' || sqlerrm);
                    print(utl_http.get_detailed_sqlerrm);
          --
            end;
        end if;

        print('**** Final do processo SEND_DANFE ****');
    --Atualizar status da NF
    exception
        when others then
        --
            print('Erro Fatal: ' || sqlerrm);
        --
    end send_danfe;
  --
    function get_access_key_number (
        p_cnpj_dest  varchar2,
        p_cnpj       varchar2,
        p_issue_date date,
        p_numero_nff number
    ) return varchar2 as
        l_return     rmais_efd_headers_hdi.access_key_number%type;
        l_numero_nff rmais_efd_headers_hdi.access_key_number%type;
    begin
        if to_char(p_issue_date, 'YYYY') = substr(p_numero_nff, 1, 4) then
            l_numero_nff := trunc(to_char(p_issue_date, 'YYYY') || to_char(to_number(nls_num_char(substr(p_numero_nff, 5)))));
        else
            l_numero_nff := trunc(to_number(p_numero_nff));
        end if;
    --
        print('Gerando chave p_Cnpj_Dest:'
              || p_cnpj_dest
              || ' p_Cnpj'
              || ' p_issue_date: '
              || p_issue_date
              || ' p_Numero_Nff: ' || p_numero_nff);
    --
        select
            access_key_number
        into l_return
        from
            rmais_efd_headers_hdi
        where
            access_key_number = lpad(lpad(p_cnpj_dest, 15, '0')
                                     || lpad(p_cnpj, 15, '0')
                                     || to_char(p_issue_date, 'YYYYMM')
                                     || lpad(p_numero_nff, 8, '0'),
                                     44,
                                     '0')
            or access_key_number = lpad(lpad(p_cnpj_dest, 15, '0')
                                        || lpad(p_cnpj, 15, '0')
                                        || to_char(p_issue_date, 'YYYYMM')
                                        || lpad(l_numero_nff, 8, '0'),
                                        44,
                                        '0');

        return ( l_return );
    exception
        when others then
    --
            begin
        --
                select
                    access_key_number
                into l_return
                from
                    rmais_efd_headers_hdi
                where
                    access_key_number = lpad(lpad(
                        nvl(p_cnpj, '0'),
                        15,
                        '0'
                    )
                                             || lpad(
                        nvl(p_cnpj_dest, '0'),
                        15,
                        '0'
                    )
                                             || to_char(to_date(p_issue_date, 'DD-MM-YY'), 'YYYYMM')
                                             || p_numero_nff,
                                             44,
                                             '0')
                    or access_key_number = lpad(lpad(
                        nvl(p_cnpj, '0'),
                        15,
                        '0'
                    )
                                                || lpad(
                        nvl(p_cnpj_dest, '0'),
                        15,
                        '0'
                    )
                                                || to_char(to_date(p_issue_date, 'DD-MM-YY'), 'YYYYMM')
                                                || l_numero_nff,
                                                44,
                                                '0');
        --
                return ( l_return );
        --
            exception
                when others then
                    begin
            --Incluído mais uma analise devido ao ajuste de números de notas modelo 00 que possam ser reprocessadas 14/04/2023.            
            --
                        select
                            access_key_number
                        into l_return
                        from
                            rmais_efd_headers_hdi
                        where
                            access_key_number = lpad(lpad(
                                nvl(p_cnpj, '0'),
                                15,
                                '0'
                            )
                                                     || to_char(to_date(p_issue_date, 'DD-MM-YY'), 'YYYYMM')
                                                     || lpad(p_numero_nff, 23, '0'),
                                                     44,
                                                     '0')
                            or access_key_number = lpad(lpad(
                                nvl(p_cnpj, '0'),
                                15,
                                '0'
                            )
                                                        || to_char(to_date(p_issue_date, 'DD-MM-YY'), 'YYYYMM')
                                                        || lpad(l_numero_nff, 23, '0'),
                                                        44,
                                                        '0');
            --
                        return ( l_return );
            --
                    exception
                        when others then
                --
                            l_return := lpad(lpad(
                                nvl(p_cnpj, '0'),
                                15,
                                '0'
                            )
                                             || to_char(to_date(p_issue_date, 'DD-MM-YY'), 'YYYYMM')
                                             || lpad(p_numero_nff, 23, '0'),
                                             44,
                                             '0');
                --
                            return ( l_return );
                --
                    end;
            end;
    end get_access_key_number;  
  --
    procedure source_docs (
        p_id number default null
    ) as
 --
        return_reposnse2 clob;
        g_status         varchar2(1);--P processado  E Error   D Duplicada   R Rejeitada    M evento de manifesto
        g_ctrl_id        number;
        g_ctrl           rmais.rmais_ctrl_docs_poc%rowtype;
        g_source         rmais.xxrmais_invoices%rowtype;
        g_source_l       rmais.xxrmais_invoice_lines%rowtype;
        l_header         rmais.rmais_efd_headers_hdi%rowtype;
        l_lines          rmais.rmais_efd_lines_hdi%rowtype;
 --
        g_doc_count      number := 0;
 --
        type c$refcur is ref cursor;
  --
        type rh$nfse is record (
                versao                   number,
                id                       varchar2(1000),
                xtiponf                  varchar2(1000),
                xmodelofiscal            varchar2(1000),
                xdata_carimbo            varchar2(1000),
                xoperfiscal              varchar2(1000),
                condpagto                varchar2(1000),
                numero_nff               varchar2(1000),
                serie                    varchar2(1000),
                xcfo                     varchar2(1000),
                cfo                      varchar2(1000),
                codigoverificacao        varchar2(1000),
                dataemissao              varchar2(1000),
                outrasinformacoes        varchar2(4000),
                basecalculo              varchar2(1000),
                aliquota                 varchar2(1000),
                valoriss_nfse            varchar2(1000),
                dtvenc_iss               varchar2(1000),
                valorliquidonfse         varchar2(1000),
                valorcredito             varchar2(1000),
                cnpj                     varchar2(1000),
                cpf                      varchar2(1000),
                inscricaomunicipal       varchar2(1000),
                inscricaoestadual        varchar2(1000),
                nome                     varchar2(1000),
                razaosocial              varchar2(1000),
                nomefantasia             varchar2(1000),
                endereco                 varchar2(1000),
                numero                   varchar2(1000),
                bairro                   varchar2(1000),
                uf                       varchar2(1000),
                cep                      varchar2(1000),
                telefone                 varchar2(1000),
                complemento              varchar2(1000),
                email                    varchar2(1000),
                codigomunicipio          varchar2(1000),
                municipio                varchar2(1000),
                pais                     varchar2(1000),
                tipo_rps                 varchar2(1000),
                dataemissao_rps          varchar2(1000),
                numero_rps               varchar2(1000),
                serie_rps                varchar2(1000),
                status_rps               varchar2(1000),
                tipo_rps_subst           varchar2(1000),
                competencia              varchar2(1000),
                valorservicos            varchar2(1000),
                valordeducoes            varchar2(1000),
                valorpis                 varchar2(1000),
                alqpispasep              varchar2(1000),
                valorcofins              varchar2(1000),
                alqcofins                varchar2(1000),
                valorinss_servico        varchar2(1000),
                valorir                  varchar2(1000),
                alqirrf                  varchar2(1000),
                valorcsll                varchar2(1000),
                vlrissretido             varchar2(1000),
                alqissretido             varchar2(1000),
                alqcsll                  varchar2(1000),
                outrasretencoes          varchar2(1000),
                valoriss                 varchar2(1000),
                descontoincondicionado   varchar2(1000),
                descontocondicionado     varchar2(1000),
                issretido                varchar2(1000),
                codtribmuni              varchar2(1000),
                codigomunicipio_ser      varchar2(1000),
                exigibilidadeiss         varchar2(1000),
                xdatapaga                varchar2(1000),
                cnpj_emit                varchar2(1000),
                cpf_emit                 varchar2(1000),
                entity_id                varchar2(1000),
                inscricaomunicipal_p     varchar2(1000),
                cnpj_dest                varchar2(1000),
                inscricaomunicipal_dest  varchar2(1000),
                razaosocial_dest         varchar2(1000),
                endereco_dest            varchar2(1000),
                numero_dest              varchar2(1000),
                uf_dest                  varchar2(1000),
                xnomemunicipio           varchar2(1000),
                telefone_dest            varchar2(1000),
                email_dest               varchar2(1000),
                xcodestabtomador         varchar2(1000),
                xnomeestabtomador        varchar2(1000),
                optantesimplesnacional   varchar2(1000),
                incentivofiscal          varchar2(1000),
                serv_list                varchar2(1000),
                numeronfsesubstituida    varchar2(1000),
                dtprestacaoservico       varchar2(1000),
                inter_cpf                varchar2(1000),
                inter_cnpj               varchar2(1000),
                inter_inscricaomunicipal varchar2(1000),
                inter_inscricaoestadual  varchar2(1000),
                inter_nome               varchar2(1000),
                inter_razaosocial        varchar2(1000),
                inter_nomefantasia       varchar2(1000),
                inter_endereco           varchar2(1000),
                inter_numero             varchar2(1000),
                inter_complemento        varchar2(1000),
                inter_bairro             varchar2(1000),
                inter_municipio          varchar2(1000),
                inter_uf                 varchar2(1000),
                inter_pais               varchar2(1000),
                inter_cep                varchar2(1000),
                inter_telefone           varchar2(1000),
                inter_email              varchar2(1000),
                inter_regime             varchar2(1000),
                inter_codigomobiliario   varchar2(1000),
                toma_regime              varchar2(1000),
                toma_codigomobiliario    varchar2(1000),
                prest_nome               varchar2(1000),
                prest_regime             varchar2(1000),
                prest_codigomobiliario   varchar2(1000),
                discr_servico            varchar2(1000),
                constru_art              varchar2(1000),
                constru_cod_obra         varchar2(1000),
                valor_total              varchar2(1000),
                desconto                 varchar2(1000),
                ret_federal              varchar2(1000),
                municipioincidencia      varchar2(1000),
                recolhimento             varchar2(1000),
                tributacao               varchar2(1000),
                cnae                     varchar2(1000),
                descricaoatividade       varchar2(1000),
                descricaotiposervico     varchar2(1000),
                localprestacao           varchar2(1000),
                naturezaoperacao         varchar2(1000),
                regimeespecialtributacao varchar2(1000),
                numeroguia               varchar2(1000),
                po_num                   varchar2(1000),
                po_item                  varchar2(1000),
                particularidades         varchar2(1000),
                status_nf                varchar2(100),
                itens                    xmltype,
                boleto_cod               varchar2(100),
                currency_code            varchar2(10),
                chave_pix                varchar2(1024)
        );
  --
  --
        type rl$nfse is record (
                pedido       varchar2(150),
                line_num     number,
                xcod_produto varchar2(500),
                xdes_produto varchar2(500),
                uom          varchar2(100),
                valor_tot    number,
                valor_un     number,
                vqtde        number
        );
  --
  --
  --
        procedure valid_org (
            p_cnpj   varchar2,
            p_status out varchar2
        ) as
            l_name_cliente varchar2(200);--retirar
            l_name_org     varchar2(200);
        begin
    --
            select
                rmc.id    cliente_id,
                rmc.nome  cliente_name
      --     ,rmcc.id org_id
                ,
                rmcc.nome org_name,
                rmcc.cnpj
            into
                g_ctrl.id,
                l_name_cliente,
                l_name_org,
                g_ctrl.cnpj_fornecedor
            from
                rmais_suppliers         rmc,
                rmais_organizations_hdi rmcc
            where
                    rmc.id = rmcc.cliente_id
                and rmcc.cnpj = p_cnpj;
    --
            print('****IDENTIFICAÇÂO DE DOCUMENTO ****');
            print('CLIENTE: '
                  || l_name_cliente
                  || ' ORG: ' || l_name_org);
            print('');
    --
        exception
            when others then
    --
                p_status := 'E';
    --
                print('****IDENTIFICAÇÂO DE DOCUMENTO ****');
                print('CLIENTE: '
                      || l_name_cliente
                      || ' NÃO CADASTRADO NO SISTEMA RECEBE MAIS. CNPJ: '
                      || p_cnpj, 1);
    --
        end valid_org;
  --
        function get_po_description_invoice (
            p_value1 varchar2,
            p_value2 varchar2
        ) return varchar2 as

            l_count_position number := 1;
            l_count_instr    number := 0;
            l_count_occ      number := 0;
            l_po_number      varchar2(20);
            l_entry          varchar2(4000) := 'Servicos prestados Faturamento Mensal - Hospedagem Cloud - Gestao de Caixa (Jan a Dez/22) / Referente a Proposta No HDI.2020_03_16.01.12.COM PO: OC001000324 Banco Itau Ag: 0641 C/C: 47820-1 Ref. Jun/2022 - Vencto. 18/07/2022'
            ;
        begin
  --
            for n in 1..2 loop
    --
                if n = 1 then
                    l_entry := p_value1;
                else
                    l_entry := p_value2;
                end if;
      --
                if l_entry like '%OC%' then
                    while l_count_position <> 0 loop
            -- 
                        select
                            instr(l_entry,
                                  'OC',
                                  1,
                                  decode(l_count_occ, 0, 1, l_count_occ))
                        into l_count_position
                        from
                            dual;
            --
                        print(regexp_replace(
                            substr(l_entry, l_count_position, 13),
                            '[^0-9]',
                            ''
                        ));
            --
                        l_po_number := regexp_replace(
                            substr(l_entry, l_count_position, 13),
                            '[^0-9]',
                            ''
                        );
            --
                        if length(l_po_number) in ( 9, 10 ) then
              --
                            l_po_number := 'OC' || l_po_number;
              -- 
                            return l_po_number;
              --
                        else
              --
                            null;
              --  
                        end if;
            --
                        print('l_count_position: ' || l_count_position);
            --
                        if l_count_position <> 0 then
              --
                            l_count_occ := l_count_occ +
                                case
                                    when l_count_occ = 0 then
                                        2
                                    else
                                        1
                                end;
               --
                        else
              --
                            l_count_occ := l_count_occ - 1;
              --
                        end if;
            --
                    end loop;
      --
                end if;
      --
            end loop;
    --
            return null;
    --
            print('Total de ocorrencias: ' || l_count_occ);
    --
            print('Numero de PO Localizado: ' || l_po_number);
    --
        exception
            when others then
    --
                print('Error po_description_invoice: ' || sqlerrm);
    --
        end get_po_description_invoice;
  --
  --
    ----------------------------------------------
  -- Processo de Integração de XMLs para NFSe --
  ----------------------------------------------
        procedure load_read_file_xml_nfse (
            psource    clob,
            p_filename in rmais_efd_headers_hdi.blob_filename%type default null,
            p_file     in rmais_efd_headers_hdi.blob_file%type default null,
            p_process  in rmais_efd_headers_hdi.poc%type
        ) is
    --
            vidx              number;
            clin              c$refcur;
            rlin              rl$nfse;
            rregh             rh$nfse;
            xregc             clob;
            xlinc             clob;
            l_layout          varchar2(60);
            l_xml             xmltype;
            l_header          rmais_efd_headers_hdi%rowtype;
            l_lines           rmais_efd_lines_hdi%rowtype;
    --
            l_document_status rmais_efd_headers_hdi.document_status%type;
    --
            l_resp_link_nfse  varchar2(1000); -- Robson 23/03/2023
    --
            l_poc             varchar2(5);
        begin
    --
            print('Iniciando processamento do Arquivo NFse ' || to_char(sysdate, 'DD/MM/RRRR HH24:MI:SS'));
    --------------------------------------------
    -- Verifica se foi encontrado o diretorio --
    --------------------------------------------
            if 1 = 1 then
      --
                begin
        --
                    declare
        --l_source_trat clob := replace(replace(replace(replace(pSource,'<?xml version="1.0" encoding="ISO-8859-1"?><NFe','<?xml version="1.0" encoding="UTF-8"?><NFe'), chr(10),''),chr(13),''), chr(09), '');
                        l_source_trat clob;-- := replace(replace(replace(replace(pSource, chr(10),''),chr(13),''), chr(09), ''),'<?xml version="1.0" encoding="ISO-8859-1"?><NFe','<?xml version="1.0" encoding="UTF-8"?><NFe');
       -- <?xml version="1.0" encoding="ISO-8859-1"?>
                    begin
        --
                        l_source_trat := replace(
                            replace(
                                replace(psource,
                                        chr(10),
                                        ''),
                                chr(13),
                                ''
                            ),
                            chr(09),
                            ''
                        );

                        l_source_trat := replace(
                            replace(l_source_trat, '<?xml version="1.0" encoding="ISO-8859-1"?><NFe', '<?xml version="1.0" encoding="UTF-8"?><NFe'
                            ),
                            'versao="1.00"',
                            ''
                        );
        --l_source_trat := replace(replace(replace( l_source_trat , chr(10),''),chr(13),''), chr(09), '');
        --
                        for rw in (
                            select
                                source,
                                control,
                                text_value
                            from
                                rmais_source_ctrl --FOR UPDATE
                            where
                                replace(l_source_trat, ' ', '') like replace('%'
                                                                             || text_value
                                                                             || '%', ' ', '')
                                and text_value is not null
                                and nvl(context, '-1') = 'LAYOUT'
                        ) loop
                            if replace(l_source_trat, ' ', '') like replace('%'
                                                                            || rw.text_value
                                                                            || '%', ' ', '') then
                                print(rw.control
                                      || ' => ' || rw.text_value);
                            end if;
                        end loop;

                        select
                            source,
                            control
                        into
                            xregc,
                            l_layout
                        from
                            rmais_source_ctrl --FOR UPDATE
                        where
                            replace(l_source_trat, ' ', '') like replace('%'
                                                                         || text_value
                                                                         || '%', ' ', '')
                            and text_value is not null
                            and nvl(context, '-1') = 'LAYOUT';
            --
          --  SELECT * FROM rmais_source_ctrl FOR UPDATE;
                        print('Layout identificado: ' || l_layout);
            --
                    exception
                        when others then
          --
                            print('Não localizado layout para integração:' || sqlerrm);
          --
                            print(l_source_trat);
          --
                    end;
          --FOR UPDATE
        --

        --print('XML SEM TRATA: '||pSource);
                    if psource like '%xmlns="http://www.barueri.sp.gov.br/nfe"%' then
          --
                        l_xml := xmltype(replace(
                            replace(
                                replace(psource, '<?xml version="1.0" encoding="utf-16"?>', ''),
                                ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"'
                                ,
                                ''
                            ),
                            ' xmlns="http://www.barueri.sp.gov.br/nfe"',
                            ''
                        ));
          --
                    elsif psource like '%<tcNfse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">%'
                    then
          --
                        l_xml := xmltype(replace(psource, '<tcNfse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><InfNfse xmlns="http://www.rmaisorg.br/nfse.xsd">'
                        , '<tcNfse><InfNfse>'));
          --
                    elsif psource like '%<?xml version="1.0" encoding="UTF-8"?><NFe>%' then
          --
                        l_xml := xmltype(replace(psource, '<?xml version="1.0" encoding="UTF-8"?>', ''));
          --
                    elsif psource like '<?xml version="1.0" encoding="ISO-8859-1"?><NFe' then
          --
                        l_xml := xmltype(replace(psource, '<?xml version="1.0" encoding="ISO-8859-1"?>', ''));
          --
                    elsif psource like '<nf3eProc xmlns="http://www.portalfiscal.inf.br/nf3e" versao="1.00">%' then
          --

                        l_xml := xmltype(replace(psource, '<nf3eProc xmlns="http://www.portalfiscal.inf.br/nf3e" versao="1.00"><NF3e xmlns="http://www.portalfiscal.inf.br/nf3e"><infNF3e'
                        , '<nf3eProc><NF3e><infNF3e'));
          --
                    else
          --

                        l_xml := xmltype(psource);
          --
                    end if;
        --
                    l_xml := xmltype(replace(l_xml.getclobval, 'ns2:', ''));
        --
                    print('XML: ' || substr(l_xml.getclobval, 1, 3800));
        --
        --print('TRATA: '||l_xml.getclobval);
        ---------------------------------------
        -- dados do cabeçalho da nota fiscal --
        ---------------------------------------

        --print (xRegc);
                    print('antes do immediate');
                    print(l_xml.getclobval);
                    print('###############');
                    print(xregc);
                    execute immediate xregc
                    into rregh
                        using l_xml;
                    print('teste02');
        --
                    print('Inicializando ORG: ' || rregh.xcodestabtomador);
        --
                    print('');
                    print('versao....................:' || rregh.versao);
                    print('ID........................:' || rregh.id);
                    print('xTipoNF...................:' || rregh.xtiponf);
                    print('xModeloFiscal.............:' || rregh.xmodelofiscal);
                    print('xdata_carimbo.............:' || rregh.xdata_carimbo);
                    print('xOperFiscal...............:' || rregh.xoperfiscal);
                    print('CondPagto.................:' || rregh.condpagto);
                    print('Numero_Nff................:' || rregh.numero_nff);
                    print('Serie.....................:' || rregh.serie);
                    print('xCFO......................:' || rregh.xcfo);
                    print('CFO.......................:' || rregh.cfo);
                    print('CodigoVerificacao.........:' || rregh.codigoverificacao);
                    print('DataEmissao...............:' || rregh.dataemissao);
                    print('OutrasInformacoes.........:' || rregh.outrasinformacoes);
                    print('BaseCalculo...............:' || rregh.basecalculo);
                    print('Aliquota..................:' || rregh.aliquota);
                    print('ValorIss_Nfse.............:' || rregh.valoriss_nfse);
                    print('DtVenc_iss................:' || rregh.dtvenc_iss);
                    print('ValorLiquidoNfse..........:' || rregh.valorliquidonfse);
                    print('ValorCredito..............:' || rregh.valorcredito);
                    print('Cnpj......................:' || rregh.cnpj);
                    print('CPF.......................:' || rregh.cpf);
                    print('InscricaoMunicipal........:' || rregh.inscricaomunicipal);
                    print('InscricaoEstadual.........:' || rregh.inscricaoestadual);
                    print('Nome......................:' || rregh.nome);
                    print('RazaoSocial...............:' || rregh.razaosocial);
                    print('NomeFantasia..............:' || rregh.nomefantasia);
                    print('Endereco..................:' || rregh.endereco);
                    print('Numero....................:' || rregh.numero);
                    print('Bairro....................:' || rregh.bairro);
                    print('Uf........................:' || rregh.uf);
                    print('Cep.......................:' || rregh.cep);
                    print('Telefone..................:' || rregh.telefone);
                    print('complemento...............:' || rregh.complemento);
                    print('email.....................:' || rregh.email);
                    print('CodigoMunicipio...........:' || rregh.codigomunicipio);
                    print('Municipio.................:' || rregh.municipio);
                    print('Pais......................:' || rregh.pais);
                    print('Tipo_Rps..................:' || rregh.tipo_rps);
                    print('DataEmissao_Rps...........:' || rregh.dataemissao_rps);
                    print('Numero_rps................:' || rregh.numero_rps);
                    print('serie_rps.................:' || rregh.serie_rps);
                    print('Status_Rps................:' || rregh.status_rps);
                    print('Tipo_Rps_Subst............:' || rregh.tipo_rps_subst);
                    print('Competencia...............:' || rregh.competencia);
                    print('ValorServicos.............:' || rregh.valorservicos);
                    print('ValorDeducoes.............:' || rregh.valordeducoes);
                    print('ValorPis..................:' || rregh.valorpis);
                    print('AlqPisPasep...............:' || rregh.alqpispasep);
                    print('ValorCofins...............:' || rregh.valorcofins);
                    print('AlqCofins.................:' || rregh.alqcofins);
                    print('ValorInss_Servico.........:' || rregh.valorinss_servico);
                    print('ValorIr...................:' || rregh.valorir);
                    print('AlqIrrf...................:' || rregh.alqirrf);
                    print('ValorCsll.................:' || rregh.valorcsll);
                    print('VlrIssRetido..............:' || rregh.vlrissretido);
                    print('AlqIssRetido..............:' || rregh.alqissretido);
                    print('AlqCsll...................:' || rregh.alqcsll);
                    print('OutrasRetencoes...........:' || rregh.outrasretencoes);
                    print('ValorIss..................:' || rregh.valoriss);
                    print('DescontoIncondicionado....:' || rregh.descontoincondicionado);
                    print('DescontoCondicionado......:' || rregh.descontocondicionado);
                    print('IssRetido.................:' || rregh.issretido);
                    print('CodTribMuni...............:' || rregh.codtribmuni);
                    print('CodigoMunicipio_Ser.......:' || rregh.codigomunicipio_ser);
                    print('ExigibilidadeISS..........:' || rregh.exigibilidadeiss);
                    print('xDataPaga.................:' || rregh.xdatapaga);
                    print('Cnpj_Emit.................:' || rregh.cnpj_emit);
                    print('CPF_Emit..................:' || rregh.cpf_emit);
                    print('Entity_id.................:' || rregh.entity_id);
                    print('InscricaoMunicipal_P......:' || rregh.inscricaomunicipal_p);
                    print('Cnpj_Dest.................:' || rregh.cnpj_dest);
                    print('InscricaoMunicipal_Dest...:' || rregh.inscricaomunicipal_dest);
                    print('RazaoSocial_Dest..........:' || rregh.razaosocial_dest);
                    print('Endereco_Dest.............:' || rregh.endereco_dest);
                    print('Numero_Dest...............:' || rregh.numero_dest);
                    print('Uf_DesT...................:' || rregh.uf_dest);
                    print('xnomemunicipio............:' || rregh.xnomemunicipio);
                    print('Telefone_Dest.............:' || rregh.telefone_dest);
                    print('Email_Dest................:' || rregh.email_dest);
                    print('xCodEstabTomador..........:' || rregh.xcodestabtomador);
                    print('xNomeEstabTomador.........:' || rregh.xnomeestabtomador);
                    print('OptanteSimplesNacional....:' || rregh.optantesimplesnacional);
                    print('IncentivoFiscal...........:' || rregh.incentivofiscal);
                    print('Serv_list.................:' || rregh.serv_list);
                    print('NumeroNFSeSubstituida.....:' || rregh.numeronfsesubstituida);
                    print('DtPrestacaoServico........:' || rregh.dtprestacaoservico);
                    print('Inter_Cpf.................:' || rregh.inter_cpf);
                    print('Inter_Cnpj................:' || rregh.inter_cnpj);
                    print('Inter_InscricaoMunicipal..:' || rregh.inter_inscricaomunicipal);
                    print('Inter_InscricaoEstadual...:' || rregh.inter_inscricaoestadual);
                    print('Inter_Nome................:' || rregh.inter_nome);
                    print('Inter_RazaoSocial.........:' || rregh.inter_razaosocial);
                    print('Inter_NomeFantasia........:' || rregh.inter_nomefantasia);
                    print('Inter_Endereco............:' || rregh.inter_endereco);
                    print('Inter_Numero..............:' || rregh.inter_numero);
                    print('Inter_Complemento.........:' || rregh.inter_complemento);
                    print('Inter_Bairro..............:' || rregh.inter_bairro);
                    print('Inter_Municipio...........:' || rregh.inter_municipio);
                    print('Inter_Uf..................:' || rregh.inter_uf);
                    print('Inter_Pais................:' || rregh.inter_pais);
                    print('Inter_Cep.................:' || rregh.inter_cep);
                    print('Inter_telefone............:' || rregh.inter_telefone);
                    print('Inter_Email...............:' || rregh.inter_email);
                    print('Inter_Regime..............:' || rregh.inter_regime);
                    print('Inter_CodigoMobiliario....:' || rregh.inter_codigomobiliario);
                    print('toma_Regime...............:' || rregh.toma_regime);
                    print('toma_CodigoMobiliario.....:' || rregh.toma_codigomobiliario);
                    print('Prest_nome................:' || rregh.prest_nome);
                    print('Prest_Regime..............:' || rregh.prest_regime);
                    print('Prest_CodigoMobiliario....:' || rregh.prest_codigomobiliario);
                    print('Discr_servico.............:' || rregh.discr_servico);
                    print('constru_art...............:' || rregh.constru_art);
                    print('constru_cod_obra..........:' || rregh.constru_cod_obra);
                    print('valor_total...............:' || rregh.valor_total);
                    print('desconto..................:' || rregh.desconto);
                    print('Ret_federal...............:' || rregh.ret_federal);
                    print('MunicipioIncidencia.......:' || rregh.municipioincidencia);
                    print('Recolhimento..............:' || rregh.recolhimento);
                    print('Tributacao................:' || rregh.tributacao);
                    print('CNAE......................:' || rregh.cnae);
                    print('DescricaoAtividade........:' || rregh.descricaoatividade);
                    print('DescricaoTipoServico......:' || rregh.descricaotiposervico);
                    print('LocalPrestacao............:' || rregh.localprestacao);
                    print('NaturezaOperacao..........:' || rregh.naturezaoperacao);
                    print('RegimeEspecialTributacao..:' || rregh.regimeespecialtributacao);
                    print('NumeroGuia................:' || rregh.numeroguia);
                    print('Po_num....................:' || rregh.po_num);
                    print('po_item...................:' || rregh.po_item);
                    print('particularidades..........:' || rregh.particularidades);
                    print('Status_nf.................:' || rregh.status_nf);
       -- Print('First_Due_Date............:'||rRegh.xDataPaga                 );
       -- Print('boleto_cod................:'||rRegh.boleto_cod                );
                    print('');

        --
                    l_header.doc_id := g_ctrl_id;
                    l_header.currency_code := rregh.currency_code;
                    l_header.model :=
                        case
                            when rregh.xmodelofiscal = '' then
                                '00'
                            else
                                nvl(rregh.xmodelofiscal, '00')
                        end;

                    l_header.efd_header_id := xxrmais_invoices_s.nextval;
                    l_header.document_number := rregh.numero_nff;
                    g_ctrl.numero := rregh.numero_nff;
                    l_header.cod_verif_nfs := rregh.codigoverificacao;
                    print('rRegh.DataEmissao: ' || rregh.dataemissao);
                    begin
                        l_header.issue_date := to_timestamp_tz ( rregh.dataemissao,
                        'RRRR-MM-DD"T"HH24:MI:SS TZR' );
                        print('debugdata');
                    exception
                        when others then
                            begin
                                l_header.issue_date := to_date ( rregh.dataemissao,
                                'YYYY-MM-DD' );--2022-08-19
                            exception
                                when others then
                                    begin
                                        l_header.issue_date := to_timestamp_tz ( rregh.dataemissao,
                                        'YYYY-MM-DD"T"HH24:MI:SS.FF3 TZR' );
                                    exception
                                        when others then
                                            l_header.issue_date := trunc(to_date(rregh.dataemissao, 'DD/MM/YYYY HH24:MI:SS'));
                                    end;
                            end;

                            print('debugdata2');
                    end;

                    print('debugdata3');
                    l_header.additional_information := rregh.outrasinformacoes;
                    print('debug1');
                    l_header.iss_base :=
                        case
                            when nvl(rregh.valoriss, 0) > 0 then
                                rregh.basecalculo
                            else
                                0
                        end;

                    print('debug00');
                    l_header.net_amount := rregh.valorliquidonfse;
                    print('debug002');
                    l_header.issuer_document_number := nvl(rregh.cnpj, rregh.cpf);
                    l_header.issuer_name := substr(rregh.razaosocial, 1, 45);
        --l_header.issuer_name                   := substr(rRegh.NomeFantasia;
                    l_header.issuer_address := rregh.endereco;
                    l_header.issuer_address_number := rregh.numero;
                    l_header.issuer_address_complement := rregh.bairro;
                    l_header.issuer_address_state := rregh.uf;
                    l_header.issuer_address_zip_code := rregh.cep;
                    l_header.issuer_address_city_code := rregh.codigomunicipio;
                    l_header.issuer_address_city_name := rregh.municipio;
                    l_header.competencia_nfs := rregh.competencia;
                    l_header.total_amount :=
                        case
                            when nvl(rregh.valorservicos, 0) = 0 then
                                rregh.valor_total
                            else
                                rregh.valorservicos
                        end;

                    l_header.pis_amount := rregh.valorpis;
                    l_header.cofins_amount := rregh.valorcofins;
                    l_header.inss_amount := rregh.valorinss_servico;
                    l_header.ir_amount := rregh.valorir;
                    l_header.iss_amount := rregh.valoriss;
                    print('debug2');
                    l_header.iss_tax := rregh.aliquota;
        --
                    l_header.iss_ret_flag :=
                        case
                            when nvl(rregh.issretido, 'false') in ( 'true', 'Y' ) then
                                'Y'
                            else
                                null
                        end;
        --
                    l_header.csll_amount := rregh.valorcsll;
                    l_header.municipio_incidencia := rregh.codigomunicipio_ser;
                    l_header.incricao_obra := rregh.constru_cod_obra;
                    l_header.tributos_aproximados := rregh.tributacao;
                    l_header.fonte := null;
        
        --g_source.inscricaomunicipal_emit       := rRegh.InscricaoMunicipal;
        -- g_source.cliente_id                    := g_ctrl.id;
        --g_source.valorcredito                  := rRegh.ValorCredito;
        -- g_source.telefone_emit                 := rRegh.Telefone;
        --g_source.valordeducoes                 := rRegh.ValorDeducoes;
        --g_source.valorcsll                     := rRegh.ValorCsll;
        --g_source.vlrissretido                  := rRegh.VlrIssRetido;
        --g_source.alqissreti                    := rRegh.AlqIssRetido;
        --g_source.outrasretencoes               := rRegh.OutrasRetencoes;
        --g_source.descontoincondicio            := rRegh.DescontoIncondicionado;
        --g_source.descontocondicio              := rRegh.DescontoCondicionado;
        --Print('Error;?_'||rRegh.IssRetido);
        --g_source.issretido                     := rRegh.IssRetido;
        --     rmais_efd_headers_hdi
        --g_source.receiver_name                 := rRegh.RazaoSocial_Dest;
       -- g_source.telefone_dest                 := rRegh.Telefone_Dest;
       -- g_source.email_dest                    := rRegh.Email_Dest;
        --g_source.codestabtomador               := rRegh.xCodEstabTomador;
        --g_source.incentivofiscal               := rRegh.IncentivoFiscal;
        -- INFORMACAO DA LINHA????????
        --l_header.codigomunicipio_serv          := rRegh.CodigoMunicipio_Ser;
        --
        --l_header.serv_code                     := rRegh.Serv_list;
        --
        --????????????
        --l_header.inscricaomunicipal_dest       := nvl(rRegh.InscricaoMunicipal_P , rRegh.InscricaoMunicipal_Dest);
                    l_header.receiver_mun_registration := rregh.inscricaomunicipal_p;
                    l_header.receiver_document_number := nvl(rregh.cnpj_dest, rregh.cpf_emit);
                    l_header.receiver_address := rregh.endereco_dest;
                    l_header.first_due_date := to_date ( rregh.xdatapaga,
                    'YYYY-MM-DD' );
                    l_header.boleto_cod := rregh.boleto_cod;
                    l_header.chave_pix := rregh.chave_pix;
                    print('debug 3a');
                    l_header.receiver_address_number := rregh.numero_dest;
                    l_header.receiver_address_state := rregh.uf_dest;
                    l_header.receiver_address_city_name := rregh.xnomemunicipio;
                    l_header.receiver_name := substr(rregh.xnomeestabtomador, 1, 60);
                    print('debug3b');
                    print('rRegh.OptanteSimplesNacional: ' || rregh.optantesimplesnacional);
        --
        --print(length (CASE WHEN nvl(rRegh.OptanteSimplesNacional,'NAO DEFINIDO') = 'NAO DEFINIDO' THEN '' ELSE case when rRegh.OptanteSimplesNacional = 'true' then 'Y' else rRegh.OptanteSimplesNacional END END ));
                    l_header.simple_national_indicator :=
                        case
                            when upper(nvl(rregh.optantesimplesnacional, 'NAO DEFINIDO')) in ( 'NAO DEFINIDO', 'FALSE' ) then
                                ''
                            else
                                case
                                    when upper(rregh.optantesimplesnacional) in ( 'TRUE', 'S', 'Y', 'SIM', 'YES' ) then
                                            'Y'
                                    else
                                        ''
                                end
                        end;
        --l_header.document_status               := 'N';
        --l_header.access_key_number             := lpad(LPAD(nvl(rRegh.Cnpj_Dest,rRegh.CPF_Emit),15,'0')||LPAD(nvl(rRegh.Cnpj,rRegh.CPF),15,'0')||to_char(l_header.issue_date,'YYYYMM')||LPAD(rRegh.Numero_Nff,8,'0'),44,'0');
                    print('debug4');
                    print(' l_header.issue_date: ' || l_header.issue_date);
        --
                    l_header.access_key_number := get_access_key_number(
                        nvl(rregh.cnpj_dest, rregh.cpf_emit),
                        nvl(rregh.cnpj, rregh.cpf),
                        l_header.issue_date,
                        rregh.numero_nff
                    );
        --

                    print('Chave NFSe: ' || l_header.access_key_number);
        --
                    g_ctrl.eletronic_invoice_key := l_header.access_key_number;
        --
        --
                    l_header.creation_date := sysdate;
                    l_header.created_by := '-1';
                    l_header.last_update_date := sysdate;
                    l_header.last_updated_by := '-1';
                    g_ctrl.status := 'P';
        --
                    l_header.blob_filename := p_filename;
                    l_header.blob_file := p_file;
        --  
                    if p_process not like '%POC%' then
                        valid_org(
                            nvl(rregh.cnpj_dest, rregh.cpf_emit),
                            g_ctrl.status
                        );
                    end if;
        --
                    l_header.poc :=
                        case
                            when p_process like '%POC%' then
                                p_process
                            else
                                null
                        end;
                    l_header.document_status := 'I';
                    if nvl(g_ctrl.status, 'P') <> 'E' then
          --
                        if nvl(rregh.status_nf, 'N') = 'C' then
            --
                            g_ctrl.status := 'C';
            --
                            begin
              --
                                insert into rmais_black_list_cancel values ( l_header.access_key_number,
                                                                             sysdate );
              --
                            exception
                                when others then
                                    null;--
                            end;
            --
                        end if;
            --
                        back_list(l_header.document_status, l_header.access_key_number);
            --
            -- Buscando BU_NAME na integração
                        begin
              --
                            l_header.bu_name := json_value(rmais_process_pkg.get_taxpayer(l_header.receiver_document_number, 'RECEIVER'
                            ),
           '$.DATA.BU_NAME');
              --
                            print('BU_NAME: '
                                  || l_header.bu_name
                                  || 'CNPJ: ' || l_header.receiver_document_number);
              --
                        exception
                            when others then
              --
                                print('Não foi possível identificar a BU_NAME' || sqlerrm, 2);
              --
                        end;
            --
                        begin
             --
                            insert into rmais_efd_headers_hdi values l_header;
            --
                            print('Inserindo Header id: ' || l_header.efd_header_id);
            --Print('---Registros inseridos---');
            --
                        exception
                            when dup_val_on_index then
              --
                                if nvl(g_ctrl.status, 'N') = 'C' then
                --
                                    print('***** Documento Cancelado *****');
                --
                                    begin
                  --
                                        update rmais_efd_headers_hdi
                                        set
                                            document_status =
                                                case
                                                    when document_status in ( 'T', 'UP' ) then
                                                        'X'
                                                    else
                                                        'C'
                                                end
                                        where
                                            access_key_number = l_header.access_key_number
                                        returning document_status into l_document_status;
                  --
                --   if l_document_status = 'X' then
                --     if rmais_process_pkg.Cancel_NF_ERP(p_header_id => l_header.efd_header_id) is null then
                --         null;
                --     end if;
                --   end if;
                  --
                                    exception
                                        when others then
                                            print('Erro ao atualizar status: ' || sqlerrm);
                                    end;
                --
                                else
              --
                                    g_ctrl.status := 'D';
              --
                                    print('***** Documento já integrado *****' || sqlerrm);
              --
                                end if;
              --
                            when others then
            --
                                print('Erro ao inserir rmais_efd_headers_hdi' || sqlerrm);
            --
            --
                                g_ctrl.status := 'E';
            --
                        end;
          --
                    else
          --
                        print('Não foi possível inserir registro STATUS: ' || g_ctrl.status);
          --
                    end if;
        --
        --
                    begin
                        begin
                            select
                                source
                            into xlinc
                            from
                                rmais_source_ctrl a --FOR UPDATE
                            where
                                    control = l_layout || '_LINES'
                                and context = 'LAYOUT';
          --
                            print('Encontrado Layout Linha: '
                                  || l_layout || '_LINES');
          --
                        exception
                            when others then
                                print('Não encontrado template de linhas');
                        end;
        --
         --
                        if l_layout like 'NFSE_%'
                           or l_layout = 'NF3E_GOIANIA' then
          --
                            print('RECEBENDO CONTEUDO xml');
          --
                            rregh.itens := l_xml;
          --
                        end if;
        --
        --
                        vidx := 1;
        --
        --
       /* declare
        l_c clob;
        begin
        l_c := rRegh.Itens.getclobval();
        print('XML LINHA:');
        dbms_output.put_line(l_c);
        print('XML LINHA final');
        end;
        */
        --
                        open clin for xlinc
                            using rregh.itens;

                        loop
          --
          --
                            begin
            --
                                begin
              --
                                    fetch clin into rlin;
              --
                                exception
                                    when others then
                                        print('Fech Error NFSE lines ' || sqlerrm);
                                end;
            --
                                print('Numeros de linha ' || vidx);
                                if vidx > 1 then
              --
                                    print('WARNING: NFSe Possui mais de uma linha... Verificar codificação');
              --
                                end if;
            --
                                if vidx = 1 then
                                    print(' ');
                                    print('Pedido....................: ' || rlin.pedido);
                                    print('Line_num..................: ' || rlin.line_num);
                                    print('xCod_Produto..............: ' || rlin.xcod_produto);
                                    print('xDes_Produto..............: ' || substr(rlin.xdes_produto, 1, 120));
                                    print('Uom.......................: ' || rlin.uom);
                                    print('Qtde_Lin..................: ' || rlin.vqtde);
                                    print('Valor_Un..................: ' || rlin.valor_un);
                                    print('Valor_Tot.................: ' || rlin.valor_tot);
              --
                                    print('Carregando informações das Linhas da NFSe');
              --
            -- SELECT * FROM rmais_efd_lines_hdi
                                    l_lines.efd_line_id := rmais_efd_lines_s.nextval;
                                    l_lines.efd_header_id := l_header.efd_header_id;
                                    l_lines.line_number := rlin.line_num;
                                    l_lines.item_code := rlin.xcod_produto;
              --print('TRAT: '||SUBSTR(rLin.xDes_Produto,1,10));
              --Print('STRAT: '||rLin.xDes_Produto);--rRegh.OutrasInformacoes rLin.xDes_Produto
                                    l_lines.item_description := substr(rlin.xdes_produto, 1, 110);--print('Error'||rLin.xDes_Produto);
            --rmais_efd_lines_hdi
                                    print('Debug1');
                                    l_lines.source_doc_number := nvl(rlin.pedido,
                                                                     get_po_description_invoice(
                                                                                                         p_value1 => rlin.xdes_produto
                                                                                                         ,
                                                                                                         p_value2 => rregh.outrasinformacoes
                                                                                                     ));

                                    print('Debug1b');
                                    l_lines.uom_to := rlin.uom;
                                    l_lines.line_quantity := rlin.vqtde;
                                    l_lines.unit_price := rlin.valor_un;
                                    l_lines.line_amount := rlin.valor_tot;
                                    print('Debug2');
                                    l_lines.city_service_type_rel_code := get_cod_serv_expecific(rregh.codigomunicipio, rregh.serv_list
                                    );
                                    l_lines.fiscal_classification := get_cod_serv_expecific(rregh.codigomunicipio, rregh.serv_list);
              --
                                    print('Debug1');
                                    l_lines.creation_date := sysdate;
                                    l_lines.created_by := -1;
                                    l_lines.last_update_date := sysdate;
                                    l_lines.last_updated_by := -1;
              --
                                    print('efd_line_id' || l_lines.efd_line_id);
                                    print('Inserindo efd_line_id: ' || l_lines.efd_line_id);
              --
                                    if nvl(g_ctrl.status, 'P') not in ( 'C', 'D', 'E' ) then
                --
                                        begin
                  --
                                            insert into rmais_efd_lines_hdi values l_lines;
                  --
                                            print('Registro inserido LINE_ID: ' || l_lines.efd_line_id);
                  --
                                            g_ctrl.status := 'P';
                  --
                                        exception
                                            when others then
                  --
                                                print('Erro ao inserir linhas' || sqlerrm);
                  --
                                                g_ctrl.status := 'E';
                  --
                                        end;
                --
                                    else
                --
                                        print('Linhas descartadas, documentos com status: ' || g_ctrl.status);
                --
                                    end if;
              --
                                end if;
            --
            --
                            exception
                                when others then
                                    print('Falha ao carregar Linhas da Interface >> ' || sqlerrm);
              --Insert_File_Error ( rSource.rCtrl.Filename, 'Falha ao carregar Linhas do XML >> '||sqlerrm);
                            end;
          --
                            vidx := vidx + 1;
                            exit when clin%notfound;
          --
                        end loop;
        --
                        close clin;
        --
                        if nvl(
                            length(l_header.blob_file),
                            0
                        ) = 0 then
                            l_resp_link_nfse := rmais_util_pkg_poc.get_link_nfse(l_header.efd_header_id); -- Robson 23/03/2023 start
                        else
                            l_resp_link_nfse := 1;
                        end if;
        --
                        if l_resp_link_nfse is null then
                            update rmais_efd_headers_hdi
                            set
                                document_status = 'FA'
                            where
                                efd_header_id = l_header.efd_header_id;

                        else -- Robson 23/03/2023 end 
                            begin
              --commit;
                                print('Call main - 1-ini *************************************************************************************'
                                );
              --rmais_process_pkg.main(p_header_id => l_header.efd_header_id , p_flag_auto => 'Y', p_send_erp => 'Y');
                                print('Call main - 1-ter *************************************************************************************'
                                );
                                commit;
                            exception
                                when others then
              --raise_application_error (-20011,'Erro ao reprocessar documento '||sqlerrm);
                                    null;
                            end;
                        end if;
        --vIDX := rSource.rLines.count;
        --
                    end;
        --Insert_Interface(rSource);
        --
                exception
                    when others then
          --apps.xxrmais_global_pkg.g_Retcode := retcode_f;
          --apps.xxrmais_global_pkg.g_Errbuf := 'Erro ao processar arquivo ('||rSource.rCtrl.Filename||') '||SQLERRM;
          --Insert_File_Error (rSource.rCtrl.Filename, apps.xxrmais_global_pkg.g_Errbuf);
                        print('Erro ao processar documento: ' || sqlerrm);
                        g_ctrl.status := 'E';
                end;
      --
     -- FIM(rSource, apps.xxrmais_global_pkg.g_Retcode);
      --
            end if;  -- Directory_Name
    --
    --Finalizar;
    --
        exception
            when others then
      --apps.xxrmais_global_pkg.g_Retcode := retcode_f;
      --apps.xxrmais_global_pkg.g_Errbuf  := 'FALHA GERAL (NFSE): '||SQLERRM;
                print('FALHA GERAL (NFSE): ' || sqlerrm);
                g_ctrl.status := 'E';
        end load_read_file_xml_nfse;
  --
  --SELECT * FROM all_directories WHERE directory_name =  'RMAIS_ERROR_18182137000170'
    --
        procedure load_nfe (
            p_xml      clob,
            p_filename in rmais_efd_headers_hdi.blob_filename%type default null,
            p_file     in rmais_efd_headers_hdi.blob_file%type default null
        ) is
    --    l_filename rmais_efd_headers_hdi.BLOB_FILENAME%type;
            l_file               rmais_efd_headers_hdi.blob_file%type;
            vidx                 number;
            l_ctrbr              number;
    --
            l_xml                clob;
    --
            l_id_header          number;
            l_unic_line_danfe_df number := rmais_process_pkg.get_parameter('UNIC_LINE_DANFE_DF');
        begin
    
    --
            begin
        --
                print('Processando Arquivo NFe... ' || to_char(sysdate, 'DD/MM/RRRR HH24:MI:SS'));
        --
                l_xml := replace(p_xml, '¿<?xml version="1.0" encoding="UTF-8"?>', '');
        --
                l_xml := replace(l_xml, '¿<?xml version="1.0" encoding="UTF-8" ?><nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
                , '<nfeProc versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe">');
        --
                l_xml := replace(l_xml, '<?xml version="1.0" encoding="UTF-8" ?><nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
                , '<nfeProc versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe">');
        --
                l_xml := replace(l_xml, '<protNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">', '<protNFe versao="4.00">)'
                );
        --
        --
                l_xml := replace(l_xml, '¿<', '<');
        --
        --
        ---------------------------------------
        -- dados do cabeçalho da nota fiscal --
        ---------------------------------------
                for regc in (
                    select
                        xnf.*,
                        (
                            select
                                regexp_replace(
                                    listagg(refkeynf, ';') within group(
                                    order by
                                        refkeynf
                                    ),
                                    '([^;]+)(;\1)*(;|$)',
                                    '\1\3') refkeynf
                            from
                                xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/nfe' ),
                                '/nfeProc/NFe/infNFe/ide/NFref'
                                        passing xmltype(l_xml)
                                    columns
                                        refkeynf varchar2(150) path '/NFref/refNFe/text()'
                                )
                        ) refkeynf
                    from
                        xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/nfe' ),
                        '/nfeProc'
                                passing xmltype(l_xml)
                            columns
                                serie varchar2(150) path '/nfeProc/NFe/infNFe/ide/serie/text()',
                                modelo varchar2(100) path '/nfeProc/NFe/infNFe/ide/mod/text()',
                                indpag varchar2(020) path '/nfeProc/NFe/infNFe/ide/indPag/text()',
                                natop varchar2(020) path '/nfeProc/NFe/infNFe/ide/natOp/text()',
                                versao varchar2(100) path '/nfeProc/NFe/infNFe/@versao',
                                num_nf varchar2(150) path '/nfeProc/NFe/infNFe/ide/nNF/text()',
                                tiponf varchar2(150) path '/nfeProc/NFe/infNFe/ide/tpNF/text()',
                                finnf varchar2(150) path '/nfeProc/NFe/infNFe/ide/finNFe/text()',
                                tpemis varchar2(150) path '/nfeProc/NFe/infNFe/ide/tpEmis/text()',
                                danfe varchar2(200) path '/nfeProc/protNFe/infProt/chNFe/text()',
                                recebto varchar2(200) path '/nfeProc/protNFe/infProt/dhRecbto/text()',
                                usage_auth varchar2(200) path '/nfeProc/protNFe/infProt/cStat/text()',
                                xtiponf varchar2(100) path '/nfeProc/Integracao/xTipoNF/text()',
                                xoperfiscal varchar2(100) path '/nfeProc/Integracao/xTipoOperFiscal/text()',
                                xmodelo varchar2(100) path '/nfeProc/Integracao/xModeloFiscal/text()',
                                emissao varchar2(200) path '/nfeProc/NFe/infNFe/ide/dhEmi/text()',
                                v_prod number path '/nfeProc/NFe/infNFe/total/ICMSTot/vProd/text()',
                                v_total_nf number path '/nfeProc/NFe/infNFe/total/ICMSTot/vNF/text()',
                                v_b_icms number path '/nfeProc/NFe/infNFe/total/ICMSTot/vBC/text()',
                                v_vl_icms number path '/nfeProc/NFe/infNFe/total/ICMSTot/vICMS/text()',
                                v_bst_icms number path '/nfeProc/NFe/infNFe/total/ICMSTot/vBCST/text()',
                                v_st_icms number path '/nfeProc/NFe/infNFe/total/ICMSTot/vST/text()',
                                v_frete number path '/nfeProc/NFe/infNFe/total/ICMSTot/vFrete/text()',
                                v_desconto number path '/nfeProc/NFe/infNFe/total/ICMSTot/vDesc/text()',
                                vseg number path '/nfeProc/NFe/infNFe/total/ICMSTot/vSeg/text()',
                                vipi number path '/nfeProc/NFe/infNFe/total/ICMSTot/vIPI/text()',
                                vpis number path '/nfeProc/NFe/infNFe/total/ICMSTot/vPIS/text()',
                                vcofins number path '/nfeProc/NFe/infNFe/total/ICMSTot/vCOFINS/text()',
                                vfcpufdest number path '/nfeProc/NFe/infNFe/total/ICMSTot/vFCPUFDest/text()',
                                vicmsufdest number path '/nfeProc/NFe/infNFe/total/ICMSTot/vICMSUFDest/text()',
                                vicmsufremet number path '/nfeProc/NFe/infNFe/total/ICMSTot/vICMSUFRemet/text()',
                                v_outras_des number path '/nfeProc/NFe/infNFe/total/ICMSTot/vOutro/text()',
                                ir_base number path '/nfeProc/NFe/infNFe/total/retTrib/vBCIRRF/text()',
                                ir_amount number path '/nfeProc/NFe/infNFe/total/retTrib/vIRRF/text()',
                                iss_base number path '/nfeProc/NFe/infNFe/total/ISSQNtot/vBC/text()',
                                iss_amount number path '/nfeProc/NFe/infNFe/total/ISSQNtot/vISS/text()',
                                iss_amount_a number path '/nfeProc/NFe/infNFe/total/ISSQNtot/vISSRet/text()' -- Robson 16/03/2023
                                ,
                                iss_tax number path '/nfeProc/NFe/infNFe/imposto/ISSQN/vAliq/text()' -- Verificar com Victor (Robson)
                                ,
                                modfrete number path '/nfeProc/NFe/infNFe/transp/modFrete/text()',
                                transp_cpf varchar2(100) path '/nfeProc/NFe/infNFe/transp/transporta/CPF/text()',
                                transp_cnpj varchar2(100) path '/nfeProc/NFe/infNFe/transp/transporta/CNPJ/text()',
                                transp_uf varchar2(100) path '/nfeProc/NFe/infNFe/transp/transporta/UF/text()',
                                transp_ie varchar2(100) path '/nfeProc/NFe/infNFe/transp/transporta/IE/text()',
                                transp_xnome varchar2(100) path '/nfeProc/NFe/infNFe/transp/transporta/xNome/text()',
                                crt varchar2(200) path '/nfeProc/NFe/infNFe/emit/CRT/text()',
                                cnpj_for varchar2(200) path '/nfeProc/NFe/infNFe/emit/CNPJ/text()',
                                cpf_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/CPF/text()',
                                nome_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/xNome/text()',
                                uf_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/enderEmit/UF/text()',
                                cmun_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/enderEmit/cMun/text()',
                                xmun_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/enderEmit/xMun/text()',
                                xlgr_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/enderEmit/xLgr/text()',
                                nro_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/enderEmit/nro/text()',
                                xcpl_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/enderEmit/xCpl/text()',
                                cep_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/enderEmit/CEP/text()'
                         --, Entity_id    NUMBER           Path '/nfeProc/NFe/infNFe/emit/InfTrad/xCodFornecedor/text()'
                                ,
                                cnpj_emp varchar2(200) path '/nfeProc/NFe/infNFe/dest/CNPJ/text()',
                                cpf_dest varchar2(200) path '/nfeProc/NFe/infNFe/dest/CPF/text()',
                                nome_dest varchar2(200) path '/nfeProc/NFe/infNFe/dest/xNome/text()',
                                uf_dest varchar2(200) path '/nfeProc/NFe/infNFe/dest/enderDest/UF/text()',
                                cmun_dest varchar2(200) path '/nfeProc/NFe/infNFe/dest/enderDest/cMun/text()',
                                xmun_dest varchar2(200) path '/nfeProc/NFe/infNFe/dest/enderDest/xMun/text()',
                                xlgr_dest varchar2(200) path '/nfeProc/NFe/infNFe/dest/enderDest/xLgr/text()',
                                nro_dest varchar2(200) path '/nfeProc/NFe/infNFe/dest/enderDest/nro/text()',
                                xcpl_dest varchar2(200) path '/nfeProc/NFe/infNFe/dest/enderDest/xCpl/text()',
                                cep_dest varchar2(200) path '/nfeProc/NFe/infNFe/dest/enderDest/CEP/text()'
                         --, Org_Code     VARCHAR2(200)    Path '/nfeProc/NFe/infNFe/dest/InfTrad/xCodEstabelecimento/text()'
                                ,
                                shipfr_cnpj varchar2(200) path '/nfeProc/NFe/infNFe/retirada/CNPJ/text()',
                                shipfr_cpf varchar2(200) path '/nfeProc/NFe/infNFe/retirada/CPF/text()',
                                shipfr_uf varchar2(200) path '/nfeProc/NFe/infNFe/retirada/UF/text()',
                                shipfr_cmun varchar2(200) path '/nfeProc/NFe/infNFe/retirada/cMun/text()',
                                shipfr_xmun varchar2(200) path '/nfeProc/NFe/infNFe/retirada/xMun/text()',
                                shipfr_xlgr varchar2(200) path '/nfeProc/NFe/infNFe/retirada/xLgr/text()',
                                shipfr_nro varchar2(200) path '/nfeProc/NFe/infNFe/retirada/nro/text()',
                                shipfr_xcpl varchar2(200) path '/nfeProc/NFe/infNFe/retirada/xCpl/text()',
                                shipto_cnpj varchar2(200) path '/nfeProc/NFe/infNFe/entrega/CNPJ/text()',
                                shipto_cpf varchar2(200) path '/nfeProc/NFe/infNFe/entrega/CPF/text()',
                                shipto_uf varchar2(200) path '/nfeProc/NFe/infNFe/entrega/UF/text()',
                                shipto_cmun varchar2(200) path '/nfeProc/NFe/infNFe/entrega/cMun/text()',
                                shipto_xmun varchar2(200) path '/nfeProc/NFe/infNFe/entrega/xMun/text()',
                                shipto_xlgr varchar2(200) path '/nfeProc/NFe/infNFe/entrega/xLgr/text()',
                                shipto_nro varchar2(200) path '/nfeProc/NFe/infNFe/entrega/nro/text()',
                                shipto_xcpl varchar2(200) path '/nfeProc/NFe/infNFe/entrega/xCpl/text()'
                         --, CondPagto    VARCHAR2(200)    Path '/nfeProc/NFe/infNFe/cobr/InfTrad/xCondPagto/text()'
                                ,
                                comments clob path '/nfeProc/NFe/infNFe/infAdic/infCpl/text()'
                        ) xnf
                ) loop
          --
                    print('Carregando Cabeçalho da NF...');
          --
                    print('NFe '
                          ||
                        case regc.tiponf
                            when 0 then
                                'Entrada'
                            when 1 then
                                'Saída '
                        end
                          ||
                        case regc.finnf
                            when 1 then
                                'Normal '
                            when 2 then
                                'Complementar '
                            when 4 then
                                'Devolução/Retorno '
                        end
                    );
          --
                    print('Serie.....................: ' || regc.serie);
                    print('Modelo....................: ' || regc.modelo);
                    print('indPag....................: ' || regc.indpag);
                    print('Versao....................: ' || regc.versao);
                    print('num_nf....................: ' || regc.num_nf);
                    print('TipoNF....................: ' || regc.tiponf);
                    print('FinNF.....................: ' || regc.finnf);
                    print('tpEmis....................: ' || regc.tpemis);
                    print('Danfe.....................: ' || regc.danfe);
                    print('Recebto...................: ' || regc.recebto);
                    print('Usage_Auth................: ' || regc.usage_auth);
                    print('Emissao...................: ' || regc.emissao);
                    print('V_Prod....................: ' || regc.v_prod);
                    print('V_Total_Nf................: ' || regc.v_total_nf);
                    print('V_B_Icms..................: ' || regc.v_b_icms);
                    print('V_Vl_Icms.................: ' || regc.v_vl_icms);
                    print('V_Bst_Icms................: ' || regc.v_bst_icms);
                    print('V_St_Icms.................: ' || regc.v_st_icms);
                    print('V_Frete...................: ' || regc.v_frete);
                    print('V_Desconto................: ' || regc.v_desconto);
                    print('vSeg......................: ' || regc.vseg);
                    print('vIpi......................: ' || regc.vipi);
                    print('vPis......................: ' || regc.vpis);
                    print('vCofins...................: ' || regc.vcofins);
                    print('vFCPUFDest................: ' || regc.vfcpufdest);
                    print('vICMSUFDest...............: ' || regc.vicmsufdest);
                    print('vICMSUFRemet..............: ' || regc.vicmsufremet);
                    print('V_Outras_Des..............: ' || regc.v_outras_des);
                    print('IR_Base...................: ' || regc.ir_base);
                    print('IR_Amount.................: ' || regc.ir_amount);
                    print('ISS_Base..................: ' || regc.iss_base);
                    print('ISS_Amount................: ' || regc.iss_amount);
                    print('ISS_Amount_a..............: ' || regc.iss_amount_a);
                    print('ISS_Tax...................: ' || regc.iss_tax);
                    print('modFrete..................: ' || regc.modfrete);
                    print('transp_CPF................: ' || regc.transp_cpf);
                    print('transp_CNPJ...............: ' || regc.transp_cnpj);
                    print('transp_UF.................: ' || regc.transp_uf);
                    print('transp_IE.................: ' || regc.transp_ie);
                    print('CRT.......................: ' || regc.crt);
                    print('Cnpj_For..................: ' || regc.cnpj_for);
                    print('CPF_Emit..................: ' || regc.cpf_emit);
                    print('Nome_Emit.................: ' || regc.nome_emit);
                    print('UF_Emit...................: ' || regc.uf_emit);
                    print('cMun_Emit.................: ' || regc.cmun_emit);
                    print('xMun_Emit.................: ' || regc.xmun_emit);
                    print('xLgr_Emit.................: ' || regc.xlgr_emit);
                    print('nro_Emit..................: ' || regc.nro_emit);
                    print('xCpl_Emit.................: ' || regc.xcpl_emit);
                    print('CEP_Emit..................: ' || regc.cep_emit);
        --Print('Entity_id.................: '||Regc.Entity_id);
                    print('Cnpj_Emp..................: ' || regc.cnpj_emp);
                    print('Cpf_Dest..................: ' || regc.cpf_dest);
                    print('Nome_Dest.................: ' || regc.nome_dest);
                    print('UF_Dest...................: ' || regc.uf_dest);
                    print('cMun_Dest.................: ' || regc.cmun_dest);
                    print('xMun_Dest.................: ' || regc.xmun_dest);
                    print('xLgr_Dest.................: ' || regc.xlgr_dest);
                    print('nro_Dest..................: ' || regc.nro_dest);
                    print('xCpl_Dest.................: ' || regc.xcpl_dest);
                    print('CEP_Dest..................: ' || regc.cep_dest);
        --Print('Org_Code..................: '||Regc.Org_Code);
                    print('ShipFr_Cnpj...............: ' || regc.shipfr_cnpj);
                    print('ShipFr_CPF................: ' || regc.shipfr_cpf);
                    print('ShipFr_UF.................: ' || regc.shipfr_uf);
                    print('ShipFr_cMun...............: ' || regc.shipfr_cmun);
                    print('ShipFr_xMun...............: ' || regc.shipfr_xmun);
                    print('ShipFr_xLgr...............: ' || regc.shipfr_xlgr);
                    print('ShipFr_nro................: ' || regc.shipfr_nro);
                    print('ShipFr_xCpl...............: ' || regc.shipfr_xcpl);
                    print('ShipTo_Cnpj...............: ' || regc.shipto_cnpj);
                    print('ShipTo_CPF................: ' || regc.shipto_cpf);
                    print('ShipTo_UF.................: ' || regc.shipto_uf);
                    print('ShipTo_cMun...............: ' || regc.shipto_cmun);
                    print('ShipTo_xMun...............: ' || regc.shipto_xmun);
                    print('ShipTo_xLgr...............: ' || regc.shipto_xlgr);
                    print('ShipTo_nro................: ' || regc.shipto_nro);
                    print('ShipTo_xCpl...............: ' || regc.shipto_xcpl);
          --Print('CondPagto.................: '||Regc.CondPagto);
                    print('Comments..................: ' || regc.comments);
          --
                    for regfrt in (
                        select
                            *
                        from
                            xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/nfe' ),
                            '/nfeProc/NFe/infNFe/transp/vol'
                                    passing xmltype(l_xml)
                                columns
                                    frtesp varchar2(200) path '/vol/esp/text()',
                                    frtpesobr number path '/vol/pesoB/text()'
                            ) frt
                    ) loop
            --
                        print('FrtEsp....................: ' || regfrt.frtesp);
                        print('FrtPesoBr.................: ' || regfrt.frtpesobr);
            --
                        if regc.modfrete = 1 then
              --
                            print('Modelo de FRETE: 1');
              --
                        end if;
            --
                    end loop;
          --
          -- NF Entrada Complementar - Validar Tipo NF payment_flag = 'Y' and parent_flag = 'Y' and credit_debit_flag = 'D' and freight_flag = 'N' and triangle_operation = 'N' and operation_type = 'E' and return_customer_flag = 'N' and foreign_currency_usage = 'N' and generate_return_invoice = 'N'
          -- NF Entrada Normal com PO  - Validar Tipo NF - o  Requisition_type =  'PO' and payment_flag = 'S' and parent_flag = 'N' and credit_debit_flag = 'D' and freight_flag = 'N' and triangle_operation = 'N' and operation_type = 'E' and return_flag = 'N' and bonus_flag = 'N' and import_icms_flag = 'N' and include_iss_flag = 'S' (se <nfeProc><<Nfe><infNFe><total>< ISSQNtot><vISS> for maior que 0,00, caso contrário, include_iss_flag = 'N')  and return_customer_flag = 'N' and foreign_currency_usage = 'N' and generate_return_invoice = 'N' and inss_calculation_flag = 'N' and include_icms_flag = 'S' (se <nfeProc><NFe><infNFe><total><ICMSTot><vICMS> for > '0,00', caso contrário include_icms_flag = 'N') and include_ipi_flag = 'S' (se <nfeProc><NFe><infNFe><total><ICMSTot><vIPI> for > '0,00', caso contrário include_ipi_flag = 'N' PO_HEADERS_ALL.TYPE_LOOKUP_CODE = `STANDARD, BLANKET, PLANNED¿
          -- NF Entrada Devolução/Retorno - Validar Tipo NF requisition_type = 'PO'ou 'NA' and payment_flag = 'S' and parent_flag = 'N'  and price_adjust_flag = 'N' and tax_adjust_flag = 'N' freight_flag = 'N' and triangle_operation = 'N' and return_flag = 'S' and bonus_flag = 'N' and cost_adjust_flag = 'N' and import_icms_flag = 'N' and return_customer_flag = 'N' and foreign_currency_usage = 'N' and generate_return_invoice = 'N' and inss_calculation_flag = 'N' RETURN_CFO_ID, RETURN_AMOUNT, RETURN_DATE E RETURN_SERIES passam a ser obrigatórios e precisam ser preenchidos pelo usuário.
          --
        /*IF Regc.tpEmis =  1   AND  --Emissão normal (não em contingência)
             Regc.Modelo = '55' AND  --NFe
             Regc.FinNF  =  4   AND  --Devolução/Retorno
             Regc.TipoNF =  1   THEN --Saída
             --
             Insert_File_Error (rFile.name, 'Devolução de NF de Saída não contemplado!');
             --
          END IF;*/
          --
         --Print('Modelo....................: '||Regc.Modelo);  tipo de documento
                    print('indPag....................: ' || regc.indpag);
                    print('natOp.....................: ' || regc.natop);
                    print('Versao....................: ' || regc.versao);
                    print('TipoNF....................: ' || regc.tiponf);
                    print('FinNF.....................: ' || regc.finnf);
                    print('tpEmis....................: ' || regc.tpemis);
                    print('Danfe.....................: ' || regc.danfe);
                    print('Recebto...................: ' || regc.recebto);
                    print('Usage_Auth................: ' || regc.usage_auth);
                    print('xTipoNF...................: ' || regc.xtiponf);
                    print('xOperFiscal...............: ' || regc.xoperfiscal);
                    print('xModelo...................: ' || regc.xmodelo);
                    print('Emissao...................: ' || regc.emissao);
                    print('V_Prod....................: ' || regc.v_prod);
                    print('V_Total_Nf................: ' || regc.v_total_nf);
                    print('V_B_Icms..................: ' || regc.v_b_icms);
                    print('V_Vl_Icms.................: ' || regc.v_vl_icms);
                    print('V_Bst_Icms................: ' || regc.v_bst_icms);
                    print('V_St_Icms.................: ' || regc.v_st_icms);
                    print('V_Frete...................: ' || regc.v_frete);
                    print('V_Desconto................: ' || regc.v_desconto);
                    print('vSeg......................: ' || regc.vseg);
                    print('vIpi......................: ' || regc.vipi);
                    print('vPis......................: ' || regc.vpis);
                    print('vCofins...................: ' || regc.vcofins);
                    print('vFCPUFDest................: ' || regc.vfcpufdest);
                    print('vICMSUFDest...............: ' || regc.vicmsufdest);
                    print('vICMSUFRemet..............: ' || regc.vicmsufremet);
                    print('V_Outras_Des..............: ' || regc.v_outras_des);
                    print('IR_Base...................: ' || regc.ir_base);
                    print('IR_Amount.................: ' || regc.ir_amount);
                    print('ISS_Base..................: ' || regc.iss_base);
                    print('ISS_Amount................: ' || regc.iss_amount);
                    print('ISS_Amount_a..............: ' || regc.iss_amount_a);
                    print('ISS_Tax...................: ' || regc.iss_tax);
                    print('modFrete..................: ' || regc.modfrete);
                    print('transp_CPF................: ' || regc.transp_cpf);
                    print('transp_CNPJ...............: ' || regc.transp_cnpj);
                    print('transp_UF.................: ' || regc.transp_uf);
                    print('transp_IE.................: ' || regc.transp_ie);
                    print('CRT.......................: ' || regc.crt);
                    print('Cnpj_For..................: ' || regc.cnpj_for);
                    print('CPF_Emit..................: ' || regc.cpf_emit);
                    print('Nome_Emit.................: ' || regc.nome_emit);
                    print('UF_Emit...................: ' || regc.uf_emit);
                    print('cMun_Emit.................: ' || regc.cmun_emit);
                    print('xMun_Emit.................: ' || regc.xmun_emit);
                    print('xLgr_Emit.................: ' || regc.xlgr_emit);
                    print('nro_Emit..................: ' || regc.nro_emit);
                    print('xCpl_Emit.................: ' || regc.xcpl_emit);
                    print('CEP_Emit..................: ' || regc.cep_emit);
         --Print('Entity_id.................: '||Regc.Entity_id);
                    print('Cnpj_Emp..................: ' || regc.cnpj_emp);
                    print('Cpf_Dest..................: ' || regc.cpf_dest);
                    print('Nome_Dest.................: ' || regc.nome_dest);
                    print('UF_Dest...................: ' || regc.uf_dest);
                    print('cMun_Dest.................: ' || regc.cmun_dest);
                    print('xMun_Dest.................: ' || regc.xmun_dest);
                    print('xLgr_Dest.................: ' || regc.xlgr_dest);
                    print('nro_Dest..................: ' || regc.nro_dest);
                    print('xCpl_Dest.................: ' || regc.xcpl_dest);
                    print('CEP_Dest..................: ' || regc.cep_dest);
         --Print('Org_Code..................: '||Regc.Org_Code);
                    print('ShipFr_Cnpj...............: ' || regc.shipfr_cnpj);
                    print('ShipFr_CPF................: ' || regc.shipfr_cpf);
                    print('ShipFr_UF.................: ' || regc.shipfr_uf);
                    print('ShipFr_cMun...............: ' || regc.shipfr_cmun);
                    print('ShipFr_xMun...............: ' || regc.shipfr_xmun);
                    print('ShipFr_xLgr...............: ' || regc.shipfr_xlgr);
                    print('ShipFr_nro................: ' || regc.shipfr_nro);
                    print('ShipFr_xCpl...............: ' || regc.shipfr_xcpl);
                    print('ShipTo_Cnpj...............: ' || regc.shipto_cnpj);
                    print('ShipTo_CPF................: ' || regc.shipto_cpf);
                    print('ShipTo_UF.................: ' || regc.shipto_uf);
                    print('ShipTo_cMun...............: ' || regc.shipto_cmun);
                    print('ShipTo_xMun...............: ' || regc.shipto_xmun);
                    print('ShipTo_xLgr...............: ' || regc.shipto_xlgr);
                    print('ShipTo_nro................: ' || regc.shipto_nro);
                    print('ShipTo_xCpl...............: ' || regc.shipto_xcpl);
         --Print('CondPagto.................: '||Regc.CondPagto);
                    print('Comments..................: ' || regc.comments);
                    valid_org(
                        nvl(regc.cnpj_emp, regc.cpf_dest),
                        g_ctrl.status
                    );
               --
                    if nvl(g_ctrl.status, 'X') <> 'E' then
                 --
                        print('--- Inicio atribuicão variaveis NFe ---');
                 --
                    end if;
          --
          --g_source.header_id                     := xxrmais_invoices_s.nextval;
                    g_source.cliente_id := g_ctrl.id;
                    g_source.numero_nff := regc.num_nf;
                    g_source.serie := regc.serie;
                    g_ctrl.numero := regc.num_nf;
                    g_ctrl.serie := regc.serie;
                    g_source.natop := regc.natop;
                    g_source.dataemissao := to_timestamp_tz ( regc.emissao,
                    'RRRR-MM-DD"T"HH24:MI:SS TZR' );
                    g_source.cnpj_cpf := nvl(regc.cnpj_for, regc.cpf_emit);
                    g_source.razaosocial_emit := regc.nome_emit;
                    g_source.cnpj_dest := regc.cnpj_emp;
                    g_source.razaosocial_dest := regc.nome_dest;
                    g_source.uf_dest := regc.uf_dest;
                    g_source.endereco_dest := regc.xlgr_dest;
                    g_source.numero_dest := regexp_substr(regc.nro_dest, '[0-9]');
                    g_source.nomemunicipio_dest := regc.xmun_dest;
                    g_source.valorservicos := regc.v_total_nf;
          --
          --l_header.efd_header_id                 := xxrmais_invoices_s.nextval;
                    l_header.doc_id := g_ctrl_id;
                    l_header.access_key_number := regc.danfe;
                    l_header.model := '00';
                    l_header.creation_date := sysdate;
                    l_header.created_by := -1;
                    l_header.last_update_date := sysdate;
                    l_header.last_updated_by := -1;
          --

                    g_source.status := 'N';
          --
                    g_source.optantesimplesnacio :=
                        case
                            when regc.crt = '1' then
                                'S'
                            else
                                'N'
                        end;
          --
                    print('SN? :' || g_source.optantesimplesnacio);
          --
          --l_header.file_name                    := rSource.rCtrl.Filename;
                    l_header.process_date := trunc(sysdate);
                    l_header.tributary_regimen := regc.crt;
                    l_header.layout_version := regc.versao;
                    l_header.operation_type := regc.tiponf;
                    l_header.issuing_type := regc.tpemis;
                    l_header.issuing_purpose := regc.finnf;
                    l_header.issue_date := to_timestamp_tz ( regc.emissao,
                    'RRRR-MM-DD"T"HH24:MI:SS TZR' );--rSource.rHead.Invoice_Date;
                    l_header.document_type :=
                        case
                            when regc.cpf_emit is not null then
                                'CPF'
                            else
                                'CNPJ'
                        end;

                    l_header.payment_indicator := regc.indpag;
                    l_header.operation_nature := regc.natop;
                    l_header.liable_freight_payment := regc.modfrete;
                    l_header.carrier_address_state := regc.transp_uf;
                    l_header.issuer_name := regc.nome_emit;
                    l_header.issuer_document_number := xxrmais_util_pkg.lpad(
                        nvl(regc.cnpj_for, regc.cpf_emit),
                        14,
                        '0'
                    );

                    l_header.issuer_address_state := regc.uf_emit;
                    l_header.issuer_address_city_code := regc.cmun_emit;
                    l_header.issuer_address_city_name := regc.xmun_emit;
                    l_header.issuer_address := regc.xlgr_emit;
                    l_header.issuer_address_number := regc.nro_emit;
                    l_header.issuer_address_complement := regc.xcpl_emit;
                    l_header.issuer_address_zip_code := regc.cep_emit;
                    l_header.receiver_name := substr(regc.nome_dest, 1, 60);
                    l_header.receiver_document_number := nvl(regc.cnpj_emp, regc.cpf_dest);
                    l_header.receiver_address_state := regc.uf_dest;
                    l_header.receiver_address_city_name := regc.xmun_dest;
                    l_header.receiver_address := regc.xlgr_dest;
                    l_header.receiver_address_number := regc.nro_dest;
                    l_header.receiver_address_complement := regc.xcpl_dest;
                    l_header.receiver_address_zip_code := regc.cep_dest;
                    l_header.ship_from_document_number := regc.shipfr_cnpj;
                    l_header.ship_from_address_state := regc.shipfr_uf;
                    l_header.ship_from_address_city_code := regc.shipfr_cmun;
                    l_header.ship_from_address_city_name := regc.shipfr_xmun;
                    l_header.ship_from_address := regc.shipfr_xlgr;
                    l_header.ship_from_address_number := regc.shipfr_nro;
                    l_header.ship_from_address_complement := regc.shipfr_xcpl;
                    l_header.ship_to_document_number := nvl(regc.shipto_cnpj, regc.shipto_cpf);
                    l_header.ship_to_address_state := regc.shipto_uf;
                    l_header.ship_to_address_city_code := regc.shipto_cmun;
                    l_header.ship_to_address_city_name := regc.shipto_xmun;
                    l_header.ship_to_address := regc.shipto_xlgr;
                    l_header.ship_to_address_number := regc.shipto_nro;
                    l_header.ship_to_address_complement := regc.shipto_xcpl;
                    l_header.pis_amount := regc.vpis;
                    l_header.cofins_amount := regc.vcofins;
          --
                    l_header.icms_fcp_amount := regc.vfcpufdest;
                    l_header.icms_sharing_dest_amount := regc.vicmsufdest;
                    l_header.icms_sharing_source_amount := regc.vicmsufremet;
                    l_header.icms_amount := nls_num_char(nvl(regc.v_vl_icms, 0));
                    l_header.icms_calculation_basis := nls_num_char(nvl(regc.v_b_icms, 0));
                    l_header.icms_st_amount := nls_num_char(nvl(regc.v_st_icms, 0));
                    l_header.icms_st_calculation_basis := nls_num_char(nvl(regc.v_bst_icms, 0));
          --l_header.Icms_St_Amount_Recover      := 0; --
          --l_header.Diff_Icms_Amount_Recover    := 0; --
          --l_header.Diff_Icms_Amount            := 0; --
          --l_header.Diff_Icms_Tax               := 0; --
                    l_header.inss_amount := 0; --
                    l_header.inss_base := 0; --
                    l_header.inss_tax := 0; --
                    l_header.ipi_amount := nls_num_char(nvl(regc.vipi, 0));
                    l_header.ir_amount := nls_num_char(nvl(regc.ir_amount, 0));
                    l_header.ir_base := nls_num_char(nvl(regc.ir_base, 0));
                    l_header.ir_categ := 0; --
                    l_header.ir_tax := 0; --
                    l_header.iss_amount := nls_num_char(nvl(regc.iss_amount, 0));
                    l_header.iss_base := nls_num_char(nvl(regc.iss_base, 0));
                    l_header.iss_tax := nls_num_char(nvl(regc.iss_tax, 0));
                    l_header.discount_amount := nls_num_char(nvl(regc.v_desconto, 0));
                    l_header.insurance_amount := nls_num_char(nvl(regc.vseg, 0));
                    l_header.other_expenses_amount := nls_num_char(nvl(regc.v_outras_des, 0));
          --l_header.Subst_Icms_Base             := 0;
          --l_header.Subst_Icms_Amount           := 0;
                    l_header.pis_withhold_amount := 0; --
                    l_header.cofins_withhold_amount := 0; --
                    l_header.carrier_document_number := nvl(regc.transp_cnpj, regc.transp_cpf);
                    l_header.carrier_document_type :=
                        case
                            when length(l_header.carrier_document_number) > 0 then
                                    case
                                        when length(regc.transp_cpf) > 0 then
                                            'CPF'
                                        else
                                            'CNPJ'
                                    end
                        end;
          --l_header.carrier_ie                  := Regc.transp_IE;
                    l_header.carrier_name := regc.transp_xnome;
          --
                    l_header.usage_authorization := regc.usage_auth;
                    l_header.document_number := regc.num_nf;
                    l_header.series := regc.serie;
                    l_header.model := regc.modelo;
                    l_header.total_amount := regc.v_total_nf;
          --
                    l_header.blob_filename := p_filename;
                    l_header.blob_file := p_file;
                    l_header.poc := g_ctrl.process;
                    l_header.document_status := 'I';                         
          --
          --
        
          --
          --------------------------------
          -- Selecionar dados dos itens --
          --------------------------------
          --
                    print('Inserindo registros NFe HEADER');
          --
                    begin
            --
            -- Buscando BU_NAME na integração
                        begin
              --
                            l_header.bu_name := json_value(rmais_process_pkg.get_taxpayer(l_header.receiver_document_number, 'RECEIVER'
                            ),
           '$.DATA.BU_NAME');
              --
                            print('BU_NAME: '
                                  || l_header.bu_name
                                  || 'CNPJ: ' || l_header.receiver_document_number);
              --
                        exception
                            when others then
              --
                                print('Não foi possível identificar a BU_NAME' || sqlerrm, 2);
              --
                        end;
            --
                        back_list(l_header.document_status, l_header.access_key_number);
            --
                        if nvl(g_ctrl.status, 'P') <> 'E' then
              --h
                            l_header.efd_header_id := xxrmais_invoices_s.nextval;
              --
                            if regc.finnf = '4' then
                                l_header.document_status := 'AU';
                            end if;
              --
                            insert into rmais_efd_headers_hdi values l_header returning efd_header_id into l_id_header;
              --
                        else
              --
                            print('Documento descartado por conter erros no header');
              --
                        end if;
            --
            --SELECT * FROM rmais_efd_headers_hdi;
            --
            --Print('---Registros inseridos---');
           --
                    exception
                        when dup_val_on_index then
              --
                            g_ctrl.status := 'D';
              --
                            print('Documento já integrado');
              --
                        when others then
            --
                            print('Erro ao inserir rmais_efd_headers_hdi' || sqlerrm);
            --
            --
                            g_ctrl.status := 'E';
            --
                    end;
          --
                    print('---Registros inseridos HEADER---');
          --
                    vidx := 0;
          --
                    print('Carregando informações das Linhas da NFe');
          --
                    for rlin in (
             --
                        select
                            row_number()
                            over(partition by pedido, line_num, cod_produto, release_num
                                 order by
                                     pedido, line_num,
                                     cod_produto, release_num, shipment_num
                            )                                                                                                                   ocurr_seq
                            ,
                            count(*)
                            over(partition by pedido, line_num, cod_produto, release_num)                                                       ocurr_tot
                            ,
                            itm.*,
                            pedido
                            || '_'
                            || line_num
                            || '_'
                            || nvl(release_num, 0)
                            || '_'
                            || cod_produto                                                                                                      chave
                            ,
                            nvl(itm.icms_00,
                                nvl(itm.icms_10,
                                    nvl(itm.icms_20,
                                        nvl(itm.icms_51,
                                            nvl(itm.icms_70,
                                                nvl(itm.icms_80,
                                                    nvl(itm.icms_81,
                                                        nvl(itm.icms_90,
                                                            nvl(itm.icms_ou, itm.icmssn_900)))))))))                                            icms
                                                            ,
                            nvl(itm.icms_aliq_00,
                                nvl(itm.icms_aliq_10,
                                    nvl(itm.icms_aliq_20,
                                        nvl(itm.icms_aliq_51,
                                            nvl(itm.icms_aliq_70,
                                                nvl(itm.icms_aliq_80,
                                                    nvl(itm.icms_aliq_81,
                                                        nvl(itm.icms_aliq_90,
                                                            nvl(itm.icms_aliq_ou, itm.icmssn_aliq_900)))))))))                                  icms_aliq
                                                            ,
                            nvl(itm.icms_base_00,
                                nvl(itm.icms_base_10,
                                    nvl(itm.icms_base_20,
                                        nvl(itm.icms_base_51,
                                            nvl(itm.icms_base_70,
                                                nvl(itm.icms_base_80,
                                                    nvl(itm.icms_base_81,
                                                        nvl(itm.icms_base_90,
                                                            nvl(itm.icms_base_ou, itm.icmssn_base_900)))))))))                                  icms_base
                                                            ,
                            nvl(itm.icms_st_00,
                                nvl(itm.icms_st_10,
                                    nvl(itm.icms_st_20,
                                        nvl(itm.icms_st_30,
                                            nvl(itm.icms_st_51,
                                                nvl(itm.icms_st_70,
                                                    nvl(itm.icms_st_80,
                                                        nvl(itm.icms_st_81,
                                                            nvl(itm.icms_st_90,
                                                                nvl(itm.icms_st_ou,
                                                                    nvl(itm.icmssn_st_201,
                                                                        nvl(itm.icmssn_st_202,
                                                                            nvl(itm.icmssn_st_500, itm.icmssn_st_900)))))))))))))               icms_st
                                                                            ,
                            nvl(itm.icms_st_aliq_00,
                                nvl(itm.icms_st_aliq_10,
                                    nvl(itm.icms_st_aliq_20,
                                        nvl(itm.icms_st_aliq_30,
                                            nvl(itm.icms_st_aliq_51,
                                                nvl(itm.icms_st_aliq_70,
                                                    nvl(itm.icms_st_aliq_80,
                                                        nvl(itm.icms_st_aliq_81,
                                                            nvl(itm.icms_st_aliq_90,
                                                                nvl(itm.icms_st_aliq_ou,
                                                                    nvl(itm.icmssn_st_aliq_201,
                                                                        nvl(itm.icmssn_st_aliq_202, itm.icmssn_st_aliq_900)))))))))))
                                                                        )          icms_st_aliq,
                            nvl(itm.icms_st_base_00,
                                nvl(itm.icms_st_base_10,
                                    nvl(itm.icms_st_base_20,
                                        nvl(itm.icms_st_base_30,
                                            nvl(itm.icms_st_base_51,
                                                nvl(itm.icms_st_base_70,
                                                    nvl(itm.icms_st_base_80,
                                                        nvl(itm.icms_st_base_81,
                                                            nvl(itm.icms_st_base_90,
                                                                nvl(itm.icms_st_base_ou,
                                                                    nvl(itm.icmssn_st_base_201,
                                                                        nvl(itm.icmssn_st_base_202,
                                                                            nvl(itm.icmssn_st_base_500, itm.icmssn_st_base_900)))))))
                                                                            ))))))     icms_st_base,
                            nvl(itm.icms_orig_00,
                                nvl(itm.icms_orig_10,
                                    nvl(itm.icms_orig_20,
                                        nvl(itm.icms_orig_30,
                                            nvl(itm.icms_orig_40,
                                                nvl(itm.icms_orig_51,
                                                    nvl(itm.icms_orig_60,
                                                        nvl(itm.icms_orig_70,
                                                            nvl(itm.icms_orig_90,
                                                                nvl(itm.icms_orig_ou,
                                                                    nvl(itm.icmssn_orig_101,
                                                                        nvl(itm.icmssn_orig_102,
                                                                            nvl(itm.icmssn_orig_201,
                                                                                nvl(itm.icmssn_orig_202,
                                                                                    nvl(itm.icmssn_orig_500, itm.icmssn_orig_900)))))
                                                                                    )))))))))) icms_orig,
                            nvl(itm.icms_cst_00,
                                nvl(itm.icms_cst_10,
                                    nvl(itm.icms_cst_20,
                                        nvl(itm.icms_cst_30,
                                            nvl(itm.icms_cst_40,
                                                nvl(itm.icms_cst_51,
                                                    nvl(itm.icms_cst_60,
                                                        nvl(itm.icms_cst_70,
                                                            nvl(itm.icms_cst_90, itm.icms_cst_ou)))))))))                                       icms_cst
                                                            ,
                            nvl(itm.icmssn_csosn_102,
                                nvl(itm.icmssn_csosn_101,
                                    nvl(itm.icmssn_csosn_201,
                                        nvl(itm.icmssn_csosn_202,
                                            nvl(itm.icmssn_csosn_500, itm.icmssn_csosn_900)))))                                                 icmssn_csosn
                                            ,
                            nvl(itm.icmssn_cr_101,
                                nvl(itm.icmssn_cr_201, itm.icmssn_cr_900))                                                                      icmssn_cr
                                ,
                            nvl(itm.icmssn_cr_aliq_101,
                                nvl(itm.icmssn_cr_aliq_201, itm.icmssn_cr_aliq_900))                                                            icmssn_cr_aliq
                                ,
                            nvl(itm.icmssn_st_modbc_201,
                                nvl(itm.icmssn_st_modbc_202, itm.icmssn_st_modbc_900))                                                          icmssn_st_modbc
                                ,
                            nvl(itm.icmssn_st_pmva_202,
                                nvl(itm.icmssn_st_pmva_201, itm.icmssn_st_pmva_900))                                                            icmssn_st_pmva
                                ,
                            itm.icmssn_red_base_900                                                                                             icmssn_red_base
                            ,
                            nvl(itm.icmssn_st_red_base_201,
                                nvl(itm.icmssn_st_red_base_202, itm.icmssn_st_red_base_900))                                                    icmssn_st_red_base
                                ,
                            itm.icmssn_modbc_900                                                                                                icmssn_modbc
                            ,
                            nvl(icms_fcp_perc_00 --#004
                            ,
                                nvl(icms_fcp_perc_10,
                                    nvl(icms_fcp_perc_20,
                                        nvl(icms_fcp_perc_51,
                                            nvl(icms_fcp_perc_70, icms_fcp_perc_90)))))                                                         icms_fcp_perc
                                            ,
                            nvl(icms_fcp_00,
                                nvl(icms_fcp_10,
                                    nvl(icms_fcp_20,
                                        nvl(icms_fcp_51,
                                            nvl(icms_fcp_70, icms_fcp_90)))))                                                                   icms_fcp
                                            ,
                            nvl(icms_fcp_base_10,
                                nvl(icms_fcp_base_20,
                                    nvl(icms_fcp_base_51,
                                        nvl(icms_fcp_base_70, icms_fcp_base_90))))                                                              icms_fcp_base
                                        ,
                            nvl(icms_fcp_st_base_10,
                                nvl(icms_fcp_st_base_30,
                                    nvl(icms_fcp_st_base_70,
                                        nvl(icms_fcp_st_base_90,
                                            nvl(icmssn_fcp_st_base_201,
                                                nvl(icmssn_fcp_st_base_202, icmssn_fcp_st_base_900))))))                                        icms_st_fcp_base
                                                ,
                            nvl(icms_fcp_st_perc_10,
                                nvl(icms_fcp_st_perc_30,
                                    nvl(icms_fcp_st_perc_70,
                                        nvl(icms_fcp_st_perc_90,
                                            nvl(icmssn_fcp_st_perc_201,
                                                nvl(icmssn_fcp_st_perc_202, icmssn_fcp_st_perc_900))))))                                        icms_st_fcp_perc
                                                ,
                            nvl(icms_fcp_st_10,
                                nvl(icms_fcp_st_30,
                                    nvl(icms_fcp_st_70,
                                        nvl(icms_fcp_st_90,
                                            nvl(icmssn_fcp_st_201,
                                                nvl(icmssn_fcp_st_202, icmssn_fcp_st_900))))))                                                  icms_st_fcp
                                                ,
                            nvl(icms_fcp_aliq_con_60, icmssn_fcp_aliq_con_500)                                                                  icms_fcp_aliq_cons
                            ,
                            nvl(icms_fcp_base_ret_60, icmssn_fcp_base_ret_500)                                                                  icms_st_fcp_base_ret
                            ,
                            nvl(icms_fcp_perc_ret_60, icmssn_fcp_perc_ret_500)                                                                  icms_st_fcp_perc_ret
                            ,
                            nvl(icms_fcp_st_ret_60, icmssn_fcp_st_ret_500)                                                                      icms_st_fcp_ret  --#004 fim
                    --
                            ,
                            nvl(itm.cofinsal_cst,
                                nvl(itm.cofinsqt_cst,
                                    nvl(itm.cofinsnt_cst, itm.cofinsou_cst)))                                                                   cofins_cst
                                    ,
                            nvl(itm.pisalq_cst,
                                nvl(itm.pisqtd_cst,
                                    nvl(itm.pisnt_cst, itm.pisout_cst)))                                                                        pis_cst
                                    ,
                            nvl(itm.pisqtd_qty, itm.pisout_qty)                                                                                 pis_qty
                            ,
                            nvl(itm.pisqtd_un_amt, itm.pisout_un_amt)                                                                           pis_un_amt
                            ,
                            nvl(itm.cofinsal_amount,
                                nvl(itm.cofinsqt_amount, itm.cofinsou_amount))                                                                  cofins_amount
                                ,
                            nvl(itm.cofinsal_base, itm.cofinsou_base)                                                                           cofins_base
                            ,
                            nvl(itm.cofinsal_aliq, itm.cofinsal_aliq)                                                                           cofins_aliq
                            ,
                            nvl(itm.cofinsqt_qty, itm.cofinsou_qty)                                                                             cofins_qty
                            ,
                            nvl(itm.cofinsqt_un_amt, itm.cofinsou_un_amt)                                                                       cofins_un_amt
                            ,
                            nvl(itm.ipi_trib_cst, itm.ipi_nt_cst)                                                                               ipi_cst
    --                    , itm.Fator_Conv
    --                    , itm.Precisao_Conv
    --                    , itm.Qtd_Prod_Conv
                        from
                            xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/nfe' ),
                            '/nfeProc/NFe/infNFe/det'
                                    passing xmltype(l_xml)
                                columns
                                    pedido varchar2(150) path '/det/prod/xPed/text()',
                                    line_num number path '/det/@nItem',
                                    line_num_ped number path '/det/prod/nItemPed/text()',
                                    release_num number path '/det/prod/InfTrad/xReleaseNum/text()',
                                    shipment_num number path '/det/prod/nParcela/text()'
                --, xCod_Produto           VARCHAR2(100) Path '/det/prod/InfTrad/xCodProduto/text()'
                --, xDes_Produto           VARCHAR2(255) Path '/det/prod/InfTrad/xDesProduto/text()'
                                    ,
                                    qtd_prod number path '/det/prod/qCom/text()',
                                    qtd_orig number path '/det/prod/qTrib/text()',
                                    uom varchar2(300) path '/det/prod/uCom/text()',
                                    cod_produto varchar2(200) path '/det/prod/cProd/text()',
                                    des_produto varchar2(255) path '/det/prod/xProd/text()',
                                    cod_barras varchar2(200) path '/det/prod/cEAN/text()',
                                    valor_unit number path '/det/prod/vUnCom/text()',
                                    valor_tot number path '/det/prod/vProd/text()',
                                    cfo varchar2(10) path '/det/prod/CFOP/text()',
                                    desconto varchar2(200) path '/det/prod/vDesc/text()',
                                    ncm varchar2(200) path '/det/prod/NCM/text()',
                                    outras_desp number path '/det/prod/vOutro/text()',
                                    tipo_pedido varchar2(300) path '/det/prod/xTipoPed/text()',
                                    cod_conta varchar2(200) path '/det/prod/xContContab/text()',
                                    seguro number path '/det/prod/vSeg/text()',
                                    vfrete number path '/det/prod/vFrete/text()',
                                    xcentrocusto varchar2(100) path '/det/prod/xCentroCusto/text()',
                                    cest varchar2(200) path '/det/prod/CEST/text()',
                                    nfci varchar2(200) path '/det/prod/nFCI/text()',
                                    fator_conv varchar2(100) path '/det/prod/InfTrad/vFatConvUM/text()',
                                    precisao_conv varchar2(100) path '/det/prod/InfTrad/vPrecisaoConv/text()',
                                    qtd_prod_conv varchar2(100) path '/det/prod/InfTrad/vQtdeConv/text()',
                                    operating_unit varchar2(200) path '/det/prod/InfTrad/xOperatingUnit/text()',
                                    utilizacao varchar2(100) path '/det/prod/InfTrad/xUtilizFiscal/text()',
                                    xuom varchar2(200) path '/det/prod/InfTrad/xUMint/text()',
                                    xcfo varchar2(10) path '/det/prod/InfTrad/xCfopEntrada/text()',
                                    xnaturoper varchar2(10) path '/det/prod/InfTrad/xNaturOper/text()',
                                    xorganization varchar2(10) path '/det/prod/InfTrad/xCodOrganizacao/text()',
                                    refserie varchar2(10) path '/det/prod/InfTrad/NFrefItem/refNF/serie/text()',
                                    refnnf varchar2(10) path '/det/prod/InfTrad/NFrefItem/refNF/nNF/text()',
                                    refdatnf varchar2(10) path '/det/prod/InfTrad/NFrefItem/refNF/dDataNF/text()',
                                    refkeynf varchar2(10) path '/det/prod/InfTrad/NFrefItem/refNF/xChaveNF/text()',
                                    refvqtd varchar2(10) path '/det/prod/InfTrad/NFrefItem/refNF/vQtd/text()',
                                    icms_orig_00 varchar2(80) path '/det/imposto/ICMS/ICMS00/orig/text()',
                                    icms_00 number path '/det/imposto/ICMS/ICMS00/vICMS/text()',
                                    icms_base_00 number path '/det/imposto/ICMS/ICMS00/vBC/text()',
                                    icms_aliq_00 number path '/det/imposto/ICMS/ICMS00/pICMS/text()',
                                    icms_st_00 number path '/det/imposto/ICMS/ICMS00/vICMSST/text()',
                                    icms_st_base_00 number path '/det/imposto/ICMS/ICMS00/vBCST/text()',
                                    icms_st_aliq_00 number path '/det/imposto/ICMS/ICMS00/pICMSST/text()',
                                    icms_fcp_perc_00 number path '/det/imposto/ICMS/ICMS00/pFCP/text()',
                                    icms_fcp_00 number path '/det/imposto/ICMS/ICMS00/vFCP/text()',
                                    icms_cst_00 varchar2(80) path '/det/imposto/ICMS/ICMS00/CST/text()',
                                    icms_orig_10 varchar2(80) path '/det/imposto/ICMS/ICMS10/orig/text()',
                                    icms_10 number path '/det/imposto/ICMS/ICMS10/vICMS/text()',
                                    icms_base_10 number path '/det/imposto/ICMS/ICMS10/vBC/text()',
                                    icms_aliq_10 number path '/det/imposto/ICMS/ICMS10/pICMS/text()',
                                    icms_st_10 number path '/det/imposto/ICMS/ICMS10/vICMSST/text()',
                                    icms_st_base_10 number path '/det/imposto/ICMS/ICMS10/vBCST/text()',
                                    icms_st_aliq_10 number path '/det/imposto/ICMS/ICMS10/pICMSST/text()',
                                    icms_fcp_perc_10 number path '/det/imposto/ICMS/ICMS10/pFCP/text()',
                                    icms_fcp_10 number path '/det/imposto/ICMS/ICMS10/vFCP/text()',
                                    icms_fcp_base_10 number path '/det/imposto/ICMS/ICMS10/vBCFCP/text()',
                                    icms_fcp_st_base_10 number path '/det/imposto/ICMS/ICMS10/vBCFCPST/text()',
                                    icms_fcp_st_perc_10 number path '/det/imposto/ICMS/ICMS10/pFCPST/text()',
                                    icms_fcp_st_10 number path '/det/imposto/ICMS/ICMS10/vFCPST/text()'
                    --
                                    ,
                                    icms_cst_10 varchar2(80) path '/det/imposto/ICMS/ICMS10/CST/text()',
                                    icms_orig_20 varchar2(80) path '/det/imposto/ICMS/ICMS20/orig/text()',
                                    icms_20 number path '/det/imposto/ICMS/ICMS20/vICMS/text()',
                                    icms_base_20 number path '/det/imposto/ICMS/ICMS20/vBC/text()',
                                    icms_aliq_20 number path '/det/imposto/ICMS/ICMS20/pICMS/text()',
                                    icms_st_20 number path '/det/imposto/ICMS/ICMS20/vICMSST/text()',
                                    icms_st_base_20 number path '/det/imposto/ICMS/ICMS20/vBCST/text()',
                                    icms_st_aliq_20 number path '/det/imposto/ICMS/ICMS20/pICMSST/text()',
                                    icms_fcp_perc_20 number path '/det/imposto/ICMS/ICMS20/pFCP/text()' ---#004
                                    ,
                                    icms_fcp_20 number path '/det/imposto/ICMS/ICMS20/vFCP/text()' ---#004
                                    ,
                                    icms_fcp_base_20 number path '/det/imposto/ICMS/ICMS20/vBCFCP/text()' ---#004
                                    ,
                                    icms_cst_20 varchar2(80) path '/det/imposto/ICMS/ICMS20/CST/text()',
                                    icms_orig_30 varchar2(80) path '/det/imposto/ICMS/ICMS30/orig/text()',
                                    icms_st_30 varchar2(80) path '/det/imposto/ICMS/ICMS30/vICMSST/text()' --#004
                                    ,
                                    icms_st_base_30 varchar2(80) path '/det/imposto/ICMS/ICMS30/vBCST/text()' --#004
                                    ,
                                    icms_st_aliq_30 number path '/det/imposto/ICMS/ICMS30/pICMSST/text()' --#004
                                    ,
                                    icms_fcp_st_base_30 number path '/det/imposto/ICMS/ICMS30/vBCFCPST/text()' ---#004
                                    ,
                                    icms_fcp_st_perc_30 number path '/det/imposto/ICMS/ICMS30/pFCPST/text()' ---#004
                                    ,
                                    icms_fcp_st_30 number path '/det/imposto/ICMS/ICMS30/vFCPST/text()' ---#004
                                    ,
                                    icms_cst_30 varchar2(80) path '/det/imposto/ICMS/ICMS30/CST/text()',
                                    icms_orig_40 varchar2(80) path '/det/imposto/ICMS/ICMS40/orig/text()',
                                    icms_cst_40 varchar2(80) path '/det/imposto/ICMS/ICMS40/CST/text()',
                                    icms_orig_51 varchar2(80) path '/det/imposto/ICMS/ICMS51/orig/text()',
                                    icms_51 number path '/det/imposto/ICMS/ICMS51/vICMS/text()',
                                    icms_base_51 number path '/det/imposto/ICMS/ICMS51/vBC/text()',
                                    icms_aliq_51 number path '/det/imposto/ICMS/ICMS51/pICMS/text()',
                                    icms_st_51 number path '/det/imposto/ICMS/ICMS51/vICMSST/text()',
                                    icms_st_base_51 number path '/det/imposto/ICMS/ICMS51/vBCST/text()',
                                    icms_st_aliq_51 number path '/det/imposto/ICMS/ICMS51/pICMSST/text()',
                                    icms_fcp_perc_51 number path '/det/imposto/ICMS/ICMS51/pFCP/text()' ---#004
                                    ,
                                    icms_fcp_51 number path '/det/imposto/ICMS/ICMS51/vFCP/text()' ---#004
                                    ,
                                    icms_fcp_base_51 number path '/det/imposto/ICMS/ICMS51/vBCFCP/text()' ---#004
                                    ,
                                    deferred_icms_amt number path '/det/imposto/ICMS/ICMS51/vICMSDif/text()',
                                    icms_cst_51 varchar2(80) path '/det/imposto/ICMS/ICMS51/CST/text()',
                                    icms_orig_60 varchar2(80) path '/det/imposto/ICMS/ICMS60/orig/text()',
                                    icms_st_base_60 number path '/det/imposto/ICMS/ICMS60/vBCSTRet/text()',
                                    icms_st_60 number path '/det/imposto/ICMS/ICMS60/vICMSSTRet/text()',
                                    icms_cst_60 varchar2(80) path '/det/imposto/ICMS/ICMS60/CST/text()',
                                    icms_fcp_aliq_con_60 number path '/det/imposto/ICMS/ICMS60/pST/text()' ---#004
                                    ,
                                    icms_fcp_base_ret_60 number path '/det/imposto/ICMS/ICMS60/vBCFCPSTRet/text()' ---#004
                                    ,
                                    icms_fcp_perc_ret_60 number path '/det/imposto/ICMS/ICMS60/pFCPSTRet/text()' ---#004
                                    ,
                                    icms_fcp_st_ret_60 number path '/det/imposto/ICMS/ICMS60/vFCPSTRet/text()' ---#004
                                    ,
                                    icms_orig_70 varchar2(80) path '/det/imposto/ICMS/ICMS70/orig/text()',
                                    icms_70 number path '/det/imposto/ICMS/ICMS70/vICMS/text()',
                                    icms_base_70 number path '/det/imposto/ICMS/ICMS70/vBC/text()',
                                    icms_aliq_70 number path '/det/imposto/ICMS/ICMS70/pICMS/text()',
                                    icms_st_70 number path '/det/imposto/ICMS/ICMS70/vICMSST/text()',
                                    icms_st_base_70 number path '/det/imposto/ICMS/ICMS70/vBCST/text()',
                                    icms_st_aliq_70 number path '/det/imposto/ICMS/ICMS70/pICMSST/text()',
                                    icms_fcp_perc_70 number path '/det/imposto/ICMS/ICMS70/pFCP/text()' ---#004
                                    ,
                                    icms_fcp_70 number path '/det/imposto/ICMS/ICMS70/vFCP/text()' ---#004
                                    ,
                                    icms_fcp_base_70 number path '/det/imposto/ICMS/ICMS70/vBCFCP/text()' ---#004
                                    ,
                                    icms_fcp_st_base_70 number path '/det/imposto/ICMS/ICMS70/vBCFCPST/text()' ---#004
                                    ,
                                    icms_fcp_st_perc_70 number path '/det/imposto/ICMS/ICMS70/pFCPST/text()' ---#004
                                    ,
                                    icms_fcp_st_70 number path '/det/imposto/ICMS/ICMS70/vFCPST/text()' ---#004
                                    ,
                                    icms_cst_70 varchar2(80) path '/det/imposto/ICMS/ICMS70/CST/text()',
                                    icms_80 number path '/det/imposto/ICMS/ICMS80/vICMS/text()',
                                    icms_base_80 number path '/det/imposto/ICMS/ICMS80/vBC/text()',
                                    icms_aliq_80 number path '/det/imposto/ICMS/ICMS80/pICMS/text()',
                                    icms_st_80 number path '/det/imposto/ICMS/ICMS80/vICMSST/text()',
                                    icms_st_base_80 number path '/det/imposto/ICMS/ICMS80/vBCST/text()',
                                    icms_st_aliq_80 number path '/det/imposto/ICMS/ICMS80/pICMSST/text()',
                                    icms_81 number path '/det/imposto/ICMS/ICMS81/vICMS/text()',
                                    icms_base_81 number path '/det/imposto/ICMS/ICMS81/vBC/text()',
                                    icms_aliq_81 number path '/det/imposto/ICMS/ICMS81/pICMS/text()',
                                    icms_st_81 number path '/det/imposto/ICMS/ICMS81/vICMSST/text()',
                                    icms_st_base_81 number path '/det/imposto/ICMS/ICMS81/vBCST/text()',
                                    icms_st_aliq_81 number path '/det/imposto/ICMS/ICMS81/pICMSST/text()',
                                    icms_orig_90 varchar2(80) path '/det/imposto/ICMS/ICMS90/orig/text()',
                                    icms_90 number path '/det/imposto/ICMS/ICMS90/vICMS/text()',
                                    icms_base_90 number path '/det/imposto/ICMS/ICMS90/vBC/text()',
                                    icms_aliq_90 number path '/det/imposto/ICMS/ICMS90/pICMS/text()',
                                    icms_st_90 number path '/det/imposto/ICMS/ICMS90/vICMSST/text()',
                                    icms_st_base_90 number path '/det/imposto/ICMS/ICMS90/vBCST/text()',
                                    icms_st_aliq_90 number path '/det/imposto/ICMS/ICMS90/pICMSST/text()',
                                    icms_fcp_st_90 number path '/det/imposto/ICMS/ICMS90/vFCPST/text()' ---#004
                                    ,
                                    icms_fcp_perc_90 number path '/det/imposto/ICMS/ICMS90/pFCP/text()' ---#004
                                    ,
                                    icms_fcp_90 number path '/det/imposto/ICMS/ICMS90/vFCP/text()' ---#004
                                    ,
                                    icms_fcp_base_90 number path '/det/imposto/ICMS/ICMS90/vBCFCP/text()' ---#004
                                    ,
                                    icms_fcp_st_base_90 number path '/det/imposto/ICMS/ICMS90/vBCFCPST/text()' ---#004
                                    ,
                                    icms_fcp_st_perc_90 number path '/det/imposto/ICMS/ICMS90/pFCPST/text()' ---#004
                                    ,
                                    icms_cst_90 varchar2(80) path '/det/imposto/ICMS/ICMS90/CST/text()',
                                    icms_orig_ou varchar2(80) path '/det/imposto/ICMS/ICMSPart/orig/text()',
                                    icms_cst_ou varchar2(80) path '/det/imposto/ICMS/ICMSPart/CST/text()',
                                    icms_modbc_ou varchar2(80) path '/det/imposto/ICMS/ICMSPart/modBC/text()',
                                    icms_base_ou number path '/det/imposto/ICMS/ICMSPart/vBC/text()',
                                    icms_predbc_ou number path '/det/imposto/ICMS/ICMSPart/pRedBC/text()',
                                    icms_aliq_ou number path '/det/imposto/ICMS/ICMSPart/pICMS/text()',
                                    icms_ou number path '/det/imposto/ICMS/ICMSPart/vICMS/text()',
                                    icms_st_modbc_ou varchar2(80) path '/det/imposto/ICMS/ICMSPart/modBCST/text()',
                                    icms_st_pmva_ou varchar2(80) path '/det/imposto/ICMS/ICMSPart/pMVAST/text()',
                                    icms_st_predbc_ou varchar2(80) path '/det/imposto/ICMS/ICMSPart/pRedBCST/text()',
                                    icms_st_base_ou number path '/det/imposto/ICMS/ICMSPart/vBCST/text()',
                                    icms_st_aliq_ou number path '/det/imposto/ICMS/ICMSPart/pICMSST/text()',
                                    icms_st_ou number path '/det/imposto/ICMS/ICMSPart/vICMSST/text()',
                                    icms_st_pbcop_ou number path '/det/imposto/ICMS/ICMSPart/pBCOp/text()',
                                    icms_st_uf_ou varchar2(80) path '/det/imposto/ICMS/ICMSPart/UFST/text()',
                                    icms_orig_st varchar2(80) path '/det/imposto/ICMS/ICMSST/orig/text()',
                                    icms_cst_st varchar2(80) path '/det/imposto/ICMS/ICMSST/CST/text()',
                                    icms_st_base_st number path '/det/imposto/ICMS/ICMSST/vBCSTRet/text()',
                                    icms_st_st number path '/det/imposto/ICMS/ICMSST/vICMSSTRet/text()',
                                    icms_st_base_dest_st number path '/det/imposto/ICMS/ICMSST/vBCSTDest/text()',
                                    icms_st_dest_st number path '/det/imposto/ICMS/ICMSST/vICMSSTDest/text()'
                  --ICMS Simples Nacional
                                    ,
                                    icmssn_orig_101 varchar2(80) path '/det/imposto/ICMS/ICMSSN101/orig/text()',
                                    icmssn_csosn_101 varchar2(80) path '/det/imposto/ICMS/ICMSSN101/CSOSN/text()',
                                    icmssn_cr_aliq_101 number path '/det/imposto/ICMS/ICMSSN101/pCredSN/text()',
                                    icmssn_cr_101 number path '/det/imposto/ICMS/ICMSSN101/vCredICMSSN/text()',
                                    icmssn_orig_102 varchar2(80) path '/det/imposto/ICMS/ICMSSN102/orig/text()',
                                    icmssn_csosn_102 varchar2(80) path '/det/imposto/ICMS/ICMSSN102/CSOSN/text()',
                                    icmssn_orig_201 varchar2(80) path '/det/imposto/ICMS/ICMSSN201/orig/text()',
                                    icmssn_csosn_201 varchar2(80) path '/det/imposto/ICMS/ICMSSN201/CSOSN/text()',
                                    icmssn_st_modbc_201 varchar2(80) path '/det/imposto/ICMS/ICMSSN201/modBCST/text()',
                                    icmssn_st_pmva_201 varchar2(80) path '/det/imposto/ICMS/ICMSSN201/pMVAST/text()',
                                    icmssn_st_red_base_201 number path '/det/imposto/ICMS/ICMSSN201/pRedBCST/text()',
                                    icmssn_st_base_201 number path '/det/imposto/ICMS/ICMSSN201/vBCST/text()',
                                    icmssn_st_aliq_201 number path '/det/imposto/ICMS/ICMSSN201/pICMSST/text()',
                                    icmssn_st_201 number path '/det/imposto/ICMS/ICMSSN201/vICMSST/text()',
                                    icmssn_cr_aliq_201 number path '/det/imposto/ICMS/ICMSSN201/pCredSN/text()',
                                    icmssn_cr_201 number path '/det/imposto/ICMS/ICMSSN201/vCredICMSSN/text()',
                                    icmssn_fcp_st_base_201 number path '/det/imposto/ICMS/ICMSSN201/vBCFCPST/text()' ---#004
                                    ,
                                    icmssn_fcp_st_perc_201 number path '/det/imposto/ICMS/ICMSSN201/pFCPST/text()' ---#004
                                    ,
                                    icmssn_fcp_st_201 number path '/det/imposto/ICMS/ICMSSN201/vFCPST/text()' ---#004
                                    ,
                                    icmssn_orig_202 varchar2(80) path '/det/imposto/ICMS/ICMSSN202/orig/text()',
                                    icmssn_csosn_202 varchar2(80) path '/det/imposto/ICMS/ICMSSN202/CSOSN/text()',
                                    icmssn_st_modbc_202 varchar2(80) path '/det/imposto/ICMS/ICMSSN202/modBCST/text()',
                                    icmssn_st_pmva_202 varchar2(80) path '/det/imposto/ICMS/ICMSSN202/pMVAST/text()',
                                    icmssn_st_red_base_202 number path '/det/imposto/ICMS/ICMSSN202/pRedBCST/text()',
                                    icmssn_st_base_202 number path '/det/imposto/ICMS/ICMSSN202/vBCST/text()',
                                    icmssn_st_aliq_202 number path '/det/imposto/ICMS/ICMSSN202/pICMSST/text()',
                                    icmssn_st_202 number path '/det/imposto/ICMS/ICMSSN202/vICMSST/text()',
                                    icmssn_fcp_st_base_202 number path '/det/imposto/ICMS/ICMSSN202/vBCFCPST/text()' ---#004
                                    ,
                                    icmssn_fcp_st_perc_202 number path '/det/imposto/ICMS/ICMSSN202/pFCPST/text()' ---#004
                                    ,
                                    icmssn_fcp_st_202 number path '/det/imposto/ICMS/ICMSSN202/vFCPST/text()' ---#004
                                    ,
                                    icmssn_orig_500 varchar2(80) path '/det/imposto/ICMS/ICMSSN500/orig/text()',
                                    icmssn_csosn_500 varchar2(80) path '/det/imposto/ICMS/ICMSSN500/CSOSN/text()',
                                    icmssn_st_base_500 number path '/det/imposto/ICMS/ICMSSN500/vBCSTRet/text()',
                                    icmssn_st_500 number path '/det/imposto/ICMS/ICMSSN500/vICMSSTRet/text()',
                                    icmssn_fcp_aliq_con_500 number path '/det/imposto/ICMS/ICMSSN500/pST/text()' ---#004
                                    ,
                                    icmssn_fcp_base_ret_500 number path '/det/imposto/ICMS/ICMSSN500/vBCFCPSTRet/text()' ---#004
                                    ,
                                    icmssn_fcp_perc_ret_500 number path '/det/imposto/ICMS/ICMSSN500/pFCPSTRet/text()' ---#004
                                    ,
                                    icmssn_fcp_st_ret_500 number path '/det/imposto/ICMS/ICMSSN500/vFCPSTRet/text()' ---#004
                                    ,
                                    icmssn_orig_900 varchar2(80) path '/det/imposto/ICMS/ICMSSN900/orig/text()',
                                    icmssn_csosn_900 varchar2(80) path '/det/imposto/ICMS/ICMSSN900/CSOSN/text()',
                                    icmssn_modbc_900 varchar2(80) path '/det/imposto/ICMS/ICMSSN900/modBC/text()',
                                    icmssn_red_base_900 number path '/det/imposto/ICMS/ICMSSN900/pRedBC/text()',
                                    icmssn_base_900 number path '/det/imposto/ICMS/ICMSSN900/vBC/text()',
                                    icmssn_aliq_900 number path '/det/imposto/ICMS/ICMSSN900/pICMS/text()',
                                    icmssn_900 number path '/det/imposto/ICMS/ICMSSN900/vICMS/text()',
                                    icmssn_st_modbc_900 varchar2(80) path '/det/imposto/ICMS/ICMSSN900/modBCST/text()',
                                    icmssn_st_pmva_900 varchar2(80) path '/det/imposto/ICMS/ICMSSN900/pMVAST/text()',
                                    icmssn_st_red_base_900 number path '/det/imposto/ICMS/ICMSSN900/pRedBCST/text()',
                                    icmssn_st_base_900 number path '/det/imposto/ICMS/ICMSSN900/vBCST/text()',
                                    icmssn_st_aliq_900 number path '/det/imposto/ICMS/ICMSSN900/pICMSST/text()',
                                    icmssn_st_900 number path '/det/imposto/ICMS/ICMSSN900/vICMSST/text()',
                                    icmssn_cr_aliq_900 number path '/det/imposto/ICMS/ICMSSN900/pCredSN/text()',
                                    icmssn_cr_900 number path '/det/imposto/ICMS/ICMSSN900/vCredICMSSN/text()',
                                    icmssn_fcp_st_base_900 number path '/det/imposto/ICMS/ICMSSN900/vBCFCPST/text()' ---#004
                                    ,
                                    icmssn_fcp_st_perc_900 number path '/det/imposto/ICMS/ICMSSN900/pFCPST/text()'   ---#004
                                    ,
                                    icmssn_fcp_st_900 number path '/det/imposto/ICMS/ICMSSN900/vFCPST/text()'   ---#004
                    --
                                    ,
                                    ipi number path '/det/imposto/IPI/IPITrib/vIPI/text()',
                                    ipi_type number path '/det/imposto/IPI/cEnq/text()',
                                    ipi_base number path '/det/imposto/IPI/IPITrib/vBC/text()',
                                    ipi_qtd number path '/det/imposto/IPI/IPITrib/qUnid/text()',
                                    ipi_unit number path '/det/imposto/IPI/IPITrib/vUnid/text()',
                                    ipi_trib_cst varchar2(200) path '/det/imposto/IPI/IPITrib/CST/text()',
                                    ipi_aliq number path '/det/imposto/IPI/IPITrib/pIPI/text()',
                                    ipi_nt_cst varchar2(200) path '/det/imposto/IPI/IPINT/CST/text()',
                                    pisqtd_cst varchar2(80) path '/det/imposto/PIS/PISQtde/CST/text()',
                                    pisqtd_qty number path '/det/imposto/PIS/PISQtde/qBCProd/text()',
                                    pisqtd_un_amt number path '/det/imposto/PIS/PISQtde/vAliqProd/text()',
                                    pisnt_cst varchar2(80) path '/det/imposto/PIS/PISNT/CST/text()',
                                    pisout_cst varchar2(80) path '/det/imposto/PIS/PISOutr/CST/text()',
                                    pisout_qty number path '/det/imposto/PIS/PISOutr/qBCProd/text()',
                                    pisout_un_amt number path '/det/imposto/PIS/PISOutr/vAliqProd/text()',
                                    pisalq_cst varchar2(80) path '/det/imposto/PIS/PISAliq/CST/text()',
                                    pis number path '/det/imposto/PIS/PISAliq/vPIS/text()',
                                    pis_base number path '/det/imposto/PIS/PISAliq/vBC/text()',
                                    pis_aliq number path '/det/imposto/PIS/PISAliq/pPIS/text()',
                                    cofinsqt_qty number path '/det/imposto/COFINS/COFINSQtde/qBCProd/text()',
                                    cofinsqt_un_amt number path '/det/imposto/COFINS/COFINSQtde/vAliqProd/text()',
                                    cofinsqt_amount number path '/det/imposto/COFINS/COFINSQtde/vCOFINS/text()',
                                    cofinsqt_cst varchar2(80) path '/det/imposto/COFINS/COFINSQtde/CST/text()',
                                    cofinsnt_cst varchar2(80) path '/det/imposto/COFINS/COFINSNT/CST/text()',
                                    cofinsou_base number path '/det/imposto/COFINS/COFINSOutr/vBC/text()',
                                    cofinsou_aliq number path '/det/imposto/COFINS/COFINSOutr/pCOFINS/text()',
                                    cofinsou_qty number path '/det/imposto/COFINS/COFINSOutr/qBCProd/text()',
                                    cofinsou_un_amt number path '/det/imposto/COFINS/COFINSOutr/vAliqProd/text()',
                                    cofinsou_amount number path '/det/imposto/COFINS/COFINSOutr/vCOFINS/text()',
                                    cofinsou_cst varchar2(80) path '/det/imposto/COFINS/COFINSOutr/CST/text()',
                                    cofinsal_cst varchar2(80) path '/det/imposto/COFINS/COFINSAliq/CST/text()',
                                    cofinsal_amount number path '/det/imposto/COFINS/COFINSAliq/vCOFINS/text()',
                                    cofinsal_base number path '/det/imposto/COFINS/COFINSAliq/vBC/text()',
                                    cofinsal_aliq number path '/det/imposto/COFINS/COFINSAliq/pCOFINS/text()',
                                    clistserv varchar2(100) path '/det/imposto/ISSQN/cListServ/text()',
                                    indiss number path '/det/imposto/ISSQN/indISS/text()'
                            ) itm
                        order by
                            pedido,
                            line_num,
                            cod_produto,
                            release_num,
                            ocurr_seq
                    ) loop
            --
                        begin
              --
                            vidx := vidx + 1;
              --
                            print('Pedido XML................: ' || rlin.pedido);
                            print('line_num..................: ' || rlin.line_num);
                            print('line_num_ped..............: ' || rlin.line_num_ped);
                            print('Release XML...............: ' || rlin.release_num);
                            print('shipment_num..............: ' || rlin.shipment_num);
            --Print('xCod_Produto..............: '||rLin.xCod_Produto);
            --Print('xDes_Produto..............: '||rLin.xDes_Produto);
                            print('Qtd_Prod..................: ' || rlin.qtd_prod);
                            print('Qtd_Orig..................: ' || rlin.qtd_orig);
                            print('Uom.......................: ' || rlin.uom);
                            print('Cod_Produto...............: ' || rlin.cod_produto);
                            print('Des_Produto...............: ' || rlin.des_produto);
                            print('Cod_Barras................: ' || rlin.cod_barras);
                            print('Valor_Unit................: ' || rlin.valor_unit);
                            print('Valor_Tot.................: ' || rlin.valor_tot);
                            print('Cfo.......................: ' || rlin.cfo);
                            print('Desconto..................: ' || rlin.desconto);
                            print('Ncm.......................: ' || rlin.ncm);
                            print('Outras_Desp...............: ' || rlin.outras_desp);
                            print('Tipo_Pedido...............: ' || rlin.tipo_pedido);
                            print('cod_conta.................: ' || rlin.cod_conta);
                            print('seguro....................: ' || rlin.seguro);
                            print('vFrete....................: ' || rlin.vfrete);
                            print('Operating_unit............: ' || rlin.operating_unit);
                            print('Utilizacao................: ' || rlin.utilizacao);
                            print('xNaturOper................: ' || rlin.xnaturoper);
                            print('Fator_Conv................: ' || rlin.fator_conv);
                            print('Precisao_Conv.............: ' || rlin.precisao_conv);
                            print('Qtd_Prod_Conv.............: ' || rlin.qtd_prod_conv);
                            print('xUOM......................: ' || rlin.xuom);
                            print('xCfo......................: ' || rlin.xcfo);
                            print('Icms_orig_00..............: ' || rlin.icms_orig_00);
                            print('Icms_00...................: ' || rlin.icms_00);
                            print('Icms_Base_00..............: ' || rlin.icms_base_00);
                            print('Icms_Aliq_00..............: ' || rlin.icms_aliq_00);
                            print('Icms_St_00................: ' || rlin.icms_st_00);
                            print('Icms_St_Base_00...........: ' || rlin.icms_st_base_00);
                            print('Icms_St_Aliq_00...........: ' || rlin.icms_st_aliq_00);
                            print('Icms_FCP_perc_00..........: ' || rlin.icms_fcp_perc_00);
                            print('Icms_FCP_00...............: ' || rlin.icms_fcp_00);
                            print('Icms_CST_00...............: ' || rlin.icms_cst_00);
                            print('Icms_orig_10..............: ' || rlin.icms_orig_10);
                            print('Icms_10...................: ' || rlin.icms_10);
                            print('Icms_Base_10..............: ' || rlin.icms_base_10);
                            print('Icms_Aliq_10..............: ' || rlin.icms_aliq_10);
                            print('Icms_St_10................: ' || rlin.icms_st_10);
                            print('Icms_St_Base_10...........: ' || rlin.icms_st_base_10);
                            print('Icms_St_Aliq_10...........: ' || rlin.icms_st_aliq_10);
                            print('Icms_FCP_perc_10..........: ' || rlin.icms_fcp_perc_10);
                            print('Icms_FCP_10...............: ' || rlin.icms_fcp_10);
                            print('Icms_FCP_Base_10..........: ' || rlin.icms_fcp_base_10);
                            print('Icms_St_FCP_Base_10.......: ' || rlin.icms_fcp_st_base_10);
                            print('Icms_St_FCP_Perc_10.......: ' || rlin.icms_fcp_st_perc_10);
                            print('Icms_St_FCP_10............: ' || rlin.icms_fcp_st_10);
                            print('Icms_CST_10...............: ' || rlin.icms_cst_10);
                            print('Icms_orig_20..............: ' || rlin.icms_orig_20);
                            print('Icms_20...................: ' || rlin.icms_20);
                            print('Icms_Base_20..............: ' || rlin.icms_base_20);
                            print('Icms_Aliq_20..............: ' || rlin.icms_aliq_20);
                            print('Icms_St_20................: ' || rlin.icms_st_20);
                            print('Icms_St_Base_20...........: ' || rlin.icms_st_base_20);
                            print('Icms_St_Aliq_20...........: ' || rlin.icms_st_aliq_20);
                            print('Icms_FCP_perc_20..........: ' || rlin.icms_fcp_perc_20);
                            print('Icms_FCP_20...............: ' || rlin.icms_fcp_20);
                            print('Icms_FCP_Base_20..........: ' || rlin.icms_fcp_base_20);
                            print('Icms_CST_20...............: ' || rlin.icms_cst_20);
                            print('Icms_orig_30..............: ' || rlin.icms_orig_30);
                            print('Icms_st_30................: ' || rlin.icms_st_30);
                            print('Icms_St_Base_30...........: ' || rlin.icms_st_base_30);
                            print('Icms_St_Aliq_30...........: ' || rlin.icms_st_aliq_30);
                            print('Icms_St_FCP_Base_30.......: ' || rlin.icms_fcp_st_base_30);
                            print('Icms_St_FCP_Perc_30.......: ' || rlin.icms_fcp_st_perc_30);
                            print('Icms_St_FCP_30............: ' || rlin.icms_fcp_st_30);
                            print('Icms_CST_30...............: ' || rlin.icms_cst_30);
                            print('Icms_orig_40..............: ' || rlin.icms_orig_40);
                            print('Icms_CST_40...............: ' || rlin.icms_cst_40);
                            print('Icms_orig_51..............: ' || rlin.icms_orig_51);
                            print('Icms_51...................: ' || rlin.icms_51);
                            print('Icms_Base_51..............: ' || rlin.icms_base_51);
                            print('Icms_Aliq_51..............: ' || rlin.icms_aliq_51);
                            print('Icms_St_51................: ' || rlin.icms_st_51);
                            print('Icms_St_Base_51...........: ' || rlin.icms_st_base_51);
                            print('Icms_St_Aliq_51...........: ' || rlin.icms_st_aliq_51);
                            print('Icms_St_FCP_Base_51.......: ' || rlin.icms_fcp_base_51);
                            print('Icms_St_FCP_Perc_51.......: ' || rlin.icms_fcp_perc_51);
                            print('Icms_St_FCP_51............: ' || rlin.icms_fcp_51);
                            print('Deferred_Icms_Amt.........: ' || rlin.deferred_icms_amt);
                            print('Icms_CST_51...............: ' || rlin.icms_cst_51);
                            print('Icms_orig_60..............: ' || rlin.icms_orig_60);
                            print('Icms_St_Base_60...........: ' || rlin.icms_st_base_60);
                            print('Icms_St_60................: ' || rlin.icms_st_60);
                            print('Icms_St_FCP_Aliq_cons_60..: ' || rlin.icms_fcp_aliq_con_60);
                            print('Icms_St_FCP_Base_Ret_60...: ' || rlin.icms_fcp_base_ret_60);
                            print('Icms_St_FCP_Perc_Ret_60...: ' || rlin.icms_fcp_perc_ret_60);
                            print('Icms_St_FCP_ret_60........: ' || rlin.icms_fcp_st_ret_60);
                            print('Icms_CST_60...............: ' || rlin.icms_cst_60);
                            print('Icms_orig_70..............: ' || rlin.icms_orig_70);
                            print('Icms_70...................: ' || rlin.icms_70);
                            print('Icms_Base_70..............: ' || rlin.icms_base_70);
                            print('Icms_Aliq_70..............: ' || rlin.icms_aliq_70);
                            print('Icms_St_70................: ' || rlin.icms_st_70);
                            print('Icms_St_Base_70...........: ' || rlin.icms_st_base_70);
                            print('Icms_St_Aliq_70...........: ' || rlin.icms_st_aliq_70);
                            print('Icms_FCP_perc_70..........: ' || rlin.icms_fcp_perc_70);
                            print('Icms_FCP_70...............: ' || rlin.icms_fcp_70);
                            print('Icms_FCP_Base_70..........: ' || rlin.icms_fcp_base_70);
                            print('Icms_St_FCP_Base_70.......: ' || rlin.icms_fcp_st_base_70);
                            print('Icms_St_FCP_Perc_70.......: ' || rlin.icms_fcp_st_perc_70);
                            print('Icms_St_FCP_70............: ' || rlin.icms_fcp_st_70);
                            print('Icms_CST_70...............: ' || rlin.icms_cst_70);
                            print('Icms_80...................: ' || rlin.icms_80);
                            print('Icms_Base_80..............: ' || rlin.icms_base_80);
                            print('Icms_Aliq_80..............: ' || rlin.icms_aliq_80);
                            print('Icms_St_80................: ' || rlin.icms_st_80);
                            print('Icms_St_Base_80...........: ' || rlin.icms_st_base_80);
                            print('Icms_St_Aliq_80...........: ' || rlin.icms_st_aliq_80);
                            print('Icms_81...................: ' || rlin.icms_81);
                            print('Icms_Base_81..............: ' || rlin.icms_base_81);
                            print('Icms_Aliq_81..............: ' || rlin.icms_aliq_81);
                            print('Icms_St_81................: ' || rlin.icms_st_81);
                            print('Icms_St_Base_81...........: ' || rlin.icms_st_base_81);
                            print('Icms_St_Aliq_81...........: ' || rlin.icms_st_aliq_81);
                            print('Icms_orig_90..............: ' || rlin.icms_orig_90);
                            print('Icms_90...................: ' || rlin.icms_90);
                            print('Icms_Base_90..............: ' || rlin.icms_base_90);
                            print('Icms_Aliq_90..............: ' || rlin.icms_aliq_90);
                            print('Icms_St_90................: ' || rlin.icms_st_90);
                            print('Icms_St_Base_90...........: ' || rlin.icms_st_base_90);
                            print('Icms_St_Aliq_90...........: ' || rlin.icms_st_aliq_90);
                            print('Icms_FCP_perc_90..........: ' || rlin.icms_fcp_perc_90);
                            print('Icms_FCP_90...............: ' || rlin.icms_fcp_90);
                            print('Icms_FCP_Base_90..........: ' || rlin.icms_fcp_base_90);
                            print('Icms_St_FCP_Base_90.......: ' || rlin.icms_fcp_st_base_90);
                            print('Icms_St_FCP_Perc_90.......: ' || rlin.icms_fcp_st_perc_90);
                            print('Icms_St_FCP_90............: ' || rlin.icms_fcp_st_90);
                            print('Icms_CST_90...............: ' || rlin.icms_cst_90);
                            print('Icms_orig_OU..............: ' || rlin.icms_orig_ou);
                            print('Icms_CST_OU...............: ' || rlin.icms_cst_ou);
                            print('Icms_modBC_OU.............: ' || rlin.icms_modbc_ou);
                            print('Icms_Base_OU..............: ' || rlin.icms_base_ou);
                            print('Icms_pRedBC_OU............: ' || rlin.icms_predbc_ou);
                            print('Icms_Aliq_OU..............: ' || rlin.icms_aliq_ou);
                            print('Icms_OU...................: ' || rlin.icms_ou);
                            print('Icms_St_modBC_OU..........: ' || rlin.icms_st_modbc_ou);
                            print('Icms_St_pMVA_OU...........: ' || rlin.icms_st_pmva_ou);
                            print('Icms_St_pRedBC_OU.........: ' || rlin.icms_st_predbc_ou);
                            print('Icms_St_Base_OU...........: ' || rlin.icms_st_base_ou);
                            print('Icms_St_Aliq_OU...........: ' || rlin.icms_st_aliq_ou);
                            print('Icms_St_OU................: ' || rlin.icms_st_ou);
                            print('Icms_St_pBCOp_OU..........: ' || rlin.icms_st_pbcop_ou);
                            print('Icms_St_UF_OU.............: ' || rlin.icms_st_uf_ou);
                            print('Icms_orig_ST..............: ' || rlin.icms_orig_st);
                            print('Icms_CST_ST...............: ' || rlin.icms_cst_st);
                            print('Icms_St_Base_ST...........: ' || rlin.icms_st_base_st);
                            print('Icms_St_ST................: ' || rlin.icms_st_st);
                            print('Icms_St_Base_Dest_ST......: ' || rlin.icms_st_base_dest_st);
                            print('Icms_St_Dest_ST...........: ' || rlin.icms_st_dest_st);
                            print('IcmsSN_orig_101...........: ' || rlin.icmssn_orig_101);
                            print('IcmsSN_CSOSN_101..........: ' || rlin.icmssn_csosn_101);
                            print('IcmsSN_Cr_Aliq_101........: ' || rlin.icmssn_cr_aliq_101);
                            print('IcmsSN_Cr_101.............: ' || rlin.icmssn_cr_101);
                            print('IcmsSN_orig_102...........: ' || rlin.icmssn_orig_102);
                            print('IcmsSN_CSOSN_102..........: ' || rlin.icmssn_csosn_102);
                            print('IcmsSN_orig_201...........: ' || rlin.icmssn_orig_201);
                            print('IcmsSN_CSOSN_201..........: ' || rlin.icmssn_csosn_201);
                            print('IcmsSN_St_modBC_201.......: ' || rlin.icmssn_st_modbc_201);
                            print('IcmsSN_St_pMVA_201........: ' || rlin.icmssn_st_pmva_201);
                            print('IcmsSN_St_Red_Base_201....: ' || rlin.icmssn_st_red_base_201);
                            print('IcmsSN_St_Base_201........: ' || rlin.icmssn_st_base_201);
                            print('IcmsSN_St_Aliq_201........: ' || rlin.icmssn_st_aliq_201);
                            print('IcmsSN_St_201.............: ' || rlin.icmssn_st_201);
                            print('Icms_St_FCP_Base_201......: ' || rlin.icmssn_fcp_st_base_201);
                            print('Icms_St_FCP_Perc_201......: ' || rlin.icmssn_fcp_st_perc_201);
                            print('Icms_St_FCP_201...........: ' || rlin.icmssn_fcp_st_201);
                            print('IcmsSN_Cr_Aliq_201........: ' || rlin.icmssn_cr_aliq_201);
                            print('IcmsSN_Cr_201.............: ' || rlin.icmssn_cr_201);
                            print('IcmsSN_orig_202...........: ' || rlin.icmssn_orig_202);
                            print('IcmsSN_CSOSN_202..........: ' || rlin.icmssn_csosn_202);
                            print('IcmsSN_St_modBC_202.......: ' || rlin.icmssn_st_modbc_202);
                            print('IcmsSN_St_pMVA_202........: ' || rlin.icmssn_st_pmva_202);
                            print('IcmsSN_St_Red_Base_202 ...: ' || rlin.icmssn_st_red_base_202);
                            print('IcmsSN_St_Base_202........: ' || rlin.icmssn_st_base_202);
                            print('IcmsSN_St_Aliq_202........: ' || rlin.icmssn_st_aliq_202);
                            print('IcmsSN_St_202.............: ' || rlin.icmssn_st_202);
                            print('Icms_St_FCP_Base_202......: ' || rlin.icmssn_fcp_st_base_202);
                            print('Icms_St_FCP_Perc_202......: ' || rlin.icmssn_fcp_st_perc_202);
                            print('Icms_St_FCP_202...........: ' || rlin.icmssn_fcp_st_202);
                            print('IcmsSN_orig_500...........: ' || rlin.icmssn_orig_500);
                            print('IcmsSN_CSOSN_500..........: ' || rlin.icmssn_csosn_500);
                            print('IcmsSN_St_Base_500........: ' || rlin.icmssn_st_base_500);
                            print('IcmsSN_St_500.............: ' || rlin.icmssn_st_500);
                            print('IcmsSN_orig_900...........: ' || rlin.icmssn_orig_900);
                            print('IcmsSN_CSOSN_900..........: ' || rlin.icmssn_csosn_900);
                            print('IcmsSN_modBC_900..........: ' || rlin.icmssn_modbc_900);
                            print('IcmsSN_Red_Base_900    ...: ' || rlin.icmssn_red_base_900);
                            print('IcmsSN_Base_900...........: ' || rlin.icmssn_base_900);
                            print('IcmsSN_Aliq_900...........: ' || rlin.icmssn_aliq_900);
                            print('IcmsSN_900................: ' || rlin.icmssn_900);
                            print('IcmsSN_St_modBC_900    ...: ' || rlin.icmssn_st_modbc_900);
                            print('IcmsSN_St_pMVA_900........: ' || rlin.icmssn_st_pmva_900);
                            print('IcmsSN_St_Red_Base_900 ...: ' || rlin.icmssn_st_red_base_900);
                            print('IcmsSN_St_Base_900........: ' || rlin.icmssn_st_base_900);
                            print('IcmsSN_St_Aliq_900........: ' || rlin.icmssn_st_aliq_900);
                            print('IcmsSN_St_900.............: ' || rlin.icmssn_st_900);
                            print('Icms_St_FCP_Base_900......: ' || rlin.icmssn_fcp_st_base_900);
                            print('Icms_St_FCP_Perc_900......: ' || rlin.icmssn_fcp_st_perc_900);
                            print('Icms_St_FCP_900...........: ' || rlin.icmssn_fcp_st_900);
                            print('IcmsSN_Cr_Aliq_900........: ' || rlin.icmssn_cr_aliq_900);
                            print('IcmsSN_Cr_900.............: ' || rlin.icmssn_cr_900);
                            print('Ipi.......................: ' || rlin.ipi);
                            print('Ipi_Base..................: ' || rlin.ipi_base);
                            print('Ipi_Qtd...................: ' || rlin.ipi_qtd);
                            print('Ipi_Unit..................: ' || rlin.ipi_unit);
                            print('Ipi_Trib_CST..............: ' || rlin.ipi_trib_cst);
                            print('Ipi_Aliq..................: ' || rlin.ipi_aliq);
                            print('Ipi_NT_CST................: ' || rlin.ipi_nt_cst);
                            print('PisQTD_CST................: ' || rlin.pisqtd_cst);
                            print('PisNT_CST.................: ' || rlin.pisnt_cst);
                            print('PisOUT_CST................: ' || rlin.pisout_cst);
                            print('PisALQ_CST................: ' || rlin.pisalq_cst);
                            print('Pis.......................: ' || rlin.pis);
                            print('Pis_Base..................: ' || rlin.pis_base);
                            print('Pis_Aliq..................: ' || rlin.pis_aliq);
                            print('CofinsQT_QTY..............: ' || rlin.cofinsqt_qty);
                            print('CofinsQT_Un_Amt...........: ' || rlin.cofinsqt_un_amt);
                            print('CofinsQT_Amount...........: ' || rlin.cofinsqt_amount);
                            print('CofinsQT_CST..............: ' || rlin.cofinsqt_cst);
                            print('CofinsNT_CST..............: ' || rlin.cofinsnt_cst);
                            print('CofinsOU_Base.............: ' || rlin.cofinsou_base);
                            print('CofinsOU_Aliq.............: ' || rlin.cofinsou_aliq);
                            print('CofinsOU_QTY..............: ' || rlin.cofinsou_qty);
                            print('CofinsOU_Un_Amt...........: ' || rlin.cofinsou_un_amt);
                            print('CofinsOU_Amount...........: ' || rlin.cofinsou_amount);
                            print('CofinsOU_CST..............: ' || rlin.cofinsou_cst);
                            print('CofinsAL_CST..............: ' || rlin.cofinsal_cst);
                            print('CofinsAL_Amount...........: ' || rlin.cofinsal_amount);
                            print('CofinsAL_Base.............: ' || rlin.cofinsal_base);
                            print('CofinsAL_Aliq.............: ' || rlin.cofinsal_aliq);
              --
                            print('RefnNF....................: ' || rlin.refnnf);
                            print('RefdatNF..................: ' || rlin.refdatnf);
                            print('RefvQtd...................: ' || rlin.refvqtd);
                            print('RefKeyNF..................: ' || rlin.refkeynf);
                            print('FCI.......................: ' || rlin.nfci);
                            print('Pedido....................: ' || regexp_substr(
                                regexp_replace(rlin.pedido, ' ', '-'),
                                '[^-|$-]+',
                                1,
                                1
                            ));

                            print('Release...................: ' || regexp_substr(
                                regexp_replace(rlin.pedido, ' ', '-'),
                                '[^-|$-]+',
                                1,
                                2
                            ));

                            print('indISS....................: ' || rlin.indiss);
              --inserir variaveis
              -- SELECT * FROM xxrmais_invoice_lines
                            g_source_l.line_id := rmais_efd_lines_s.nextval;
                            g_source_l.header_id := l_header.efd_header_id;
                            g_source_l.line_num := rlin.line_num;
                            g_source_l.cod_produto := rlin.cod_produto;
                            g_source_l.des_produto := rlin.des_produto;
                            g_source_l.pedido := rlin.pedido;
                            g_source_l.uom := rlin.uom;
                            g_source_l.qtde := to_number ( rlin.qtd_prod );
                            g_source_l.valor_unit := rlin.valor_unit;
                            g_source_l.valor_total := rlin.valor_tot;
                            g_source_l.ncm := rlin.ncm;
                            g_source_l.cst := nvl(
                                lpad(rlin.icms_cst, 2, '0'),
                                rlin.icmssn_csosn
                            );

                            g_source_l.cfop := rlin.cfo;
                            g_source_l.bc_icms := nvl(rlin.icms_base, 0);
                            g_source_l.v_icms := nvl(rlin.icms, 0);
                            g_source_l.v_ipi := nvl(rlin.ipi, 0);
                            g_source_l.aliq_icms := nvl(rlin.icms_aliq, 0);
                            g_source_l.aliq_ipi := nvl(rlin.ipi_aliq, 0);
              --
                            print('Inserindo linha: ' || g_source_l.line_num);
              --
              --INSERT INTO xxrmais_invoice_lines VALUES g_source_l;
              --
             /* rSource.rLines(vIDX).Reg.Purchase_order_num        := rLin.Pedido;
              rSource.rLines(vIDX).Reg.Operation_Fiscal_Type     := rLin.xNaturOper; --Regc.xOperFiscal;
              rSource.rLines(vIDX).Reg.Line_Num                  := nvl(rLin.Line_Num, rLin.Line_num_Ped);
              rSource.rLines(vIDX).Reg.Item_Number               := nvl(rLin.Line_Num, rLin.Line_num_Ped);
              rSource.rLines(vIDX).Reg.Shipment_Num              := rLin.Shipment_Num;
              rSource.rLines(vIDX).Reg.Item_Id                   := Get_Item(rSource.rHead.Organization_id, rLin.Cod_Produto);
              rSource.rLines(vIDX).Reg.UOM                       := rLin.xUOM;
              rSource.rLines(vIDX).Reg.Description               := rLin.Des_Produto;
              rSource.rLines(vIDX).Reg.Utilization_Code          := rLin.utilizacao;
              rSource.rLines(vIDX).Reg.Cfo_Code                  := rLin.xCfo;
              rSource.rLines(vIDX).Reg.Fci_Number                := rLin.nFCI;
              rSource.rLines(vIDX).Cfo_Saida                     := rLin.Cfo;
              rSource.rLines(vIDX).Cst_Origem                    := REPLACE(rLin.Icms_Orig,1,2);
              rSource.rLines(vIDX).Cst_Pis                       := rLin.Pis_CST;
              rSource.rLines(vIDX).Cst_Cofins                    := rLin.Cofins_CST;
              rSource.rLines(vIDX).Cst_Icms                      := NVL(LPAD(rLin.ICMS_CST,2,'0'), rLin.IcmsSN_CSOSN);
              rSource.rLines(vIDX).Cst_Ipi                       := rLin.Ipi_CST;
              rSource.rLines(vIDX).Chave                         := rLin.Chave;
              rSource.rLines(vIDX).Cod_Produto                   := rLin.Cod_Produto;
            --rSource.rLines(vIDX).xCod_Produto                  := rLin.xCod_Produto;
              rSource.rLines(vIDX).Des_Produto                   := rLin.Des_Produto;
            --rSource.rLines(vIDX).xDes_Produto                  := rLin.xDes_Produto;
              rSource.rLines(vIDX).Cod_Barras                    := rLin.Cod_Barras;
              rSource.rLines(vIDX).Ocurr_Seq                     := rLin.Ocurr_Seq;
              rSource.rLines(vIDX).Ocurr_Tot                     := rLin.Ocurr_Tot;
              rSource.rLines(vIDX).Qtd_Orig                      := rLin.Qtd_Orig;
              rSource.rLines(vIDX).Reg.Net_amount                := rLin.Valor_Tot;
              rSource.rLines(vIDX).Reg.Quantity                  := NVL(REPLACE(TRIM(rLin.Qtd_Prod),',','.'),0);
              rSource.rLines(vIDX).Reg.Unit_Price                := CASE WHEN rSource.rLines(vIDX).Reg.Quantity > 0 THEN rLin.Valor_Tot/rSource.rLines(vIDX).Reg.Quantity ELSE 0 END;
              --
              --
              rSource.rLines(vIDX).Reg.fcp_base_amount           := rLin.icms_Fcp_base;
              rSource.rLines(vIDX).Reg.fcp_rate                  := rLin.Icms_Fcp_perc;
              rSource.rLines(vIDX).Reg.fcp_amount                := rLin.Icms_Fcp;
              rSource.rLines(vIDX).Reg.fcp_st_base_amount        := rLin.Icms_St_Fcp_base;
              rSource.rLines(vIDX).Reg.fcp_st_rate               := rLin.Icms_St_Fcp_perc;
              rSource.rLines(vIDX).Reg.fcp_st_amount             := rLin.Icms_St_Fcp;
              --
              rSource.rLines(vIDX).Reg.Icms_Tax                  := NVL(rLin.Icms_Aliq,   0);
              rSource.rLines(vIDX).Reg.Icms_Base                 := NVL(rLin.Icms_Base,   0);
              rSource.rLines(vIDX).Reg.Icms_Amount               := NVL(rLin.Icms,        0);
              rSource.rLines(vIDX).Reg.Icms_St_Base              := NVL(rLin.Icms_St_Base,0);
              rSource.rLines(vIDX).Reg.Icms_St_Amount            := NVL(rLin.Icms_St,     0);
              rSource.rLines(vIDX).Reg.Icms_Amount_Recover       := rLin.IcmsSN_Cr;
              rSource.rLines(vIDX).Reg.Icms_Tax_rec_simpl_br     := rLin.IcmsSN_Cr_Aliq;
              rSource.rLines(vIDX).Reg.Icms_St_Amount_Recover    := 0;
              rSource.rLines(vIDX).Reg.Diff_Icms_Tax             := 0;
              rSource.rLines(vIDX).Reg.Diff_Icms_Amount          := 0;
              rSource.rLines(vIDX).Reg.Diff_Icms_Amount_Recover  := 0;
              rSource.rLines(vIDX).Reg.Deferred_icms_amount      := rLin.Deferred_Icms_Amt;
              rSource.rLines(vIDX).Reg.Tributary_status_code_out := rSource.rLines(vIDX).Cst_Origem||rSource.rLines(vIDX).Cst_Icms;
              rSource.rLines(vIDX).Reg.Icms_Tax_Code             := CASE WHEN Regc.CRT = 1 THEN 2 ELSE 3 END;*/
              --
              --
            /*  rSource.rLines(vIDX).Reg.Ipi_Amount_Recover        := 0;
              rSource.rLines(vIDX).Reg.Ipi_Tax                   := NVL(rLin.Ipi_Aliq,0);
              rSource.rLines(vIDX).Reg.Ipi_tributary_code        := rLin.Ipi_CST;
              rSource.rLines(vIDX).Reg.Ipi_tributary_type        := rLin.Ipi_Type;
              rSource.rLines(vIDX).Reg.Ipi_tributary_code_out    := rLin.Ipi_CST;
              rSource.rLines(vIDX).Reg.Ipi_Base_Amount           := NVL(rLin.IPI_Base,0);
              rSource.rLines(vIDX).Reg.Ipi_Amount                := NVL(rLin.Ipi,     0);
              rSource.rLines(vIDX).Reg.Ipi_Unit_Amount           := rLin.Ipi_Unit;
              rSource.rLines(vIDX).Reg.Ipi_Tax_Code              := CASE WHEN Regc.CRT = 1 THEN 2 END;
              --
              rSource.rLines(vIDX).Reg.Pis_Amount_Recover        := 0;
              rSource.rLines(vIDX).Reg.Pis_Base_Amount           := NVL(rLin.Pis_Base,0);
              rSource.rLines(vIDX).Reg.Pis_tax_rate              := NVL(rLin.Pis_Aliq,0);
              rSource.rLines(vIDX).Reg.Pis_Qty                   := rLin.Pis_QTY;
              rSource.rLines(vIDX).Reg.Pis_Unit_Amount           := rLin.Pis_Un_Amt;
              rSource.rLines(vIDX).Reg.Pis_Amount                := NVL(rLin.Pis,0);
              rSource.rLines(vIDX).Reg.Pis_tributary_code        := rLin.Pis_CST;
              rSource.rLines(vIDX).Reg.Pis_tributary_code_out    := rLin.Pis_CST;
              --
              rSource.rLines(vIDX).Reg.Cofins_Amount_Recover     := 0;
              rSource.rLines(vIDX).Reg.Cofins_Base_amount        := rLin.Cofins_Base;
              rSource.rLines(vIDX).Reg.Cofins_Tax_rate           := rLin.Cofins_Aliq;
              rSource.rLines(vIDX).Reg.Cofins_Qty                := rLin.Cofins_QTY;
              rSource.rLines(vIDX).Reg.Cofins_Unit_amount        := rLin.Cofins_Un_Amt;
              rSource.rLines(vIDX).Reg.Cofins_Amount             := NVL(rLin.Cofins_Amount,0);
              rSource.rLines(vIDX).Reg.Cofins_tributary_code     := rLin.Cofins_CST;
              rSource.rLines(vIDX).Reg.Cofins_tributary_code_out := rLin.Cofins_CST;
              --
              rSource.rLines(vIDX).Reg.Iss_Base_Amount           := 0;
              rSource.rLines(vIDX).Reg.Iss_Tax_Amount            := 0;
              --
              rSource.rLines(vIDX).Reg.Classification_code       := rLin.Ncm;
              rSource.rLines(vIDX).Reg.Freight_Amount            := NVL(rLin.vFrete,     0);
              rSource.rLines(vIDX).Reg.Discount_Amount           := NVL(rLin.Desconto,   0);
              rSource.rLines(vIDX).Reg.Discount_Net_Amount       := NVL(rLin.Desconto,   0);
              rSource.rLines(vIDX).Reg.Other_Expenses            := NVL(rLin.Outras_Desp,0);
              rSource.rLines(vIDX).Reg.Insurance_amount          := NVL(rLin.Seguro,     0);
              --
              rSource.rEfd.org_id                                := rSource.rCtrl.Operating_unit;
              rSource.rLines(vIDX).rEfd.Item_Code                := rLin.Cod_Produto;
              rSource.rLines(vIDX).rEfd.Uom_from                 := rLin.Uom;
              rSource.rLines(vIDX).rEfd.goods_origin_from        := rSource.rLines(vIDX).Cst_Origem;
              rSource.rLines(vIDX).rEfd.icms_cst_from            := rSource.rLines(vIDX).Cst_Icms;
              rSource.rLines(vIDX).rEfd.Cfop_from                := rSource.rLines(vIDX).Cfo_Saida;
              rSource.rLines(vIDX).rEfd.source_document_type     := rSource.rEfd.source_document_type;*/
              --
                            begin
                                l_lines.efd_line_id := rmais_efd_lines_s.nextval;
                                l_lines.efd_header_id := l_header.efd_header_id;
                                l_lines.source_doc_number :=
                                    case
                                        when rlin.pedido like '%OC%' then
                                            rlin.pedido
                                        else
                                            null
                                    end;
                --rSource.rLines(vIDX).Release_num                   := CASE WHEN regexp_substr(regexp_replace(rLin.Pedido,' ','-'),'[^-|$-]+',1,2) LIKE '%/%' THEN ''
                --                                                      ELSE
                --                                                        regexp_substr(regexp_replace(rLin.Pedido,' ','-'),'[^-|$-]+',1,2)
                --                                                      END;
                                l_lines.ri_operation_fiscal_type := rlin.xnaturoper; --Regc.xOperFiscal;
               -- l_line.Reg.Line_Num                  := nvl(rLin.Line_Num, rLin.Line_num_Ped);
                                l_lines.line_number := nvl(rlin.line_num, rlin.line_num_ped);
                                l_lines.source_doc_line_num :=
                                    case
                                        when rlin.pedido like '%OC%' then
                                            rlin.line_num_ped
                                        else
                                            null
                                    end; 
                --l_line.Reg.Shipment_Num              := rLin.Shipment_Num;
                --l_line.Reg.Item_Id                   := Get_Item(rSource.rHead.Organization_id, rLin.Cod_Produto);
                                l_lines.uom_to := rlin.xuom;
                                l_lines.item_description := rlin.des_produto;
                --l_line.Utilization_Code          := rLin.utilizacao;
                                l_lines.cfop_to := rlin.xcfo;
                                l_lines.fci_number := rlin.nfci;
                                l_lines.cfop_from := rlin.cfo;
                                l_lines.goods_origin_from := replace(rlin.icms_orig, 1, 2);
                                l_lines.pis_cst_to := rlin.pis_cst;
                                l_lines.cofins_cst_to := rlin.cofins_cst;
                                l_lines.icms_cst_from := nvl(
                                    lpad(rlin.icms_cst, 2, '0'),
                                    rlin.icmssn_csosn
                                );

                                l_lines.ipi_cst_to := rlin.ipi_cst;
                --l_line.Chave                         := rLin.Chave;
                                l_lines.item_code := rlin.cod_produto;
              --l_line.xCod_Produto                  := rLin.xCod_Produto;
                                l_lines.item_description := rlin.des_produto;
              --l_line.xDes_Produto                  := rLin.xDes_Produto;
                --l_line.Cod_Barras                    := rLin.Cod_Barras;
                --l_line.Ocurr_Seq                     := rLin.Ocurr_Seq;
                --l_line.Ocurr_Tot                     := rLin.Ocurr_Tot;
                --l_line.Qtd_Orig                      := rLin.Qtd_Orig;
                                l_lines.line_amount := rlin.valor_tot;
                                l_lines.line_quantity := nvl(
                                    replace(
                                        trim(rlin.qtd_prod),
                                        ',',
                                        '.'
                                    ),
                                    0
                                );

                                l_lines.unit_price := rlin.valor_unit;----CASE WHEN rSource.rLines(vIDX).Reg.Quantity > 0 THEN rLin.Valor_Tot/rSource.rLines(vIDX).Reg.Quantity ELSE 0 END;
                --
              /*rSource.rLines(vIDX).Reg.Icms_Base                 := NVL(rLin.Icms_Base, CASE WHEN rSource.rLines(vIDX).Reg.Icms_Tax > 0 THEN NVL(rLin.Valor_Tot,0) ELSE 0 END);
                rSource.rLines(vIDX).Reg.Icms_Amount               := NVL(rLin.Icms, CASE WHEN rSource.rLines(vIDX).Reg.Icms_Tax > 0 THEN rSource.rLines(vIDX).Reg.Icms_Base * rSource.rLines(vIDX).Reg.Icms_Tax/100 ELSE 0 END);
                rSource.rLines(vIDX).Reg.Icms_Amount_Recover       := CASE WHEN NVL(rLin.IcmsSN_Cr,0) > 0 THEN rLin.IcmsSN_Cr ELSE rSource.rLines(vIDX).Reg.Icms_Amount END;*/
                --
                --
                                l_lines.fcp_base_amount := rlin.icms_fcp_base;
                                l_lines.fcp_rate := rlin.icms_fcp_perc;
                                l_lines.fcp_amount := rlin.icms_fcp;
                                l_lines.fcp_st_base_amount := rlin.icms_st_fcp_base;
                                l_lines.fcp_st_rate := rlin.icms_st_fcp_perc;
                                l_lines.fcp_st_amount := rlin.icms_st_fcp;
                --
                                l_lines.icms_rate := nvl(rlin.icms_aliq, 0);
                                l_lines.icms_calc_basis := nvl(rlin.icms_base, 0);
                                l_lines.icms_amount := nvl(rlin.icms, 0);
                                l_lines.icms_st_calc_basis := nvl(rlin.icms_st_base, 0);
                                l_lines.icms_st_amount := nvl(rlin.icms_st, 0);
                                l_lines.simplified_icms_credit_amount := rlin.icmssn_cr;
                                l_lines.simplified_icms_rate := rlin.icmssn_cr_aliq;
                --l_lines.Icms_St_Amount_Recover    := 0;
                --l_lines.Diff_Icms_Tax             := 0;
                --l_lines.Diff_Icms_Amount          := 0;
                --l_lines.Diff_Icms_Amount_Recover  := 0;
                --l_line.Deferred_icms_amount      := rLin.Deferred_Icms_Amt;
                --l_line.Tributary_status_code_out := rSource.rLines(vIDX).Cst_Origem||rSource.rLines(vIDX).Cst_Icms;
                                l_lines.icms_taxable_flag :=
                                    case
                                        when regc.crt = 1 then
                                            2
                                        else
                                            3
                                    end;
                --
                --l_lines.city_service_type_rel_code := rLin.Iss_listserv;
                --
                --
                --
                --l_lines.Ipi_Amount_Recover          := 0;
                                l_lines.ipi_rate := nvl(rlin.ipi_aliq, 0);
                                l_lines.ipi_cst_to := rlin.ipi_cst;
                                l_lines.ipi_tributary_type := rlin.ipi_type;
                                l_lines.ipi_cst_from := rlin.ipi_cst;
                                l_lines.ipi_calc_basis := nvl(rlin.ipi_base, 0);
                                l_lines.ipi_amount := nvl(rlin.ipi, 0);
                                l_lines.ipi_unit_amount := rlin.ipi_unit;
                                l_lines.ipi_taxable_flag :=
                                    case
                                        when regc.crt = 1 then
                                            2
                                    end;
                --
                --l_lines.Pis_Amount_Recover          := 0;
                                l_lines.pis_calc_basis := nvl(rlin.pis_base, 0);
                                l_lines.pis_rate := nvl(rlin.pis_aliq, 0);
                                l_lines.pis_base_quantity := rlin.pis_qty;
                                l_lines.pis_unit_amount := rlin.pis_un_amt;
                                l_lines.pis_amount := nvl(rlin.pis, 0);
                                l_lines.pis_cst_to := rlin.pis_cst;
                                l_lines.pis_cst_from := rlin.pis_cst;
                --
                --l_lines.Cofins_Amount_Recover       := 0;
                                l_lines.cofins_calc_basis := rlin.cofins_base;
                                l_lines.cofins_rate := rlin.cofins_aliq;
                                l_lines.cofins_base_quantity := rlin.cofins_qty;
                                l_lines.cofins_unit_amount := rlin.cofins_un_amt;
                                l_lines.cofins_amount := nvl(rlin.cofins_amount, 0);
                                l_lines.cofins_cst_to := rlin.cofins_cst;
                                l_lines.cofins_cst_from := rlin.cofins_cst;
                --
                                l_lines.iss_base_amount := 0;
                                l_lines.iss_tax_amount := 0;
                --
                                l_lines.fiscal_classification :=
                                    case
                                        when regc.cmun_emit = '5300108'
                                             and regc.modelo = '55'
                                             and instr(rlin.clistserv, '.') > 0 then
                                            rlin.clistserv
                                        else
                                            rlin.ncm
                                    end; -- Robson 16/03/2023
                                l_lines.freight_line_amount := nvl(rlin.vfrete, 0);
                                l_lines.discount_line_amount := nvl(rlin.desconto, 0);
                --l_lines.Discount_Net_Amount         := NVL(rLin.Desconto,   0);
                                l_lines.other_expenses_line_amount := nvl(rlin.outras_desp, 0);
                                l_lines.insurance_line_amount := nvl(rlin.seguro, 0);
                --
                --rSource.rEfd.org_id                                := rSource.rCtrl.Operating_unit;
                                l_lines.item_code := rlin.cod_produto;
                                l_lines.uom_from := rlin.uom;
                                l_lines.goods_origin_from := replace(rlin.icms_orig, 1, 2);
                                l_lines.creation_date := sysdate;
                                l_lines.created_by := -1;
                                l_lines.last_update_date := sysdate;
                                l_lines.last_updated_by := -1;
                                update rmais_efd_headers_hdi a -- Robson (15/03/2023) start
                                set
                                    a.iss_ret_flag =
                                        case
                                            when nvl(rlin.indiss, 0) = 1 then
                                                'Y'
                                            else
                                                'N'
                                        end,
                                    a.iss_amount =
                                        case
                                            when regc.cmun_emit = '5300108'
                                                 and regc.modelo = '55'
                                                 and instr(rlin.clistserv, '.') > 0 then
                                                regc.iss_amount_a
                                            else
                                                a.iss_amount
                                        end
                                where
                                    a.efd_header_id = l_id_header; -- Robson (15/03/2023) end

                --l_lines.icms_cst_from            := rSource.rLines(vIDX).Cst_Icms;
                --l_lines.Cfop_from                := rSource.rLines(vIDX).Cfo_Saida;
                --l_lines.source_document_type     := rSource.rEfd.source_document_type;
                                print('Atribuido variáveis da linha');
                                if nvl(g_ctrl.status, 'P') not in ( 'D', 'E' ) then
                  --
                                    if
                                        regc.cmun_emit = '5300108'
                                        and regc.modelo = '55'
                                        and instr(rlin.clistserv, '.') > 0
                                        and nvl(l_unic_line_danfe_df, 0) = 1
                                    then -- Robson 17/03/2023 start
                                        l_lines.line_quantity := 1;
                                        l_lines.unit_price := regc.v_total_nf;
                                        l_lines.line_amount := regc.v_total_nf;
                                        insert into rmais_efd_lines_hdi values l_lines;

                                        exit;
                                    else
                                        insert into rmais_efd_lines_hdi values l_lines;

                                    end if; -- Robson 17/03/2023 end
                  --
                                else
                  --
                                    print('Linhas não inseridas em decorrência de erro do Header');
                  --
                                end if;
                --
                            exception
                                when others then
                                    print('Error ao atribuir variáveis linha: ' || sqlerrm);
                            end;
              --
                        exception
                            when others then
                                print('Falha ao carregar Linhas NFe >> ' || sqlerrm, 1);
                        end;
            --
                        l_lines := null;
                    end loop;  -- Reg
          --

                    begin
                        commit;
                        print('Call main - 2-ini *************************************************************************************'
                        );
             --rmais_process_pkg.main(p_header_id => l_header.efd_header_id , p_flag_auto => 'Y', p_send_erp => 'Y');
                        print('Call main - 2-ter *************************************************************************************'
                        );
                        commit;
                    exception
                        when others then
            --raise_application_error (-20011,'Erro ao reprocessar documento '||sqlerrm);
                            null;
                    end;
          --
                end loop; -- Regc
        --
                if g_ctrl.status is null then
          --
                    g_ctrl.status := 'P';
          --
                end if;
            exception
                when others then
                    print('Erro ao processar arquivo NFe >> ' || sqlerrm, 1);
            end;
      --
     --
    --Finalizar;
    --
        exception
            when others then
      --
                print('Falha geral NFe!' || sqlerrm, 1);
      --
        end load_nfe;
  --
    ---------------------------------
  -- Processo para caregar o xml --
  -- da nota fiscal do tipo CTE  --
  ---------------------------------
        procedure load_read_file_xml_cteos (
            psource clob
        ) is
            vidx number;
        begin
    --
    --------------------------------------------
    -- Buscando informações do CTEOS          --
    --------------------------------------------
            for rcte in (
                select
                    r.cuf,
                    r.cct,
                    r.cfop,
                    r.natop,
                    r.mod,
                    r.serie,
                    r.nct,
                    r.dhemi,
                    r.tpimp,
                    r.tpemis,
                    r.cdv,
                    r.tpamb,
                    r.tpcte,
                    r.procemi,
                    r.verproc,
                    r.cmunenv,
                    r.xmunenv,
                    r.ufenv,
                    r.modal,
                    r.tpserv,
                    r.indietoma,
                    r.cmunini,
                    r.xmunini,
                    r.ufini,
                    r.cmunfim,
                    r.xmunfim,
                    r.uffim,
                    r.compl,
                    r.emit_cnpj,
                    r.emit_ie,
                    r.emit_xnome,
                    r.emit_xlgr,
                    r.emit_nro,
                    r.emit_xcpl,
                    r.emit_xbairro,
                    r.emit_cmun,
                    r.emit_xmun,
                    r.emit_cep,
                    r.emit_uf,
                    r.emit_fone,
                    r.toma_cnpj,
                    r.toma_ie,
                    r.toma_xnome,
                    r.fone,
                    r.toma_xlgr,
                    r.toma_nro,
                    r.toma_xcpl,
                    r.toma_xbairro,
                    r.toma_cmun,
                    r.toma_xmun,
                    r.toma_cep,
                    r.toma_uf,
                    r.toma_cpais,
                    r.toma_xpais,
                    r.vtprest,
                    r.vrec,
                    nvl(
                        nvl(
                            nvl(
                                nvl(r.cst_icms00, r.cst_icms45),
                                r.cst_icms90
                            ),
                            r.cst_icmssn
                        ),
                        r.cst_icms_out
                    )                          cst_icms,
                    nvl(
                        nvl(r.vbc_00, r.vbc_90),
                        r.vbc_out
                    )                          icms_bc,
                    nvl(
                        nvl(
                            nvl(r.picms_00, r.picms_90),
                            r.picms_90
                        ),
                        picms_out
                    )                          icms_tax,
                    nvl(vicms_90, vicms_00)    icms_amount,
                    nvl(predbc_90, predbc_out) icms_bc_red,
                    vcred_90                   vcred,
                    xdescserv,
                    1                          quantidade,
                    chave,
                    xobs
                from
                    ( xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/cte' ),
                    '/cteOSProc'
                            passing xmltype(psource)
                        columns
                                            -- cUF          VARCHAR2(150)    Path 'infCte/ide/cUF/text()',
                                            -- natOp        VARCHAR2(150)    Path 'infCte/ide/natOp/text()'
                            cuf varchar2(150) path 'CTeOS/infCte/ide/cUF/text()',
                            cct varchar2(150) path 'CTeOS/infCte/ide/cCT/text()',
                            cfop varchar2(150) path 'CTeOS/infCte/ide/CFOP/text()',
                            natop varchar2(150) path 'CTeOS/infCte/ide/natOp/text()',
                            mod varchar2(150) path 'CTeOS/infCte/ide/mod/text()',
                            serie varchar2(150) path 'CTeOS/infCte/ide/serie/text()',
                            nct varchar2(150) path 'CTeOS/infCte/ide/nCT/text()',
                            dhemi varchar2(150) path 'CTeOS/infCte/ide/dhEmi/text()',
                            tpimp varchar2(150) path 'CTeOS/infCte/ide/tpImp/text()',
                            tpemis varchar2(150) path 'CTeOS/infCte/ide/tpEmis/text()',
                            cdv varchar2(150) path 'CTeOS/infCte/ide/cDV/text()',
                            tpamb varchar2(150) path 'CTeOS/infCte/ide/tpAmb/text()',
                            tpcte varchar2(150) path 'CTeOS/infCte/ide/tpCTe/text()',
                            procemi varchar2(150) path 'CTeOS/infCte/ide/procEmi/text()',
                            verproc varchar2(150) path 'CTeOS/infCte/ide/verProc/text()',
                            cmunenv varchar2(150) path 'CTeOS/infCte/ide/cMunEnv/text()',
                            xmunenv varchar2(150) path 'CTeOS/infCte/ide/xMunEnv/text()',
                            ufenv varchar2(150) path 'CTeOS/infCte/ide/UFEnv/text()',
                            modal varchar2(150) path 'CTeOS/infCte/ide/modal/text()',
                            tpserv varchar2(150) path 'CTeOS/infCte/ide/tpServ/text()',
                            indietoma varchar2(150) path 'CTeOS/infCte/ide/indIEToma/text()',
                            cmunini varchar2(150) path 'CTeOS/infCte/ide/cMunIni/text()',
                            xmunini varchar2(150) path 'CTeOS/infCte/ide/xMunIni/text()',
                            ufini varchar2(150) path 'CTeOS/infCte/ide/UFIni/text()',
                            cmunfim varchar2(150) path 'CTeOS/infCte/ide/cMunFim/text()',
                            xmunfim varchar2(150) path 'CTeOS/infCte/ide/xMunFim/text()',
                            uffim varchar2(150) path 'CTeOS/infCte/ide/UFFim/text()',
                            compl clob path 'CTeOS/infCte/compl/xObs/text()',
                            emit_cnpj varchar2(150) path 'CTeOS/infCte/emit/CNPJ/text()',
                            emit_ie varchar2(150) path 'CTeOS/infCte/emit/IE/text()',
                            emit_xnome varchar2(600) path 'CTeOS/infCte/emit/xNome/text()',
                            emit_xlgr varchar2(200) path 'CTeOS/infCte/emit/enderEmit/xLgr/text()',
                            emit_nro varchar2(200) path 'CTeOS/infCte/emit/enderEmit/nro/text()',
                            emit_xcpl varchar2(200) path 'CTeOS/infCte/emit/enderEmit/xCpl/text()',
                            emit_xbairro varchar2(200) path 'CTeOS/infCte/emit/enderEmit/xBairro/text()',
                            emit_cmun varchar2(200) path 'CTeOS/infCte/emit/enderEmit/cMun/text()',
                            emit_xmun varchar2(200) path 'CTeOS/infCte/emit/enderEmit/xMun/text()',
                            emit_cep varchar2(200) path 'CTeOS/infCte/emit/enderEmit/CEP/text()',
                            emit_uf varchar2(200) path 'CTeOS/infCte/emit/enderEmit/UF/text()',
                            emit_fone varchar2(200) path 'CTeOS/infCte/emit/enderEmit/fone/text()',
                            toma_cnpj varchar2(200) path 'CTeOS/infCte/toma/CNPJ/text()',
                            toma_ie varchar2(200) path 'CTeOS/infCte/toma/IE/text()',
                            toma_xnome varchar2(200) path 'CTeOS/infCte/toma/xNome/text()',
                            fone varchar2(200) path 'CTeOS/infCte/toma/fone/text()',
                            toma_xlgr varchar2(600) path 'CTeOS/infCte/toma/enderToma/xLgr/text()',
                            toma_nro varchar2(600) path 'CTeOS/infCte/toma/enderToma/nro/text()',
                            toma_xcpl varchar2(600) path 'CTeOS/infCte/toma/enderToma/xCpl/text()',
                            toma_xbairro varchar2(600) path 'CTeOS/infCte/toma/enderToma/xBairro/text()',
                            toma_cmun varchar2(300) path 'CTeOS/infCte/toma/enderToma/cMun/text()',
                            toma_xmun varchar2(300) path 'CTeOS/infCte/toma/enderToma/xMun/text()',
                            toma_cep varchar2(20) path 'CTeOS/infCte/toma/enderToma/CEP/text()',
                            toma_uf varchar2(30) path 'CTeOS/infCte/toma/enderToma/UF/text()',
                            toma_cpais varchar2(200) path 'CTeOS/infCte/toma/enderToma/cPais/text()',
                            toma_xpais varchar2(200) path 'CTeOS/infCte/toma/enderToma/xPais/text()',
                            vtprest number path 'CTeOS/infCte/vPrest/vTPrest/text()',
                            vrec number path 'CTeOS/infCte/vPrest/vRec/text()',
                                            --
                            cst_icms00 varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMS00/CST/text()',--
                            vbc_00 varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMS00/vBC/text()',
                            picms_00 varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMS00/pICMS/text()',
                            vicms_00 varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMS00/vICMS/text()',
                                            --
                            cst_icms45 varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMS45/CST/text()',
                                            --
                                            --
                                            --
                            cst_icms90 varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMS90/CST/text()',
                            vbc_90 varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMS90/vBC/text()',
                            picms_90 varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMS90/pICMS/text()',
                            vicms_90 varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMS90/vICMS/text()',
                            predbc_90 varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMS90/pRedBC/text()',
                            vcred_90 varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMS90/vCred/text()',                      
                                            --
                            cst_icmsoutrauf varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMSOutraUF/CST/text()',
                                            --
                            cst_icmssn varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMSSN/CST/text()',
                                            --
                                            --
                            cst_icms_out varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMSOutraUF/CST/text()',
                            vbc_out varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMSOutraUF/vBCOutraUF/text()',
                            picms_out varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMSOutraUF/pICMSOutraUF/text()',
                            vicms_out varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMSOutraUF/vICMSOutraUF/text()',
                            predbc_out varchar2(200) path 'CTeOS/infCte/imp/ICMS/ICMSOutraUF/pRedBCOutraUF/text()',
                                            --
                            xdescserv varchar2(4000) path 'CTeOS/infCte/infCTeNorm/infServico/xDescServ/text()',
                                            --
                            chave varchar2(150) path 'protCTe/infProt/chCTe/text()',
                            xobs varchar2(150) path 'CTeOS/infCte/compl/xObs/text()'
                                            --
                    ) ) r
            ) loop
             --
                print('rcte.cUF...................: ' || rcte.cuf);
                print('rcte.cCT...................: ' || rcte.cct);
                print('rcte.CFOP..................: ' || rcte.cfop);
                print('rcte.natOp.................: ' || rcte.natop);
                print('rcte.mod...................: ' || rcte.mod);
                print('rcte.serie.................: ' || rcte.serie);
                print('rcte.nCT...................: ' || rcte.nct);
                print('rcte.dhEmi.................: ' || rcte.dhemi);
                print('rcte.tpImp.................: ' || rcte.tpimp);
                print('rcte.tpEmis................: ' || rcte.tpemis);
                print('rcte.cDV...................: ' || rcte.cdv);
                print('rcte.tpAmb.................: ' || rcte.tpamb);
                print('rcte.tpCTe.................: ' || rcte.tpcte);
                print('rcte.procEmi...............: ' || rcte.procemi);
                print('rcte.verProc...............: ' || rcte.verproc);
                print('rcte.cMunEnv...............: ' || rcte.cmunenv);
                print('rcte.xMunEnv...............: ' || rcte.xmunenv);
                print('rcte.UFEnv.................: ' || rcte.ufenv);
                print('rcte.modal.................: ' || rcte.modal);
                print('rcte.tpServ................: ' || rcte.tpserv);
                print('rcte.indIEToma.............: ' || rcte.indietoma);
                print('rcte.cMunIni...............: ' || rcte.cmunini);
                print('rcte.xMunIni...............: ' || rcte.xmunini);
                print('rcte.UFIni.................: ' || rcte.ufini);
                print('rcte.cMunFim...............: ' || rcte.cmunfim);
                print('rcte.xMunFim...............: ' || rcte.xmunfim);
                print('rcte.UFFim.................: ' || rcte.uffim);
                print('rcte.compl.................: ' || rcte.compl);
                print('rcte.emit_cnpj.............: ' || rcte.emit_cnpj);
                print('rcte.emit_IE...............: ' || rcte.emit_ie);
                print('rcte.emit_xNome............: ' || rcte.emit_xnome);
                print('rcte.emit_xLgr.............: ' || rcte.emit_xlgr);
                print('rcte.emit_nro..............: ' || rcte.emit_nro);
                print('rcte.emit_xCpl.............: ' || rcte.emit_xcpl);
                print('rcte.emit_xBairro..........: ' || rcte.emit_xbairro);
                print('rcte.emit_cMun.............: ' || rcte.emit_cmun);
                print('rcte.emit_xMun.............: ' || rcte.emit_xmun);
                print('rcte.emit_CEP..............: ' || rcte.emit_cep);
                print('rcte.emit_UF...............: ' || rcte.emit_uf);
                print('rcte.emit_fone.............: ' || rcte.emit_fone);
                print('rcte.toma_cnpj.............: ' || rcte.toma_cnpj);
                print('rcte.toma_IE...............: ' || rcte.toma_ie);
                print('rcte.toma_xNome............: ' || rcte.toma_xnome);
                print('rcte.fone..................: ' || rcte.fone);
                print('rcte.toma_xLgr.............: ' || rcte.toma_xlgr);
                print('rcte.toma_nro..............: ' || rcte.toma_nro);
                print('rcte.toma_xCpl.............: ' || rcte.toma_xcpl);
                print('rcte.toma_xBairro..........: ' || rcte.toma_xbairro);
                print('rcte.toma_cMun.............: ' || rcte.toma_cmun);
                print('rcte.toma_xMun.............: ' || rcte.toma_xmun);
                print('rcte.toma_CEP..............: ' || rcte.toma_cep);
                print('rcte.toma_UF...............: ' || rcte.toma_uf);
                print('rcte.toma_cPais............: ' || rcte.toma_cpais);
                print('rcte.toma_xPais............: ' || rcte.toma_xpais);
                print('rcte.vTPrest...............: ' || rcte.vtprest);
                print('rcte.vRec..................: ' || rcte.vrec);
                print('rcte.cst_icms..............: ' || rcte.cst_icms);
                print('rcte.icms_bc...............: ' || rcte.icms_bc);
                print('rcte.icms_tax..............: ' || rcte.icms_tax);
                print('rcte.icms_amount...........: ' || rcte.icms_amount);
                print('rcte.icms_bc_red...........: ' || rcte.icms_bc_red);
                print('rcte.vcred.................: ' || rcte.vcred);
                print('rcte.xDescServ.............: ' || rcte.xdescserv);
                print('rcte.quantidade............: ' || rcte.quantidade);
                print('rcte.chave.................: ' || rcte.chave);
             --
                begin
                    null;
                --
                    l_header.doc_id := g_ctrl_id;
                    l_header.access_key_number := g_ctrl.eletronic_invoice_key;
                    print('l_header.access_key_number2: ' || l_header.access_key_number);
                    l_header.model := '67';
                    l_header.series := rcte.serie;
                    l_header.document_number := rcte.nct;
                    g_ctrl.numero := rcte.nct;
                    l_header.issue_date := to_timestamp_tz ( rcte.dhemi,
                    'RRRR-MM-DD"T"HH24:MI:SS TZR' );
                    l_header.additional_information := rcte.xobs;
                    l_header.net_amount := rcte.vtprest;
                --
                    l_header.receiver_name := rcte.toma_xnome;
                    l_header.receiver_document_number := rcte.toma_cnpj;
                    l_header.receiver_address_state := rcte.toma_uf;
                    l_header.receiver_address_city_code := rcte.toma_cmun;
                    l_header.receiver_address_city_name := rcte.toma_xmun;
                    l_header.receiver_address := rcte.toma_xlgr;
                    l_header.receiver_address_number := rcte.toma_nro;
                    l_header.receiver_address_complement := rcte.toma_xcpl;
                    l_header.receiver_address_zip_code := rcte.toma_cep;
                --
                    l_header.issuer_name := rcte.emit_xnome;
                    l_header.issuer_document_number := rcte.emit_cnpj;
                    l_header.issuer_address_state := rcte.emit_uf;
                    l_header.issuer_address_city_code := rcte.emit_cmun;
                    l_header.issuer_address_city_name := rcte.emit_xmun;
                    l_header.issuer_address := rcte.emit_xlgr;
                    l_header.issuer_address_number := rcte.emit_nro;
                    l_header.issuer_address_complement := rcte.emit_xcpl;
                    l_header.issuer_address_zip_code := rcte.emit_cep;
                    l_header.total_amount := nvl(rcte.vtprest, 0);
                    l_header.source_state_code := rcte.emit_uf;
                    l_header.icms_amount := nvl(rcte.icms_amount, 0);
              --  l_header.Icms_St_Amount              := NVL(rImp.Icms60_vICMSSTRet, 0);
                --
                --
                    l_header.creation_date := sysdate;
                    l_header.created_by := -1;
                    l_header.last_update_date := sysdate;
                    l_header.last_updated_by := -1;
                  --
                --
               /* IF rRem.UF = 'EX' OR NVL(rRem.CNPJ, rRem.CPF) LIKE '%000' THEN
                  --
                  l_header.ship_from_document_number    := NVL(rExped.CNPJ, rExped.CPF);
                  l_header.ship_from_address_state      := rExped.UF;
                  l_header.ship_from_address_city_code  := rExped.cMun;
                  l_header.ship_from_address_city_name  := rExped.xMun;
                  l_header.ship_from_address            := rExped.xLgr;
                  l_header.ship_from_address_number     := rExped.nro ;
                  l_header.ship_from_address_complement := rExped.xCpl;   
                  --
                ELSE*/
                  --
                /*  l_header.ship_from_document_number    := NVL(rRem.CNPJ, rRem.CPF);
                  l_header.ship_from_address_state      := rRem.UF;
                  l_header.ship_from_address_city_code  := rRem.cMun;
                  l_header.ship_from_address_city_name  := rRem.xMun;
                  l_header.ship_from_address            := rRem.xLgr;
                  l_header.ship_from_address_number     := rRem.nro ;
                  l_header.ship_from_address_complement := rRem.xCpl;*/
                  --
               -- END IF;
                  --
                /*  l_header.ship_to_document_number      := NVL(rDest.CNPJ, rDest.CPF);
                  l_header.ship_to_address_state        := rDest.UF;
                  l_header.ship_to_address_city_code    := rDest.cMun;
                  l_header.ship_to_address_city_name    := rDest.xMun;
                  l_header.ship_to_address              := rDest.xLgr;
                  l_header.ship_to_address_number       := rDest.nro;
                  l_header.ship_to_address_complement   := rDest.xCpl;*/
                  --
                  --
                    l_header.process_date := trunc(sysdate);
                 -- l_header.tributary_regimen            := CASE WHEN (rcte.tpCTe = 1 AND rImp.indSN = 1) OR (rIde.tpCTe <> 1 AND rImp.indSN = 1) THEN 1 ELSE 3 END;
                    l_header.layout_version := rcte.verproc;
                    l_header.operation := 'INBOUND';
                    l_header.issuing_type := rcte.tpemis;
                    l_header.issuing_purpose := rcte.tpcte;
                    l_header.document_type := 'CNPJ';
                    l_header.operation_nature := rcte.natop; 
                 -- l_header.service_taker_type           := NVL(rIde.toma, rIde.toma4_toma); 
                    l_header.freight_ibge_source := rcte.cmunini;
                    l_header.freight_ibge_destination :=
                        case
                            when rcte.cmunfim like ( '%-%' ) then
                                '00000'
                            else
                                rcte.cmunfim
                        end;

                    l_header.source_ibge_code := rcte.cmunini;
                    l_header.source_state_code := rcte.ufini;
                    l_header.destination_ibge_code := l_header.receiver_address_city_code;
                    l_header.destination_state_code := l_header.receiver_address_state;
                    l_header.poc := g_ctrl.process;
                 --
                    vidx := 1;
                  --
                    l_lines.line_number := vidx;
                    l_lines.discount_line_amount := 0;
                    l_lines.freight_line_amount := 0;
                    l_lines.insurance_line_amount := 0;
                    l_lines.other_expenses_line_amount := 0;
                  -- 
                    l_lines.line_quantity := 1;
                  --
                    l_lines.unit_price := nvl(rcte.vtprest, 0);
                  --
                --  l_lines.cfop_from                 := NVL(rIde.xCFOP, rIde.CFOP);
                    l_lines.goods_origin_to := 0;
                    l_lines.pis_cst_to := '56';
                    l_lines.cofins_cst_to := '56';
                    l_lines.icms_cst_to := rcte.cst_icms;
                    l_lines.ipi_cst_to := '03';
                    l_lines.fiscal_classification := '00000000';
                    l_lines.cofins_amount := 0;
                    l_lines.cofins_calc_basis := 0;
                    l_lines.cofins_rate := 0;
                    l_lines.cofins_cst_to := '56';
                    l_lines.cofins_unit_amount := '';
                    l_lines.cofins_base_quantity := '';
                    l_lines.icms_st_amount := 0;
                    l_lines.item_description := rcte.xdescserv;
                    l_lines.icms_amount := rcte.icms_amount;
                    l_lines.icms_calc_basis := rcte.icms_bc;
                    l_lines.icms_rate := rcte.icms_tax;
                 /* l_lines.ICMS_TAXABLE_FLAG          := CASE WHEN NVL(rImp.Icms00_CST
                                                                                ,     rImp.Icms20_CST) IS NOT NULL THEN 1 ELSE
                                                                        CASE WHEN     rImp.Icms45_CST  IS NOT NULL THEN 2 ELSE 3 END END;
                  */--
                  --
                 -- l_lines.icms_st_calc_basis              := NVL(rImp.Icms60_vBCSTRet,  0);
                --  l_lines.icms_st_amount            := NVL(rImp.Icms60_vICMSSTRet,0);
                 -- l_lines.RI_ICMS_TYPE              := CASE rIde.tpCTe WHEN '0' THEN CASE SIGN(l_header.ICMS_CALCULATION_BASIS) WHEN 1 THEN 'NORMAL' ELSE 'EXEMPT' END WHEN 3 THEN 'SUBSTITUTE' ELSE CASE WHEN rImp.indSN = 1 THEN 'EXEMPT' ELSE 'NORMAL' END END;
                    l_lines.ipi_amount := 0;
                  --
                    l_lines.net_amount := ( l_lines.unit_price * l_lines.line_quantity );  
                  --
                    l_lines.creation_date := sysdate;
                    l_lines.created_by := -1;
                    l_lines.last_update_date := sysdate;
                    l_lines.last_updated_by := -1;
                  --
                    valid_org(l_header.receiver_document_number, g_ctrl.status);
                  --
                exception
                    when others then 
               --
                        print('Error: Ao atribuir variáveis ' || sqlerrm);
                        g_ctrl.status := 'E';
               --
                end;

            end loop;
           
           --
            if check_nf_exists(g_ctrl.eletronic_invoice_key)
            or nvl(g_ctrl.status, 'P') = 'E' then
             --
                if check_nf_exists(g_ctrl.eletronic_invoice_key) then
               --
                    g_ctrl.status := 'D';
                    print('*** NF já existente na plataforma - DUPLICADA ***');
               --
                else
               --
                    g_ctrl.status := 'D';
                    print('*** NF Não gerada em decorrência de erros ***');
               --
                end if;
             --
             --
             --
                l_header := null;
                l_lines := null;
             --
            else
             --
                print('*** Inserção nas tabelas R+ CTEOS ***');
             --
                begin
               --
                    l_header.efd_header_id := xxrmais_invoices_s.nextval;
                    l_lines.efd_header_id := l_header.efd_header_id;
                    l_lines.efd_line_id := rmais_efd_lines_s.nextval;
               --
                    print('l_header.access_key_number: ' || l_header.access_key_number);
               --
                           -- Buscando BU_NAME na integração
                    begin
                  --
                        l_header.bu_name := json_value(rmais_process_pkg.get_taxpayer(l_header.receiver_document_number, 'RECEIVER'),
           '$.DATA.BU_NAME');
                  --
                        print('BU_NAME: '
                              || l_header.bu_name
                              || 'CNPJ: ' || l_header.receiver_document_number);
                  --
                    exception
                        when others then
                  --
                            print('Não foi possível identificar a BU_NAME' || sqlerrm, 2);
                  --
                    end;

                    insert into rmais_efd_headers_hdi values l_header;

                    insert into rmais_efd_lines_hdi values l_lines;
               --
                    g_ctrl.status := 'P';
               --
                    begin
                 --
                        commit;
                        print('Call main - 3-ini *************************************************************************************'
                        );
                 --rmais_process_pkg.main(p_header_id => l_header.efd_header_id , p_flag_auto => 'Y', p_send_erp => 'Y');
                        print('Call main - 3-ter *************************************************************************************'
                        );
                 --
                        commit;
                    exception
                        when others then
                 --raise_application_error (-20011,'Erro ao reprocessar documento '||sqlerrm);
                            null;
                    end;
               --
                exception
                    when others then
               --
                        print('Error: Inserção de dados nas tabelas ' || sqlerrm);
               --
                        g_ctrl.status := 'E';
               --
                end;
             --
            end if;
         --
        end load_read_file_xml_cteos;
  ---------------------------------
  -- Processo para caregar o xml --
  -- da nota fiscal do tipo CTE  --
  ---------------------------------
        procedure load_read_file_xml_cte (
            psource clob
        ) is
    --
            rsource     clob;
    --
            l_nscte     varchar2(100) := 'xmlns="http://www.portalfiscal.inf.br/cte"';
    --
            l_xml       xmltype;
    --
            vidx        number;
    --
            cursor c_cte (
                pxml xmltype
            ) is
            select
                *
            from
                xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/cte' ),
                '/cteProc/CTe/infCte'
                        passing pxml
                    columns
                        ide xmltype path 'ide',
                        compl xmltype path 'compl',
                        emit xmltype path 'emit',
                        rem xmltype path 'rem',
                        dest xmltype path 'dest',
                        exped xmltype path 'exped',
                        receb xmltype path 'receb',
                        imp xmltype path 'imp',
                        infitem xmltype path 'InfItem',
                        infctenorm xmltype path 'infCTeNorm',
                        infcteanu xmltype path 'infCteAnu',
                        infctecomp xmltype path 'infCteComp',
                        vprest xmltype path 'vPrest',
                        versao varchar2(90) path '@versao',
                        xcondpagto varchar2(200) path '/infCte/cobr/xCondPagto/text()'
                ) inf,
                xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/cte' ),
                '/cteProc/protCTe/infProt'
                        passing pxml
                    columns
                        cod_danfe varchar2(100) path 'chCTe/text()'
                ) key
         /*, XMLTABLE   (XMLNAMESPACES(DEFAULT 'http://www.portalfiscal.inf.br/cte') ,'/cteProc/Integracao'
             PASSING     pXML COLUMNS
             xTipoNF     VARCHAR2(100) PATH '/Integracao/xTipoNF/text()'
           , xOperFiscal VARCHAR2(100) PATH '/Integracao/xTipoOperFiscal/text()'
           , xModelo     VARCHAR2(100) PATH '/Integracao/xModeloFiscal/text()') itg*/;
    --
            rcte        c_cte%rowtype;
    --
            cursor c_ide (
                p_ide xmltype
            ) is
            select
                extractvalue(column_value, '*/nCT', l_nscte)                       as nct,
                extractvalue(column_value, '*/cUF', l_nscte)                       as cuf,
                extractvalue(column_value, '*/cCT', l_nscte)                       as cct,
                extractvalue(column_value, '*/cDV', l_nscte)                       as cdv,
                extractvalue(column_value, '*/CFOP', l_nscte)                      as cfop,
                extractvalue(column_value, '*/InfTrad/xCFOP', l_nscte)             as xcfop,
                extractvalue(column_value, '*/cMunEmi', l_nscte)                   as cmunemi,
                extractvalue(column_value, '*/cMunFim', l_nscte)                   as cmunfim,
                extractvalue(column_value, '*/cMunIni', l_nscte)                   as cmunini,
                extractvalue(column_value, '*/dhEmi', l_nscte)                     as dhemi,
                extractvalue(column_value, '*/forPag', l_nscte)                    as forpag,
                extractvalue(column_value, '*/mod', l_nscte)                       as mod,
                extractvalue(column_value, '*/modal', l_nscte)                     as modal,
                extractvalue(column_value, '*/natOp', l_nscte)                     as natop,
                extractvalue(column_value, '*/procEmi', l_nscte)                   as procemi,
                extractvalue(column_value, '*/refCTE', l_nscte)                    as refcte,
                extractvalue(column_value, '*/retira', l_nscte)                    as retira,
                extractvalue(column_value, '*/serie', l_nscte)                     as serie,
                extractvalue(column_value, '*/tpAmb', l_nscte)                     as tpamb,
                extractvalue(column_value, '*/tpCTe', l_nscte)                     as tpcte,
                extractvalue(column_value, '*/tpEmis', l_nscte)                    as tpemis,
                extractvalue(column_value, '*/tpImp', l_nscte)                     as tpimp,
                extractvalue(column_value, '*/tpServ', l_nscte)                    as tpserv,
                extractvalue(column_value, '*/UFEmi', l_nscte)                     as ufemi,
                extractvalue(column_value, '*/UFFim', l_nscte)                     as uffim,
                extractvalue(column_value, '*/UFIni', l_nscte)                     as ufini,
                extractvalue(column_value, '*/verProc', l_nscte)                   as verproc,
                extractvalue(column_value, '*/xDetRetira', l_nscte)                as xdetretira,
                extractvalue(column_value, '*/xMunEmi', l_nscte)                   as xmunemi,
                extractvalue(column_value, '*/xMunFim', l_nscte)                   as xmunfim,
                extractvalue(column_value, '*/xMunIni', l_nscte)                   as xmunini,
                extractvalue(column_value, '*/xNatOpPedag', l_nscte)               as xnatoppedag,
                extractvalue(column_value, '*/xTipNF', l_nscte)                    as xinvoicetype,
                extractvalue(column_value, '*/xModeloFiscal', l_nscte)             as xmodelo,
                extractvalue(column_value, '*/toma3/toma', l_nscte)                as toma,
                extractvalue(column_value, '*/toma3/InfTrad/xCodTomador', l_nscte) as xcodtomador,
                extractvalue(column_value, '*/toma3/InfTrad/xDesTomador', l_nscte) as xdestomador,
                extractvalue(column_value, '*/toma4/toma', l_nscte)                as toma4_toma,
                extractvalue(column_value, '*/toma4/CNPJ', l_nscte)                as toma4_cnpj,
                extractvalue(column_value, '*/toma4/CPF', l_nscte)                 as toma4_cpf,
                extractvalue(column_value, '*/toma4/IE', l_nscte)                  as toma4_ie,
                extractvalue(column_value, '*/toma4/enderToma/CEP', l_nscte)       as toma4_cep,
                extractvalue(column_value, '*/toma4/enderToma/cMun', l_nscte)      as toma4_cmun,
                extractvalue(column_value, '*/toma4/enderToma/cPais', l_nscte)     as toma4_cpais,
                extractvalue(column_value, '*/toma4/enderToma/nro', l_nscte)       as toma4_nro,
                extractvalue(column_value, '*/toma4/enderToma/UF', l_nscte)        as toma4_uf,
                extractvalue(column_value, '*/toma4/enderToma/xBairro', l_nscte)   as toma4_xbairro,
                extractvalue(column_value, '*/toma4/enderToma/xCpl', l_nscte)      as toma4_xcpl,
                extractvalue(column_value, '*/toma4/enderToma/xLgr', l_nscte)      as toma4_xlgr,
                extractvalue(column_value, '*/toma4/enderToma/xMun', l_nscte)      as toma4_xmun,
                extractvalue(column_value, '*/toma4/enderToma/xPais', l_nscte)     as toma4_xpais,
                extractvalue(column_value, '*/toma4/fone', l_nscte)                as toma4_fone,
                extractvalue(column_value, '*/toma4/xFant', l_nscte)               as toma4_xfant,
                extractvalue(column_value, '*/toma4/xNome', l_nscte)               as toma4_xnome
            from
                table ( xmlsequence(extract(p_ide, 'ide', l_nscte)) );
    --
            ride        c_ide%rowtype;
    --
            cursor c_dest (
                p_dest xmltype
            ) is
            select
                extractvalue(column_value, '*/CNPJ', l_nscte)                            as cnpj,
                extractvalue(column_value, '*/CPF', l_nscte)                             as cpf,
                extractvalue(column_value, '*/IE', l_nscte)                              as ie,
                extractvalue(column_value, '*/ISUF', l_nscte)                            as isuf,
                extractvalue(column_value, '*/xNome', l_nscte)                           as xnome,
                extractvalue(column_value, '*/fone', l_nscte)                            as fone,
                extractvalue(column_value, '*/enderDest/CEP', l_nscte)                   as cep,
                extractvalue(column_value, '*/enderDest/cMun', l_nscte)                  as cmun,
                extractvalue(column_value, '*/enderDest/cPais', l_nscte)                 as cpais,
                extractvalue(column_value, '*/enderDest/nro', l_nscte)                   as nro,
                extractvalue(column_value, '*/enderDest/UF', l_nscte)                    as uf,
                extractvalue(column_value, '*/enderDest/xBairro', l_nscte)               as xbairro,
                extractvalue(column_value, '*/enderDest/xCpl', l_nscte)                  as xcpl,
                extractvalue(column_value, '*/enderDest/xLgr', l_nscte)                  as xlgr,
                extractvalue(column_value, '*/enderDest/xMun', l_nscte)                  as xmun,
                extractvalue(column_value, '*/enderDest/xPais', l_nscte)                 as xpais,
                extractvalue(column_value, '*/InfTrad/xCodEstabelecimentoDest', l_nscte) as xcoddestinatario,
                extractvalue(column_value, '*/InfTrad/xNomEstabelecimentoDest', l_nscte) as xnomdestinatario
            from
                table ( xmlsequence(extract(p_dest, 'dest', l_nscte)) );
    --
            rdest       c_dest%rowtype;
    --
            cursor c_emit (
                p_emit xmltype
            ) is
            select
                extractvalue(column_value, '*/CNPJ', l_nscte)                   as cnpj,
                extractvalue(column_value, '*/CPF', l_nscte)                    as cpf,
                extractvalue(column_value, '*/IE', l_nscte)                     as ie,
                extractvalue(column_value, '*/xNome', l_nscte)                  as xnome,
                extractvalue(column_value, '*/xFant', l_nscte)                  as xfant,
                extractvalue(column_value, '*/enderEmit/CEP', l_nscte)          as cep,
                extractvalue(column_value, '*/enderEmit/cMun', l_nscte)         as cmun,
                extractvalue(column_value, '*/enderEmit/cPais', l_nscte)        as cpais,
                extractvalue(column_value, '*/enderEmit/fone', l_nscte)         as fone,
                extractvalue(column_value, '*/enderEmit/nro', l_nscte)          as nro,
                extractvalue(column_value, '*/enderEmit/UF', l_nscte)           as uf,
                extractvalue(column_value, '*/enderEmit/xBairro', l_nscte)      as xbairro,
                extractvalue(column_value, '*/enderEmit/xCpl', l_nscte)         as xcpl,
                extractvalue(column_value, '*/enderEmit/xLgr', l_nscte)         as xlgr,
                extractvalue(column_value, '*/enderEmit/xMun', l_nscte)         as xmun,
                extractvalue(column_value, '*/enderEmit/xPais', l_nscte)        as xpais,
                extractvalue(column_value, '*/InfTrad/xCodFornecedor', l_nscte) as xcodemitente,
                extractvalue(column_value, '*/InfTrad/xDesFornecedor', l_nscte) as xdesemitente
            from
                table ( xmlsequence(extract(p_emit, 'emit', l_nscte)) );
    --
            remit       c_emit%rowtype;
    --
            cursor c_rem (
                p_rem xmltype
            ) is
            select
                extractvalue(column_value, '*/CNPJ', l_nscte)                       as cnpj,
                extractvalue(column_value, '*/CPF', l_nscte)                        as cpf,
                extractvalue(column_value, '*/IE', l_nscte)                         as ie,
                extractvalue(column_value, '*/xNome', l_nscte)                      as xnome,
                extractvalue(column_value, '*/xFant', l_nscte)                      as xfant,
                extractvalue(column_value, '*/fone', l_nscte)                       as fone,
                extractvalue(column_value, '*/email', l_nscte)                      as email,
                extractvalue(column_value, '*/enderReme/CEP', l_nscte)              as cep,
                extractvalue(column_value, '*/enderReme/cMun', l_nscte)             as cmun,
                extractvalue(column_value, '*/enderReme/cPais', l_nscte)            as cpais,
                extractvalue(column_value, '*/enderReme/nro', l_nscte)              as nro,
                extractvalue(column_value, '*/enderReme/UF', l_nscte)               as uf,
                extractvalue(column_value, '*/enderReme/xBairro', l_nscte)          as xbairro,
                extractvalue(column_value, '*/enderReme/xCpl', l_nscte)             as xcpl,
                extractvalue(column_value, '*/enderReme/xLgr', l_nscte)             as xlgr,
                extractvalue(column_value, '*/enderReme/xMun', l_nscte)             as xmun,
                extractvalue(column_value, '*/enderReme/xPais', l_nscte)            as xpais,
                extractvalue(column_value, '*/InfTrad/xCodFornecedorReme', l_nscte) as xcodremetente,
                extractvalue(column_value, '*/InfTrad/xDesFornecedorReme', l_nscte) as xnomremetente
            from
                table ( xmlsequence(extract(p_rem, 'rem', l_nscte)) );
    --
            rrem        c_rem%rowtype;
    --
            cursor c_exped (
                p_exped xmltype
            ) is
            select
                extractvalue(column_value, '*/CNPJ', l_nscte)                   as cnpj,
                extractvalue(column_value, '*/CPF', l_nscte)                    as cpf,
                extractvalue(column_value, '*/IE', l_nscte)                     as ie,
                extractvalue(column_value, '*/ISUF', l_nscte)                   as isuf,
                extractvalue(column_value, '*/xNome', l_nscte)                  as xnome,
                extractvalue(column_value, '*/fone', l_nscte)                   as fone,
                extractvalue(column_value, '*/enderExped/CEP', l_nscte)         as cep,
                extractvalue(column_value, '*/enderExped/cMun', l_nscte)        as cmun,
                extractvalue(column_value, '*/enderExped/cPais', l_nscte)       as cpais,
                extractvalue(column_value, '*/enderExped/nro', l_nscte)         as nro,
                extractvalue(column_value, '*/enderExped/UF', l_nscte)          as uf,
                extractvalue(column_value, '*/enderExped/xBairro', l_nscte)     as xbairro,
                extractvalue(column_value, '*/enderExped/xCpl', l_nscte)        as xcpl,
                extractvalue(column_value, '*/enderExped/xLgr', l_nscte)        as xlgr,
                extractvalue(column_value, '*/enderExped/xMun', l_nscte)        as xmun,
                extractvalue(column_value, '*/enderExped/xPais', l_nscte)       as xpais,
                extractvalue(column_value, '*/InfTrad/xCodFornecedor', l_nscte) as xcodexpedidor,
                extractvalue(column_value, '*/InfTrad/xDesFornecedor', l_nscte) as xnomexpedidor
            from
                table ( xmlsequence(extract(p_exped, 'exped', l_nscte)) );
    --
            rexped      c_exped%rowtype;
    --
            cursor c_receb (
                p_receb xmltype
            ) is
            select
                extractvalue(column_value, '*/CNPJ', l_nscte)                  as cnpj,
                extractvalue(column_value, '*/CPF', l_nscte)                   as cpf,
                extractvalue(column_value, '*/IE', l_nscte)                    as ie,
                extractvalue(column_value, '*/ISUF', l_nscte)                  as isuf,
                extractvalue(column_value, '*/xNome', l_nscte)                 as xnome,
                extractvalue(column_value, '*/fone', l_nscte)                  as fone,
                extractvalue(column_value, '*/enderReceb/CEP', l_nscte)        as cep,
                extractvalue(column_value, '*/enderReceb/cMun', l_nscte)       as cmun,
                extractvalue(column_value, '*/enderReceb/cPais', l_nscte)      as cpais,
                extractvalue(column_value, '*/enderReceb/nro', l_nscte)        as nro,
                extractvalue(column_value, '*/enderReceb/UF', l_nscte)         as uf,
                extractvalue(column_value, '*/enderReceb/xBairro', l_nscte)    as xbairro,
                extractvalue(column_value, '*/enderReceb/xCpl', l_nscte)       as xcpl,
                extractvalue(column_value, '*/enderReceb/xLgr', l_nscte)       as xlgr,
                extractvalue(column_value, '*/enderReceb/xMun', l_nscte)       as xmun,
                extractvalue(column_value, '*/enderReceb/xPais', l_nscte)      as xpais,
                extractvalue(column_value, '*/InfTrad/CodFornecedor', l_nscte) as xcodrecebedor,
                extractvalue(column_value, '*/InfTrad/DesFornecedor', l_nscte) as xnomrecebedor
            from
                table ( xmlsequence(extract(p_receb, 'receb', l_nscte)) );
    --
            rreceb      c_receb%rowtype;
    --
            cursor c_compl (
                p_compl xmltype
            ) is
            select
                extractvalue(column_value, '*/destCalc', l_nscte)  as destcalc,
                extractvalue(column_value, '*/origCalc', l_nscte)  as origcalc,
                extractvalue(column_value, '*/xCaracAd', l_nscte)  as xcaracad,
                extractvalue(column_value, '*/xCaracSer', l_nscte) as xcaracser,
                extractvalue(column_value, '*/xEmi', l_nscte)      as xemi,
                extractvalue(column_value, '*/xObs', l_nscte)      as xobs
            from
                table ( xmlsequence(extract(p_compl, 'compl', l_nscte)) );
    --
            rcompl      c_compl%rowtype;
    --
            cursor c_item (
                p_infitem xmltype,
                ppedido   varchar2 default null
            ) is
            select
                row_number()
                over(partition by pedido, line_num, xcodproduto, release_num
                     order by
                         pedido, line_num,
                         xcodproduto, release_num, shipment_num
                )                                                             ocurr_seq,
                count(*)
                over(partition by pedido, line_num, xcodproduto, release_num) ocurr_tot,
                itm.*,
                pedido
                || '_'
                || line_num
                || '_'
                || nvl(release_num, 0)
                || '_'
                || xcodproduto                                                chave
            from
                (
                    select
                        extractvalue(column_value, '*/InfTradItem/cPedido', l_nscte)           as pedido,
                        extractvalue(column_value, '*/InfTradItem/nItemPed', l_nscte)          as line_num,
                        extractvalue(column_value, '*/InfTradItem/nNroOrdemProducao', l_nscte) as nnroordemproducao,
                        extractvalue(column_value, '*/InfTradItem/nParcela', l_nscte)          as shipment_num,
                        extractvalue(column_value, '*/InfTradItem/xReleaseNum', l_nscte)       as release_num,
                        extractvalue(column_value, '*/InfTradItem/vValor', l_nscte)            as vvalor,
                        extractvalue(column_value, '*/InfTradItem/xUMint', l_nscte)            as xuom,
                        extractvalue(column_value, '*/InfTradItem/xCodProduto', l_nscte)       as xcodproduto,
                        extractvalue(column_value, '*/InfTradItem/xDesProduto', l_nscte)       as xdesproduto,
                        extractvalue(column_value, '*/InfTradItem/xNroCentroCusto', l_nscte)   as xnrocentrocusto,
                        extractvalue(column_value, '*/InfTradItem/xNroContaContabil', l_nscte) as xnrocontacontabil,
                        extractvalue(column_value, '*/InfTradItem/xUtilizFiscal', l_nscte)     as xutilizacao,
                        extractvalue(column_value, '*/InfTradItem/xCodOrganizacao', l_nscte)   as xorganization,
                        extractvalue(column_value, '*/InfTradItem/xNaturOper', l_nscte)        as xnaturoper
                    from
                        table ( xmlsequence(extract(p_infitem, 'InfItem', l_nscte)) )
                ) itm
            where
                nvl(pedido, 'X') = nvl(ppedido,
                                       nvl(pedido, 'X'));
    --
            ritem       c_item%rowtype;
    --
            cursor c_imp (
                p_imp xmltype
            ) is
            select
                nvl(icms00_cst,
                    nvl(icms60_cst,
                        nvl(icms80_cst,
                            nvl(icms20_cst,
                                nvl(icms81_cst,
                                    nvl(icms90_cst,
                                        nvl(icms45_cst,
                                            nvl(icmsoutrauf_cst, 0)))))))) icms_cst,
                nvl(icms90_picms,
                    nvl(icms80_picms,
                        nvl(icms20_picms,
                            nvl(icms81_picms,
                                nvl(icms00_picms,
                                    nvl(picmsoutrauf, 0))))))              icms_picms,
                nvl(icms00_vicms,
                    nvl(icms20_vicms,
                        nvl(icms81_vicms,
                            nvl(icms80_vicms,
                                nvl(icms90_vicms,
                                    nvl(vicmsoutrauf, 0))))))              icms_vicms,
                nvl(icms20_predbc,
                    nvl(icms90_predbc,
                        nvl(icms81_predbc,
                            nvl(predbcoutrauf, 0))))                       icms_predbc,
                nvl(icms00_vbc,
                    nvl(icms20_vbc,
                        nvl(icms81_vbc,
                            nvl(icms90_vbc,
                                nvl(icms80_vbc,
                                    nvl(vbcoutrauf, 0))))))                icms_vbc,
                nvl(icms90_vcred,
                    nvl(icms80_vcred, 0))                                  icms_vcred,
                icm.*
            from
                (
                    select
                        extractvalue(column_value, '*/ICMS/ICMS00/CST', l_nscte)                as icms00_cst,
                        extractvalue(column_value, '*/ICMS/ICMS00/pICMS', l_nscte)              as icms00_picms,
                        extractvalue(column_value, '*/ICMS/ICMS00/vBC', l_nscte)                as icms00_vbc,
                        extractvalue(column_value, '*/ICMS/ICMS00/vICMS', l_nscte)              as icms00_vicms,
                        extractvalue(column_value, '*/ICMS/ICMS20/CST', l_nscte)                as icms20_cst,
                        extractvalue(column_value, '*/ICMS/ICMS20/pICMS', l_nscte)              as icms20_picms,
                        extractvalue(column_value, '*/ICMS/ICMS20/pRedBC', l_nscte)             as icms20_predbc,
                        extractvalue(column_value, '*/ICMS/ICMS20/vBC', l_nscte)                as icms20_vbc,
                        extractvalue(column_value, '*/ICMS/ICMS20/vICMS', l_nscte)              as icms20_vicms,
                        extractvalue(column_value, '*/ICMS/ICMS45/CST', l_nscte)                as icms45_cst,
                        extractvalue(column_value, '*/ICMS/ICMS60/CST', l_nscte)                as icms60_cst,
                        extractvalue(column_value, '*/ICMS/ICMS60/vBCSTRet', l_nscte)           as icms60_vbcstret,
                        extractvalue(column_value, '*/ICMS/ICMS60/vICMSSTRet', l_nscte)         as icms60_vicmsstret,
                        extractvalue(column_value, '*/ICMS/ICMS60/pICMSSTRet', l_nscte)         as icms60_picmsstret,
                        extractvalue(column_value, '*/ICMS/ICMS60/vCred', l_nscte)              as icms60_vcred,
                        extractvalue(column_value, '*/ICMS/ICMS80/CST', l_nscte)                as icms80_cst,
                        extractvalue(column_value, '*/ICMS/ICMS80/pICMS', l_nscte)              as icms80_picms,
                        extractvalue(column_value, '*/ICMS/ICMS80/vBC', l_nscte)                as icms80_vbc,
                        extractvalue(column_value, '*/ICMS/ICMS80/vCred', l_nscte)              as icms80_vcred,
                        extractvalue(column_value, '*/ICMS/ICMS80/vICMS', l_nscte)              as icms80_vicms,
                        extractvalue(column_value, '*/ICMS/ICMS81/CST', l_nscte)                as icms81_cst,
                        extractvalue(column_value, '*/ICMS/ICMS81/pICMS', l_nscte)              as icms81_picms,
                        extractvalue(column_value, '*/ICMS/ICMS81/pRedBC', l_nscte)             as icms81_predbc,
                        extractvalue(column_value, '*/ICMS/ICMS81/vBC', l_nscte)                as icms81_vbc,
                        extractvalue(column_value, '*/ICMS/ICMS81/vICMS', l_nscte)              as icms81_vicms,
                        extractvalue(column_value, '*/ICMS/ICMS90/CST', l_nscte)                as icms90_cst,
                        extractvalue(column_value, '*/ICMS/ICMS90/pICMS', l_nscte)              as icms90_picms,
                        extractvalue(column_value, '*/ICMS/ICMS90/pRedBC', l_nscte)             as icms90_predbc,
                        extractvalue(column_value, '*/ICMS/ICMS90/vBC', l_nscte)                as icms90_vbc,
                        extractvalue(column_value, '*/ICMS/ICMS90/vCred', l_nscte)              as icms90_vcred,
                        extractvalue(column_value, '*/ICMS/ICMS90/vICMS', l_nscte)              as icms90_vicms,
                        extractvalue(column_value, '*/ICMS/ICMSOutraUF/CST', l_nscte)           as icmsoutrauf_cst,
                        extractvalue(column_value, '*/ICMS/ICMSOutraUF/pICMSOutraUF', l_nscte)  as picmsoutrauf,
                        extractvalue(column_value, '*/ICMS/ICMSOutraUF/pRedBCOutraUF', l_nscte) as predbcoutrauf,
                        extractvalue(column_value, '*/ICMS/ICMSOutraUF/vBCOutraUF', l_nscte)    as vbcoutrauf,
                        extractvalue(column_value, '*/ICMS/ICMSOutraUF/vICMSOutraUF', l_nscte)  as vicmsoutrauf,
                        extractvalue(column_value, '*/ICMS/ICMSSN/indSN', l_nscte)              as indsn,
                        extractvalue(column_value, '*/infAdFisco', l_nscte)                     as infadfisco
                    from
                        table ( xmlsequence(extract(p_imp, 'imp', l_nscte)) )
                ) icm;
    --
            rimp        c_imp%rowtype;
    --
            cursor c_normferrov (
                p_infctenorm xmltype
            ) is
            select
                extractvalue(column_value, '*/infCTeNorm/ferrov/fluxo', l_nscte)                  as fluxo,
                extractvalue(column_value, '*/ferrov/idTrem', l_nscte)                            as idtrem,
                extractvalue(column_value, '*/ferrov/tpTraf', l_nscte)                            as tptraf,
                extractvalue(column_value, '*/ferrov/vFrete', l_nscte)                            as vfrete,
                extractvalue(column_value, '*/ferrov/DCL/dEmi', l_nscte)                          as dcl_demi,
                extractvalue(column_value, '*/ferrov/DCL/detVagDCL/cap', l_nscte)                 as dcl_cap,
                extractvalue(column_value, '*/ferrov/DCL/detVagDCL/contDCL/dPrev', l_nscte)       as dcl_dprev,
                extractvalue(column_value, '*/ferrov/DCL/detVagDCL/contDCL/nCont', l_nscte)       as dcl_ncont,
                extractvalue(column_value, '*/ferrov/DCL/detVagDCL/lacDetVagDCL/nLacre', l_nscte) as dcl_nlacre,
                extractvalue(column_value, '*/ferrov/DCL/detVagDCL/nVag', l_nscte)                as dcl_nvag,
                extractvalue(column_value, '*/ferrov/DCL/detVagDCL/pesoBC', l_nscte)              as dcl_pesobc,
                extractvalue(column_value, '*/ferrov/DCL/detVagDCL/pesoR', l_nscte)               as dcl_pesor,
                extractvalue(column_value, '*/ferrov/DCL/detVagDCL/tpVag', l_nscte)               as dcl_tpvag,
                extractvalue(column_value, '*/ferrov/DCL/idTrem', l_nscte)                        as dcl_idtrem,
                extractvalue(column_value, '*/ferrov/DCL/nDCL', l_nscte)                          as dcl_ndcl,
                extractvalue(column_value, '*/ferrov/DCL/pCalc', l_nscte)                         as dcl_pcalc,
                extractvalue(column_value, '*/ferrov/DCL/qVag', l_nscte)                          as dcl_qvag,
                extractvalue(column_value, '*/ferrov/DCL/serie', l_nscte)                         as dcl_serie,
                extractvalue(column_value, '*/ferrov/DCL/vFrete', l_nscte)                        as dcl_vfrete,
                extractvalue(column_value, '*/ferrov/DCL/vSAcess', l_nscte)                       as dcl_vsacess,
                extractvalue(column_value, '*/ferrov/DCL/vTar', l_nscte)                          as dcl_vtar,
                extractvalue(column_value, '*/ferrov/DCL/vTServ', l_nscte)                        as dcl_vtserv,
                extractvalue(column_value, '*/ferrov/detVag/cap', l_nscte)                        as detvag_dprev,
                extractvalue(column_value, '*/ferrov/detVag/contVag/dPrev', l_nscte)              as detvag_ncont,
                extractvalue(column_value, '*/ferrov/detVag/contVag/nCont', l_nscte)              as detvag_nlacre,
                extractvalue(column_value, '*/ferrov/detVag/lacDetVag/nLacre', l_nscte)           as detvag_nvag,
                extractvalue(column_value, '*/ferrov/detVag/nVag', l_nscte)                       as detvag_pesobc,
                extractvalue(column_value, '*/ferrov/detVag/pesoBC', l_nscte)                     as detvag_pesor,
                extractvalue(column_value, '*/ferrov/detVag/pesoR', l_nscte)                      as detvag_tpvag,
                extractvalue(column_value, '*/ferrov/detVag/tpVag', l_nscte)                      as tpvag,
                extractvalue(column_value, '*/ferrov/ferroSub/CNPJ', l_nscte)                     as cnpj,
                extractvalue(column_value, '*/ferrov/ferroSub/cInt', l_nscte)                     as cint,
                extractvalue(column_value, '*/ferrov/ferroSub/IE', l_nscte)                       as ie,
                extractvalue(column_value, '*/ferrov/ferroSub/xNome', l_nscte)                    as xnome,
                extractvalue(column_value, '*/ferrov/ferroSub/enderFerro/CEP', l_nscte)           as cep,
                extractvalue(column_value, '*/ferrov/ferroSub/enderFerro/cMun', l_nscte)          as cmun,
                extractvalue(column_value, '*/ferrov/ferroSub/enderFerro/nro', l_nscte)           as nro,
                extractvalue(column_value, '*/ferrov/ferroSub/enderFerro/UF', l_nscte)            as uf,
                extractvalue(column_value, '*/ferrov/ferroSub/enderFerro/xBairro', l_nscte)       as xbairro,
                extractvalue(column_value, '*/ferrov/ferroSub/enderFerro/xCpl', l_nscte)          as xcpl,
                extractvalue(column_value, '*/ferrov/ferroSub/enderFerro/xLgr', l_nscte)          as xlgr,
                extractvalue(column_value, '*/ferrov/ferroSub/enderFerro/xMun', l_nscte)          as xmun
            from
                table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm', l_nscte)) );
    --
            rnormferrov c_normferrov%rowtype;
    --
            cursor c_normduto (
                p_infctenorm xmltype
            ) is
            select
                extractvalue(column_value, '*/duto/vTar', l_nscte) as vtar
            from
                table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm', l_nscte)) );
      --
            rnormduto   c_normduto%rowtype;
    --
            cursor c_normperi (
                p_infctenorm xmltype
            ) is
            select
                extractvalue(column_value, '*/peri/grEmb', l_nscte)       as gremb,
                extractvalue(column_value, '*/peri/nONU', l_nscte)        as nonu,
                extractvalue(column_value, '*/peri/pontoFulgor', l_nscte) as pontofulgor,
                extractvalue(column_value, '*/peri/qTotProd', l_nscte)    as qtotprod,
                extractvalue(column_value, '*/peri/qVolTipo', l_nscte)    as qvoltipo,
                extractvalue(column_value, '*/peri/xClaRisco', l_nscte)   as xclarisco,
                extractvalue(column_value, '*/peri/xNomeAE', l_nscte)     as xnomeae
            from
                table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm', l_nscte)) );
    --
            rnormperi   c_normperi%rowtype;
    --
            cursor c_normveic (
                p_infctenorm xmltype
            ) is
            select
                extractvalue(column_value, '*/veicNovos/cCor', l_nscte)   as ccor,
                extractvalue(column_value, '*/veicNovos/chassi', l_nscte) as chassi,
                extractvalue(column_value, '*/veicNovos/cMod', l_nscte)   as cmod,
                extractvalue(column_value, '*/veicNovos/vFrete', l_nscte) as vfrete,
                extractvalue(column_value, '*/veicNovos/vUnit', l_nscte)  as vunit,
                extractvalue(column_value, '*/veicNovos/xCor', l_nscte)   as xcor
            from
                table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm', l_nscte)) );
    --
            rnormveic   c_normveic%rowtype;
    --
            cursor c_normout (
                p_infctenorm xmltype
            ) is
            select
                extractvalue(column_value, '*/infDoc/infOutros/dEmi', l_nscte)       as demi,
                extractvalue(column_value, '*/infDoc/infOutros/descOutros', l_nscte) as descoutros,
                extractvalue(column_value, '*/infDoc/infOutros/dPrev', l_nscte)      as dprev,
                extractvalue(column_value, '*/infDoc/infOutros/nDoc', l_nscte)       as ndoc,
                extractvalue(column_value, '*/infDoc/infOutros/tpDoc', l_nscte)      as tpdoc,
                extractvalue(column_value, '*/infDoc/infOutros/vDocFisc', l_nscte)   as vdocfisc
            from
                table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm', l_nscte)) );
    --
            rnormout    c_normout%rowtype;
    --
            cursor c_normnf (
                p_infctenorm xmltype
            ) is
            select
                rownum seq,
                a.*
            from
                (
                    select
                        extractvalue(column_value, '*/dPrev', l_nscte) as dprev,
                        extractvalue(column_value, '*/PIN', l_nscte)   as pin,
                        extractvalue(column_value, '*/dEmi', l_nscte)  as demi,
                        extractvalue(column_value, '*/mod', l_nscte)   as mod,
                        extractvalue(column_value, '*/nCFOP', l_nscte) as ncfop,
                        extractvalue(column_value, '*/nDoc', l_nscte)  as ndoc,
                        extractvalue(column_value, '*/nPed', l_nscte)  as nped,
                        extractvalue(column_value, '*/nPeso', l_nscte) as npeso,
                        extractvalue(column_value, '*/nRoma', l_nscte) as nroma,
                        extractvalue(column_value, '*/serie', l_nscte) as serie,
                        extractvalue(column_value, '*/vBC', l_nscte)   as vbc,
                        extractvalue(column_value, '*/vBCST', l_nscte) as vbcst,
                        extractvalue(column_value, '*/vICMS', l_nscte) as vicms,
                        extractvalue(column_value, '*/vNF', l_nscte)   as vnf,
                        extractvalue(column_value, '*/vProd', l_nscte) as vprod,
                        extractvalue(column_value, '*/vST', l_nscte)   as vst,
                        ''                                             tpdoc,
                        ''                                             descoutros,
                        ''                                             vdocfisc,
                        ''                                             chave,
                        'NF'                                           tipo
                    from
                        table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm/infDoc/infNF', l_nscte)) )
                    union
                    select
                        extractvalue(column_value, '*/dPrev', l_nscte) as dprev,
                        extractvalue(column_value, '*/PIN', l_nscte)   as pin,
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        extractvalue(column_value, '*/chave', l_nscte) as chave,
                        'NFe'
                    from
                        table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm/infDoc/infNFe', l_nscte)) )
                    union
                    select
                        extractvalue(column_value, '*/dPrev', l_nscte)      as dprev,
                        '',
                        extractvalue(column_value, '*/dEmi', l_nscte)       as demi,
                        '',
                        '',
                        extractvalue(column_value, '*/nDoc', l_nscte)       as ndoc,
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        '',
                        extractvalue(column_value, '*/tpDoc', l_nscte)      as tpdoc  --00 - Declaração; 10 - Dutoviário; 59 - CF-e SAT; 65 - NFC-e; 99 - Outros
                        ,
                        extractvalue(column_value, '*/descOutros', l_nscte) as descoutros,
                        extractvalue(column_value, '*/vDocFisc', l_nscte)   as vdocfisc,
                        '',
                        'Outros'
                    from
                        table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm/infDoc/infOutros', l_nscte)) )
                ) a;
    --
            rnormnf     c_normnf%rowtype;
    --
            cursor c_normdocant (
                p_infctenorm xmltype
            ) is
            select
                extractvalue(column_value, '*/docAnt/emiDocAnt/CNPJ', l_nscte)                        as cnpj,
                extractvalue(column_value, '*/docAnt/emiDocAnt/CPF', l_nscte)                         as cpf,
                extractvalue(column_value, '*/docAnt/emiDocAnt/IE', l_nscte)                          as ie,
                extractvalue(column_value, '*/docAnt/emiDocAnt/UF', l_nscte)                          as uf,
                extractvalue(column_value, '*/docAnt/emiDocAnt/xNome', l_nscte)                       as xnome,
                extractvalue(column_value, '*/docAnt/emiDocAnt/idDocAnt/idDocAntEle/chave', l_nscte)  as chave,
                extractvalue(column_value, '*/docAnt/emiDocAnt/idDocAnt/idDocAntPap/dEmi', l_nscte)   as demi,
                extractvalue(column_value, '*/docAnt/emiDocAnt/idDocAnt/idDocAntPap/nDoc', l_nscte)   as ndoc,
                extractvalue(column_value, '*/docAnt/emiDocAnt/idDocAnt/idDocAntPap/serie', l_nscte)  as serie,
                extractvalue(column_value, '*/docAnt/emiDocAnt/idDocAnt/idDocAntPap/subser', l_nscte) as subser,
                extractvalue(column_value, '*/docAnt/emiDocAnt/idDocAnt/idDocAntPap/tpDoc', l_nscte)  as tpdoc
            from
                table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm', l_nscte)) );
    --
            rnormdocant c_normdocant%rowtype;
    --
            cursor c_normrodo (
                p_infctenorm xmltype
            ) is
            select
                extractvalue(column_value, '*/rodo/CTRB/nCTRB', l_nscte)          as nctrb,
                extractvalue(column_value, '*/rodo/CTRB/serie', l_nscte)          as serie,
                extractvalue(column_value, '*/rodo/dPrev', l_nscte)               as dprev,
                extractvalue(column_value, '*/rodo/lacRodo/nLacre', l_nscte)      as nlacre,
                extractvalue(column_value, '*/rodo/lota', l_nscte)                as lota,
                extractvalue(column_value, '*/rodo/RNTRC', l_nscte)               as rntrc,
                extractvalue(column_value, '*/rodo/moto/CPF', l_nscte)            as cpf_moto,
                extractvalue(column_value, '*/rodo/moto/xNome', l_nscte)          as xnome_moto,
                extractvalue(column_value, '*/rodo/valePed/disp/dVig', l_nscte)   as dvig,
                extractvalue(column_value, '*/rodo/valePed/disp/nCompC', l_nscte) as ncompc,
                extractvalue(column_value, '*/rodo/valePed/disp/nDisp', l_nscte)  as ndisp,
                extractvalue(column_value, '*/rodo/valePed/disp/tpDisp', l_nscte) as tpdisp,
                extractvalue(column_value, '*/rodo/valePed/disp/xEmp', l_nscte)   as xemp,
                extractvalue(column_value, '*/rodo/valePed/nroRE', l_nscte)       as nrore,
                extractvalue(column_value, '*/rodo/valePed/respPg', l_nscte)      as resppg,
                extractvalue(column_value, '*/rodo/valePed/vTValePed', l_nscte)   as vtvaleped,
                extractvalue(column_value, '*/rodo/occ/dEmi', l_nscte)            as occ_demi,
                extractvalue(column_value, '*/rodo/occ/emiOcc/cInt', l_nscte)     as occ_cint,
                extractvalue(column_value, '*/rodo/occ/emiOcc/CNPJ', l_nscte)     as occ_cnpj,
                extractvalue(column_value, '*/rodo/occ/emiOcc/fone', l_nscte)     as occ_fone,
                extractvalue(column_value, '*/rodo/occ/emiOcc/IE', l_nscte)       as occ_ie,
                extractvalue(column_value, '*/rodo/occ/emiOcc/UF', l_nscte)       as occ_uf,
                extractvalue(column_value, '*/rodo/occ/nOcc', l_nscte)            as occ_nocc,
                extractvalue(column_value, '*/rodo/occ/serie', l_nscte)           as occ_serie,
                extractvalue(column_value, '*/rodo/veic/capKG', l_nscte)          as veic_capkg,
                extractvalue(column_value, '*/rodo/veic/capM3', l_nscte)          as veic_capm3,
                extractvalue(column_value, '*/rodo/veic/cInt', l_nscte)           as veic_cint,
                extractvalue(column_value, '*/rodo/veic/placa', l_nscte)          as veic_placa,
                extractvalue(column_value, '*/rodo/veic/RENAVAM', l_nscte)        as veic_renavam,
                extractvalue(column_value, '*/rodo/veic/tara', l_nscte)           as veic_tara,
                extractvalue(column_value, '*/rodo/veic/tpCar', l_nscte)          as veic_tpcar,
                extractvalue(column_value, '*/rodo/veic/tpProp', l_nscte)         as veic_tpprop,
                extractvalue(column_value, '*/rodo/veic/tpRod', l_nscte)          as veic_tprod,
                extractvalue(column_value, '*/rodo/veic/tpVeic', l_nscte)         as veic_tpveic,
                extractvalue(column_value, '*/rodo/veic/UF', l_nscte)             as veic_uf,
                extractvalue(column_value, '*/rodo/veic/prop/CNPJ', l_nscte)      as veic_prop_cnpj,
                extractvalue(column_value, '*/rodo/veic/prop/CPF', l_nscte)       as veic_prop_cpf,
                extractvalue(column_value, '*/rodo/veic/prop/IE', l_nscte)        as veic_prop_ie,
                extractvalue(column_value, '*/rodo/veic/prop/RNTRC', l_nscte)     as veic_prop_rntrc,
                extractvalue(column_value, '*/rodo/veic/prop/tpProp', l_nscte)    as veic_prop_tpprop,
                extractvalue(column_value, '*/rodo/veic/prop/UF', l_nscte)        as veic_prop_uf,
                extractvalue(column_value, '*/rodo/veic/prop/xNome', l_nscte)     as veic_prop_xnome
            from
                table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm', l_nscte)) );
    --
            rnormrodo   c_normrodo%rowtype;
    --
            cursor c_normaereo (
                p_infctenorm xmltype
            ) is
            select
                extractvalue(column_value, '*/aereo/cIATA', l_nscte)         as ciata,
                extractvalue(column_value, '*/aereo/dPrev', l_nscte)         as dprev,
                extractvalue(column_value, '*/aereo/dPrevAereo', l_nscte)    as dprevaereo,
                extractvalue(column_value, '*/aereo/nMinu', l_nscte)         as nminu,
                extractvalue(column_value, '*/aereo/nOCA', l_nscte)          as noca,
                extractvalue(column_value, '*/aereo/tarifa/CL', l_nscte)     as cl,
                extractvalue(column_value, '*/aereo/tarifa/cTar', l_nscte)   as ctar,
                extractvalue(column_value, '*/aereo/tarifa/trecho', l_nscte) as trecho,
                extractvalue(column_value, '*/aereo/tarifa/vTar', l_nscte)   as vtar,
                extractvalue(column_value, '*/aereo/xLAgEmi', l_nscte)       as xlagemi
            from
                table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm', l_nscte)) );
    --
            rnormaereo  c_normaereo%rowtype;
    --
            cursor c_normaquav (
                p_infctenorm xmltype
            ) is
            select
                extractvalue(column_value, '*/aquav/direc', l_nscte)        as direc,
                extractvalue(column_value, '*/aquav/irin', l_nscte)         as irin,
                extractvalue(column_value, '*/aquav/lacre/nLacre', l_nscte) as nlacre,
                extractvalue(column_value, '*/aquav/nBooking', l_nscte)     as nbooking,
                extractvalue(column_value, '*/aquav/nCtrl', l_nscte)        as nctrl,
                extractvalue(column_value, '*/aquav/nViag', l_nscte)        as nviag,
                extractvalue(column_value, '*/aquav/prtDest', l_nscte)      as prtdest,
                extractvalue(column_value, '*/aquav/prtEmb', l_nscte)       as prtemb,
                extractvalue(column_value, '*/aquav/prtTrans', l_nscte)     as prttrans,
                extractvalue(column_value, '*/aquav/tpNav', l_nscte)        as tpnav,
                extractvalue(column_value, '*/aquav/vAFRMM', l_nscte)       as vafrmm,
                extractvalue(column_value, '*/aquav/vPrest', l_nscte)       as vprest,
                extractvalue(column_value, '*/aquav/xNavio', l_nscte)       as xnavio
            from
                table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm', l_nscte)) );
    --
            rnormaquav  c_normaquav%rowtype;
    --
            cursor c_normsub (
                p_infctenorm xmltype
            ) is
            select
                extractvalue(column_value, '*/infCteSub/chCte', l_nscte)                   as chcte,
                extractvalue(column_value, '*/infCteSub/tomaICMS/refCte', l_nscte)         as refcte,
                extractvalue(column_value, '*/infCteSub/tomaICMS/refNF/CNPJ', l_nscte)     as cnpj,
                extractvalue(column_value, '*/infCteSub/tomaICMS/refNF/dEmi', l_nscte)     as demi,
                extractvalue(column_value, '*/infCteSub/tomaICMS/refNF/mod', l_nscte)      as mod,
                extractvalue(column_value, '*/infCteSub/tomaICMS/refNF/nro', l_nscte)      as nro,
                extractvalue(column_value, '*/infCteSub/tomaICMS/refNF/serie', l_nscte)    as serie,
                extractvalue(column_value, '*/infCteSub/tomaICMS/refNF/subserie', l_nscte) as subserie,
                extractvalue(column_value, '*/infCteSub/tomaICMS/refNF/valor', l_nscte)    as valor,
                extractvalue(column_value, '*/infCteSub/tomaICMS/refNFe', l_nscte)         as refnfe,
                extractvalue(column_value, '*/infCteSub/tomaNaoICMS/refCteAnu', l_nscte)   as refcteanu
            from
                table ( xmlsequence(extract(p_infctenorm, 'infCTeNorm', l_nscte)) );
    --
            rnormsub    c_normsub%rowtype;
    --
            cursor c_comp (
                p_infctecomp xmltype
            ) is
            select
                extractvalue(column_value, '*/chave', l_nscte)                         as chave,
                extractvalue(column_value, '*/vPresComp/vTPrest', l_nscte)             as vtprest,
                extractvalue(column_value, '*/vPresComp/compComp/vComp', l_nscte)      as vcomp,
                extractvalue(column_value, '*/vPresComp/compComp/xNome', l_nscte)      as xnome,
                extractvalue(column_value, '*/impComp/ICMSComp/CST00/CST', l_nscte)    as cst00_cst,
                extractvalue(column_value, '*/impComp/ICMSComp/CST00/pICMS', l_nscte)  as cst00_picms,
                extractvalue(column_value, '*/impComp/ICMSComp/CST00/vBC', l_nscte)    as cst00_vbc,
                extractvalue(column_value, '*/impComp/ICMSComp/CST00/vICMS', l_nscte)  as cst00_vicms,
                extractvalue(column_value, '*/impComp/ICMSComp/CST20/CST', l_nscte)    as cst20_cst,
                extractvalue(column_value, '*/impComp/ICMSComp/CST20/pICMS', l_nscte)  as cst20_picms,
                extractvalue(column_value, '*/impComp/ICMSComp/CST20/pRedBC', l_nscte) as cst20_predbc,
                extractvalue(column_value, '*/impComp/ICMSComp/CST20/vBC', l_nscte)    as cst20_vbc,
                extractvalue(column_value, '*/impComp/ICMSComp/CST20/vICMS', l_nscte)  as cst20_vicms,
                extractvalue(column_value, '*/impComp/ICMSComp/CST45/CST', l_nscte)    as cst45_cst,
                extractvalue(column_value, '*/impComp/ICMSComp/CST80/CST', l_nscte)    as cst80_cst,
                extractvalue(column_value, '*/impComp/ICMSComp/CST80/pICMS', l_nscte)  as cst80_picms,
                extractvalue(column_value, '*/impComp/ICMSComp/CST80/vBC', l_nscte)    as cst80_vbc,
                extractvalue(column_value, '*/impComp/ICMSComp/CST80/vCred', l_nscte)  as cst80_vcred,
                extractvalue(column_value, '*/impComp/ICMSComp/CST80/vICMS', l_nscte)  as cst80_vicms,
                extractvalue(column_value, '*/impComp/ICMSComp/CST81/CST', l_nscte)    as cst81_cst,
                extractvalue(column_value, '*/impComp/ICMSComp/CST81/pICMS', l_nscte)  as cst81_picms,
                extractvalue(column_value, '*/impComp/ICMSComp/CST81/pRedBC', l_nscte) as cst81_predbc,
                extractvalue(column_value, '*/impComp/ICMSComp/CST81/vBC', l_nscte)    as cst81_vbc,
                extractvalue(column_value, '*/impComp/ICMSComp/CST81/vICMS', l_nscte)  as cst81_vicms,
                extractvalue(column_value, '*/impComp/ICMSComp/CST90/CST', l_nscte)    as cst90_cst,
                extractvalue(column_value, '*/impComp/ICMSComp/CST90/pICMS', l_nscte)  as cst90_picms,
                extractvalue(column_value, '*/impComp/ICMSComp/CST90/pRedBC', l_nscte) as cst90_predbc,
                extractvalue(column_value, '*/impComp/ICMSComp/CST90/vBC', l_nscte)    as cst90_vbc,
                extractvalue(column_value, '*/impComp/ICMSComp/CST90/vCred', l_nscte)  as cst90_vcred,
                extractvalue(column_value, '*/impComp/ICMSComp/CST90/vICMS', l_nscte)  as cst90_vicms,
                extractvalue(column_value, '*/impComp/infAdFisco', l_nscte)            as infadfisco
            from
                table ( xmlsequence(extract(p_infctecomp, 'infCteComp', l_nscte)) );
    --
            rcomp       c_comp%rowtype;
    --
            cursor c_anu (
                p_infcteanu xmltype
            ) is
            select
                extractvalue(column_value, '*/chCte', l_nscte) as chcte,
                extractvalue(column_value, '*/dEmi', l_nscte)  as demi
            from
                table ( xmlsequence(extract(p_infcteanu, 'infCteAnu', l_nscte)) );
    --
            ranu        c_anu%rowtype;
    --
            cursor c_vprest (
                p_vprest xmltype
            ) is
            select
                extractvalue(column_value, '*/vTPrest', l_nscte) as vtprest,
                extractvalue(column_value, '*/vRec', l_nscte)    as vrec,
                ''                                               as vcomp
         --, EXTRACTVALUE(COLUMN_VALUE, '*/Comp/'         , l_nsCTe) as vComp
         --, EXTRACTVALUE(COLUMN_VALUE, '*/Comp/vTipComp' , l_nsCTe) as vTipComp
         --, EXTRACTVALUE(COLUMN_VALUE, '*/Comp/xNome'    , l_nsCTe) as xNome
            from
                table ( xmlsequence(extract(p_vprest, 'vPrest', l_nscte)) );
    --
            rvprest     c_vprest%rowtype;
    --
            cursor c_carga (
                p_infctenorm xmltype
            ) is
            select
                *
            from
                xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/cte' ),
                'infCTeNorm/infCarga/infQ'
                        passing p_infctenorm
                    columns
                        cunid varchar2(200) path '/infQ/cUnid/text()',
                        tpmed varchar2(200) path '/infQ/tpMed/text()',
                        qcarga number path '/infQ/qCarga/text()'
                );
    --
            rcarga      c_carga%rowtype;
    --
        begin
    --
    --
            rsource := psource;
    --
    --------------------------------------------
    -- Verifica se foi encontrado o diretorio --
    --------------------------------------------
            if rsource is not null then
      --
                begin
        --
        --xxgwb_inv_util.enable_log(2,rFile.name);
        --
                    l_xml := xmltype(rsource);
        --
                    rcte := null;
        --
                    for rcte in c_cte(l_xml) loop
          --
                        print('Carregando informações do cabeçalho - CTe');
          --
                        print('Versão....................: ' || rcte.versao);
                        print('Danfe.....................: ' || rcte.cod_danfe);
                        print('xCondPagto................: ' || rcte.xcondpagto);
          --
                        print('rIde');
          --
                        for r in c_ide(rcte.ide) loop
            --
                            ride := r;
            --
                            print('nCT.......................: ' || ride.nct);
            --Print('TipoNf....................: '||rIde.tiponf);
                            print('cUF.......................: ' || ride.cuf);
                            print('cCT.......................: ' || ride.cct);
                            print('cDV.......................: ' || ride.cdv);
                            print('CFOP......................: ' || ride.cfop);
                            print('xCFOP.....................: ' || ride.xcfop);
                            print('cMunEmi...................: ' || ride.cmunemi);
                            print('cMunFim...................: ' || ride.cmunfim);
                            print('cMunIni...................: ' || ride.cmunini);
                            print('dhEmi.....................: ' || ride.dhemi);
                            print('forPag....................: ' || ride.forpag);
                            print('mod.......................: ' || ride.mod);
                            print('modal.....................: ' || ride.modal);
                            print('natOp.....................: ' || ride.natop);
                            print('procEmi...................: ' || ride.procemi);
                            print('refCTE....................: ' || ride.refcte);
                            print('retira....................: ' || ride.retira);
                            print('serie.....................: ' || ride.serie);
                            print('tpAmb.....................: ' || ride.tpamb);
                            print('tpCTe.....................: ' || ride.tpcte);
                            print('tpEmis....................: ' || ride.tpemis);
                            print('tpImp.....................: ' || ride.tpimp);
                            print('tpServ....................: ' || ride.tpserv);
                            print('UFEmi.....................: ' || ride.ufemi);
                            print('UFFim.....................: ' || ride.uffim);
                            print('UFIni.....................: ' || ride.ufini);
                            print('verProc...................: ' || ride.verproc);
                            print('xDetRetira................: ' || ride.xdetretira);
                            print('xMunEmi...................: ' || ride.xmunemi);
                            print('xMunFim...................: ' || ride.xmunfim);
                            print('xMunIni...................: ' || ride.xmunini);
                            print('xNatOpPedag...............: ' || ride.xnatoppedag);
                            print('xInvoiceType..............: ' || ride.xinvoicetype);
                            print('toma......................: ' || ride.toma);
                            print('xCodTomador...............: ' || ride.xcodtomador);
                            print('xDesTomador...............: ' || ride.xdestomador);
                            print('toma4_toma................: ' || ride.toma4_toma);
                            print('toma4_CNPJ................: ' || ride.toma4_cnpj);
                            print('toma4_CPF.................: ' || ride.toma4_cpf);
                            print('toma4_IE..................: ' || ride.toma4_ie);
                            print('toma4_CEP.................: ' || ride.toma4_cep);
                            print('toma4_cMun................: ' || ride.toma4_cmun);
                            print('toma4_cPais...............: ' || ride.toma4_cpais);
                            print('toma4_nro.................: ' || ride.toma4_nro);
                            print('toma4_UF..................: ' || ride.toma4_uf);
                            print('toma4_xBairro.............: ' || ride.toma4_xbairro);
                            print('toma4_xCpl................: ' || ride.toma4_xcpl);
                            print('toma4_xLgr................: ' || ride.toma4_xlgr);
                            print('toma4_xMun................: ' || ride.toma4_xmun);
                            print('toma4_xPais...............: ' || ride.toma4_xpais);
                            print('toma4_fone................: ' || ride.toma4_fone);
                            print('toma4_xFant...............: ' || ride.toma4_xfant);
                            print('toma4_xNome...............: ' || ride.toma4_xnome);
            --
                        end loop;
          --
                        for r in c_dest(rcte.dest) loop
            --
                            rdest := r;
            --
                            print('rDest');
                            print('CNPJ......................: ' || rdest.cnpj);
                            print('CPF.......................: ' || rdest.cpf);
                            print('IE........................: ' || rdest.ie);
                            print('ISUF......................: ' || rdest.isuf);
                            print('xNome.....................: ' || rdest.xnome);
                            print('fone......................: ' || rdest.fone);
                            print('CEP.......................: ' || rdest.cep);
                            print('cMun......................: ' || rdest.cmun);
                            print('cPais.....................: ' || rdest.cpais);
                            print('nro.......................: ' || rdest.nro);
                            print('UF........................: ' || rdest.uf);
                            print('xBairro...................: ' || rdest.xbairro);
                            print('xCpl......................: ' || rdest.xcpl);
                            print('xLgr......................: ' || rdest.xlgr);
                            print('xMun......................: ' || rdest.xmun);
                            print('xPais.....................: ' || rdest.xpais);
                            print('xCodDest..................: ' || rdest.xcoddestinatario);
                            print('xNomDest..................: ' || rdest.xnomdestinatario);
            --
                        end loop;
          --
                        for r in c_emit(rcte.emit) loop
            --
                            remit := r;
            --
                            print('rEmit');
                            print('CNPJ......................: ' || remit.cnpj);
                            print('IE........................: ' || remit.ie);
                            print('xNome.....................: ' || remit.xnome);
                            print('xFant.....................: ' || remit.xfant);
                            print('CEP.......................: ' || remit.cep);
                            print('cMun......................: ' || remit.cmun);
                            print('cPais.....................: ' || remit.cpais);
                            print('fone......................: ' || remit.fone);
                            print('nro.......................: ' || remit.nro);
                            print('UF........................: ' || remit.uf);
                            print('xBairro...................: ' || remit.xbairro);
                            print('xCpl......................: ' || remit.xcpl);
                            print('xLgr......................: ' || remit.xlgr);
                            print('xMun......................: ' || remit.xmun);
                            print('xPais.....................: ' || remit.xpais);
                            print('xCodEmitente..............: ' || remit.xcodemitente);
                            print('xDesEmitente..............: ' || remit.xdesemitente);
            --
                        end loop;
          --
                        for r in c_rem(rcte.rem) loop
            --
                            rrem := r;
            --
                            print('rRem');
                            print('CNPJ......................: ' || rrem.cnpj);
                            print('CPF.......................: ' || rrem.cpf);
                            print('IE........................: ' || rrem.ie);
          --Print('ISUF......................: '|| rRem.ISUF);
                            print('xNome.....................: ' || rrem.xnome);
                            print('fone......................: ' || rrem.fone);
                            print('CEP.......................: ' || rrem.cep);
                            print('cMun......................: ' || rrem.cmun);
                            print('cPais.....................: ' || rrem.cpais);
                            print('nro.......................: ' || rrem.nro);
                            print('UF........................: ' || rrem.uf);
                            print('xBairro...................: ' || rrem.xbairro);
                            print('xCpl......................: ' || rrem.xcpl);
                            print('xLgr......................: ' || rrem.xlgr);
                            print('xMun......................: ' || rrem.xmun);
                            print('xPais.....................: ' || rrem.xpais);
                            print('xCodRemet.................: ' || rrem.xcodremetente);
                            print('xNomRemet.................: ' || rrem.xnomremetente);
            --
                        end loop;
          --
                        for r in c_exped(rcte.exped) loop
            --
                            rexped := r;
            --
                            print('rExped');
                            print('CNPJ......................: ' || rexped.cnpj);
                            print('CPF.......................: ' || rexped.cpf);
                            print('IE........................: ' || rexped.ie);
                            print('ISUF......................: ' || rexped.isuf);
                            print('xNome.....................: ' || rexped.xnome);
                            print('fone......................: ' || rexped.fone);
                            print('CEP.......................: ' || rexped.cep);
                            print('cMun......................: ' || rexped.cmun);
                            print('cPais.....................: ' || rexped.cpais);
                            print('nro.......................: ' || rexped.nro);
                            print('UF........................: ' || rexped.uf);
                            print('xBairro...................: ' || rexped.xbairro);
                            print('xCpl......................: ' || rexped.xcpl);
                            print('xLgr......................: ' || rexped.xlgr);
                            print('xMun......................: ' || rexped.xmun);
                            print('xPais.....................: ' || rexped.xpais);
                            print('xCodExped.................: ' || rexped.xcodexpedidor);
                            print('xNomExped.................: ' || rexped.xnomexpedidor);
            --
                        end loop;
          --
                        for r in c_receb(rcte.receb) loop
            --
                            rreceb := r;
            --
                            print('rReceb');
                            print('CNPJ......................: ' || rreceb.cnpj);
                            print('CPF.......................: ' || rreceb.cpf);
                            print('IE........................: ' || rreceb.ie);
                            print('ISUF......................: ' || rreceb.isuf);
                            print('xNome.....................: ' || rreceb.xnome);
                            print('fone......................: ' || rreceb.fone);
                            print('CEP.......................: ' || rreceb.cep);
                            print('cMun......................: ' || rreceb.cmun);
                            print('cPais.....................: ' || rreceb.cpais);
                            print('nro.......................: ' || rreceb.nro);
                            print('UF........................: ' || rreceb.uf);
                            print('xBairro...................: ' || rreceb.xbairro);
                            print('xCpl......................: ' || rreceb.xcpl);
                            print('xLgr......................: ' || rreceb.xlgr);
                            print('xMun......................: ' || rreceb.xmun);
                            print('xPais.....................: ' || rreceb.xpais);
                            print('xCodReceb.................: ' || rreceb.xcodrecebedor);
                            print('xNomReceb.................: ' || rreceb.xnomrecebedor);
            --
                        end loop;
          --
                        for r in c_compl(rcte.compl) loop
            --
                            rcompl := r;
            --
                            print('rCompl');
                            print('destCalc..................: ' || rcompl.destcalc);
                            print('origCalc..................: ' || rcompl.origcalc);
                            print('xCaracAd..................: ' || rcompl.xcaracad);
                            print('xCaracSer.................: ' || rcompl.xcaracser);
                            print('xEmi......................: ' || rcompl.xemi);
                            print('xObs......................: ' || rcompl.xobs);
            --
                        end loop;
          --
                        for r in c_vprest(rcte.vprest) loop
            --
                            rvprest := r;
            --
                            print('rVPrest');
                            print('vTPrest...................: ' || rvprest.vtprest);
                            print('vRec......................: ' || rvprest.vrec);
            --
            --
            --
                            begin
              --
                                for r_custom in (
                --
                                    select
                                        *
                                    from
                                        xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/cte' ),
                                        '/vPrest/Comp'
                                                passing rcte.vprest
                                            columns
                                                xnome varchar2(300) path '/Comp/xNome/text()',
                                                xcomp varchar2(300) path '/Comp/vComp/text()'
                                        ) itm
                                ) loop
                --
                                    if upper(r_custom.xnome) = 'FRETE VALOR' then
                  --
                                        print('Valor Frete: ' || r_custom.xcomp);
                  --                
                                    elsif upper(r_custom.xnome) = 'TARIFA' then
                  --
                                        rvprest.vcomp := r_custom.xcomp;
                  --
                                        print('Valor Unitário/Tarifa: ' || r_custom.xcomp);
                  --
                                    else
                                        print('TAG NÂO IDENTIFICADA NO CTE: ' || upper(r_custom.xnome),
                                              2);
                  --
                                    end if;
                -- 
        /*l_header.pis_amount                       := rRegh.ValorPis;
        l_header.cofins_amount                    := rRegh.ValorCofins;
        l_header.inss_amount                      := rRegh.ValorInss_Servico;
        l_header.ir_amount                        := rRegh.ValorIr;
        l_header.iss_amount                       := rRegh.ValorIss;
        l_header.iss_tax                          := rRegh.Aliquota;
        l_header.csll_amount                      := rRegh.ValorCsll;
        l_header.municipio_incidencia             := rRegh.CodigoMunicipio_Ser;
        l_header.incricao_obra                    := rRegh.constru_cod_obra;
        l_header.tributos_aproximados             := rRegh.Tributacao;
        l_header.fonte                            := NULL;
             l_header.simple_national_indicator     := CASE WHEN rRegh.OptanteSimplesNacional = 'NAO DEFINIDO' THEN '' ELSE rRegh.OptanteSimplesNacional END ;
        l_header.access_key_number             := lpad(LPAD(nvl(rRegh.Cnpj_Dest,rRegh.CPF_Emit),15,'0')||LPAD(nvl(rRegh.Cnpj,rRegh.CPF),15,'0')||to_char(l_header.issue_date,'YYYYMM')||LPAD(rRegh.Numero_Nff,8,'0'),44,'0');
        --
        Print('Chave NFSe: '||l_header.access_key_number);
        --
        g_ctrl.eletronic_invoice_key           := l_header.access_key_number;
        --
        l_header.creation_date                 := SYSDATE;
        l_header.CREATED_BY                    := '-1';
        l_header.LAST_UPDATE_DATE              := SYSDATE;
        l_header.LAST_UPDATED_BY               := '-1';
        --
        g_ctrl.status := 'P';
        --
        valid_org(nvl(rRegh.Cnpj_Dest,rRegh.CPF_Emit),g_ctrl.status);
        --
        IF nvl(g_ctrl.status,'P') <> 'E' THEN
          --
          IF nvl(rRegh.status_nf,'N') = 'C' THEN
            --
            g_ctrl.status := 'C';
            --
            BEGIN
              --
              INSERT INTO rmais_black_list_cancel VALUES (l_header.access_key_number,SYSDATE);
              --
            EXCEPTION WHEN OTHERS THEN
              NULL;--
            END;
            --
          END IF;
            --
            back_list(l_header.document_status,l_header.access_key_number);
            --
           BEGIN
             --
            INSERT INTO rmais_efd_headers_hdi VALUES l_header;
            --
            Print('Inserindo Header id: '||l_header.efd_header_id);
            --Print('---Registros inseridos---');
            --
           EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
              --
              IF nvl(g_ctrl.status,'N') = 'C' THEN
                --
                Print('***** Documento Cancelado *****');
                --
                BEGIN
                  --
                  UPDATE rmais_efd_headers_hdi
                     SET document_status = CASE WHEN document_status = 'T' THEN 'X' ELSE 'C' END
                   WHERE access_key_number = l_header.access_key_number;
                  --
                EXCEPTION WHEN OTHERS THEN
                  print('Erro ao atualizar status: '||SQLERRM);
                END;
                --
              ELSE
              --
              g_ctrl.status := 'D';
              --
              Print('***** Documento já integrado *****'||SQLERRM);
              --
              END IF;
              --
            WHEN OTHERS THEN
            --
            Print('Erro ao inserir rmais_efd_headers_hdi'||SQLERRM);
            --
            --
            g_ctrl.status := 'E';
            --
          END;
          --
        ELSE
          --
          Print('Não foi possível inserir registro STATUS: '||g_ctrl.status);
          --
        END IF;
          --
              Print('Carregando informações das Linhas da NFSe');
              --
              l_lines.efd_line_id        := rmais_efd_lines_s.nextval;
              l_lines.efd_header_id      := l_header.efd_header_id;
              l_lines.line_number        := rLin.Line_num ;
              l_lines.item_code          := rLin.xCod_Produto ;
              l_lines.item_description   := SUBSTR(rLin.xDes_Produto,1,110);--print('Error'||rLin.xDes_Produto);
              l_lines.source_doc_number  := rLin.Pedido ;
              l_lines.uom_to             := rLin.Uom;
              l_lines.line_quantity      := rLin.vQtde;
              l_lines.unit_price         := rLin.Valor_Un;
              l_lines.line_amount        := rLin.Valor_Tot;
              l_lines.city_service_type_rel_code := get_cod_serv_expecific(rRegh.CodigoMunicipio,rRegh.Serv_list);
              l_lines.fiscal_classification      := get_cod_serv_expecific(rRegh.CodigoMunicipio,rRegh.Serv_list);
              --
              l_lines.creation_date                 := SYSDATE;
              l_lines.CREATED_BY                    := -1;
              l_lines.LAST_UPDATE_DATE              := SYSDATE;
              l_lines.LAST_UPDATED_BY               := -1;
              --
              PRINT('Inserindo efd_line_id: '||l_lines.efd_line_id);*/
              --
             /*  BEGIN
                --rmais_process_pkg.main(p_header_id => l_header.efd_header_id);
              commit;
              EXCEPTION WHEN OTHERS THEN
                --raise_application_error (-20011,'Erro ao reprocessar documento '||sqlerrm);
                NULL;
              end;*/
              --  
                                end loop;
            --
                            exception
                                when others then
              --
                                    print('Error: Atribuição de variáveis ' || sqlerrm);
              --
                                    g_ctrl.status := 'E';
              --
                            end;
            --
            --
                        end loop;
          --
                        for r in c_imp(rcte.imp) loop
            --
                            rimp := r;
            --
                            print('rImp');
                            print('ICMS00_CST................: ' || rimp.icms00_cst);
                            print('ICMS00_pICMS..............: ' || rimp.icms00_picms);
                            print('ICMS00_vBC................: ' || rimp.icms00_vbc);
                            print('ICMS00_vICMS..............: ' || rimp.icms00_vicms);
                            print('ICMS20_CST................: ' || rimp.icms20_cst);
                            print('ICMS20_pICMS..............: ' || rimp.icms20_picms);
                            print('ICMS20_pRedBC.............: ' || rimp.icms20_predbc);
                            print('ICMS20_vBC................: ' || rimp.icms20_vbc);
                            print('ICMS20_vICMS..............: ' || rimp.icms20_vicms);
                            print('ICMS45_CST................: ' || rimp.icms45_cst);
                            print('ICMS60_CST................: ' || rimp.icms60_cst);
                            print('ICMS80_CST................: ' || rimp.icms80_cst);
                            print('ICMS80_pICMS..............: ' || rimp.icms80_picms);
                            print('ICMS80_vBC................: ' || rimp.icms80_vbc);
                            print('ICMS80_vCred..............: ' || rimp.icms80_vcred);
                            print('ICMS80_vICMS..............: ' || rimp.icms80_vicms);
                            print('ICMS81_CST................: ' || rimp.icms81_cst);
                            print('ICMS81_pICMS..............: ' || rimp.icms81_picms);
                            print('ICMS81_pRedBC.............: ' || rimp.icms81_predbc);
                            print('ICMS81_vBC................: ' || rimp.icms81_vbc);
                            print('ICMS81_vICMS..............: ' || rimp.icms81_vicms);
                            print('ICMS90_CST................: ' || rimp.icms90_cst);
                            print('ICMS90_pICMS..............: ' || rimp.icms90_picms);
                            print('ICMS90_pRedBC.............: ' || rimp.icms90_predbc);
                            print('ICMS90_vBC................: ' || rimp.icms90_vbc);
                            print('ICMS90_vCred..............: ' || rimp.icms90_vcred);
                            print('ICMS90_vICMS..............: ' || rimp.icms90_vicms);
                            print('ICMSOutraUF_CST...........: ' || rimp.icmsoutrauf_cst);
                            print('pICMSOutraUF..............: ' || rimp.picmsoutrauf);
                            print('pRedBCOutraUF.............: ' || rimp.predbcoutrauf);
                            print('vBCOutraUF................: ' || rimp.vbcoutrauf);
                            print('vICMSOutraUF..............: ' || rimp.vicmsoutrauf);
                            print('indSN.....................: ' || rimp.indsn);
                            print('infAdFisco................: ' || rimp.infadfisco);
            --
                        end loop;
          --
                        for r in c_comp(rcte.infctecomp) loop
            --
                            rcomp := r;
            --
                            print('rComp');
                            print('chave.....................: ' || rcomp.chave);
                            print('vTPrest...................: ' || rcomp.vtprest);
                            print('vComp.....................: ' || rcomp.vcomp);
                            print('xNome.....................: ' || rcomp.xnome);
                            print('CST00_CST.................: ' || rcomp.cst00_cst);
                            print('CST00_pICMS...............: ' || rcomp.cst00_picms);
                            print('CST00_vBC.................: ' || rcomp.cst00_vbc);
                            print('CST00_vICMS...............: ' || rcomp.cst00_vicms);
                            print('CST20_CST.................: ' || rcomp.cst20_cst);
                            print('CST20_pICMS...............: ' || rcomp.cst20_picms);
                            print('CST20_pRedBC..............: ' || rcomp.cst20_predbc);
                            print('CST20_vBC.................: ' || rcomp.cst20_vbc);
                            print('CST20_vICMS...............: ' || rcomp.cst20_vicms);
                            print('CST45_CST.................: ' || rcomp.cst45_cst);
                            print('CST80_CST.................: ' || rcomp.cst80_cst);
                            print('CST80_pICMS...............: ' || rcomp.cst80_picms);
                            print('CST80_vBC.................: ' || rcomp.cst80_vbc);
                            print('CST80_vCred...............: ' || rcomp.cst80_vcred);
                            print('CST80_vICMS...............: ' || rcomp.cst80_vicms);
                            print('CST81_CST.................: ' || rcomp.cst81_cst);
                            print('CST81_pICMS...............: ' || rcomp.cst81_picms);
                            print('CST81_pRedBC..............: ' || rcomp.cst81_predbc);
                            print('CST81_vBC.................: ' || rcomp.cst81_vbc);
                            print('CST81_vICMS...............: ' || rcomp.cst81_vicms);
                            print('CST90_CST.................: ' || rcomp.cst90_cst);
                            print('CST90_pICMS...............: ' || rcomp.cst90_picms);
                            print('CST90_pRedBC..............: ' || rcomp.cst90_predbc);
                            print('CST90_vBC.................: ' || rcomp.cst90_vbc);
                            print('CST90_vCred...............: ' || rcomp.cst90_vcred);
                            print('CST90_vICMS...............: ' || rcomp.cst90_vicms);
                            print('infAdFisco................: ' || rcomp.infadfisco);
            --
                        end loop;
          --
                        for r in c_normout(rcte.infctenorm) loop
            --
                            rnormout := r;
            --
                            print('rNormOut');
                            print('dEmi......................: ' || rnormout.demi);
                            print('descOutros................: ' || rnormout.descoutros);
                            print('dPrev.....................: ' || rnormout.dprev);
                            print('nDoc......................: ' || rnormout.ndoc);
                            print('tpDoc.....................: ' || rnormout.tpdoc);
                            print('vDocFisc..................: ' || rnormout.vdocfisc);
            --
                        end loop;
          --
                        for r in c_normsub(rcte.infctenorm) loop
            --
                            rnormsub := r;
            --
                            print('rNormSub');
                            print('chCte.....................: ' || rnormsub.chcte);
                            print('refCte....................: ' || rnormsub.refcte);
                            print('CNPJ......................: ' || rnormsub.cnpj);
                            print('dEmi......................: ' || rnormsub.demi);
                            print('mod.......................: ' || rnormsub.mod);
                            print('nro.......................: ' || rnormsub.nro);
                            print('serie.....................: ' || rnormsub.serie);
                            print('subserie..................: ' || rnormsub.subserie);
                            print('valor.....................: ' || rnormsub.valor);
                            print('refNFe....................: ' || rnormsub.refnfe);
                            print('refCteAnu.................: ' || rnormsub.refcteanu);
            --
                        end loop;
          --
                        for r in c_anu(rcte.infctenorm) loop
            --
                            ranu := r;
            --
                            print('rAnu');
                            print('chCte.....................: ' || ranu.chcte);
                            print('dEmi......................: ' || ranu.demi);
            --
                        end loop;
          --
                        for r in c_carga(rcte.infctenorm) loop
            --
         /* IF Valida_Tipo_Peso(r.tpMed) THEN --verificar se é necessário
            --
            rCarga := r;
            --
          ELSIF REGEXP_LIKE(r.tpMed,'PESO','i') AND rCarga.qCarga IS NULL THEN
            --
            rCarga := r;
            --
          END IF;*/
            --
                            print('rCarga');
                            print('tpMed.....................: '
                                  || r.tpmed
                                  || ' ' ||
                                case
                                    when rcarga.tpmed = r.tpmed then
                                        '(Carregado)'
                                end
                            );

                            print('cUnid.....................: ' || r.cunid);
                            print('qCarga....................: ' || r.qcarga);
            --
                        end loop;
          --
          --
         /* rSource.rHead.Cte_Type                    := rIde.tpCTe;
          rSource.rHead.Invoice_Num                 := rIde.Nct;
          rSource.rHead.Series                      := rIde.Serie;
          rSource.rHead.Terms_name                  := nvl(rCte.xCondPagto,rSource.rHead.Terms_name);--NVL(rCte.xCondPagto,'30 DAYS NO DISCOUNT'); 
          rSource.rHead.Eletronic_Invoice_Key       := rCte.Cod_Danfe;
          rSource.rHead.Invoice_Amount              := Nvl(rVPrest.vTPrest,0);
          rSource.rHead.Invoice_Date                := To_timestamp_tz(rIde.dhEmi,'RRRR-MM-DD"T"HH24:MI:SS TZR');
          rSource.rHead.Comments                    := rCompl.xObs;
          rSource.rHead.Source_State_code           := rEmit.UF;
          rSource.rHead.Document_Number             := rEmit.CNPJ;
          rSource.rHead.Fiscal_Document_Model       := rIde.Mod;
          rSource.rHead.Gross_Total_Amount          := NVL(rVPrest.vTPrest,0);
          rSource.rHead.Icms_Tax                    := rImp.ICMS_pICMS;
          rSource.rHead.Icms_Base                   := NVL(rImp.Icms_Vbc,    0);
          rSource.rHead.Icms_Amount                 := NVL(rImp.Icms_Vicms,    0);
          rSource.rHead.Icms_St_Base                := NVL(rImp.Icms60_vBCSTRet, 0);
          rSource.rHead.Icms_St_Amount              := NVL(rImp.Icms60_vICMSSTRet, 0);
          rSource.rHead.Icms_St_Amount_Recover      := 0;
          rSource.rHead.Subst_Icms_Base             := 0;
          rSource.rHead.Subst_Icms_Amount           := 0;
          rSource.rHead.Diff_Icms_Amount            := 0;
          rSource.rHead.Diff_Icms_Amount_Recover    := 0;
          rSource.rHead.Diff_Icms_Tax               := 0;
          rSource.rHead.Inss_Amount                 := 0;
          rSource.rHead.Inss_Base                   := 0;
          rSource.rHead.Inss_Tax                    := 0; --
          rSource.rHead.Ipi_Amount                  := 0;
          rSource.rHead.Ir_Amount                   := 0;
          rSource.rHead.Ir_Base                     := 0;
          rSource.rHead.Ir_Categ                    := 0; --
          rSource.rHead.Ir_Tax                      := 0;
          rSource.rHead.Iss_Amount                  := 0;
          rSource.rHead.Iss_Base                    := 0;
          rSource.rHead.Iss_Tax                     := 0;
          rSource.rHead.Other_Expenses              := 0;
          rSource.rHead.Pis_Withhold_Amount         := 0;
          rSource.rHead.Cofins_Withhold_Amount      := 0;
          rSource.rHead.Payment_Discount            := 0;
          rSource.rHead.Freight_Amount              := 0;
          --
          rSource.rEfd.receiver_name                := CASE rIde.toma WHEN '0' THEN rRem.xNome WHEN '1' THEN rExped.xNome WHEN '2' THEN rReceb.xNome ELSE CASE WHEN rIde.toma4_toma = '4' THEN rIde.toma4_xNome ELSE rDest.xNome END END;
          rSource.rEfd.receiver_document_number     := CASE rIde.toma WHEN '0' THEN NVL(rRem.CNPJ, rRem.CPF)  WHEN '1' THEN NVL(rExped.CNPJ, rExped.CPF)  WHEN '2' THEN NVL(rReceb.CNPJ, rReceb.CPF)  ELSE CASE WHEN rIde.toma4_toma = '4' THEN NVL(rIde.toma4_CNPJ, rIde.toma4_CPF) ELSE NVL(rDest.CNPJ, rDest.CPF) END END;
          rSource.rEfd.receiver_address_state       := CASE rIde.toma WHEN '0' THEN rRem.UF    WHEN '1' THEN rExped.UF    WHEN '2' THEN rReceb.UF    ELSE CASE WHEN rIde.toma4_toma = '4' THEN rIde.toma4_UF    ELSE rDest.UF    END END;
          rSource.rEfd.receiver_address_city_code   := CASE rIde.toma WHEN '0' THEN rRem.cMun  WHEN '1' THEN rExped.cMun  WHEN '2' THEN rReceb.cMun  ELSE CASE WHEN rIde.toma4_toma = '4' THEN rIde.toma4_cMun  ELSE rDest.cMun  END END;
          rSource.rEfd.receiver_address_city_name   := CASE rIde.toma WHEN '0' THEN rRem.xMun  WHEN '1' THEN rExped.xMun  WHEN '2' THEN rReceb.xMun  ELSE CASE WHEN rIde.toma4_toma = '4' THEN rIde.toma4_xMun  ELSE rDest.xMun  END END;
          rSource.rEfd.receiver_address             := CASE rIde.toma WHEN '0' THEN rRem.xLgr  WHEN '1' THEN rExped.xLgr  WHEN '2' THEN rReceb.xLgr  ELSE CASE WHEN rIde.toma4_toma = '4' THEN rIde.toma4_xLgr  ELSE rDest.xLgr  END END;
          rSource.rEfd.receiver_address_number      := CASE rIde.toma WHEN '0' THEN rRem.nro   WHEN '1' THEN rExped.nro   WHEN '2' THEN rReceb.nro   ELSE CASE WHEN rIde.toma4_toma = '4' THEN rIde.toma4_nro   ELSE rDest.nro   END END;
          rSource.rEfd.receiver_address_complement  := CASE rIde.toma WHEN '0' THEN rRem.xCpl  WHEN '1' THEN rExped.xCpl  WHEN '2' THEN rReceb.xCpl  ELSE CASE WHEN rIde.toma4_toma = '4' THEN rIde.toma4_xCpl  ELSE rDest.xCpl  END END;
          rSource.rEfd.receiver_address_zip_code    := CASE rIde.toma WHEN '0' THEN rRem.CEP   WHEN '1' THEN rExped.CEP   WHEN '2' THEN rReceb.CEP   ELSE CASE WHEN rIde.toma4_toma = '4' THEN rIde.toma4_CEP   ELSE rDest.CEP   END END;
          --
          rSource.rEfd.issuer_name                  := rEmit.xNome;
          rSource.rEfd.issuer_document_number       := apps.xxrmais_util_pkg.lpad(NVL(rEmit.CNPJ, rEmit.CPF),14,'0');
          rSource.rEfd.issuer_address_state         := rEmit.UF;
          rSource.rEfd.issuer_address_city_code     := rEmit.cMun;
          rSource.rEfd.issuer_address_city_name     := rEmit.xMun;
          rSource.rEfd.issuer_address               := rEmit.xLgr;
          rSource.rEfd.issuer_address_number        := rEmit.nro;
          rSource.rEfd.issuer_address_complement    := rEmit.xCpl;
          rSource.rEfd.issuer_address_zip_code      := rEmit.CEP;*/
          --
                        if rrem.uf = 'EX'
                        or nvl(rrem.cnpj, rrem.cpf) like '%000' then
            --
  /*          rSource.rEfd.ship_from_document_number    := NVL(rExped.CNPJ, rExped.CPF);
            rSource.rEfd.ship_from_address_state      := rExped.UF;
            rSource.rEfd.ship_from_address_city_code  := rExped.cMun;
            rSource.rEfd.ship_from_address_city_name  := rExped.xMun;
            rSource.rEfd.ship_from_address            := rExped.xLgr;
            rSource.rEfd.ship_from_address_number     := rExped.nro ;
            rSource.rEfd.ship_from_address_complement := rExped.xCpl;   */
                            null;
            --
                        else
            --
        /*    rSource.rEfd.ship_from_document_number    := NVL(rRem.CNPJ, rRem.CPF);
            rSource.rEfd.ship_from_address_state      := rRem.UF;
            rSource.rEfd.ship_from_address_city_code  := rRem.cMun;
            rSource.rEfd.ship_from_address_city_name  := rRem.xMun;
            rSource.rEfd.ship_from_address            := rRem.xLgr;
            rSource.rEfd.ship_from_address_number     := rRem.nro ;
            rSource.rEfd.ship_from_address_complement := rRem.xCpl;*/
                            null;
            --
                        end if;
          --
       /*   rSource.rEfd.ship_to_document_number      := NVL(rDest.CNPJ, rDest.CPF);
          rSource.rEfd.ship_to_address_state        := rDest.UF;
          rSource.rEfd.ship_to_address_city_code    := rDest.cMun;
          rSource.rEfd.ship_to_address_city_name    := rDest.xMun;
          rSource.rEfd.ship_to_address              := rDest.xLgr;
          rSource.rEfd.ship_to_address_number       := rDest.nro;
          rSource.rEfd.ship_to_address_complement   := rDest.xCpl;
          --
          rSource.rEfd.file_name                    := rSource.rCtrl.Filename;
          rSource.rEfd.process_date                 := trunc(SYSDATE);
          rSource.rEfd.tributary_regimen            := CASE WHEN (rIde.tpCTe = 1 AND rImp.indSN = 1) OR (rIde.tpCTe <> 1 AND rImp.indSN = 1) THEN 1 ELSE 3 END;
          rSource.rEfd.layout_version               := rCTe.Versao;
          rSource.rEfd.operation                    := 'INBOUND';
          rSource.rEfd.issuing_type                 := rIde.tpEmis;
          rSource.rEfd.issuing_purpose              := rIde.tpCTe;
          rSource.rEfd.issue_date                   := rSource.rHead.Invoice_Date;
          rSource.rEfd.document_type                := CASE WHEN rEmit.CPF IS NOT NULL THEN 'CPF' ELSE 'CNPJ' END;
          rSource.rEfd.operation_nature             := rIde.natOp; 
          rSource.rEfd.service_taker_type           := NVL(rIde.toma, rIde.toma4_toma); 
          rSource.rEfd.freight_ibge_source          := rIde.cMunIni; Print('Saindo do Loop');
          rSource.rEfd.freight_ibge_destination     := CASE WHEN rIde.cMunFim LIKE ('%-%') THEN '00000' ELSE rIde.cMunFim END;
          rSource.rEfd.source_ibge_code             := rIde.cMunIni;
          rSource.rEfd.source_state_code            := rIde.UFIni;
          rSource.rEfd.destination_ibge_code        := rSource.rEfd.receiver_address_city_code;
          rSource.rEfd.destination_state_code       := rSource.rEfd.receiver_address_state;*/
          --
          -- Verifica? se CTE ?NBOUND ou OUTBOUND
          --
          /*DECLARE
          l_aux_cnpj_rem  NUMBER;
          l_aux_cnpj_dest NUMBER;
          BEGIN
            --
            SELECT COUNT (cnpj) 
              INTO l_aux_cnpj_rem
              FROM apps.xxrmais_INV_ORGANIZATION_V
             WHERE cnpj = NVL(rRem.CNPJ, rRem.CPF);
            --
            --
            SELECT COUNT (cnpj) 
              INTO l_aux_cnpj_dest
              FROM apps.xxrmais_INV_ORGANIZATION_V
             WHERE cnpj = NVL(rDest.CNPJ, rDest.CPF);
            --
            IF l_aux_cnpj_rem > 0 AND l_aux_cnpj_dest > 0 THEN
              --
              Print('Tranferencia intercompany');
              --
              rSource.rEfd.operation_type := 1;
              --
            ELSIF l_aux_cnpj_rem > 0 AND l_aux_cnpj_dest = 0 THEN
              --
              Print('CTE Outbound');
              --
              rSource.rEfd.operation_type := 1;
              --
            ELSIF l_aux_cnpj_rem = 0 AND l_aux_cnpj_dest > 0 THEN
              --
              Print('CTE Inbound');
              --
              rSource.rEfd.operation_type := 0;
              --
            END IF;
            --
            l_aux_cnpj_rem  := 0;
            l_aux_cnpj_dest := 0;
            --
          EXCEPTION
              WHEN OTHERS THEN
                Print('Erro na verifica? de tipo de NF CTE Outbound/Inbound');
          END;
          --
          --
          rSource.rCtrl.Tipo_Doc                    := rIde.Mod;
          rSource.rCtrl.CNPJ_Emit                   := rEmit.CNPJ;
          rSource.rCtrl.CPF_Emit                    := rEmit.CPF;
          rSource.rCtrl.Simples_BR                  := rImp.indSN;
          rSource.rCtrl.tomador                     := rSource.rEfd.service_taker_type;
          rSource.rCtrl.CNPJ_Dest                   := rSource.rEfd.receiver_document_number;
          rSource.rHead.Destination_State_code      := rSource.rEfd.receiver_address_state;
          --
          vIDX := 1;
          --
          rSource.rLines(vIDX).Reg.item_number               := vIDX;
          rSource.rLines(vIDX).Cfo_Saida                     := rIde.CFOP; --CFOP_FROM
          rSource.rLines(vIDX).Reg.discount_amount           := 0;
          rSource.rLines(vIDX).Reg.freight_amount            := 0;
          rSource.rLines(vIDX).Reg.insurance_amount          := 0;
          rSource.rLines(vIDX).Reg.other_expenses            := 0;
          -- 
          rSource.rLines(vIDX).Reg.Quantity                  := CASE WHEN APPS.xxrmais_recebemais_util.get_parameter('TEXT_VALUE','CONTROL','XXRMAIS_DFE_CTE_MODEL1') = NVL(rSource.rCtrl.CNPJ_Emit,rSource.rCtrl.CPF_Emit) THEN
                                                                   ROUND((nvl(rCarga.qCarga,1) / 1000),2) --tonelada
                                                                 WHEN APPS.xxrmais_recebemais_util.get_parameter('TEXT_VALUE','CONTROL','XXRMAIS_DFE_CTE_MODEL2') = NVL(rSource.rCtrl.CNPJ_Emit,rSource.rCtrl.CPF_Emit) THEN
                                                                   NVL(rCarga.qCarga,1)
                                                                 ELSE 
                                                                   1
                                                                 END ;
          --
          rSource.rLines(vIDX).Reg.unit_price                := CASE WHEN APPS.xxrmais_recebemais_util.get_parameter('TEXT_VALUE','CONTROL','XXRMAIS_DFE_CTE_MODEL1') = NVL(rSource.rCtrl.CNPJ_Emit,rSource.rCtrl.CPF_Emit) THEN
                                                                   ROUND((NVL(rVPrest.vTPrest,0) / rSource.rLines(vIDX).Reg.Quantity),2)
                                                                 WHEN APPS.xxrmais_recebemais_util.get_parameter('TEXT_VALUE','CONTROL','XXRMAIS_DFE_CTE_MODEL2') = NVL(rSource.rCtrl.CNPJ_Emit,rSource.rCtrl.CPF_Emit) THEN
                                                                   nvl(rVPrest.vComp,NVL(rVPrest.vTPrest,0))
                                                                 ELSE 
                                                                   nvl(rVPrest.vComp,NVL(rVPrest.vTPrest,0))
                                                                 END ;
          --
          rSource.rLines(vIDX).Reg.cfo_code                  := NVL(rIde.xCFOP, rIde.CFOP);
          rSource.rLines(vIDX).Cst_Origem                    := 0;
          rSource.rLines(vIDX).Cst_Pis                       := '56';
          rSource.rLines(vIDX).Cst_Cofins                    := '56';
          rSource.rLines(vIDX).Cst_Icms                      := rImp.ICMS_CST;
          rSource.rLines(vIDX).Cst_Ipi                       := '03';
          rSource.rLines(vIDX).Reg.classification_code       :='00000000';
          rSource.rLines(vIDX).Reg.cofins_amount             := 0;
          rSource.rLines(vIDX).Reg.cofins_amount_recover     := 0;
          rSource.rLines(vIDX).Reg.cofins_base_amount        := 0;
          rSource.rLines(vIDX).Reg.cofins_tax_rate           := 0;
          rSource.rLines(vIDX).Reg.cofins_tributary_code     := '56';
          rSource.rLines(vIDX).Reg.cofins_unit_amount        := '';
          rSource.rLines(vIDX).Reg.cofins_qty                := '';
          rSource.rLines(vIDX).Reg.deferred_icms_amount      := 0;
          rSource.rLines(vIDX).Reg.diff_icms_tax             := 0;
          rSource.rLines(vIDX).Reg.diff_icms_amount_recover  := 0;
          rSource.rLines(vIDX).Reg.icms_amount_recover       := 0;
          rSource.rLines(vIDX).Reg.description               := 'TRANSPORTE';
          rSource.rLines(vIDX).Reg.icms_amount               := rImp.ICMS_vICMS;
          rSource.rLines(vIDX).Reg.icms_base                 := NVL(rImp.ICMS_vBC, 0);
          rSource.rLines(vIDX).Reg.icms_tax                  := rImp.ICMS_pICMS;
          rSource.rLines(vIDX).Reg.Icms_Tax_Code             := CASE WHEN NVL(rImp.Icms00_CST
                                                                        ,     rImp.Icms20_CST) IS NOT NULL THEN 1 ELSE
                                                                CASE WHEN     rImp.Icms45_CST  IS NOT NULL THEN 2 ELSE 3 END END;
          --
          --
          rSource.rLines(vIDX).Reg.icms_st_base              := NVL(rImp.Icms60_vBCSTRet,  0);
          rSource.rLines(vIDX).Reg.icms_st_amount            := NVL(rImp.Icms60_vICMSSTRet,0);
          rSource.rLines(vIDX).Reg.icms_st_amount_recover    := 0;
          rSource.rLines(vIDX).Reg.Icms_Type                 := CASE rIde.tpCTe WHEN '0' THEN CASE SIGN(rSource.rHead.Icms_Base) WHEN 1 THEN 'NORMAL' ELSE 'EXEMPT' END WHEN 3 THEN 'SUBSTITUTE' ELSE CASE WHEN rImp.indSN = 1 THEN 'EXEMPT' ELSE 'NORMAL' END END;
          rSource.rLines(vIDX).Reg.ipi_amount                := 0;
          rSource.rLines(vIDX).Reg.ipi_amount_recover        := 0;
          rSource.rLines(vIDX).Reg.ipi_base_amount           := 0;
          rSource.rLines(vIDX).Reg.ipi_tax                   := 0;
          rSource.rLines(vIDX).Reg.ipi_tax_code              := 3;
          rSource.rLines(vIDX).Reg.ipi_tributary_code        := '03';
          rSource.rLines(vIDX).Reg.ipi_unit_amount           := 0;
          rSource.rLines(vIDX).Reg.iss_base_amount           := 0;
          rSource.rLines(vIDX).Reg.iss_tax_amount            := 0;
          rSource.rLines(vIDX).Reg.iss_tax_rate              := 0;
          rSource.rLines(vIDX).Reg.pis_amount                := 0;
          rSource.rLines(vIDX).Reg.pis_amount_recover        := 0;
          rSource.rLines(vIDX).Reg.pis_base_amount           := 0;
          rSource.rLines(vIDX).Reg.pis_tax_rate              := 0;
          rSource.rLines(vIDX).Reg.pis_tributary_code        := '56';
          rSource.rLines(vIDX).Reg.pis_unit_amount           := '';
          rSource.rLines(vIDX).Reg.pis_qty                   := '';
          rSource.rLines(vIDX).Reg.tributary_status_code     := 0||lpad(rImp.icms_cst,2,'0');
          rSource.rLines(vIDX).Reg.net_amount                := (rSource.rLines(vIDX).Reg.unit_price * rSource.rLines(vIDX).Reg.quantity); */                                           --Correção Line_amount
          --
          --
                        print('CTE FOB - Carregando informações da NF referenciada');
          --
          /*rSource.rHead.total_freight_weight := NVL(rCarga.qCarga,0);*/
          --
                        for rnormnf in c_normnf(rcte.infctenorm) loop
            --
                            print('rNormNF');
                            print('chave.....................: ' || rnormnf.chave);
                            print('dPrev.....................: ' || rnormnf.dprev);
                            print('PIN.......................: ' || rnormnf.pin);
                            print('dEmi......................: ' || rnormnf.demi);
                            print('mod.......................: ' || rnormnf.mod);
                            print('nCFOP.....................: ' || rnormnf.ncfop);
                            print('nDoc......................: ' || rnormnf.ndoc);
                            print('serie.....................: ' || rnormnf.serie);
                            print('nPed......................: ' || rnormnf.nped);
                            print('nPeso.....................: ' || rnormnf.npeso);
                            print('nRoma.....................: ' || rnormnf.nroma);
                            print('vBC.......................: ' || rnormnf.vbc);
                            print('vBCST.....................: ' || rnormnf.vbcst);
                            print('vICMS.....................: ' || rnormnf.vicms);
                            print('vNF.......................: ' || rnormnf.vnf);
                            print('vProd.....................: ' || rnormnf.vprod);
                            print('vST.......................: ' || rnormnf.vst);
            --Print('Entity_id.................: '||rSource.rHead.Entity_id);
                            print('cnpj  Key.................: ' || substr(rnormnf.chave, 07, 14));
                            print('nDoc  Key.................: ' || substr(rnormnf.chave, 26, 09));
                            print('serie Key.................: ' || substr(rnormnf.chave, 23, 03));
            --
                            begin
              --
                                if rnormnf.chave is not null --AND LENGTH(regexp_replace(rNormNF.nDoc,'[[:digit:]]')) = 0 
                                 then
                --
                /*rSource.rRef(rNormNF.seq).Hea.ref_access_key_number      := rNormNF.chave;
                rSource.rRef(rNormNF.seq).Hea.ref_document_number        := nvl(rNormNF.nDoc, Substr(rNormNF.chave,26,09)); 
                rSource.rRef(rNormNF.seq).Hea.ref_series                 := nvl(rNormNF.serie,Substr(rNormNF.chave,23,03));
                rSource.rRef(rNormNF.seq).Hea.ref_model                  := rNormNF.mod;
                rSource.rRef(rNormNF.seq).Hea.ref_issuer_document_num    := NVL(NVL(rRem.CNPJ, rRem.CPF),Substr(rNormNF.chave,07,14));
                rSource.rRef(rNormNF.seq).Hea.ref_issuer_ibge_code       := rRem.cMun;
                rSource.rRef(rNormNF.seq).Hea.referenced_othersdoc       := CASE WHEN rNormNF.tipo = 'Outros' THEN rNormNF.nDoc END;
*/
                                    null;
                --
                                end if;
              --
                            exception
                                when others then
                                    print('Erro ao carregadar dados da NF referenciada');
                --Insert_File_Error (rSource.rCtrl.Filename, 'Falha ao carregar dados da NF referenciada '||SQLERRM);
                            end;
            --
                            if ride.toma = 3 then
              --
                                null;
              --
                            end if;
            --
                        end loop;
          --
          --
         -- Insert_Interface(rSource);
          --
                        begin
            --
                            l_header.doc_id := g_ctrl_id;
                            l_header.access_key_number := g_ctrl.eletronic_invoice_key;
                            print('l_header.access_key_number2: ' || l_header.access_key_number);
                            l_header.model := '57';
                            l_header.series := ride.serie;
            --l_header.efd_header_id                 := xxrmais_invoices_s.nextval ;
                            l_header.document_number := ride.nct;
                            g_ctrl.numero := ride.nct;
           -- l_header.cod_verif_nfs                 := rRegh.CodigoVerificacao;
                            l_header.issue_date := to_timestamp_tz ( ride.dhemi,
                            'RRRR-MM-DD"T"HH24:MI:SS TZR' );
                            l_header.additional_information := rcompl.xobs;
            --l_header.Iss_Base                      := CASE WHEN nvl(rRegh.ValorIss,0) > 0 THEN rRegh.BaseCalculo ELSE 0 END;
                            l_header.net_amount := rcomp.vtprest;
            --
                            l_header.receiver_name :=
                                case ride.toma
                                    when '0' then
                                        rrem.xnome
                                    when '1' then
                                        rexped.xnome
                                    when '2' then
                                        rreceb.xnome
                                    else
                                        case
                                            when ride.toma4_toma = '4' then
                                                    ride.toma4_xnome
                                            else
                                                rdest.xnome
                                        end
                                end;

                            l_header.receiver_document_number :=
                                case ride.toma
                                    when '0' then
                                        nvl(rrem.cnpj, rrem.cpf)
                                    when '1' then
                                        nvl(rexped.cnpj, rexped.cpf)
                                    when '2' then
                                        nvl(rreceb.cnpj, rreceb.cpf)
                                    else
                                        case
                                            when ride.toma4_toma = '4' then
                                                    nvl(ride.toma4_cnpj, ride.toma4_cpf)
                                            else
                                                nvl(rdest.cnpj, rdest.cpf)
                                        end
                                end;

                            l_header.receiver_address_state :=
                                case ride.toma
                                    when '0' then
                                        rrem.uf
                                    when '1' then
                                        rexped.uf
                                    when '2' then
                                        rreceb.uf
                                    else
                                        case
                                            when ride.toma4_toma = '4' then
                                                    ride.toma4_uf
                                            else
                                                rdest.uf
                                        end
                                end;

                            l_header.receiver_address_city_code :=
                                case ride.toma
                                    when '0' then
                                        rrem.cmun
                                    when '1' then
                                        rexped.cmun
                                    when '2' then
                                        rreceb.cmun
                                    else
                                        case
                                            when ride.toma4_toma = '4' then
                                                    ride.toma4_cmun
                                            else
                                                rdest.cmun
                                        end
                                end;

                            l_header.receiver_address_city_name :=
                                case ride.toma
                                    when '0' then
                                        rrem.xmun
                                    when '1' then
                                        rexped.xmun
                                    when '2' then
                                        rreceb.xmun
                                    else
                                        case
                                            when ride.toma4_toma = '4' then
                                                    ride.toma4_xmun
                                            else
                                                rdest.xmun
                                        end
                                end;

                            l_header.receiver_address :=
                                case ride.toma
                                    when '0' then
                                        rrem.xlgr
                                    when '1' then
                                        rexped.xlgr
                                    when '2' then
                                        rreceb.xlgr
                                    else
                                        case
                                            when ride.toma4_toma = '4' then
                                                    ride.toma4_xlgr
                                            else
                                                rdest.xlgr
                                        end
                                end;

                            l_header.receiver_address_number :=
                                case ride.toma
                                    when '0' then
                                        rrem.nro
                                    when '1' then
                                        rexped.nro
                                    when '2' then
                                        rreceb.nro
                                    else
                                        case
                                            when ride.toma4_toma = '4' then
                                                    ride.toma4_nro
                                            else
                                                rdest.nro
                                        end
                                end;

                            l_header.receiver_address_complement :=
                                case ride.toma
                                    when '0' then
                                        rrem.xcpl
                                    when '1' then
                                        rexped.xcpl
                                    when '2' then
                                        rreceb.xcpl
                                    else
                                        case
                                            when ride.toma4_toma = '4' then
                                                    ride.toma4_xcpl
                                            else
                                                rdest.xcpl
                                        end
                                end;

                            l_header.receiver_address_zip_code :=
                                case ride.toma
                                    when '0' then
                                        rrem.cep
                                    when '1' then
                                        rexped.cep
                                    when '2' then
                                        rreceb.cep
                                    else
                                        case
                                            when ride.toma4_toma = '4' then
                                                    ride.toma4_cep
                                            else
                                                rdest.cep
                                        end
                                end;
            --
                            l_header.issuer_name := remit.xnome;
                            l_header.issuer_document_number := nvl(remit.cnpj, remit.cpf);
                            l_header.issuer_address_state := remit.uf;
                            l_header.issuer_address_city_code := remit.cmun;
                            l_header.issuer_address_city_name := remit.xmun;
                            l_header.issuer_address := remit.xlgr;
                            l_header.issuer_address_number := remit.nro;
                            l_header.issuer_address_complement := remit.xcpl;
                            l_header.issuer_address_zip_code := remit.cep;
            --l_header.competencia_nfs               := rRegh.Competencia;
                            l_header.total_amount := nvl(rvprest.vtprest, 0);
                            l_header.source_state_code := remit.uf;
            --l_header.Document_Number             := rEmit.CNPJ;
            --l_header.Icms_Tax                    := rImp.ICMS_pICMS;
            --l_header.Icms_Base                   := NVL(rImp.Icms_Vbc,    0);
                            l_header.icms_amount := nvl(rimp.icms_vicms, 0);
            --l_header.Icms_St_Base                := NVL(rImp.Icms60_vBCSTRet, 0);
                            l_header.icms_st_amount := nvl(rimp.icms60_vicmsstret, 0);
            --
            --
                            l_header.creation_date := sysdate;
                            l_header.created_by := -1;
                            l_header.last_update_date := sysdate;
                            l_header.last_updated_by := -1;
              --
            --
                            if rrem.uf = 'EX'
                            or nvl(rrem.cnpj, rrem.cpf) like '%000' then
              --
                                l_header.ship_from_document_number := nvl(rexped.cnpj, rexped.cpf);
                                l_header.ship_from_address_state := rexped.uf;
                                l_header.ship_from_address_city_code := rexped.cmun;
                                l_header.ship_from_address_city_name := rexped.xmun;
                                l_header.ship_from_address := rexped.xlgr;
                                l_header.ship_from_address_number := rexped.nro;
                                l_header.ship_from_address_complement := rexped.xcpl;   
              --
                            else
              --
                                l_header.ship_from_document_number := nvl(rrem.cnpj, rrem.cpf);
                                l_header.ship_from_address_state := rrem.uf;
                                l_header.ship_from_address_city_code := rrem.cmun;
                                l_header.ship_from_address_city_name := rrem.xmun;
                                l_header.ship_from_address := rrem.xlgr;
                                l_header.ship_from_address_number := rrem.nro;
                                l_header.ship_from_address_complement := rrem.xcpl;
              --
                            end if;
              --
                            l_header.ship_to_document_number := nvl(rdest.cnpj, rdest.cpf);
                            l_header.ship_to_address_state := rdest.uf;
                            l_header.ship_to_address_city_code := rdest.cmun;
                            l_header.ship_to_address_city_name := rdest.xmun;
                            l_header.ship_to_address := rdest.xlgr;
                            l_header.ship_to_address_number := rdest.nro;
                            l_header.ship_to_address_complement := rdest.xcpl;
              --
              --
              --rSource.rEfd.file_name                    := rSource.rCtrl.Filename;
                            l_header.process_date := trunc(sysdate);
                            l_header.tributary_regimen :=
                                case
                                    when ( ride.tpcte = 1
                                           and rimp.indsn = 1 )
                                         or ( ride.tpcte <> 1
                                              and rimp.indsn = 1 ) then
                                        1
                                    else
                                        3
                                end;

                            l_header.layout_version := rcte.versao;
                            l_header.operation := 'INBOUND';
                            l_header.issuing_type := ride.tpemis;
                            l_header.issuing_purpose := ride.tpcte;
                            l_header.document_type :=
                                case
                                    when remit.cpf is not null then
                                        'CPF'
                                    else
                                        'CNPJ'
                                end;

                            l_header.operation_nature := ride.natop;
                            l_header.service_taker_type := nvl(ride.toma, ride.toma4_toma);
                            l_header.freight_ibge_source := ride.cmunini;
                            l_header.freight_ibge_destination :=
                                case
                                    when ride.cmunfim like ( '%-%' ) then
                                        '00000'
                                    else
                                        ride.cmunfim
                                end;

                            l_header.source_ibge_code := ride.cmunini;
                            l_header.source_state_code := ride.ufini;
                            l_header.destination_ibge_code := l_header.receiver_address_city_code;
                            l_header.destination_state_code := l_header.receiver_address_state;
                            l_header.poc := g_ctrl.process;
              --l_header.total_freight_weight         := NVL(rCarga.qCarga,0);
            --
              ---g_ctrl.Tipo_Doc                    := rIde.Mod;
              --g_ctrl.CNPJ_Emit                   := rEmit.CNPJ;
              --g_ctrl.CPF_Emit                    := rEmit.CPF;
              --g_ctrl.Simples_BR                  := rImp.indSN;
              --g_ctrl.tomador                     := l_header.service_taker_type;
              --g_ctrl.CNPJ_Dest                   := l_header.receiver_document_number;
              --g_ctrl.Destination_State_code      := l_header.receiver_address_state;
              --
                            vidx := 1;
              --
             -- SELECT * FROM rmais_efd_lines
              ---XXXXX
            --rSource.rLines(vIDX).Reg.Operation_Fiscal_Type     := rCTe.xOperFiscal;
                            l_lines.line_number := vidx;
              --l_lines.Cfop_from                 := rIde.CFOP; --CFOP_FROM
                            l_lines.discount_line_amount := 0;
                            l_lines.freight_line_amount := 0;
                            l_lines.insurance_line_amount := 0;
                            l_lines.other_expenses_line_amount := 0;
              -- 
                            l_lines.line_quantity := 1;/*CASE WHEN APPS.xxrmais_recebemais_util.get_parameter('TEXT_VALUE','CONTROL','XXRMAIS_DFE_CTE_MODEL1') = NVL(rSource.rCtrl.CNPJ_Emit,rSource.rCtrl.CPF_Emit) THEN
                                                                       ROUND((nvl(rCarga.qCarga,1) / 1000),2) --tonelada
                                                                     WHEN APPS.xxrmais_recebemais_util.get_parameter('TEXT_VALUE','CONTROL','XXRMAIS_DFE_CTE_MODEL2') = NVL(rSource.rCtrl.CNPJ_Emit,rSource.rCtrl.CPF_Emit) THEN
                                                                       NVL(rCarga.qCarga,1)
                                                                     ELSE 
                                                                       1
                                                                     END ;*/
              --
                            l_lines.unit_price := nvl(rvprest.vtprest, 0);/*CASE WHEN APPS.xxrmais_recebemais_util.get_parameter('TEXT_VALUE','CONTROL','XXRMAIS_DFE_CTE_MODEL1') = NVL(rSource.rCtrl.CNPJ_Emit,rSource.rCtrl.CPF_Emit) THEN
                                                                       ROUND((NVL(rVPrest.vTPrest,0) / rSource.rLines(vIDX).Reg.Quantity),2)
                                                                     WHEN APPS.xxrmais_recebemais_util.get_parameter('TEXT_VALUE','CONTROL','XXRMAIS_DFE_CTE_MODEL2') = NVL(rSource.rCtrl.CNPJ_Emit,rSource.rCtrl.CPF_Emit) THEN
                                                                       nvl(rVPrest.vComp,NVL(rVPrest.vTPrest,0))
                                                                     ELSE 
                                                                       nvl(rVPrest.vComp,NVL(rVPrest.vTPrest,0))
                                                                     END ;*/
              --
                            l_lines.cfop_from := nvl(ride.xcfop, ride.cfop);
                            l_lines.goods_origin_to := 0;
                            l_lines.pis_cst_to := '56';
                            l_lines.cofins_cst_to := '56';
                            l_lines.icms_cst_to := rimp.icms_cst;
                            l_lines.ipi_cst_to := '03';
                            l_lines.fiscal_classification := '00000000';
                            l_lines.cofins_amount := 0;
              --l_lines.cofins_amount_recover     := 0;
                            l_lines.cofins_calc_basis := 0;
                            l_lines.cofins_rate := 0;
                            l_lines.cofins_cst_to := '56';
                            l_lines.cofins_unit_amount := '';
                            l_lines.cofins_base_quantity := '';
                            l_lines.icms_st_amount := 0;
              --l_lines.diff_icms_tax             := 0;
              --l_lines.diff_icms_amount_recover  := 0;
              --l_lines.icms_amount_recover       := 0;
                            l_lines.item_description := 'TRANSPORTE';
                            l_lines.icms_amount := rimp.icms_vicms;
              --l_header.ICMS_CALCULATION_BASIS   := nvl(l_lines.icms_amount,0)
                            l_lines.icms_calc_basis := nvl(rimp.icms_vbc, 0);
                            l_lines.icms_rate := rimp.icms_picms;
                            l_lines.icms_taxable_flag :=
                                case
                                    when nvl(rimp.icms00_cst, rimp.icms20_cst) is not null then
                                        1
                                    else
                                        case
                                            when rimp.icms45_cst is not null then
                                                    2
                                            else
                                                3
                                        end
                                end;
              --
              --
                            l_lines.icms_st_calc_basis := nvl(rimp.icms60_vbcstret, 0);
                            l_lines.icms_st_amount := nvl(rimp.icms60_vicmsstret, 0);
             -- l_lines.icms_st_amount_recover    := 0;
                            l_lines.ri_icms_type :=
                                case ride.tpcte
                                    when '0' then
                                            case sign(l_header.icms_calculation_basis)
                                                when 1 then
                                                    'NORMAL'
                                                else
                                                    'EXEMPT'
                                            end
                                    when 3   then
                                        'SUBSTITUTE'
                                    else
                                        case
                                            when rimp.indsn = 1 then
                                                    'EXEMPT'
                                            else
                                                'NORMAL'
                                        end
                                end;

                            l_lines.ipi_amount := 0;
              --l_lines.ipi_amount_recover        := 0;
              --l_lines.ipi_base_amount           := 0;
              --l_lines.ipi_tax                   := 0;
              --l_lines.ipi_tax_code              := 3;
              --l_lines.ipi_tributary_code        := '03';
              --l_lines.ipi_unit_amount           := 0;
              --l_lines.iss_base_amount           := 0;
              --l_lines.iss_tax_amount            := 0;
              --l_lines.Reg.iss_tax_rate              := 0;
              --l_lines.Reg.pis_amount                := 0;
              --l_lines.pis_amount_recover        := 0;
              --l_lines.pis_base_amount           := 0;
              --l_lines.pis_tax_rate              := 0;
              --l_lines.Reg.pis_tributary_code        := '56';
              --l_lines.pis_unit_amount           := '';
              --l_lines.pis_qty                   := '';
              --l_lines.tributary_status_code     := 0||lpad(rImp.icms_cst,2,'0');
                            l_lines.net_amount := ( l_lines.unit_price * l_lines.line_quantity );  
              --
                            l_lines.creation_date := sysdate;
                            l_lines.created_by := -1;
                            l_lines.last_update_date := sysdate;
                            l_lines.last_updated_by := -1;
              --
                        exception
                            when others then 
           --
                                print('Error: Ao atribuir variáveis ' || sqlerrm);
                                g_ctrl.status := 'E';
           --
                        end;

                    end loop; -- CTe
        --
                    if ride.tpcte = 1 then
          --
                        print('CTe Complementar');
          --
          -- Validar Tipo nf payment_flag = 'S' and parent_flag = 'S' and credit_debit_flag = 'D' and freight_flag = 'N' and triangle_operation = 'N' and operation_type = 'E' and return_customer_flag = 'N' and foreign_currency_usage = 'N' and generate_return_invoice = 'N'
          --
                    elsif
                        ride.tpcte in ( 0, 3 )
                        and --Normal(0) Substituto(3)
                         ride.tpemis = 1
                        and --Normal
                         ( nvl(ride.forpag, 1) = 1 )
                    then --A pagar
          --
                        if rnormnf.nped is not null then
            --
                            print('CTe Normal Com PO');
            --
            -- Validar Tipo NF o  Requisition_type =  'PO' and payment_flag = 'S' and parent_flag = 'N' and credit_debit_flag = 'D' and freight_flag = 'N' and triangle_operation = 'N' and operation_type = 'E' and return_flag = 'N' and bonus_flag = 'N' and import_icms_flag = 'N' and include_iss_flag = 'N' and return_customer_flag = 'N' and foreign_currency_usage = 'N' and generate_return_invoice = 'N' and inss_calculation_flag = 'N' and include_icms_flag = 'S' se um dos campos abaixo for > '0,00', caso contrário include_icms_flag = 'N'
            -- Validar PO - PO_HEADERS_ALL.TYPE_LOOKUP_CODE = `STANDARD¿
            --
                        else
            --
                            print('CTe Normal Sem PO');
            --
            -- Validar Tipo NF o  Requisition_type =  'NA' and payment_flag = 'S' and parent_flag = 'N' and credit_debit_flag = 'D' and freight_flag = 'N' and triangle_operation = 'N' and operation_type = 'E' and return_flag = 'N' and bonus_flag = 'N' and import_icms_flag = 'N' and include_iss_flag = 'N' and include_iss_flag = 'N' and return_customer_flag = 'N' and foreign_currency_usage = 'N' and generate_return_invoice = 'N' and inss_calculation_flag = 'N' and include_icms_flag = 'S' se um dos campos abaixo for > '0,00', caso contrário include_icms_flag = 'N'
            --
                        end if;
          --
                    end if;
        --
                    if check_nf_exists(g_ctrl.eletronic_invoice_key)
                    or g_ctrl.status = 'E'
                    or check_tomador_cte(nvl(l_header.receiver_document_number, '999')) = false then
          --
                        if check_nf_exists(g_ctrl.eletronic_invoice_key) then
            --
                            g_ctrl.status := 'D';
                            print('*** NF já existente na plataforma - DUPLICADA ***');
            --
                        end if;
          --
                        if check_tomador_cte(nvl(l_header.issuer_document_number, '999')) = false then
            --
                            g_ctrl.status := 'R'; --Identificada como não tomador CTE
                            print('*** Cte identificado como não tomador, documento descartado CNPJ TOMADOR: '
                                  || nvl(l_header.issuer_document_number, '999') || ' ***');
            --
                        end if;
          --
                        l_header := null;
                        l_lines := null;
          --
                    else
          --
                        print('*** Inserção nas tabelas R+ CTE ***');
          --
                        begin
            --
                            l_header.efd_header_id := xxrmais_invoices_s.nextval;
                            l_lines.efd_header_id := l_header.efd_header_id;
                            l_lines.efd_line_id := rmais_efd_lines_s.nextval;
            --
                            print('l_header.access_key_number: ' || l_header.access_key_number);
            --
            -- Buscando BU_NAME na integração
                            begin
              --
                                l_header.bu_name := json_value(rmais_process_pkg.get_taxpayer(l_header.receiver_document_number, 'RECEIVER'
                                ),
           '$.DATA.BU_NAME');
              --
                                print('BU_NAME: '
                                      || l_header.bu_name
                                      || 'CNPJ: ' || l_header.receiver_document_number);
              --
                            exception
                                when others then
              --
                                    print('Não foi possível identificar a BU_NAME' || sqlerrm, 2);
              --
                            end;

                            insert into rmais_efd_headers_hdi values l_header;

                            insert into rmais_efd_lines_hdi values l_lines;
            --
                            g_ctrl.status := 'P';
            --
                            commit;
            --
                            begin
              --
                                print('Call main - 4-ini *************************************************************************************'
                                );
                --rmais_process_pkg.main(p_header_id => l_header.efd_header_id, p_flag_auto => 'Y');
                                print('Call main - 4-ter *************************************************************************************'
                                );
                                commit;
              --
                            exception
                                when others then
              --raise_application_error (-20011,'Erro ao reprocessar documento '||sqlerrm);
                                    null;
                            end;
            --
                        exception
                            when others then
            --
                                print('Error: Inserção de dados nas tabelas ' || sqlerrm);
            --
                                g_ctrl.status := 'E';
            --
                        end;
          --
                    end if;
        --
                exception
                    when others then
          --apps.xxrmais_global_pkg.g_Retcode := retcode_f;
          --apps.xxrmais_global_pkg.g_Errbuf  := 'Erro ao processar arquivo ('||rSource.rCtrl.Filename||') '||SQLERRM;
          --Insert_File_Error (rSource.rCtrl.Filename, apps.xxrmais_global_pkg.g_Errbuf);
                        print('Error: ao processar documento' || sqlerrm);
                end;
      --
   --   FIM(rSource, apps.xxrmais_global_pkg.g_Retcode);
      --
            else
      --
      /*apps.xxrmais_global_pkg.g_Retcode := retcode_f;
      apps.xxrmais_global_pkg.g_Errbuf := 'ARQUIVO NÃO CARREGADO!';*/
                print('Error: documento não processado' || sqlerrm);
      --
    --  Insert_File_Error (NVL(rSource.rCtrl.Filename,'FILE NOT FOUND ')||TO_CHAR(SYSDATE,'DD/MM/RRRR HH24:MI:SS'), apps.xxrmais_global_pkg.g_Errbuf);
      --
            end if;
    --
    --Finalizar;
    --
        exception
            when others then
    --  apps.xxrmais_global_pkg.g_Retcode := retcode_f;
    --  apps.xxrmais_global_pkg.g_Errbuf := NVL(rSource.rCtrl.Filename,'GENERIC FAILURE')||' '||SQLERRM;
      --
                print('Falha geral (CTE) ' || sqlerrm);
      --
        end load_read_file_xml_cte;
  --
        procedure process_xml (
            p_source_orig clob,
            p_ctrl_id     number default null
        ) as
    --
            l_xml       xmltype;
            xml_clob    clob;
            l_clob_decr clob;
            l_filename  rmais_efd_headers_hdi.blob_filename%type;
            l_file      rmais_efd_headers_hdi.blob_file%type;
    --base64decode_to_blob(json_value(l_clob,'$.BASE64' returning clob))
        begin
      --
            print('Iniciando leitura xml');
      --Print(p_source_orig);
            l_clob_decr := json_value(p_source_orig, '$.xml' returning clob);
      --
            if json_value(p_source_orig, '$.filename') is not null then
        --
                l_filename := json_value(p_source_orig, '$.filename');
                l_file := base64decode_to_blob_poc(json_value(p_source_orig, '$.file' returning clob));
        --
            end if;
--      print(TO_CHAR(SUBSTR (l_clob_decr,0,3999)));
--
      --print(l_clob_decr);
      --Print('Falha');
      --print('xml: '||l_clob_decr);
            begin
       /* l_clob_decr := convert(dbms_lob.substr(l_clob_decr,dbms_lob.getlength(l_clob_decr)),
                                              'AL32UTF8',
                                              'WE8ISO8859P15');*/
                l_clob_decr := xxrmais_util_pkg.base64decode(l_clob_decr);
      --
      --print('DECODE: '||l_clob_decr);
            exception
                when others then
                    print('Erro ao Decriptografar BASE64 ' || sqlerrm);
            end;
      --
      --print('xml: '||l_clob_decr);
            g_ctrl.process := xxrmais_util_pkg.get_value_json('process', p_source_orig);
            g_ctrl.id_doc := json_value(p_source_orig, '$.id');
      --
            print('Processo: ' || g_ctrl.process);
      --
            l_xml := ( xmltype(l_clob_decr) );
      --
            xml_clob := l_xml.getclobval();
      --
     -- Print(xml_clob);
      --
            g_ctrl.source_doc_decr := xml_clob;
      --
            g_ctrl.process := xxrmais_util_pkg.get_value_json('process', p_source_orig);
      --
            if
                ( regexp_like(xml_clob, 'nfeProc')
                or regexp_like(xml_clob, 'http://www.portalfiscal.inf.br/nfe') )
                and xml_clob not like '%<resNFe%'
            then
        --
                xml_clob := replace(xml_clob, '¿<?xml version="1.0" encoding="UTF-8"?>', '');
        --
                xml_clob := replace(xml_clob, '¿<?xml version="1.0" encoding="UTF-8" ?><nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
                , '<nfeProc versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe">');
        --
                xml_clob := replace(xml_clob, '<?xml version="1.0" encoding="UTF-8" ?><nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
                , '<nfeProc versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe">');
        --
                xml_clob := replace(xml_clob, '<protNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">', '<protNFe versao="4.00">)'
                );
        --
        --
                xml_clob := replace(xml_clob, '¿<', '<');
        --
                g_ctrl.tipo_fiscal := '55';
       -- PRINT(xml_clob);
                for rnfe in (
                    select
                        danfe,
                        serie,
                        num_nf                  numero,
                        nvl(cnpj_for, cpf_emit) cnpj_cpf,
                        referenciada
                    from
                        xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/nfe' ),
                        '/nfeProc'
                                passing xmltype(xml_clob)
                            columns
                                danfe varchar2(200) path '/nfeProc/protNFe/infProt/chNFe/text()',
                                serie varchar2(150) path '/nfeProc/NFe/infNFe/ide/serie/text()',
                                num_nf varchar2(150) path '/nfeProc/NFe/infNFe/ide/nNF/text()',
                                cnpj_for varchar2(200) path '/nfeProc/NFe/infNFe/emit/CNPJ/text()',
                                cpf_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/CPF/text()',
                                referenciada varchar2(200) path '//nfeProc/NFe/infNFe/ide/NFref/refNFe/text()'
                        )
                ) loop
                    if rnfe.referenciada is not null then
                        begin
                            insert into rmais_notas_devolucao (
                                id_nd,
                                access_key_number_purchase,
                                access_key_number_devolution,
                                status,
                                data_criacao,
                                data_update
                            ) values ( nota_devolucao_seq.nextval,
                                       rnfe.referenciada,
                                       rnfe.danfe,
                                       'AU',
                                       sysdate,
                                       sysdate );

                        exception
                            when others then
                                g_ctrl.status := 'E';
                        end;
                    end if;
         -- SELECT 'Y' FROM xxrmais_
          --
          --g_source.tipo_nf   := 'Nfe';
                    g_ctrl.eletronic_invoice_key := rnfe.danfe;
          --r.rCtrl.Danfe := rNfe.Danfe;
                    print('XML estruturado 55 Chave: ' || rnfe.danfe);
          --
          --
                    print('rNfe.cnpj_cpf: ' || rnfe.cnpj_cpf);
                    print('rNfe.Danfe   : ' || rnfe.danfe);
                    print('rNfe.numero  : ' || rnfe.numero);
                    print('rNfe.serie   : ' || rnfe.serie);
          --
                    declare
          --
                        l_aux varchar2(1);
          --
                    begin
            --
            --
           /* SELECT 'Y'
              INTO l_aux
              FROM xxrmais_invoices
             WHERE cnpj_cpf = rNfe.cnpj_cpf
             AND (eletronic_invoice_key = rNfe.Danfe OR
                  (numero_nff = rNfe.numero AND
                   serie     = nvl(rNfe.serie,serie)));*/  --FAZER VALIDAÇÃO COM TABELA FINAL
                        select
                            1
                        into l_aux
                        from
                            dual
                        where
                            1 <> 1;
            --
                        print('Documento Duplicado');
            --
                        g_ctrl.status := 'D';
            --
                    exception
                        when no_data_found then
            --
                            load_nfe(xml_clob);
            --
                    end;
          --
          --
                end loop;
        --
                if g_ctrl.eletronic_invoice_key is null then
          --
                    g_ctrl.status := 'E';
          --
                    print('Erro na leitura do XML NFe');
          --
                end if;
        --
            elsif regexp_like(xml_clob, 'cteOSProc') then
        --
                for rcte in (
                    select
                        chave
                    from
                        xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/cte' ),
                        '/cteOSProc/protCTe'
                                passing xmltype(xml_clob)
                            columns
                                chave varchar2(150) path 'infProt/chCTe/text()'
                        ) r
                ) loop
          --
                    g_ctrl.tipo_fiscal := '67';
          --g_source.tipo_nf   := 'Cte';
                    g_ctrl.eletronic_invoice_key := rcte.chave;
          --
                    load_read_file_xml_cteos(xml_clob);
          --
                    print('XML estruturado CTEos Chave: ' || rcte.chave);
          --
                end loop;
        --
            elsif regexp_like(xml_clob, 'cteProc') then
        --
                for rcte in (
                    select
                        danfe
                    from
                        xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/cte' ),
                        '/cteProc/protCTe/infProt'
                                passing xmltype(xml_clob)
                            columns
                                danfe varchar2(100) path 'chCTe/text()'
                        )
                ) loop
          --
                    g_ctrl.tipo_fiscal := '57';
          --g_source.tipo_nf   := 'Cte';
                    g_ctrl.eletronic_invoice_key := rcte.danfe;
          --
                    load_read_file_xml_cte(xml_clob);
          --
                    print('XML estruturado CTE Chave: ' || rcte.danfe);
          --
                end loop;
        --
      --
            elsif regexp_like(xml_clob, '<resNFe xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance'
            )
            or regexp_like(xml_clob, 'procEventoNFe') then
        --
                print('**** XML identificado como EVENTO ****');
                g_ctrl.status := 'M';
                g_ctrl.source_doc_decr := xml_clob;
        --
                print('Documento de Status de Nf');
                for rst in (
                    select
                        danfe,
                        situacao
                    from
                        xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/nfe' ),
                        '/resNFe'
                                passing xmltype(xml_clob)
                            columns
                                danfe varchar2(100) path 'chNFe/text()',
                                situacao varchar2(1) path 'cSitNFe/text()'
                        )
                ) loop
          --
                    print('Chave: ' || rst.danfe);
                    print('Situação: ' || rst.situacao);
          --
                    g_ctrl.eletronic_invoice_key := rst.danfe;
          --
                    if rst.situacao in ( '2', '3' ) then
            --
                        begin
              --
                            insert into rmais_black_list_cancel values ( rst.danfe,
                                                                         sysdate );
              --
                        exception
                            when others then
                                null;
                        end;
            --
                        begin
                            update rmais_efd_headers_hdi
                            set
                                document_status = 'C'
                            where
                                access_key_number = rst.danfe;

                        exception
                            when others then
                                null;
                        end;
            --
                    end if;
          --
                end loop;
        --
            else
        --
                if regexp_like(xml_clob, '<Modelo>CAP</Modelo>') then
          --
                    print('TIPO ABRASF RECEBEMAIS - FATURA');
                    g_ctrl.tipo_fiscal := 'Fatura';
          --g_source.tipo_nf   := g_ctrl.tipo_fiscal;
          --
                else
          --
                    print('TIPO ABRASF RECEBEMAIS NFse');
                    g_ctrl.tipo_fiscal := 'NFse';
          --g_source.tipo_nf   := g_ctrl.tipo_fiscal;
          --g_ctrl.eletronic_invoice_key := SUBSTR (g_ctrl.file_name,1,INSTR(upper(g_ctrl.file_name),'.XML')-1);
                    g_source.eletronic_invoice_key := g_ctrl.eletronic_invoice_key;
          --
          --
                    declare
           --
                        l_xml clob;
           --
                    begin
            --
           --IF  xml_clob NOT LIKE '%<tcNfse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">%' THEN
             --g_ctrl.status := 'E';
             --Print('Layout não Abrasf');
             --Print(xml_clob);
                        load_read_file_xml_nfse(xml_clob, l_filename, l_file, g_ctrl.process);
           --END IF;
            --
                        l_xml := replace(xml_clob, '<tcNfse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <InfNfse xmlns="http://www.abrasf.org.br/nfse.xsd">', '<tcNfse>
          <InfNfse>');
           --pRINT(l_xml);
                        for nfse in (
                            select
                                xnfs.numero_nff numero,
                                ''              serie,
                                xnfs.cnpj_emit  cnpj_cpf
                            from
                                xmltable ( '/tcNfse'
                                        passing xmltype(l_xml)
                                    columns
                                        numero_nff varchar2(30) path '/tcNfse/InfNfse/Numero/text()',
                                        cnpj_emit varchar2(150) path '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Prestador/CpfCnpj/Cnpj/text()'
                                        ,
                                        cpf_emit varchar2(150) path '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Prestador/CpfCnpj/Cpf/text()'
                                ) xnfs
                        ) loop
                       --
                            print('nfse.cnpj_cpf: ' || nfse.cnpj_cpf);
                            print('g_ctrl.eletronic_invoice_key: ' || g_ctrl.eletronic_invoice_key);
                            print('nfse.numero: ' || nfse.numero);
                  --
                            declare
                  --
                                l_aux varchar2(1);
                  --
                            begin
                    --
                    --
                                select
                                    'Y'
                                into l_aux
                                from
                                    xxrmais_invoices
                                where
                                        cnpj_cpf = nfse.cnpj_cpf
                                    and ( eletronic_invoice_key = g_ctrl.eletronic_invoice_key
                                          or ( numero_nff = nfse.numero
                                               and serie = nvl(nfse.serie, serie) ) );
                    --
                                print('Documento Duplicado');
                    --
                                g_ctrl.status := 'D';
                    --
                            exception
                                when no_data_found then
                    --
                    --load_nfse(xml_clob);
                                    null;
                    --
                            end;
                  --
                        end loop;

                    end;
                  --
                    if g_ctrl.status = 'D' then
                    --
                        print('Descartando armazenamento em banco do XML SOURCE', 2);
                    --
                        g_ctrl.source_doc_decr := null;
                    --
                    else
                    --
                        g_ctrl.source_doc_decr := xml_clob;
                    --
                        print('Armazenando XML SOURCE', 2);
                    --
                    end if;
                  --
                end if;
                --Get_Layout(r);
                --
            end if;

        end process_xml;
    --
    --
--
    begin
  --
        execute immediate 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/YYYY''';
        print('Iniciando');
  --
        execute immediate 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''.,''';
  ---
        g_log := null;
        g_status := null;
  --
  --debug
  --
        for reg_nf in (
            select
                *
            from
                (
                    select
                        *
                    from
                        rmais_ctrl_docs_poc
                    where
                            1 = 1--CASE WHEN p_id IS NULL THEN '1' ELSE status END = CASE WHEN p_id IS NULL THEN '1' ELSE 'N' END
                        and case
                                when p_id is null then
                                    nvl(status, 'N')
                                else
                                    'X'
                            end = case
                                      when p_id is null then
                                          'N'
                                      else
                                          'X'
                                  end
                        and id = nvl(p_id, id)
                    order by
                        id desc
                )
            where
                rownum <= 10
        ) loop
    --
            begin
      --
      --print(TO_CHAR(SUBSTR (reg_nf.source_doc_orig,0,3999)));
                if 1 = 1 then
        --
        --FOR x IN 1..file_source.last  LOOP
          --
          --
                    g_log := null;
          --
                    g_ctrl := null;
          --
                    g_status := null;--P processado  E Error   D Duplicada
          --
                    g_source := null;
          --
                    g_source_l := null;
          --
                    g_ctrl_id := null;
          --
                    g_doc_count := g_doc_count + 1;
          --
                    print('Processamento do documento numero: ' || g_doc_count);
          --
                    print('Inicio de processo de integração APEX ' || to_char(systimestamp, 'dd-mm-yyyy hh24:mi:ss.FF'));
          --
                    print('ID: ' || reg_nf.id);
          --
                    g_ctrl_id := reg_nf.id;
          --
                    process_xml(reg_nf.source_doc_orig, reg_nf.id);
          --
                    print(
                        case
                            when g_ctrl.status = null then
                                'Status nulo, alterando para Erro'
                            else
                                'Status: ' || g_ctrl.status
                        end
                    );
          --
                    g_ctrl.status := nvl(g_ctrl.status, 'E');
          --
          --
                    print('Final Processo ID: '
                          || reg_nf.id
                          || ' ' || to_char(systimestamp, 'dd-mm-yyyy hh24:mi:ss.FF'));
          --
                    print('');
          --
                    print('g_ctrl.status: ' || g_ctrl.status);
          --
                    begin
            --
                        update rmais_ctrl_docs_poc
                        set
                            cnpj_fornecedor = g_ctrl.cnpj_fornecedor,
                            filename = g_ctrl.filename,
                            tipo_fiscal = g_ctrl.tipo_fiscal,
                            status = g_ctrl.status,
                            log_process = g_log,
                            source_doc_decr = g_ctrl.source_doc_decr,
                            process_date = sysdate,
                            eletronic_invoice_key = g_ctrl.eletronic_invoice_key,
                            numero = g_ctrl.numero,
                            serie = g_ctrl.serie,
                            process = g_ctrl.process,
                            id_doc = g_ctrl.id_doc
                        where
                            id = reg_nf.id;
          --
                    exception
                        when others then
                            g_ctrl.status := 'E';
          --
                            print('Erro ao fazer update: ' || sqlerrm);
          --
                            print('Update CTRL ID: '
                                  || reg_nf.id
                                  || ' ' || to_char(systimestamp, 'dd-mm-yyyy hh24:mi:ss.FF'));
          --
                    end;
        --
                else
        --
                    print('Nenhum arquivo a processar');
        --
                end if;
      --
            exception
                when others then
      --
                    print('Erro ao buscar arquivo: ' || sqlerrm);
      --
                    g_ctrl.status := 'E';
                    update rmais_ctrl_docs_poc
                    set
                        status = g_ctrl.status,
                        log_process = g_log,
                        source_doc_decr = g_ctrl.source_doc_decr,
                        process_date = sysdate,
                        id_doc = g_ctrl.id_doc
                    where
                        id = reg_nf.id;

            end;

            if g_ctrl.id_doc is not null then
                refresh_status_bancada(g_ctrl.id_doc, g_ctrl.status, reg_nf.id, null);
        /*
          --Montagem do json para enviar n body
          apex_json.initialize_clob_output;
          apex_json.open_object;
          apex_json.write('id', g_ctrl.id_doc);
          apex_json.write('status', g_ctrl.status);
          apex_json.close_object;
          print(apex_json.get_clob_output);
          return_reposnse2 := RMAIS_PROCESS_PKG.Get_Response2
              (p_url     => rmais_process_pkg.get_Parameter('URL_REFRESH_STATUS_BANCADA'),--'http://144.22.253.165:9000/api/bancada/v1/status_refresh',
    	       p_content => apex_json.get_clob_output,
               p_type    => 'POST'
          );
        apex_json.free_output;
        --em caso de erros na chamada, gravar log
        print(json_value(return_reposnse2,'$.code'));
        print(json_value(return_reposnse2,'$.msg'));
        if (json_value(return_reposnse2,'$.code') not in ('200','201')) then
            insert into LOG_STATUS_BANCADA (ID_DOC_LSB,STATUS_LSB,MSG_LSB,DT_PROCESS_LSB) 
                   values(g_ctrl.id_doc,json_value(return_reposnse2,'$.code'),json_value(return_reposnse2,'$.msg'),sysdate);            
        end if;
        --incluir as chamadas.
        */
            end if;
    --
            print('');
    --
    --
            g_log := null;
    --
            g_ctrl := null;
    --
            g_status := null;--P processado  E Error   D Duplicada
    --
            g_source := null;
    --
            g_source_l := null;
    --
            g_ctrl_id := null;
    --
        end loop;
  --
        commit;
  --
        print('*** Fim do processo ***');
  --
    exception
        when others then
            raise_application_error(-20012, 'Erro faltal: ' || sqlerrm);
    end source_docs;
--
    procedure update_status_nfe (
        p_body clob
    ) as
  --
    begin
    --
        for reg_st in (
            select
                json_value(p_body, '$.chave_eletronica') chave,
                json_value(p_body, '$.cnpj_emissor')     cnpj_emissor,
                json_value(p_body, '$.status_fdc')       status_fdc
            from
                dual
        ) loop
        --
            update rmais_efd_headers_hdi
            set
                status_info = p_body,
                status_erp = reg_st.status_fdc
            where
                access_key_number = reg_st.chave;
        --
        end loop;
    --
        print('Processo OK');
    --
    exception
        when others then
    --
            raise_application_error(-20017, 'Falha ao alterar Status ' || sqlerrm);
    --
    end update_status_nfe;
--
    function get_link_nfse (
        p_id number
    ) return varchar2 as

        l_cxml    clob;
        l_cit_cod rmais_efd_headers_hdi.issuer_address_city_code%type;
        l_cod     rmais_efd_headers_hdi.cod_verif_nfs%type;
        l_num     rmais_efd_headers_hdi.document_number%type;
        l_cnpj    rmais_efd_headers_hdi.receiver_document_number%type;
        l_link    varchar2(4000);
  --
        l_andr    varchar2(600);
  --
    begin
    -- Desenvolvido somente NFse do WS da Prefeitura de São Paulo , usar parametros para desenvolver novas prefeituras
    --3505708 IBGE BARUERI
    --3550308 IBGE SP
        select
            rd.source_doc_decr,
            efdh.issuer_address_city_code,
            efdh.cod_verif_nfs,
            efdh.document_number,
            efdh.issuer_document_number,
            substr(efdh.additional_information, 1, 3000)
        into
            l_cxml,
            l_cit_cod,
            l_cod,
            l_num,
            l_cnpj,
            l_link
        from
            rmais_ctrl_docs_poc   rd,
            rmais_efd_headers_hdi efdh
        where
                rd.id = efdh.doc_id
            and efdh.model = '00'
            and efdh.efd_header_id = p_id
            and pdf_filename is null;
    --
        if l_cit_cod = '3550308' then
      --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_SP_SP', 'TEXT_VALUE');
      --
            for reg in (
                select
                    inscricaomunicipal,
                    numero_nff,
                    codigoverificacao
                from
                    xmltable ( '/NFe'
                            passing xmltype(l_cxml)
                        columns
                            numero_nff varchar2(30) path 'ChaveNFe/NumeroNFe/text()',
                            codigoverificacao varchar2(900) path 'ChaveNFe/CodigoVerificacao/text()',
                            inscricaomunicipal varchar2(150) path 'ChaveNFe/InscricaoPrestador/text()'
                    ) xnfs
            ) loop
        --
                if reg.inscricaomunicipal is not null or reg.numero_nff is not null
                                                         and reg.codigoverificacao is not null then
          --
                    return replace(
                        replace(
                            replace(l_andr, ':1', reg.inscricaomunicipal),
                            ':2',
                            reg.numero_nff
                        ),
                        ':3',
                        reg.codigoverificacao
                    );
          --
                end if;
        --
            end loop;

        elsif l_cit_cod = '3505708' then
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_SP_BARUERI', 'TEXT_VALUE');
       --
            l_cxml := replace(
                replace(
                    replace(l_cxml, '<?xml version="1.0" encoding="utf-16"?>', ''),
                    ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"',
                    ''
                ),
                ' xmlns="http://www.barueri.sp.gov.br/nfe"',
                ''
            );
       --
            for reg in (
                select
                    codigoverificacao,
                    case
                        when cnpj_dest is not null then
                            substr(cnpj_dest, 1, 2)
                            || '.'
                            || substr(cnpj_dest, 3, 3)
                            || '.'
                            || substr(cnpj_dest, 6, 3)
                            || '/'
                            || substr(cnpj_dest, 9, 4)
                            || '-'
                            || substr(cnpj_dest, 13, 2)
                        else
                            ''
                    end cnpj_dest,
                    case
                        when cpf_dest is not null then
                            substr(cpf_dest, 1, 3)
                            || '.'
                            || substr(cpf_dest, 3, 3)
                            || '.'
                            || substr(cpf_dest, 6, 3)
                            || '-'
                            || substr(cpf_dest, 9, 2)
                        else
                            ''
                    end cpf_dest
                from
                    xmltable ( '/ConsultarNfeServPrestadoResposta/ListaNfeServPrestado/CompNfeServPrestado/NfeServPrestado/InfNfeServPrestado'
                            passing xmltype(l_cxml)
                        columns
                            codigoverificacao varchar2(200) path 'CodigoVerificacao/text()',
                            cnpj_dest varchar2(200) path 'DeclaracaoServicoPrestado/InfDeclaracaoServicoPrestado/TomadorServico/IdentificacaoTomador/CpfCnpj/Cnpj/text()'
                            ,
                            cpf_dest varchar2(200) path 'DeclaracaoServicoPrestado/InfDeclaracaoServicoPrestado/TomadorServico/IdentificacaoTomador/CpfCnpj/Cpf/text()'
                    )
            ) loop
         --
                if
                    reg.codigoverificacao is not null
                    and ( reg.cnpj_dest is not null
                          or reg.cpf_dest is not null )
                then
           --
                    return replace(
                        replace(l_andr, ':1', reg.codigoverificacao),
                        ':2',
                        nvl(reg.cnpj_dest, reg.cpf_dest)
                    );
           --
                end if;
         --
            end loop;
       --
        elsif l_cit_cod = '3547809' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_SANTO_ANDRE', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
     /*elsif  l_cit_cod = '4106902' THEN 
       --
       l_andr := rmais_process_pkg.Get_Parameter('GET_LINK_NFSE_PR_CURITIBA','TEXT_VALUE');
       return utl_url.escape(replace(replace(replace(l_andr,':1',l_cod),':2', l_num),':3',l_cnpj));

        elsif  l_cit_cod = '3552502' THEN 
       --
       l_andr := rmais_process_pkg.Get_Parameter('GET_LINK_NFSE_SUZANO_SC','TEXT_VALUE');
       return utl_url.escape(replace(replace(replace(l_andr,':1',l_cod),':2', l_num),':3',l_cnpj));*/
       --
        elsif l_cit_cod = '3548708' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_SAO_BERNARDO', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3118601' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_CONTAGEM', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
          --
        elsif l_cit_cod = '4128104' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_UMUARAMA', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3516200' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_FRANCA_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3503208' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_ARARAQUARA_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3525102' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_JARDINOPOLIS_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3525904' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_JUNDIAI_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '1500800' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_ANANINDEUA_PA', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3518800' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_GUARULHOS_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3548807' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_SAO_CAETANO_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3548500' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_SANTOS_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3518701' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_GUARUJA_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3506359' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_BERTIOGA_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3543907' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_RIO_CLARO_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3513801' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_DIADEMA_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3510401' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_CAPIVARI_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3523909' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_ITU_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '2604106' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_CARUARU_PE', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3524303' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_JABOTICABAL_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3143906' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_MURIAE_MG', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3106705' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_BETIM_MG', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3519071' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_HORTOLANDIA_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3542602' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_REGISTRO_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3515103' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_EMBU_GUACU_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
        elsif l_cit_cod = '3529401' then 
       --
            l_andr := rmais_process_pkg.get_parameter('GET_LINK_NFSE_MAUA_SP', 'TEXT_VALUE');
            return utl_url.escape(replace(
                replace(
                    replace(l_andr, ':1', l_cod),
                    ':2',
                    l_num
                ),
                ':3',
                l_cnpj
            ));
       --
     /*  elsif  l_cit_cod = '4204608' THEN 
       return utl_url.escape(l_link);*/
       --
        end if;
     --
        return '';
     --
    exception
        when others then
    --
            return null;
    --
    end get_link_nfse;
  --
    procedure reprocess_doc (
        p_efd_header_id in number
    ) as
        l_id            number;
        l_efd_header_id number := p_efd_header_id;
    begin
    --
        select
            doc_id
        into l_id
        from
            rmais_efd_headers_hdi
        where
            efd_header_id = l_efd_header_id;
    --
        delete rmais_efd_lines_hdi
        where
            efd_header_id = l_efd_header_id;
    --
        delete rmais_efd_headers_hdi
        where
            efd_header_id = l_efd_header_id;
    --
        update rmais_ctrl_docs_poc
        set
            status = 'N'
        where
            id = l_id;
    --
        print('Documento Reprocessado Efd_header_id: ' || l_efd_header_id);
    -- 
    exception
        when others then
    --
            print('Error: ' || sqlerrm);
    --
    end;
  --
    function get_destination (
        p_header_id number
    ) return varchar2 as
        l_return rmais_efd_lines_hdi.destination_type%type;
    begin
      --
        select distinct
            destination_type
        into l_return
        from
            rmais_efd_lines_hdi
        where
            efd_header_id = p_header_id;
      --
        return l_return;
      --
    exception
        when others then
      --
      --raise_application_error(-20004,'Não foi possível definir detino de item');
      --
            return '';
      --
    end get_destination;
  --
    function get_period_entry return varchar2 as
        l_ret varchar2(1);
    begin
    --
        select distinct
            'Y'
        into l_ret
        from
            rmais_period_entry e
        where
            trunc(sysdate) between trunc(date_ini) and trunc(date_fim);
    --
        return l_ret;
    exception
        when others then
    --
            return 'N';
    --
    end get_period_entry;
  --
    function valid_org_func (
        p_cnpj varchar2
    ) return boolean as
        l_aux number;
    begin
    --
        select
            1
        into l_aux
        from
            rmais_suppliers         rmc,
            rmais_organizations_hdi rmcc
        where
                rmc.id = rmcc.cliente_id
            and rmcc.cnpj = p_cnpj;
    --
        print('****IDENTIFICAÇÂO DE DOCUMENTO ****');
        print('CLIENTE: CNPJ Encontrado CNPJ: ' || p_cnpj);
        print('');
        return true;
    --
    exception
        when others then
    --
            print('****IDENTIFICAÇÂO DE DOCUMENTO ****');
            print('ERROR: CNPJ Tomador Não Encontrado CNPJ: '
                  || p_cnpj || '!!!!'); --
            return false;
    --
    end valid_org_func;
  --
    function valid_source_model (
        p33_xml     apex_application_temp_files.name%type,
        p_parameter varchar2,
        p_mime_type varchar2 default null
    ) return varchar2 as 
    --MIME_TYPE
        l_blob       blob;
        l_clob       clob;
        l_mime_type  apex_application_temp_files.mime_type%type;
        l_efd_header number;
        l_cnpj_toma  varchar2(15);
        l_ret        varchar2(1);
    begin 
  --  apex_debug.message('P33_XML: %s', :P34_ANEXO);

        select
            blob_content,
            mime_type
        into
            l_blob,
            l_mime_type
        from
            apex_application_temp_files
        where
            name = p33_xml;

        l_clob := xxrmais_util_pkg.blob_to_clob(l_blob);
      --apex_debug.message('XML: %s',l_clob);
      --apex_debug.message('blob length: %s', dbms_lob.getlength(l_blob));
     --
        if p_parameter = 'MIME_TYPE' then
            if
                l_mime_type = 'application/xml'
                and ( ( lower(p_mime_type) = 'xml' )
                or lower(p_mime_type) = 'application/xml' )
            then
                return 'Y';
            elsif
                l_mime_type = 'application/pdf'
                and ( ( lower(p_mime_type) = 'pdf' )
                or lower(p_mime_type) = 'application/pdf' )
            then
                return 'Y';
            else
                return 'N';
            end if;
        end if;
     -- 
        if p_parameter in ( 'LAYOUT', 'CNPJ', 'DUPLICIDADE', 'CHAVE' ) then
       --
            if
                ( regexp_like(l_clob, 'nfeProc')
                or ( regexp_like(l_clob, 'http://www.portalfiscal.inf.br/nfe') ) )
                and l_clob not like '%<resNFe%'
            then
        --
                if p_parameter = 'LAYOUT' then
                    return 'Y';
                end if;
        --
                if l_mime_type = 'application/xml' then
          --
                    l_clob := replace(l_clob, '¿<?xml version="1.0" encoding="UTF-8"?>', '');
           --
                    l_clob := replace(l_clob, '¿<?xml version="1.0" encoding="UTF-8" ?><nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
                    , '<nfeProc versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe">');
           --
                    l_clob := replace(l_clob, '<?xml version="1.0" encoding="UTF-8" ?><nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
                    , '<nfeProc versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe">');
           --
                    l_clob := replace(l_clob, '<protNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">', '<protNFe versao="4.00">)'
                    );
           --
           --
                    l_clob := replace(l_clob, '¿<', '<');
           --=
                    if p_parameter in ( 'CNPJ', 'DUPLICIDADE', 'CHAVE' ) then
             -- PRINT(l_clob);
                        for rnfe in (
                            select
                                danfe,
                                serie,
                                num_nf                   numero,
                                nvl(cnpj_toma, cpf_toma) cnpj_cpf
                            from
                                xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/nfe' ),
                                '/nfeProc'
                                        passing xmltype(l_clob)
                                    columns
                                        danfe varchar2(200) path '/nfeProc/protNFe/infProt/chNFe/text()',
                                        serie varchar2(150) path '/nfeProc/NFe/infNFe/ide/serie/text()',
                                        num_nf varchar2(150) path '/nfeProc/NFe/infNFe/ide/nNF/text()',
                                        cnpj_toma varchar2(200) path '/nfeProc/NFe/infNFe/dest/CNPJ/text()',
                                        cpf_toma varchar2(200) path '/nfeProc/NFe/infNFe/dest/CNPJ/text()'
                                )
                        ) loop
              --
                            if p_parameter = 'CNPJ' then
               --
                                return
                                    case
                                        when valid_org_func(rnfe.cnpj_cpf) then
                                            'Y'
                                        else
                                            'N'
                                    end;
               /*declare
               l_aux2 number;
               begin
                   SELECT distinct 1 
                     INTO l_aux2
                     FROM rmais_suppliers rmc
                         ,RMAIS_ORGANIZATIONS_HDI rmcc
                     WHERE rmc.id = rmcc.cliente_id
                     AND rmcc.cnpj = rNfe.cnpj_cpf;
                 return true;
               exception when others then
               return false;
               end;*/
              --
                            elsif p_parameter = 'DUPLICIDADE' then
                 --
                                declare
                                    l_aux2 number;
                                begin
                                    select distinct
                                        1
                                    into l_aux2
                                    from
                                        rmais_efd_headers_hdi
                                    where
                                        access_key_number = rnfe.danfe;

                                    return 'N';
                                exception
                                    when others then
                                        return 'Y';
                                end;
                            elsif p_parameter = 'CHAVE' then
                                return rnfe.danfe;
                            end if;

                            null;
                        end loop;

                        return 'N';
                    end if;

                end if;

            elsif ( regexp_like(l_clob, 'cteOSProc') ) then
        --
                if p_parameter = 'LAYOUT' then
                    return 'Y';
                end if;
        --
                for rcte in (
                    select
                        r.nct,
                        nvl(r.toma_cnpj, r.toma_cpf) toma_cnpj,
                        chave
                    from
                        ( xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/cte' ),
                        '/cteOSProc'
                                passing xmltype(l_clob)
                            columns
                                nct varchar2(150) path 'CTeOS/infCte/ide/nCT/text()',
                                toma_cnpj varchar2(200) path 'CTeOS/infCte/toma/CNPJ/text()',
                                toma_cpf varchar2(200) path 'CTeOS/infCte/toma/CPF/text()',
                                toma_ie varchar2(200) path 'CTeOS/infCte/toma/IE/text()',
                                chave varchar2(150) path 'protCTe/infProt/chCTe/text()'
                        ) ) r
                ) loop
             --
                    if p_parameter = 'CNPJ' then
                        return
                            case
                                when valid_org_func(rcte.toma_cnpj) then
                                    'Y'
                                else
                                    'N'
                            end;
                    elsif p_parameter = 'DUPLICIDADE' then
                        declare
                            l_aux2 number;
                        begin
                            select distinct
                                1
                            into l_aux2
                            from
                                rmais_efd_headers_hdi
                            where
                                access_key_number = rcte.chave;

                            return 'N';
                        exception
                            when others then
                                return 'Y';
                        end;
                    elsif p_parameter = 'CHAVE' then
                        return rcte.chave;
                    end if;
                end loop;  
        --
            elsif regexp_like(l_clob, 'cteProc') then
        --
                if p_parameter = 'LAYOUT' then
                    return 'Y';
                end if;
        --
                if p_parameter in ( 'CNPJ', 'DUPLICIDADE', 'CHAVE' ) then
          --
                    declare
                        l_cnpj_toma varchar2(15);
                        l_chave     varchar2(44) := null;
                    begin
                        for cte in (
                            select
                                nvl(toma3, toma4)          toma,
                                chave,
                                nvl(rem_cnpj, rem_cpf)     rem_cnpj,
                                nvl(exped_cnpj, exped_cpf) exped_cnpj,
                                nvl(receb_cnpj, receb_cpf) receb_cnpj,
                                nvl(toma4_cnpj, toma4_cpf) toma4_cnpj,
                                nvl(dest_cnpj, dest_cpf)   dest_cnpj
                            from
                                ( xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/cte' ),
                                '/cteProc'
                                        passing xmltype(l_clob)
                                    columns
                                                      -- cUF          VARCHAR2(150)    Path 'infCte/ide/cUF/text()',
                                                      -- natOp        VARCHAR2(150)    Path 'infCte/ide/toma3/toma/text()'
                                        toma3 varchar2(150) path 'CTe/infCte/ide/toma3/toma/text()',
                                        toma4 varchar2(150) path 'CTe/infCte/ide/toma4/toma/text()',
                                        rem_cnpj varchar2(150) path 'CTe/infCte/rem/CNPJ/text()',
                                        rem_cpf varchar2(150) path 'CTe/infCte/rem/CPF/text()',
                                        dest_cnpj varchar2(150) path 'CTe/infCte/dest/CNPJ/text()',
                                        dest_cpf varchar2(150) path 'CTe/infCte/dest/CPF/text()',
                                        emit_cnpj varchar2(150) path 'CTe/infCte/emit/CNPJ/text()',
                                        emit_cpf varchar2(150) path 'CTe/infCte/emit/CPF/text()',
                                        exped_cnpj varchar2(150) path 'CTe/infCte/exped/CNPJ/text()',
                                        exped_cpf varchar2(150) path 'CTe/infCte/exped/CPF/text()',
                                        receb_cnpj varchar2(150) path 'CTe/infCte/receb/CNPJ/text()',
                                        receb_cpf varchar2(150) path 'CTe/infCte/receb/CPF/text()',
                                        toma4_cnpj varchar2(150) path 'CTe/infCte/ide/toma4/CNPJ/text()',
                                        toma4_cpf varchar2(150) path 'CTe/infCte/ide/toma4/CPF/text()',
                                                      --emit
                                        chave varchar2(150) path 'protCTe/infProt/chCTe/text()'
                                                      --
                                ) ) cte
                        ) loop
               --
                            l_cnpj_toma :=
                                case cte.toma
                                    when '0' then
                                        cte.rem_cnpj
                                    when '1' then
                                        cte.exped_cnpj
                                    when '2' then
                                        cte.receb_cnpj
                                    else
                                        case
                                            when cte.toma = '4' then
                                                    cte.toma4_cnpj
                                            else
                                                cte.dest_cnpj
                                        end
                                end;
               --l_cnpj_toma := CASE WHEN 1=1 THEN '00' ELSE '11' END---;
                            l_chave := cte.chave;
               --
                        end loop;

                        if p_parameter = 'CNPJ' then
                            return
                                case
                                    when valid_org_func(l_cnpj_toma) then
                                        'Y'
                                    else
                                        'N'
                                end;
                        elsif p_parameter = 'DUPLICIDADE' then
                            declare
                                l_aux2 number;
                            begin
                                select distinct
                                    1
                                into l_aux2
                                from
                                    rmais_efd_headers_hdi
                                where
                                    access_key_number = l_chave;

                                return 'N';
                            exception
                                when others then
                                    return 'Y';
                            end;
                        elsif p_parameter = 'CHAVE' then
                            return l_chave;
                        end if;

                    end;

                end if;

            else
                return 'N';
            end if;

            return 'N';
        end if;

        return 'N';
    exception
        when others then
            apex_debug.message('ERROR SQL: %s', sqlerrm);
            return 'N';
    end valid_source_model;
  --
    function parse_xml_sefaz (
        p_id number
    ) return clob as
    --
        l_ret     clob;
        l_nls     varchar2(15);
        l_nls_dot varchar2(10);
    --
    begin
      --
        select
            value
        into l_nls
        from
            v$nls_parameters
        where
            parameter = 'NLS_DATE_FORMAT';
    --
        execute immediate 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD-MON-RR''';
    --
        select
            replace(xmlelement(
                "nfeProc",
                    xmlattributes(
                    'http://www.portalfiscal.inf.br/nfe' as "xmlns",
                    '4.00' as "versao"
                ),
                    xmlelement(
                    "NFe",
                    xmlattributes('http://www.portalfiscal.inf.br/nfe' as "xmlns"),
                    xmlelement(
                        "infNFe",
                    xmlattributes(
                            '4.00' as "versao",
                    'NFe' || h.access_key_number as "Id"
                        ),
                    xmlelement(
                            "ide",
                    xmlelement(
                                "cUF",
                    '35'
                            ),
                    xmlelement(
                                "cNF",
                    '777'
                            ),
                    xmlelement(
                                "natOp",
                    'SERVIÇO'
                            ),
                    xmlelement(
                                "mod",
                    '55'
                            ),
                    xmlelement(
                                "serie",
                    '1'
                            ),
                    xmlelement(
                                "nNF",
                                h.document_number
                            ),
                              --XMLELEMENT("dhEmi" , h.issue_date),
                    xmlelement(
                                "dhEmi",
                    to_char(h.issue_date, 'YYYY-MM-DD"T"HH24:MI:SS"-03:00"')
                            ),
                    xmlelement(
                                "tpNF",
                    '1'
                            ),
                    xmlelement(
                                "idDest",
                    '1'
                            ),
                    xmlelement(
                                "cMunFG",
                    get_ibge_code(h.issuer_address_city_name, h.issuer_address_state)
                            ), --sao bernardo '3554102'), --utilizando de São paulo
                    xmlelement(
                                "tpImp",
                    '1'
                            ),
                    xmlelement(
                                "tpEmis",
                    '2'
                            ),
                    xmlelement(
                                "cDV",
                    '1'
                            ),
                    xmlelement(
                                "tpAmb",
                    '1'
                            ),
                    xmlelement(
                                "finNFe",
                    '1'
                            ),
                    xmlelement(
                                "indFinal",
                    '0'
                            ),
                    xmlelement(
                                "indPres",
                    '9'
                            ),
                    xmlelement(
                                "procEmi",
                    '0'
                            ),
                    xmlelement(
                                "verProc",
                    '4,0'
                            )
                        ),--ide
                    xmlelement(
                            "emit",
                    xmlelement(
                                cnpj,
                    upper(h.issuer_document_number)
                            ),
                    xmlelement(
                                "xNome",
                    upper(h.issuer_name)
                            ),
                    xmlelement(
                                "xFant",
                    upper(h.issuer_name)
                            ),
                    xmlelement(
                                "enderEmit",
                    xmlelement(
                                    "xLgr",
                    upper(h.issuer_address)
                                ),
                    xmlelement(
                                    "nro",
                                    h.issuer_address_number
                                ),
                    xmlelement(
                                    "xBairro",
                    upper(h.issuer_address_city_code)
                                ),
                                 -- XMLELEMENT("cMun" , '3548708'), --São Bernardo
                    xmlelement(
                                    "cMun",
                    get_ibge_code(h.issuer_address_city_name, h.issuer_address_state)
                                ),
                    xmlelement(
                                    "xMun",
                    upper(h.issuer_address_city_name)
                                ),
                    xmlelement(
                                    uf,
                    upper(h.issuer_address_state)
                                ),
                                  --XMLELEMENT("CEP" , h.issuer_address_zip_code ),
                    xmlelement(
                                    cep,
                    lpad(
                                        to_char(h.issuer_address_zip_code),
                                        8,
                                        '0'
                                    )
                                ),
                    xmlelement(
                                    "xPais",
                    'Brasil'
                                ),
                    xmlelement(
                                    "fone",
                    '999999999'
                                )
                            ),--enderEmit
                    xmlelement(
                                ie,
                    '688487041111'
                            ),
                    xmlelement(
                                crt,
                    3
                            )--simples nacional ou nãp       
                        ),--emit
                    xmlelement(
                            "dest",
                    xmlelement(
                                cnpj,
                                h.receiver_document_number
                            ),
                    xmlelement(
                                "xNome",
                    upper(h.receiver_name)
                            ),
                    xmlelement(
                                "enderDest",
                    xmlelement(
                                    "xLgr",
                    upper(h.receiver_address)
                                ),
                    xmlelement(
                                    "nro",
                                    h.receiver_address_number
                                ),
                    xmlelement(
                                    "xBairro",
                    upper(h.receiver_address_city_code)
                                ),
                                    --XMLELEMENT("cMun" , '3509502'),--campinas
                    xmlelement(
                                    "cMun",
                    get_ibge_code(h.receiver_address_city_name, h.receiver_address_state)
                                ),
                    xmlelement(
                                    "xMun",
                    upper(h.receiver_address_city_name)
                                ),
                    xmlelement(
                                    uf,
                    upper(h.receiver_address_state)
                                ),
                    xmlelement(
                                    cep,
                                    h.receiver_address_zip_code
                                ),
                    xmlelement(
                                    "cPais",
                    '1058'
                                ),
                    xmlelement(
                                    "xPais",
                    'Brasil'
                                ),
                    xmlelement(
                                    "fone",
                    '3130559706'
                                )
                            ),--enderDest  xLgr
                    xmlelement(
                                "indIEDest",
                    1
                            ),
                    xmlelement(
                                ie,
                    '206265026118'
                            )
                        ),--dest
                    xmlelement(
                            "entrega",
                    xmlelement(
                                cnpj,
                                h.receiver_document_number
                            ),
                    xmlelement(
                                "xLgr",
                                h.receiver_address
                            ),
                    xmlelement(
                                "nro",
                                h.receiver_address_number
                            ),
                    xmlelement(
                                "xBairro",
                                h.receiver_address_city_code
                            ),
                                --XMLELEMENT("cMun" , '3509502'),--campinas
                    xmlelement(
                                "cMun",
                    get_ibge_code(h.receiver_address_city_name, h.receiver_address_state)
                            ),
                    xmlelement(
                                "xMun",
                                h.receiver_address_city_name
                            ),
                    xmlelement(
                                uf,
                                h.receiver_address_state
                            )
                        ), --entrega
                    xmlelement(
                            "det",
                    xmlattributes(l.line_number as "nItem"),
                    xmlelement(
                                "prod",
                    xmlelement(
                                    "cProd",
                    nvl(l.item_code_efd, l.item_code)
                                ),
                    xmlelement(
                                    "cEAN",
                    'SEM GTIN'
                                ),
                    xmlelement(
                                    "xProd",
                                    l.item_description
                                ),
                    xmlelement(
                                    ncm,
                    '00000000'
                                ),
                    xmlelement(
                                    cest,
                    null
                                ),
                    xmlelement(
                                    cfop,
                    '5933'
                                ),
                    xmlelement(
                                    "uCom",
                    nvl(l.uom_to, 'UN')
                                ),
                    xmlelement(
                                    "qCom",
                    replace(
                                        to_char(l.line_quantity, '9999999999999999999999999999999D0000'),
                                        ' ',
                                        ''
                                    )
                                ),
                    xmlelement(
                                    "vUnCom",
                                    l.unit_price
                                ),
                    xmlelement(
                                    "vProd",
                                    l.line_amount
                                ),
                    xmlelement(
                                    "cEANTrib",
                    'SEM GTIN'
                                ),
                    xmlelement(
                                    "uTrib",
                    nvl(l.uom_to, 'UN')
                                ),
                    xmlelement(
                                    "qTrib",
                    replace(
                                        to_char(l.line_quantity, '9999999999999999999999999999999D0000'),
                                        ' ',
                                        ''
                                    )
                                ),
                    xmlelement(
                                    "vUnTrib",
                    replace(
                                        to_char(l.unit_price, '9999999999999999999999999999999D0000000000'),
                                        ' ',
                                        ''
                                    )
                                ), --l.unit_price ),
                    xmlelement(
                                    "indTot",
                    1
                                ),
                    xmlelement(
                                    "xPed",
                    nvl(l.source_doc_number, 'X')
                                ),
                    xmlelement(
                                    "nItemPed",
                    nvl(l.source_doc_line_num, '0')
                                )
                            ), --prod   
                    xmlelement(
                                "imposto",
                    xmlelement(
                                    icms,
                    xmlelement(
                                        icms40,
                    xmlelement(
                                            "orig",
                    '0'
                                        ),
                    xmlelement(
                                            cst,
                    '40'
                                        )
                                        /*,
                                        XMLELEMENT("modBC", '3'), 
                                        XMLELEMENT("pRedBC", '0'), 
                                        XMLELEMENT("vBC", 0),
                                        XMLELEMENT("pICMS", 0 ),
                                        XMLELEMENT("vICMS" , 0 )*/
                                    )--icms20
                                ),--ICMS 
                    xmlelement(
                                    ipi,
                    xmlelement(
                                        "cEnq",
                    '999'
                                    ),
                    xmlelement(
                                        "IPITrib",
                    xmlelement(
                                            cst,
                    '50'
                                        ),
                    xmlelement(
                                            "vBC",
                                            l.line_amount
                                        ),
                    xmlelement(
                                            "pIPI",
                    '0.0000'
                                        ),
                    xmlelement(
                                            "vIPI",
                    '0.00'
                                        )
                                    )--IPITrib
                                          --CST
                                ), --IPI
                    xmlelement(
                                    pis,
                    xmlelement(
                                        pisnt,
                    xmlelement(
                                            cst,
                    '6'
                                        )
                                    )--PISNT
                                ),--PIS  
                    xmlelement(
                                    cofins,
                    xmlelement(
                                        cofinsnt,
                    xmlelement(
                                            cst,
                    '6'
                                        )
                                    )--COFINSNT
                                )--cofins
                            ),--imposto
                    xmlelement(
                                "infAdProd",
                    l.item_code_efd
                    || '  -  '
                    || l.item_description
                            )
                        ), --det 
                    xmlelement(
                            "total",
                    xmlelement(
                                "ICMSTot",
                    xmlelement(
                                    "vBC",
                                    h.total_amount
                                ),
                    xmlelement(
                                    "vICMS",
                    '0.00'
                                ),
                    xmlelement(
                                    "vICMSDeson",
                    '0.00'
                                ),
                    xmlelement(
                                    "vFCP",
                    '0.00'
                                ),
                    xmlelement(
                                    "vBCST",
                    '0.00'
                                ),
                    xmlelement(
                                    "vST",
                    '0.00'
                                ),
                    xmlelement(
                                    "vFCPST",
                    '0.00'
                                ),
                    xmlelement(
                                    "vFCPSTRet",
                    '0.00'
                                ),
                    xmlelement(
                                    "vProd",
                                    h.total_amount
                                ),
                    xmlelement(
                                    "vFrete",
                    '0.00'
                                ),
                    xmlelement(
                                    "vSeg",
                    '0.00'
                                ),
                    xmlelement(
                                    "vDesc",
                    '0.00'
                                ),
                    xmlelement(
                                    "vII",
                    '0.00'
                                ),
                    xmlelement(
                                    "vIPI",
                    '0.00'
                                ),
                    xmlelement(
                                    "vIPIDevol",
                    '0.00'
                                ),
                    xmlelement(
                                    "vPIS",
                    '0.00'
                                ),
                    xmlelement(
                                    "vCOFINS",
                    '0.00'
                                ),
                    xmlelement(
                                    "vOutro",
                    '0.00'
                                ),
                    xmlelement(
                                    "vNF",
                                    h.total_amount
                                )
                            )--ICMStot,
                        ),--total ICMSTot
                    xmlelement(
                            "transp",
                    xmlelement(
                                "modFrete",
                    3
                            ),
                    xmlelement(
                                "vol",
                    xmlelement(
                                    "qVol",
                    1
                                ),
                    xmlelement(
                                    "esp",
                    'SERVICE'
                                ),
                    xmlelement(
                                    "marca",
                    'FDC'
                                ),
                    xmlelement(
                                    "pesoL",
                    '1.000'
                                ),
                    xmlelement(
                                    "pesoB",
                    '1.000'
                                )
                            ) --vol 
                        ), --transp
                    xmlelement(
                            "cobr",
                    xmlelement(
                                "fat",
                    xmlelement(
                                    "nFat",
                    '00022'
                                ),
                    xmlelement(
                                    "vOrig",
                                    h.total_amount
                                ),
                    xmlelement(
                                    "vDesc",
                    0
                                ),
                    xmlelement(
                                    "vLiq",
                                    h.total_amount
                                )
                            ), --fat
                    xmlelement(
                                "dup",
                    xmlelement(
                                    "nDup",
                    '001'
                                ),
                    xmlelement(
                                    "dVenc",
                    to_date(h.issue_date, 'YYYY-MM-DD')
                                ),
                    xmlelement(
                                    "h.issue_date",
                                    h.total_amount
                                )
                            )
                        ), --cobr
                    xmlelement(
                            "pag",
                    xmlelement(
                                "detPag",
                                         -- XMLELEMENT("indPag", 0 ),
                    xmlelement(
                                    "tPag",
                    99
                                ),
                                         -- XMLELEMENT("xPag", 'CARTEIRA DIGITAL' ),
                    xmlelement(
                                    "vPag",
                                    h.total_amount
                                )
                            )--detPag
                        ),--pag
                    xmlelement(
                            "infAdic",
                    xmlelement(
                                "infCpl",
                    'Nota fiscal de Serviço para entrada no Módulo FDC'
                            )
                        )--infAdic
                    ),--infNef
                    xmlelement(
                        "Signature",
                    xmlattributes('http://www.w3.org/2000/09/xmldsig#' as "xmlns"),
                    xmlelement(
                            "SignedInfo",
                    xmlelement(
                                "CanonicalizationMethod",
                    xmlattributes(
                                    'http://www.w3.org/TR/2001/REC-xml-c14n-20010315' as "Algorithm"
                                )
                            ),
                    xmlelement(
                                "SignatureMethod",
                    xmlattributes(
                                    'http://www.w3.org/2000/09/xmldsig#rsa-sha1' as "Algorithm"
                                )
                            ),
                    xmlelement(
                                "Reference",
                    xmlattributes('#Nfe' || h.access_key_number as uri),
                    xmlelement(
                                    "Transforms",
                    xmlelement(
                                        "Transform",
                    xmlattributes(
                                            'http://www.w3.org/2000/09/xmldsig#enveloped-signature' as "Algorithm"
                                        )
                                    ),
                    xmlelement(
                                        "Transform",
                    xmlattributes(
                                            'http://www.w3.org/TR/2001/REC-xml-c14n-20010315' as "Algorithm"
                                        )
                                    )
                                ),--Transforms
                    xmlelement(
                                    "DigestMethod",
                    xmlattributes(
                                        'http://www.w3.org/2000/09/xmldsig#sha1' as "Algorithm"
                                    )
                                ),--DigestMethod,
                    xmlelement(
                                    "DigestValue",
                    'o379oh9AhoQk6OwVCced/9qKxfg='
                                )
                            )--Reference
                        ),--SignedInfo  
                    xmlelement(
                            "SignatureValue",
                    'lSknQc30m8P3G6Qnj7DTW0Si27KK20Ypeo7HEz0iguGbkVQwVdcNDTjQbMXmobJ8qHjxlFFJU8IiLzciMdIUXmV7yykE3u8El+Q1jWF+Dj6r7nen7+7SfBeWuyGkvGgDORpWaWpOFHDTj6VoyY81gI2kyXiLAhBttzS3jGjTUzTAzMUtN4/sLGIa9WxdoGSxQyWCuorUJqPzK+tM9Sj/wd/eW/4pUqPagN+QS28nbnkTYUWIKpVTMfCfLOInc+XFAID9/zFP3iSjqUyNT2IewaaLlIwMlAjS/ZfXEhjG2RdVpP3iOra3PcckDF4UFuPzyy/8U+VJA/3vAev6eGAocQ=='
                        ),--SignatureValue
                    xmlelement(
                            "KeyInfo",
                    xmlelement(
                                "X509Data",
                    xmlelement(
                                    "X509Certificate",
                    'MIIIAzCCBeugAwIBAgIQINJ02gXzygU2cfSCXXrW7jANBgkqhkiG9w0BAQsFADB4MQswCQYDVQQGEwJCUjETMBEGA1UEChMKSUNQLUJyYXNpbDE2MDQGA1UECxMtU2VjcmV0YXJpYSBkYSBSZWNlaXRhIEZlZGVyYWwgZG8gQnJhc2lsIC0gUkZCMRwwGgYDVQQDExNBQyBDZXJ0aXNpZ24gUkZCIEc1MB4XDTIwMDgwNzE4NDE1MFoXDTIxMDgwNzE4NDE1MFowgfAxCzAJBgNVBAYTAkJSMRMwEQYDVQQKDApJQ1AtQnJhc2lsMQswCQYDVQQIDAJTUDEcMBoGA1UEBwwTU2FvIEpvc2UgZG9zIENhbXBvczE2MDQGA1UECwwtU2VjcmV0YXJpYSBkYSBSZWNlaXRhIEZlZGVyYWwgZG8gQnJhc2lsIC0gUkZCMRYwFAYDVQQLDA1SRkIgZS1DTlBKIEExMRcwFQYDVQQLDA4wMDY3OTE2MzAwMDE0MjE4MDYGA1UEAwwvWUFCT1JBIElORFVTVFJJQSBBRVJPTkFVVElDQSBTIEE6MzA2NTcyNTAwMDAxNjAwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC4Xe6HRIRfOmChQck8kBAri02AVNjWvcsmq4OjpI+kSz5c/NT+NceDAwd4ySSSJJRtHydGevZA94tbWGCqCOe0nE0Eql00wLg5haxV1vEAB0RD1KUHtAoGigK+03dVrpGCKZMqNgrFkDM6xkomeEa31UVpa0MLpKHg0HmnA9IEys1vXP0sWSKcqgyCZasAinZl+vfrnbAJqrkGBl3qNeuphV7Yx/WTuPdYNJGzesQcwm+IfGaLMxkqGRriLMN9iH8BsMOnHcNG0UvAwzcaf7zhUesGlYELD5E04J/h6mxrq1/mufMK0pEF+yq6nuLj6oN/KO8vlvigrtgZOsYDPqp7AgMBAAGjggMOMIIDCjCBvQYDVR0RBIG1MIGyoD0GBWBMAQMEoDQEMjI3MDUxOTY1MDY0Njg5NTU4MzEwMDAwMDAwMDAwMDAwMDAwMDExOTY2MDUwN1NTUFNQoCAGBWBMAQMCoBcEFUFOVE9OSU8gQ0FSTE9TIEdBUkNJQaAZBgVgTAEDA6AQBA4zMDY1NzI1MDAwMDE2MKAXBgVgTAEDB6AOBAwwMDAwMDAwMDAwMDCBG2RhbmllbC5zYXJhbkBlbWJyYWVyLm5ldC5icjAJBgNVHRMEAjAAMB8GA1UdIwQYMBaAFFN9f52+0WHQILran+OJpxNzWM1CMH8GA1UdIAR4MHYwdAYGYEwBAgEMMGowaAYIKwYBBQUHAgEWXGh0dHA6Ly9pY3AtYnJhc2lsLmNlcnRpc2lnbi5jb20uYnIvcmVwb3NpdG9yaW8vZHBjL0FDX0NlcnRpc2lnbl9SRkIvRFBDX0FDX0NlcnRpc2lnbl9SRkIucGRmMIG8BgNVHR8EgbQwgbEwV6BVoFOGUWh0dHA6Ly9pY3AtYnJhc2lsLmNlcnRpc2lnbi5jb20uYnIvcmVwb3NpdG9yaW8vbGNyL0FDQ2VydGlzaWduUkZCRzUvTGF0ZXN0Q1JMLmNybDBWoFSgUoZQaHR0cDovL2ljcC1icmFzaWwub3V0cmFsY3IuY29tLmJyL3JlcG9zaXRvcmlvL2xjci9BQ0NlcnRpc2lnblJGQkc1L0xhdGVzdENSTC5jcmwwDgYDVR0PAQH/BAQDAgXgMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcDBDCBrAYIKwYBBQUHAQEEgZ8wgZwwXwYIKwYBBQUHMAKGU2h0dHA6Ly9pY3AtYnJhc2lsLmNlcnRpc2lnbi5jb20uYnIvcmVwb3NpdG9yaW8vY2VydGlmaWNhZG9zL0FDX0NlcnRpc2lnbl9SRkJfRzUucDdjMDkGCCsGAQUFBzABhi1odHRwOi8vb2NzcC1hYy1jZXJ0aXNpZ24tcmZiLmNlcnRpc2lnbi5jb20uYnIwDQYJKoZIhvcNAQELBQADggIBAKKUW0ZZLvyuAZEOsCE7NZRflEIzKtdfMrZxJPee+ZrclPlPT3i8PH/r8kbsu0WAy7vfcqahp6IL+u7LCuzIavxdUqJaA81yaRBFitmp+4Et3nhVKbxIn6Ke3NLOsdeLl/QuPWqk17Y/P4nDnoIBKQkTKNLBCza5x3RYKkxi5x1ZaDAe4Lp8xpj2pk0Yfvx4/jONb54vvr1ityzgWB2iC2XZyY/KWksWWRLjTEDO8iEohI7eLpkGriuad+QsDFlnl0aWOj5oVSpBGKw6hDZ5SIGLP5Z2SUZxzX2ztU/dt8/4SXKm/6d2u0NvRm7kLqGO4agofeOYRJH6B20FLGqAJ4u2fLOkdwfvMOPS+DMWSEX42h07deD3KnIAUK8Ki9vAneUbMY0addXHtVlyIabMycBDaBT7YGO+0YiZ0G15QCziJAW0gbQLivgijOgq4LSEJYvxkYkSkoOqoEkktv2VFOFLyRDcVL/RIqPuyrrNWL4LKD+falAyqPRqxZVNyhiXselnW3MgV9F+kRJasZj8w2svyxzhHFCYn73qyp1Lk9ouWSapw8q94W9/3Hxqc5+vczhvstcxuwU9FKyMWOm2hwyKbAXFcUsEOk29aaw9D8IcejVZlZwNcZjiGRHiqCuHMhbPU490JxDW2ohglfeLNLBAzcG0qHEljKRShIEgRV48'
                                )
                            )--X509Data
                        )--KeyInfo
                    )--Signature
                ),--Nfe
                    xmlelement(
                    "protNFe",
                    xmlattributes(
                        '4.00' as "versao"
                    ),
                    xmlelement(
                    "infProt",
                    xmlattributes('Id135210665687939' as "Id"),
                    xmlelement(
                            "tpAmb",
                    1
                        ),
                    xmlelement(
                            "verAplic",
                    'SP_NFE_PL009_V4'
                        ),
                    xmlelement(
                            "chNFe",
                            h.access_key_number
                        ),
                    xmlelement(
                            "dhRecbto",
                    to_char(h.issue_date, 'YYYY-MM-DD"T"HH24:MI:SS"-03:00"')
                        ),
                    xmlelement(
                            "nProt",
                    135210665687939
                        ),
                    xmlelement(
                            "digVal",
                    'o379oh9AhoQk6OwVCced/9qKxfg='
                        ),
                    xmlelement(
                            "cStat",
                    100
                        ),
                    xmlelement(
                            "xMotivo",
                    'Autorizado o uso da NF-e'
                        )
                    )--protNFe 
                )
            ).getclobval(),
                    '<NFe>',
                    '<NFe xmlns="http://www.portalfiscal.inf.br/nfe">') xml
        into l_ret
        from
            rmais_efd_headers_hdi h,
            rmais_efd_lines_hdi   l
        where
                h.efd_header_id = p_id
            and h.efd_header_id = l.efd_header_id;
      --
        execute immediate 'ALTER SESSION SET NLS_DATE_FORMAT = '''
                          || l_nls
                          || '''';
      --
        return l_ret;
    --
    exception
        when others then
      --
            raise_application_error(-20254, 'Não foi possível gerar XML para integração: ' || sqlerrm);
      --
    end parse_xml_sefaz;
  --
    function get_ibge_code (
        p_citie varchar2,
        p_state varchar2
    ) return varchar2 as
        l_return varchar2(100);
    begin
        select
            cod_muni
        into l_return
        from
            rmais_cities_ibge
        where
                replace(
                    translate(
                        upper(municipio),
                        'ÃÂÁÉÍÓÔÕÚ',
                        'AAAEIOOOU'
                    ),
                    ' ',
                    ''
                ) = replace(
                    translate(
                        upper(p_citie),
                        'ÃÂÁÉÍÓÔÕÚ',
                        'AAAEIOOOU'
                    ),
                    ' ',
                    ''
                )
            and estado = p_state;

        return l_return;
    exception
        when others then
            raise_application_error(-20099, 'Não foi possível buscar ibge da cidade');
    end get_ibge_code;
  --
    procedure ws_process_return (
        p_body   in clob,
        p_status in out varchar,
        p_method in varchar2
    ) as
     --l_body CLOB := p_body;
    begin
       --
       --if l_body is null then
       --   p_status := 500;
       --   raise_application_error('20011','Não foi possível ser feita a integração: '||SQLERRM);
       -- ELSE
          --
        insert into rmais_ws_nf_info_ap (
            id,
            body_ws,
            creation_date,
            status
        ) values ( rmais_ws_nf_info_ap_seq.nextval,
                   p_body,
                   sysdate,
                   'N' );
          --
        --end if;  
      --
    exception
        when others then
            p_status := 400;
    end ws_process_return;
   --
    procedure create_event (
        p_efd_header_id number,
        p_event         varchar2,
        p_msg           varchar2,
        p_user          varchar2 default '-1'
    ) as
        l_key_acess clob;
    begin
       --
        select
            access_key_number
        into l_key_acess
        from
            rmais_efd_headers_hdi
        where
            efd_header_id = p_efd_header_id;
       --
        insert into rmais_invoices_events (
            efd_header_id,
            evento,
            mensagem,
            creation_date,
            user_name,
            access_key_number
        ) values ( p_efd_header_id,
                   p_event,
                   p_msg,
                   sysdate,
                   p_user,
                   l_key_acess );
       --
        dbms_output.put_line('headerId: '
                             || p_efd_header_id
                             || 'Event: '
                             || p_event
                             || p_msg || p_user);

    exception
        when others then
       --
            raise_application_error(-20055, 'Não foi possível inserir evento');
       --
    end create_event;
    --
    -- PROCEDURE get_cnpjs_erp AS
    -- l_id_client NUMBER;
    -- BEGIN
    -- BEGIN
    --     --
    --     SELECT ID INTO l_id_client FROM  RMAIS_SUPPLIERS;
    --     --
    -- EXCEPTION WHEN OTHERS THEN
    --     raise_application_error(-20041,'Erro ao buscar ID do Cliente principal '||SQLERRM);
    -- END;
    -- FOR reg IN (SELECT  BU_NAME, 
    -- registration_number CNPJ_BU,
    -- initcap(REGISTERED_NAME) legal_entity_name,
    -- INITCAP(city) city,
    -- replace(postal_code,'-','') postal_code,
    -- state,
    -- INITCAP (ADDRESS1) endereco,
    -- to_number(regexp_substr(ADDRESS2, '[0-9]')) numero,
    -- ADDRESS3 complemento,
    -- initcap(ADDRESS4) bairro,
    -- registration_number_le,
    -- decode (cnpj_seq,1,'Y','N') bu_flag
    -- FROM RMAIS_SETUP_CNPJ_ORACLE_TMP --where rownum = 1
    --                                 )
        
    --     LOOP
    --     BEGIN
    --         INSERT INTO RMAIS_ORGANIZATIONS_HDI VALUES ( RMAIS_ORGANIZATIONS_S.nextval,
    --                                                 l_id_client,
    --                                                 reg.legal_entity_name,
    --                                                 lpad(reg.REGISTRATION_NUMBER_LE,14,'0'),
    --                                                 reg.endereco,
    --                                                 reg.numero,
    --                                                 reg.complemento,
    --                                                 reg.bairro,
    --                                                 reg.city,
    --                                                 reg.state,
    --                                                 reg.postal_code,
    --                                                 reg.bu_flag,
    --                                                 reg.bu_name);
    --         EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
    --             --
    --             UPDATE RMAIS_ORGANIZATIONS_HDI 
    --             SET nome     = reg.legal_entity_name
    --             ,endereco = reg.endereco
    --             ,numero   = reg.numero
    --             ,compl    = reg.complemento
    --             ,bairro   = reg.bairro
    --             ,cidade   = reg.city
    --             ,estado   = reg.state
    --             ,cep      = reg.postal_code
    --             ,bu_flag  = reg.bu_flag
    --             ,bu_code  = reg.bu_name
    --             WHERE lpad(cnpj,14,'0') = lpad(reg.REGISTRATION_NUMBER_LE,14,'0');
    --             --
    --         WHEN OTHERS THEN
    --             --
    --             raise_application_error(-20022,'Erro ao executar processo de setup automático '||SQLERRM);
    --             --
    --         END;
    --         --
    --     END LOOP;
    -- END get_cnpjs_erp;
  --
    function get_fornecedores (
        in_issuer_document_number in varchar2,
        bu_name                   in varchar2 default null,
        efd_header_id             in varchar2 default null,
        chamada_api               in varchar2
    ) return tp_fornecedores_table
        pipelined
    is

        l_url      varchar2(300) := '/api/report/fornecedor/getFornecedor/';
        l_response clob;
        l_ctrl     varchar2(300);
        l_body     varchar2(600);
        l_bu       varchar2(400);
        total      number;
    --
    begin
        begin
            << verifica_bu >> if chamada_api = 0 then
                << chamada_via_api >> l_body := '{"cnpj": "'
                                                || in_issuer_document_number
                                                || '","bu": "$BU$"}';
                if bu_name is null then
                    << if_bu_nulo >>
                --
                     select
                                                          json_value(receiver_info, '$.DATA.BU_NAME')
                                                      into l_bu
                                                      from
                                                          rmais_efd_headers_hdi
                                     where
                                         efd_header_id = efd_header_id;
                --
                    l_body := replace(l_body, '$BU$', l_bu);
                --
                else
              --
                    l_body := replace(l_body, '$BU$', bu_name);
              --
                end if;
            --
                null;
            --
            else
                l_body := '{"cnpj": "'
                          || in_issuer_document_number
                          || '","bu": ""}';
            end if;
        exception
            when others then
                l_body := replace(l_body, '$BU$', bu_name);
        end "verifica_bu";
      --
        l_response := rmais_process_pkg.get_response(l_url, l_body);
      --
        if l_response not like '%PARTY_NAME%' then
            << localizado_oracle >>
        --
             begin
                for rw in (
                    select
                        issuer_document_number,
                        issuer_name,
                        issuer_name2,--l_ctrl,
                        issuer_address,
                        issuer_address_number,
                        issuer_address_complement,
                        issuer_address_city_code,
                        issuer_address_city_name,
                        issuer_address_zip_code,
                        issuer_address_state
                    from
                        (
                            select
                                issuer_document_number,
                                issuer_name,
                                issuer_name                               issuer_name2,
                                issuer_address,
                                issuer_address_number,
                                issuer_address_complement,
                                issuer_address_city_code,
                                issuer_address_city_name,
                                replace(issuer_address_zip_code, '-', '') issuer_address_zip_code,
                                issuer_address_state
                            from
                                rmais_efd_headers_hdi
                            where
                                issuer_document_number = regexp_replace(in_issuer_document_number, '[^0-9]', '')
                            order by
                                creation_date desc
                        )
                    where
                        rownum = 1
                ) loop
                    pipe row ( tp_fornecedores_obj(rw.issuer_document_number, rw.issuer_name, rw.issuer_name2, rw.issuer_address, rw.issuer_address_number
                    ,
                                                   rw.issuer_address_complement, rw.issuer_address_city_code, rw.issuer_address_city_name
                                                   , rw.issuer_address_zip_code, rw.issuer_address_state) );
                end loop;
            end;
        else -- quando não localizado ele busca os dados na tabela headers
            for rw in (
                select distinct
                    issuer_document_number,
                    issuer_name,
                    issuer_name2,
                    issuer_address,
                    issuer_address_number,
                    issuer_address_complement,
                    issuer_address_city_code,
                    issuer_address_city_name,
                    issuer_address_zip_code,
                    issuer_address_state
                from
                    json_table ( replace(
                        replace(l_response, '"DATA":{', '"DATA": [{'),
                        '}}}',
                        '}}]}'
                    ), '$'
                        columns (
                            issuer_document_number varchar2 ( 4000 ) path '$.P_TAX_PAYER_NUMBER',
                            nested path '$.DATA'
                                columns (
                                    issuer_name varchar2 ( 4000 ) path '$.PARTY_NAME',
                                    issuer_name2 varchar2 ( 4000 ) path '$.PARTY_NAME',
                                    nested path '$.ADDRESS[*]'
                                        columns (
                                            issuer_address varchar2 ( 4000 ) path '$.ADDRESS1',
                                            issuer_address_number varchar2 ( 4000 ) path '$.ADDRESS2',
                                            issuer_address_complement varchar2 ( 4000 ) path '$.ADDRESS3',
                                            issuer_address_city_code varchar2 ( 4000 ) path '$.ADDRESS4',
                                            issuer_address_city_name varchar2 ( 4000 ) path '$.CITY',
                                            issuer_address_zip_code varchar2 ( 4000 ) path '$.POSTAL_CODE',
                                            issuer_address_state varchar2 ( 4000 ) path '$.STATE',
                                            vendor_site_code varchar2 ( 4000 ) path '$.VENDOR_SITE_CODE'
                                        )
                                )
                        )
                    )
                where
                        vendor_site_code = in_issuer_document_number
                    and rownum = 1
            ) loop
                pipe row ( tp_fornecedores_obj(rw.issuer_document_number, rw.issuer_name, rw.issuer_name2, rw.issuer_address, rw.issuer_address_number
                ,
                                               rw.issuer_address_complement, rw.issuer_address_city_code, rw.issuer_address_city_name
                                               , rw.issuer_address_zip_code, rw.issuer_address_state) );
            end loop;
        --
        end if;

    exception
        when others then
            null;--;raise_application_error(-20011,'Não foi possível consumir WS para busca de fornecedor');*/
    end get_fornecedores;
    --
    function get_filial (
        p_header_id                in varchar2,
        p_receiver_document_number in varchar2,
        p_role                     varchar2 default null
    ) return varchar2 is

        cursor c_combinacao is
        (
            select
                combinacao_contabil_ger
            from
                     rmais_efd_headers_hdi red
                inner join rmais_define_det_entry rdde on rdde.type = nvl(red.define_det_entry_type, p_role)
                                                          and rdde.model = red.model
            where
                efd_header_id = p_header_id
        );

        l_account varchar2(100);
        l_filial  clob;
        l_body    clob;
        l_url     clob;
    begin
        open c_combinacao;
        fetch c_combinacao into l_account;
        close c_combinacao;
        l_url := rmais_process_pkg.get_parameter('GET_FILIAL_COMBINACAO');
        l_body := '{"cnpjTomador": "'
                  || p_receiver_document_number
                  || '"}';
        l_filial := rmais_process_pkg.get_response2(l_url, l_body, 'POST');
        if json_value(l_filial, '$.DATA.FILIAL') is not null then
            return replace(l_account,
                           'XXX',
                           json_value(l_filial, '$.DATA.FILIAL'));
        else
            return null;
        end if;

    end get_filial;
    --
    function get_metodo_pagamento (
        p_header_id in varchar2
    ) return varchar2 is
        l_metodo varchar2(30);
    begin
        select
            rdde.paymentmethod
        into l_metodo
        from
                 rmais_efd_headers_hdi red
            inner join rmais_define_det_entry rdde on rdde.type = red.define_det_entry_type
                                                      and rdde.model = red.model
        where
            efd_header_id = p_header_id;

        return l_metodo;
    exception
        when others then
            return null;
    end get_metodo_pagamento;
    --
    procedure alterar_senha (
        p_usuario   in varchar2,
        p_workspace in varchar2,
        p_texto     in varchar2
    ) is

        l_password_hash clob := sys.dbms_random.string('p', 16);
        l_body          clob := 'To view the content of this message, please use an HTML enabled mail client.' || utl_tcp.crlf;
        l_body_html     clob;
        l_url           clob;
        email           varchar2(4000);
    begin
        select
            email
        into email
        from
            apex_workspace_apex_users
        where
                user_name = upper(p_usuario)
            and workspace_name = p_workspace;

        l_body_html := 'Olá '
                       || p_usuario
                       || '.<br>'
                       || p_texto
                       || ' <b>'
                       || l_password_hash
                       || '</b><br> Atenção no seu primeiro login irá solicitar a alteração da mesma.';

        apex_util.reset_password(
            p_user_name                    => upper(p_usuario),
            p_old_password                 => null,
            p_new_password                 => l_password_hash,
            p_change_password_on_first_use => true
        );

        apex_mail.send(
            p_to        => email,
            p_from      => 'naoresponda@rm.digital',
            p_body      => l_body,
            p_body_html => l_body_html,
            p_subj      => 'Nova senha Recebe Mais HDI'
        );

        apex_mail.push_queue();
    end alterar_senha;
    --
    procedure set_workflow (
        p_efd_header_id in varchar2,
        p_descricao     in varchar2,
        p_usuario       in varchar2
    ) is

        l_status                 varchar2(10);
        l_user                   varchar2(300);
        l_invoice_number         number;
        l_invoice_amount         number;
        l_issuer_document_number varchar2(30);
    begin
        /*########################################################################################################*/
        /*Procedure criada para execução de workflow para alterações efetuadas no status da nf e na validação main*/
        /*Desenvolvido por erickson na data de 03/07/2023 demanda solicitada por Victor Orsi*/
        /*########################################################################################################*/
        print('debug wkf gravando');
        commit;
        select
            document_status,
            nvl(p_usuario, last_updated_by),
            document_number,
            issuer_document_number,
            total_amount
        into
            l_status,
            l_user,
            l_invoice_number,
            l_issuer_document_number,
            l_invoice_amount
        from
            rmais_efd_headers_hdi
        where
            efd_header_id = p_efd_header_id;

        insert into rmais_invoices_workflow values ( p_efd_header_id,
                                                     l_status,
                                                     p_descricao,
                                                     l_user,
                                                     sysdate,
                                                     l_invoice_number,
                                                     l_issuer_document_number,
                                                     l_invoice_amount );

    exception
        when others then
            print('erro');
    end;
    --
    procedure refresh_status_bancada (
        pr_doc_id       in varchar2,
        pr_status       in varchar2,
        pr_id_ctrl_docs in number,
        pr_descricao    in varchar2
    ) is
        l_body     varchar2(4000);
        l_response clob;
    begin
        select
            json_object(
                'id' is pr_doc_id,
                'status' is pr_status,
                'id_ctrl_docs' is pr_id_ctrl_docs,
                'descricao' is pr_descricao
            )
        into l_body
        from
            dual;  
        --insert into LOG_UPDATE_BANCADA values  (pr_id_ctrl_docs,l_body,'');          
        l_response := rmais_process_pkg.get_response2(
            p_url     => rmais_process_pkg.get_parameter('URL_REFRESH_STATUS_BANCADA'),--'http://144.22.253.165:9000/api/bancada/v1/status_refresh',
            p_content => l_body,
            p_type    => 'POST'
        );
        --insert into LOG_UPDATE_BANCADA values  (pr_id_ctrl_docs,l_response,'');          
        --em caso de erros na chamada, gravar log
        print(json_value(l_response, '$.code'));
        print(json_value(l_response, '$.msg'));
        if ( json_value(l_response, '$.code') not in ( '200', '201' ) ) then
            insert into log_status_bancada (
                id_doc_lsb,
                status_lsb,
                msg_lsb,
                dt_process_lsb
            ) values ( pr_doc_id,
                       json_value(l_response, '$.code'),
                       json_value(l_response, '$.msg'),
                       sysdate );

        end if;
        --incluir as chamadas.
    end refresh_status_bancada;
    --
    procedure reprocess_header (
        p_efd_header_id number
    ) as
        --
        r_nf    rmais_efd_headers.document_number%type;
        nf_orig rmais_efd_headers.document_number%type;
        n_rp    rmais_efd_headers.document_number%type;
        --
    begin
        --  
        execute immediate 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/YYYY''';
        --
        execute immediate 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''.,''';
        --
        print('Iniciando');
        --
        for rp in (
            select
                *
            from
                rmais_efd_headers_hdi
            where
                    efd_header_id = p_efd_header_id
                and document_status in ( 'CE', 'D' )
        ) loop
            print('NF ' || rp.document_number);
            --
            print('Calculando numero original e quantidade de reprocessamentos');
            --
            select
                case
                    when instr(rp.document_number, '.') > 0 then
                        substr(rp.document_number,
                               0,
                               instr(rp.document_number, '.') - 1)
                    else
                        substr(rp.document_number,
                               0,
                               length(rp.document_number))
                end,
                case
                    when instr(rp.document_number, '.') > 0 then
                        substr(rp.document_number,
                               instr(rp.document_number, '.') + 1,
                               length(rp.document_number))
                    else
                        '00'
                end
            into
                nf_orig,
                n_rp
            from
                dual;
            --
            print('NF original: ' || nf_orig);
            --
            print('Reprocessada '
                  || n_rp || ' vez(es).');
            -- 
            begin
                --
                r_nf := nf_orig
                        || '.'
                        || lpad((to_number(n_rp) + 1), 2, 0);
                --
                print('NF ' || r_nf);
            exception
                when others then
                        --
                    null;
                        --
            end;
            --            
            update rmais_efd_headers_hdi
            set
                document_status = 'I',
                document_number = r_nf
            where
                efd_header_id = p_efd_header_id;
            --
            rmais_util_pkg_poc.create_event(rp.efd_header_id, 'NF Reprocessada', 'NF reprocessada: ' || r_nf, 'SISTEMA');
            --
        end loop;
        --
        --rmais_process_pkg.set_workflow(p_efd_header_id,'Nota reprocessada.',nvl(v('APP_USER'),'-1'));
        --
        print('Terminando');
    end reprocess_header;
    --
end rmais_util_pkg_poc;
--homol;

/


-- sqlcl_snapshot {"hash":"adc232d668b669b313c789ec8ee2a6637f8c766c","type":"PACKAGE_BODY","name":"RMAIS_UTIL_PKG_POC","schemaName":"RMAIS","sxml":""}