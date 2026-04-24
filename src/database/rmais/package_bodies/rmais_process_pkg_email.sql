create or replace package body "rmais_process_pkg_email" as
    --
    
    --
    procedure ins_log (
        p_msg varchar2
    ) is
        pragma autonomous_transaction;
    begin
    --
        null;
    --INSERT INTO rmais_log VALUES (systimestamp,substr(p_msg,1,3700));COMMIT;
    --
    end;
  --
    procedure print (
        p_msg varchar2
    ) is
    begin
    --
        ins_log(p_msg);
    --
        rmais_global_pkg.print(p_msg);
    --
    end print;
  --
    function text2base64 (
        p_txt   in varchar2,
        p_encod in varchar2 default null
    ) return varchar2 is
    begin
        return utl_encode.text_encode(p_txt, p_encod, utl_encode.base64);
    end;
  --
    function base642text (
        p_txt   in varchar2,
        p_encod in varchar2 default null
    ) return varchar2 is
    begin
        return utl_encode.text_decode(p_txt, p_encod, utl_encode.base64);
    end;
  -- Victor 10/03/2021
    function get_cfop_lin_type (
        p_cfop varchar2
    ) return varchar2 is
        l_aux number;
    begin
    --
        select
            1
        into l_aux
        from
            rmais_cfop_define
        where
                tipo = 'RETORNO/REMESSA'
            and cfop = p_cfop
            or p_cfop is null;
    --
        return 'NA';
    --
    exception
        when others then
    --
            return 'PO';
    --
    end;
  --
    procedure get_item_erp (
        p_cnpj_fornecedor       in varchar2,
        p_cnpj_tomador          in varchar2,
        p_item_desc             in varchar2,
        p_item_ncm              in varchar2,
        p_item_code_efd         out varchar2,
        p_item_descr_efd        out varchar2,
        p_uom                   out varchar2,
        p_uom_desc              out varchar2,
        p_fiscal_classification out varchar2,
        p_catalog_code_ncm      out varchar2,
        p_item_type             out varchar2,
        p_combination_descr     out varchar2,
        p_icms_rate             out varchar2,
        p_user_defined          out varchar2,
        p_cfop_from             out varchar2,
        p_cfop_to               out varchar2,
        p_withholding           out varchar2
    ) as
    --
        l_ret varchar2(400);
    --
    begin
      --
        select
            item_code_efd,
            item_descr_efd,
            uom_to,
            uom_to_desc,
            fiscal_classification_to,
            catalog_code_ncm,
            item_type,
            combination_descr,
            icms_rate,
            user_defined,
            cfop_to,
            cfop_from,
            withholding
        into
            p_item_code_efd,
            p_item_descr_efd,
            p_uom,
            p_uom_desc,
            p_fiscal_classification,
            p_catalog_code_ncm,
            p_item_type,
            p_combination_descr,
            p_icms_rate,
            p_user_defined,
            p_cfop_from,
            p_cfop_to,
            p_withholding
    --
        from
            rmais_get_util_item
        where
                fornecedor = p_cnpj_fornecedor
            and tomador = p_cnpj_tomador
            and ( ( to_char(p_item_ncm) is not null
                    and fiscal_classification = to_char(p_item_ncm) )
                  or item_description = p_item_desc )
       --AND item_description = p_item_desc
            and rownum = 1;
      --
    exception
        when others then
      --
            print('aqui deu erro => ' || sqlerrm);
            null;
      --
    end get_item_erp;
  --
    function get_status_lines (
        p_efd_header_id number
    ) return varchar2 is
        l_aux varchar2(100);
    begin
        for rlin in (
            select
                status
            from
                rmais_efd_lines
            where
                efd_header_id = p_efd_header_id
        ) loop
            if l_aux is null then
                l_aux := rlin.status;
            else
          --
                if l_aux <> rlin.status then
            --
                    return 'DIF';
            --
                end if;
          --
            end if;
        --
        end loop;
      --
        return l_aux;
      --
    exception
        when others then
            return 'DIF';
    end;
  --
    function get_item_na (
        p_cnpj_fornecedor varchar2,
        p_item_code       varchar2
    ) return varchar2 is

        l_url      varchar2(100) := '/api/report/item/getPartnerItems';
        l_response varchar2(4000);
        l_body     varchar2(500);
    begin
    --
        l_body := '{"cnpj_fornecedor" : "'
                  || p_cnpj_fornecedor
                  || '","item_code" : "'
                  || p_item_code
                  || '"}';
    --
        l_response := json_value(rmais_process_pkg_email.get_response(l_url, l_body),
           '$.DATA.ITEM_ORACLE');
    --
        return l_response;
    --
    exception
        when others then
            return '';
    end get_item_na;
    --
    procedure log_efd (
        p_msg in varchar2,
        p_lin in number,
        p_hea in number,
        p_typ in varchar2 default null
    ) is
    --
    begin
        --
        print(p_msg
              || ' '
              || p_hea
              || ' ' || p_lin);
        --
        rmais_process_pkg_email.g_log_workflow := rmais_process_pkg_email.g_log_workflow
                                                  || p_msg
                                                  || '<br>';
        --
        insert into rmais_efd_lin_valid (
            efd_header_id,
            efd_line_id,
            type,
            message_text,
            creation_date
        ) values ( p_hea,
                   p_lin,
                   p_typ,
                   p_msg,
                   sysdate );
        --
    exception
        when others then
            print('Insert Log ' || sqlerrm);
            --
    end log_efd;
    --
    procedure delete_efd (
        p_key varchar2
    ) is
    begin
    --
        for r in (
            select
                l.*
            from
                rmais_efd_headers h,
                rmais_efd_lines   l
            where
                    h.efd_header_id = l.efd_header_id
                and h.access_key_number = p_key
        ) loop
      --
            delete from rmais_efd_distributions
            where
                efd_line_id = r.efd_line_id;
      --
            print('Del Dist: ' || sql%rowcount);
      --
            delete from rmais_efd_shipments
            where
                efd_line_id = r.efd_line_id;
      --
            print('Del Ship: ' || sql%rowcount);
      --
            delete from rmais_efd_lines
            where
                efd_line_id = r.efd_line_id;
      --
            print('Del Line: ' || sql%rowcount);
      --
            delete from rmais_efd_headers
            where
                efd_header_id = r.efd_header_id;
      --
            print('Del Head: ' || sql%rowcount);
      --
        end loop;
    --
    end;
  --
    procedure log_del (
        p_id number
    ) is
    begin
    --
        delete from rmais_efd_lin_valid
        where
            efd_header_id = p_id;
    --
    end;
  --
  /*PROCEDURE insert_head(p_efd IN OUT rmais_efd_headers%ROWTYPE) IS
  BEGIN
    --
    p_efd.efd_header_id     := rmais_efd_headers_s.nextval;
    p_efd.Creation_Date     := sysdate;
    p_efd.Last_Update_Date  := sysdate;
  p_efd.Created_By        := x_user_id;
    p_efd.Last_Updated_By   := x_user_id;
    p_efd.Last_Update_Login := x_login_id;
    --
    Delete_efd(p_efd.access_key_number);
    --
    INSERT INTO rmais_efd_headers VALUES p_efd;
    --
    Print('EFD Header inserted');
    --
  END;
  --
  PROCEDURE insert_head(pSource IN OUT r$source) IS
  BEGIN
    --
    insert_head(pSource.rHea);
    --
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line( 'insert_efd_h '||SQLERRM);
  END;
  --
  
  PROCEDURE insert_line(p_efd IN OUT rmais_efd_lines%ROWTYPE) IS
  BEGIN
    --
    p_efd.efd_line_id       := rmais_efd_lines_s.nextval;
    p_efd.efd_header_id     := nvl(p_efd.efd_header_id, rmais_efd_headers_s.currval);
    p_efd.Creation_Date     := x_sysdate;
    p_efd.Last_Update_Date  := x_sysdate;
  --p_efd.Created_By        := x_user_id;
    p_efd.Last_Updated_By   := x_user_id;
    p_efd.Last_Update_Login := x_login_id;*/
    --
    /*
    INSERT INTO rmais_efd_lines VALUES p_efd;
    --
    Print('EFD Line inserted');
    --
  END;
  --
  PROCEDURE insert_line(pNF IN OUT r$source) IS
  BEGIN
    --
    FOR x IN pNF.rLin.first..pNF.rLin.last LOOP
      --
      pNF.rLin(x).rLin.efd_header_id := pNF.rHea.efd_header_id;
      --
      insert_line(pNF.rLin(x).rLin);
      --
    END LOOP;
    --
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line( 'insert_efd_l '||SQLERRM);
  END;
  
  PROCEDURE insert_taxes(p_tax IN OUT NOCOPY rmais_efd_taxes%ROWTYPE) IS
  BEGIN
    --
    p_tax.id := rmais_efd_taxes_s.nextval;
    p_tax.Creation_Date := sysdate;
    p_tax.Update_Date   := sysdate;
    --
    INSERT INTO rmais_efd_taxes VALUES p_tax;
    --
  EXCEPTION
    WHEN OTHERS THEN
      Print('Insert Shipments ERROR: '||SQLERRM);
  END;
  */
  --
    procedure insert_ship (
        p_ship in out nocopy rmais_efd_shipments%rowtype
    ) is
    begin
    --
        if p_ship.source_doc_shipment_id is not null then
      --
            p_ship.efd_shipment_id := rmais_efd_shipments_s.nextval;
            p_ship.creation_date := sysdate;
            p_ship.last_update_date := sysdate;
            p_ship.created_by := 0;
            p_ship.last_updated_by := 0;
            p_ship.last_update_login := 0;
      --
            insert into rmais_efd_shipments values p_ship;
      --
        end if;
    --
    exception
        when others then
            print('Insert Shipments ERROR: ' || sqlerrm);
    end;
  --
    procedure ins_issuer (
        p_taxpayer rmais_issuer_info%rowtype
    ) is
    begin
    --
    --Print('Inserting Issuer '||p_taxpayer.cnpj||chr(10)||'DOCS: '||p_taxpayer.docs||chr(10)||'INFO: '||p_taxpayer.info);
    --
    --INSERT INTO rmais_issuer_info VALUES p_taxpayer;
    --
        update rmais_issuer_info
        set
            info = p_taxpayer.info
        where
                cnpj = p_taxpayer.cnpj
            and receiver = p_taxpayer.receiver;

        if sql%rowcount = 0 then
            insert into rmais_issuer_info values p_taxpayer;

        end if;
    exception
        when others then
    --
            print('Erro ao inserir rmais_issuer_info: ' || sqlerrm);
    --
    end;
  --
    procedure ins_receiv (
        p_taxpayer rmais_receiver_info%rowtype
    ) is
    begin
    --
        insert into rmais_receiver_info values p_taxpayer;
    --
    end;
  --
    function ins_ws_info (
        p_trx_method in varchar2 default null
    ) return number is
        l_return number;
    begin
    --
        insert into rmais_ws_info (
            transaction_id,
            transaction_method,
            clob_info,
            blob_info,
            creation_date,
            created_by,
            update_date,
            updated_by
        ) values ( to_char(systimestamp, 'rrrrmmddhh24missff'),
                   p_trx_method,
                   null,
                   null,
                   sysdate,
                   nvl(
                       v('app_user'),
                       user
                   ),
                   sysdate,
                   nvl(
                       v('app_user'),
                       user
                   ) ) returning transaction_id into l_return;
    --
        return l_return;
    --
    exception
        when others then
            return -1;
    end;
  --
    procedure set_ws_info (
        p_trx_id   in number,
        p_trx_info in clob default null--, p_trx_return OUT NOCOPY NUMBER
    ) is
    begin
    --
        update rmais_ws_info
        set
            clob_info = p_trx_info
        where
            transaction_id = p_trx_id;
    --
    --p_trx_return := 200;
    --
    exception
        when others then
            null;--p_trx_return := 400;
    end;
  --
    procedure set_ws_info (
        p_trx_id     in number,
        p_trx_info   in blob,
        p_trx_return out nocopy number
    ) is
    begin
    --
        update rmais_ws_info
        set
            blob_info = p_trx_info
        where
            transaction_id = p_trx_id;
    --
        p_trx_return := 200;
    --
    exception
        when others then
            p_trx_return := 400;
    end;
  --

    procedure set_po_array (
        p_fornec in varchar2,
        p_receiv in varchar2,
        p_po     in out nocopy t$po
    ) is
    --
        r_issuer  rmais_issuer_info%rowtype;
    --
        l_body_po varchar2(500);
    --
        procedure setpo is
            cursor c_po is
            select
                *
            from
                rmais_issuer_info_v
            where
                    receiver = p_receiv
                and cnpj = p_fornec;
      --
        begin
      --
            open c_po;
            fetch c_po
            bulk collect into p_po;
      --
        end;
    --
    begin
    --
        l_body_po :=
            json_object(
                'cnpj_tomador' value p_receiv,
                        'cnpj_fornecedor' value p_fornec,
                        'data_promessa_inicial' value to_char(
                    add_months(sysdate, -6),
                    'dd/mm/rrrr'
                ),
                        'data_promessa_final' value to_char(
                    add_months(sysdate, 6),
                    'dd/mm/rrrr'
                )
            );
    --
        setpo;
    --
        if p_po.count = 0 then
      --
            r_issuer.info := rmais_process_pkg_email.get_taxpayer(p_fornec, 'ISSUER');
            r_issuer.docs := rmais_process_pkg_email.get_po_list(l_body_po);
            r_issuer.cnpj := p_fornec;
            r_issuer.receiver := p_receiv;
      --
            rmais_process_pkg_email.ins_issuer(r_issuer);
      --
            setpo;
      --
        end if;
    --
    exception
        when others then
            print('Set PO ERROR: ' || sqlerrm);
    end;
  --

    procedure insert_ws_info (
        p_id     in out number,
        p_method varchar2 default 'GET_PO',
        p_clob   clob default null
    ) as
        l_id number;
    begin
      --
        p_id := nvl(p_id, rmais_ws_info_s.nextval);
      --
        insert into rmais_ws_info (
            transaction_id,
            transaction_method,
            clob_info,
            creation_date,
            created_by
        ) values ( p_id,
                   p_method,
                   p_clob,
                   sysdate,
                   'WS' );
      --
        commit;
      --
    exception
        when others then
      --
            dbms_output.put_line(sqlerrm);
      --
    end insert_ws_info;
  --
    function set_transaction_po_arrays (
        p_fornec         in varchar2,
        p_receiv         in varchar2,
        p_trasanction_id number
    ) return number as
    --
        l_body_po varchar2(4000);
    --
        l_return  varchar2(4000);
    --
    begin
      --
        l_body_po :=
            json_object(
                'cnpj_tomador' value p_receiv,
                        'cnpj_fornecedor' value p_fornec,
                        'data_promessa_inicial' value to_char(
                    add_months(sysdate, -6),
                    'dd/mm/rrrr'
                ),
                        'data_promessa_final' value to_char(
                    add_months(sysdate, 6),
                    'dd/mm/rrrr'
                ),
                        'transaction_id' value p_trasanction_id
            );
      --
        print('l_body_po: ' || l_body_po);
        l_return := get_po_list(l_body_po);
      --
        print('Return: ' || l_return);
      --
        return json_value(get_po_list(l_body_po),
           '$.transaction_id');
      --
    exception
        when others then
      --
            dbms_output.put_line(sqlerrm);
            return null;
      --
    end set_transaction_po_arrays;
  --

    procedure set_po_array_v2 (
        p_fornec in varchar2,
        p_receiv in varchar2,
        p_po     in out nocopy t$po
    ) is
    --
        r_issuer         rmais_issuer_info%rowtype;
    --
        l_body_po        varchar2(500);
    --
        l_transaction_id number;
    --
        procedure setpo is
            cursor c_po is
            select
                *
            from
                rmais_issuer_info_v
            where
                    receiver = p_receiv
                and cnpj = p_fornec;
      --
        begin
      --
            open c_po;
            fetch c_po
            bulk collect into p_po;
      --
        end;
    --
    begin
    --
        l_body_po :=
            json_object(
                'cnpj_tomador' value p_receiv,
                        'cnpj_fornecedor' value p_fornec,
                        'data_promessa_inicial' value to_char(
                    add_months(sysdate, -6),
                    'dd/mm/rrrr'
                ),
                        'data_promessa_final' value to_char(
                    add_months(sysdate, 6),
                    'dd/mm/rrrr'
                )
            );
    --
        setpo;
    --
        if p_po.count = 0 then
      --
            r_issuer.info := rmais_process_pkg_email.get_taxpayer(p_fornec, 'ISSUER');
      --
            l_transaction_id := rmais_process_pkg_email.get_po_list_v2(l_body_po);
      --
            begin
        --
                if l_transaction_id is not null then
          --
                    select
                        xxrmais_util_pkg.base64decode(clob_info)
                    into r_issuer.docs
                    from
                        rmais_ws_info
                    where
                        transaction_id = l_transaction_id;
          --
                end if;
      --
            exception
                when others then
        --
                    print('Erro ao buscar retorno de WS de busca de PO');
        --
            end;
      --
            r_issuer.cnpj := p_fornec;
            r_issuer.receiver := p_receiv;
      --
            rmais_process_pkg_email.ins_issuer(r_issuer);
      --
            setpo;
      --
        end if;
    --
    exception
        when others then
            print('Set PO ERROR: ' || sqlerrm);
    end;
  
  --

    procedure set_po_array_v2 (
        p_fornec in varchar2,
        p_receiv in varchar2
    ) is
        p_po t$po;
    begin
    --
        set_po_array_v2(p_fornec, p_receiv, p_po);
    --
    end;
  
  --
    --

    procedure set_po_array (
        p_fornec in varchar2,
        p_receiv in varchar2
    ) is
        p_po t$po;
    begin
    --
        set_po_array(p_fornec, p_receiv, p_po);
    --
    end;
  
  --
    procedure set_line_info (
        p_efd in out nocopy r$source,
        p_idx in number
    ) is
    begin
    --
        for rlrn in (
            select
                *
            from
                rmais_efd_learning_v
            where
                    issuer_document_number = p_efd.rhea.issuer_document_number
                and fiscal_classification = p_efd.rlin(p_idx).rlin.fiscal_classification
            order by
                decode(item_code,
                       p_efd.rlin(p_idx).rlin.item_code,
                       0,
                       1),
                decode(item_description,
                       p_efd.rlin(p_idx).rlin.item_description,
                       0,
                       1),
                decode(item_code_efd,
                       p_efd.rlin(p_idx).rlin.item_code_efd,
                       0,
                       1),
                decode(item_descr_efd,
                       p_efd.rlin(p_idx).rlin.item_descr_efd,
                       0,
                       1)
        ) loop
      --
            p_efd.rlin(p_idx).rlin.cfop_to := rlrn.cfop_to;
      --
        end loop;
    --
    end;
  --
    function get_parameter (
        p_control   in varchar2,
        p_field     varchar2 default 'TEXT_VALUE',
        p_condition varchar2 default null
    ) return varchar2
        result_cache
    is
    --
        vret  varchar2(4000);
        l_sql varchar2(4000);
    --
    begin
    --
        l_sql := 'SELECT '
                 || p_field
                 || ' FROM rmais_source_ctrl'
                 || ' WHERE control = :1 '
                 || p_condition;
    --
        execute immediate l_sql
        into vret
            using p_control;
    --
        return vret;
    --
    exception
        when others then
            return null;
    end;
  --
    function get_ws return varchar2
        result_cache
    is
    begin
        return get_parameter('RMAIS_WS_URL');
    end;
  --
    function get_response (
        p_url     in varchar2,
        p_content in clob default null,
        p_type    in varchar2 default 'GET'
    ) return clob is
    --
        req    utl_http.req;
        res    utl_http.resp;
        url    varchar2(4000) :=
            case
                when upper(p_url) like '%HTTP%' then
                    p_url
                else
                    get_ws || p_url
            end;
        buffer clob;
    --
    begin
    --
        print('Getting reponse...' || url);
        print('p_content: ' || p_content);
    --
        req := utl_http.begin_request(url, p_type, ' HTTP/1.1');
        utl_http.set_header(req,
                            'Authorization',
                            'Basic ' || get_parameter('AUTHORIZATION_BASIC'));
        utl_http.set_header(req, 'user-agent', 'mozilla/4.0');
        utl_http.set_header(req, 'content-type', 'application/json; charset=utf-8');
--  utl_http.set_header(req, 'content-type', 'application/json');
    --
        if p_content is not null then
      --
            utl_http.set_header(req,
                                'Content-Length',
                                length(p_content));
            utl_http.write_text(req, p_content);
      --
        end if;
    --
        res := utl_http.get_response(req);
    --
        begin
      --
            loop
        --
                utl_http.read_line(res, buffer);
        --
            end loop;
      --
            utl_http.end_response(res);
      --
        exception
            when utl_http.end_of_body then
                utl_http.end_response(res);
                print(sqlerrm);
            when others then
                utl_http.end_response(res);
                print(sqlerrm);
        end;
    --
        return buffer;
    --
    exception
        when others then
            print('Error get_detail: ' || utl_http.get_detailed_sqlerrm);
            print('Error chamada get_response:' || sqlerrm);
            return null;
    end;
  --
    function get_response2 (
        p_url     in varchar2,
        p_content in clob default null,
        p_type    in varchar2 default 'GET'
    ) return clob is

        v_response    clob;
        v_buffer      varchar2(32767);
        v_buffer_size number := 32000;
        v_offset      number := 1;
    begin
      -- Set connection and invoke REST API.
        print('Get_reponse2 body: ' || p_content);
      --
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
      --
        print(
            case
                when upper(p_url) like '%HTTP%' then
                    p_url
                else
                    get_ws
                    ||
                    case
                        when substr(p_url, 1, 1) = '/' then
                                p_url
                        else
                            '/' || p_url
                    end
            end
        );

        v_response := apex_web_service.make_rest_request(
            p_url         =>
                   case
                       when upper(p_url) like '%HTTP%' then
                           p_url
                       else
                           get_ws
                           ||
                           case
                               when substr(p_url, 1, 1) = '/' then
                                       p_url
                               else
                                   '/' || p_url
                           end
                   end,--'http://150.230.68.115/luznfe/rest.php'||CHR(63)||'class=getPDF'||chr(38)||'method=executar',
            p_http_method => p_type,--'POST',
            p_username    => 'admin',
            p_password    => 'admin',
            p_body        => p_content--'{"transaction_id":25862,"method":"NFE","url":null}' -- Your JSON.
        );
      -- Get response.
        print(nvl(v_response, 'teste'));
        begin
            loop
                print('passou');
                dbms_lob.read(v_response, v_buffer_size, v_offset, v_buffer);
              -- Do something with buffer.
                print('aqui');
                dbms_output.put_line(v_buffer);
                v_offset := v_offset + v_buffer_size; 
              --
                return v_buffer;
              --
            end loop;

            return '';
        exception
            when no_data_found then
          --
                print('Error WS');
                return '';
          --    
        end;

    exception
        when others then
            print(utl_http.get_detailed_sqlerrm);
            print('Error get_response2: ' || sqlerrm);
            return null;
    end;
  --
    function get_po_list (
        p_parameter in varchar2
    ) return clob is
    begin
    --
        print('Get_PO_List: URL: ' || get_parameter('GET_PO_URL'));
        return get_response(
            get_parameter('GET_PO_URL'),
            p_parameter
        );
    --
    exception
        when others then
            print('Get PO ERROR: ' || sqlerrm);
    end;
  --
   --
    function get_po_list_v2 (
        p_parameter in varchar2
    ) return number is
    begin
    --
        return json_value(get_response(
            get_parameter('GET_PO_URL'),
            p_parameter
        ),
           '$.transaction_id');
    --
    exception
        when others then
            print('Get PO ERROR: ' || sqlerrm);
    end;
  --
  --
    function get_po_array (
        p_fornec in varchar2,
        p_receiv in varchar2
    ) return t$po
        pipelined
    is
    begin
    --
        for r in (
            select
                *
            from
                rmais_issuer_info_v
            where
                    receiver = p_receiv
                and cnpj = p_fornec
        ) loop
      --
            pipe row ( r );
      --
        end loop;
    --
        return;
    --
    exception
        when others then
            print('Get PO PIPE ERROR: ' || sqlerrm);
    end;
  --
  
  --
  /*
  FUNCTION Get_PO_Array_v2 (p_transaction_id NUMBER) RETURN t$po2 PIPELINED IS
  l_clob CLOB;
  BEGIN
    --
    BEGIN
      SELECT xxrmais_util_pkg.base64decode(CLOB_INFO)
        INTO l_clob
        FROM rmais_ws_info
        WHERE transaction_id = p_transaction_id;
    EXCEPTION WHEN OTHERS THEN
      l_clob := '';
    END;
    --
    FOR r IN
      (
      SELECT "TRANSACTION_ID","CNPJ","RECEIVER","TOTAL_PO","PO_HEADER_ID","PO_NUM","PO_TYPE","TOMADOR","TOMADOR_CNPJ","PRC_BU_ID","VENDOR_NAME","VENDOR_ID","VENDOR_SITE_ID","VENDOR_SITE_CODE","FORNECEDOR_CNPJ","CURRENCY_CODE",to_clob(INFO_DOC) "INFO_DOC",to_clob(INFO_TERM) "INFO_TERM","PO_SEQ",to_clob(INFO_PO) "INFO_PO",to_clob(INFO_ITEM) "INFO_ITEM",to_clob(info_ship) "INFO_SHIP","PO_LINE_ID","LINE_TYPE_ID","LINE_NUM","ITEM_ID","CATEGORY_ID","ITEM_DESCRIPTION","UOM_CODE","UNIT_PRICE","QUANTITY_LINE","PRC_BU_ID_LIN","REQ_BU_ID_LIN","TAXABLE_FLAG_LIN","ORDER_TYPE_LOOKUP_CODE","PURCHASE_BASIS","MATCHING_BASIS","LINE_LOCATION_ID","DESTINATION_TYPE_CODE","TRX_BUSINESS_CATEGORY","PRC_BU_ID_LOC","REQ_BU_ID_LOC","PRODUCT_TYPE","ASSESSABLE_VALUE","QUANTITY_SHIP","QUANTITY_RECEIVED","QUANTITY_ACCEPTED","QUANTITY_REJECTED","QUANTITY_BILLED","QUANTITY_CANCELLED","SHIP_TO_LOCATION_ID","NEED_BY_DATE","PROMISED_DATE","LAST_ACCEPT_DATE","PRICE_OVERRIDE","TAXABLE_FLAG","RECEIPT_REQUIRED_FLAG","SHIP_TO_ORGANIZATION_ID","SHIPMENT_NUM","SHIPMENT_TYPE","FUNDS_STATUS","DESTINATION_TYPE_DIST","PRC_BU_ID_DIST","REQ_BU_ID_DIST","ENCUMBERED_FLAG","UNENCUMBERED_QUANTITY","AMOUNT_BILLED","AMOUNT_CANCELLED","QUANTITY_FINANCED","AMOUNT_FINANCED","QUANTITY_RECOUPED","AMOUNT_RECOUPED","RETAINAGE_WITHHELD_AMOUNT","RETAINAGE_RELEASED_AMOUNT","TAX_ATTRIBUTE_UPDATE_CODE","PO_DISTRIBUTION_ID","BUDGET_DATE","CLOSE_BUDGET_DATE","DIST_INTENDED_USE","SET_OF_BOOKS_ID","CODE_COMBINATION_ID","QUANTITY_ORDERED","QUANTITY_DELIVERED","CONSIGNMENT_QUANTITY","REQ_DISTRIBUTION_ID","DELIVER_TO_LOCATION_ID","DELIVER_TO_PERSON_ID","RATE_DATE","RATE","ACCRUED_FLAG","ENCUMBERED_AMOUNT","UNENCUMBERED_AMOUNT","DESTINATION_ORGANIZATION_ID","PJC_TASK_ID","TASK_NUMBER","TASK_ID","LOCATION_ID","COUNTRY","POSTAL_CODE","LOCAL_DESCRIPTION","EFFECTIVE_START_DATE","EFFECTIVE_END_DATE","BUSINESS_GROUP_ID","ACTIVE_STATUS","SHIP_TO_SITE_FLAG","RECEIVING_SITE_FLAG","BILL_TO_SITE_FLAG","OFFICE_SITE_FLAG","INVENTORY_ORGANIZATION_ID","ACTION_OCCURRENCE_ID","LOCATION_CODE","LOCATION_NAME","STYLE","ADDRESS_LINE_1","ADDRESS_LINE_2","ADDRESS_LINE_3","ADDRESS_LINE_4","REGION_1","REGION_2","TOWN_OR_CITY","LINE_SEQ","INVENTORY_ITEM_ID","PRIMARY_UOM_CODE","ITEM_TYPE","INVENTORY_ITEM_FLAG","TAX_CODE","ENABLED_FLAG","ITEM_NUMBER","DESCRIPTION","LONG_DESCRIPTION","SEQ" FROM (
SELECT p_transaction_id TRANSACTION_ID
     ,d.fornecedor_cnpj cnpj
     , d.tomador_cnpj  receiver
     , SUM(NVL(d.price_override * quantity_ship,d.unit_price * d.quantity_line)) OVER (PARTITION BY po_header_id) total_po
     , '' info_doc
     , d.*
     , ROW_NUMBER() OVER (PARTITION BY d.po_header_id, d.po_line_id ORDER BY d.po_line_id, d.shipment_num) seq
  FROM
       json_table(l_clob, '$' COLUMNS(
                                   NESTED         PATH '$.HEADER[*]' COLUMNS(
       po_header_id                NUMBER         PATH '$.PO_HEADER_ID',
       po_num                      VARCHAR2(500)  PATH '$.PO_NUM',
       po_type                     VARCHAR2(500)  PATH '$.PO_TYPE',
       tomador                     VARCHAR2(300)  PATH '$.TOMADOR',
       tomador_cnpj                VARCHAR2(200)  PATH '$.TOMADOR_CNPJ',
       prc_bu_id                   NUMBER         PATH '$.PRC_BU_ID',
       vendor_name                 VARCHAR2(300)  PATH '$.VENDOR_NAME',
       vendor_id                   NUMBER         PATH '$.VENDOR_ID',
       vendor_site_id              NUMBER         PATH '$.VENDOR_SITE_ID',
       vendor_site_code            VARCHAR2(100)  PATH '$.VENDOR_SITE_CODE',
       fornecedor_cnpj             VARCHAR2(200)  PATH '$.FORNECEDOR_CNPJ',
       currency_code               VARCHAR2(100)  PATH '$.CURRENCY_CODE',
       --info_doc   VARCHAR2(4000) FORMAT JSON WITH  WRAPPER  PATH '$',
       info_term  VARCHAR2(4000) FORMAT JSON WITH  WRAPPER  PATH '$.TERM',
       po_seq     FOR  ORDINALITY, NESTED         PATH '$.LINES[*]' COLUMNS(
       info_po    clob FORMAT JSON WITH  WRAPPER  PATH '$',
       info_item  VARCHAR2(4000) FORMAT JSON WITH  WRAPPER  PATH '$.ITEM',
       info_ship  VARCHAR2(4000) FORMAT JSON WITH  WRAPPER  PATH '$.LINE_LOCATIONS',
       po_line_id                  NUMBER         PATH '$.PO_LINE_ID',
       line_type_id                NUMBER         PATH '$.LINE_TYPE_ID',
       line_num                    NUMBER         PATH '$.LINE_NUM',
       item_id                     NUMBER         PATH '$.ITEM_ID',
       category_id                 NUMBER         PATH '$.CATEGORY_ID',
       item_description            VARCHAR2(300)  PATH '$.ITEM_DESCRIPTION',
       uom_code                    VARCHAR2(100)  PATH '$.UOM_CODE',
       unit_price                  NUMBER         PATH '$.UNIT_PRICE',
       quantity_line               NUMBER         PATH '$.QUANTITY',
       prc_bu_id_lin               NUMBER         PATH '$.PRC_BU_ID',
       req_bu_id_lin               NUMBER         PATH '$.REQ_BU_ID',
       taxable_flag_lin            VARCHAR2(100)  PATH '$.TAXABLE_FLAG',
       order_type_lookup_code      VARCHAR2(100)  PATH '$.ORDER_TYPE_LOOKUP_CODE',
       purchase_basis              VARCHAR2(100)  PATH '$.PURCHASE_BASIS',
       matching_basis              VARCHAR2(100)  PATH '$.MATCHING_BASIS',
       line_seq   FOR  ORDINALITY, NESTED         PATH '$.ITEM[*]' COLUMNS (
       --info_item varchar2(4000) FORMAT JSON  PATH '$[*]',
       inventory_item_id           NUMBER         PATH '$.INVENTORY_ITEM_ID',
       primary_uom_code            VARCHAR2(100)  PATH '$.PRIMARY_UOM_CODE',
       item_type                   VARCHAR2(900)  PATH '$.ITEM_TYPE',
       inventory_item_flag         VARCHAR2(100)  PATH '$.INVENTORY_ITEM_FLAG',
       tax_code                    VARCHAR2(500)  PATH '$.TAX_CODE',
       enabled_flag                VARCHAR2(100)  PATH '$.ENABLED_FLAG',
       item_number                 VARCHAR2(300)  PATH '$.ITEM_NUMBER',
       description                 VARCHAR2(300)  PATH '$.DESCRIPTION',
       long_description            VARCHAR2(900)  PATH '$.LONG_DESCRIPTION'),
       line_location_id            NUMBER         PATH '$.LINE_LOCATIONS.LINE_LOCATION_ID',
       destination_type_code       VARCHAR2(900)  PATH '$.LINE_LOCATIONS.DESTINATION_TYPE_CODE',
       trx_business_category       VARCHAR2(900)  PATH '$.LINE_LOCATIONS.TRX_BUSINESS_CATEGORY',
       prc_bu_id_loc               NUMBER         PATH '$.LINE_LOCATIONS.PRC_BU_ID',
       req_bu_id_loc               NUMBER         PATH '$.LINE_LOCATIONS.REQ_BU_ID',
       product_type                VARCHAR2(100)  PATH '$.LINE_LOCATIONS.PRODUCT_TYPE',
       assessable_value            NUMBER         PATH '$.LINE_LOCATIONS.ASSESSABLE_VALUE',
       quantity_ship               NUMBER         PATH '$.LINE_LOCATIONS.QUANTITY',
       quantity_received           NUMBER         PATH '$.LINE_LOCATIONS.QUANTITY_RECEIVED',
       quantity_accepted           NUMBER         PATH '$.LINE_LOCATIONS.QUANTITY_ACCEPTED',
       quantity_rejected           NUMBER         PATH '$.LINE_LOCATIONS.QUANTITY_REJECTED',
       quantity_billed             NUMBER         PATH '$.LINE_LOCATIONS.QUANTITY_BILLED',
       quantity_cancelled          NUMBER         PATH '$.LINE_LOCATIONS.QUANTITY_CANCELLED',
       ship_to_location_id         NUMBER         PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION_ID',
       need_by_date                VARCHAR2(50)   PATH '$.LINE_LOCATIONS.NEED_BY_DATE',
       promised_date               VARCHAR2(50)   PATH '$.LINE_LOCATIONS.PROMISED_DATE',
       last_accept_date            VARCHAR2(50)   PATH '$.LINE_LOCATIONS.LAST_ACCEPT_DATE',
       price_override              NUMBER         PATH '$.LINE_LOCATIONS.PRICE_OVERRIDE',
       taxable_flag                VARCHAR2(10)   PATH '$.LINE_LOCATIONS.TAXABLE_FLAG',
       receipt_required_flag       VARCHAR2(10)   PATH '$.LINE_LOCATIONS.RECEIPT_REQUIRED_FLAG',
       ship_to_organization_id     NUMBER         PATH '$.LINE_LOCATIONS.SHIP_TO_ORGANIZATION_ID',
       shipment_num                VARCHAR2(10)   PATH '$.LINE_LOCATIONS.SHIPMENT_NUM',
       shipment_type               VARCHAR2(500)  PATH '$.LINE_LOCATIONS.SHIPMENT_TYPE',
       funds_status                VARCHAR2(500)  PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.FUNDS_STATUS',
       destination_type_dist       VARCHAR2(500)  PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_TYPE_CODE',
       prc_bu_id_dist              NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.PRC_BU_ID',
       req_bu_id_dist              NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_BU_ID',
       encumbered_flag             VARCHAR2(10)   PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_FLAG',
       unencumbered_quantity       NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_QUANTITY',
       amount_billed               NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_BILLED',
       amount_cancelled            NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_CANCELLED',
       quantity_financed           NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_FINANCED',
       amount_financed             NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_FINANCED',
       quantity_recouped           NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_RECOUPED',
       amount_recouped             NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_RECOUPED',
       retainage_withheld_amount   NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_WITHHELD_AMOUNT',
       retainage_released_amount   NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_RELEASED_AMOUNT',
       tax_attribute_update_code   VARCHAR2(100)  PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.TAX_ATTRIBUTE_UPDATE_CODE',
       po_distribution_id          NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.PO_DISTRIBUTION_ID',
       budget_date                 VARCHAR2(50)   PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.BUDGET_DATE',
       close_budget_date           VARCHAR2(50)   PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.CLOSE_BUDGET_DATE',
       dist_intended_use           VARCHAR2(500)  PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.DIST_INTENDED_USE',
       set_of_books_id             NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.SET_OF_BOOKS_ID',
       code_combination_id         NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.CODE_COMBINATION_ID',
       quantity_ordered            NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_ORDERED',
       quantity_delivered          NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_DELIVERED',
       consignment_quantity        NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.CONSIGNMENT_QUANTITY',
       req_distribution_id         NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_DISTRIBUTION_ID',
       deliver_to_location_id      NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_LOCATION_ID',
       deliver_to_person_id        NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_PERSON_ID',
       rate_date                   VARCHAR2(50)   PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE_DATE',
       rate                        NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE',
       accrued_flag                VARCHAR2(50)   PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.ACCRUED_FLAG',
       encumbered_amount           NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_AMOUNT',
       unencumbered_amount         NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_AMOUNT',
       destination_organization_id NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_ORGANIZATION_ID',
       pjc_task_id                 NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.PJC_TASK_ID',
       task_number                 VARCHAR2(200)  PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_NUMBER',
       task_id                     NUMBER         PATH '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_ID',
       location_id                 NUMBER         PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_ID',
       country                     VARCHAR2(500)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.COUNTRY',
       postal_code                 VARCHAR2(50)   PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.POSTAL_CODE',
       local_description           VARCHAR2(300)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.DESCRIPTION',
       effective_start_date        VARCHAR2(50)   PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_START_DATE',
       effective_end_date          VARCHAR2(50)   PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_END_DATE',
       business_group_id           NUMBER         PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BUSINESS_GROUP_ID',
       active_status               VARCHAR2(100)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTIVE_STATUS',
       ship_to_site_flag           VARCHAR2(100)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.SHIP_TO_SITE_FLAG',
       receiving_site_flag         VARCHAR2(100)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.RECEIVING_SITE_FLAG',
       bill_to_site_flag           VARCHAR2(100)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BILL_TO_SITE_FLAG',
       office_site_flag            VARCHAR2(100)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.OFFICE_SITE_FLAG',
       inventory_organization_id   NUMBER         PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.INVENTORY_ORGANIZATION_ID',
       action_occurrence_id        NUMBER         PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTION_OCCURRENCE_ID',
       location_code               VARCHAR2(100)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_CODE',
       location_name               VARCHAR2(300)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_NAME',
       style                       VARCHAR2(100)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.STYLE',
       address_line_1              VARCHAR2(300)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_1',
       address_line_2              VARCHAR2(300)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_2',
       address_line_3              VARCHAR2(300)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_3',
       address_line_4              VARCHAR2(300)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_4',
       region_1                    VARCHAR2(300)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_1',
       region_2                    VARCHAR2(300)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_2',
       town_or_city                VARCHAR2(300)  PATH '$.LINE_LOCATIONS.SHIP_TO_LOCATION.TOWN_OR_CITY')))) d
       --AND ROWNUM>11
       )
 WHERE seq = 1
      )
    LOOP
      --
      PIPE ROW(r);
      --
    END LOOP;
    --
    RETURN;
    --
  EXCEPTION
    WHEN OTHERS THEN
      Print('Get PO PIPE ERROR: '||SQLERRM);
  END;
  */
  --
  /*
  PROCEDURE Get_Taxes (p_Efd IN OUT NOCOPY r$source, p_Idx IN NUMBER) IS
    --
    bTaxes CLOB;
    --
    r_tax rmais_efd_taxes%ROWTYPE;
    --
    PROCEDURE LoadTaxes(pClb IN CLOB) IS
    BEGIN
      --
      Print('LoadTax '||pClb);
      --
      DELETE FROM rmais_efd_taxes
       WHERE efd_line_id = p_Efd.rLin(p_Idx).rLin.efd_line_id;
      --
      FOR r IN
        (
        SELECT j.*
          FROM json_table(pClb,'$' COLUMNS(NESTED PATH '$.RULES[*]' COLUMNS
             ( condition_group_code VARCHAR2(100) PATH '$.CONDITION_GROUP_CODE'
             , tax_rate_code        VARCHAR2(100) PATH '$.TAX_RATE_CODE'
             , tax_regime_code      VARCHAR2(100) PATH '$.TAX_REGIME_CODE'
             , tax                  VARCHAR2(100) PATH '$.TAX'
             , rate_type_code       VARCHAR2(100) PATH '$.RATE_TYPE_CODE'
             , percentage_rate      NUMBER        PATH '$.PERCENTAGE_RATE'
             , active_flag          VARCHAR2(100) PATH '$.ACTIVE_FLAG'
             , alphanumeric_value2  VARCHAR2(100) PATH '$.ALPHANUMERIC_VALUE2'
             , alphanumeric_value1  VARCHAR2(100) PATH '$.ALPHANUMERIC_VALUE1'
             , determining_factor   VARCHAR2(100) PATH '$.DETERMINING_FACTOR_CODE'))) j
        )
      LOOP
        --
        r_tax.efd_line_id          := p_Efd.rLin(p_Idx).rLin.efd_line_id;
        r_tax.condition_group_code := r.condition_group_code;
        r_tax.tax_rate_code        := r.tax_rate_code;
        r_tax.tax_regime_code      := r.tax_regime_code;
        r_tax.tax                  := r.tax;
        r_tax.rate_type_code       := r.rate_type_code;
        r_tax.percentage_rate      := r.percentage_rate;
        r_tax.active_flag          := r.active_flag;
        r_tax.attribute2           := r.alphanumeric_value2;
        r_tax.attribute1           := r.alphanumeric_value1;
        r_tax.determining_factor   := r.determining_factor;
        --
        Insert_taxes(r_tax);
        --
      END LOOP;
      --
    END;
    --
  BEGIN
    */--
    /*IF p_Efd.rHea.model = '55' THEN
      --
      bTaxes := JSON_OBJECT('ncm' VALUE p_Efd.rLin(p_Idx).rLin.Fiscal_Classification,'cfop' VALUE p_Efd.rLin(p_Idx).rLin.cfop_to);
      --
      LoadTaxes(Get_response(get_Parameter('GET_RULES_NCM_URL'),bTaxes));
      --
      bTaxes := JSON_OBJECT('cnpj_emissor' VALUE p_Efd.rHea.Receiver_document_number,'cfop' VALUE p_Efd.rLin(p_Idx).rLin.cfop_to);
      --
      LoadTaxes(Get_response(get_Parameter('GET_RULES_CFOP_URL'),bTaxes));
      --
    ELSE
      --
      bTaxes := JSON_OBJECT('cnpj_emissor' VALUE p_Efd.rHea.Issuer_document_number, 'codigo_servico' VALUE p_Efd.rLin(p_Idx).rLin.Fiscal_Classification);
      --
      LoadTaxes(Get_response(get_Parameter('GET_RULES_NFSE_URL'),bTaxes));
      --
    END IF;*/
    --
    /*
    NULL;
  EXCEPTION
    WHEN OTHERS THEN
      Print('Get_Taxes '||SQLERRM);
  END;
  --
  */
    procedure get_po_line (
        p_efd            in out nocopy r$source,
        p_idx            in number,
        p_transaction_id number default null
    ) is
        --
        rlin     rmais_efd_lines%rowtype := p_efd.rlin(p_idx).rlin;
        rlin_old rmais_efd_lines%rowtype := p_efd.rlin(p_idx).rlin;
        rshp     rmais_efd_shipments%rowtype;
        rhea     rmais_efd_headers%rowtype := p_efd.rhea;
        --
        l_count  number := 0;
        --   
        r$po     t$po;
        --
        cursor c$po (
            p_transaction number
        ) is
        with clob_po as (
            select
                xxrmais_util_pkg.base64decode(clob_info) clob_info,
                transaction_id
            from
                rmais_ws_info p
            where
                transaction_id = p_transaction--419197--419194 
        ), linhaspo as (
            select
                po_header_idl,
                case
                    when dbms_lob.substr(a.linhas, 1) = '{' then
                        '['
                        || ( a.linhas )
                        || ']'
                    else
                        ''
                        || a.linhas
                        || ''
                end linhas,
                transaction_id,
                clob_info
            from
                clob_po p,
                json_table ( p.clob_info, '$.HEADER[*].LINES'
                        columns (
                            po_header_idl number path '$.PO_HEADER_ID',
                            linhas clob format json path '$'
                        )
                    )
                a
        )
        select
            d.fornecedor_cnpj                                 cnpj,
            d.tomador_cnpj                                    receiver,
            sum(nvl(d.price_override * quantity_ship, d.unit_price * d.quantity_line))
            over(partition by po_header_id)                   total_po,
            po_header_id,
            po_num,
            po_type,
            tomador,
            tomador_cnpj,
            prc_bu_id,
            vendor_name,
            vendor_id,
            vendor_site_id,
            vendor_site_code,
            fornecedor_cnpj,
            currency_code,
            info_doc,
            info_term,
            po_seq,
            info_po,
            info_item,
            info_ship,
            po_line_id,
            line_type_id,
            line_num,
            item_id,
            category_id,
            item_description,
            --case when nvl(destination_type_code,destination_type_dist)  = 'EXPENSE' then nvl(UNIT_OF_MEASURE_PO,UOM_CODE2) ELSE nvl(UOM_CODE_PO,UOM_CODE)  end uom_code,
            primary_uom_code                                  uom_code,
            uom_code_po                                       uom_desc,
            unit_price,
            quantity_line,
            prc_bu_id_lin,
            req_bu_id_lin,
            taxable_flag_lin,
            order_type_lookup_code,
            purchase_basis,
            matching_basis,
            line_location_id,
            destination_type_code,
            trx_business_category,
            prc_bu_id_loc,
            req_bu_id_loc,
            product_type,
            assessable_value,
            quantity_ship,
            quantity_received,
            quantity_accepted,
            quantity_rejected,
            quantity_billed,
            quantity_cancelled,
            ship_to_location_id,
            need_by_date,
            promised_date,
            last_accept_date,
            price_override,
            taxable_flag,
            receipt_required_flag,
            ship_to_organization_id,
            shipment_num,
            shipment_type,
            funds_status,
            destination_type_dist,
            prc_bu_id_dist,
            req_bu_id_dist,
            encumbered_flag,
            unencumbered_quantity,
            amount_billed,
            amount_cancelled,
            quantity_financed,
            amount_financed,
            quantity_recouped,
            amount_recouped,
            retainage_withheld_amount,
            retainage_released_amount,
            tax_attribute_update_code,
            po_distribution_id,
            budget_date,
            close_budget_date,
            dist_intended_use,
            set_of_books_id,
            code_combination_id,
            quantity_ordered,
            quantity_delivered,
            consignment_quantity,
            req_distribution_id,
            deliver_to_location_id,
            deliver_to_person_id,
            rate_date,
            rate,
            accrued_flag,
            encumbered_amount,
            unencumbered_amount,
            destination_organization_id,
            pjc_task_id,
            task_number,
            task_id,
            location_id,
            country,
            postal_code,
            local_description,
            effective_start_date,
            effective_end_date,
            business_group_id,
            active_status,
            ship_to_site_flag,
            receiving_site_flag,
            bill_to_site_flag,
            office_site_flag,
            inventory_organization_id,
            action_occurrence_id,
            location_code,
            location_name,
            style,
            address_line_1,
            address_line_2,
            address_line_3,
            address_line_4,
            region_1,
            region_2,
            town_or_city,
            line_seq,
            inventory_item_id,
            primary_uom_code,
            item_type,
            inventory_item_flag,
            tax_code,
            enabled_flag,
            item_number,
            description,
            long_description,
            ncm,
            ''                                                catalog_code_ncm,
            nvl(destination_type_code, destination_type_dist) destination_type,
            null,--SEGMENT1||'.'||SEGMENT2||'.'||SEGMENT3||'.'||SEGMENT4||'.'||SEGMENT5||'.'||SEGMENT6||'.'||SEGMENT7||'.'||SEGMENT8 cc_combination_name,
            row_number()
            over(partition by d.po_header_id, d.po_line_id
                 order by
                     d.po_line_id, d.shipment_num
            )                                                 seq,
            email_approve
        from
            (
                select
                    d.fornecedor_cnpj               cnpj,
                    d.tomador_cnpj                  receiver,
                    sum(nvl(l.price_override * quantity_ship, l.unit_price * l.quantity_line))
                    over(partition by po_header_id) total_po,
                    d.*,
                    l.*,
                    row_number()
                    over(partition by d.po_header_id, l.po_line_id
                         order by
                             l.po_line_id, l.shipment_num
                    )                               seq
                    --, lp.*            
                from
                    linhaspo lp,
                    json_table ( clob_info, '$'
                            columns (
                                nested path '$.HEADER[*]'
                                    columns (
                                        po_header_id number path '$.PO_HEADER_ID',
                                        po_num varchar2 ( 500 ) path '$.PO_NUM',
                                        po_type varchar2 ( 500 ) path '$.PO_TYPE',
                                        tomador varchar2 ( 300 ) path '$.TOMADOR',
                                        tomador_cnpj varchar2 ( 200 ) path '$.TOMADOR_CNPJ',
                                        prc_bu_id number path '$.PRC_BU_ID',
                                        vendor_name varchar2 ( 300 ) path '$.VENDOR_NAME',
                                        vendor_id number path '$.VENDOR_ID',
                                        vendor_site_id number path '$.VENDOR_SITE_ID',
                                        vendor_site_code varchar2 ( 100 ) path '$.VENDOR_SITE_CODE',
                                        fornecedor_cnpj varchar2 ( 200 ) path '$.FORNECEDOR_CNPJ',
                                        currency_code varchar2 ( 100 ) path '$.CURRENCY_CODE',
                                        info_doc varchar2 ( 4000 ) format json with wrapper path '$',
                                        info_term varchar2 ( 4000 ) format json with wrapper path '$.TERM',
                                        po_seq for ordinality,
                                        info_po clob format json with wrapper path '$',
                                        email_approve varchar2 ( 4000 ) path '$.MAILS.EMAIL_ADDRESS'
                                    )
                            )
                        )
                    d,
                    json_table ( lp.linhas, '$[*]'
                            columns (
                                po_header_idl number path '$.PO_HEADER_ID',
                                info_item varchar2 ( 4000 ) format json with wrapper path '$.ITEM',
                                info_ship varchar2 ( 4000 ) format json with wrapper path '$.LINE_LOCATIONS',
                                po_line_id number path '$.PO_LINE_ID',
                                line_type_id number path '$.LINE_TYPE_ID',
                                line_num number path '$.LINE_NUM',
                                item_id number path '$.ITEM_ID',
                                category_id number path '$.CATEGORY_ID',
                                item_description varchar2 ( 300 ) path '$.ITEM_DESCRIPTION',
                                uom_code_po varchar2 ( 100 ) path '$.UOM_CODE',
                                unit_price number path '$.UNIT_PRICE',
                                quantity_line number path '$.QUANTITY',
                                prc_bu_id_lin number path '$.PRC_BU_ID',
                                req_bu_id_lin number path '$.REQ_BU_ID',
                                taxable_flag_lin varchar2 ( 100 ) path '$.TAXABLE_FLAG',
                                order_type_lookup_code varchar2 ( 100 ) path '$.ORDER_TYPE_LOOKUP_CODE',
                                purchase_basis varchar2 ( 100 ) path '$.PURCHASE_BASIS',
                                matching_basis varchar2 ( 100 ) path '$.MATCHING_BASIS',
                                line_seq for ordinality,
                                nested path '$.ITEM'
                                    columns (
                                        --info_item CLOB FORMAT JSON PATH '$[*]',
                                        inventory_item_id number path '$.INVENTORY_ITEM_ID',
                                        primary_uom_code varchar2 ( 100 ) path '$.PRIMARY_UOM_CODE',
                                        item_type varchar2 ( 900 ) path '$.ITEM_TYPE',
                                        inventory_item_flag varchar2 ( 100 ) path '$.INVENTORY_ITEM_FLAG',
                                        tax_code varchar2 ( 500 ) path '$.TAX_CODE',
                                        enabled_flag varchar2 ( 100 ) path '$.ENABLED_FLAG',
                                        item_number varchar2 ( 300 ) path '$.ITEM_NUMBER',
                                        description varchar2 ( 300 ) path '$.DESCRIPTION',
                                        long_description varchar2 ( 900 ) path '$.LONG_DESCRIPTION',
                                        ncm varchar2 ( 100 ) path '$.NCM',
                                        uom_code varchar ( 100 ) path '$.UNIT_OF_MEASURE'
                                    ),
                                line_location_id number path '$.LINE_LOCATIONS.LINE_LOCATION_ID',
                                destination_type_code varchar2 ( 900 ) path '$.LINE_LOCATIONS.DESTINATION_TYPE_CODE',
                                trx_business_category varchar2 ( 900 ) path '$.LINE_LOCATIONS.TRX_BUSINESS_CATEGORY',
                                prc_bu_id_loc number path '$.LINE_LOCATIONS.PRC_BU_ID',
                                req_bu_id_loc number path '$.LINE_LOCATIONS.REQ_BU_ID',
                                product_type varchar2 ( 100 ) path '$.LINE_LOCATIONS.PRODUCT_TYPE',
                                assessable_value number path '$.LINE_LOCATIONS.ASSESSABLE_VALUE',
                                quantity_ship number path '$.LINE_LOCATIONS.QUANTITY',
                                quantity_received number path '$.LINE_LOCATIONS.QUANTITY_RECEIVED',
                                quantity_accepted number path '$.LINE_LOCATIONS.QUANTITY_ACCEPTED',
                                quantity_rejected number path '$.LINE_LOCATIONS.QUANTITY_REJECTED',
                                quantity_billed number path '$.LINE_LOCATIONS.QUANTITY_BILLED',
                                quantity_cancelled number path '$.LINE_LOCATIONS.QUANTITY_CANCELLED',
                                ship_to_location_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION_ID',
                                need_by_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.NEED_BY_DATE',
                                promised_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.PROMISED_DATE',
                                last_accept_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.LAST_ACCEPT_DATE',
                                price_override number path '$.LINE_LOCATIONS.PRICE_OVERRIDE',
                                taxable_flag varchar2 ( 10 ) path '$.LINE_LOCATIONS.TAXABLE_FLAG',
                                receipt_required_flag varchar2 ( 10 ) path '$.LINE_LOCATIONS.RECEIPT_REQUIRED_FLAG',
                                ship_to_organization_id number path '$.LINE_LOCATIONS.SHIP_TO_ORGANIZATION_ID',
                                shipment_num varchar2 ( 10 ) path '$.LINE_LOCATIONS.SHIPMENT_NUM',
                                shipment_type varchar2 ( 500 ) path '$.LINE_LOCATIONS.SHIPMENT_TYPE',
                                funds_status varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.FUNDS_STATUS',
                                destination_type_dist varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_TYPE_CODE',
                                prc_bu_id_dist number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PRC_BU_ID',
                                req_bu_id_dist number path '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_BU_ID',
                                encumbered_flag varchar2 ( 10 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_FLAG',
                                unencumbered_quantity number path '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_QUANTITY',
                                amount_billed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_BILLED',
                                amount_cancelled number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_CANCELLED',
                                quantity_financed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_FINANCED',
                                amount_financed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_FINANCED',
                                quantity_recouped number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_RECOUPED',
                                amount_recouped number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_RECOUPED',
                                retainage_withheld_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_WITHHELD_AMOUNT',
                                retainage_released_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_RELEASED_AMOUNT',
                                tax_attribute_update_code varchar2 ( 100 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.TAX_ATTRIBUTE_UPDATE_CODE'
                                ,
                                po_distribution_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PO_DISTRIBUTION_ID',
                                budget_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.BUDGET_DATE',
                                close_budget_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CLOSE_BUDGET_DATE',
                                dist_intended_use varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.DIST_INTENDED_USE',
                                set_of_books_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.SET_OF_BOOKS_ID',
                                code_combination_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.CODE_COMBINATION_ID',
                                quantity_ordered number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_ORDERED',
                                quantity_delivered number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_DELIVERED',
                                consignment_quantity number path '$.LINE_LOCATIONS.DISTRIBUTIONS.CONSIGNMENT_QUANTITY',
                                req_distribution_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_DISTRIBUTION_ID',
                                deliver_to_location_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_LOCATION_ID',
                                deliver_to_person_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_PERSON_ID',
                                rate_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE_DATE',
                                rate number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE',
                                accrued_flag varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.ACCRUED_FLAG',
                                encumbered_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_AMOUNT',
                                unencumbered_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_AMOUNT',
                                destination_organization_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_ORGANIZATION_ID',
                                pjc_task_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PJC_TASK_ID',
                                task_number varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_NUMBER',
                                task_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_ID',
                                     --
                                segment1 varchar2 ( 7 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT1',
                                segment2 varchar2 ( 2 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT2',
                                segment3 varchar2 ( 5 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT3',
                                segment4 varchar2 ( 5 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT4',
                                segment5 varchar2 ( 11 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT5',
                                segment6 varchar2 ( 9 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT6',
                                segment7 varchar2 ( 7 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT7',
                                segment8 varchar2 ( 1 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CC.SEGMENT8',
                                    --
                                location_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_ID',
                                country varchar2 ( 500 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.COUNTRY',
                                postal_code varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.POSTAL_CODE',
                                local_description varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.DESCRIPTION',
                                effective_start_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_START_DATE',
                                effective_end_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_END_DATE',
                                business_group_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BUSINESS_GROUP_ID',
                                active_status varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTIVE_STATUS',
                                ship_to_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.SHIP_TO_SITE_FLAG',
                                receiving_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.RECEIVING_SITE_FLAG',
                                bill_to_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BILL_TO_SITE_FLAG',
                                office_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.OFFICE_SITE_FLAG',
                                inventory_organization_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.INVENTORY_ORGANIZATION_ID',
                                action_occurrence_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTION_OCCURRENCE_ID',
                                location_code varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_CODE',
                                location_name varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_NAME',
                                style varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.STYLE',
                                address_line_1 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_1',
                                address_line_2 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_2',
                                address_line_3 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_3',
                                address_line_4 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_4',
                                region_1 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_1',
                                region_2 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_2',
                                town_or_city varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.TOWN_OR_CITY'
                            )
                        )
                    l
                where
                    l.po_header_idl = d.po_header_id
            ) d; 
        --
    begin
        --
        print(': ' || p_transaction_id);
        print('Status: ' || p_efd.rlin(p_idx).rlin.status);
        open c$po(p_transaction_id);
        fetch c$po
        bulk collect into r$po;
        close c$po;
        -- --
        for t in r$po.first..r$po.last loop
            print('loop pedidos ' || r$po(t).po_num);
            --print(r$Po(t).info_po);
        end loop;

        print('Fetch Collect OK r$Po.count:' || r$po.count);
        --
        if nvl(rlin.status, '$') <> 'MANUAL' then
            --
            rlin.source_doc_line_id := null;
            --
        end if;
        --
        print('Buscando Po considerando por valor unitário e quantidade exata LINHA:' || p_idx);
        --
        print('PO: ' || rlin.source_doc_number);
        --
        print('Linha: ' || rlin.source_doc_line_num);
        --
        print('Status: ' || p_efd.rlin(p_idx).rlin.status);
        --
        for rpo in (
            with dados_po as (
                select
                    rownum sq,
                    a.*
                from
                    (
                        select
                            i.*
                        from
                            table ( r$po ) i --rmais_issuer_info_v i
                        where
                                i.cnpj = p_efd.rhea.issuer_document_number
                            and regexp_replace(i.po_num, '[^0-9]') = regexp_replace(
                                nvl(rlin.source_doc_number, i.po_num),
                                '[^0-9]'
                            ) --Victor
                            and to_number(i.line_num) = to_number(nvl(rlin.source_doc_line_num, i.line_num))   
                    --AND i.unit_price = rLin.unit_price
                        order by
                            decode(
                                regexp_replace(rlin.source_doc_number, '[^0-9]'),
                                regexp_replace(i.po_num, '[^0-9]'),
                                0,
                                1
                            ),
                            decode(to_number(i.line_num), to_number(rlin.source_doc_line_num), 0, 1),
                            decode(
                                sign(i.line_location_id),
                                1,
                                0,
                                1
                            ),
                            decode(rlin.line_quantity, i.quantity_ship, 0, i.quantity_line, 0,
                                   1),
                            decode(rlin.unit_price, i.unit_price, 0, 1),
                            decode(rlin.line_amount, i.unit_price * i.quantity_line, 0, i.price_override * i.quantity_ship, 0,
                                   1),
                            decode(p_efd.rhea.total_amount,
                                   i.total_po,
                                   0,
                                   1)
                    ) a
            )
            select
                *
            from
                dados_po a
            where
                ( p_efd.rhea.model not in ( '00', '22', '23', '06', '24' )
                  and a.unit_price = rlin.unit_price )
                or ( p_efd.rhea.model in ( '00', '22', '23', '06', '24' )
                     and ( a.unit_price = rlin.unit_price
                           or ( a.quantity_line = rlin.unit_price ) ) )
        ) loop
            --
            print('Getting PO Line Info...l_count: ' || l_count);--||' seq: '||rPo.seq);
            print('Gettinf PO Line Indo...line_num_NF: '
                  || to_number(rlin.source_doc_line_num)
                  || '  '
                  || 'Line_num_PO: ' || rpo.line_num);

            print('rLin.source_doc_number: '
                  || rlin.source_doc_number
                  || '  rPo.po_num: ' || rpo.po_num);
            -- Print(round(rLin.line_quantity,     3)||' IN( '||round(nvl(rPo.quantity_ship,0),3)||',  '||round(nvl(rPo.quantity_line,0),3));
            print(round(rlin.line_quantity, 3)
                  || ' <=( '
                  || round(
                nvl(rpo.quantity_ship, 0),
                3
            )
                  || ',  ' || round(
                nvl(rpo.quantity_line, 0),
                3
            ));

            print(round(rlin.unit_price, 2)
                  || '  =  ' || round(
                nvl(rpo.unit_price, 0),
                2
            ));

            print(round(rlin.line_amount, 2)
                  || ' IN ('
                  || round(nvl(rpo.unit_price, 0) * nvl(rpo.quantity_ship, 0),
                           2)
                  || ', ' || round(nvl(rpo.unit_price, 0) * nvl(rpo.quantity_ship, 0),
                                   2));

            print(round(p_efd.rhea.total_amount,
                        2)
                  || '  =  ' || round(
                nvl(rpo.total_po, 0),
                2
            ));
            --tratativa erros pos
            if
                regexp_replace(rpo.po_num, '[^0-9]') = regexp_replace(
                    nvl(rlin.source_doc_number, '-1'),
                    '[^0-9]'
                )
                and to_number ( rpo.line_num ) = to_number ( nvl(rlin.source_doc_line_num, '-1') )
            then
                --
                if
                    round(rlin.unit_price, 2) = round(
                        nvl(rpo.unit_price, 0),
                        2
                    )
                    and round(rlin.line_quantity, 3) > ( round(
                        nvl(
                            nvl(rpo.quantity_ship, rpo.quantity_line),
                            0
                        ),
                        3
                    ) )
                then
                    --
                    print('Ordem de Compra '
                          || rlin.source_doc_number || ' com divergência de quantidade');
                    --
                    log_efd('Ordem de Compra '
                            || rlin.source_doc_number
                            || ' com divergência de quantidade',
                            p_efd.rlin(p_idx).rlin.efd_line_id,
                            p_efd.rhea.efd_header_id);
                    --
                    p_efd.rlin(p_idx).rlin.source_doc_line_id := null;
                    --
                    p_efd.rlin(p_idx).rlin.status := 'INVALID';
                    --
                    exit;
                    --
                end if;
                --
            end if;
            --
            if rlin.source_doc_line_id = rpo.po_line_id then
                --
                p_efd.rlin(p_idx).rlin.order_info := rpo.info_po;
                p_efd.rlin(p_idx).rlin.item_info := rpo.info_item;
                p_efd.rlin(p_idx).rlin.shipto_info := rpo.info_ship;
                p_efd.rlin(p_idx).rlin.item_code_efd := rpo.item_number;
                p_efd.rlin(p_idx).rlin.item_descr_efd := rpo.description;
                p_efd.rlin(p_idx).rlin.uom_to := rpo.uom_code;
                p_efd.rlin(p_idx).rlin.uom_to_desc := rpo.uom_desc;
                p_efd.rlin(p_idx).rlin.destination_type := rpo.destination_type;
                p_efd.rlin(p_idx).rlin.fiscal_classification_to := rpo.ncm;
                p_efd.rlin(p_idx).rlin.catalog_code_ncm := rpo.catalog_code_ncm;
                --
                p_efd.rlin(p_idx).rlin.combination_descr := rpo.cc_cod_combination_name;
                --
                p_efd.rhea.currency_code := rpo.currency_code;
                p_efd.rhea.source_doc_info := rpo.info_doc;
                p_efd.rhea.term_info := rpo.info_term;
                p_efd.rhea.vendor_site_code := rpo.vendor_site_code;
                p_efd.rhea.legal_entity_name := rpo.tomador;
                p_efd.rhea.legal_entity_cnpj := rpo.tomador_cnpj;
                p_efd.rhea.email_approve := rpo.email_approve;
                --
                p_efd.rhea.party_name := rpo.vendor_name;
                --
                rshp.efd_line_id := rlin.efd_line_id;
                rshp.ship_to_organization_id := rpo.ship_to_organization_id;
                rshp.ship_to_location_id := rpo.ship_to_location_id;
                rshp.source_doc_shipment_id := rpo.line_location_id;
                rshp.quantity_to_receive := rlin.line_quantity;
                --
                l_count := 1;
                --
                print('Localizado pelo line_id ');
                --
                exit;
                --
            end if;
            --
            print('Status Linha consistencia: ' || p_efd.rlin(p_idx).rlin.status);
            --
            if nvl(p_efd.rlin(p_idx).rlin.status,
                   '$') <> 'MANUAL' then
                --
                if (
                    ( (
                        round(rlin.line_quantity, 3) = ( round(
                            nvl(
                                nvl(rpo.quantity_ship, rpo.quantity_line),
                                0
                            ),
                            3
                        ) )
                        and round(rlin.unit_price, 2) = round(
                            nvl(rpo.unit_price, 0),
                            2
                        )
                    )
                    or (
                        l_count = 0
                        and ( round(rlin.line_amount, 2) in ( round(nvl(rpo.unit_price, 0) * nvl(rpo.quantity_ship, 0),
                                                                    2), round(nvl(rpo.unit_price, 0) * nvl(rpo.quantity_ship, 0),
                                                                              2) ) )
                    ) )
                    and not g_shipments.exists(rpo.po_line_id
                                               || '.' || nvl(rpo.line_location_id, 0))
                ) then
                    --
                    if
                        rlin.source_doc_number is not null
                        and rlin.source_doc_id is null
                        and regexp_replace(rlin.source_doc_number, '[^0-9]') <> regexp_replace(rpo.po_num, '[^0-9]')
                        and l_count = 0
                    then
                        --
                        print('PO informada pelo fornecedor inválida');
                        --
                        exit;
                        --
                    end if;
                    --
                    l_count := l_count + 1;
                    --
                    print('PO LOCALIZADA');
                    --
                    if
                        ( round(rlin.unit_price, 2) <> round(
                            nvl(rpo.unit_price, 0),
                            2
                        )
                        or trunc(rlin.unit_price, 2) <> trunc(
                            nvl(rpo.unit_price, 0),
                            2
                        ) )
                        and round(
                            nvl(rpo.unit_price, 0),
                            2
                        ) = 1
                    then
                        --
                        rlin.unit_price := 1;-- rmais_efd_lines%ROWTYPE := p_Efd.rLin(p_Idx).rLin;
                        rlin.line_quantity := rlin.line_amount;
                        --
                    end if;
                    --
                end if;
                --
                if l_count > 1 then
                    --
                    print('Voltando valores anteriores');
                    --
                    rlin.unit_price := rlin_old.unit_price;  --retorna valor original para caso seja PO Guardachuva
                    rlin.line_quantity := rlin_old.line_quantity;
                    --
                    exit;
                    --
                elsif
                    l_count = 1
                    and rlin.source_doc_line_id is null
                then
                    --
                    print('Atribuindo pedido a linha');
                    --
                    rlin.source_doc_id := rpo.po_header_id;
                    rlin.source_doc_line_id := rpo.po_line_id;
                    rlin.source_doc_line_num := rpo.line_num;
                    rlin.source_doc_number := rpo.po_num;
                    rlin.line_location_id := rpo.line_location_id;
                    rlin.status := 'AUTO';
                    rlin.order_info := rpo.info_po;
                    --dbms_output.put_line('rPo.info_po: '||rPo.info_po);
                    rlin.item_info := rpo.info_item;
                    --      rLin.shipto_info             := rPo.info_ship;
                    rlin.item_code_efd := rpo.item_number;
                    rlin.item_descr_efd := rpo.description;
                    rlin.uom_to := rpo.uom_code;
                    rlin.uom_to_desc := rpo.uom_desc;
                    rlin.destination_type := rpo.destination_type;
                    rlin.fiscal_classification_to := rpo.ncm;
                    rlin.catalog_code_ncm := rpo.catalog_code_ncm;
                    --
                    rlin.combination_descr := rpo.cc_cod_combination_name;
                    --
                    rhea.currency_code := rpo.currency_code;
                    rhea.term_info := rpo.info_term;
                    rhea.vendor_site_code := rpo.vendor_site_code;
                    rhea.legal_entity_name := rpo.tomador;
                    rhea.legal_entity_cnpj := rpo.tomador_cnpj;    --
                    rhea.party_name := rpo.vendor_name;
                    rhea.email_approve := rpo.email_approve;
                    --
                    if rpo.line_location_id is not null then
                        --
                        rshp.efd_line_id := rlin.efd_line_id;
                        rshp.ship_to_organization_id := rpo.ship_to_organization_id;
                        rshp.ship_to_location_id := rpo.ship_to_location_id;
                        rshp.source_doc_shipment_id := rpo.line_location_id;
                        rshp.quantity_to_receive := rlin.line_quantity;
                        --
                    end if;
                    --
                end if;
                --
            end if;
            --
        end loop;
        --
        print('Status antes de considerar quantidade parcial: ' || nvl(p_efd.rlin(p_idx).rlin.status,
                                                                       'X'));
        --
        if
            l_count = 0
            and nvl(p_efd.rlin(p_idx).rlin.status,
                    'X') in ( 'INVALID', 'MANUAL' )
        then
            --
            print('Po não localizada1!!!');
            --
            log_efd('PO '
                    || p_efd.rlin(p_idx).rlin.source_doc_number
                    || ' Não localizada1.',
                    p_efd.rlin(p_idx).rlin.efd_line_id,
                    p_efd.rhea.efd_header_id);
            --
            p_efd.rlin(p_idx).rlin.status := 'INVALID';
            --
        elsif
            l_count = 0
            and nvl(p_efd.rlin(p_idx).rlin.status,
                    'X') not in ( 'INVALID', 'MANUAL' )
        then
            --
            print('Buscando Po considerando por valor unitário e quantidade parcial');
            --
            /*
            for t in r$Po.first..r$Po.last loop
                print('loop pedidos2 '||t);
                --print(r$Po(t).info_po);
            end loop;
            */
            for rpo in (
                with dados_po as (
                    select
                        rownum sq,
                        a.*
                    from
                        (
                            select
                                i.*
                            from
                                table ( r$po ) i --rmais_issuer_info_v i
                            where
                                    i.cnpj = p_efd.rhea.issuer_document_number
                                and regexp_replace(i.po_num, '[^0-9]') = regexp_replace(
                                    nvl(rlin.source_doc_number, i.po_num),
                                    '[^0-9]'
                                ) --Victor
                                and to_number(i.line_num) = to_number(nvl(rlin.source_doc_line_num, i.line_num))
                            order by
                                decode(
                                    regexp_replace(rlin.source_doc_number, '[^[:alnum:]]'),
                                    regexp_replace(i.po_num, '[^[:alnum:]]'),
                                    0,
                                    1
                                ),
                                decode(
                                    sign(i.line_location_id),
                                    1,
                                    0,
                                    1
                                ),
                                decode(rlin.line_quantity, i.quantity_ship, 0, i.quantity_line, 0,
                                       1),
                                decode(rlin.unit_price, i.unit_price, 0, 1),
                                decode(rlin.line_amount, i.unit_price * i.quantity_line, 0, i.price_override * i.quantity_ship, 0,
                                       1),
                                decode(p_efd.rhea.total_amount,
                                       i.total_po,
                                       0,
                                       1)
                        ) a
                )
                select
                    *
                from
                    dados_po --where unit_price = rLin.unit_price
            ) loop
                --
                print('debbug1');
                --
                print('Getting PO Line Info...l_count: ' || l_count);--||' seq: '||rPo.seq);
                print('rLin.source_doc_number: '
                      || rlin.source_doc_number
                      || '  rPo.po_num: ' || rpo.po_num);
                -- Print(round(rLin.line_quantity,     3)||' IN( '||round(nvl(rPo.quantity_ship,0),3)||',  '||round(nvl(rPo.quantity_line,0),3));
                print(round(rlin.line_quantity, 3)
                      || ' <=( '
                      || round(
                    nvl(rpo.quantity_ship, 0),
                    3
                )
                      || ',  ' || round(
                    nvl(rpo.quantity_line, 0),
                    3
                ));

                print(round(rlin.unit_price, 2)
                      || '  =  ' || round(
                    nvl(rpo.unit_price, 0),
                    2
                ));

                print(round(rlin.line_amount, 2)
                      || ' IN ('
                      || round(nvl(rpo.unit_price, 0) * nvl(rpo.quantity_ship, 0),
                               2)
                      || ', ' || round(nvl(rpo.unit_price, 0) * nvl(rpo.quantity_ship, 0),
                                       2));

                print(round(p_efd.rhea.total_amount,
                            2)
                      || '  =  ' || round(
                    nvl(rpo.total_po, 0),
                    2
                ));
                --
                print(rlin.source_doc_line_id
                      || ' = ' || rpo.po_line_id);
                if rlin.source_doc_line_id = rpo.po_line_id then
                    --
                    print('entrei aqui');
                    p_efd.rlin(p_idx).rlin.order_info := rpo.info_po;
                    p_efd.rlin(p_idx).rlin.item_info := rpo.info_item;
                    p_efd.rlin(p_idx).rlin.shipto_info := rpo.info_ship;
                    p_efd.rlin(p_idx).rlin.item_code_efd := rpo.item_number;
                    p_efd.rlin(p_idx).rlin.item_descr_efd := rpo.description;
                    p_efd.rlin(p_idx).rlin.uom_to := rpo.uom_code;
                    p_efd.rlin(p_idx).rlin.uom_to_desc := rpo.uom_desc;
                    p_efd.rlin(p_idx).rlin.destination_type := rpo.destination_type;
                    p_efd.rlin(p_idx).rlin.fiscal_classification_to := rpo.ncm;
                    p_efd.rlin(p_idx).rlin.catalog_code_ncm := rpo.catalog_code_ncm;
                    --
                    print('Combainação 1: ' || rpo.cc_cod_combination_name);
                    --
                    p_efd.rlin(p_idx).rlin.combination_descr := rpo.cc_cod_combination_name;
                    --
                    p_efd.rhea.currency_code := rpo.currency_code;
                    p_efd.rhea.source_doc_info := rpo.info_doc;
                    p_efd.rhea.term_info := rpo.info_term;
                    p_efd.rhea.vendor_site_code := rpo.vendor_site_code;
                    p_efd.rhea.legal_entity_name := rpo.tomador;
                    p_efd.rhea.legal_entity_cnpj := rpo.tomador_cnpj;
                    --
                    p_efd.rhea.party_name := rpo.vendor_name;
                    p_efd.rhea.email_approve := rpo.email_approve;
                    --
                end if;
                --
                print('Status Linha parcial consistencia: ' || p_efd.rlin(p_idx).rlin.status);
                if nvl(p_efd.rlin(p_idx).rlin.status,
                       '$') <> 'MANUAL' then
                    --
                    print('verificando nota não manual');
                    if (
                        ( (
                            round(rlin.line_quantity, 8) <= ( round(
                                nvl(
                                    nvl(rpo.quantity_ship, rpo.quantity_line),
                                    0
                                ),
                                8
                            ) )
                            and round(rlin.unit_price, 2) = round(
                                nvl(rpo.unit_price, 0),
                                2
                            )
                        )
                        or (
                            l_count = 0
                            and ( round(rlin.line_amount, 2) in ( round(nvl(rpo.unit_price, 0) * nvl(rpo.quantity_ship, 0),
                                                                        2), round(nvl(rpo.unit_price, 0) * nvl(rpo.quantity_ship, 0),
                                                                                  2) )
                                  or round(p_efd.rhea.total_amount,
                                           2) = round(
                                nvl(rpo.total_po, 0),
                                2
                            ) )
                        ) )
                        and not g_shipments.exists(rpo.po_line_id
                                                   || '.' || nvl(rpo.line_location_id, 0))
                    ) then
                        --
                        if
                            rlin.source_doc_number is not null
                            and rlin.source_doc_id is null
                            and regexp_replace(rlin.source_doc_number, '[^0-9]') <> regexp_replace(rpo.po_num, '[^0-9]')
                            and l_count = 0
                        then
                            --
                            print('PO informada pelo fornecedor inválida');
                            --
                            exit;
                            --
                        end if;
                        --
                        l_count := l_count + 1;
                        print('l_count => ' || l_count);
                        --
                        if
                            ( round(rlin.unit_price, 2) <> round(
                                nvl(rpo.unit_price, 0),
                                2
                            )
                            or --alteração de valores caso seja determinada linha automática com PO Guardachuva
                             trunc(rlin.unit_price, 2) <> trunc(
                                nvl(rpo.unit_price, 0),
                                2
                            ) )
                            and round(
                                nvl(rpo.unit_price, 0),
                                2
                            ) = 1
                        then
                            --
                            rlin.unit_price := 1;-- rmais_efd_lines%ROWTYPE := p_Efd.rLin(p_Idx).rLin;
                            rlin.line_quantity := rlin.line_amount;
                            --
                        end if;
                        --
                    end if;
                    --
                    if l_count > 1 then
                        --
                        rlin.unit_price := rlin_old.unit_price;  --retorna valor original para caso seja PO Guardachuva
                        rlin.line_quantity := rlin_old.line_quantity;
                        --
                        exit;
                        --
                    elsif
                        l_count = 1
                        and rlin.source_doc_line_id is null
                    then
                        print('Entrando pois o source_doc_line_id é nulo');
                        --
                        rlin.source_doc_id := rpo.po_header_id;
                        rlin.source_doc_line_id := rpo.po_line_id;
                        rlin.source_doc_line_num := rpo.line_num;
                        rlin.source_doc_number := rpo.po_num;
                        rlin.line_location_id := rpo.line_location_id;
                        rlin.status := 'AUTO';
                        rlin.order_info := rpo.info_po;
                        rlin.item_info := rpo.info_item;
                        --rLin.shipto_info             := rPo.info_ship;
                        rlin.item_code_efd := rpo.item_number;
                        rlin.item_descr_efd := rpo.description;
                        rlin.uom_to := rpo.uom_code;
                        rlin.uom_to_desc := rpo.uom_desc;
                        rlin.destination_type := rpo.destination_type;
                        rlin.fiscal_classification_to := rpo.ncm;
                        rlin.catalog_code_ncm := rpo.catalog_code_ncm;
                        --
                        print('Combainação 2: ' || rpo.cc_cod_combination_name);
                        --
                        rlin.combination_descr := rpo.cc_cod_combination_name;
                        --
                        rhea.currency_code := rpo.currency_code;
                        rhea.term_info := rpo.info_term;
                        rhea.vendor_site_code := rpo.vendor_site_code;
                        rhea.legal_entity_name := rpo.tomador;
                        rhea.legal_entity_cnpj := rpo.tomador_cnpj;
                        rhea.party_name := rpo.vendor_name;
                        rhea.email_approve := rpo.email_approve;
                        --
                        if rpo.line_location_id is not null then
                            --
                            rshp.efd_line_id := rlin.efd_line_id;
                            rshp.ship_to_organization_id := rpo.ship_to_organization_id;
                            rshp.ship_to_location_id := rpo.ship_to_location_id;
                            rshp.source_doc_shipment_id := rpo.line_location_id;
                            rshp.quantity_to_receive := rlin.line_quantity;
                            --
                        end if;
                        --
                    elsif
                        l_count = 1
                        and rlin.source_doc_line_id is not null
                    then
                        --
                        rlin.source_doc_id := rpo.po_header_id;
                        rlin.source_doc_line_id := rpo.po_line_id;
                        rlin.source_doc_line_num := rpo.line_num;
                        rlin.source_doc_number := rpo.po_num;
                        rlin.line_location_id := rpo.line_location_id;
                        --rLin.status                  := 'AUTO';
                        rlin.order_info := rpo.info_po;
                        rlin.item_info := rpo.info_item;
                        --rLin.shipto_info             := rPo.info_ship;
                        rlin.item_code_efd := rpo.item_number;
                        rlin.item_descr_efd := rpo.description;
                        rlin.uom_to := rpo.uom_code;
                        rlin.uom_to_desc := rpo.uom_desc;
                        rlin.destination_type := rpo.destination_type;
                        rlin.fiscal_classification_to := rpo.ncm;
                        rlin.catalog_code_ncm := rpo.catalog_code_ncm;
                        --
                        print('Combinação contábil: ' || rpo.cc_cod_combination_name);
                        --
                        rlin.combination_descr := rpo.cc_cod_combination_name;
                        --
                        rhea.currency_code := rpo.currency_code;
                        rhea.term_info := rpo.info_term;
                        rhea.vendor_site_code := rpo.vendor_site_code;
                        rhea.legal_entity_name := rpo.tomador;
                        rhea.legal_entity_cnpj := rpo.tomador_cnpj;
                        --
                        rhea.party_name := rpo.vendor_name;
                        rhea.email_approve := rpo.email_approve;
                        --
                        if rpo.line_location_id is not null then
                            --
                            rshp.efd_line_id := rlin.efd_line_id;
                            rshp.ship_to_organization_id := rpo.ship_to_organization_id;
                            rshp.ship_to_location_id := rpo.ship_to_location_id;
                            rshp.source_doc_shipment_id := rpo.line_location_id;
                            rshp.quantity_to_receive := rlin.line_quantity;
                            --
                        end if;
                            --
                    end if;
                    --
                end if;
                --
            end loop;
            --
        end if;
        --
        print('Msg da PO: l_count: '
              || l_count
              || ' rLin.source_doc_line_id: '
              || rlin.source_doc_line_id
              || 'p_Efd.rLin(p_Idx).rLin.status :' || p_efd.rlin(p_idx).rlin.status);
        --
        if
            l_count = 1
            and rlin.source_doc_line_id is not null
            and nvl(rlin.status, 'X') = 'AUTO'
        then
            --
            log_efd('Ordem de Compra '
                    || rlin.source_doc_number
                    || ' selecionada automaticamente pelo sistema.',
                    p_efd.rlin(p_idx).rlin.efd_line_id,
                    p_efd.rhea.efd_header_id);
            --
            if rshp.source_doc_shipment_id is null then
                --
                log_efd('Atenção! Dados de entrega não localizado para Ordem de Compra '
                        || rlin.source_doc_number
                        || ' selecionada.',
                        rlin.efd_line_id,
                        p_efd.rhea.efd_header_id);
                --
            end if;
            --
            p_efd.rhea := rhea;
            --
            p_efd.rlin(p_idx).rlin := rlin;
            --
            p_efd.rlin(p_idx).rshp(1) := rshp;
            --
            g_shipments(rlin.source_doc_line_id
                        || '.' || nvl(rlin.line_location_id, 0)).cod := rlin.source_doc_line_id
                                                                        || '.'
                                                                        || nvl(rlin.line_location_id, 0);
            --
            insert_ship(rshp);
            --
        elsif nvl(p_efd.rlin(p_idx).rlin.status,
                  '$') <> 'MANUAL' then
            --
            if l_count = 0 then
                --
                if nvl(p_efd.rlin(p_idx).rlin.status,
                       'X') <> 'INVALID' then
                    --
                    log_efd('PO '
                            || p_efd.rlin(p_idx).rlin.source_doc_number
                            || ' Não localizada2.',
                            p_efd.rlin(p_idx).rlin.efd_line_id,
                            p_efd.rhea.efd_header_id);
                    --
                end if;
                --
            elsif l_count > 1 then
                --
                print('Mais de uma Ordem linha: ' || p_idx);
                --
                log_efd('Mais de uma Ordem de Compra encontrada. Favor selecionar manualmente.',
                        rlin.efd_line_id,
                        p_efd.rhea.efd_header_id);
                --
            end if;
            --
            p_efd.rlin(p_idx).rlin.status := 'INVALID';
            --
            p_efd.rhea.document_status := 'I';
            --
        end if;
        --
        l_count := 0;
        --
    end;
    --
    function get_taxpayer (
        p_cnpj    in varchar2,
        p_type    in varchar2,
        p_bu_name in varchar2 default null
    ) return clob is
        l_response clob;
        l_ctrl     varchar2(300);
        l_body     varchar2(600);
    begin
        --
        print('Get ' || p_type);
        --
        if p_type = 'ISSUER' then
            --
            declare
                l_bu varchar2(400);
            begin
                --
                l_body := '{"cnpj": "'
                          || p_cnpj
                          || '","bu": "$BU$"}';
                --    
                l_body := replace(l_body, '$BU$', '');
            exception
                when others then
                    l_body := replace(l_body, '$BU$', '');---VERIFICAR BUSCA DE NOME DA BU
            end;
            --
            print(get_parameter('GET_'
                                || p_type || '_URL'));
            print('BODY: ' || l_body);
            --
            return get_response(
                get_parameter('GET_'
                              || p_type || '_URL'),
                l_body
            );
            --
        else
            --
            l_body := '{"cnpj": "'
                      ||--get_bu_cnpj(p_cnpj)
                       p_cnpj
                      || '","bu": "$BU$"}';
            --
            print(get_parameter('GET_'
                                || p_type || '_URL')
                  || '/' || p_cnpj--get_bu_cnpj(p_cnpj)
                  );
            --
            return get_response(get_parameter('GET_'
                                              || p_type || '_URL')
                                || '/' || p_cnpj--get_bu_cnpj(p_cnpj)
                                );
            --
        end if;
        --
    exception
        when others then
            print('Get Issuer ERROR: ' || sqlerrm);
    end get_taxpayer;
  --
    function get_invoice_v2 (
        p_header_id in number
    ) return clob is
        l_model rmais_efd_headers.model%type;
    begin
        --        
        for r in (
            with tp_lines as (
                select
                    a.*,
                    case
                        when b.model = '55'
                             and sum(nvl(a.line_amount, a.line_quantity * a.unit_price))
                                 over(partition by a.efd_header_id) != b.total_amount then
                            1
                        else
                            0
                    end                                flag_add_line,
                    case
                        when sum(
                            case
                                when a.item_code = 'Frete Destacado' then
                                    1
                                else
                                    0
                            end
                        )
                             over(partition by a.efd_header_id) > 0 then
                            0
                        else
                            1
                    end                                flag_add_freight,
                            -- temp remover
                    sum(nvl(a.line_amount, a.line_quantity * a.unit_price))
                    over(partition by a.efd_header_id) line_amount_sum,
                    b.total_amount,
                    b.access_key_number
                            -- 
                from
                    rmais_efd_lines   a,
                    rmais_efd_headers b
                where
                        a.efd_header_id = p_header_id
                    and a.efd_header_id = b.efd_header_id
            ), tp_lines_a as (
                select
                    a.*,
                    case
                        when b.lh = 1 then
                            a.line_number
                        else
                            max(a.line_number)
                            over() + b.lh - 1
                    end line_number_esp,
                    case
                        when b.lh = 1 then
                            'Item'
                        when b.lh = 2 then
                            'Miscellaneous'
                        else
                            'Freight'
                    end line_type_esp,
                    case
                        when a.flag_add_line = 1
                             and b.lh = 2
                             and nvl(a.discount_line_amount, 0) > 0 then
                            'Desconto referente linha ' || a.line_number
                        when a.flag_add_line = 1
                             and b.lh = 3
                             and nvl(a.freight_line_amount, 0) > 0
                             and a.flag_add_freight = 1 then
                            'Frete referente linha ' || a.line_number
                        when a.flag_add_line = 1
                             and b.lh = 4
                             and nvl(a.insurance_line_amount, 0) > 0 then
                            'Seguro referente linha ' || a.line_number
                        when a.flag_add_line = 1
                             and b.lh = 5
                             and nvl(a.other_expenses_line_amount, 0) > 0 then
                            'Outras despesas referente linha ' || a.line_number
                    end item_desc_esp,
                    case
                        when a.flag_add_line = 1
                             and b.lh = 2
                             and nvl(a.discount_line_amount, 0) > 0 then
                            a.discount_line_amount * ( - 1 )
                        when a.flag_add_line = 1
                             and b.lh = 3
                             and nvl(a.freight_line_amount, 0) > 0 then
                            a.freight_line_amount
                        when a.flag_add_line = 1
                             and b.lh = 4
                             and nvl(a.insurance_line_amount, 0) > 0 then
                            a.insurance_line_amount
                        when a.flag_add_line = 1
                             and b.lh = 5
                             and nvl(a.other_expenses_line_amount, 0) > 0 then
                            a.other_expenses_line_amount
                    end line_amount_esp
                from
                    tp_lines a,
                    (
                        select
                            level lh
                        from
                            dual
                        connect by
                            level <= 5
                    )        b
            ), tp_lines_b as (
                select
                    a.*
                from
                    tp_lines_a a
                where
                    ( a.line_type_esp = 'Item'
                      or ( a.line_type_esp in ( 'Freight', 'Miscellaneous' )
                           and a.item_desc_esp is not null ) )
                    --order by a.line_number_esp
            ), l as (
                select
                    l.efd_header_id,
                    l.efd_line_id
               --, l.line_number
                    ,
                    nvl(l.line_number_esp, l.line_number)                                                                                                     line_number
                    ,
                    case
                        when l.line_type_esp = 'Item' then
                            nvl(l.line_amount, l.line_quantity * l.unit_price)
                        else
                            l.line_amount_esp
                    end                                                                                                                                       line_amount
                    ,
                    nvl(l.ipi_amount, 0) + nvl(l.freight_line_amount, 0) - nvl(l.discount_line_amount, 0) + nvl(l.insurance_line_amount
                    , 0) + nvl(l.icms_st_amount, 0) dif_nfe,
                    nvl(l.uom_to_desc, uom_to)                                                                                                                uom_to
                    ,
                    l.fiscal_classification_to
               --, NVL(l.item_info.DESCRIPTION,l.item_descr_efd) item_desc
                    ,
                    nvl(l.item_desc_esp,
                        nvl(l.item_info.description,
                            l.item_descr_efd))                                                                                                                item_desc
               --, NVL(l.item_info.ITEM_NUMBER,l.item_code_efd)  item_code
                            ,
                    case
                        when l.line_type_esp = 'Item' then
                            nvl(l.item_info.item_number,
                                l.item_code_efd)
                    end                                                                                                                                       item_code -- Robson 15/06/2023
               --, l.line_quantity
                    ,
                    case
                        when not l.line_type_esp = 'Item' then
                            1
                        else
                            l.line_quantity
                    end                                                                                                                                       line_quantity -- Robson 15/06/2023
               --, l.unit_price
                    ,
                    case
                        when not l.line_type_esp = 'Item' then
                            l.line_amount_esp
                        else
                            l.unit_price
                    end                                                                                                                                       unit_price
                    ,
                    l.shipto_info.location_code                                                                                                               location_code
                    ,
                    l.shipto_info.location_name                                                                                                               location_name
                    ,
                    nvl(l.order_info.line_locations.assessable_value,
                        l.line_amount)                                                                                                                        line_amt
                        ,
                    nvl(
                        regexp_replace(l.item_info.item_type,
                                       '{|}',
                                       ''),
                        'Services'
                    )                                                                                                                                         item_type
                    ,
                    l.source_doc_number,
                    l.source_doc_line_num,
                    l.order_info.vendor_name                                                                                                                  vendor_name
                    ,
                    nvl(l.order_info.line_locations.shipment_num,
                        1)                                                                                                                                    shipment_num
                        ,
                    l.fiscal_classification
               --, nvl(MAX((SELECT MAX(determining_factor) FROM rmais_efd_taxes tx WHERE tx.efd_line_id = l.efd_line_id)),rmais_process_pkg_email.Get_Parameter('DETERM_FACTOR')) determining_factor
                    ,
                    l.catalog_code_ncm,
                    l.cfop_to,
                    l.net_amount,
                    l.source_document_type,
                    l.destination_type,
                    l.item_type                                                                                                                               item_type_na
                    ,
                    l.product_category,
                    l.user_defined,
                    ( l.intended_use )                                                                                                                        intended_use_descr
                    ,
                    (
                        select distinct
                            c.classification_code
                        from 
                        --RMAIS_CFOP_OUT_IN a
                        --inner join rmais_utilization_cfop b on a.utilization_id = b.id
                            rmais_utilizations_ws c
                        where
                            c.classification_name = l.intended_use
                    )                                                                                                                                         intended_use
                    ,
                    l.item_description,
                    to_char(to_timestamp_tz(nvl(
                        json_value(l.order_info, '$.CREATION_DATE'),
                        json_value(l.order_info, '$.LINES.CREATION_DATE')
                    ),
                            'RRRR-MM-DD"T"HH24:MI:SS TZR'),
                            'RRRR-MM-DD')                                                                                                                     cricao_po
                            ,
                    l.combination_descr,
                    l.line_type_esp,
                    l.withholding
                from
                    tp_lines_b l --adicionado busca WS 17/02/2022
                where
                    1 = 1-- ROWNUM <=10
                group by
                    l.efd_header_id,
                    l.efd_line_id
               --, l.line_number
                    ,
                    nvl(l.line_number_esp, l.line_number),
                    l.line_amount,
                    l.ipi_amount,
                    l.freight_line_amount,
                    l.discount_line_amount,
                    l.insurance_line_amount,
                    l.icms_st_amount,
                    nvl(l.uom_to_desc, uom_to),
                    l.fiscal_classification_to,
                    nvl(l.item_desc_esp,
                        nvl(l.item_info.description,
                            l.item_descr_efd)),
                    case
                        when l.line_type_esp = 'Item' then
                                nvl(l.item_info.item_number,
                                    l.item_code_efd)
                    end,
                    l.line_quantity,
                    case
                        when not l.line_type_esp = 'Item' then
                                l.line_amount_esp
                        else
                            l.unit_price
                    end,
                    l.unit_price,
                    l.shipto_info.location_code,
                    l.shipto_info.location_name,
                    nvl(l.order_info.line_locations.assessable_value,
                        l.line_amount),
                    nvl(
                        regexp_replace(l.item_info.item_type,
                                       '{|}',
                                       ''),
                        'Services'
                    ),
                    l.source_doc_number,
                    l.source_doc_line_num,
                    l.order_info.vendor_name,
                    l.line_number,
                    l.fiscal_classification,
                    l.catalog_code_ncm,
                    l.line_number,
                    l.order_info.line_locations.shipment_num,
                    l.cfop_to,
                    l.net_amount,
                    l.source_document_type,
                    l.destination_type,
                    l.item_type,
                    l.product_category,
                    l.user_defined,
                    l.intended_use,
                    l.item_description,
                    to_char(to_timestamp_tz(nvl(
                        json_value(l.order_info, '$.CREATION_DATE'),
                        json_value(l.order_info, '$.LINES.CREATION_DATE')
                    ),
                            'RRRR-MM-DD"T"HH24:MI:SS TZR'),
                            'RRRR-MM-DD'),
                    l.combination_descr,
                    case
                        when not l.line_type_esp = 'Item' then
                                1
                        else
                            l.line_quantity
                    end,
                    l.line_type_esp,
                    case
                        when l.line_type_esp = 'Item' then
                                nvl(l.line_amount, l.line_quantity * l.unit_price)
                        else
                            l.line_amount_esp
                    end,
                    l.withholding
                order by
                    nvl(l.line_number_esp, l.line_number)
            )
             -- NFse, danfe , cte , cteos
            select
                    json_object(
                        'InvoiceNumber' is h.document_number,
                                'InvoiceCurrency' is nvl(h.currency_code, 'BRL'),
                                'PaymentCurrency' is nvl(h.currency_code, 'BRL'),
                                'PaymentMethod' is
                            case
                                when h.model in('06', '22', '23', '24', '25') then
                                    'CONCESSIONARIA'
                                else
                                    null
                            end,
                                'PaymentTerms' is
                            case
                                when h.source_type = 'NA' then
                                    'IMEDIATO'
                                else
                                    (
                                        select
                                            json_value(order_info, '$.TERMS')
                                        from
                                            rmais_efd_lines
                                        where
                                            efd_header_id = p_header_id
                                    )
                            end,
                                'InvoiceAmount' is h.total_amount,
                                'InvoiceDate' is to_char(h.issue_date, 'RRRR-MM-DD'),
                                'InvoiceReceivedDate' is to_char(sysdate, 'RRRR-MM-DD'),
                                'BusinessUnit' is
                            case
                                when nvl((
                                    select
                                        source_document_type
                                    from
                                        rmais_efd_lines l
                                    where
                                            l.efd_header_id = h.efd_header_id
                                        and rownum = 1
                                        and l.source_document_type is not null
                                ), 'PO') = 'PO' then
                                    get_bu_name(h.legal_entity_cnpj)
                                when h.receiver_info.data[0].bu_name is null then
                                    get_bu_name(h.receiver_document_number)
                                else
                                    nvl(h.receiver_info.data[0].bu_name, h.receiver_name)
                            end,
                                'ProcurementBU' is 'PACAEMBU_CENTRALIZADORA_COMPRAS'/* CASE WHEN nvl((select source_document_type 
                                                                     from rmais_efd_lines l
                                                                    where l.efd_header_id = h.efd_header_id and rownum = 1
                                                                      and l.source_document_type  is not null),'PO')  = 'PO' then get_bu_name(h.legal_entity_cnpj) when h.receiver_info.DATA.BU_NAME is null then get_bu_name(h.receiver_document_number)else nvl(h.receiver_info.DATA.BU_NAME, h.receiver_name) end*/		   --                               
                                ,
                                'Supplier' is nvl(h.party_name,
                                                  nvl(
                                                                          nvl((
                                                                              select
                                                                                  party_name
                                                                              from
                                                                                  json_table(h.issuer_info,
                                                                              '$.DATA[*]'
                                                                                      columns(
                                                                                          party_name varchar2(500) path '$.PARTY_NAME'
                                                                                          ,
                                                                              tax_payer_number varchar2(500) path '$.TAX_PAYER_NUMBER'
                                                                                      )
                                                                                  )
                                                                              where
                                                                                      rownum = 1
                                                                                  and to_number(tax_payer_number) = to_number(h.issuer_document_number
                                                                                  )
                                                                          ),
                                                                              nvl(
                                                                              nvl(h.issuer_info.data.party_name,
                                                                                  (
                                                                                  select
                                                                                      max(l.order_info.vendor_name)
                                                                                  from
                                                                                      rmais_efd_lines l
                                                                                  where
                                                                                          l.efd_header_id = h.efd_header_id
                                                                                      and rownum = 1
                                                                              )), --h.issuer_name
                                                                              json_value(h.issuer_info, '$.PARTY_NAME')
                                                                          )),
                                                                          h.party_name
                                                                      )),
                                'SupplierSite' is
                            case
                                when h.model = '98' then
                                    (
                                        select
                                            supplier_site
                                        from
                                            rmais_suplier_site_guias
                                        where
                                            id_site = h.vendor_site_code
                                    )
                                else
                                    case
                                        when length(nvl(h.vendor_site_code, h.issuer_document_number)) = 11 then
                                                nvl(h.vendor_site_code, h.issuer_document_number)
                                        else
                                            nvl(h.vendor_site_code, h.issuer_document_number)
                                    end
                            end,
                                'AccountingDate' is to_char(sysdate - 60, 'RRRR-MM-DD')              
               --,'PaymentTerms'                        IS null
                                ,
                                'TermsDate' is to_char(first_due_date, 'RRRR-MM-DD')
               --,'LegalEntity'                         IS h.LEGAL_ENTITY_NAME
                                ,
                                'LegalEntityIdentifier' is --CASE WHEN h.DOCUMENT_TYPE  = 'PO' then h.legal_entity_cnpj else h.receiver_document_number end
                            case
                                when(
                                    select
                                        source_document_type
                                    from
                                        rmais_efd_lines l
                                    where
                                            l.efd_header_id = h.efd_header_id
                                        and rownum = 1
                                        and l.source_document_type is not null
                                ) = 'PO' then
                                    h.legal_entity_cnpj
                                else
                                    (h.receiver_document_number)
                            end,
                                'TaxationCountry' is 'Brazil',
                                'FirstPartyTaxRegistrationId' is h.org_id --buscar via api, ver com o nene.         
              --,'FirstPartyTaxRegistrationNumber'      IS h.receiver_document_number              
                                ,
                                'InvoiceSource' is
                            case
                                when h.model = '98' then
                                    'RECEBEMAISGUIAS'
                                when h.model = '00' then
                                    'RECEBEMAIS SERVICO'
                                else
                                    'RECEBEMAIS'
                            end
              --,'Requester'                            is 'CONCESSIONARIAS RM'--'CONCESSIONARIAS RM'             
                            ,
                                'invoiceDff' is(
                            select
                                json_array(
                                    json_object(
                                        '__FLEX_Context' is
                                            case
                                                when model = '00' then /*'ISVCLS_BRA'*/
                                                    null
                                                else
                                                    (
                                                        select
                                                            context
                                                        from
                                                            rmais_modelo_guias
                                                        where
                                                            cod_guia = h.context
                                                    )
                                            end,
                                                '__FLEX_Context_DisplayValue' is
                                            case
                                                when model = '00' then /*'ISV Additional Information'*/
                                                    null
                                                else
                                                    (
                                                        select
                                                            display_value
                                                        from
                                                            rmais_modelo_guias
                                                        where
                                                            cod_guia = h.context
                                                    )
                                            end,
                                                'isvModel' is null,--CASE when h.model = '00' then '39' else null end,
                                                'isvSerie' is null,--CASE when h.model = '00' then rmais_process_pkg_email.Get_Parameter('GET_SERIE_NFSE') else null end,
                                                'isvSubserie' is '',
                                                'isvAccessKey' is '',
                                                case
                                                when h.context in('FGTS', 'DARJ', 'DARF') then
                                                    'codigoDaReceita'
                                                when h.context = 'GRU' then
                                                    'codigoDeRecolhimento'
                                                else
                                                    'NULO_CODE'
                                                end
                                        is
                                            case
                                                when h.context in('DARJ', 'FGTS', 'GRU', 'DARF') then
                                                    h.codigo_guia
                                                else
                                                    null
                                            end,
                                                'nomeContribuinte' is h.nome_contribuinte,
                                                case
                                                    when h.context in('DARJ', 'DARF') then
                                                        'periodoApuracaoCompetencia'
                                                    else
                                                        'NULO_PERIODO'
                                                end
                                        is
                                            case
                                                when h.context in('DARJ', 'DARF') then
                                                    h.periodo
                                                else
                                                    null
                                            end,
                                                'numeroDaInscricaoEstadual' is h.inscricao_estadual,
                                                'numeroDoDocumentoOrigem' is h.numero_documento,
                                                'numeroDeReferencia' is h.referencia,
                                                case
                                                    when h.context in('FGTS', 'GRU', 'GUIA') then
                                                        'metodoDeEntrada'
                                                    else
                                                        'NULO_MTH_BAR'
                                                end
                                        is
                                            case
                                                when h.context in('FGTS', 'GRU', 'GUIA') then
                                                    'MANUAL'
                                                else
                                                    null
                                            end,
                                                case
                                                    when h.context in('FGTS', 'GRU', 'GUIA') then
                                                        'codigoDeBarras'
                                                    else
                                                        'NULO_COD_BAR'
                                                end
                                        is
                                            case
                                                when h.context in('FGTS', 'GRU', 'GUIA') then
                                                    regexp_replace(h.boleto_cod, '[^0-9]')
                                                else
                                                    null
                                            end,
                                                'campoIdentificadorDoFgts' is h.id_recolhimento_fgts,
                                                'lacreDaConectividadeSocial' is h.conectividade_social_fgts,
                                                'dvDoLacreDaConectividadeSocial' is h.conectividade_social_dv_fgts,
                                                'numeroDeReferencia' is h.referencia_gru,
                                                'competencia' is h.competencia_gru,
                                                'tipoIdentificacaoDoContribuint' is h.idt_contribuinte,
                                                'nroIdentificacaoContribuinte' is h.numero_contribuinte
                        --'laclsBrReference'                    IS h.referencia
                                                 absent on null)
                                absent on null)
                            from
                                dual
                            where
                                h.model = '98'
                        ),
                                'invoiceLines' is(
                            select
                                json_arrayagg(
                                    json_object(
                                        'LineNumber' is rownum--l.line_number
                                        ,
                                                'LineAmount' is l.line_amount,
                                                'AccountingDate' is sysdate - 60--l.cricao_po
               --,'BudgetDate'                          IS l.cricao_po
                                                ,
                                                'ShipToLocation' is
                                            case
                                                when h.model in('55', '00') then
                                                    get_ship_to_location(h.receiver_document_number)
                                                else
                                                    null
                                            end,
                                                'UOM' is
                                            case
                                                when line_type_esp = 'Item' then
                                                    l.uom_to
                                                else
                                                    null
                                            end,
                                                'LineType' is l.line_type_esp,
                                                'Description' is l.item_desc,
                                                'Item' is l.item_code,
                                                'Quantity' is
                                            case
                                                when line_type_esp = 'Item' then
                                                    l.line_quantity
                                                else
                                                    null
                                            end,
                                                'UnitPrice' is
                                            case
                                                when line_type_esp = 'Item' then
                                                    l.unit_price
                                                else
                                                    null
                                            end
               --, decode(l.source_document_type,'NA','ProductType','Withholding')          IS CASE WHEN l.source_document_type = 'NA' THEN l.item_type_na ELSE NULL END
                                            ,
                                                'UserDefinedFiscalClassification' is
                                            case
                                                when line_type_esp = 'Item' then
                                                    l.user_defined
                                                else
                                                    null
                                            end,
                                                'ProductFiscalClassification' is
                                            case
                                                when h.model = '00' then
                                                    '|'
                                                    || to_number(replace(l.fiscal_classification, '.', ''))
                                                    || '|'
                                                else
                                                    case
                                                        when line_type_esp = 'Item' then
                                                                l.fiscal_classification
                                                        else
                                                            null
                                                    end
                                            end,
                                                'ProductFiscalClassificationCode' is
                                            case
                                                when h.model = '00' then
                                                    '|'
                                                    || to_number(replace(l.fiscal_classification, '.', ''))
                                                    || '|'
                                                else
                                                    case
                                                        when line_type_esp = 'Item' then
                                                                l.fiscal_classification
                                                        else
                                                            null
                                                    end
                                            end,
                                                'ProductFiscalClassificationType' is /*case when h.model = '00' then null else*/
                                            case
                                                when line_type_esp = 'Item' then
                                                        case
                                                            when h.model in('55', '00') then
                                                                'LACLS_NCM_SERVICE_CODE'
                                                            else
                                                                null
                                                        end /*else null end*/
                                            end
               /*
               ,'ProductFiscalClassification'         IS case when h.model = '00' then null else case when LINE_TYPE_ESP = 'Item' then l.fiscal_classification else null end end
               ,'ProductFiscalClassificationCode'     IS case when h.model = '00' then null else case when LINE_TYPE_ESP = 'Item' then l.fiscal_classification else null end end
               ,'ProductFiscalClassificationType'     IS case when h.model = '00' then null else case when LINE_TYPE_ESP = 'Item' then case when h.model in ('55','00') then 'LACLS_NCM_SERVICE_CODE' else null end else null end end
               */,
                                                'ProductType' is
                                            case
                                                when line_type_esp = 'Item' then
                                                        case
                                                            when h.model in('55') then
                                                                'Goods'
                                                            when h.model in('00') then
                                                                'Services'
                                                            else
                                                                null
                                                        end
                                                else
                                                    null
                                            end,
                                                'DistributionCombination' is trim(
                                            case
                                                when line_type_esp = 'Item'          then
                                                    l.combination_descr
                                                when line_type_esp = 'Miscellaneous' then
                                                    replace(l.combination_descr,
                                                            substr(
                                                        substr(l.combination_descr,
                                                               instr(l.combination_descr,
                                                                     '-',
                                                                     instr(l.combination_descr, '-') + 1) + 1),
                                                        1,
                                                        instr(
                                                            substr(l.combination_descr,
                                                                   instr(l.combination_descr,
                                                                         '-',
                                                                         instr(l.combination_descr, '-') + 1) + 1),
                                                            '-'
                                                        ) - 1
                                                    ),
                                                            '422060001')
                                                else
                                                    null
                                            end
                                        ),
                                                'TransactionBusinessCategoryCodePath' is
                                            case
                                                when line_type_esp = 'Item' then
                                                        case
                                                            when h.model in('55', '00') then
                                                                'PURCHASE_TRANSACTION/OPERATION FISCAL CODE/'
                                                                || nvl(l.cfop_to,
                                                                       case
                                                                           when h.issuer_address_state = h.receiver_address_state then
                                                                               '1'
                                                                           else
                                                                               '2'
                                                                       end
                                                                       || '933')
                                                            else
                                                                null
                                                        end
                                                else
                                                    null
                                            end,
                                                'IntendedUseCode' is l.intended_use,
                                                'IntendedUse' is l.intended_use_descr 
                --comentado para tentar enviar para dentro.                                                                      --,'ProductFiscalClassification'         IS l.fiscal_classification
               --               
                                                ,
                                                'PurchaseOrderNumber' is
                                            case
                                                when nvl(l.source_document_type, 'PO') = 'NA' then
                                                    null
                                                else
                                                    l.source_doc_number
                                            end,
                                                'PurchaseOrderLineNumber' is
                                            case
                                                when nvl(l.source_document_type, 'PO') = 'NA' then
                                                    null
                                                else
                                                    l.source_doc_line_num
                                            end,
                                                'PurchaseOrderScheduleLineNumber' is
                                            case
                                                when nvl(l.source_document_type, 'PO') = 'NA' then
                                                    null
                                                else
                                                    l.shipment_num
                                            end,
                                                'ProductCategory' is l.product_category,
                                                'Withholding' is l.withholding absent on null)
                                absent on null returning clob)
                            from
                                l
                            where
                                l.efd_header_id = h.efd_header_id
                        ),
                                'attachments' is(
                        select
                            json_arrayagg(
                                json_object(
                                    'Type' is
                                        case
                                            when at.filename is not null then
                                                'File'
                                            else
                                                ''
                                        end,
                                            'FileName' is substr(
                                        substr(
                                            upper(at.filename),
                                            1,
                                            instr(
                                                upper(at.filename),
                                                '.PDF'
                                            ) - 1
                                        ),
                                        1,
                                        50
                                    )
                                                          || substr(
                                        upper(at.filename),
                                        instr(
                                                                             upper(at.filename),
                                                                             '.PDF'
                                                                         ),
                                        4
                                    ),
                                            'Title' is replace(
                                        replace(substr(
                                            substr(
                                                upper(at.filename),
                                                1,
                                                instr(
                                                    upper(at.filename),
                                                    '.PDF'
                                                ) - 1
                                            ),
                                            1,
                                            50
                                        )
                                                || substr(
                                            upper(at.filename),
                                            instr(
                                                                                     upper(at.filename),
                                                                                     '.PDF'
                                                                                 ),
                                            4
                                        ),
                                                '.pdf',
                                                ''),
                                        '.PDF',
                                        ''
                                    ),
                                            'Description' is replace(
                                        replace(substr(
                                            substr(
                                                upper(at.filename),
                                                1,
                                                instr(
                                                    upper(at.filename),
                                                    '.PDF'
                                                ) - 1
                                            ),
                                            1,
                                            50
                                        )
                                                || substr(
                                            upper(at.filename),
                                            instr(
                                                                                     upper(at.filename),
                                                                                     '.PDF'
                                                                                 ),
                                            4
                                        ),
                                                '.pdf',
                                                ''),
                                        '.PDF',
                                        ''
                                    ),
                                            'Category' is
                                        case
                                            when at.filename is not null then
                                                'From Supplier'
                                            else
                                                ''
                                        end,
                                            'FileContents' is at.clob_file
                                returning clob)
                            returning clob)
                        from
                            dual
                    ) absent on null returning clob)
                doc
            from
                rmais_efd_headers h,
                rmais_attachments at
            where
                    h.efd_header_id = p_header_id
                and h.efd_header_id = at.efd_header_id (+)
        ) loop
          --
            return r.doc;
          --
        end loop;
        --
    end get_invoice_v2;      
    --

    procedure send_invoice_v2 (
        p_header_id in number
    ) is
        --
        l_transaction_id number;
        --
        l_return         clob;
        --
        l_body           clob;
        --
        l_body_send      clob;
        --
        l_model          varchar2(100);
        --l_url  VARCHAR2(4000) := get_Parameter('SEND_INVOICE_AP_URL');
        l_status         rmais_efd_headers.document_status%type;
        --
    begin
        send_invoice_v3(p_header_id);
        return;
        --incluíido return na linha acima devido novo método de envio em teste.
        begin
            select
                model,
                document_status
            into
                l_model,
                l_status
            from
                rmais_efd_headers
            where
                efd_header_id = p_header_id;

        end;
        --
        if l_status in ( 'T' ) then
            print('Nota já integrada');
            return;
        end if;
        --
        print('send_invoice_v2');
        generate_attachments(p_header_id);
        --
        --l_body := REPLACE (ASCIISTR (Get_Invoice_v2(p_header_id)), '\', '\u');
        l_body := get_invoice_v2(p_header_id);
        --l_body := '{"BASE64":"'||replace(translate(xxrmais_util_pkg.base64encode(xxrmais_util_pkg.clob_to_blob(l_body)), chr(10) || chr(13) || chr(09), ' '),' ','')||'"}';
        --l_body := json_object('BASE64' VALUE regexp_replace(text2base64(l_body),'[^[:alnum:][:print:]]'));
        --
        l_body := xxrmais_util_pkg.base64encode(xxrmais_util_pkg.clob_to_blob(l_body));
        --
        rmais_process_pkg_email.insert_ws_info(
            p_id     => l_transaction_id,
            p_method => 'SEND_NF_AP',
            p_clob   => replace(
                replace(
                    replace(
                        replace(l_body,
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
        --return;
        --Print(Get_ws||l_url);
        --
        --l_return := Get_response(l_url, l_body, 'POST');
        --
        --Print(l_body);
        --
        l_body_send := '{"transaction_id":'
                       || l_transaction_id
                       || '}';
        --
        print('l_body_send: ' || l_body_send);
        --
        if nvl(xxrmais_util_pkg.g_test, 'T') = 'T' then
                --
            declare
                --http://140.238.190.67:9000/api/payables/v2/createInvoiceService
                l_url      varchar2(400) := rmais_process_pkg_email.get_parameter('SEND_INVOICE_AP_URL')
                                       ||
                    case
                        when l_model in ( '00', '57', '67', '97' ) then
                            '/N'
                        else
                            '/N'
                    end;
                --                      http://150.230.89.158:9000/api/payables/v2/createInvoiceService
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
                print('URL: ' || l_url);
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
                            for r in (
                                select
                                    json_value(l_response, '$.code')       as code,
                                    json_value(l_response, '$.retorno')    as retorno,
                                    json_value(l_response, '$.DocumentId') as documentid,
                                    'X'                                    s
                                from
                                    dual
                            ) loop
                                if r.documentid is not null then
                                    --
                                    log_efd(
                                        nvl(r.retorno, 'Enviado para ERP (AP)'),
                                        null,
                                        p_header_id,
                                        case
                                            when r.code = '400' then
                                                    'Erro'
                                            else
                                                'Integrado'
                                        end
                                    );
                                    --
                                    update rmais_efd_headers
                                    set
                                        document_status =
                                            case
                                                when to_number(regexp_replace(r.code, '[^[:digit:]]')) not between 200 and 299 then
                                                    'E'
                                                else
                                                    'T'
                                            end,
                                        last_update_date = sysdate
                                    where
                                        efd_header_id = p_header_id;
                                    --
                                    /*fluxo de aprovacao*/
                                    --insert into RMAIS_LOG_FLUXO_APROVACAO values ( p_header_id,sysdate,nvl(v('APP_USER'),'-1'),CASE WHEN to_number(regexp_replace(r.code,'[^[:digit:]]')) NOT BETWEEN 200 AND 299 THEN 'E' ELSE 'T' END,'T');
                                    --COMMIT;
                                    --
                                    /*
                                    if l_model IN ('06','22','23','24','25') then
                                        send_boleto(p_header_id);
                                        null;
                                    end if;
                                    */
                                    --  
                                else
                                    --
                                    log_efd(
                                        nvl(r.retorno, 'Erro indefinido - Contacte o Administrador'),
                                        null,
                                        p_header_id,
                                        case
                                            when r.code = '400' then
                                                    'Erro'
                                            else
                                                'Erro'
                                        end
                                    );
                                    --
                                    update rmais_efd_headers
                                    set
                                        document_status = 'E',
                                        last_update_date = sysdate
                                    where
                                        efd_header_id = p_header_id;
                                    --
                                    commit;
                                --
                                end if;
                            end loop;
                            --
                        end if;

                    end loop;
                    --
                    utl_http.end_response(resp);
                    --
                exception
                    when utl_http.end_of_body then
                        utl_http.end_response(resp);
                    when others then
                        utl_http.end_response(resp);
                end;
                --
                rmais_process_pkg_email.set_workflow(p_header_id,
                                                     g_log_workflow,
                                                     nvl(
                                 v('APP_USER'),
                                 '-1'
                             ));

                g_set_workflow := false;
                --
            exception
                when others then
                    --
                    print('Erro ao chamar WS: ' || sqlerrm);
                    --
                    print(utl_http.get_detailed_sqlerrm);
                    --
            end;
        end if;
        --
        /*FOR r IN
        (
        SELECT JSON_VALUE(l_return, '$.code')    AS code,
             JSON_VALUE(l_return, '$.retorno') AS retorno
        FROM dual
        )
        LOOP
        --
        Log_Efd(nvl(r.retorno,'Enviado para ERP'),NULL,p_header_id,CASE WHEN r.code = '400' THEN 'Erro' ELSE 'Integrado' END);
        --
        UPDATE rmais_efd_headers
         SET document_status = CASE WHEN to_number(regexp_replace(r.code,'[^[:digit:]]')) NOT BETWEEN 200 AND 299 THEN 'E' ELSE 'T' END
           , last_update_date = SYSDATE
        WHERE efd_header_id = p_header_id;
        --
        COMMIT;
        --
        END LOOP;*/
        --
    exception
        when others then
            print('Send Invoice ERROR: ' || sqlerrm);
    end send_invoice_v2;
    
        --
    function get_registrationid (
        p_cnpj varchar2
    ) return varchar2 as
        l_url varchar2(1000) := rmais_process_pkg_email.get_parameter('GET_TAX_REGISTRATION')
                                || '/';
    begin
    --
        l_url := l_url || p_cnpj;
        return json_value(rmais_process_pkg_email.get_response(l_url),
           '$.RegistrationId');
    --
    exception
        when others then
            return '';
    end get_registrationid;
  --
    procedure main (
        p_header_id in number default null,
        p_acces_key in varchar2 default null,
        p_revalidar in varchar2 default null,
        p_user      in varchar2 default null
    ) as
        --
        type t$issuer is
            table of rmais_issuer_info%rowtype index by varchar2(100);
        --
        t_issuer         t$issuer;
        --
        type t$receiv is
            table of rmais_receiver_info%rowtype index by varchar2(100);
        --
        t_receiv         t$receiv;
        --
        l_body_po        varchar2(500);
        --
        ix_l             number;
        --
        r_efd            r$source;
        --
        l_transaction_id number;
        --
        l_icms_rate      varchar2(4);
        l_user_defined   varchar2(20);
        l_cfop_from      varchar2(6);
        l_cfop_to        varchar2(6);
        --
        l_extra          number;
        --
    begin
        --
        g_shipments.delete;
        --
        --EXECUTE IMMEDIATE 'truncate table rmais_log';
        --
        execute immediate 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD-MON-RR''';
        --
        print('Iniciando validação... ' || to_char(current_date, 'DD/MM/RRRR HH24:MI:SS'));
        --
        for r in (
            select
                * --efd_header_id
            from
                rmais_efd_headers
            where
                    1 = 1
                and ( ( document_status is null
                        and nvl(p_header_id, p_acces_key) is null )
                      or nvl(p_header_id, p_acces_key) is not null )
                and ( ( efd_header_id = p_header_id
                        and p_header_id is not null )
                      or ( p_header_id is null ) )
                and ( ( access_key_number = p_acces_key
                        and p_acces_key is not null )
                      or ( p_acces_key is null ) )
                and nvl(document_status, 'A') not in ( 'T' )
        ) loop
            --
            r_efd.rhea := r;
            --
            if
                rmais_process_pkg_email.g_first_main is null
                and r.document_status = 'N'
            then
                rmais_process_pkg_email.g_first_main := 'RMAIS';
            end if;
            --
            log_del(r.efd_header_id);
            --
            insert_ws_info(l_transaction_id);
            --
            l_transaction_id := rmais_process_pkg_email.set_transaction_po_arrays(r.issuer_document_number,
                                                                                  get_bu_cnpj(r.receiver_document_number),
                                                                                  l_transaction_id);
            --
            print('NF.....: ' || r.document_number);
            print('Fornec.: '
                  || r.issuer_taxpayer_id
                  || ' '
                  || r.issuer_document_number
                  || ' ' || r.issuer_name);

            print('Estab..: '
                  || r.receiver_taxpayer_id
                  || ' '
                  || r.receiver_document_number
                  || ' ' || r.receiver_name);
            --
            --Ação para trazer as informações mais atuais do fornecedor conforme seu CNPJ.
            if not t_issuer.exists(r.issuer_document_number) then
                --
                t_issuer(r.issuer_document_number).receiver := r.receiver_document_number;
                t_issuer(r.issuer_document_number).info := get_taxpayer(r.issuer_document_number, 'ISSUER');
                --código comentado abaixo, pois cliente não possui pedidos, caso tenham pedidos mais adiante, descomentar o código.                
                begin
                    if l_transaction_id is not null then
                        --
                        select
                            xxrmais_util_pkg.base64decode(clob_info) clob_info
                        into t_issuer(r.issuer_document_number).docs
                        from
                            rmais_ws_info
                        where
                            transaction_id = l_transaction_id;
                        --
                    end if;
                exception
                    when others then
                        print('Falha ao buscar clob_info WS ID: '
                              || l_transaction_id
                              || ' - Error: ' || sqlerrm);
                end;
                --
                t_issuer(r.issuer_document_number).cnpj := r.issuer_document_number;
                --
                ins_issuer(t_issuer(r.issuer_document_number));
                --
            end if;
            --
            begin
                
                --condicional para modelos com ou sem po.
                if
                    r_efd.rhea.model in ( '98', 'BO' )
                    and nvl(r_efd.rhea.document_type,
                            'NA') = 'NA'
                then
                    r_efd.rhea.document_type := 'NA';
                    update rmais_efd_lines
                    set
                        source_document_type = 'NA'
                    where
                        efd_header_id = r_efd.rhea.efd_header_id;

                elsif r_efd.rhea.document_type is null
                      or (
                    r_efd.rhea.model != '55'
                    and r_efd.rhea.document_type is not null
                ) then
                    r_efd.rhea.document_type := 'PO';
                    update rmais_efd_lines
                    set
                        source_document_type = 'PO'
                    where
                        efd_header_id = r_efd.rhea.efd_header_id;

                end if;    
                --
            exception
                when others then
                    print('Falha ao carregar informações do Fornecedor '
                          || r.issuer_document_number
                          || ' ' || sqlerrm);
            end;
            -- Verifica  ão de tomadores, onde busca dados do tomador mais recentes no oracle.
            if not t_receiv.exists(r.receiver_document_number) then
                --
                print('receiver');
                --
                t_receiv(r.receiver_document_number).type := 'RECEIVER';
                t_receiv(r.receiver_document_number).info := get_taxpayer(r.receiver_document_number, 'RECEIVER');

                t_receiv(r.receiver_document_number).cnpj := r.receiver_document_number;
                print('analizando retorno receiver cnpj =>' || r.receiver_document_number);
                print(t_receiv(r.receiver_document_number).info);
                print('fim da informação de receiver');
                --
                update rmais_receiver_info
                set
                    info = t_receiv(r.receiver_document_number).info
                where
                        cnpj = r.receiver_document_number
                    and type = 'RECEIVER';

                print('verificação update linhas => ' || sql%rowcount);
                if sql%rowcount = 0 then
                    print('entrando para gravação.');
                    ins_receiv(t_receiv(r.receiver_document_number));
                end if; 
                --
                print('Chamada WS Receiver.');
                print(t_receiv(r.receiver_document_number).info);
                --
            end if;
            --
            begin
                -- Conforme gravado na chamada anterior, irá incluir informação do tomador na tabela headers.
                for r1 in (
                    select
                        a.info.data.establishment_id taxpayer_id,
                        a.info
                    from
                        rmais_receiver_info a
                    where
                            cnpj = r.receiver_document_number
                        and info is not null
                        and rownum = 1
                ) loop
                    --
                    print('Carregando Receiver ' || r1.taxpayer_id);
                    --
                    r_efd.rhea.receiver_info := r1.info;
                    r_efd.rhea.receiver_taxpayer_id := r1.taxpayer_id;
                    --
                end loop;
                --
            exception
                when others then
                    print('Falha ao carregar informações do Estabelecimento '
                          || r.receiver_document_number
                          || ' ' || sqlerrm);
            end;    
            -- Inclusão de status válido para o documento, atentar para que tenha sempre os status neste if para que possa validar.
            r_efd.rhea.document_status := 'V';
            r_efd.rhea.org_id := get_registrationid(r_efd.rhea.receiver_document_number);
            -- Variável auxiliar, na qual começa zerada para que seja feito o número de linhas da nota.
            ix_l := 0;
            --

            begin
            --
                for rl in (
                    select
                        *
                    from
                        rmais_efd_lines
                    where
                        efd_header_id = r.efd_header_id
                    order by
                        line_number
                ) loop
                --
                    ix_l := r_efd.rlin.count + 1;
                --
                    r_efd.rlin(ix_l).rlin := rl;
                --
                    print('r_Efd.rHea.document_type 2                   : ' || r_efd.rhea.document_type);
                    print('r_Efd.rLin(ix_l).rLin.status 2               : ' || r_efd.rlin(ix_l).rlin.status);
                    print('r_Efd.rLin(ix_l).rLin.source_doc_line_id 2   : ' || r_efd.rlin(ix_l).rlin.source_doc_line_id);
                    print('r_Efd.rLin(ix_l).rLin.source_document_type 2 : ' || r_efd.rlin(ix_l).rlin.source_document_type);
                --
                    set_line_info(r_efd, ix_l);
                --
                    print('r_Efd.rHea.document_type 3                   : ' || r_efd.rhea.document_type);
                    print('r_Efd.rLin(ix_l).rLin.status 3               : ' || r_efd.rlin(ix_l).rlin.status);
                    print('r_Efd.rLin(ix_l).rLin.source_doc_line_id 3   : ' || r_efd.rlin(ix_l).rlin.source_doc_line_id);
                    print('r_Efd.rLin(ix_l).rLin.source_document_type 3 : ' || r_efd.rlin(ix_l).rlin.source_document_type);
                --Na primeira interação, é verificado se possui fornecedor e data de vencimento, caso não possua, a nota deverá ser invalidada.                
                    if r_efd.rlin(ix_l).rlin.source_document_type is null then
                    --
                        if r_efd.rhea.model = '55' then
                            r_efd.rlin(ix_l).rlin.source_document_type := get_cfop_lin_type(r_efd.rlin(ix_l).rlin.cfop_from);

                        elsif r_efd.rhea.model = 'BO' then
                            r_efd.rlin(ix_l).rlin.source_document_type := 'NA';
                        else
                            r_efd.rlin(ix_l).rlin.source_document_type := 'PO';
                        end if;
                    --
                    end if;                
                --
                    if ix_l = 1 then
                    --validando fornecedor.
                    --
                        for r1 in (
                            select
                                a.info.data.party_id taxpayer_id,
                                a.info
                            from
                                rmais_issuer_info a
                            where
                                    cnpj = r.issuer_document_number
                                and r_efd.rhea.vendor_site_code is null
                        ) loop
                        --
                            print('Carregando Issuer ' || r1.taxpayer_id);
                        --
                            print('r1.info: ' || substr(r1.info, 1, 3000));
                            r_efd.rhea.issuer_info := r1.info;
                            r_efd.rhea.issuer_taxpayer_id := r1.taxpayer_id;
                        --
                            if r_efd.rhea.model != '98'
                            or r_efd.rhea.vendor_site_code is null then
                                r_efd.rhea.vendor_site_code := nvl(
                                    json_value(r1.info, '$.DATA.ADDRESS.VENDOR_SITE_CODE'),
                                    r_efd.rhea.vendor_site_code
                                );
                            end if;
                        --
                            print('r_Efd.rHea.vendor_site_code: ' || r_efd.rhea.vendor_site_code);
                        -- Ajustado incluindo um parametro de sempre puxar o primeiro cadastro.

                            if r_efd.rhea.vendor_site_code is null then --verificar se não tem array de endereços
                            --
                                begin
                                --
                                    select
                                        a.vendor_site_code
                                    into r_efd.rhea.vendor_site_code
                                    from
                                            json_table ( replace(
                                                replace(r_efd.rhea.issuer_info,
                                                        '"DATA":{',
                                                        '"DATA":[{'),
                                                '}}}',
                                                '}}]}'
                                            ), '$'
                                                columns (
                                                    party_name varchar2 ( 500 ) path '$.P_TAX_PAYER_NUMBER',
                                                    party_name2 varchar2 ( 500 ) path '$.DATA.PARTY_NAME',
                                                    nested path '$.DATA.ADDRESS[*]'
                                                        columns (
                                                            vendor_site_code varchar2 ( 100 ) path '$.VENDOR_SITE_CODE'
                                                        )
                                                )
                                            )
                                        a;
                                --WHERE replace(vendor_site_code,' ','') = replace(r_Efd.rHea.issuer_document_number,' ','')
                                    print('r_Efd.rHea.vendor_site_code2: ' || r_efd.rhea.vendor_site_code);
                                --
                                exception
                                    when too_many_rows then 
                                    --
                                        log_efd('Possui mais de um vendor site code para este fornecedor.',
                                                null,
                                                r_efd.rhea.efd_header_id);
                                        r_efd.rhea.document_status := 'I';
                                    --
                                    --Print('Não localizado Array');
                                    --
                                    when others then
                                        log_efd('Fornecedor Não Localizado',
                                                null,
                                                r_efd.rhea.efd_header_id);
                                        r_efd.rhea.document_status := 'FI';
                                end;
                            --
                            end if;
                        --                        
                        end loop;
                    --Validar anexo extra para notas de serviço.
                        if
                            1 = 0
                            and r_efd.rhea.model = '00'
                        then
                            select
                                max(efd_header_id)
                            into l_extra
                            from
                                rmais_anexos_complementares
                            where
                                efd_header_id = p_header_id;

                            if l_extra is null then
                            --
                                log_efd('Anexo extra não localizado.',
                                        r_efd.rlin(ix_l).rlin.efd_line_id,
                                        r_efd.rhea.efd_header_id);

                                r_efd.rhea.document_status := 'I';
                            --
                            end if;

                        end if; 
                    --
                        if (
                            r_efd.rhea.model = '98'
                            and r_efd.rlin(ix_l).rlin.combination_descr is null
                        )
                        or (
                            r_efd.rhea.model != '98'
                            and r_efd.rlin(ix_l).rlin.item_code_efd is null
                        ) then
                        --
                            get_item_erp(r_efd.rhea.issuer_document_number,
                                         r_efd.rhea.receiver_document_number,
                                         r_efd.rlin(ix_l).rlin.item_description,
                                         r_efd.rlin(ix_l).rlin.fiscal_classification,
                                         r_efd.rlin(ix_l).rlin.item_code_efd,
                                         r_efd.rlin(ix_l).rlin.item_descr_efd,
                                         r_efd.rlin(ix_l).rlin.uom_to,
                                         r_efd.rlin(ix_l).rlin.uom_to_desc,
                                         r_efd.rlin(ix_l).rlin.fiscal_classification_to,
                                         r_efd.rlin(ix_l).rlin.catalog_code_ncm,
                                         r_efd.rlin(ix_l).rlin.item_type,
                                         r_efd.rlin(ix_l).rlin.combination_descr,
                                         l_icms_rate,
                                         l_user_defined,
                                         l_cfop_from,
                                         l_cfop_to,
                                         r_efd.rlin(ix_l).rlin.withholding);
                        --                                     
                            if
                                nvl(l_icms_rate, -1) > 0
                                and l_icms_rate = r_efd.rlin(ix_l).rlin.icms_rate
                            then
                                r_efd.rlin(ix_l).rlin.user_defined := l_user_defined;
                            end if;
                        --
                            if
                                nvl(l_cfop_from, -1) > 0
                                and l_cfop_from = r_efd.rlin(ix_l).rlin.cfop_from
                            then
                                r_efd.rlin(ix_l).rlin.cfop_to := l_cfop_to;
                            end if;
                        --
                        end if;
                    --
                    end if;                
                --
                    print('r_Efd.rHea.document_type 1                   : ' || r_efd.rhea.document_type);
                    print('r_Efd.rLin(ix_l).rLin.status 1               : ' || r_efd.rlin(ix_l).rlin.status);
                    print('r_Efd.rLin(ix_l).rLin.source_doc_line_id 1   : ' || r_efd.rlin(ix_l).rlin.source_doc_line_id);
                    print('r_Efd.rLin(ix_l).rLin.source_document_type 1 : ' || r_efd.rlin(ix_l).rlin.source_document_type);
                    print('DEBUG 1 - Pré verificação PO ou NA.');
                    if nvl(r_efd.rlin(ix_l).rlin.source_document_type,
                           'PO') = 'PO' then
                    --
                        print('Nota com PO => ' || r_efd.rlin(ix_l).rlin.source_document_type);
                        if r_efd.rlin(ix_l).rlin.source_doc_line_id is null
                           or (
                            r_efd.rlin(ix_l).rlin.source_doc_line_id is not null
                            and nvl(r_efd.rlin(ix_l).rlin.status,
                                    '$') not in ( 'MANUAL' )
                        ) then
                        --
                            delete from rmais_efd_distributions
                            where
                                efd_line_id = rl.efd_line_id;
                        --
                            delete from rmais_efd_shipments shp
                            where
                                shp.efd_line_id = rl.efd_line_id;
                        --
                            print('Buscando Informações da Po...'
                                  || rl.efd_line_id
                                  || ' ix_l: ' || ix_l);
                        --
                        end if;
                    --
                        if rl.efd_header_id not in ( 524394, 524395, 524396, 524397, 524398,
                                                     524399, 524400, 524401, 524402, 524403,
                                                     524404, 524405, 524406, 524407, 524408,
                                                     524409, 524410, 524411, 524412, 524413 ) then
                            get_po_line(r_efd, ix_l, l_transaction_id);
                        end if;
                    --
                    elsif nvl(r_efd.rlin(ix_l).rlin.source_document_type,
                              'PO') = 'NA' then
                    --
                        print('*** Linha identificada como S/ Pedido ***');
                    --
                        if r_efd.rhea.model in ( 'BO' ) then 
                        --
                            r_efd.rlin(ix_l).rlin.status := '';
                        --
                        end if;
                    --
                        if
                            r_efd.rhea.model in ( '06', '23', '24' )
                            and r_efd.rhea.cliente_cod is not null
                        then
                            print('buscar combinação contábil.');
                            r_efd.rlin(ix_l).rlin.combination_descr := get_combinacao_concessionarias(r_efd.rhea.cliente_cod);

                        elsif r_efd.rhea.model = '98' then
                            null;--r_Efd.rLin(ix_l).rLin.COMBINATION_DESCR := get_combinacao_guias(r_Efd.rHea.vendor_site_code,r_Efd.rHea.receiver_document_number);
                        end if;
                    --
                        if
                            r_efd.rhea.model in ( 'BO' )
                            and r_efd.rhea.boleto_cod is null
                        then
                        --
                            log_efd('Boleto de Cobrança sem Código de Barras. Solicitar correção para o Suporte.',
                                    r_efd.rlin(ix_l).rlin.efd_line_id,
                                    r_efd.rhea.efd_header_id);
                        --
                            r_efd.rlin(ix_l).rlin.status := 'INVALID';
                        --
                        end if;
                    --
                        print('DOCUMENT STATUS DEBUG r_Efd.rHea.document_status:' || r_efd.rhea.document_status);
                    --
                        if
                            r_efd.rhea.model not in ( '98', '23', '24', '25', '06',
                                                      '22', 'BO' )
                            and r_efd.rlin(ix_l).rlin.item_code_efd is null
                        then
                        --
                            log_efd('Item De/Para não cadastrado no ERP. Favor fazer setup e revalidar documento.',
                                    r_efd.rlin(ix_l).rlin.efd_line_id,
                                    r_efd.rhea.efd_header_id);
                        --
                            r_efd.rlin(ix_l).rlin.status := 'INVALID';
                        --
                        end if;
                    --
                        r_efd.rlin(ix_l).rlin.status := nvl(r_efd.rlin(ix_l).rlin.status,
                                                            'VALID');
                    --
                    --verificação combinação contábil retirada pois sera reanalisada após alteração dos serviços do joviano.
                    --r_Efd.rLin(1).rLin.COMBINATION_DESCR := get_combinacao(r_Efd.rLin(1).rLin.COMBINATION_DESCR);
                    --
                        if
                            1 = 0
                            and r_efd.rlin(ix_l).rlin.combination_descr is null
                        then
                        --
                            r_efd.rlin(ix_l).rlin.status := 'INVALID';
                            log_efd('Não foi possível localizar combinação contábil.',
                                    r_efd.rlin(ix_l).rlin.efd_line_id,
                                    r_efd.rhea.efd_header_id);

                        end if;
                    --
                    /*
                    if r_Efd.rLin(ix_l).rLin.Withholding is null and r_Efd.rHea.model = '00' then
                        r_Efd.rLin(ix_l).rLin.status := 'INVALID';
                        Log_Efd('Não foi possível localizar grupo de retenção.',r_Efd.rLin(ix_l).rLin.efd_line_id, r_Efd.rHea.efd_header_id);
                    end if;
                    */
                    --
                        if
                            r_efd.rlin(ix_l).rlin.cfop_to is null
                            and nvl(r_efd.rhea.model,
                                    '00') in ( '55', '57', '67' )
                        then --AND r_Efd.rLin(ix_l).rLin.destination_type = 'EXPENSE' THEN
                        --             
                            begin
                          --
                                select
                                        case
                                            when r_efd.rhea.issuer_address_state <> r_efd.rhea.receiver_address_state then
                                                '2'
                                            else
                                                '1'
                                        end
                                        || cfop.cfop_in,
                                        cfop.utilization_id
                                into
                                    r_efd.rlin(ix_l).rlin.cfop_to,
                                    r_efd.rlin(ix_l).rlin.utilization_id
                                from
                                    rmais_cfop_out_in      cfop,
                                    rmais_utilization_cfop util
                                where
                                        cfop.utilization_id = util.id
                                    and cfop.cfop_out = substr(r_efd.rlin(ix_l).rlin.cfop_from,
                                                               2,
                                                               3);
                           --
                            exception
                                when no_data_found then
                          --
                                    r_efd.rlin(ix_l).rlin.status := 'INVALID';
                          --
                                    log_efd('Setup de De/Para de CFOP não localizado.',
                                            r_efd.rlin(ix_l).rlin.efd_line_id,
                                            r_efd.rhea.efd_header_id);
                          --
                                when too_many_rows then
                          --
                                    r_efd.rlin(ix_l).rlin.status := 'INVALID';
                          --
                                    log_efd('Mais de uma utilização para o CFOP de saída, faça o preenchimento manual.',
                                            r_efd.rlin(ix_l).rlin.efd_line_id,
                                            r_efd.rhea.efd_header_id);
                          --  
                            end;
                        --
                        elsif
                            r_efd.rlin(ix_l).rlin.cfop_to is null
                            and nvl(r_efd.rhea.model,
                                    '00') not in ( '55', '57', '67' )
                        then
                            print(
                                case
                                    when r_efd.rhea.issuer_address_state <> r_efd.rhea.receiver_address_state then
                                        '2933'
                                    else
                                        '1933'
                                end
                            );

                            r_efd.rlin(ix_l).rlin.cfop_to :=
                                case
                                    when r_efd.rhea.issuer_address_state <> r_efd.rhea.receiver_address_state then
                                        '2933'
                                    else
                                        '1933'
                                end;
                        --r_Efd.rLin(ix_l).rLin.utilization_id := 'Services';
                        end if;

                    end if;
                --
                    print('r_Efd.rHea.document_type                   : ' || r_efd.rhea.document_type);
                    print('r_Efd.rLin(ix_l).rLin.status               : ' || r_efd.rlin(ix_l).rlin.status);
                    print('r_Efd.rLin(ix_l).rLin.source_doc_line_id   : ' || r_efd.rlin(ix_l).rlin.source_doc_line_id);
                    print('r_Efd.rLin(ix_l).rLin.source_document_type : ' || r_efd.rlin(ix_l).rlin.source_document_type);
                --
                    if nvl(r_efd.rlin(ix_l).rlin.status,
                           '$') = 'INVALID' then -- apenas quando tiver pedido OR (r_Efd.rLin(ix_l).rLin.source_doc_line_id IS NULL AND nvl(r_Efd.rLin(ix_l).rLin.source_document_type,'PO') = 'PO')  THEN
                    --
                        r_efd.rhea.document_status := 'I';
                    --
                    end if;     
                --
                    begin
                    --
                        r_efd.rlin(ix_l).rlin.last_update_date := sysdate;
                    --
                        r_efd.rlin(ix_l).rlin.status := nvl(r_efd.rlin(ix_l).rlin.status,
                                                            'VALID');
                    --
                        print('Fazer update');
                        update rmais_efd_lines
                        set
                            row = r_efd.rlin(ix_l).rlin
                        where
                            efd_line_id = rl.efd_line_id;
                    --
                        print('Update OK');
                    exception
                        when others then
                            log_efd('Falha ao atulizar linha...' || sqlerrm, rl.efd_line_id, rl.efd_header_id);
                    end;
                --
                end loop;
            end;
            --
            begin
                --
                    --boleto procurarando nota de exato valor robson.
                    --se encontar nota vincula, se a nota tiver enviada, envia o boleto.
                    --nota procurando o boleto de exato valor.
                    
                    --GET_NF_RELAC_BOL(r_Efd.rHea);
                --
                print('Update header...' || r_efd.rhea.document_status);
                --
                if
                    p_user is null
                    and r_efd.rhea.document_status = 'V'
                then
                    --
                    print('Alterando status de Válido para Inválido');
                    --
                    r_efd.rhea.document_status := 'I';
                    --
                    print('Novo Status...' || r_efd.rhea.document_status);
                    --
                end if;
                --                
                r_efd.rhea.last_update_date := sysdate;
                --
                update rmais_efd_headers
                set
                    row = r_efd.rhea
                where
                    efd_header_id = r.efd_header_id;
                --
            exception
                when others then
                    log_efd('Falha ao atualizar Header ' || sqlerrm, '', r.efd_header_id);
            end;
            --
            begin
                --
                --inclusão de email para envio 
                if
                    p_user is null
                    and r_efd.rhea.email_approve is not null
                then
                    send_mail(p_header_id,/*r_Efd.rHea.EMAIL_APPROVE*/ 'erickson.mattos@rm.digital', null);
                end if;
                --encerramento email para envio
                --
                if
                    nvl(r_efd.rhea.document_status,
                        'I') = 'V'
                    and nvl(
                        rmais_process_pkg_email.get_parameter('SEND_ERP_AUTO'),
                        '2'
                    ) = '1'
                    --  AND get_status_lines(r_Efd.rHea.efd_header_id) = 'AUTO' 
                    and xxrmais_util_v2_pkg.get_send_invoice_exception(r_efd.rhea.efd_header_id)
                then
                    --
                    commit;
                    --
                    xxrmais_util_v2_pkg.send_invoice_erp(r_efd.rhea.efd_header_id);
                    --
                end if;
                --
            end;
            --
            if g_set_workflow then
                --
                if
                    g_log_workflow is null
                    and r_efd.rhea.document_status = 'V'
                then
                    g_log_workflow := 'Documento Válido';
                end if;
                --
                rmais_process_pkg_email.set_workflow(p_header_id,
                                                     g_log_workflow,
                                                     nvl(
                                 v('APP_USER'),
                                 '-1'
                             ));
                --
            end if;

        end loop;
        --
    exception
        when others then
            print('Falha no processamento de NFs ' || sqlerrm);
    end main;
    --
    function get_itens (
        p_transaction_id number,
        p_item           varchar2,
        p_item_descr     varchar2,
        p_org_code       varchar2 default null
    ) return number as
    --
        l_body clob := '{
        "transaction_id": ":1",
        "item_number": ":2",
        "item_desc": ":3",
        "item_id": "",
        "org_name": "",
        "bu_code": "",
        "bu_name": "",
        "org_code": ""
    }';
    begin
     --
        l_body := replace(l_body, ':1', p_transaction_id);
     --
        if p_item is null then
            l_body := replace(l_body, ':2', '');
        else
            l_body := replace(l_body,
                              ':2',
                              upper(p_item));
        end if;
     --
        if p_item_descr is null then
            l_body := replace(l_body, ':3', '');
        else
            l_body := replace(l_body,
                              ':3',
                              upper(p_item_descr));
        end if;
    /*
     IF p_org_code IS NULL THEN
       l_body := REPLACE(l_body,':4','');
     ELSE
       l_body := REPLACE(l_body,':4',upper(p_org_code));
     END IF;
     --
     */
        return to_number ( json_value(get_response(
            get_parameter('GET_ITENS_URL'),
            l_body,
            'POST'
        ),
           '$.transaction_id') );
     --
    exception
        when others then
      --
            print('Error na busca de itens: ' || sqlerrm);
            return '';
      --
    end get_itens;
  --
    function get_bu_cnpj (
        p_cnpj varchar2
    ) return varchar2 as
        l_return varchar2(50);
    begin
      --
        select
            org1.cnpj
        into l_return
        from
            rmais_organizations org1,
            rmais_organizations org2
        where
                org1.bu_flag = 'Y'
            and org1.bu_code = org2.bu_code
            and org2.cnpj = p_cnpj;
      /*SELECT DISTINCT cnpj_bu
        INTO l_return
        FROM rmais_bu_orgs
       WHERE (to_number(cnpj_bu) = to_number(p_cnpj) OR to_number(cnpj_lru) = to_number(p_cnpj));*/
      --
        return l_return;
      --
    exception
        when others then
      --
            return p_cnpj;
      --
    end get_bu_cnpj;
  --
    function get_cc_concessionaria (
        p_efd_header_id number,
        p_efd_line_id   number
    ) return varchar2 as
  --
        l_ret varchar2(1000);
    begin
    --
        select
            '01'
            || '.'
            || lpad(
                regexp_replace(bu_code, '[^[:digit:]]'),
                4,
                '0'
            )
            || '.'
            || rmt.cod2
            || '.'
            || rmc.conta
            || '.'
            || cod3
            || '.'
            || cod4
            || '.'
            || '0.0' cc
        into l_ret
        from
            rmais_organizations  ro,
           -- rmais_efd_headers rmh,
            rmais_efd_lines      rml,
            rmais_match_bu_types rmt,
            rmais_cc_type_match  rmc
        where
                1 = 1--to_number(ro.cnpj) = to_number(rmh.receiver_document_number)
            and rmt.id = rml.fiscal_classification_to
            and rmc.type = rmt.type
            and to_number(rmt.id_bu) = ro.id
        --and rml.efd_header_id = rmh.efd_header_id
            and rml.fiscal_classification_to <> '-1'
            and rml.efd_line_id = p_efd_line_id
        union
        select
            *
        from
            (
                select distinct
                    '01'
                    || '.'
                    || lpad(
                        regexp_replace(bu_code, '[^[:digit:]]'),
                        4,
                        '0'
                    )
                    || '.'
                    || rmt.cod2
                    || '.'
                    || rmc.conta
                    || '.'
                    || cod3
                    || '.'
                    || cod4
                    || '.'
                    || '0.0' cc 
        --INTO l_ret
                from
                    rmais_organizations  ro,
               -- rmais_efd_headers rmh,
                    rmais_efd_lines      rml,
                    rmais_match_bu_types rmt,
                    rmais_cc_type_match  rmc
                where
                        1 = 1--to_number(ro.cnpj) = to_number(rmh.receiver_document_number)
                    and rmt.id = rml.fiscal_classification_to
                    and rmc.type = '-1'
                    and to_number(rmt.id_bu) = ro.id
            --and rml.efd_header_id = rmh.efd_header_id
                    and rml.fiscal_classification_to <> '-1'
                    and rml.efd_line_id <> p_efd_line_id
                    and rml.efd_header_id = p_efd_header_id
                    and exists (
                        select
                            1
                        from
                            rmais_efd_lines
                        where
                                efd_line_id = p_efd_line_id
                            and fiscal_classification_to = '-1'
                    )
                order by
                    decode('0001', 1, 2)
            )
        where
            rownum = 1;
    --
        return replace(l_ret, ' ', '');
    --
    exception
        when others then
            return '';
    end;
  --
    --
    function get_descr_concessionaria (
        p_efd_header_id number,
        p_efd_line_id   number
    ) return varchar2 as
  --
        l_ret varchar2(1000);
    begin
    --
        select
            bu_code
            || ' - '
            || rmt.cod2 cc
        into l_ret
        from
            rmais_organizations  ro,
            rmais_efd_headers    rmh,
            rmais_efd_lines      rml,
            rmais_match_bu_types rmt,
            rmais_cc_type_match  rmc
        where
                to_number(ro.cnpj) = to_number(rmh.receiver_document_number)
            and rmt.id = rml.fiscal_classification_to
            and rmc.type = rmt.type
            and rml.efd_header_id = rmh.efd_header_id
            and rml.fiscal_classification_to <> '-1'
            and rml.efd_line_id = p_efd_line_id
        union
        select distinct
            bu_code
            || ' - '
            || rmt.cod2 cc 
        --INTO l_ret
        from
            rmais_organizations  ro,
            rmais_efd_headers    rmh,
            rmais_efd_lines      rml,
            rmais_match_bu_types rmt,
            rmais_cc_type_match  rmc
        where
                to_number(ro.cnpj) = to_number(rmh.receiver_document_number)
            and rmt.id = rml.fiscal_classification_to
            and rmc.type = '-1'
            and rml.efd_header_id = rmh.efd_header_id
            and rml.fiscal_classification_to <> '-1'
            and rml.efd_line_id <> p_efd_line_id
            and rml.efd_header_id = p_efd_header_id
            and exists (
                select
                    1
                from
                    rmais_efd_lines
                where
                        efd_line_id = p_efd_line_id
                    and fiscal_classification_to = '-1'
            )
            and rownum = 1;
    --
        return l_ret;
    --
    exception
        when others then
            return '';
    end;
  --
  --
    function get_cc_cod_cliente (
        p_efd_header_id number
    ) return varchar2 as
  --
        l_ret varchar2(1000);
    begin
    --
        select
            rmt.cod1
        into l_ret
        from
            rmais_match_bu_types rmt,
            rmais_efd_lines      rml
        where
                rmt.id = rml.fiscal_classification_to
            and rml.fiscal_classification_to <> 1
            and rml.efd_header_id = p_efd_header_id--:P7_EFD_HEADER_ID
            and rownum = 1;
    --
        return l_ret;
    --
    exception
        when others then
            return '';
    end get_cc_cod_cliente;
  --
    procedure generate_attachments (
        p_efd_header_id number
    ) as
    --
    begin
        --
        print('Iniciando');
        --
        delete rmais_attachments
        where
            efd_header_id = p_efd_header_id
            or creation_date < sysdate - 1; --limpando registros
        --
        --FOR nf IN (SELECT  nvl(pdf_file,XLS_FILE) pdf_file , nvl(pdf_filename,XLS_FILENAME) pdf_filename, MODEL , access_key_number , issuer_address_city_code , document_number FROM rmais_efd_headers WHERE efd_header_id = p_efd_header_id)LOOP
        for nf in (
            select
                *
            from
                rmais_monta_lst_anexos
            where
                efd_header_id = p_efd_header_id
        ) loop
            --
            if nf.model in ( '55', '57', '67' ) then
                --chamada para ws base64 de layout via xml
                declare
                    l_clob           clob;
                    l_transaction_id number;
                    l_reponse        clob;
                begin
                    --
                    print('Funcionou o inicio');
                    select
                        json_value(source_doc_orig, '$.xml' returning clob)
                    into l_clob
                    from
                        rmais_ctrl_docs   rct,
                        rmais_efd_headers rh
                    where
                            rct.id = rh.doc_id
                        and rh.efd_header_id = p_efd_header_id;
                    --
                    print('Inserindo ws');
                    --     
                    insert_ws_info(l_transaction_id, 'REPORT_SEFAZ', l_clob);
                    --
                    print('l_transaction_id: ' || l_transaction_id);            
                    --chamada WS para gerar report
                    commit;
                    --
                    declare
                        l_body clob;
                        l_url  varchar2(300) := rmais_process_pkg_email.get_parameter('URL_GET_PDF');
                    begin
                        l_body :=
                            json_object(
                                'transaction_id' value l_transaction_id,
                                'method' value
                                    case nf.model
                                        when '55' then
                                            'NFE'
                                        when '57' then
                                            'CTE'
                                        when '67' then
                                            'CTEOS'
                                        else
                                            'NFE'
                                    end,
                                'url' value null
                            );
                        --
                        print('l_body: ' || l_body);
                        --
                        l_reponse := get_response2(
                            utl_url.escape(l_url),
                            l_body,
                            'POST'
                        );
                        --
                        print('l_reponse2323: ' || l_reponse);
                        --
                        if nvl(
                            json_value(l_reponse, '$.status'),
                            'ERROR'
                        ) = 'success' then
                            begin
                                --
                                print('Inserindo anexos RMAIS_ATTACHMENTS');
                                --
                                select
                                    clob_info
                                into l_clob
                                from
                                    rmais_ws_info
                                where
                                    transaction_id = l_transaction_id;
                                --
                                insert into rmais_attachments values ( p_efd_header_id,
                                                                       l_clob,
                                                                       null,
                                                                       nf.access_key_number || '.pdf',
                                                                       'PDF',
                                                                       sysdate );
                                --                                   
                            end;
                            ---
                        end if;
                        --
                    end;
                    --
                exception
                    when others then
                        -- 
                        print('Error NFE: ' || sqlerrm);
                        -- 
                        --
                        raise_application_error(-20022, 'Não foi possível gerar anexo');
                end;

            else
                --
                if
                    nf.pdf_file is not null
                    and nf.pdf_filename is not null
                then
                    --
                    insert into rmais_attachments values ( p_efd_header_id,
                                                           replace(
                                                               replace(
                                                                   replace(
                                                                       replace(
                                                                           xxrmais_util_pkg.base64encode(nf.pdf_file),
                                                                           chr(10),
                                                                           ''
                                                                       ),
                                                                       chr(13),
                                                                       ''
                                                                   ),
                                                                   chr(09),
                                                                   ''
                                                               ),
                                                               ' ',
                                                               ''
                                                           ),
                                                           null,
                                                           nf.pdf_filename,
                                                           case
                                                               when upper(nf.pdf_filename) like '%PDF%' then
                                                                   'PDF'
                                                               when upper(nf.pdf_filename) like '%XLS%' then
                                                                   'XLSX'
                                                               else
                                                                   'PDF'
                                                           end--  nf.pdf_filename
                                                           ,
                                                           sysdate );
                    --
                else
                    if
                        nf.issuer_address_city_code in ( '3550308',  --Sao paulo
                         '3505708' --Barueri
                         )
                        and nf.model = '00'
                    then
                      --chamada WS para gerar report
                        declare
                            l_clob           clob;
                            l_transaction_id number;
                            l_reponse        clob;
                        begin
                            --
                            print('Inserindo REPORT_NFSE');
                            insert_ws_info(l_transaction_id, 'REPORT_NFSE', l_clob);
                            print('inserido insert_ws_info');
                            --
                            declare
                                l_link varchar2(1000) := xxrmais_util_v2_pkg.get_link_nfse(p_efd_header_id);
                                l_body clob;
                                l_url  varchar2(300) := rmais_process_pkg_email.get_parameter('URL_GET_PDF'); --parametrizar endereço
                            begin
                                l_body :=
                                    json_object(
                                        'transaction_id' value l_transaction_id,
                                        'method' value nf.issuer_address_city_code,
                                        'url' value l_link
                                    );
                                --
                                print('l_body: ' || l_body);
                                --
                                l_reponse := get_response2(l_url, l_body, 'POST');
                                --
                                print('l_reponse: ' || l_reponse);
                                --
                                if nvl(
                                    json_value(l_reponse, '$.status'),
                                    'ERROR'
                                ) = 'success' then
                                    begin
                                        --
                                        select
                                            clob_info
                                        into l_clob
                                        from
                                            rmais_ws_info
                                        where
                                            transaction_id = l_transaction_id;
                                        --
                                        insert into rmais_attachments values ( p_efd_header_id,
                                                                               l_clob,
                                                                               null,
                                                                               'Nfse_'
                                                                               || nf.document_number
                                                                               || '.pdf',
                                                                               'PDF',
                                                                               sysdate );
                                        -- 
                                        print('Registro inserindo na RMAIS_ATTACHMENTS');
                                        --                                  
                                    end;
                                    ---
                                end if;
                                --
                            end;

                        end;

                    end if;
                end if;
                --        
            end if;
            --  
        end loop;
        --
    exception
        when others then
            raise_application_error(-20011, 'Não foi possível gerar anexos ' || sqlerrm);
    end generate_attachments;

    function get_bu_name (
        p_cnpj varchar2
    ) return varchar2 as
        l_ret varchar2(500);
    begin
        select
            a.bu_code
        into l_ret
        from
            (
                select
                    org.id,
                    sup.nome          cliente_id,
                    org.nome,
                    org.cnpj,
                    org.endereco,
                    org.cep,
                    nvl(bu_flag, 'N') bu_flag,
                    org.bu_code
                from
                    rmais_organizations org,
                    rmais_suppliers     sup
                where
                    org.cliente_id = sup.id
            ) a
        where
            cnpj = p_cnpj;

        return l_ret;
    exception
        when others then
            return '';
    end get_bu_name;
  --
    procedure set_workflow (
        p_efd_header_id in varchar2,
        p_descricao     in varchar2,
        p_usuario       in varchar2
    ) is

        l_status                 varchar2(10);
        l_user                   varchar2(300);
        l_invoice_number         rmais_invoices_workflow.invoice_number%type;
        l_invoice_amount         number;
        l_issuer_document_number varchar2(30);
        --PRAGMA AUTONOMOUS_TRANSACTION;
    begin
        /*########################################################################################################*/
        /*Procedure criada para execução de workflow para alterações efetuadas no status da nf e na validação main*/
        /*Desenvolvido por erickson na data de 03/07/2023 demanda solicitada por Victor Orsi*/
        /*########################################################################################################*/
        commit;
        select
            document_status,
            nvl(rmais_process_pkg_email.g_first_main, p_usuario),
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
            rmais_efd_headers
        where
            efd_header_id = p_efd_header_id;

        insert into rmais_invoices_workflow values ( p_efd_header_id,
                                                     l_status,
                                                     nvl(p_descricao, l_status),
                                                     l_user,
                                                     sysdate,
                                                     l_invoice_number,
                                                     l_issuer_document_number,
                                                     l_invoice_amount );
        --commit;
        --exception when others then
            --print(sqlerrm);
    end set_workflow;
    --
    function get_combinacao_concessionarias (
        pr_cliente_cod in rmais_efd_headers.cliente_cod%type
    ) return rmais_efd_lines.combination_descr%type is
        l_combinacao rmais_efd_lines.combination_descr%type;
    begin
        select
            cod2
            || '.'
            || cod4
            || '.'
            || conta
            || '.00000.0.0'
        into l_combinacao
        from
                 rmais_match_bu_types a
            inner join rmais_cc_type_match b on a.type = b.type
        where
            a.id = pr_cliente_cod;

        return l_combinacao;
    exception
        when others then
            return '';
    end;
    --
    function get_combinacao_guias (
        pr_vendor_site_code         in rmais_efd_headers.vendor_site_code%type,
        pr_receiver_document_number in rmais_efd_headers.receiver_document_number%type
    ) return rmais_efd_lines.combination_descr%type is
        l_combinacao rmais_efd_lines.combination_descr%type;
    begin
        select distinct
            flex_value
            || '.'
            || centro_custo
            || '.'
            || conta_contabil
            || '.00000.0.0'
        into l_combinacao
        from
                 rmais_estrutura_contabil a
            inner join rmais_organizations    b on b.nome = a.lru
            inner join rmais_combinacao_guias c on c.cnpj_receiver = b.cnpj
        where
                c.cnpj_receiver = pr_receiver_document_number
            and c.fk_site = pr_vendor_site_code
            and flex_value_set_id = 65002
            and length(flex_value) = 5;

        return l_combinacao;
    exception
        when others then
            return '';
    end get_combinacao_guias;
    --
    /*
    function get_combinacao(p_code_combination in varchar2)  return varchar2 is
        l_combination varchar2(200);
    begin
        l_combination := p_code_combination;
        if l_combination is null then
            return null;
        end if;
        begin
            select
                l_combination into l_combination 
            from RMAIS_gl_code_combination 
            where
                SEGMENT1 = regexp_substr (l_combination,'[^-]+',1,1) and
                SEGMENT2 = regexp_substr (l_combination,'[^-]+',1,2) and
                SEGMENT3 = regexp_substr (l_combination,'[^-]+',1,3) and
                SEGMENT4 = regexp_substr (l_combination,'[^-]+',1,4) and
                SEGMENT5 = regexp_substr (l_combination,'[^-]+',1,5) and
                SEGMENT6 = regexp_substr (l_combination,'[^-]+',1,6) and
                SEGMENT7 = regexp_substr (l_combination,'[^-]+',1,7) and
                SEGMENT8 = regexp_substr (l_combination,'[^-]+',1,8) and 
                SEGMENT9 = regexp_substr (l_combination,'[^-]+',1,9) and 
                ENABLED_FLAG = 'Y';
            return l_combination;
            exception when no_data_found then
                    return null;
        end;
    end;
    --
    */
    function get_response_v3 (
        p_url    varchar2,
        p_body   clob,
        p_method varchar2 default 'GET'
    ) return clob is
        l_response clob := empty_clob();
    begin
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        l_response := apex_web_service.make_rest_request(
            p_url         => p_url,
            p_http_method => p_method,
            p_username    => 'admin',
            p_password    => 'admin',
            p_body        => p_body
        );
        /*
        if apex_web_service.g_status_code in ('200','201') then
            return l_response;  
        end if;
        */
        return l_response;
    exception
        when others then
            print(utl_http.get_detailed_sqlerrm);
            print('Error get_response2: ' || sqlerrm);
    end;
    --
    function get_ship_to_location (
        p_cnpj varchar2
    ) return varchar2 is
        l_ship varchar2(100);
    begin
        select
            location
        into l_ship
        from
            rmais_ship_to_location
        where
                cnpj = p_cnpj
            and rownum = 1;

        return l_ship;
    exception
        when others then
            return '';
    end;
    --
    procedure set_po_lines_auto (
        p_linhas_nota  in varchar2,
        p_pedido       in varchar2,
        o_retorno      out varchar2,
        p_linha_pedido in varchar2
    ) as

        l_erros               clob;
        l_validacao           boolean := true;
        l_po                  varchar2(50);
        l_po_line_id          varchar2(50);
        l_quant_po            varchar2(50);
        l_unit_price_po       varchar2(50);
        l_line_location_id    varchar2(50);
        l_po_header_id        varchar2(50);
        l_info_po             varchar2(4000);
        l_item_number         varchar2(50);
        l_descr               varchar2(50);
        l_info_item           varchar2(4000);
        l_term_info           varchar2(4000);
        l_source_doc_line_num varchar2(50);
        l_uom                 varchar2(50);
        l_destination_type    varchar2(50);
        l_ncm                 varchar2(50);
        l_uom_desc_po         varchar2(50);
    begin
        execute immediate q'[alter session set NLS_NUMERIC_CHARACTERS='.,']';
        for rw in (
            select
                line_number,
                efd_line_id,
                line_quantity,
                unit_price,
                item_code_efd
            from
                rmais_efd_lines
            where
                efd_line_id in (
                    select
                        regexp_substr(p_linhas_nota, '[^:]+', 1, level) line_id
                    from
                        dual
                    connect by
                        level <= regexp_count(p_linhas_nota, ':') + 1
                )
            order by
                1
        ) loop
            --
            l_validacao := true;
            begin
                select
                    c001 pedido,
                    n001 po_line_id,
                    replace(
                        to_char(n004),
                        '.',
                        ','
                    )    line_quantity_po_s_t,
                    c010 unit_price,
                    n005 line_location_id,
                    c009 po_header_id,
                    c006 info_po,
                    c007 item_number,
                    c012 item_info,
                    c011 term_info,
                    n002 line_num,
                    c003 uom_code,
                    c014 destination_type,
                    c015 ncm,
                    c016 uom_desc
                into
                    l_po,
                    l_po_line_id,
                    l_quant_po,
                    l_unit_price_po,
                    l_line_location_id,
                    l_po_header_id,
                    l_info_po,
                    l_item_number,
                    l_info_item,
                    l_term_info,
                    l_source_doc_line_num,
                    l_uom,
                    l_destination_type,
                    l_ncm,
                    l_uom_desc_po
                from
                    apex_collections a
                where
                        collection_name = 'RMAIS_PO_OK'
                    and c001 = p_pedido
                    --and c015 =  rw.item_code_efd
                    and nls_num_char(c010) = nls_num_char(rw.unit_price)
                    and nls_num_char(n004) >= nls_num_char(rw.line_quantity)
                    and ( p_linha_pedido is null
                          or p_linha_pedido = n002 );
                --iniciar validações...
                if
                    1 = 0
                    and l_item_number is null
                then
                    l_validacao := false;
                    l_erros := l_erros
                               || rw.line_number
                               || ' => Item não informado na PO.<br>';
                else
                    --
                    if nls_num_char(rw.unit_price) != nls_num_char(l_unit_price_po) then
                        l_validacao := false;
                        l_erros := l_erros
                                   || rw.line_number
                                   || ' => Valor da linha divergente.<br>';
                    end if;
                    --
                    if nls_num_char(rw.line_quantity) > nls_num_char(l_quant_po) then
                        l_validacao := false;
                        l_erros := l_erros
                                   || rw.line_number
                                   || ' => Quantidade insuficiente na PO.<br>';
                    end if;
                    --
                end if;
                --
                --l_validacao := true;
                --l_erros := 'OK';
                if l_validacao then
                    << apos_validacao_incluir_po >> begin
                        update rmais_efd_lines
                        set
                            source_doc_number = l_po,
                            source_doc_line_id = l_po_line_id,
                            source_doc_id = l_po_header_id,
                            line_location_id = l_line_location_id,
                            order_info = l_info_po,
                            item_code_efd = l_item_number,
                            item_descr_efd = l_item_number,
                            item_info = l_info_item,
                            uom_to = l_uom,
                            uom_to_desc = l_uom_desc_po,
                            source_doc_line_num = l_source_doc_line_num,
                            source_document_type = 'PO',
                            destination_type = l_destination_type,
                            fiscal_classification_to = l_ncm,
                            status = 'MANUAL'
                        where
                            efd_line_id = rw.efd_line_id;

                    end;
                end if;
                --
            exception
                when no_data_found then
                    l_erros := l_erros
                               || rw.line_number
                               || ' => Linha PO não encontrada, verificar valor unitário, quantidade, Item ou NCM.<br>';
                when too_many_rows then
                    l_erros := l_erros
                               || rw.line_number
                               || ' => Possui mais de uma linha para mesmo valor unitário.<br>';
                when others then
                    l_erros := l_erros
                               || rw.line_number
                               || ' => Contacte o administrador.<br>'
                               || sqlerrm;
            end;    
        --
        end loop;

        execute immediate q'[alter session set NLS_NUMERIC_CHARACTERS=',.']';
        o_retorno := nvl(l_erros, 'OK');
    end set_po_lines_auto;
    --
    procedure debug_log_teste (
        p_header_id in number,
        p_job_name  varchar2 default null
    ) as
        pragma autonomous_transaction;
    --
    begin
        if get_parameter('DEBUG_LOG') = '1' then
            --
            insert into rmais_upload_log (
                creation_date,
                log,
                efd_header_id,
                job_name,
                file_name
            ) values ( sysdate,
                       rmais_global_pkg.g_log,
                       p_header_id,
                       p_job_name,
                       'LOG' );
            --
            commit;
            --
        end if;
    exception
        when others then
            print('Erro debug_log_teste: ' || sqlerrm);
    end debug_log_teste;
    --
    procedure send_invoice_v3 (
        p_header_id in number
    ) is
        --
        l_transaction_id     number;
        --
        l_return             clob;
        l_body               clob;
        l_body_send          clob;
        l_status             rmais_efd_headers.document_status%type;
        --
        l_model              varchar2(100);
        l_bol_id             number;
        l_bol_filename       varchar2(4000);
        --
        l_start_tag          varchar2(50) := '<title>';
        l_end_tag            varchar2(50) := '</title>';
        l_start_index        number;
        l_end_index          number;
        l_error_title        varchar2(1000);
        l_timeout_invoice_id number;
        --    
        l_url                varchar2(400) := rmais_process_pkg_email.get_ws
                               || get_parameter('SEND_INVOICE_AP_URL_V4')
                               || '/N';
        l_response           clob;
        l_loop_count         number := 0;
        --
        l_cnpj               rmais_efd_headers.receiver_document_number%type;
        l_creation_date      rmais_efd_headers.creation_date%type;
        --
        l_resposta_anexo     varchar2(50);
    begin
        --
        print('Iniciando Send_Invoice_v3');
        --
        print('Verificando status da nota');
        --
        select
            document_status,
            model,
            receiver_document_number,
            creation_date
        into
            l_status,
            l_model,
            l_cnpj,
            l_creation_date
        from
            rmais_efd_headers
        where
            efd_header_id = p_header_id;
        --
        if l_status in ( 'T', 'Y' ) then
            print('Nota já integrada');
            return;
        end if;
		--        
        print('Enviando ao AP: ' || p_header_id);
		--
        if nvl(l_status, 'V') = 'V' then
			--
            print('Gerando anexo da nota.');
			--
            generate_attachments(p_header_id);
			--
            commit;
            --
			-- BEGIN
			-- 	--
			-- 	print('Pré body 1');
			-- 	l_body  := REPLACE (ASCIISTR (Get_Invoice_v2(p_header_id)), '\', '\u'); 
			-- 	--
			-- EXCEPTION WHEN OTHERS THEN
			-- 	--
			-- 	print('Pré body 2');
			-- 	l_body := Get_Invoice_v2(p_header_id);
			-- 	--
			-- END;
			--
            select
                doc
            into l_body
            from
                vw_get_invoice
            where
                efd_header_id = p_header_id;

            select
                doc
            into l_body
            from
                vw_get_invoice
            where
                efd_header_id = p_header_id;
            --
            print('Pré body 3');
            l_body := xxrmais_util_pkg.base64encode(xxrmais_util_pkg.clob_to_blob(l_body));
			--
            print('Pré body 4');
            l_body := replace(
                replace(
                    replace(
                        replace(l_body,
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
            );
			--
            print('Pré body 5');
            l_body := '{"BASE64":"'
                      || l_body
                      || '"}';
			--
            if get_parameter('DEBUG_LOG') = '1' then
				--
                print('Guardando l_body na RMAIS_UPLOAD_LOG');
				--
                insert into rmais_upload_log (
                    creation_date,
                    log,
                    efd_header_id,
                    file_name,
                    job_name
                ) values ( sysdate,
                           replace(
                               replace(
                                   replace(
                                       replace(l_body,
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
                           ),
                           p_header_id,
                           'L_BODY',
                           'send_invoice_v3' );
				--
                commit;
				--
            end if;
			--
            commit;
			--
            begin
				--
                print('Entrando na chamada WS');
				--
                print('l_url: ' || l_url);
				--
                begin
                    print('l_body: ' || l_body);
                exception
                    when others then
                        print('l_body muito grande.');
                end;
				-- 
                begin
					--
                    begin
                        print('Pré Get_response3 ' || to_char(sysdate, 'DD/MM/RRRR HH24:MI:SS'));
                        l_response := rmais_process_pkg_email.get_response_v3(l_url, l_body, 'POST');
                        print('Pós Get_response3 ' || to_char(sysdate, 'DD/MM/RRRR HH24:MI:SS'));
						-- 
                        l_response := replace(l_response, 'o:error', 'oerror');
						--
                    exception
                        when others then
                            print('Erro ao fazer chamada WS: ' || sqlerrm);
                    end;
					--
                    if get_parameter('DEBUG_LOG') = '1' then
						--
                        print('Guardando l_response na RMAIS_UPLOAD_LOG');
						--
                        insert into rmais_upload_log (
                            creation_date,
                            log,
                            efd_header_id,
                            file_name,
                            job_name
                        ) values ( sysdate,
                                   l_response,
                                   p_header_id,
                                   'L_RESPONSE',
                                   'send_invoice_v3' );
						--
                        commit;
						--
                    end if;
					--
					/*   Cenarios: 1 - Resposta HTML (erro)    - html
									   1.1 - Timeout           - html
									   1.2 - Outros            - html
								   2 - Resposta mapeada (erro) - json
								   3 - Resposta Oracle         - json
									   3.1 - Sucesso Oracle    - json
									   3.2 - Erro Oracle       - json 
								   4 - Resposta Nula (erro)    - null */
					--
                    if l_response like '%</html>%' then  -- Cenario: 1 - Erro HTML - html
						--
                        print('Erro HTML');
						--
                        --print(substr(l_response,0,32000));
                        --
                        l_loop_count := l_loop_count + 1;
						--
                        begin
							--
                            l_start_index := instr(l_response, l_start_tag) + length(l_start_tag);
                            l_end_index := instr(l_response, l_end_tag, l_start_index);
							--
                            print('l_start_tag: ' || l_start_tag);
                            print('l_end_tag: ' || l_end_tag);
                            print('l_start_index: ' || l_start_index);
                            print('l_end_index: ' || l_end_index);
							-- calculando l_error_title:
                            if
                                l_start_index > 0
                                and l_end_index > 0
                            then
								--
                                l_error_title := substr(l_response, l_start_index, l_end_index - l_start_index);
                                print('Title: ' || l_error_title);
                            else
                                print('Title não encontrado');
                                l_error_title := 'ERRO';
                            end if;
							--
                            if upper(l_error_title) like '%504%'
                               or upper(l_error_title) like '%TIME-OUT%'
                            or upper(l_error_title) like '%TIMEOUT%' then -- Cenário: 1.1 - Erro de Timeout
								--
                                print('Time-Out detectado');
								--
                                print('Timeout ao enviar nota: '
                                      || p_header_id || ' .');
								--
                                update rmais_efd_headers
                                set
                                    document_status = 'E',
                                    last_update_date = sysdate
                                where
                                    efd_header_id = p_header_id;
								--
                                commit;
								--
                                set_workflow(p_header_id,
                                             l_error_title,
                                             nvl(
                                    v('APP_USER'),
                                    '-1'
                                ));
								--
                                log_efd(l_error_title, null, p_header_id, 'Erro'); 
								--
								/*
								IF l_bol_id is not null THEN
									--
									print('Colocar boleto na fila de aguardo');
									--
									UPDATE RMAIS_EFD_HEADERS
									   SET DOCUMENT_STATUS = 'AO'
										  ,INTEGRATED = 'Y'
										  ,last_update_date = SYSDATE
									 WHERE EFD_HEADER_ID = l_bol_id;
									--
									commit;
									--
									set_workflow(l_bol_id,'Documento enviado para a Fila de Timeout',nvl(v('APP_USER'),'-1'));
									--
								END IF;
								--
								commit;
								--
								Log_Efd('Timeout identificado: documento enviado para fila de aguardo de resposta do Oracle',null,p_header_id, 'Erro'); 
								--
								BEGIN
									--
									print('Inserindo dados na tabela de Timeout.');
									--
									insert into RMAIS_TIMEOUT (id, efd_header_id, BOL_ID, creation_date, PROCESS_COUNT)
									values (RMAIS_TIMEOUT_S.nextval, p_header_id,l_bol_id, sysdate,0);
									--
									COMMIT;
									--
								EXCEPTION WHEN OTHERS THEN
									--
									print('Erro ao inserir dados na tabela de Timeout: '||sqlerrm);
									--
								END;
								*/
								--
                            else    -- Cenário: 1.2 - Erro html
								--
								--
                                print('Erro ao enviar nota: '
                                      || p_header_id || ' .');
								--
                                update rmais_efd_headers
                                set
                                    document_status = 'E',
                                    last_update_date = sysdate
                                where
                                    efd_header_id = p_header_id;
								--
                                commit;
								--
                                set_workflow(p_header_id,
                                             l_error_title,
                                             nvl(
                                    v('APP_USER'),
                                    '-1'
                                ));
								--
                                log_efd(l_error_title, null, p_header_id, 'Erro'); 
								--
								--
                            end if;
							--
                        exception
                            when others then
                                --
                                print('Erro ao buscar o title: ' || sqlerrm);
                                l_error_title := 'ERRO';
                                --
                                --
                                print('Erro ao enviar nota: '
                                      || p_header_id || ' .');
                                --
                                update rmais_efd_headers
                                set
                                    document_status = 'E',
                                    last_update_date = sysdate
                                where
                                    efd_header_id = p_header_id;
                                --
                                commit;
                                --
                                set_workflow(p_header_id,
                                             l_error_title,
                                             nvl(
                                    v('APP_USER'),
                                    '-1'
                                ));
                                --
                                log_efd(l_error_title, null, p_header_id, 'Erro'); 
                                --
                        end;
                        --
                    end if;
					-- 
                    if l_loop_count = 0 then -- Cenario de Erro: 2 - Erro Mapeado - json
						--
                        for m in (
                            select
                                *
                            from
                                json_table ( l_response, '$'
                                    columns (
                                        retorno varchar2 ( 4000 ) path '$.retorno'
                                    )
                                )
                            where
                                retorno is not null
                        ) loop
							--
                            print('Erro Mapeado');
							--
                            l_loop_count := l_loop_count + 1;
							--
                            print('Erro ao enviar nota: '
                                  || p_header_id || '.');
							--
                            update rmais_efd_headers
                            set
                                document_status = 'E',
                                last_update_date = sysdate
                            where
                                efd_header_id = p_header_id;
							--
                            commit;
							--
                            set_workflow(p_header_id,
                                         m.retorno,
                                         nvl(
                                v('APP_USER'),
                                '-1'
                            ));
							--
                            log_efd(m.retorno, null, p_header_id, 'Erro'); 
							--
                        end loop;
						--
                    end if;
					--
                    if l_loop_count = 0 then  -- Cenario 3 - resposta Oracle
						--
                        for r in (
                            select
                                *
                            from
                                json_table ( l_response, '$'
                                    columns (
                                        code varchar2 ( 4000 ) path '$.code',
                                        invoice_id number path '$.InvoiceId',
                                        created_by varchar ( 4000 ) path '$.CreatedBy',
                                        mensagem varchar ( 4000 ) path '$.msg',
                                        nested path '$.retorno' -- dados de erro
                                            columns (
                                                title varchar2 ( 4000 ) path '$.title',
                                                status varchar2 ( 4000 ) path '$.status',
                                                nested path '$.oerrorDetails[*]'
                                                    columns (
                                                        detail varchar2 ( 4000 ) path '$.detail',
                                                        error_code varchar2 ( 4000 ) path '$.oerrorCode',
                                                        error_path varchar2 ( 4000 ) path '$.oerrorPath'
                                                    )
                                            ),
                                        nested path '$.attachments.items[*]' -- dados de boleto
                                            columns (
                                                attachment_id number path '$.AttachedDocumentId',
                                                filename varchar2 ( 4000 ) path '$.FileName'
                                            )
                                    )
                                )
                        ) loop
							--
                            l_loop_count := l_loop_count + 1;
							--
                            print('l_loop_count: ' || l_loop_count);
                            print('Code: ' || r.code);
							--print('Retorno: '||r.retorno);
                            print('invoice_id: ' || r.invoice_id);
                            print('attachment_id: ' || r.attachment_id);
                            print('filename: ' || r.filename);
                            print('Atualizando status da nota');
							--
                            if r.invoice_id is not null then -- Cenario 3.1 - resposta Oracle -- Caso de nota enviada com sucesso -- Pode passar mais de 1 vez por causa do boleto
								--
                                if l_loop_count = 1 then 
									--
                                    print('invoice_id: '
                                          || r.invoice_id || ' . Nota enviada ao ERP com sucesso');
									--
                                    print('Atualizando dados do documento fiscal para Integrado');
									--
                                    update rmais_efd_headers
                                    set
                                        document_status = 'T',
                                        invoice_id = r.invoice_id
--										,attachment_id = r.attachment_id										
                                        ,
                                        last_update_date = sysdate
                                    where
                                        efd_header_id = p_header_id;
									--
                                    commit;
									--
                                    set_workflow(p_header_id,
                                                 'Enviado para ERP (AP)',
                                                 nvl(
                                        v('APP_USER'),
                                        '-1'
                                    ));
									--
                                    log_efd('Enviado para ERP (AP)', null, p_header_id, 'Integrado'); -- Criando Sumario de validação
									--
                                    xxrmais_util_v2_pkg.create_event(p_header_id, 'Submissão ERP (AP)', 'Id: '
                                                                                                        || p_header_id
                                                                                                        || ' - Invoice_Id: '
                                                                                                        || r.invoice_id, 'SISTEMA'); -- Criando Evento
									--
                                    --início de envio de anexo
                                    send_anexo(
                                        p_efd_header_id => p_header_id,
                                        p_invoice_id    => r.invoice_id,
                                        p_todos         => 1,
                                        p_resposta      => l_resposta_anexo
                                    );
                                    --fim de envio de anexo
                                end if;
								--
                            elsif
                                r.invoice_id is null
                                and r.detail is not null
                            then -- Cenario 3.2 - Erro Oracle 
								-- 
                                print('Erro ao enviar nota: '
                                      || p_header_id
                                      || ' - : ' || l_loop_count);
								--
                                if l_loop_count = 1 then
									--
                                    print('Atualizando dados do documento fiscal para Erro');
									--
                                    update rmais_efd_headers
                                    set
                                        document_status = 'E',
                                        last_update_date = sysdate
                                    where
                                        efd_header_id = p_header_id;
									--
                                    commit;
									--
                                    set_workflow(p_header_id,
                                                 'Erro ao enviar nota.',
                                                 nvl(
                                        v('APP_USER'),
                                        '-1'
                                    ));
									--
                                end if;
								--
                                log_efd(r.detail, null, p_header_id, 'Erro'); 
								--
                            else 
								--
                                print('Erro Oracle não identificado');
                                l_loop_count := 0;
								--
                            end if;
							--
                            commit;
							--
                        end loop;
						--
                    end if;
					--
                    if l_loop_count = 0 then
						--
                        print('Atualizando dados do documento fiscal para Erro');
						--
                        update rmais_efd_headers
                        set
                            document_status = 'E',
                            last_update_date = sysdate
                        where
                            efd_header_id = p_header_id;
						--
                        commit;
						--
                        set_workflow(p_header_id,
                                     'Erro não identificado',
                                     nvl(
                            v('APP_USER'),
                            '-1'
                        ));
						--
                        begin
							--
                            log_efd('Erro não identificado: ' || l_response, null, p_header_id, 'Erro');
							--
                        exception
                            when others then
                                --
                                log_efd('Erro não identificado.', null, p_header_id, 'Erro');
                                --
                        end;
						--
                    end if;
					--
                    print('l_loop_count fim da procedure: ' || l_loop_count);
					--
                exception
                    when others then
                        print('Erro: ' || sqlerrm);
                end;
				--
            exception
                when others then
                    --
                    print('Erro ao chamar WS send_invoice_v3: ' || sqlerrm);
                    --
            end;
			--
        end if;
		--
        debug_log_teste(p_header_id, 'send_invoice_v3');
        -- 
        commit;
        --
    exception
        when others then
            --
            print('Send Invoice v3 ERROR: ' || sqlerrm);
            --
            update rmais_efd_headers
            set
                document_status = 'E',
                last_update_date = sysdate
            where
                efd_header_id = p_header_id;
            --
            commit;
            --
            set_workflow(p_header_id,
                         'Erro ao enviar documento',
                         nvl(
                v('APP_USER'),
                '-1'
            ));
            --
            log_efd('Erro ao enviar documento: ' || sqlerrm, null, p_header_id, 'Erro'); 
            --
            debug_log_teste(p_header_id, 'send_invoice_v3');
            --
    end send_invoice_v3;
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
                rmais_efd_headers
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
            update rmais_efd_headers
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
        rmais_process_pkg_email.set_workflow(p_efd_header_id,
                                             'Nota reprocessada.',
                                             nvl(
                         v('APP_USER'),
                         '-1'
                     ));
        --
        print('Terminando');
    end reprocess_header;
    --
    procedure send_cert_dig_v2 (
        p_cnpj     in varchar2,
        p_tomador  in varchar2,
        p_file     in clob,
        p_pass     in varchar2,
        p_exp_date in out date
    ) as

        l_url_mod  constant varchar2(1000) := rmais_process_pkg_email.get_parameter('URL_VALID_CERT');
        l_response clob;
        l_body_doc clob;
        l_status   varchar2(2);
        l_retorno  varchar2(4000);
    begin
        --
        print('Iniciando Envio e Validação do Certificado Digital');
        --
        print('URL: ' || l_url_mod);
        print('p_cnpj: ' || p_cnpj);
        print('p_tomador: ' || p_tomador);
        print('p_pass: ' || p_pass);
        --print('p_file: '||p_file);
        --

        select
                json_object(
                    'arq' value p_file,
                    'pass' value p_pass,
                    'empresa' value p_tomador,
                    'cnpj' value p_cnpj
                returning clob)
            a
        into l_body_doc
        from
            dual;
        --
        --
        if get_parameter('DEBBUG_LOG') = '1' then
            --
            print('Guardando l_body na RMAIS_UPLOAD_LOG');
            --
            insert into rmais_upload_log (
                id,
                creation_date,
                log,
                file_name,
                job_name
            ) values ( rmais_upload_log_seq.nextval,
                       sysdate,
                       l_body_doc,
                       'L_BODY',
                       'send_cert_dig_v2' );
            --
            commit;
            --
        end if;
        -- 
        --
        print('l_url_mod: ' || l_url_mod);
        --print ('l_body_doc: '||l_body_doc);
        -- 
        l_response := rmais_process_pkg_email.get_response_v3(l_url_mod, l_body_doc, 'POST');
        --
        --
        if get_parameter('DEBBUG_LOG') = '1' then
            --
            print('Guardando l_response na RMAIS_UPLOAD_LOG');
            --
            insert into rmais_upload_log (
                id,
                creation_date,
                log,
                file_name,
                job_name
            ) values ( rmais_upload_log_seq.nextval,
                       sysdate,
                       l_response,
                       'L_RESPONSE',
                       'send_cert_dig_v2' );
            --
            commit;
            --
        end if;
        --
        print('l_reponse1: ' || l_response);
        --
        for x in (
            select
                code,
                msg,
                          --case when code = '200' then trim(replace(replace(msg,'O Certificado Digital Expira no dia: ',''),'O Certificado Digital Expirou no dia: ','')) else '' end retorno
                case
                    when msg like '%O Certificado Digital Expira no dia:%' then
                        trim(replace(msg, 'O Certificado Digital Expira no dia: ', ''))
                    when msg like '%O Certificado Digital Expirou no dia:%' then
                        trim(replace(msg, 'O Certificado Digital Expirou no dia: ', ''))
                    else
                        ''
                end retorno
            from
                json_table ( l_response, '$'
                    columns (
                        code varchar2 ( 4000 ) path '$.data.code',
                        msg varchar2 ( 4000 ) path '$.data.msg'
                    )
                )
            where
                code is not null
        ) loop
            --
            print('Code: ' || x.code);
            print('Msg: ' || x.msg);
            --
            --l_retorno := x.msg;
            --
            if x.retorno is not null then 
                --
                p_exp_date := to_date ( x.retorno,
                'DD/MM/RRRR' );
                --
            else 
                --
                p_exp_date := null;
                --
            end if;
            --
        end loop;
        --
        --return l_retorno;
        debug_log_teste(null, 'send_cert_dig_v2');
        --
    exception
        when others then 
        --
            print('Erro ao enviar Certificado Digital: ' || sqlerrm);
        --
        --return 'Erro';
            debug_log_teste(null, 'send_cert_dig_v2');
        --
    end send_cert_dig_v2;
    --
    procedure split_line (
        p_line_id    number,
        p_po_line_id varchar2,
        p_receipt    varchar2,
        p_discount   number default null,
        p_seq        varchar2
    ) as

        l_rowl        rmais_efd_lines%rowtype;
        l_rowh        rmais_efd_headers%rowtype;
        l_amount_ctrl number;
        l_count_split number := regexp_count(p_po_line_id, ':') + 1;
    begin
    --
        select
            *
        into l_rowl
        from
            rmais_efd_lines
        where
            efd_line_id = (
                select
                    nvl(efd_line_id_parent, efd_line_id)
                from
                    rmais_efd_lines
                where
                    efd_line_id = p_line_id
            );
        --
        select
            *
        into l_rowh
        from
            rmais_efd_headers
        where
            efd_header_id = l_rowl.efd_header_id;
        --
        print('');
        print('Header_id......: ' || l_rowl.efd_header_id);
        print('');
        --
        l_rowl.efd_line_id_parent := l_rowl.efd_line_id;--linha inicial mesmo id do efd_line_id
        --
        l_rowl.cfop_to := null;
        l_rowl.utilization_id := null;
        l_rowl.utilization_code := null;
        --
        begin
            --
            print('Excluindo linhas splitadas anteriormente');
            --
            delete rmais_efd_lines
            where
                    efd_line_id_parent = l_rowl.efd_line_id
                and efd_line_id <> l_rowl.efd_line_id
                and efd_header_id = l_rowl.efd_header_id;
            --
        exception
            when others then
                print('Error ao deletar: ' || sqlerrm);
        end;
        --
        if (
            l_rowl.efd_line_id_parent is null
            and l_rowl.line_amount_original is null
        )
        or --split inicial
         ( l_rowl.efd_line_id_parent = l_rowl.efd_line_id ) --garantindo que está na primeira linha mesmo após splitado            
         then
            if l_rowl.line_amount_original is null then
                --
                print('Linha identificada como split inicial - Armazenando valor Original');
                --
                l_rowl.line_amount_original := l_rowl.line_amount;
                l_rowl.unit_price_original := nvl(l_rowl.unit_price_original, l_rowl.unit_price);
                l_rowl.quantity_original := nvl(l_rowl.quantity_original, l_rowl.line_quantity);
                --
            end if;
            --
            for pid in (
                with pline (
                    shuttle_item,
                    receipt_num,
                    seq
                ) as  --abrindo pedidos pelo po_line_id
                 (
                    select
                        p_po_line_id,
                        p_receipt,
                        p_seq
                    from
                        dual
                )
                select
                    regexp_substr(shuttle_item, '[^:]+', 1, level) po_line_id,
                    regexp_substr(receipt_num, '[^:]+', 1, level)  receipt_num,
                    regexp_substr(seq, '[^:]+', 1, level)          seq
                from
                    pline
                connect by
                    level <= regexp_count(shuttle_item, ':') + 1
            ) loop
                --
                l_rowl.efd_line_id := nvl(l_rowl.efd_line_id, rmais_efd_lines_s.nextval);
                --
                print('PO_LINE_ID: ' || pid.po_line_id);
                --
                begin
                    select
                        c001               pedido,
                        n001               po_line_id,
                        c009               po_header_id,
                        n005               line_location_id,
                        c006               info_po,
                        c007               item_number,
                        c002               item_description,
                        c012               item_info,
                        c003               uom_code,
                        n002               line_num,
                        --NLS_NUM_CHAR
                        --replace(c010,'.',',')   unit_price,
                        nls_num_char(c010) unit_price,
                        replace(
                            to_char(n004),
                            '.',
                            ','
                        )                  quantity_line,
                        ( to_number(replace(c010, '.', ',')) * ( n004 ) ) -
                        case
                            when nvl(p_discount, 0) > 0 then
                                    ( p_discount / l_count_split )
                            else
                                0
                        end
                        tot,-- + replace(nvl(c017,'0'),'.',',')tot,
                        'PO'               typ,
                        'MANUAL'           status,
                        nvl(p_discount, 0),
                        c024               receipt_num,
                        c025               receipt_line_num
                    into
                        l_rowl.source_doc_number,
                        l_rowl.source_doc_line_id,
                        l_rowl.source_doc_id,
                        l_rowl.line_location_id,
                        l_rowl.order_info,
                        l_rowl.item_code_efd,
                        l_rowl.item_descr_efd,
                        l_rowl.item_info,
                        l_rowl.uom_to,
                        l_rowl.source_doc_line_num,
                        l_rowl.unit_price,
                        l_rowl.line_quantity,
                        l_rowl.line_amount,
                        l_rowl.source_document_type,
                        l_rowl.status,
                        l_rowl.discount_line_amount,
                        l_rowl.receipt_num,
                        l_rowl.receipt_line_num
                    from
                        apex_collections a
                    where
                            collection_name = 'RMAIS_PO_OK'
                        and n001 = pid.po_line_id
                        and nvl(c024, 'NA') = nvl(pid.receipt_num, 'NA')
                        and seq_id = pid.seq;

                exception
                    when others then
                        print('Não foi encontrado o pedido na tabela temporária apex_collection ERROR: ' || sqlerrm);
                        raise_application_error(-20012, 'Não foi possível splitar a linha, erro apex_colletion ' || sqlerrm);
                end;
                --
                if
                    l_rowl.line_amount_original < l_rowl.line_quantity
                    and l_rowl.unit_price = 1
                then --corrigindo valor caso split tenha sido efetuado com desconto
                    l_rowl.line_quantity := l_rowl.line_amount_original;
                    l_rowl.line_amount := l_rowl.line_amount_original;
                end if;

                l_rowl.last_update_date := sysdate;
                --
                if l_rowl.efd_line_id = l_rowl.efd_line_id_parent then
                    --
                    begin
                        --
                        update rmais_efd_lines
                        set
                            row = l_rowl
                        where
                            efd_line_id = p_line_id;
                        --
                        print('Registro atualizado da primeira linha');
                    exception
                        when others then
                            raise_application_error(-20012, 'Não foi possível atualizar linhas ' || sqlerrm);
                    end;
                    --
                else
                    --
                    insert into rmais_efd_lines values l_rowl;
                    --
                    print('Split inserido');
                    --
                end if;
                --
                l_rowl.line_number := l_rowl.line_number + 1;
                l_rowl.efd_line_id := null; --zerando id para próxima linha
                --
            end loop;
            --
            print('');
            print('--------------------');
            print('');
            --
        end if;
        --
        --correção de numero das linhas
        --
        declare
            l_aux number := 0;
        begin
            for up in (
                select
                    *
                from
                    rmais_efd_lines
                where
                    efd_header_id = l_rowl.efd_header_id
                order by
                    efd_line_id_parent,
                    efd_line_id asc,
                    line_number
            ) loop
               --
                l_aux := l_aux + 1;
                update rmais_efd_lines
                set
                    line_number = l_aux
                where
                    efd_line_id = up.efd_line_id;
               --
            end loop;
            --
        end;

    exception
        when others then
            raise_application_error(-20022, 'Erro fatal - ' || sqlerrm);
    end;
    --
    procedure clear_split (
        p_line_id number
    ) as
    begin
        --
        delete rmais_efd_lines
        where
                efd_line_id_parent = p_line_id
            and efd_line_id <> p_line_id;
        --
        update rmais_efd_lines
        set
            efd_line_id_parent = '',
            line_amount = nvl(unit_price_original * quantity_original, line_amount)
        where
            efd_line_id = p_line_id;
        --
    end;
    --
    procedure send_anexo (
        p_efd_header_id in number,
        p_invoice_id    in number,
        p_todos         in number default 1,
        p_resposta      out varchar2
    ) is

        l_url                varchar2(200) := rmais_process_pkg_email.get_ws || get_parameter('SEND_ANEXOS');
        l_body               clob := empty_clob();
        l_response           clob := empty_clob();
        l_attacheddocumentid number;
    begin
        print(l_url);
        if p_todos = 1 then   
            --         
            select
                    json_object(
                        'invoiceId' is p_invoice_id,
                                'fileName' is substr(
                            substr(
                                upper(at.filename),
                                1,
                                instr(
                                    upper(at.filename),
                                    '.PDF'
                                ) - 1
                            ),
                            1,
                            50
                        )
                                              || substr(
                            upper(at.filename),
                            instr(
                                                     upper(at.filename),
                                                     '.PDF'
                                                 ),
                            4
                        ),
                                'title' is replace(
                            replace(substr(
                                substr(
                                    upper(at.filename),
                                    1,
                                    instr(
                                        upper(at.filename),
                                        '.PDF'
                                    ) - 1
                                ),
                                1,
                                50
                            )
                                    || substr(
                                upper(at.filename),
                                instr(
                                                             upper(at.filename),
                                                             '.PDF'
                                                         ),
                                4
                            ),
                                    '.pdf',
                                    ''),
                            '.PDF',
                            ''
                        ),
                                'description' is replace(
                            replace(substr(
                                substr(
                                    upper(at.filename),
                                    1,
                                    instr(
                                        upper(at.filename),
                                        '.PDF'
                                    ) - 1
                                ),
                                1,
                                50
                            )
                                    || substr(
                                upper(at.filename),
                                instr(
                                                             upper(at.filename),
                                                             '.PDF'
                                                         ),
                                4
                            ),
                                    '.pdf',
                                    ''),
                            '.PDF',
                            ''
                        ),
                                'category' is
                            case
                                when at.filename is not null then
                                    'From Supplier'
                                else
                                    ''
                            end,
                                'content' is at.clob_file
                    returning clob)
                doc
            into l_body
            from
                rmais_attachments at
            where
                efd_header_id = p_efd_header_id;

            print('Body anexo criado');
            print('url => ' || l_url);
            print('body => ' || substr(l_body, 1, 4000));
            l_response := rmais_process_pkg_email.get_response_v3(l_url, l_body, 'POST');
            print(l_response);
            l_attacheddocumentid := json_value(l_response, '$.AttachedDocumentId');
            if l_attacheddocumentid is not null then
                p_resposta := ( 'Anexo incluído (AP)!' );
                update rmais_efd_headers
                set
                    attacheddocumentid = l_attacheddocumentid
                where
                    efd_header_id = p_efd_header_id;

            else
                p_resposta := ( 'Não foi possível incluir o anexo no (AP).' );
            end if;
            --
            set_workflow(p_efd_header_id,
                         p_resposta,
                         nvl(
                v('APP_USER'),
                '-1'
            ));
    		--
            log_efd(p_resposta, null, p_efd_header_id, 'Integrado'); -- Criando Sumario de validação
    		--
            xxrmais_util_v2_pkg.create_event(p_efd_header_id, 'Submissão ERP (AP)', p_resposta); -- Criando Evento
            --
        end if;
        --
        for rw in (
            select
                *
            from
                rmais_anexos_complementares
            where
                    efd_header_id = p_efd_header_id
                and ( id_anexo_ap = '0'
                      or nvl(invoice_id, 0) != p_invoice_id )
        ) loop
            --null;

            select
                    json_object(
                        'invoiceId' is p_invoice_id,
                                'fileName' is substr(rw.filename, 1, 40)/*substr(SUBSTR(upper(rw.FILENAME),1,INSTR(upper(rw.FILENAME),'.PDF')-1),1,50)*/
                                              || substr(
                            upper(rw.filename),
                            instr(
                                                     upper(rw.filename),
                                                     '.'
                                                 )
                        ),
                                'title' is replace(
                            replace(substr(
                                substr(
                                    upper(rw.filename),
                                    1,
                                    instr(
                                        upper(rw.filename),
                                        '.PDF'
                                    ) - 1
                                ),
                                1,
                                50
                            )
                                    || substr(
                                upper(rw.filename),
                                instr(
                                                             upper(rw.filename),
                                                             '.PDF'
                                                         ),
                                4
                            ),
                                    '.pdf',
                                    ''),
                            '.PDF',
                            ''
                        ),
                                'description' is replace(
                            replace(substr(
                                substr(
                                    upper(rw.filename),
                                    1,
                                    instr(
                                        upper(rw.filename),
                                        '.PDF'
                                    ) - 1
                                ),
                                1,
                                50
                            )
                                    || substr(
                                upper(rw.filename),
                                instr(
                                                             upper(rw.filename),
                                                             '.PDF'
                                                         ),
                                4
                            ),
                                    '.pdf',
                                    ''),
                            '.PDF',
                            ''
                        ),
                                'category' is
                            case
                                when rw.filename is not null then
                                    'From Supplier'
                                else
                                    ''
                            end,
                                'content' is replace(
                            replace(
                                replace(
                                    replace(
                                        xxrmais_util_v2_pkg.base64encode_v2(fun_compact_un_blob(rw.blob_file)),
                                        chr(10),
                                        ''
                                    ),
                                    chr(13),
                                    ''
                                ),
                                chr(09),
                                ''
                            ),
                            ' ',
                            ''
                        )
                    returning clob)
                doc
            into l_body
            from
                dual;

            print('Body anexo criado');  
            --print(to_char(l_body));
            l_response := rmais_process_pkg_email.get_response_v3(l_url, l_body, 'POST');
            print(substr(l_response, 4000, 4000));
            l_attacheddocumentid := json_value(l_response, '$.AttachedDocumentId');
            if l_attacheddocumentid is not null then
                p_resposta := ( 'Anexo extra incluído AP!' );
                update rmais_anexos_complementares
                set
                    id_anexo_ap = l_attacheddocumentid,
                    invoice_id = p_invoice_id
                where
                    efd_header_id = p_efd_header_id;

            else
                p_resposta := ( 'Não foi possível incluir anexo extra no AP.' );
            end if; 
            --
            set_workflow(p_efd_header_id,
                         p_resposta,
                         nvl(
                v('APP_USER'),
                '-1'
            ));
    		--
            log_efd(p_resposta, null, p_efd_header_id, 'Integrado'); -- Criando Sumario de validação
    		--
            xxrmais_util_v2_pkg.create_event(p_efd_header_id, 'Submissão ERP (AP)', p_resposta); -- Criando Evento
            --  
        end loop;

    end send_anexo;
    --
    
    --
    procedure insert_ws_info_v2 (
        p_id        in out number,
        p_header_id number default null,
        p_method    varchar2 default 'GET_PO',
        p_clob      clob default null
    ) as
    begin
      --
        p_id := nvl(p_id, rmais_ws_info_s.nextval);
      --
        insert into rmais_ws_info (
            transaction_id,
            transaction_method,
            clob_info,
            creation_date,
            created_by,
            efd_header_id
        ) values ( p_id,
                   p_method,
                   p_clob,
                   sysdate,
                   'WS',
                   p_header_id );
      --
        commit;
      --
    exception
        when others then
      --
            print(sqlerrm);
      --
    end insert_ws_info_v2;
  --
    procedure send_boleto (
        p_efd_header_id in number,
        p_user          varchar2 default null,
        p_destination   varchar2 default null,
        p_doc_number    varchar2 default null
    ) as

        l_body     clob;
        l_url      varchar2(500) := get_ws || '/api/ap/v1/slip';
        l_response varchar2(4000);
        l_danfe    rmais_efd_headers.access_key_number%type;
        --
    begin
        --
        print('Iniciando send_boleto.');
        --
        select
                json_object(
                    'invoice_num' value rmh.document_number,
                            'invoice_date' value to_char(rmh.issue_date, 'YYYY-MM-DD'),
                            'due_date' value to_char(rmh.first_due_date, 'YYYY-MM-DD'),--verificar data de pagamento
                            'amount' value rmh.total_amount,
                            'barcode' value regexp_replace(rmh.boleto_cod, '[^[:digit:]]'),
                            'cnpj_paying' value rmh.receiver_document_number,
                            'name_paying' value(coalesce(replace(rmh.receiver_info.data.name,
                                                                 '-'
                                                                 || substr(rmh.receiver_info.data.organization_code,
                                                                           4),
                                                                 '')
                                                         || '-'
                                                         || substr(rmh.receiver_info.data.organization_code,
                                                                   4),
                                                         rmh.receiver_name)),
                            'cnpj_supplier' value rmh.issuer_document_number,
                            'name_supplier' value(coalesce(rmh.issuer_info.data.party_name,
                                                           (
                                                                          select
                                                                              max(l.order_info.vendor_name)
                                                                          from
                                                                              rmais_efd_lines l
                                                                          where
                                                                              l.efd_header_id = rmh.efd_header_id
                                                                      ),
                                                           rmh.issuer_name))
                ),
                access_key_number
        into
            l_body,
            l_danfe
        from
            rmais_efd_headers rmh
        where
            efd_header_id = p_efd_header_id;                       
        --
        begin
            --
            l_body := replace(
                asciistr(l_body),
                '\',
                '\u'
            );
            --
        exception
            when others then
            --
                null;
            --
        end;
        --
        if get_parameter('DEBBUG_LOG') = '1' then
            --
            print('Guardando l_body na RMAIS_UPLOAD_LOG');
            --
            insert into rmais_upload_log (
                id,
                creation_date,
                log,
                efd_header_id,
                file_name,
                job_name
            ) values ( rmais_upload_log_seq.nextval,
                       sysdate,
                       l_body,
                       p_efd_header_id,
                       'L_BODY',
                       'send_boleto' );
            --
            commit;
            --
        end if;
        --
        print('l_url: ' || l_url);
        print('Pré Get Response3');
        -- l_response := get_response_v3(l_url,l_body,'POST');
        l_response := get_response3(l_url, l_body, 'POST');
        print('Pós Get Response3');
        --
        print('Debug 0.1');
        if get_parameter('DEBBUG_LOG') = '1' then
            --
            print('Debug 1');
            print('Guardando l_response na RMAIS_UPLOAD_LOG');
            --
            insert into rmais_upload_log (
                id,
                creation_date,
                log,
                efd_header_id,
                file_name,
                job_name
            ) values ( rmais_upload_log_seq.nextval,
                       sysdate,
                       l_response,
                       p_efd_header_id,
                       'L_RESPONSE',
                       'send_boleto' );
            --
            commit;
            --
        end if;
        --
        print('Debug 2');
        if (
            l_response is not null
            and json_value(l_response, '$.id') is null
        )
        or l_response is null then
            --
            print('Debug 3');
            print('Falha ao enviar boleto - Contacte o administrador! - ' || l_response);
            --
            --xxrmais_util_v2_pkg.create_event (p_efd_header_id,'Boleto','Falha ao gerar boleto '||l_response||'Error: '||sqlerrm,'Sistema');
            --
            log_efd('Falha ao enviar boleto: ' || json_value(l_response, '$.message'),
                    '',
                    p_efd_header_id);
            --
            update rmais_efd_headers
            set
                document_status = 'E',
                last_update_date = sysdate
            where
                efd_header_id = p_efd_header_id;
            --
            commit;
            --
        else
            --
            print('Debug 4');
            print('l_response: ' || l_response);
            --
            print('Debug 5');
            --Log_Efd('Boleto aguardando confirmação de integração!','', p_efd_header_id);
            --
            xxrmais_util_v2_pkg.create_event(p_efd_header_id, 'Boleto', 'Boleto aguardando confirmação de integração!', 'Sistema');
            --
            declare
                l_bol_id number := to_number ( json_value(l_response, '$.id') );
            begin
                --
                insert into rmais_boletos_log values ( rmais_boletos_log_seq.nextval,
                                                       p_efd_header_id,
                                                       0,
                                                       '',
                                                       sysdate,
                                                      --nvl(get_username( get_current_user_id ),'-1'),
                                                       '-1',
                                                       sysdate,
                                                       '-1',
                                                       l_bol_id,
                                                       'N' );
                --
                declare
                    l_integ_id number;
                    l_ucm_id   number;
                begin
                    --
                    l_integ_id := rmais_integrated_docs_s.nextval;
                    l_ucm_id := to_number ( json_value(l_response, '$.ucm_file_id') );
                    --
                    update rmais_efd_headers
                    set
                        document_status = 'T',
                        bol_id = l_bol_id,
                        integrated = 'Y',
                        last_update_date = sysdate
                          --,destination_erp = nvl(p_destination,'COB')
                        ,
                        id_integration_cob = l_integ_id,
                        ucm_id = l_ucm_id
                    where
                        efd_header_id = p_efd_header_id;
                    --
                    commit;
                    --
                    insert into rmais_integrated_docs (
                        id,
                        access_key_number,
                        efd_header_id,
                        destination,
                        ucm_id,
                        bol_id,
                        bol_status,
                        creation_date,
                        created_by,
                        last_update_date,
                        updated_by
                    ) values ( l_integ_id,
                               l_danfe,
                               p_efd_header_id,
                               nvl(p_destination, 'COB'),
                               l_ucm_id,
                               l_bol_id,
                               'CREATED_RM',
                               sysdate,
                               p_user,
                               sysdate,
                               p_user );
                    --
                    commit;
                    --
                    set_workflow(p_efd_header_id,
                                 'Enviado para ERP (COB)',
                                 nvl(p_user, '-1'));--,'send_boleto');
					--
                    log_efd('Enviado para ERP (COB)', null, p_efd_header_id, 'Integrado'); -- Criando Sumario de validação
                    --
                    xxrmais_util_v2_pkg.create_event(p_efd_header_id, 'Submissão ERP (COB)', 'Id: '
                                                                                             || p_efd_header_id
                                                                                             || ' - Invoice_Id: '
                                                                                             || l_bol_id, 'SISTEMA'); -- Criando Evento
                    --
                    insert into rmais_integrated_erp (
                        integration_id,
                        access_key_number,
                        efd_header_id,
                        document_number,
                        doc_destination,
                        ucm_status,
                        ucm_id,
                        bol_id,
                        bol_status,
                        creation_date,
                        created_by,
                        last_event_date,
                        event_by
                    ) values ( l_integ_id,
                               l_danfe,
                               p_efd_header_id,
                               p_doc_number,
                               nvl(p_destination, 'COB'),
                               'CREATED_RM',
                               l_ucm_id,
                               l_bol_id,
                               'CREATED_RM',
                               sysdate,
                               p_user,
                               sysdate,
                               p_user );
                    --
                    commit;
                    --
                end;
                --
            exception
                when others then
                --
                    print('Erro ao gravar controle: ' || sqlerrm);
                --
            end;
            --
        end if;
        --
        debug_log_teste(p_efd_header_id, 'send_boleto');
        --
    exception
        when others then
        --
            log_efd('Falha geral ao enviar boleto. Erro: ' || sqlerrm, '', p_efd_header_id);
        --
            debug_log_teste(p_efd_header_id, 'send_boleto');
        --
    end send_boleto;
    --
    procedure status_boleto (
        p_count number default 6
    ) as
        l_count number := 0;
    --
    begin
        --
        for reg in (
            select
                id,
                id_transaction,
                count_process,
                efd_header_id
            from
                rmais_boletos_log
            where
                    count_process < p_count
                and nvl(status, 'N') <> 'P'
        )
        --
         loop
            --
            l_count := l_count + 1;
            --
            declare
            --
                l_url  varchar2(300) := '/api/ap/v1/slip/' || reg.id_transaction;
            --
                l_resp clob;
            --
            begin
                --
                l_resp := get_response_v3(l_url, '', 'GET');
                --
                print('Tentativa setada: ' || p_count);
                --
                print('l_resp; ' || l_resp);
                --
                if nvl(
                    json_value(l_resp, '$.integred_erp'),
                    'N'
                ) = 'Y' then
                    --
                    xxrmais_util_v2_pkg.create_event(reg.efd_header_id, 'Boleto', 'Boleto Integrado!', 'Sistema');
                    --
                    update rmais_boletos_log
                    set
                        count_process = count_process + 1,
                        log = l_resp,
                        last_update_date = sysdate,
                        last_user = '-1',
                        status = 'P'
                    where
                        id = reg.id;
                    -- 
                    update rmais_integrated_erp
                    set
                        bol_status = 'P',
                        ucm_id = json_value(l_resp, '$.ucm_file_id'),
                        bol_created_by = rmais_process_pkg_email.get_parameter('GET_USER_RM_OC')
                    where
                        bol_id = reg.id_transaction;
                    --
                    update rmais_integrated_docs
                    set
                        bol_status = 'P',
                        ucm_id = json_value(l_resp, '$.ucm_file_id')
                    where
                        bol_id = reg.id_transaction;
                    --
                else
                    --
                    if reg.count_process + 1 = p_count then
                        --
                        xxrmais_util_v2_pkg.create_event(reg.efd_header_id, 'Boleto', 'Não foi possível integrar o Boleto! Quantidade de tentativas: ' || p_count
                        , 'Sistema');
                        --
                        update rmais_boletos_log
                        set
                            count_process = count_process + 1,
                            log = l_resp,
                            last_update_date = sysdate,
                            last_user = '-1',
                            status = 'E'
                        where
                            id = reg.id;
                        -- 
                        update rmais_integrated_erp
                        set
                            bol_status = 'E'
                        where
                            bol_id = reg.id_transaction;
                        -- 
                        update rmais_integrated_docs
                        set
                            bol_status = 'E'
                        where
                            bol_id = reg.id_transaction;
                        --
                    else
                        --
                        update rmais_boletos_log
                        set
                            count_process = count_process + 1,
                            log = l_resp,
                            last_update_date = sysdate,
                            last_user = '-1',
                            status = 'N'
                        where
                            id = reg.id;
                        --
                    end if;
                    --
                end if; 
                --
            exception
                when others then
                --
                    declare
                        l_r clob := sqlerrm;
                --
                    begin
                    --
                        update rmais_boletos_log
                        set
                            count_process = count_process + 1,
                            log = 'Error Exception: ' || l_r,
                            last_update_date = sysdate,
                            last_user = '-1',
                            status = 'E'
                        where
                            id = reg.id;
                     --
                    end;
                --
            end;
            --
            commit;
            --
        end loop;
        --
        print(l_count || ' documentos processados');
        --
    exception
        when others then
        --
            null;
        --    
    end status_boleto;
    --
    function get_response3 (
        p_url     in varchar2,
        p_content in clob default null,
        p_type    in varchar2 default 'GET'
    ) return clob is

        v_response    clob;
        v_buffer      raw(32767);
        v_buffer_size number := 32767;
        v_offset      number := 1;
    begin
        v_response := empty_clob();
        -- Set connection and invoke REST API.
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
     
        -- Print the URL for debugging (optional).
        --print(case when upper(p_url) like '%HTTP%' then p_url else Get_WS||case when substr(p_url,1,1) = '/' then p_url else '/'||p_url end end);
        -- Make the REST API request and store the response in v_response CLOB.
        print('p_url NOVO: ' ||
            case
                when upper(p_url) like '%HTTP%' then
                    p_url
                else
                    get_ws
                    ||
                    case
                        when substr(p_url, 1, 1) = '/' then
                                p_url
                        else
                            '/' || p_url
                    end
            end
        );

        print('p_content: ' || p_content);
        print('p_type: ' || p_type);
        v_response := apex_web_service.make_rest_request(
            p_url         =>
                   case
                       when upper(p_url) like '%HTTP%' then
                           p_url
                       else
                           get_ws
                           ||
                           case
                               when substr(p_url, 1, 1) = '/' then
                                       p_url
                               else
                                   '/' || p_url
                           end
                   end,
            p_http_method => p_type,
            p_username    => 'admin',
            p_password    => 'admin',
            p_body        => p_content
        );

        print('Pós request');
        -- Initialize the result CLOB.
       -- 
       --v_response := replace(replace(replace(replace(v_response, chr(10),''),chr(13),''), chr(09), '') ,' ','');
        -- Get response.
        return v_response;
        --
    exception
        when others then
            --
            print('Error Get_Response3: ' || sqlerrm);
            --    
            print(utl_http.get_detailed_sqlerrm);
            --
            return null;
            --
    end get_response3;
    --

    /*poc não apagar e não enviar para outro cliente.*/
    function validate_line_selection (
        p_model          varchar2,
        p_type_lin       varchar2,
        p_unit_prince_po varchar2,
        p_quant_po       varchar2,
        p_quant_lin      varchar2,
        p_unit_price_lin varchar2,
        p_flag_acao      out number
    ) return varchar2 as

        nunit_price_po  number(15, 2);
        nquant_po       number(15, 2);
        nquant_lin      number(15, 2);
        nunit_price_lin number(15, 2);
        vmsg_alert      varchar2(4000);
    begin
        nunit_price_po := nls_num_char(p_unit_prince_po);
        nquant_po := nls_num_char(p_quant_po);
        nquant_lin := nls_num_char(p_quant_lin);
        nunit_price_lin := nls_num_char(p_unit_price_lin);
        if (
            nunit_price_po = nunit_price_lin
            and nquant_po >= nquant_lin
        ) then
            p_flag_acao := 2; -- Normal
        elsif (
            p_model != '55'
            and ( nunit_price_po * nquant_po ) = ( nunit_price_lin * nquant_lin )
        ) then
            --
            p_flag_acao := 5; -- Inversão comum
            --
        elsif (
            nunit_price_po = 1
            and nunit_price_po != nunit_price_lin
            and ( nunit_price_po * nquant_po ) >= ( nunit_price_lin * nquant_lin )
        ) then
            --
            p_flag_acao := 3; -- Aguarda-chuva
            --
        else
            vmsg_alert := 'Po escolhida com valor inconsistente!';
        end if;

        return vmsg_alert;
    end validate_line_selection;
    /*Fim poc*/
end rmais_process_pkg_email;
/


-- sqlcl_snapshot {"hash":"3de6df8ddda771599a09d7d8b6385e9f20e66b0f","type":"PACKAGE_BODY","name":"rmais_process_pkg_email","schemaName":"RMAIS","sxml":""}