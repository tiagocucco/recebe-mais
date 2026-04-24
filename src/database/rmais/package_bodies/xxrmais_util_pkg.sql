create or replace package body xxrmais_util_pkg as --CLL_F369_efd_send_ri_pkg
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
    begin
    --
        if l_clob_trat is null then
            l_clob_trat := p_clob;
        end if;
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
                itm.des_produto
            from --rmais_ctrl_docs rm,
                xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/nfe' ),
                '/nfeProc/NFe/infNFe/det'
                        passing xmltype(p_clob)
                    columns
                        pedido varchar2(150) path '/det/prod/xPed/text()',
                        line_num number path '/det/@nItem',
                        line_num_ped number path '/det/prod/nItemPed/text()',
                        des_produto varchar2(255) path '/det/prod/xProd/text()'
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
      --print('Loop XML');
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
                        rmais_efd_lines l
                    where
                            efd_header_id = p_efd_id
                        and line_number = xped.line_num
                ) loop
          --Tratamento XPED
                    if nvl(rml.source_document_type, 'PO') = 'PO' then
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

                        exception
                            when others then
                                print('Erro ao tratar cProd: ' || sqlerrm);
                        end;

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

                        exception
                            when others then
                                print('Erro ao tratar uTrib: ' || sqlerrm);
                        end;

                    end if;

                end loop;

            end;
      --
        end loop;

        p_clob := l_clob_trat;
    exception
        when others then
            raise_application_error(-20022, 'Não foi possível fazer a alteração no XML de envio');
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
    begin
    --
        select
            efdc.source_doc_decr,
            efdh.access_key_number,
            efdh.issuer_document_number,
            efdh.document_number
        into
            l_xml_send,
            l_danfe,
            l_cnpj_forn,
            l_num
        from
            rmais_efd_headers efdh,
            rmais_ctrl_docs   efdc
        where
            doc_id is not null
            and model = '55'
            and efdh.doc_id = efdc.id
            and efd_header_id = p_id;
    --
    --print(l_xml_send);
        process_xped(l_xml_send, p_id);
        process_cep(l_xml_send);
    --print(l_xml_send);
     --
    --print(l_xml_send);
        l_xml_encode := xxrmais_util_pkg.base64encode(xxrmais_util_pkg.clob_to_blob(l_xml_send));
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
                l_url      varchar2(400) := rmais_process_pkg.get_parameter('URL_SEND_FDC');--'http://localhost:9000/api/job/v2/sendDocToFDC';                              
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
                                    update rmais_efd_headers
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
                                               'Integrado',
                                               'Documentid: '
                                               || xxrmais_util_pkg.get_value_json('DocumentId', l_response),
                                               sysdate );
                  --
                                    update rmais_efd_headers
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
          --
                    print('Erro ao chamar WS: ' || sqlerrm);
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
        l_return rmais_efd_headers.access_key_number%type;
    begin
  --
        select
            access_key_number
        into l_return
        from
            rmais_efd_headers
        where
            access_key_number = lpad(lpad(p_cnpj_dest, 15, '0')
                                     || lpad(p_cnpj, 15, '0')
                                     || to_char(p_issue_date, 'YYYYMM')
                                     || lpad(p_numero_nff, 8, '0'),
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
                    rmais_efd_headers
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
    end get_access_key_number;
  --
    procedure source_docs (
        p_id number default null
    ) as
 --
        g_status    varchar2(1);--P processado  E Error   D Duplicada   R Rejeitada    M evento de manifesto
        g_ctrl_id   number;
        g_ctrl      rmais.rmais_ctrl_docs%rowtype;
        g_source    rmais.xxrmais_invoices%rowtype;
        g_source_l  rmais.xxrmais_invoice_lines%rowtype;
        l_header    rmais.rmais_efd_headers%rowtype;
        l_lines     rmais.rmais_efd_lines%rowtype;
 --
        g_doc_count number := 0;
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
                itens                    xmltype
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
                rmais_suppliers     rmc,
                rmais_organizations rmcc
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
                      || ' NÃO CADASTRADO NO SISTEMA RECEBE MAIS.', 1);
    --
        end valid_org;
  --
  --
    ----------------------------------------------
  -- Processo de Integração de XMLs para NFSe --
  ----------------------------------------------
        procedure load_read_file_xml_nfse (
            psource clob
        ) is
    --
            vidx             number;
            clin             c$refcur;
            rlin             rl$nfse;
            rregh            rh$nfse;
            xregc            clob;
            xlinc            clob;
            l_layout         varchar2(60);
            l_xml            xmltype;
            l_header         rmais_efd_headers%rowtype;
            l_lines          rmais_efd_lines%rowtype;
    --
            l_resp_link_nfse varchar2(1000); -- Robson 23/03/2023
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
                    begin
          --
                        select
                            source,
                            context
                        into
                            xregc,
                            l_layout
                        from
                            rmais_source_ctrl --FOR UPDATE
                        where
                            psource like '%'
                                         || text_value
                                         || '%'
                            and text_value is not null;
            --
          --  SELECT * FROM rmais_source_ctrl FOR UPDATE;
                        print('Layout identificado: ' || l_layout);
            --
                    exception
                        when others then
          --
                            print('Não localizado layout para integração');
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
                        l_xml := xmltype(replace(psource, '<tcNfse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><InfNfse xmlns="http://www.abrasf.org.br/nfse.xsd">'
                        , '<tcNfse><InfNfse>'));
          --
                    elsif psource like '%<?xml version="1.0" encoding="UTF-8"?><NFe>%' then
          --
                        l_xml := xmltype(replace(psource, '<?xml version="1.0" encoding="UTF-8"?>', ''));
          --
                    else
          --
                        l_xml := xmltype(psource);
          --
                    end if;
        --
                    print(substr(psource, 1, 3999));
        --
        --print('TRATA: '||l_xml.getclobval);
        ---------------------------------------
        -- dados do cabeçalho da nota fiscal --
        ---------------------------------------
                    execute immediate xregc
                    into rregh
                        using l_xml;
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
                    print('');
        --
                    l_header.doc_id := g_ctrl_id;
                    l_header.model := '00';
                    l_header.efd_header_id := xxrmais_invoices_s.nextval;
                    l_header.document_number := rregh.numero_nff;
                    g_ctrl.numero := rregh.numero_nff;
                    l_header.cod_verif_nfs := rregh.codigoverificacao;
                    l_header.issue_date := to_timestamp_tz ( rregh.dataemissao,
                    'RRRR-MM-DD"T"HH24:MI:SS TZR' );
                    l_header.additional_information := rregh.outrasinformacoes;
                    l_header.iss_base :=
                        case
                            when nvl(rregh.valoriss, 0) > 0 then
                                rregh.basecalculo
                            else
                                0
                        end;

                    l_header.net_amount := rregh.valorliquidonfse;
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
                    l_header.iss_tax := rregh.aliquota;
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
        --     rmais_efd_headers
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
                    l_header.receiver_document_number := nvl(rregh.cnpj_dest, rregh.cpf_emit);
                    l_header.receiver_address := rregh.endereco_dest;
                    l_header.receiver_address_number := rregh.numero_dest;
                    l_header.receiver_address_state := rregh.uf_dest;
                    l_header.receiver_address_city_name := rregh.xnomemunicipio;
                    l_header.receiver_name := substr(rregh.xnomeestabtomador, 1, 60);
                    l_header.simple_national_indicator :=
                        case
                            when rregh.optantesimplesnacional = 'NAO DEFINIDO' then
                                ''
                            else
                                rregh.optantesimplesnacional
                        end;
        --l_header.document_status               := 'N';
        --l_header.access_key_number             := lpad(LPAD(nvl(rRegh.Cnpj_Dest,rRegh.CPF_Emit),15,'0')||LPAD(nvl(rRegh.Cnpj,rRegh.CPF),15,'0')||to_char(l_header.issue_date,'YYYYMM')||LPAD(rRegh.Numero_Nff,8,'0'),44,'0');
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
                    valid_org(
                        nvl(rregh.cnpj_dest, rregh.cpf_emit),
                        g_ctrl.status
                    );
        --
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
                        begin
             --
                            insert into rmais_efd_headers values l_header;
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
                                        update rmais_efd_headers
                                        set
                                            document_status =
                                                case
                                                    when document_status = 'T' then
                                                        'X'
                                                    else
                                                        'C'
                                                end
                                        where
                                            access_key_number = l_header.access_key_number;
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
                                print('Erro ao inserir RMAIS_EFD_HEADERS' || sqlerrm);
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
                                context = l_layout || '_LINES';
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
                        if l_layout like 'NFSE_%' then
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
            -- SELECT * FROM rmais_efd_lines
                                    l_lines.efd_line_id := rmais_efd_lines_s.nextval;
                                    l_lines.efd_header_id := l_header.efd_header_id;
                                    l_lines.line_number := rlin.line_num;
                                    l_lines.item_code := rlin.xcod_produto;
              --print('TRAT: '||SUBSTR(rLin.xDes_Produto,1,10));
              --Print('STRAT: '||rLin.xDes_Produto);
                                    l_lines.item_description := substr(rlin.xdes_produto, 1, 110);--print('Error'||rLin.xDes_Produto);
            --rmais_efd_lines
                                    l_lines.source_doc_number := rlin.pedido;
                                    l_lines.uom_to := rlin.uom;
                                    l_lines.line_quantity := rlin.vqtde;
                                    l_lines.unit_price := rlin.valor_un;
                                    l_lines.line_amount := rlin.valor_tot;
                                    l_lines.city_service_type_rel_code := get_cod_serv_expecific(rregh.codigomunicipio, rregh.serv_list
                                    );
                                    l_lines.fiscal_classification := get_cod_serv_expecific(rregh.codigomunicipio, rregh.serv_list);
              --
                                    l_lines.creation_date := sysdate;
                                    l_lines.created_by := -1;
                                    l_lines.last_update_date := sysdate;
                                    l_lines.last_updated_by := -1;
              --
                                    print('Inserindo efd_line_id: ' || l_lines.efd_line_id);
              --
                                    if nvl(g_ctrl.status, 'P') not in ( 'C', 'D', 'E' ) then
                --
                                        begin
                  --
                                            insert into rmais_efd_lines values l_lines;
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
                        l_resp_link_nfse := xxrmais_util_v2_pkg.get_link_nfse(l_header.efd_header_id); -- Robson 23/03/2023 start
                        if l_resp_link_nfse is null then
                            update rmais_efd_headers
                            set
                                document_status = 'FA'
                            where
                                efd_header_id = l_header.efd_header_id;

                        else -- Robson 23/03/2023 end 
            --
                            begin
                                rmais_process_pkg.main(
                                    p_header_id => l_header.efd_header_id,
                                    p_send_erp  => 'Y'
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
            p_xml clob
        ) is
    --
            vidx    number;
            l_ctrbr number;
    --
            l_xml   clob;
    --
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
                                iss_tax number path '/nfeProc/NFe/infNFe/imposto/ISSQN/vAliq/text()',
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
                    l_header.efd_header_id := xxrmais_invoices_s.nextval;
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
                    l_header.icms_amount := nvl(regc.v_vl_icms, 0);
                    l_header.icms_calculation_basis := nvl(regc.v_b_icms, 0);
                    l_header.icms_st_amount := nvl(regc.v_st_icms, 0);
                    l_header.icms_st_calculation_basis := nvl(regc.v_bst_icms, 0);
          --l_header.Icms_St_Amount_Recover      := 0; --
          --l_header.Diff_Icms_Amount_Recover    := 0; --
          --l_header.Diff_Icms_Amount            := 0; --
          --l_header.Diff_Icms_Tax               := 0; --
                    l_header.inss_amount := 0; --
                    l_header.inss_base := 0; --
                    l_header.inss_tax := 0; --
                    l_header.ipi_amount := nvl(regc.vipi, 0);
                    l_header.ir_amount := nvl(regc.ir_amount, 0);
                    l_header.ir_base := nvl(regc.ir_base, 0);
                    l_header.ir_categ := 0; --
                    l_header.ir_tax := 0; --
                    l_header.iss_amount := nvl(regc.iss_amount, 0);
                    l_header.iss_base := nvl(regc.iss_base, 0);
                    l_header.iss_tax := nvl(regc.iss_tax, 0);
                    l_header.discount_amount := nvl(regc.v_desconto, 0);
                    l_header.insurance_amount := nvl(regc.vseg, 0);
                    l_header.other_expenses_amount := nvl(regc.v_outras_des, 0);
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
          --g_source.data
          /*g_source.codigoverificacao             := nfse.CodigoVerificacao;
          g_source.dataemissao                   := to_date(nfse.DataEmissao,'YYYY-MM-DD');
          g_source.outrasinformacoes             := nfse.OutrasInformacoes;
          g_source.basecalculo                   := nfse.BaseCalculo;
          g_source.valorliquido                  := nfse.ValorLiquidoNfse;
          g_source.valorcredito                  := nfse.ValorCredito;
          g_source.cnpj_cpf                      := nvl(nfse.Cnpj,nfse.CPF);
          g_source.inscricaomunicipal_emit       := nfse.InscricaoMunicipal;
          g_source.razaosocial_emit              := nfse.RazaoSocial;
          g_source.nomefantasia_emit             := nfse.NomeFantasia;
          g_source.endereco_emit                 := nfse.Endereco;
          g_source.numero_emit                   := nfse.Numero;
          g_source.bairro_emit                   := nfse.Bairro;
          g_source.uf_emit                       := nfse.Uf;
          g_source.cep_emit                      := nfse.Cep;
          g_source.telefone_emit                 := nfse.Telefone;
          g_source.codigomunicipio_emit          := nfse.CodigoMunicipio;
          g_source.municipio_emit                := nfse.municipio;
          g_source.competencia                   := nfse.Competencia;
          g_source.valorservicos                 := nfse.ValorServicos;
          g_source.valordeducoes                 := nfse.ValorDeducoes;
          g_source.valorpis                      := nfse.ValorPis;
          g_source.valorcofins                   := nfse.ValorCofins;
          g_source.valorinss_servico             := nfse.ValorInss_Servico;
          g_source.valorir                       := nfse.ValorIr;
          g_source.valorcsll                     := nfse.ValorCsll;
          g_source.vlrissretido                  := nfse.VlrIssRetido;
          g_source.alqissreti                    := nfse.AlqIssRetido;
          g_source.outrasretencoes               := nfse.OutrasRetencoes;
          g_source.valoriss                      := nfse.ValorIss;
          g_source.descontoincondicio            := nfse.DescontoIncondicionado;
          g_source.descontocondicio              := nfse.DescontoCondicionado;
          g_source.issretido                     := nfse.IssRetido;
          g_source.codigomunicipio_serv          := nfse.CodigoMunicipio_Ser;
          g_source.inscricaomunicipal_dest       := nvl(nfse.InscricaoMunicipal_P , nfse.InscricaoMunicipal_Dest);
          g_source.cnpj_dest                     := nvl(nfse.Cnpj_Dest,nfse.CPF_Emit);
          g_source.razaosocial_dest              := nfse.RazaoSocial_Dest;
          g_source.endereco_dest                 := nfse.Endereco_Dest;
          g_source.numero_dest                   := nfse.Numero_Dest;
          g_source.uf_dest                       := nfse.Uf_DesT;
          g_source.nomemunicipio_dest            := nfse.xnomemunicipio;
          g_source.telefone_dest                 := nfse.Telefone_Dest;
          g_source.email_dest                    := nfse.Email_Dest;
          g_source.codestabtomador               := nfse.xCodEstabTomador;
          g_source.nomeestabtomador              := nfse.xNomeEstabTomador;
          g_source.optantesimplesnacio           := nfse.OptanteSimplesNacional;
          g_source.incentivofiscal               := nfse.IncentivoFiscal;
          g_source.serv_code                     := nfse.Serv_list;
          g_source.status                        := 'N';                  */
          --
                    l_header.usage_authorization := regc.usage_auth;
                    l_header.document_number := regc.num_nf;
                    l_header.series := regc.serie;
                    l_header.model := regc.modelo;
                    l_header.total_amount := regc.v_total_nf;
          --
          --
         -- SELECT * FROM rmais_efd_headers;
         /*
          rSource.rHead.Invoice_Type_code           := Regc.xTipoNF;
          r
          rSource.rHead.Invoice_Date                := To_timestamp_tz(Regc.Emissao,'RRRR-MM-DD"T"HH24:MI:SS TZR');
          rSource.rHead.Ceo_attribute3              := To_timestamp_tz(Regc.Recebto,'RRRR-MM-DD"T"HH24:MI:SS TZR');
          rSource.rHead.Eletronic_Invoice_Key       := Regc.danfe;
        --rSource.rHead.Entity_id                   := Regc.Entity_id;
          rSource.rHead.Comments                    := Regc.Comments;
          rSource.rhead.source_ibge_city_code       := Regc.cMun_Emit;
          rSource.rhead.destination_ibge_city_code  := Regc.cMun_Dest;
          rSource.rHead.Source_State_code           := Regc.UF_Emit;
          rSource.rHead.Destination_State_code      := Regc.UF_Dest;
          rSource.rHead.Document_Number             := NVL(Regc.cnpj_for, Regc.CPF_Emit);
        --rSource.rHead.Terms_name                  := Regc.CondPagto;
          rSource.rHead.Freight_Amount              := Nvl(Regc.V_Frete,   0);
          rSource.rHead.Gross_Total_Amount          := Nvl(Regc.V_Total_Nf,0);
        --rSource.rHead.Icms_Tax                    := ???;
          rSource.rHead.icms_fcp_amount             := Regc.vFCPUFDest;
          rSource.rHead.icms_sharing_dest_amount    := Regc.vICMSUFDest;
          rSource.rHead.icms_sharing_source_amount  := Regc.vICMSUFRemet;
          rSource.rHead.Icms_Amount                 := Nvl(Regc.V_Vl_Icms, 0);
          rSource.rHead.Icms_Base                   := Nvl(Regc.V_B_Icms,  0);
          rSource.rHead.Icms_St_Amount              := Nvl(Regc.V_St_Icms, 0);
          rSource.rHead.Icms_St_Base                := Nvl(Regc.V_Bst_Icms,0);
          rSource.rHead.Icms_St_Amount_Recover      := 0; --
          rSource.rHead.Diff_Icms_Amount_Recover    := 0; --
          rSource.rHead.Diff_Icms_Amount            := 0; --
          rSource.rHead.Diff_Icms_Tax               := 0; --
          rSource.rHead.Inss_Amount                 := 0; --
          rSource.rHead.Inss_Base                   := 0; --
          rSource.rHead.Inss_Tax                    := 0; --
          rSource.rHead.Ipi_Amount                  := NVL(Regc.vIpi,      0);
          rSource.rHead.Ir_Amount                   := NVL(Regc.IR_Amount, 0);
          rSource.rHead.Ir_Base                     := NVL(Regc.IR_Base,   0);
          rSource.rHead.Ir_Categ                    := 0; --
          rSource.rHead.Ir_Tax                      := 0; --
          rSource.rHead.Iss_Amount                  := NVL(Regc.Iss_Amount,0);
          rSource.rHead.Iss_Base                    := NVL(Regc.Iss_Base,  0);
          rSource.rHead.Iss_Tax                     := NVL(Regc.Iss_Tax,   0);
          rSource.rHead.Payment_Discount            := Nvl(Regc.V_Desconto,0);
          rSource.rHead.insurance_amount            := Nvl(Regc.vSeg,      0);
          rSource.rHead.Other_Expenses              := Nvl(Regc.V_Outras_Des,0);
          rSource.rHead.Subst_Icms_Base             := 0;
          rSource.rHead.Subst_Icms_Amount           := 0;
          rSource.rHead.Pis_Withhold_Amount         := 0; --
          rSource.rHead.Cofins_Withhold_Amount      := 0; --
          rSource.rHead.carrier_document_number     := NVL(Regc.transp_CNPJ, Regc.transp_CPF);
          rSource.rHead.carrier_document_type       := CASE WHEN LENGTH(rSource.rHead.carrier_document_number) > 0 THEN CASE WHEN LENGTH(Regc.transp_CPF) > 0 THEN 'CPF' ELSE 'CNPJ' END END;
          rSource.rHead.carrier_ie                  := Regc.transp_IE;
          --
          rSource.rEfd.file_name                    := rSource.rCtrl.Filename;
          rSource.rEfd.process_date                 := trunc(SYSDATE);
          rSource.rEfd.tributary_regimen            := Regc.CRT;
          rSource.rEfd.layout_version               := Regc.Versao;
          rSource.rEfd.operation_type               := Regc.TipoNF;
          Print('rSource.rEfd.operation_type: '||rSource.rEfd.operation_type);
          rSource.rEfd.issuing_type                 := Regc.tpEmis;
          rSource.rEfd.issuing_purpose              := Regc.FinNF;
          rSource.rEfd.issue_date                   := rSource.rHead.Invoice_Date;
          rSource.rEfd.document_type                := CASE WHEN Regc.Cpf_Emit IS NOT NULL THEN 'CPF' ELSE 'CNPJ' END;
          rSource.rEfd.payment_indicator            := Regc.indPag;
          rSource.rEfd.operation_nature             := Regc.natOp;
          rSource.rEfd.liable_freight_payment       := Regc.modFrete;
          rSource.rEfd.carrier_address_state        := Regc.transp_UF;
          rSource.rEfd.issuer_name                  := Regc.Nome_Emit;
          rSource.rEfd.issuer_document_number       := apps.xxrmais_util_pkg.lpad(NVL(Regc.cnpj_for, Regc.CPF_Emit),14,'0');
          rSource.rEfd.issuer_address_state         := Regc.UF_Emit;
          rSource.rEfd.issuer_address_city_name     := Regc.xMun_Emit;
          rSource.rEfd.issuer_address               := Regc.xLgr_Emit;
          rSource.rEfd.issuer_address_number        := Regc.nro_Emit ;
          rSource.rEfd.issuer_address_complement    := Regc.xCpl_Emit;
          rSource.rEfd.issuer_address_zip_code      := Regc.CEP_Emit ;
          rSource.rEfd.receiver_name                := Regc.Nome_Dest;
          rSource.rEfd.receiver_document_number     := NVL(Regc.cnpj_emp, Regc.CPF_dest);
          rSource.rEfd.receiver_address_state       := Regc.UF_Dest;
          rSource.rEfd.receiver_address_city_name   := Regc.xMun_Dest;
          rSource.rEfd.receiver_address             := Regc.xLgr_Dest;
          rSource.rEfd.receiver_address_number      := Regc.nro_Dest ;
          rSource.rEfd.receiver_address_complement  := Regc.xCpl_Dest;
          rSource.rEfd.receiver_address_zip_code    := Regc.CEP_Dest ;
          rSource.rEfd.ship_from_document_number    := Regc.ShipFr_CNPJ;
          rSource.rEfd.ship_from_address_state      := Regc.ShipFr_UF;
          rSource.rEfd.ship_from_address_city_code  := Regc.ShipFr_cMun;
          rSource.rEfd.ship_from_address_city_name  := Regc.ShipFr_xMun;
          rSource.rEfd.ship_from_address            := Regc.ShipFr_xLgr;
          rSource.rEfd.ship_from_address_number     := Regc.ShipFr_nro ;
          rSource.rEfd.ship_from_address_complement := Regc.ShipFr_xCpl;
          rSource.rEfd.ship_to_document_number      := NVL(Regc.ShipTo_CNPJ, Regc.ShipTo_CPF);
          rSource.rEfd.ship_to_address_state        := Regc.ShipTo_UF;
          rSource.rEfd.ship_to_address_city_code    := Regc.ShipTo_cMun;
          rSource.rEfd.ship_to_address_city_name    := Regc.ShipTo_xMun;
          rSource.rEfd.ship_to_address              := Regc.ShipTo_xLgr;
          rSource.rEfd.ship_to_address_number       := Regc.ShipTo_nro ;
          rSource.rEfd.ship_to_address_complement   := Regc.ShipTo_xCpl;
          rSource.rEfd.pis_amount                   := Regc.vPIS;
          rSource.rEfd.cofins_amount                := Regc.vCOFINS;
          --
          rSource.rCtrl.Cnpj_Emit                   := Regc.Cnpj_For;
          rSource.rCtrl.Cpf_Emit                    := Regc.Cpf_Emit;
          rSource.rCtrl.Cnpj_Dest                   := Regc.Cnpj_Emp;
          rSource.rCtrl.tipo_doc                    := regc.modelo;
          rSource.rCtrl.Simples_BR                  := Regc.CRT;*/
          --
          --------------------------------
          -- Selecionar dados dos itens --
          --------------------------------
          --
                    print('Inserindo registros NFe HEADER');
          --
                    begin
            --
                        back_list(l_header.document_status, l_header.access_key_number);
            --
                        insert into rmais_efd_headers values l_header;
            --
            --SELECT * FROM rmais_efd_headers;
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
                            print('Erro ao inserir RMAIS_EFD_HEADERS' || sqlerrm);
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
                                    cofinsal_aliq number path '/det/imposto/COFINS/COFINSAliq/pCOFINS/text()'
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
                                l_lines.source_doc_number := rlin.pedido;
                --rSource.rLines(vIDX).Release_num                   := CASE WHEN regexp_substr(regexp_replace(rLin.Pedido,' ','-'),'[^-|$-]+',1,2) LIKE '%/%' THEN ''
                --                                                      ELSE
                --                                                        regexp_substr(regexp_replace(rLin.Pedido,' ','-'),'[^-|$-]+',1,2)
                --                                                      END;
                                l_lines.ri_operation_fiscal_type := rlin.xnaturoper; --Regc.xOperFiscal;
               -- l_line.Reg.Line_Num                  := nvl(rLin.Line_Num, rLin.Line_num_Ped);
                                l_lines.line_number := nvl(rlin.line_num, rlin.line_num_ped);
                                l_lines.source_doc_line_num := rlin.line_num_ped;
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
                                l_lines.fiscal_classification := rlin.ncm;
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
                --l_lines.icms_cst_from            := rSource.rLines(vIDX).Cst_Icms;
                --l_lines.Cfop_from                := rSource.rLines(vIDX).Cfo_Saida;
                --l_lines.source_document_type     := rSource.rEfd.source_document_type;
                                print('Atribuido variáveis da linha');
                                if nvl(g_ctrl.status, 'P') not in ( 'D', 'E' ) then
                  --
                                    insert into rmais_efd_lines values l_lines;
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
                        rmais_process_pkg.main(
                            p_header_id => l_header.efd_header_id,
                            p_send_erp  => 'Y'
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
/*  --
  PROCEDURE load_nfse (p_xml CLOB , p_layout VARCHAR2 DEFAULT NULL) AS
    --
    l_xml CLOB;
    --
  BEGIN
    --
    --
    l_xml := REPLACE (p_xml,'<tcNfse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <InfNfse xmlns="http://www.abrasf.org.br/nfse.xsd">','<tcNfse>
  <InfNfse>');
 --  pRINT(l_xml);
    FOR nfse IN (SELECT   '' versao
                        , '' ID
                        , '' xTipoNF
                        , '' xModeloFiscal
                        , '' xdata_carimbo
                        , '' xOperFiscal
                        , '' CondPagto
                        , Numero_Nff
                        , '' Serie
                        , '' xCFO
                        , '' CFO
                        , CodigoVerificacao
                        , DataEmissao
                        , OutrasInformacoes
                        , BaseCalculo
                        , '' Aliquota
                        , '' ValorIss_Nfse
                        , '' DtVenc_iss
                        , ValorLiquidoNfse
                        , ValorCredito
                        , Cnpj
                        , CPF
                        , InscricaoMunicipal
                        , '' InscricaoEstadual
                        , '' nome
                        , RazaoSocial
                        , NomeFantasia
                        , Endereco
                        , Numero
                        , Bairro
                        , Uf
                        , Cep
                        , Telefone
                        , '' complemento
                        , '' email
                        , CodigoMunicipio
                        , municipio
                        ,'' pais
                        ,'' Tipo_Rps
                        ,'' DataEmissao_Rps
                        ,'' Numero_rps
                        ,'' serie_rps
                        ,'' Status_Rps
                        ,'' Tipo_Rps_Subst
                        , Competencia
                        , ValorServicos
                        , ValorDeducoes
                        , ValorPis
                        , '' AlqPisPasep
                        , ValorCofins
                        , '' AlqCofins
                        , ValorInss_Servico
                        , ValorIr
                        , '' AlqIrrf
                        , ValorCsll
                        , VlrIssRetido
                        , Aliquota AlqIssRetido
                        , '' AlqCsll
                        , OutrasRetencoes
                        , ValorIss
                        , DescontoIncondicionado
                        , DescontoCondicionado
                        , IssRetido
                        , '' CodTribMuni
                        , CodigoMunicipio_Ser
                        , '' ExigibilidadeISS
                        , '' xDataPaga
                        , Cnpj_Emit
                        , CPF_Emit
                        , '' Entity_id
                        , InscricaoMunicipal_P
                        , Cnpj_Dest
                        , InscricaoMunicipal_Dest
                        , RazaoSocial_Dest
                        , Endereco_Dest
                        , Numero_Dest
                        , Uf_DesT
                        , xnomemunicipio
                        , Telefone_Dest
                        , Email_Dest
                        , xCodEstabTomador
                        , xNomeEstabTomador
                        , OptanteSimplesNacional
                        , IncentivoFiscal
                        , Serv_list
                        , '' NumeroNFSeSubstituida
                        , '' DtPrestacaoServico
                        , '' Inter_Cpf
                        , '' Inter_Cnpj
                        , '' Inter_InscricaoMunicipal
                        , '' Inter_InscricaoEstadual
                        , '' Inter_Nome
                        , '' Inter_RazaoSocial
                        , '' Inter_NomeFantasia
                        , '' Inter_Endereco
                        , '' Inter_Numero
                        , '' Inter_Complemento
                        , '' Inter_Bairro
                        , '' Inter_Municipio
                        , '' Inter_Uf
                        , '' Inter_Pais
                        , '' Inter_Cep
                        , '' Inter_telefone
                        , '' Inter_Email
                        , '' Inter_Regime
                        , '' Inter_CodigoMobiliario
                        , '' toma_Regime
                        , '' toma_CodigoMobiliario
                        , '' Prest_nome
                        , '' Prest_Regime
                        , '' Prest_CodigoMobiliario
                        , '' Discr_servico
                        , '' constru_art
                        , '' constru_cod_obra
                        , '' valor_total
                        , '' desconto
                        , '' Ret_federal
                        , '' MunicipioIncidencia
                        , '' Recolhimento
                        , '' Tributacao
                        , '' CNAE
                        , '' DescricaoAtividade
                        , '' DescricaoTipoServico
                        , '' LocalPrestacao
                        , '' NaturezaOperacao
                        , '' RegimeEspecialTributacao
                        , '' NumeroGuia
                        , '' Po_num
                        , '' po_item
                        , '' particularidades
                        , Itens
                FROM XMLTABLE( '/tcNfse'
                PASSING XMLTYPE(l_xml)
                COLUMNS
                   Numero_Nff               VARCHAR2(30)      PATH '/tcNfse/InfNfse/Numero/text()'
                 , CodigoVerificacao        VARCHAR2(900)     PATH '/tcNfse/InfNfse/CodigoVerificacao/text()'
                 , DataEmissao              VARCHAR2(200)     PATH '/tcNfse/InfNfse/DataEmissao/text()'
                 , OutrasInformacoes        VARCHAR2(1000)    PATH '/tcNfse/InfNfse/OutrasInformacoes/text()'
                 , BaseCalculo              NUMBER            PATH '/tcNfse/InfNfse/ValoresNfse/BaseCalculo/text()'
                 , ValorLiquidoNfse         NUMBER            PATH '/tcNfse/InfNfse/ValoresNfse/ValorLiquidoNfse/text()'
                 , ValorCredito             NUMBER            PATH '/tcNfse/InfNfse/ValorCredito/text()'
                 , Cnpj                     VARCHAR2(150)     PATH '/tcNfse/InfNfse/PrestadorServico/IdentificacaoPrestador/CpfCnpj/Cnpj/text()'
                 , CPF                      VARCHAR2(150)     PATH '/tcNfse/InfNfse/PrestadorServico/IdentificacaoPrestador/CpfCnpj/Cpf/text()'
                 , InscricaoMunicipal       VARCHAR2(150)     PATH '/tcNfse/InfNfse/PrestadorServico/IdentificacaoPrestador/InscricaoMunicipal/text()'
                 , RazaoSocial              VARCHAR2(100)     PATH '/tcNfse/InfNfse/PrestadorServico/RazaoSocial/text()'
                 , NomeFantasia             VARCHAR2(100)     PATH '/tcNfse/InfNfse/PrestadorServico/NomeFantasia/text()'
                 , Endereco                 VARCHAR2(100)     PATH '/tcNfse/InfNfse/PrestadorServico/Endereco/Endereco/text()'
                 , Numero                   VARCHAR2(100)     PATH '/tcNfse/InfNfse/PrestadorServico/Endereco/Numero/text()'
                 , Bairro                   VARCHAR2(200)     PATH '/tcNfse/InfNfse/PrestadorServico/Endereco/Bairro/text()'
                 , Uf                       VARCHAR2(100)     PATH '/tcNfse/InfNfse/PrestadorServico/Endereco/Uf/text()'
                 , Cep                      VARCHAR2(100)     PATH '/tcNfse/InfNfse/PrestadorServico/Endereco/Cep/text()'
                 , Telefone                 VARCHAR2(200)     PATH '/tcNfse/InfNfse/PrestadorServico/Contato/Telefone/text()'
                 , CodigoMunicipio          VARCHAR2(200)     PATH '/tcNfse/InfNfse/OrgaoGerador/CodigoMunicipio/text()'
                 , xnomemunicipio           VARCHAR2(200)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Tomador/Endereco/xNomeMunicipio/text()'
                 , municipio                VARCHAR2(200)     PATH '/tcNfse/InfNfse/PrestadorServico/Endereco/xNomeMunicipio/text()'
                 , Tipo_Rps                 VARCHAR2(200)     PATH '/tcNfse/InfNfse/DeclaracaoPrestacaoServico/InfDeclaracaoPrestacaoServico/Rps/IdentificacaoRps/Tipo/text()'
                 , DataEmissao_Rps          VARCHAR2(200)     PATH '/tcNfse/InfNfse/DeclaracaoPrestacaoServico/InfDeclaracaoPrestacaoServico/Rps/DataEmissao/text()'
                 , Status_Rps               VARCHAR2(200)     PATH '/tcNfse/InfNfse/DeclaracaoPrestacaoServico/InfDeclaracaoPrestacaoServico/Rps/Status/text()'
                 , Tipo_Rps_Subst           VARCHAR2(200)     PATH '/tcNfse/InfNfse/DeclaracaoPrestacaoServico/InfDeclaracaoPrestacaoServico/Rps/RpsSubstituido/Tipo/text()'
                 , Competencia              VARCHAR2(200)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Competencia/text()'
                 , ValorServicos            NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/ValorServicos/text()'
                 , ValorDeducoes            NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/ValorDeducoes/text()'
                 , ValorPis                 NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/ValorPis/text()'
                 , ValorCofins              NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/ValorCofins/text()'
                 , ValorInss_Servico        NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/ValorInss/text()'
                 , ValorIr                  NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/ValorIr/text()'
                 , ValorCsll                NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/ValorCsll/text()'
                 , OutrasRetencoes          NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/OutrasRetencoes/text()'
                 , ValorIss                 NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/ValorIss/text()' --Quando utilizada será retido
                 , Aliquota                 NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/Aliquota/text()' --Quando utilizada será retido
                 , VlrIssRetido             NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/ValorIss/text()' --
                 , DescontoIncondicionado   NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/DescontoIncondicionado/text()'
                 , DescontoCondicionado     NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/Valores/DescontoCondicionado/text()'
                 , IssRetido                NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/IssRetido/text()'
                 , CodigoMunicipio_Ser      NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/OrgaoGerador/CodigoMunicipio/text()'
                 --, ExigibilidadeISS         NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/ExigibilidadeISS/text()'
                 , Cnpj_Emit                VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Prestador/CpfCnpj/Cnpj/text()'
                 , CPF_Emit                 VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Prestador/CpfCnpj/Cpf/text()'
                 --, Entity_id                NUMBER            PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Prestador/InfTrad/xCodFornecedor/text()'
                 , InscricaoMunicipal_P     VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Prestador/InscricaoMunicipal/text()'
                 , Cnpj_Dest                VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Tomador/IdentificacaoTomador/CpfCnpj/Cnpj/text()'
                 , InscricaoMunicipal_Dest  VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Tomador/IdentificacaoTomador/InscricaoMunicipal/text()'
                 , RazaoSocial_Dest         VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Tomador/RazaoSocial/text()'
                 , Endereco_Dest            VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Tomador/Endereco/Endereco/text()'
                 , Numero_Dest              VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Tomador/Endereco/Numero/text()'
                 , Uf_DesT                  VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Tomador/Endereco/Uf/text()'
                 , Telefone_Dest            VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Tomador/Contato/Telefone/text()'
                 , Email_Dest               VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Tomador/Contato/Email/text()'
                 , xCodEstabTomador         VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Tomador/InfTrad/xCodEstabTomador/text()'
                 , xNomeEstabTomador        VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Tomador/InfTrad/xNomeEstabTomador/text()'
                 , OptanteSimplesNacional   VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/OptanteSimplesNacional/text()'
                 , IncentivoFiscal          VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/IncentivoFiscal/text()'
                 , Serv_list                VARCHAR2(150)     PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/ItemListaServico/text()'
                 , Itens                    XMLTYPE           PATH '/tcNfse/InfNfse/InfDeclaracaoPrestacaoServico/Servico/InfItem/InfTradItem'
                 ) xnfs
                 )
             LOOP
               --
               valid_org(nfse.Cnpj_Dest,g_ctrl.status);
               --
               IF nvl(g_ctrl.status,'X') <> 'E' THEN
                 Print('Processando');
                 Print('Numero_Nff           :'||nfse.Numero_Nff                  );
                 Print('CodigoVerificacao    :'||nfse.CodigoVerificacao           );
                 Print('DataEmissao          :'||nfse.DataEmissao                 );
                 Print('OutrasInformacoes    :'||nfse.OutrasInformacoes           );
                 Print('BaseCalculo          :'||nfse.BaseCalculo                 );
                 Print('ValorLiquidoNfse     :'||nfse.ValorLiquidoNfse            );
                 Print('ValorCredito         :'||nfse.ValorCredito                );
                 Print('Cnpj                 :'||nfse.Cnpj                        );
                 Print('CPF                  :'||nfse.CPF                         );
                 Print('InscricaoMunicipal   :'||nfse.InscricaoMunicipal          );
                 Print('RazaoSocial          :'||nfse.RazaoSocial                 );
                 Print('NomeFantasia         :'||nfse.NomeFantasia                );
                 Print('Endereco             :'||nfse.Endereco                    );
                 Print('Numero               :'||nfse.Numero                      );
                 Print('Bairro               :'||nfse.Bairro                      );
                 Print('Uf                   :'||nfse.Uf                          );
                 Print('Cep                  :'||nfse.Cep                         );
                 Print('Telefone             :'||nfse.Telefone                    );
                 Print('CodigoMunicipio      :'||nfse.CodigoMunicipio             );
                 Print('municipio            :'||nfse.municipio                   );
                 Print('Competencia          :'||nfse.Competencia                 );
                 Print('ValorServicos        :'||nfse.ValorServicos               );
                 Print('ValorDeducoes        :'||nfse.ValorDeducoes               );
                 Print('ValorPis             :'||nfse.ValorPis                    );
                 Print('ValorCofins          :'||nfse.ValorCofins                 );
                 Print('ValorInss_Servico    :'||nfse.ValorInss_Servico           );
                 Print('ValorIr              :'||nfse.ValorIr                     );
                 Print('ValorCsll            :'||nfse.ValorCsll                   );
                 Print('VlrIssRetido         :'||nfse.VlrIssRetido                );
                 Print('Aliquota AlqIssReti  :'||nfse.AlqIssRetido                );
                 Print('OutrasRetencoes      :'||nfse.OutrasRetencoes             );
                 Print('ValorIss             :'||nfse.ValorIss                    );
                 Print('DescontoIncondicion  :'||nfse.DescontoIncondicionado      );
                 Print('DescontoCondicionad  :'||nfse.DescontoCondicionado        );
                 Print('IssRetido            :'||nfse.IssRetido                   );
                 Print('CodigoMunicipio_Ser  :'||nfse.CodigoMunicipio_Ser         );
                 Print('Cnpj_Emit            :'||nfse.Cnpj_Emit                   );
                 Print('CPF_Emit             :'||nfse.CPF_Emit                    );
                 Print('InscricaoMunicipal_  :'||nfse.InscricaoMunicipal_P        );
                 Print('Cnpj_Dest            :'||nfse.Cnpj_Dest                   );
                 Print('InscricaoMunicipal_  :'||nfse.InscricaoMunicipal_Dest     );
                 Print('RazaoSocial_Dest     :'||nfse.RazaoSocial_Dest            );
                 Print('Endereco_Dest        :'||nfse.Endereco_Dest               );
                 Print('Numero_Dest          :'||nfse.Numero_Dest                 );
                 Print('Uf_DesT              :'||nfse.Uf_DesT                     );
                 Print('xnomemunicipio       :'||nfse.xnomemunicipio              );
                 Print('Telefone_Dest        :'||nfse.Telefone_Dest               );
                 Print('Email_Dest           :'||nfse.Email_Dest                  );
                 Print('xCodEstabTomador     :'||nfse.xCodEstabTomador            );
                 Print('xNomeEstabTomador    :'||nfse.xNomeEstabTomador           );
                 Print('OptanteSimplesNacio  :'||nfse.OptanteSimplesNacional      );
                 Print('IncentivoFiscal      :'||nfse.IncentivoFiscal             );
                 Print('Serv_list            :'||nfse.Serv_list                   );
               --
               -- Populando variavel
               --sa
                BEGIN
                  --
                  g_source.header_id                     := xxrmais_invoices_s.nextval ;
                  g_source.cliente_id                    := g_ctrl.id;
                  g_source.numero_nff                    := nfse.Numero_Nff;
                  g_ctrl.numero                          := nfse.numero_nff;
                  g_source.codigoverificacao             := nfse.CodigoVerificacao;
                  g_source.dataemissao                   := to_date(nfse.DataEmissao,'YYYY-MM-DD');
                  g_source.outrasinformacoes             := nfse.OutrasInformacoes;
                  g_source.basecalculo                   := nfse.BaseCalculo;
                  g_source.valorliquido                  := nfse.ValorLiquidoNfse;
                  g_source.valorcredito                  := nfse.ValorCredito;
                  g_source.cnpj_cpf                      := nvl(nfse.Cnpj,nfse.CPF);
                  g_source.inscricaomunicipal_emit       := nfse.InscricaoMunicipal;
                  g_source.razaosocial_emit              := nfse.RazaoSocial;
                  g_source.nomefantasia_emit             := nfse.NomeFantasia;
                  g_source.endereco_emit                 := nfse.Endereco;
                  g_source.numero_emit                   := nfse.Numero;
                  g_source.bairro_emit                   := nfse.Bairro;
                  g_source.uf_emit                       := nfse.Uf;
                  g_source.cep_emit                      := nfse.Cep;
                  g_source.telefone_emit                 := nfse.Telefone;
                  g_source.codigomunicipio_emit          := nfse.CodigoMunicipio;
                  g_source.municipio_emit                := nfse.municipio;
                  g_source.competencia                   := nfse.Competencia;
                  g_source.valorservicos                 := nfse.ValorServicos;
                  g_source.valordeducoes                 := nfse.ValorDeducoes;
                  g_source.valorpis                      := nfse.ValorPis;
                  g_source.valorcofins                   := nfse.ValorCofins;
                  g_source.valorinss_servico             := nfse.ValorInss_Servico;
                  g_source.valorir                       := nfse.ValorIr;
                  g_source.valorcsll                     := nfse.ValorCsll;
                  g_source.vlrissretido                  := nfse.VlrIssRetido;
                  g_source.alqissreti                    := nfse.AlqIssRetido;
                  g_source.outrasretencoes               := nfse.OutrasRetencoes;
                  g_source.valoriss                      := nfse.ValorIss;
                  g_source.descontoincondicio            := nfse.DescontoIncondicionado;
                  g_source.descontocondicio              := nfse.DescontoCondicionado;
                  g_source.issretido                     := nfse.IssRetido;
                  g_source.codigomunicipio_serv          := nfse.CodigoMunicipio_Ser;
                  g_source.inscricaomunicipal_dest       := nvl(nfse.InscricaoMunicipal_P , nfse.InscricaoMunicipal_Dest);
                  g_source.cnpj_dest                     := nvl(nfse.Cnpj_Dest,nfse.CPF_Emit);
                  g_source.razaosocial_dest              := nfse.RazaoSocial_Dest;
                  g_source.endereco_dest                 := nfse.Endereco_Dest;
                  g_source.numero_dest                   := nfse.Numero_Dest;
                  g_source.uf_dest                       := nfse.Uf_DesT;
                  g_source.nomemunicipio_dest            := nfse.xnomemunicipio;
                  g_source.telefone_dest                 := nfse.Telefone_Dest;
                  g_source.email_dest                    := nfse.Email_Dest;
                  g_source.codestabtomador               := nfse.xCodEstabTomador;
                  g_source.nomeestabtomador              := nfse.xNomeEstabTomador;
                  g_source.optantesimplesnacio           := nfse.OptanteSimplesNacional;
                  g_source.incentivofiscal               := nfse.IncentivoFiscal;
                  g_source.serv_code                     := get_cod_serv_expecific(nfse.CodigoMunicipio,nfse.Serv_list);
                  --
                  --get_cod_serv_expecific(nfse.CodigoMunicipio,nfse.Serv_list);
                  --
                  g_source.status                        := 'N';
                  --
                  g_ctrl.status := 'P';
                  --
                  --INSERT INTO xxrmais_invoices VALUES g_source;
                  -- Leitura Linhas
                  print(nfse.itens.getclobval());
                  --
                  FOR nfse_l IN ( SELECT '' Pedido
                                        , ROWNUM Line_num
                                        ,'' xCod_Produto
                                        ,xDes_Produto
                                        ,'' Uom
                                        ,Valor_Tot
                                        ,Valor_Un
                                        ,vQtde
                                   FROM XMLTABLE('/InfTradItem/tcInfTradItem'
                                PASSING nfse.itens
                                COLUMNS
                                       xDes_Produto     VARCHAR2(300) PATH '/tcInfTradItem/xDesProduto/text()'
                                      , vQtde           NUMBER        PATH '/tcInfTradItem/vQtde/text()'
                                      , Valor_Un        VARCHAR2(300) PATH '/tcInfTradItem/vValor/text()'
                                      , Valor_Tot       VARCHAR2(300) PATH '/tcInfTradItem/vValorTotal/text()'
                                      ) itm)
                    LOOP
                      --
                      Print('NFse_l.Pedido        :'||NFse_l.Pedido);
                      Print('NFse_l.Line_num      :'||NFse_l.Line_num);
                      Print('NFse_l.xCod_Produto  :'||NFse_l.xCod_Produto);
                      Print('NFse_l.xDes_Produto  :'||NFse_l.xDes_Produto);
                      Print('NFse_l.Uom           :'||NFse_l.Uom);
                      Print('NFse_l.Valor_Tot     :'||NFse_l.Valor_Tot);
                      Print('NFse_l.Valor_Un      :'||NFse_l.Valor_Un);
                      Print('NFse_l.vQtde         :'||NFse_l.vQtde);
                      --
                      --
                      g_source_l.line_id      := XXRMAIS_INVOICE_LINES_S.nextval;
                      g_source_l.header_id    := g_source.header_id;
                      g_source_l.line_num     := NFse_l.Line_num ;
                      g_source_l.cod_produto  := NFse_l.xCod_Produto ;
                      g_source_l.des_produto  := NFse_l.xDes_Produto;
                      g_source_l.pedido       := NFse_l.Pedido ;
                      g_source_l.uom          := NFse_l.Uom;
                      g_source_l.qtde         := NFse_l.vQtde;
                      g_source_l.valor_unit   := NFse_l.Valor_Un;
                      g_source_l.valor_total  := NFse_l.Valor_Tot;
                      --g_source_l.fiscal_classification   := get_cod_serv_expecific(nfse.CodigoMunicipio,nfse.Serv_list);
                      --
                      INSERT INTO xxrmais_invoice_lines VALUES g_source_l;
                      --
                    END LOOP;
                    --
                    g_ctrl.status := 'P';
                    --
                EXCEPTION WHEN OTHERS THEN
                  --
                  Print('Erro ao popular variais NFSE '||SQLERRM,1);
                  --
                END;
                --
               ELSE
                 --
                 Print('Cliente não cadastrado',1);
                 EXIT;
                 --
               END IF;
               --
             END LOOP;
  EXCEPTION WHEN OTHERS THEN
    Print('Error: Ao verificar XML: '||SQLERRM);
  END;  */
  --
  --SELECT * FROM apps.xxrmais_recebemais_source_ctrl WHERE control LIKE '%ABRASF%'
  --
        procedure process_xml (
            p_source_orig clob,
            p_ctrl_id     number default null
        ) as
    --
            l_xml       xmltype;
            xml_clob    clob;
            l_clob_decr clob;
    --
        begin
      --
            print('Iniciando leitura xml');
      --Print(p_source_orig);
            l_clob_decr := xxrmais_util_pkg.get_value_json('xml', p_source_orig);
      --
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
      --print('DECODE: '||l_clob_decr);
            exception
                when others then
                    print('Erro ao Decriptografar BASE64 ' || sqlerrm);
            end;
      --
      --print('xml: '||l_clob_decr);
            g_ctrl.process := xxrmais_util_pkg.get_value_json('process', p_source_orig);
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
                        nvl(cnpj_for, cpf_emit) cnpj_cpf
                    from
                        xmltable ( xmlnamespaces ( default 'http://www.portalfiscal.inf.br/nfe' ),
                        '/nfeProc'
                                passing xmltype(xml_clob)
                            columns
                                danfe varchar2(200) path '/nfeProc/protNFe/infProt/chNFe/text()',
                                serie varchar2(150) path '/nfeProc/NFe/infNFe/ide/serie/text()',
                                num_nf varchar2(150) path '/nfeProc/NFe/infNFe/ide/nNF/text()',
                                cnpj_for varchar2(200) path '/nfeProc/NFe/infNFe/emit/CNPJ/text()',
                                cpf_emit varchar2(200) path '/nfeProc/NFe/infNFe/emit/CPF/text()'
                        )
                ) loop
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
          --r.rCtrl.Danfe := rCte.Danfe;
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
                            update rmais_efd_headers
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
                        load_read_file_xml_nfse(xml_clob);
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
  --
        g_log := null;
        g_status := null;
  --
  --debug
  --g_test := '';
  --
        for reg_nf in (
            select
                *
            from
                rmais_ctrl_docs
            where
                    1 = 1--CASE WHEN p_id IS NULL THEN '1' ELSE status END = CASE WHEN p_id IS NULL THEN '1' ELSE 'N' END
                and nvl(status, 'N') = 'N'
                and id = nvl(p_id, id)
             -- AND ROWNUM <= 50
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
                    begin
            --
                        update rmais_ctrl_docs
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
                            process = g_ctrl.process
                        where
                            id = reg_nf.id;
          --
                    exception
                        when others then
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
                    update rmais_ctrl_docs
                    set
                        status = 'E',
                        log_process = g_log,
                        source_doc_decr = g_ctrl.source_doc_decr,
                        process_date = sysdate
                    where
                        id = reg_nf.id;

            end;
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
            update rmais_efd_headers
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
        l_cit_cod rmais_efd_headers.issuer_address_city_code%type;
  --
        l_andr    varchar2(600);
  --
    begin
    -- Desenvolvido somente NFse do WS da Prefeitura de São Paulo , usar parametros para desenvolver novas prefeituras
    --3505708 IBGE BARUERI
    --3550308 IBGE SP
        select
            rd.source_doc_decr,
            efdh.issuer_address_city_code
        into
            l_cxml,
            l_cit_cod
        from
            rmais_ctrl_docs   rd,
            rmais_efd_headers efdh
        where
                rd.id = efdh.doc_id
            and efdh.model = '00'
            and efdh.efd_header_id = p_id
            and nvl(document_type, 'X') <> 'MANUAL';
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
        xxrmais_util_v2_pkg.set_workflow(p_efd_header_id,
                                         'Reprocessamento de documento',
                                         nvl(
                         v('APP_USER'),
                         '-1'
                     ));
    --
        select
            doc_id
        into l_id
        from
            rmais_efd_headers
        where
            efd_header_id = l_efd_header_id;
    --
        delete rmais_efd_lines
        where
            efd_header_id = l_efd_header_id;
    --
        delete rmais_efd_headers
        where
            efd_header_id = l_efd_header_id;
    --
        update rmais_ctrl_docs
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
    procedure download_blob (
        p_file_id in number
    ) is
        v_blob_content blob;
        v_mime_type    varchar2(500);
        v_filename     varchar2(500);
    begin
      --
        select
            fileblob,
            mime_type,
            filename
        into
            v_blob_content,
            v_mime_type,
            v_filename
        from
            rmais_document_ctrl
        where
            id = p_file_id;
      --
        sys.htp.init;
        sys.owa_util.mime_header(v_mime_type, false);
        sys.htp.p('Content-Length: ' || dbms_lob.getlength(v_blob_content));
        sys.htp.p('Content-Disposition: filename="'
                  || v_filename || '"');
      --sys.OWA_UTIL.http_header_close;
        sys.wpg_docload.download_file(v_blob_content);
        apex_application.stop_apex_engine;
    exception
        when apex_application.e_stop_apex_engine then
            null;
    end;
  --
    procedure create_document (
        p_body    in blob,
        p_id      out number,
        p_stat    out integer,
        p_forward out varchar2
    ) as
  ---
        l_clob         clob := to_clob(p_body);
        l_id           number := rmais_document_ctrl_seq.nextval;
        l_linha        varchar2(50) := '0';
        l_sqlerrm      clob;
        l_rmh          rmais_efd_headers%rowtype;
        l_rml          rmais_efd_lines%rowtype;
        l_env_auto     varchar2(1);
        l_organization varchar2(180);
        l_tomador      number(1, 0);
  -- Robson 13/06/2023 Start
        l_table        varchar2(100);
        l_field        varchar2(100);
        l_value        varchar2(4000);
  --l_value_clob clob;
  -- Robson 13/06/2023 End
        vstatus        varchar2(10);
    begin
   --
   -- validacao
 /*  declare
   l_aux number(1);
    begin
        --
        /*
        SELECT max('D')
        into vStatus
        FROM TB_EMAILS_EXCEPTION
        WHERE email = json_value(l_clob,'$.EMAIL_SOURCE');
        --
        l_organization := upper(json_value(l_clob,'$.ORGANIZATION'));
       -- select 1 into l_aux from rmais_orgs where upper(nome) = l_organization;
        -- Select para verificação se a organização usa o envio automático ou não.
        select env_auto into l_env_auto from rmais_orgs where upper(nome) = l_organization;
        --
        if json_value(l_clob,'$.FILENAME') is null OR json_value(l_clob,'$.MIME_TYPE') is null or json_value(l_clob,'$.BASE64' returning clob)  is null then
            --
            p_stat := g_stat_inter_server_error;
            p_forward := 'Error: Identificado falta de informação em campo obrigatório';
            p_id := NULL;
            return;
            --
        end if;
        exception 
        when others then
            --
            l_sqlerrm := sqlerrm;
            insert into LOG_ERRO_FILE (NUMERO_NF,EMISSOR,BODY,MOMENTO,LINHA_ERRO,ERRO_SQLERRM)
                values(l_rmh.document_number,l_rmh.ISSUER_DOCUMENT_NUMBER,null,sysdate,l_linha,l_sqlerrm);

            p_stat := g_stat_inter_server_error;
            p_forward := 'Error: Cadastro da Organização não encontrado, entre em contato com a área técnica';
            p_id := NULL;
            --
            return;
            --
    end;
    
    */
    
    --
        insert into rmais_document_ctrl (
            id,
            source,
            organization,
            filename,
            mime_type,
            base64,
            fileblob,
            creation_date,
            last_updated_user,
            last_update_date,
                                    /*email_source,
                                    email_date,
                                    email_subject,
                                    email_body,*/
            body_request
        ) values ( l_id,
                   json_value(l_clob, '$.SOURCE'),
                   json_value(l_clob, '$.ORGANIZATION'),
                   json_value(l_clob, '$.FILENAME'),
                   json_value(l_clob, '$.MIME_TYPE'),
                   json_value(l_clob, '$.BASE64' returning clob),
                   base64decode_to_blob(json_value(l_clob, '$.BASE64' returning clob)),--'FILEBLOB',
                   sysdate,
                   null,--'LAST_UPDATED_USER',
                   null,
                                    /*json_value(l_clob,'$.EMAIL_SOURCE'),
                                    case when json_value(l_clob,'$.DATA_EMAIL') is not null then TO_DATE(json_value(l_clob,'$.DATA_EMAIL'),'YYYY/MM/DD HH24:MI:SS') else sysdate end,
                                    json_value(l_clob,'$.SUBJECT'),
                                    json_value(l_clob,'$.MSG_EMAIL' returning clob),*/
                   l_clob );
									
        --p_stat := nvl(p_stat,g_stat_created);
        p_forward := nvl(p_forward, 'Documento Criado');
        p_id := l_id;      
        
        
        --insert into log_hdi(id,BODY) values (l_id,l_clob);

        commit;
		
		
		
		
        --
        -- Inserir na tabela de digitação
        --        
        begin
          -- Alterado por Robson 13/06/2023
            l_table := 'rmais_efd_headers';
            l_linha := 'document_number';
            l_field := l_linha;
            l_value := regexp_replace(
                nvl(
                    json_value(l_clob, '$.DOCUMENT_NUMBER'),
                    json_value(l_clob, '$.NUMERO_NFF')
                ),
                '[^0-9]'
            );

            if xxrmais_util_pkg.valid_field_docs(l_id, l_linha, l_table, l_field,
                                                 p_valor => l_value) = 1 then
                l_rmh.document_number := ltrim(l_value, '0');
            end if;
          --
            l_linha := 'SERIES';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.SERIES'),
                json_value(l_clob, '$.SERIE')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.series := l_value;
            end if;
          --
            l_linha := 'MODEL_TYPE';
            l_field := 'MODEL';
            l_value := modelo_nf(json_value(l_clob, '$.MODEL_TYPE'));--case when json_value(l_clob,'$.MODEL_TYPE') = 'NFSE' then '00' else json_value(l_clob,'$.MODEL_TYPE') end;
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.model := l_value;
            end if;
          --
            l_linha := 'DATAEMISSAO';
            l_field := 'ISSUE_DATE';
            begin
                l_value := to_date ( nvl(
                    json_value(l_clob, '$.DATAEMISSAO'),
                    json_value(l_clob, '$.ISSUE_DATE')
                ),
                'YYYY-MM-DD' );--json_value(l_clob,'$.ISSUE_DATE');
            exception
                when others then
                    l_value := to_date ( nvl(
                        json_value(l_clob, '$.DATAEMISSAO'),
                        json_value(l_clob, '$.ISSUE_DATE')
                    ),
                    'DD/MM/YYYY' );--json_value(l_clob,'$.ISSUE_DATE');
            end;

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.issue_date := l_value;
            end if;
          --
            l_linha := 'VERIFICATION_CODE';
            l_field := 'COD_VERIF_NFS';
            l_value := nvl(
                json_value(l_clob, '$.VERIFICATION_CODE'),
                json_value(l_clob, '$.CODIGOVERIFICACAO')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.cod_verif_nfs := l_value;
            end if;
          --
            l_linha := 'ISSUER_NAME';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.ISSUER_NAME'),
                json_value(l_clob, '$.RAZAOSOCIAL_EMI')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.issuer_name := l_value;
            end if;
          --
            l_linha := 'ISSUER_DOCUMENT_NUMBER';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.ISSUER_DOCUMENT_NUMBER'),
                json_value(l_clob, '$.CNPJ_EMIT')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.issuer_document_number := l_value;
            end if;
          --
            l_linha := 'ISSUER_ADDRESS';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.ISSUER_ADDRESS'),
                json_value(l_clob, '$.ENDERECO_EMI')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.issuer_address := l_value;
            end if;
          --
            l_linha := 'ISSUER_COMPLE';
            l_field := 'ISSUER_ADDRESS_COMPLEMENT';
            l_value := json_value(l_clob, '$.ISSUER_COMPLE');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.issuer_address_complement := l_value;
            end if;
          --
            l_linha := 'ISSUER_ZIP_CODE';
            l_field := 'ISSUER_ADDRESS_ZIP_CODE';
            l_value := regexp_replace(
                nvl(
                    json_value(l_clob, '$.ISSUER_ZIP_CODE'),
                    json_value(l_clob, '$.CEP_EMI')
                ),
                '[^0-9]'
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.issuer_address_zip_code := l_value;
            end if;
          --
            l_linha := 'ISSUER_ADDRESS_NUMBER';
            l_field := l_linha;
            l_value := regexp_replace(
                nvl(
                    json_value(l_clob, '$.ISSUER_ADDRESS_NUMBER'),
                    json_value(l_clob, '$.NUMERO_EMI')
                ),
                '[^0-9]'
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.issuer_address_number := l_value;
            end if;
          ---
            l_linha := 'ISSUER_ADDRESS_STATE';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.ISSUER_ADDRESS_STATE'),
                json_value(l_clob, '$.UF_EMI')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.issuer_address_state := l_value;
            end if;
          --
            l_linha := 'ISSUER_CITY_NAME';
            l_field := 'ISSUER_ADDRESS_CITY_NAME';
            l_value := json_value(l_clob, '$.ISSUER_CITY_NAME');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.issuer_address_city_name := l_value;
            end if;
          --
            l_linha := 'ISSUER_EMAIL';
            l_field := 'email';
            l_value := json_value(l_clob, '$.ISSUER_EMAIL');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.email := l_value;
            end if;
          --
            l_linha := 'RECEIVER_NAME';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.RECEIVER_NAME'),
                json_value(l_clob, '$.RAZAOSOCIAL_DEST')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.receiver_name := l_value;
            end if;
          --
            l_linha := 'RECEIVER_DOCUMENT_NUMBER';
            l_field := l_linha;
            l_value := regexp_replace(
                nvl(
                    json_value(l_clob, '$.RECEIVER_DOCUMENT_NUMBER'),
                    json_value(l_clob, '$.CNPJ_DEST')
                ),
                '[^0-9]'
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.receiver_document_number := l_value;
            end if;
          --
            l_linha := 'RECEIVER_ADDRESS';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.RECEIVER_ADDRESS'),
                json_value(l_clob, '$.ENDERECO_DEST')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.receiver_address := l_value;
            end if;
          --
            l_linha := 'RECEIVER_COMPLE';
            l_field := 'RECEIVER_ADDRESS_COMPLEMENT';
            l_value := json_value(l_clob, '$.RECEIVER_COMPLE');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.receiver_address_complement := l_value;
            end if;
          --
            l_linha := 'RECEIVER_ZIP_CODE';
            l_field := 'RECEIVER_ADDRESS_ZIP_CODE';
            l_value := regexp_replace(
                json_value(l_clob, '$.RECEIVER_ZIP_CODE'),
                '[^0-9]'
            );
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.receiver_address_zip_code := l_value;
            -- l_rmh.RECEIVER_ADDRESS_ZIP_CODE   := json_value(l_clob,'$.RECEIVER_BAIRRO');
            end if;
          --
            l_linha := 'RECEIVER_ADDRESS_NUMBER';
            l_field := l_linha;
            l_value := regexp_replace(
                nvl(
                    json_value(l_clob, '$.RECEIVER_ADDRESS_NUMBER'),
                    json_value(l_clob, '$.NUMERO_DEST')
                ),
                '[^0-9]'
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.receiver_address_number := l_value;
            end if;
          --
            l_linha := 'RECEIVER_ADDRESS_STATE';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.RECEIVER_ADDRESS_STATE'),
                json_value(l_clob, '$.UF_DEST')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.receiver_address_state := l_value;
            end if;
          --
            l_linha := 'RECEIVER_ADDRESS_CITY_NAME';
            l_field := l_linha;
            l_value := json_value(l_clob, '$.RECEIVER_CITY_NAME');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.receiver_address_city_name := l_value;
            end if;
          --
            l_linha := 'COFINS_AMOUNT';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.COFINS_AMOUNT'),
                json_value(l_clob, '$.VALORCOFINS')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.cofins_amount := l_value;
            end if;
          --
            l_linha := 'PIS_AMOUNT';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.PIS_AMOUNT'),
                json_value(l_clob, '$.VALORPIS')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.pis_amount := l_value;
            end if;
          --
            l_linha := 'CSLL_AMOUNT';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.CSLL_AMOUNT'),
                json_value(l_clob, '$.VALORCSLL')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.csll_amount := l_value;
            end if;
          --
            l_linha := 'INSS_BASE';
            l_field := l_linha;
            l_value := json_value(l_clob, '$.INSS_BASE');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.inss_base := l_value;
            end if;
          --
            l_linha := 'INSS_TAX';
            l_field := l_linha;
            l_value := json_value(l_clob, '$.INSS_RATE');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.inss_tax := l_value;
            end if;
          --
            l_linha := 'INSS_AMOUNT';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.INSS_AMOUNT'),
                json_value(l_clob, '$.VALORINSS_SERVICO')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.inss_amount := l_value;
            end if;
          --
            l_linha := 'IR_BASE';
            l_field := l_linha;
            l_value := json_value(l_clob, '$.IR_BASE');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.ir_base := l_value;
            end if;
          --
            l_linha := 'IR_TAX';
            l_field := l_linha;
            l_value := json_value(l_clob, '$.IR_RATE');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.ir_tax := l_value;
            end if;
          --
            l_linha := 'IR_AMOUNT';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.IR_AMOUNT'),
                json_value(l_clob, '$.VALORIR')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.ir_amount := l_value;
            end if;
          --
            l_linha := 'ISS_BASE';
            l_field := l_linha;
            l_value := json_value(l_clob, '$.ISS_BASE');
         -- if VALID_FIELD_DOCS(l_id,l_linha,l_table,l_field,P_VALOR => l_value) = 1 then
         --   l_rmh.ISS_BASE := l_value;
        --  end if;
          --
            l_linha := 'ISS_TAX';
            l_field := l_linha;
            l_value := json_value(l_clob, '$.ISS_RATE');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.iss_tax := l_value;
            end if;
          --
            l_linha := 'ISS_AMOUNT';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.ISS_AMOUNT'),
                json_value(l_clob, '$.VALORISS')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.iss_amount := l_value;
            end if;
          --
            l_linha := 'ADDITIONAL_INFORMATION';
            l_field := l_linha;
            l_value := json_value(l_clob, '$.OUTRAS_INFORMACOES');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.additional_information := l_value;
            end if;
          --
            l_linha := 'total_amount';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.TOTAL_AMOUNT'),
                json_value(l_clob, '$.VALORSERVICOS')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.total_amount := l_value;
            end if;
          
          --
            l_linha := 'DOC_SOURCE';
            l_field := l_linha;
            l_value := json_value(l_clob, '$.SOURCE');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.source := l_value;
            end if;
          --
            l_linha := 'ISS_RET_FLAG';
            l_field := l_linha;
            l_value :=
                case
                    when nvl(
                        json_value(l_clob, '$.ISS_RET_FLAG'),
                        'S'
                    ) in ( 'Y', 'N' ) then
                        json_value(l_clob, '$.ISS_RET_FLAG')
                    else
                        null
                end;

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rmh.iss_ret_flag := l_value;
            end if;

            l_rmh.creation_date := sysdate;
          --l_linha := 'CREATED_BY';
            l_rmh.created_by := -1;
          --l_linha := 'LAST_UPDATE_DATE';
            l_rmh.last_update_date := sysdate;
          --l_linha := 'LAST_UPDATED_BY';
            l_rmh.last_updated_by := -1;
          
          
          
          
          --========================================================================================================
            l_linha := 'efd_header_id';
            l_rml.efd_header_id := l_id;
            l_linha := 'line_number';
            l_rml.line_number := 1;
          --
            l_table := 'rmais_efd_lines';
            l_linha := 'line_amount';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.TOTAL_AMOUNT'),
                json_value(l_clob, '$.VALORSERVICOS')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rml.line_amount := l_value;
            end if;
          --
            l_linha := 'line_quantity';
            l_field := l_linha;
            l_value := 1;
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rml.line_quantity := l_value;
            end if;
          --
            l_linha := 'unit_price';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.TOTAL_AMOUNT'),
                json_value(l_clob, '$.VALORSERVICOS')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rml.unit_price := l_value;
            end if;
          --
            l_linha := 'source_doc_number';
            l_rml.source_doc_number := null;
          --
            l_linha := 'item_code';
            l_rml.item_code := null;
          --
            l_linha := 'item_description';
            l_field := l_linha;
            l_value := nvl(
                json_value(l_clob, '$.DISCRIMICACAO'),
                json_value(l_clob, '$.DISCRIMINACAO_NF')
            );

            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rml.item_description := l_value;
            end if;
          --
          /*Verificar Cristiano
          l_linha := 'fiscal_classification';
          l_field := l_linha;
          l_value := COD_LISTA_SERVICOS(nvl(json_value(l_clob,'$.COD_SERV'),json_value(l_clob,'$.SERV_LIST')));--get_cod_serv_expecific(rRegh.CodigoMunicipio,rRegh.Serv_list); 07.01 7.01
          if VALID_FIELD_DOCS(l_id,l_linha,l_table,l_field,P_VALOR => l_value) = 1 then
            -- l_rml.city_service_type_rel_code := get_cod_serv_expecific(rRegh.CodigoMunicipio,rRegh.Serv_list);
            l_rml.fiscal_classification := l_value;
          end if;
          */
          
          --
            l_linha := 'efd_line_id';
          --
            l_rml.efd_line_id := rmais_efd_lines_s.nextval;
            l_linha := 'creation_date';
          --
            l_rml.creation_date := sysdate;
            l_linha := 'CREATED_BY';
            l_rml.created_by := -1;
            l_linha := 'LAST_UPDATE_DATE';
            l_rml.last_update_date := sysdate;
            l_linha := 'LAST_UPDATED_BY';
            l_rml.last_updated_by := -1;
          --
          /*Verificar Cristiano
          begin
            l_rmh.email_date :=  TO_DATE(json_value(l_clob,'$.DATA_EMAIL'),'YYYY/MM/DD HH24:MI:SS');
            exception
            when others then
                null;
          end;
          */
          --
            l_linha := 'ACCOUNT_CC';
            l_field := l_linha;
            l_value := json_value(l_clob, '$.ACCOUNT_CC');
            if valid_field_docs(l_id, l_linha, l_table, l_field,
                                p_valor => l_value) = 1 then
                l_rml.account_cc := l_value;
            end if;
          --
            begin
            --
                l_rmh.efd_header_id := l_id;
            
            
           -- frow

                l_rmh.access_key_number := l_rmh.efd_header_id;
                l_rmh.access_key_number := get_access_key_number(l_rmh.receiver_document_number, l_rmh.issuer_document_number, l_rmh.issue_date
                , l_rmh.document_number);

            
            --
            /*Verificar Cristiano
            select nvl(max(1),0) into l_tomador from rmais_tomadores_orgs where cnpj_to = l_rmh.RECEIVER_DOCUMENT_NUMBER and nome_to = l_organization;
            */
            
            
            --select count(*) into l_tomador from rmais_tomadores_orgs where cnpj_to = l_rmh.RECEIVER_DOCUMENT_NUMBER and nome_to = l_organization;
            --teste chamadas forçando entrada
            --l_tomador := 0;
            -- fim teste
            
            /*Verificar Cristiano*/
                if l_tomador > 0 then
                    << verificacao_possui_tomador >> if l_rmh.document_number is null
                                                        or ( l_rmh.model is null
                                                             or l_rmh.model not in ( 'NFSE', '00' ) )
                    or l_rmh.issue_date is null
                    or l_rmh.issuer_name is null
                    or l_rmh.issuer_document_number is null
                    or l_rmh.issuer_address_state is null
                    or l_rmh.receiver_name is null
                    or l_rmh.receiver_document_number is null
                    or l_rmh.receiver_address_state is null
                    or l_rmh.cofins_amount is null
                    or l_rmh.pis_amount is null
                    or l_rmh.csll_amount is null
                    or l_rmh.inss_amount is null
                    or l_rmh.ir_amount is null
                    or l_rmh.iss_amount is null
                    or l_rmh.total_amount is null
                    or l_rml.item_description is null
                    or l_rml.fiscal_classification is null then
                  -- 
                        if l_rmh.document_number is not null
                           or l_rmh.model is not null
                        or l_rmh.issue_date is not null
                        or l_rmh.issuer_name is not null
                        or l_rmh.issuer_document_number is not null
                        or l_rmh.issuer_address_state is not null
                        or l_rmh.receiver_name is not null
                        or l_rmh.receiver_document_number is not null
                        or l_rmh.receiver_address_state is not null
                        or l_rmh.cofins_amount is not null
                        or l_rmh.pis_amount is not null
                        or l_rmh.csll_amount is not null
                        or l_rmh.inss_amount is not null
                        or l_rmh.ir_amount is not null
                        or l_rmh.iss_amount is not null
                        or l_rmh.total_amount is not null
                        or l_rml.item_description is not null
                        or l_rml.fiscal_classification is not null
                        or l_rml.fiscal_classification is not null then
                     --
                     --frow
                            l_rmh.document_status := nvl(vstatus, 'I'); -- 

                    --
                        else
                     --
                            l_rmh.document_status := nvl(vstatus, 'N'); --
                     --
                        end if;              
                  --
                    else
                  --
                        if l_env_auto = 'Y' then
                            l_rmh.document_status := nvl(vstatus, 'CD');-- todos os campos preeeenchidos.
                        else
                            l_rmh.document_status := nvl(vstatus, 'PE');-- Pendente de envio para empresas que não querem automatico.
                        end if;
                  --
                    end if;
                else
                    if l_rmh.document_number is not null
                       or l_rmh.model is not null
                    or l_rmh.issue_date is not null
                    or l_rmh.issuer_name is not null
                    or l_rmh.issuer_document_number is not null
                    or l_rmh.issuer_address_state is not null
                    or l_rmh.receiver_name is not null
                    or l_rmh.receiver_document_number is not null
                    or l_rmh.receiver_address_state is not null
                    or l_rmh.cofins_amount is not null
                    or l_rmh.pis_amount is not null
                    or l_rmh.csll_amount is not null
                    or l_rmh.inss_amount is not null
                    or l_rmh.ir_amount is not null
                    or l_rmh.iss_amount is not null
                    or l_rmh.total_amount is not null
                    or l_rml.item_description is not null
                    or l_rml.fiscal_classification is not null
                    or l_rml.fiscal_classification is not null then
                     --
                        l_rmh.document_status := nvl(vstatus, 'I'); -- 
                     --
                    else
                     --
                        l_rmh.document_status := nvl(vstatus, 'N'); --
                     --
                    end if;
                end if;-- "verificacao_possui_tomador";
            --
                insert into rmais_efd_headers values l_rmh;
            --
                commit;
            --RMAIS_UTIL_PKG.create_workflow (p_efd_header_id => l_id,p_status_nf => l_rmh.document_status,p_usuario => 'AUTOMATE',p_flag => 'GA',p_duvida_resposta => null);
            --
                insert into rmais_efd_lines values l_rml; 
            -- metricas automação 12/07/2024
            
             /*Verificar Cristiano
            if l_rmh.document_status in ('PE','CD','I') then
                insert into TB_NOTAS_AUTOMATE values(l_rml.efd_header_id,'ITEM_DESCRIPTION',substr(l_rml.ITEM_DESCRIPTION,1,4000),substr(l_rml.ITEM_DESCRIPTION,1,4000),1);
                insert into TB_NOTAS_AUTOMATE values(l_rml.efd_header_id,'FISCAL_CLASSIFICATION',l_rml.FISCAL_CLASSIFICATION,l_rml.FISCAL_CLASSIFICATION,1);
                insert into TB_NOTAS_AUTOMATE values(l_rml.efd_header_id,'LINE_QUANTITY',substr(l_rml.LINE_QUANTITY,1,4000),substr(l_rml.LINE_QUANTITY,1,4000),1);
                insert into TB_NOTAS_AUTOMATE values(l_rml.efd_header_id,'UNIT_PRICE',l_rml.UNIT_PRICE,l_rml.UNIT_PRICE,1);
            end if;
            */
            
            
            -- fim metricas automaçao
                update rmais_document_ctrl
                set
                    status = l_rmh.document_status
                where
                    id = l_id;
             --
            end;
          --
        end;

		

          --
    exception
        when others then
            rollback;
    --Excluir documento da control quando o mesmo tem erros
            delete from rmais_document_ctrl
            where
                id = l_id;

            commit;
            l_sqlerrm := sqlerrm;
   -- insert into LOG_ERRO_FILE (NUMERO_NF,EMISSOR,BODY,MOMENTO,LINHA_ERRO,ERRO_SQLERRM)
   --                     values(l_rmh.document_number,l_rmh.ISSUER_DOCUMENT_NUMBER,null,sysdate,l_linha,l_sqlerrm);
    --
   -- p_stat := g_stat_inter_server_error;
            p_forward := 'Error: ' || sqlerrm;
            p_id := null;
    --
    end create_document;
  --
    function valid_field_docs (
        p_id           number,
        p_field_source varchar2,
        p_table        varchar2,
        p_field        varchar2,
        p_valor        varchar2 default null,
        p_clob         clob default null
    ) return number is
        nr number;
    begin
        nr := verif_campo(
            p_table => p_table,
            p_field => p_field,
            p_valor => p_valor,
            p_clob  => p_clob
        );

        if nr = 0 then
            insert into rmais_document_ctrl_err (
                id,
                table_err,
                field_err,
                val_varchar,
                val_clob,
                data
            ) values ( p_id,
                       p_table,
                       p_field_source,
                       p_valor,
                       p_clob,
                       current_date );

        end if;

        return nr;
    end;
  --
    function verif_campo (
        p_table varchar2,
        p_field varchar2,
        p_valor varchar2 default null,
        p_clob  clob default null
    ) return number is
        vsql varchar2(4000);
    begin
        if p_valor is not null
           or length(p_clob) > 0 then
            vsql := 'declare tb '
                    || p_table
                    || '%rowtype; begin tb.'
                    || p_field
                    || ' := '
                    ||
                case
                    when length(trim(translate(p_valor, '.,+-0123456789', ' '))) is null then
                        p_valor || '; end;'
                    when p_clob is not null then
                        ''''
                        || p_clob
                        || '''; end;'
                    when p_valor is not null then
                        ''''
                        || p_valor
                        || '''; end;'
                end;

            execute immediate vsql;
            dbms_output.put_line(p_field
                                 || ' -> ' || p_valor);
        end if;

        return 1;
    exception
        when others then
            return 0;
    end;
    --
    function modelo_nf (
        modelo in varchar2 default null
    ) return varchar2 is
        tam number;
    begin
        tam := length(modelo);
        return
            case
                when tam > 4         then
                        case
                            when replace(
                                upper('Nota Fiscal de Serviços Eletrônico - NFS-e'),
                                'Ç',
                                'C'
                            ) like '%SERVICO%' then
                                '00'
                            else
                                null
                        end
                when modelo = 'NFSE' then
                    '00'
                else
                    modelo
            end;

    end;

end xxrmais_util_pkg;
/


-- sqlcl_snapshot {"hash":"415a800ca0ed30cc2fab8f47b84d85992dc8f4b0","type":"PACKAGE_BODY","name":"XXRMAIS_UTIL_PKG","schemaName":"RMAIS","sxml":""}