create or replace package body rmais_process_pkg_bkp_to_worflow as
  --
    procedure ins_log (
        p_msg varchar2
    ) is
        pragma autonomous_transaction;
    begin
    --
        insert into rmais_log values ( systimestamp,
                                       substr(p_msg, 1, 3999) );

        commit;
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
            and cfop = p_cfop;
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
        p_item_code_efd         out varchar2,
        p_item_descr_efd        out varchar2,
        p_uom                   out varchar2,
        p_uom_desc              out varchar2,
        p_fiscal_classification out varchar2,
        p_catalog_code_ncm      out varchar2,
        p_item_type             out varchar2
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
            item_type
        into
            p_item_code_efd,
            p_item_descr_efd,
            p_uom,
            p_uom_desc,
            p_fiscal_classification,
            p_catalog_code_ncm,
            p_item_type
    --
        from
            rmais_get_util_item
        where
                fornecedor = p_cnpj_fornecedor
            and tomador = p_cnpj_tomador
            and item_description = p_item_desc
            and rownum = 1;
      --
    exception
        when others then
      --
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
        l_response := json_value(rmais_process_pkg_bkp_to_worflow.get_response(l_url, l_body),
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
    begin
    --
        print(p_msg
              || ' '
              || p_hea
              || ' ' || p_lin);
    --
        rmais_process_pkg_bkp_to_worflow.g_log_workflow := rmais_process_pkg_bkp_to_worflow.g_log_workflow
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
    end;
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
                efd_header_id = p_id
            and instr(message_text, 'Número do documento alterado pelo sistema') = 0;
    --
    end;
  --
    procedure insert_head (
        p_efd in out rmais_efd_headers%rowtype
    ) is
    begin
    --
        p_efd.efd_header_id := rmais_efd_headers_s.nextval;
        p_efd.creation_date := sysdate;
        p_efd.last_update_date := sysdate;
  /*p_efd.Created_By        := x_user_id;
    p_efd.Last_Updated_By   := x_user_id;
    p_efd.Last_Update_Login := x_login_id;*/
    --
        delete_efd(p_efd.access_key_number);
    --
        insert into rmais_efd_headers values p_efd;
    --
        print('EFD Header inserted');
    --
    end;
  --
    procedure insert_head (
        psource in out r$source
    ) is
    begin
    --
        insert_head(psource.rhea);
    --
    exception
        when others then
            dbms_output.put_line('insert_efd_h ' || sqlerrm);
    end;
  --
    procedure insert_line (
        p_efd in out rmais_efd_lines%rowtype
    ) is
    begin
    --
        p_efd.efd_line_id := rmais_efd_lines_s.nextval;
        p_efd.efd_header_id := nvl(p_efd.efd_header_id, rmais_efd_headers_s.currval);
        p_efd.creation_date := x_sysdate;
        p_efd.last_update_date := x_sysdate;
  /*p_efd.Created_By        := x_user_id;
    p_efd.Last_Updated_By   := x_user_id;
    p_efd.Last_Update_Login := x_login_id;*/
    --
        insert into rmais_efd_lines values p_efd;
    --
        print('EFD Line inserted');
    --
    end;
  --
    procedure insert_line (
        pnf in out r$source
    ) is
    begin
    --
        for x in pnf.rlin.first..pnf.rlin.last loop
      --
            pnf.rlin(x).rlin.efd_header_id := pnf.rhea.efd_header_id;
      --
            insert_line(pnf.rlin(x).rlin);
      --
        end loop;
    --
    exception
        when others then
            dbms_output.put_line('insert_efd_l ' || sqlerrm);
    end;
  --
    procedure insert_taxes (
        p_tax in out nocopy rmais_efd_taxes%rowtype
    ) is
    begin
    --
        p_tax.id := rmais_efd_taxes_s.nextval;
        p_tax.creation_date := sysdate;
        p_tax.update_date := sysdate;
    --
        insert into rmais_efd_taxes values p_tax;
    --
    exception
        when others then
            print('Insert Shipments ERROR: ' || sqlerrm);
    end;
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
        insert into rmais_issuer_info values p_taxpayer;
    --
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
            r_issuer.info := rmais_process_pkg_bkp_to_worflow.get_taxpayer(p_fornec, 'ISSUER');
            r_issuer.docs := rmais_process_pkg_bkp_to_worflow.get_po_list(l_body_po);
            r_issuer.cnpj := p_fornec;
            r_issuer.receiver := p_receiv;
      --
            rmais_process_pkg_bkp_to_worflow.ins_issuer(r_issuer);
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
            r_issuer.info := rmais_process_pkg_bkp_to_worflow.get_taxpayer(p_fornec, 'ISSUER');
      --
            l_transaction_id := rmais_process_pkg_bkp_to_worflow.get_po_list_v2(l_body_po);
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
            rmais_process_pkg_bkp_to_worflow.ins_issuer(r_issuer);
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
        vret  varchar2(10000);
        l_sql varchar2(10000);
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
        url    varchar2(4000) := get_ws || p_url;
        buffer clob;
    --
    begin
    --
        print('Getting reponse...' || url);
        print('p_content: ' || p_content); 
    --
        print('parameter => ' || get_parameter('AUTHORIZATION_BASIC'));
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
                print(utl_http.get_detailed_sqlerrm);
                print('status code => ' || res.status_code);
                utl_http.end_response(res);
                print(sqlerrm);
            when others then
                print(utl_http.get_detailed_sqlerrm);
                print('status code => ' || res.status_code);
                utl_http.end_response(res);
                print(sqlerrm);
        end;
    --
        return buffer;
    --
    exception
        when others then
            print(utl_http.get_detailed_sqlerrm);
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
     --
        print('Get Response 2 URL: ' || p_url);
     -- Set connection and invoke REST API.
      --print('Get_reponse2 body: '||substr(p_content,1,2000));
      --
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
      --
        v_response := apex_web_service.make_rest_request(
            p_url         => p_url,--'http://150.230.68.115/luznfe/rest.php'||CHR(63)||'class=getPDF'||chr(38)||'method=executar',
            p_http_method => p_type,--'POST',
            p_username    => 'admin',
            p_password    => 'admin',
            p_body        => p_content--'{"transaction_id":25862,"method":"NFE","url":null}' -- Your JSON.
        );
      
      -- Get response.
        begin
            loop
                dbms_lob.read(v_response, v_buffer_size, v_offset, v_buffer);
              -- Do something with buffer.
            --  DBMS_OUTPUT.PUT_LINE(v_buffer);
                return v_buffer;
                v_offset := v_offset + v_buffer_size;
            end loop;

            return '';
        exception
            when no_data_found then
                null;
                return '';
        end;

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
    function get_po_array_v2 (
        p_transaction_id number
    ) return t$po2
        pipelined
    is
        l_clob clob;
    begin
    --
        begin
            select
                xxrmais_util_pkg.base64decode(clob_info)
            into l_clob
            from
                rmais_ws_info
            where
                transaction_id = p_transaction_id;

        exception
            when others then
                l_clob := '';
        end;
    --
        for r in (
            select
                transaction_id,
                cnpj,
                receiver,
                total_po,
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
                to_clob(info_doc)  info_doc,
                to_clob(info_term) info_term,
                po_seq,
                to_clob(info_po)   info_po,
                to_clob(info_item) info_item,
                to_clob(info_ship) info_ship,
                po_line_id,
                line_type_id,
                line_num,
                item_id,
                category_id,
                item_description,
                uom_code,
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
                seq
            from
                (
                    select
                        p_transaction_id                transaction_id,
                        d.fornecedor_cnpj               cnpj,
                        d.tomador_cnpj                  receiver,
                        sum(nvl(d.price_override * quantity_ship, d.unit_price * d.quantity_line))
                        over(partition by po_header_id) total_po,
                        ''                              info_doc,
                        d.*,
                        row_number()
                        over(partition by d.po_header_id, d.po_line_id
                             order by
                                 d.po_line_id, d.shipment_num
                        )                               seq
                    from
                            json_table ( l_clob, '$'
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
       --info_doc   VARCHAR2(4000) FORMAT JSON WITH  WRAPPER  PATH '$',
                                            info_term varchar2 ( 4000 ) format json with wrapper path '$.TERM',
                                            po_seq for ordinality,
                                            nested path '$.LINES[*]'
                                                columns (
                                                    info_po varchar2 ( 4000 ) format json with wrapper path '$',
                                                    info_item varchar2 ( 4000 ) format json with wrapper path '$.ITEM',
                                                    info_ship varchar2 ( 4000 ) format json with wrapper path '$.LINE_LOCATIONS',
                                                    po_line_id number path '$.PO_LINE_ID',
                                                    line_type_id number path '$.LINE_TYPE_ID',
                                                    line_num number path '$.LINE_NUM',
                                                    item_id number path '$.ITEM_ID',
                                                    category_id number path '$.CATEGORY_ID',
                                                    item_description varchar2 ( 300 ) path '$.ITEM_DESCRIPTION',
                                                    uom_code varchar2 ( 100 ) path '$.UOM_CODE',
                                                    unit_price number path '$.UNIT_PRICE',
                                                    quantity_line number path '$.QUANTITY',
                                                    prc_bu_id_lin number path '$.PRC_BU_ID',
                                                    req_bu_id_lin number path '$.REQ_BU_ID',
                                                    taxable_flag_lin varchar2 ( 100 ) path '$.TAXABLE_FLAG',
                                                    order_type_lookup_code varchar2 ( 100 ) path '$.ORDER_TYPE_LOOKUP_CODE',
                                                    purchase_basis varchar2 ( 100 ) path '$.PURCHASE_BASIS',
                                                    matching_basis varchar2 ( 100 ) path '$.MATCHING_BASIS',
                                                    line_seq for ordinality,
                                                    nested path '$.ITEM[*]'
                                                        columns (
       --info_item varchar2(4000) FORMAT JSON  PATH '$[*]',
                                                            inventory_item_id number path '$.INVENTORY_ITEM_ID',
                                                            primary_uom_code varchar2 ( 100 ) path '$.PRIMARY_UOM_CODE',
                                                            item_type varchar2 ( 900 ) path '$.ITEM_TYPE',
                                                            inventory_item_flag varchar2 ( 100 ) path '$.INVENTORY_ITEM_FLAG',
                                                            tax_code varchar2 ( 500 ) path '$.TAX_CODE',
                                                            enabled_flag varchar2 ( 100 ) path '$.ENABLED_FLAG',
                                                            item_number varchar2 ( 300 ) path '$.ITEM_NUMBER',
                                                            description varchar2 ( 300 ) path '$.DESCRIPTION',
                                                            long_description varchar2 ( 900 ) path '$.LONG_DESCRIPTION'
                                                        ),
                                                    line_location_id number path '$.LINE_LOCATIONS.LINE_LOCATION_ID',
                                                    destination_type_code varchar2 ( 900 ) path '$.LINE_LOCATIONS.DESTINATION_TYPE_CODE'
                                                    ,
                                                    trx_business_category varchar2 ( 900 ) path '$.LINE_LOCATIONS.TRX_BUSINESS_CATEGORY'
                                                    ,
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
                                                    receipt_required_flag varchar2 ( 10 ) path '$.LINE_LOCATIONS.RECEIPT_REQUIRED_FLAG'
                                                    ,
                                                    ship_to_organization_id number path '$.LINE_LOCATIONS.SHIP_TO_ORGANIZATION_ID',
                                                    shipment_num varchar2 ( 10 ) path '$.LINE_LOCATIONS.SHIPMENT_NUM',
                                                    shipment_type varchar2 ( 500 ) path '$.LINE_LOCATIONS.SHIPMENT_TYPE',
                                                    funds_status varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.FUNDS_STATUS',
                                                    destination_type_dist varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_TYPE_CODE'
                                                    ,
                                                    prc_bu_id_dist number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PRC_BU_ID',
                                                    req_bu_id_dist number path '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_BU_ID',
                                                    encumbered_flag varchar2 ( 10 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_FLAG'
                                                    ,
                                                    unencumbered_quantity number path '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_QUANTITY'
                                                    ,
                                                    amount_billed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_BILLED',
                                                    amount_cancelled number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_CANCELLED',
                                                    quantity_financed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_FINANCED',
                                                    amount_financed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_FINANCED',
                                                    quantity_recouped number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_RECOUPED',
                                                    amount_recouped number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_RECOUPED',
                                                    retainage_withheld_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_WITHHELD_AMOUNT'
                                                    ,
                                                    retainage_released_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_RELEASED_AMOUNT'
                                                    ,
                                                    tax_attribute_update_code varchar2 ( 100 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.TAX_ATTRIBUTE_UPDATE_CODE'
                                                    ,
                                                    po_distribution_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PO_DISTRIBUTION_ID'
                                                    ,
                                                    budget_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.BUDGET_DATE',
                                                    close_budget_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CLOSE_BUDGET_DATE'
                                                    ,
                                                    dist_intended_use varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.DIST_INTENDED_USE'
                                                    ,
                                                    set_of_books_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.SET_OF_BOOKS_ID',
                                                    code_combination_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.CODE_COMBINATION_ID'
                                                    ,
                                                    quantity_ordered number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_ORDERED',
                                                    quantity_delivered number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_DELIVERED'
                                                    ,
                                                    consignment_quantity number path '$.LINE_LOCATIONS.DISTRIBUTIONS.CONSIGNMENT_QUANTITY'
                                                    ,
                                                    req_distribution_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_DISTRIBUTION_ID'
                                                    ,
                                                    deliver_to_location_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_LOCATION_ID'
                                                    ,
                                                    deliver_to_person_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_PERSON_ID'
                                                    ,
                                                    rate_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE_DATE',
                                                    rate number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE',
                                                    accrued_flag varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.ACCRUED_FLAG',
                                                    encumbered_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_AMOUNT',
                                                    unencumbered_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_AMOUNT'
                                                    ,
                                                    destination_organization_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_ORGANIZATION_ID'
                                                    ,
                                                    pjc_task_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PJC_TASK_ID',
                                                    task_number varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_NUMBER'
                                                    ,
                                                    task_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_ID',
                                                    location_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_ID',
                                                    country varchar2 ( 500 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.COUNTRY',
                                                    postal_code varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.POSTAL_CODE',
                                                    local_description varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.DESCRIPTION'
                                                    ,
                                                    effective_start_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_START_DATE'
                                                    ,
                                                    effective_end_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_END_DATE'
                                                    ,
                                                    business_group_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BUSINESS_GROUP_ID'
                                                    ,
                                                    active_status varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTIVE_STATUS'
                                                    ,
                                                    ship_to_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.SHIP_TO_SITE_FLAG'
                                                    ,
                                                    receiving_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.RECEIVING_SITE_FLAG'
                                                    ,
                                                    bill_to_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BILL_TO_SITE_FLAG'
                                                    ,
                                                    office_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.OFFICE_SITE_FLAG'
                                                    ,
                                                    inventory_organization_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.INVENTORY_ORGANIZATION_ID'
                                                    ,
                                                    action_occurrence_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTION_OCCURRENCE_ID'
                                                    ,
                                                    location_code varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_CODE'
                                                    ,
                                                    location_name varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_NAME'
                                                    ,
                                                    style varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.STYLE',
                                                    address_line_1 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_1'
                                                    ,
                                                    address_line_2 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_2'
                                                    ,
                                                    address_line_3 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_3'
                                                    ,
                                                    address_line_4 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_4'
                                                    ,
                                                    region_1 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_1',
                                                    region_2 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_2',
                                                    town_or_city varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.TOWN_OR_CITY'
                                                )
                                        )
                                )
                            )
                        d
       --AND ROWNUM>11
                )
            where
                seq = 1
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
    procedure get_taxes (
        p_efd in out nocopy r$source,
        p_idx in number
    ) is
    --
        btaxes clob;
    --
        r_tax  rmais_efd_taxes%rowtype;
    --
        procedure loadtaxes (
            pclb in clob
        ) is
        begin
      --
            print('LoadTax ' || pclb);
      --
            delete from rmais_efd_taxes
            where
                efd_line_id = p_efd.rlin(p_idx).rlin.efd_line_id;
      --
            for r in (
                select
                    j.*
                from
                        json_table ( pclb, '$'
                            columns (
                                nested path '$.RULES[*]'
                                    columns (
                                        condition_group_code varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                        tax_rate_code varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                        tax_regime_code varchar2 ( 100 ) path '$.TAX_REGIME_CODE',
                                        tax varchar2 ( 100 ) path '$.TAX',
                                        rate_type_code varchar2 ( 100 ) path '$.RATE_TYPE_CODE',
                                        percentage_rate number path '$.PERCENTAGE_RATE',
                                        active_flag varchar2 ( 100 ) path '$.ACTIVE_FLAG',
                                        alphanumeric_value2 varchar2 ( 100 ) path '$.ALPHANUMERIC_VALUE2',
                                        alphanumeric_value1 varchar2 ( 100 ) path '$.ALPHANUMERIC_VALUE1',
                                        determining_factor varchar2 ( 100 ) path '$.DETERMINING_FACTOR_CODE'
                                    )
                            )
                        )
                    j
            ) loop
        --
                r_tax.efd_line_id := p_efd.rlin(p_idx).rlin.efd_line_id;
                r_tax.condition_group_code := r.condition_group_code;
                r_tax.tax_rate_code := r.tax_rate_code;
                r_tax.tax_regime_code := r.tax_regime_code;
                r_tax.tax := r.tax;
                r_tax.rate_type_code := r.rate_type_code;
                r_tax.percentage_rate := r.percentage_rate;
                r_tax.active_flag := r.active_flag;
                r_tax.attribute2 := r.alphanumeric_value2;
                r_tax.attribute1 := r.alphanumeric_value1;
                r_tax.determining_factor := r.determining_factor;
        --
                insert_taxes(r_tax);
        --
            end loop;
      --
        end;
    --
    begin
    --
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
        null;
    exception
        when others then
            print('Get_Taxes ' || sqlerrm);
    end;
  --
      --
    procedure get_taxes_v2 (
        p_efd_line_id number
    ) is
    --
        btaxes clob;
    --
        r_tax  rmais_efd_taxes%rowtype;
    --
        l_body clob;
        l_resp clob;
    --
        procedure loadtaxes (
            pclb in clob
        ) is
        begin
      --
            print('LoadTax ' || pclb);
      --
            delete from rmais_efd_taxes
            where
                efd_line_id = p_efd_line_id;
      --
            for r in (
                select
                    *
                from
                    (
                        select
                            min(priority)
                            over(partition by imposto) pri,
                            j.*
                        from
                            (
                                select
                                    case
                                        when condition_group_code_inss is not null then
                                            'INSS'
                                        else
                                            case
                                                when condition_group_code_csrf is not null then
                                                        'CSRF'
                                                else
                                                    case
                                                        when condition_group_code_irrf is not null then
                                                                    'IRRF'
                                                        else
                                                            case
                                                                when condition_group_code_irpf is not null
                                                                     or condition_group_c_irrf_reduc is not null then
                                                                                'IRPF'
                                                                else
                                                                    case
                                                                        when condition_group_code_pcc is not null then
                                                                                            'PCC'
                                                                        else
                                                                            case
                                                                                when condition_group_code_reduc is not null then
                                                                                                        'INSS'
                                                                                else
                                                                                    case
                                                                                        when condition_group_code_icms_st is not null
                                                                                             or condition_group_c_icms_recup is not null
                                                                                             or condition_group_code_icms is not null
                                                                                             or cond_group_c_icms_applic is not null then
                                                                                                                    'ICMS'
                                                                                        else
                                                                                            case
                                                                                                when condition_group_code_fcp is not null
                                                                                                then
                                                                                                                                'FCP'
                                                                                                else
                                                                                                    case
                                                                                                        when condition_group_code_cofins
                                                                                                        is not null then
                                                                                                                                            'COFINS'
                                                                                                        else
                                                                                                            case
                                                                                                                when condition_group_code_pis
                                                                                                                is not null then
                                                                                                                                                        'PIS'
                                                                                                                else
                                                                                                                    case
                                                                                                                        when condition_group_code_ipi
                                                                                                                        is not null then
                                                                                                                                                                    'IPI'
                                                                                                                        else
                                                                                                                            case
                                                                                                                                when cond_group_csll
                                                                                                                                is not
                                                                                                                                null then
                                                                                                                                                                                'CSLL'
                                                                                                                                else
                                                                                                                                    ''
                                                                                                                            end
                                                                                                                    end
                                                                                                            end
                                                                                                    end
                                                                                            end
                                                                                    end
                                                                            end
                                                                    end
                                                            end
                                                    end
                                            end
                                    end imposto,
                                    nvl(
                                        nvl(
                                            nvl(
                                                nvl(
                                                    nvl(
                                                        nvl(
                                                            nvl(
                                                                nvl(
                                                                    nvl(
                                                                        nvl(
                                                                            nvl(
                                                                                nvl(
                                                                                    nvl(
                                                                                        nvl(
                                                                                            nvl(j.condition_group_code_inss, j.condition_group_code_pcc
                                                                                            ),
                                                                                            j.condition_group_code_irpf
                                                                                        ),
                                                                                        j.condition_group_code_irrf
                                                                                    ),
                                                                                    j.condition_group_code_csrf
                                                                                ),
                                                                                j.condition_group_code_reduc
                                                                            ) /* */,
                                                                            condition_group_code_icms_st
                                                                        ),
                                                                        condition_group_c_icms_recup
                                                                    ),
                                                                    condition_group_code_icms
                                                                ),
                                                                condition_group_c_irrf_reduc
                                                            ),
                                                            condition_group_code_fcp
                                                        ),
                                                        condition_group_code_cofins
                                                    ),
                                                    condition_group_code_pis
                                                ),
                                                condition_group_code_ipi
                                            ),
                                            cond_group_c_icms_applic
                                        ),
                                        cond_group_csll
                                    )   condition_group_code,
                                    nvl(
                                        nvl(
                                            nvl(
                                                nvl(
                                                    nvl(
                                                        nvl(
                                                            nvl(
                                                                nvl(
                                                                    nvl(
                                                                        nvl(
                                                                            nvl(
                                                                                nvl(
                                                                                    nvl(
                                                                                        nvl(
                                                                                            nvl(j.tax_rate_code_inss, j.tax_rate_code_pcc
                                                                                            ),
                                                                                            j.tax_rate_code_irpf
                                                                                        ),
                                                                                        j.tax_rate_code_irrf
                                                                                    ),
                                                                                    j.tax_rate_code_csrf
                                                                                ),
                                                                                j.tax_rate_code_reduc
                                                                            )/* */,
                                                                            j.tax_rate_code_icms_st
                                                                        ),
                                                                        j.tax_rate_code_icms_recup
                                                                    ),
                                                                    j.tax_rate_code_icms
                                                                ),
                                                                j.tax_rate_code_irrf_reduc
                                                            ),
                                                            j.tax_rate_code_fcp
                                                        ),
                                                        j.tax_rate_code_cofins
                                                    ),
                                                    j.tax_rate_code_pis
                                                ),
                                                j.tax_rate_code_ipi
                                            ),
                                            j.tax_rate_code_icms_applic
                                        ),
                                        j.tax_rate_code_csll
                                    )   tax_rate_code,
                                    nvl(
                                        nvl(
                                            nvl(
                                                nvl(
                                                    nvl(
                                                        nvl(
                                                            nvl(
                                                                nvl(
                                                                    nvl(
                                                                        nvl(
                                                                            nvl(
                                                                                nvl(
                                                                                    nvl(
                                                                                        nvl(
                                                                                            nvl(j.tax_regime_code_inss, j.tax_regime_code_pcc
                                                                                            ),
                                                                                            j.tax_regime_code_irpf
                                                                                        ),
                                                                                        j.tax_regime_code_irrf
                                                                                    ),
                                                                                    j.tax_regime_code_csrf
                                                                                ),
                                                                                j.tax_regime_code_reduc
                                                                            )/* ICMS_ST ICMS_RECUP ICMS IRRF_REDUC FCP COFINS PIS IPI ICMS_APPLIC*/
                                                                            ,
                                                                            j.tax_regime_code_icms_st
                                                                        ),
                                                                        j.tax_regime_code_icms_recup
                                                                    ),
                                                                    j.tax_regime_code_icms
                                                                ),
                                                                j.tax_regime_code_irrf_reduc
                                                            ),
                                                            j.tax_regime_code_fcp
                                                        ),
                                                        j.tax_regime_code_cofins
                                                    ),
                                                    j.tax_regime_code_pis
                                                ),
                                                j.tax_regime_code_ipi
                                            ),
                                            j.tax_regime_code_icms_applic
                                        ),
                                        j.tax_regime_code_csll
                                    )   tax_regime_code,
                                    nvl(
                                        nvl(
                                            nvl(
                                                nvl(
                                                    nvl(
                                                        nvl(
                                                            nvl(
                                                                nvl(
                                                                    nvl(
                                                                        nvl(
                                                                            nvl(
                                                                                nvl(
                                                                                    nvl(
                                                                                        nvl(
                                                                                            nvl(j.rate_type_code_inss, j.rate_type_code_pcc
                                                                                            ),
                                                                                            j.rate_type_code_irpf
                                                                                        ),
                                                                                        j.rate_type_code_irrf
                                                                                    ),
                                                                                    j.rate_type_code_csrf
                                                                                ),
                                                                                j.rate_type_code_reduc
                                                                            ) /* */,
                                                                            j.rate_type_code_icms_st
                                                                        ),
                                                                        j.rate_type_code_icms_recup
                                                                    ),
                                                                    j.rate_type_code_icms
                                                                ),
                                                                j.rate_type_code_irrf_reduc
                                                            ),
                                                            j.rate_type_code_fcp
                                                        ),
                                                        j.rate_type_code_cofins
                                                    ),
                                                    j.rate_type_code_pis
                                                ),
                                                j.rate_type_code_ipi
                                            ),
                                            j.rate_type_code_icms_applic
                                        ),
                                        j.rate_type_code_csll
                                    )   rate_type_code,
                                    nvl(
                                        nvl(
                                            nvl(
                                                nvl(
                                                    nvl(
                                                        nvl(
                                                            nvl(
                                                                nvl(
                                                                    nvl(
                                                                        nvl(
                                                                            nvl(
                                                                                nvl(
                                                                                    nvl(
                                                                                        nvl(
                                                                                            nvl(j.tax_inss, j.rate_type_code_pcc),
                                                                                            j.tax_irpf
                                                                                        ),
                                                                                        j.tax_irrf
                                                                                    ),
                                                                                    j.tax_csrf
                                                                                ),
                                                                                j.tax_reduc
                                                                            )/* */,
                                                                            j.tax_icms_st
                                                                        ),
                                                                        j.tax_icms_recup
                                                                    ),
                                                                    j.tax_icms
                                                                ),
                                                                j.tax_irrf_reduc
                                                            ),
                                                            j.tax_fcp
                                                        ),
                                                        j.tax_cofins
                                                    ),
                                                    j.tax_pis
                                                ),
                                                j.tax_ipi
                                            ),
                                            j.tax_icms_applic
                                        ),
                                        j.tax_csll
                                    )   tax,
                                    nvl(
                                        nvl(
                                            nvl(
                                                nvl(
                                                    nvl(
                                                        nvl(
                                                            nvl(
                                                                nvl(
                                                                    nvl(
                                                                        nvl(
                                                                            nvl(
                                                                                nvl(
                                                                                    nvl(
                                                                                        nvl(
                                                                                            nvl(j.percentage_rate_inss, j.percentage_rate_pcc
                                                                                            ),
                                                                                            j.percentage_rate_irpf
                                                                                        ),
                                                                                        j.percentage_rate_irrf
                                                                                    ),
                                                                                    j.percentage_rate_csrf
                                                                                ),
                                                                                j.percentage_rate_reduc
                                                                            )/* */,
                                                                            j.percentage_rate_icms_st
                                                                        ),
                                                                        j.percentage_rate_icms_recup
                                                                    ),
                                                                    j.percentage_rate_icms
                                                                ),
                                                                j.percentage_rate_irrf_reduc
                                                            ),
                                                            j.percentage_rate_fcp
                                                        ),
                                                        j.percentage_rate_cofins
                                                    ),
                                                    j.percentage_rate_pis
                                                ),
                                                j.percentage_rate_ipi
                                            ),
                                            j.percentage_rate_icms_applic
                                        ),
                                        j.percentage_rate_csll
                                    )   percentage_rate,
                                    nvl(
                                        nvl(
                                            nvl(
                                                nvl(
                                                    nvl(
                                                        nvl(
                                                            nvl(
                                                                nvl(
                                                                    nvl(
                                                                        nvl(
                                                                            nvl(
                                                                                nvl(
                                                                                    nvl(
                                                                                        nvl(
                                                                                            nvl(j.active_flag_inss, j.active_flag_pcc
                                                                                            ),
                                                                                            j.active_flag_irpf
                                                                                        ),
                                                                                        j.active_flag_irrf
                                                                                    ),
                                                                                    j.active_flag_csrf
                                                                                ),
                                                                                j.active_flag_reduc
                                                                            )/* */,
                                                                            j.active_flag_icms_st
                                                                        ),
                                                                        j.active_flag_icms_recup
                                                                    ),
                                                                    j.active_flag_icms
                                                                ),
                                                                j.active_flag_irrf_reduc
                                                            ),
                                                            j.active_flag_fcp
                                                        ),
                                                        j.active_flag_cofins
                                                    ),
                                                    j.active_flag_pis
                                                ),
                                                j.active_flag_ipi
                                            ),
                                            j.active_flag_icms_applic
                                        ),
                                        j.active_flag_csll
                                    )/* */   active_flag,
                                    nvl(
                                        nvl(
                                            nvl(
                                                nvl(
                                                    nvl(
                                                        nvl(
                                                            nvl(
                                                                nvl(
                                                                    nvl(
                                                                        nvl(
                                                                            nvl(
                                                                                nvl(
                                                                                    nvl(
                                                                                        nvl(
                                                                                            nvl(
                                                                                                nvl(
                                                                                                    nvl(j.base_reduce_inss, j.base_reduce_pcc
                                                                                                    ),
                                                                                                    j.base_reduce_irpf
                                                                                                ),
                                                                                                j.base_reduce_irrf
                                                                                            ),
                                                                                            j.base_reduce_csrf
                                                                                        ),
                                                                                        j.base_reduce_csrf
                                                                                    ),
                                                                                    j.base_reduce_reduc
                                                                                ) /* */,
                                                                                j.base_reduce_icms_st
                                                                            ),
                                                                            j.base_reduce_icms_recup
                                                                        ),
                                                                        j.base_reduce_icms
                                                                    ),
                                                                    j.base_reduce_irrf_reduc
                                                                ),
                                                                j.base_reduce_fcp
                                                            ),
                                                            j.base_reduce_cofins
                                                        ),
                                                        j.base_reduce_pis
                                                    ),
                                                    j.base_reduce_ipi
                                                ),
                                                j.base_reduce_ipi
                                            ),
                                            j.base_reduce_icms_applic
                                        ),
                                        j.base_reduce_csll
                                    )   base_reduce,
                                    nvl(
                                        nvl(
                                            nvl(
                                                nvl(
                                                    nvl(
                                                        nvl(
                                                            nvl(
                                                                nvl(
                                                                    nvl(
                                                                        nvl(
                                                                            nvl(
                                                                                nvl(
                                                                                    nvl(
                                                                                        nvl(
                                                                                            nvl(
                                                                                                nvl(j.priority_inss, j.priority_pcc),
                                                                                                j.priority_irpf
                                                                                            ),
                                                                                            j.priority_irrf
                                                                                        ),
                                                                                        j.priority_csrf
                                                                                    ),
                                                                                    j.priority_reduc
                                                                                ),
                                                                                j.priority_icms_st
                                                                            ),
                                                                            j.priority_icms_recup
                                                                        ),
                                                                        j.priority_icms
                                                                    ),
                                                                    j.priority_irrf_reduc
                                                                ),
                                                                j.priority_fcp
                                                            ),
                                                            j.priority_cofins
                                                        ),
                                                        j.priority_pis
                                                    ),
                                                    j.priority_ipi
                                                ),
                                                j.priority_icms_applic
                                            ),
                                            j.priority_csll
                                        ),
                                        1
                                    )   priority     --  ,j.*
                                from
                                        json_table ( pclb, '$'
                                            columns (
                                                nested path '$.WTAX_INSS[*]'
                                                    columns (
                                                        condition_group_code_inss varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_inss varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_inss varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_inss varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_inss varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_inss number path '$.PERCENTAGE_RATE',
                                                        active_flag_inss varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_inss number path '$.BASE_REDUCE',
                                                        priority_inss number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_PCC[*]'
                                                    columns (
                                                        condition_group_code_pcc varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_pcc varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_pcc varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_pcc varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_pcc varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_pcc number path '$.PERCENTAGE_RATE',
                                                        active_flag_pcc varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_pcc number path '$.BASE_REDUCE',
                                                        priority_pcc number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_ISS[*]'
                                                    columns (
                                                        condition_group_code_irpf varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_irpf varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_irpf varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_irpf varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_irpf varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_irpf number path '$.PERCENTAGE_RATE',
                                                        active_flag_irpf varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_irpf number path '$.BASE_REDUCE',
                                                        priority_irpf number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_IRRF[*]'
                                                    columns (
                                                        condition_group_code_irrf varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_irrf varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_irrf varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_irrf varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_irrf varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_irrf number path '$.PERCENTAGE_RATE',
                                                        active_flag_irrf varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_irrf number path '$.BASE_REDUCE',
                                                        priority_irrf number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_CSRF[*]'
                                                    columns (
                                                        condition_group_code_csrf varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_csrf varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_csrf varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_csrf varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_csrf varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_csrf number path '$.PERCENTAGE_RATE',--
                                                        active_flag_csrf varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_csrf number path '$.BASE_REDUCE',
                                                        priority_csrf number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_INSS_REDUC[*]'
                                                    columns (
                                                        condition_group_code_reduc varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_reduc varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_reduc varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_reduc varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_reduc varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_reduc number path '$.PERCENTAGE_RATE',--
                                                        active_flag_reduc varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_reduc number path '$.BASE_REDUCE',
                                                        priority_reduc number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_ICMS_ST[*]'
                                                    columns (
                                                        condition_group_code_icms_st varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_icms_st varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_icms_st varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_icms_st varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_icms_st varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_icms_st number path '$.PERCENTAGE_RATE',--
                                                        active_flag_icms_st varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_icms_st number path '$.BASE_REDUCE',
                                                        priority_icms_st number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_ICMS_RECUP[*]'
                                                    columns (
                                                        condition_group_c_icms_recup varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_icms_recup varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_icms_recup varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_icms_recup varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_icms_recup varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_icms_recup number path '$.PERCENTAGE_RATE',--
                                                        active_flag_icms_recup varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_icms_recup number path '$.BASE_REDUCE',
                                                        priority_icms_recup number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_ICMS[*]'
                                                    columns (
                                                        condition_group_code_icms varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_icms varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_icms varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_icms varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_icms varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_icms number path '$.PERCENTAGE_RATE',--
                                                        active_flag_icms varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_icms number path '$.BASE_REDUCE',
                                                        priority_icms number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_IRRF_REDUC[*]'
                                                    columns (
                                                        condition_group_c_irrf_reduc varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_irrf_reduc varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_irrf_reduc varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_irrf_reduc varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_irrf_reduc varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_irrf_reduc number path '$.PERCENTAGE_RATE',--
                                                        active_flag_irrf_reduc varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_irrf_reduc number path '$.BASE_REDUCE',
                                                        priority_irrf_reduc number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_FCP[*]'
                                                    columns (
                                                        condition_group_code_fcp varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_fcp varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_fcp varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_fcp varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_fcp varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_fcp number path '$.PERCENTAGE_RATE',--
                                                        active_flag_fcp varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_fcp number path '$.BASE_REDUCE',
                                                        priority_fcp number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_COFINS[*]'
                                                    columns (
                                                        condition_group_code_cofins varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_cofins varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_cofins varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_cofins varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_cofins varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_cofins number path '$.PERCENTAGE_RATE',--
                                                        active_flag_cofins varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_cofins number path '$.BASE_REDUCE',
                                                        priority_cofins number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_PIS[*]'
                                                    columns (
                                                        condition_group_code_pis varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_pis varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_pis varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_pis varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_pis varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_pis number path '$.PERCENTAGE_RATE',--
                                                        active_flag_pis varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_pis number path '$.BASE_REDUCE',
                                                        priority_pis number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_IPI[*]'
                                                    columns (
                                                        condition_group_code_ipi varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_ipi varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_ipi varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_ipi varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_ipi varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_ipi number path '$.PERCENTAGE_RATE',--
                                                        active_flag_ipi varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_ipi number path '$.BASE_REDUCE',
                                                        priority_ipi number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_ICMS_APPLIC[*]'
                                                    columns (
                                                        cond_group_c_icms_applic varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_icms_applic varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_icms_applic varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_icms_applic varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_icms_applic varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_icms_applic number path '$.PERCENTAGE_RATE',--
                                                        active_flag_icms_applic varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_icms_applic number path '$.BASE_REDUCE',
                                                        priority_icms_applic number path '$.PRIORITY'
                                                    ),
                                                nested path '$.WTAX_CSLL[*]'
                                                    columns (
                                                        cond_group_csll varchar2 ( 100 ) path '$.CONDITION_GROUP_CODE',
                                                        tax_rate_code_csll varchar2 ( 100 ) path '$.TAX_RATE_CODE',
                                                        tax_regime_code_csll varchar2 ( 110 ) path '$.TAX_REGIME_CODE',
                                                        tax_csll varchar2 ( 110 ) path '$.TAX',
                                                        rate_type_code_csll varchar2 ( 110 ) path '$.RATE_TYPE_CODE',
                                                        percentage_rate_csll number path '$.PERCENTAGE_RATE',--
                                                        active_flag_csll varchar2 ( 5 ) path '$.ACTIVE_FLAG',
                                                        base_reduce_csll number path '$.BASE_REDUCE',
                                                        priority_csll number path '$.PRIORITY'
                                                    )
                                            )
                                        )
                                    j
                            ) j
                    )
                where
                    pri = priority
            ) loop
        --
                r_tax.efd_line_id := p_efd_line_id;
                r_tax.condition_group_code := r.condition_group_code;
                r_tax.tax_rate_code := r.tax_rate_code;
                r_tax.tax_regime_code := r.tax_regime_code;
                r_tax.tax := r.tax;
                r_tax.rate_type_code := r.rate_type_code;
                r_tax.percentage_rate := r.percentage_rate;
                r_tax.active_flag := r.active_flag;
                r_tax.base_rate := r.base_reduce;
        --r_tax.attribute2           := r.alphanumeric_value2;
        --r_tax.attribute1           := r.alphanumeric_value1;
        --r_tax.determining_factor   := r.determining_factor;
        --
                insert_taxes(r_tax);
        --
            end loop;
      --
        end;
    --
    begin
    --
        declare
            l_withhold       rmais_efd_headers.withholding%type;
            l_defined_fiscal rmais_efd_lines.user_defined%type;
            l_intended_use   rmais_efd_lines.intended_use%type;
        begin
      --
            execute immediate q'[alter session set NLS_NUMERIC_CHARACTERS='.,']';
      --execute immediate 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '''||'.,'||'''';
      --
            select
                h.withholding,
                l.user_defined,
                l.intended_use
            into
                l_withhold,
                l_defined_fiscal,
                l_intended_use
            from
                rmais_efd_headers h,
                rmais_efd_lines   l
            where
                    h.efd_header_id = l.efd_header_id
                and l.efd_line_id = p_efd_line_id;
      --
     --l_produc_tp := 'SERVICES';
	  --
            begin
                select
                    classification_code
                into l_defined_fiscal
                from
                    rmais_ws_defined_clasification
                where
                    classification_name = l_defined_fiscal;

            exception
                when others then
                    null;
            end;

            l_body :=
                json_object(
                    'P_WITHHOLD_TAX_CLASSIF_CODE' value
                        case
                            when l_withhold in ( 'ISS_RET_2.00', 'ISS200' ) then
                                'ISS_200'
                            when l_withhold in ( 'ISS_RET_2.01', 'ISS201' ) then
                                'ISS_201'
                            else
                                l_withhold
                        end,
                    'P_USER_DEF_FISCAL_CLASS' value l_defined_fiscal,
                    'P_INTENDED_USE' value l_intended_use
                );
      --l_resp
      --l_body := REPLACE (ASCIISTR (l_body), '\', '\u'); 
      --
            print(l_body);
      --
            l_resp := get_response2(get_ws || '/api/consultas/v1/taxes', l_body, 'POST');
      --
            print('Resposta Impostos: ' || l_resp);
      --
        end;
    --
        loadtaxes(l_resp);
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
        null;
      --
      --Victor 21/03/2023
      --execute immediate q'[alter session set NLS_NUMERIC_CHARACTERS=',.']';
      --
    exception
        when others then
            print('Get_Taxes_v2 ' || sqlerrm);
    end get_taxes_v2;
  --
    procedure find_imp_det (
        p_efd_header in out rmais_efd_headers%rowtype,
        p_efd_lines  in out rmais_efd_lines%rowtype
    ) as

        l_sql                   varchar2(4000) := '';
        l_define_classification varchar2(1000);
        l_define_descr          varchar2(400);
    begin
    --    
        for nf in (
            select
                iss_amount,
                iss_tax,
                iss_name,
                case
                    when csrf_name is not null then
                        null
                    else
                        cofins_amount
                end cofins_amount,
                case
                    when csrf_name is not null then
                        null
                    else
                        cofins_tax
                end cofins_tax,
                case
                    when csrf_name is not null then
                        null
                    else
                        cofins_name
                end cofins_name,
                case
                    when csrf_name is not null then
                        null
                    else
                        pis_amount
                end pis_amount,
                case
                    when csrf_name is not null then
                        null
                    else
                        pis_tax
                end pis_tax,
                case
                    when csrf_name is not null then
                        null
                    else
                        pis_name
                end pis_name,
                case
                    when csrf_name is not null then
                        null
                    else
                        csll_amount
                end csll_amount,
                case
                    when csrf_name is not null then
                        null
                    else
                        csll_tax
                end csll_tax,
                case
                    when csrf_name is not null then
                        null
                    else
                        csll_name
                end csll_name,
                ir_amount,
                ir_tax,
                ir_name,
                inss_amount,
                inss_tax,
                inss_name,
                inss_base,
                csrf_amount,
                csrf_tax,
                csrf_name,
                total_amount
            from
                (
                    select
                        iss_amount,
                        round((iss_amount * 100 / total_amount), 2)    iss_tax,
                 --case when nvl(iss_amount,0) > 0 then 'ISS '|| round ((iss_amount*100/total_amount),2) else null end iss_name,
                        case
                            when nvl(iss_amount, 0) > 0
                                 and iss_ret_flag = 'Y' then
                                'ISS'
                                || rpad(
                                    replace(
                                        translate(
                                            round((iss_amount * 100 / total_amount), 2),
                                            '.,',
                                            '  '
                                        ),
                                        ' ',
                                        ''
                                    ),
                                    3,
                                    0
                                )
                            else
                                null
                        end                                            iss_name,
                        cofins_amount,
                        round((cofins_amount * 100 / total_amount), 2) cofins_tax,
                        case
                            when nvl(cofins_amount, 0) > 0 then
                                'COFINS '
                                || round((cofins_amount * 100 / total_amount), 2)
                            else
                                null
                        end                                            cofins_name,
                        pis_amount,
                        round((pis_amount * 100 / total_amount), 2)    pis_tax,
                        case
                            when nvl(pis_amount, 0) > 0 then
                                'PIS '
                                || round((pis_amount * 100 / total_amount), 2)
                            else
                                null
                        end                                            pis_name,
                        csll_amount,
                        round((csll_amount * 100 / total_amount), 2)   csll_tax,
                        case
                            when nvl(csll_amount, 0) > 0 then
                                'CSLL '
                                || round((csll_amount * 100 / total_amount), 2)
                            else
                                null
                        end                                            csll_name,
                        ir_amount,
                        round((ir_amount * 100 / total_amount), 2)     ir_tax,
                        case
                            when nvl(ir_amount, 0) > 0 then
                                'IR '
                                || round((ir_amount * 100 / total_amount), 2)
                            else
                                null
                        end                                            ir_name,
                        inss_amount,
                        round((inss_amount * 100 / total_amount), 2)   inss_tax,
                        case
                            when nvl(inss_amount, 0) > 0 then
                                'INSS '
                                || round((inss_amount * 100 / nvl(inss_base, total_amount)),
                                         2)
                            else
                                null
                        end                                            inss_name,
                        inss_base,
                        csrf_amount,
                        round((csrf_amount * 100 / total_amount), 2)   csrf_tax,
                        case
                            when nvl(csrf_amount, 0) > 0 then
                                'CSRF '
                                || round((csrf_amount * 100 / total_amount), 2)
                            else
                                null
                        end                                            csrf_name,
                        total_amount
                    from
                        (
                            select
                                iss_amount,
                                cofins_amount,
                                pis_amount,
                                csll_amount,
                                ir_amount,
                                inss_amount,
                                total_amount,
                                case
                                    when nvl(cofins_amount, 0) > 0
                                         and nvl(pis_amount, 0) > 0
                                         and nvl(csll_amount, 0) > 0 then
                                        cofins_amount + pis_amount + csll_amount
                                    else
                                        null
                                end                    csrf_amount,
                                case
                                    when nvl(inss_base, 0) > 0 then
                                        inss_base
                                    else
                                        null
                                end                    inss_base,
                                nvl(iss_ret_flag, 'N') iss_ret_flag
                            from
                                rmais_efd_headers
                            where
                                efd_header_id = p_efd_header.efd_header_id--510306--510311--510307--510306
                        )
                )
        ) loop
      --
            print('*** Buscando informações de imposto da nota ***');
      --
            if
                nf.iss_name is null
                and nf.cofins_name is null
                and nf.pis_name is null
                and nf.csll_name is null
                and nf.ir_name is null
                and nf.inss_name is null
                and nf.csrf_name is null
            then
        --
                print('Documento sem imposto destacado');
        --
                p_efd_header.withholding := null;
                p_efd_lines.user_defined := null;
        --
            else
        --
                print('');
                print('Documento identificado com imposto destacado');
        --
                print('--------------------------------------------');
                if nf.iss_name is not null then
          --
                    print(
                        case
                            when nf.iss_name = 'ISS200' then
                                'ISS_RET_2.00'
                            when nf.iss_name = 'ISS201' then
                                'ISS_RET_2.01'
                            else
                                nf.iss_name
                        end
                    );
          --
                    p_efd_header.withholding :=
                        case
                            when nf.iss_name = 'ISS200' then
                                'ISS_RET_2.00'
                            when nf.iss_name = 'ISS201' then
                                'ISS_RET_2.01'
                            else
                                nf.iss_name
                        end;
          --
                else
          --
                    p_efd_header.withholding := null;
          --
                end if;
        --
                if nf.cofins_name is not null
                   or nf.pis_name is not null
                or nf.csll_name is not null
                or nf.ir_name is not null
                or nf.inss_name is not null
                or nf.csrf_name is not null then
          --    
                    l_sql := 'select CLASSIFICATION_NAME'
                             || chr(13)
                             || 'from RMAIS_WS_DEFINED_CLASIFICATION'
                             || chr(13)
                             || 'where CLASSIFICATION_NAME not like '''
                             || '%ISS%'
                             || ''' '
                             || chr(13)
                             || 'and  CLASSIFICATION_NAME not like '''
                             || '%PATRONAL%'
                             || ''' '
                             || chr(13)
                             || 'and  upper(CLASSIFICATION_NAME) not like '''
                             || '%REDUZIDA%'
                             || ''' '
                             || chr(13);

                    if nf.csrf_name is not null then
            --
                        l_define_descr := l_define_descr
                                          || nf.csrf_name
                                          || ' / ';
            --
                        print(nf.csrf_name);
            --
                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME  like '''
                                 || '%'
                                 || nf.csrf_name
                                 || '%'
                                 || ''' '
                                 || chr(13);
            --
                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME not like '''
                                 || '%COFINS%'
                                 || ''' '
                                 || chr(13);

                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME not like '''
                                 || '%PIS%'
                                 || ''' '
                                 || chr(13);

                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME not like '''
                                 || '%CSLL%'
                                 || ''' '
                                 || chr(13);

                    else
            --  
                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME not like '''
                                 || '%CSRF%'
                                 || ''' '
                                 || chr(13);
                --
                        if nf.cofins_name is not null then
                --
                            print(nf.cofins_name);
                --
                            l_sql := l_sql
                                     || ' '
                                     || 'and CLASSIFICATION_NAME  like '''
                                     || '%'
                                     || nf.cofins_name
                                     || '%'
                                     || ''' '
                                     || chr(13);
                --
                            l_define_descr := l_define_descr
                                              || nf.cofins_name
                                              || ' / ';
                --
                        else
                --
                            l_sql := l_sql
                                     || ' '
                                     || 'and CLASSIFICATION_NAME not like '''
                                     || '%COFINS%'
                                     || ''' '
                                     || chr(13);
                --
                        end if;
                --
                        if nf.pis_name is not null then
                --
                            print(nf.pis_name);
                --
                            l_sql := l_sql
                                     || ' '
                                     || 'and CLASSIFICATION_NAME  like '''
                                     || '%'
                                     || nf.pis_name
                                     || '%'
                                     || ''' '
                                     || chr(13);
                --
                            l_define_descr := l_define_descr
                                              || nf.pis_name
                                              || ' / ';
                --
                        else
                --
                            l_sql := l_sql
                                     || ' '
                                     || 'and CLASSIFICATION_NAME not like '''
                                     || '%PIS%'
                                     || ''' '
                                     || chr(13);
                --
                        end if;
                --
                        if nf.csll_name is not null then
                --
                            print(nf.csll_name);
                --
                            l_define_descr := l_define_descr
                                              || nf.csll_name
                                              || ' / ';
                --
                            l_sql := l_sql
                                     || ' '
                                     || 'and CLASSIFICATION_NAME  like '''
                                     || '%'
                                     || nf.csll_name
                                     || '%'
                                     || ''' '
                                     || chr(13);
                --
                        else
                --
                            l_sql := l_sql
                                     || ' '
                                     || 'and CLASSIFICATION_NAME not like '''
                                     || '%CSLL%'
                                     || ''' '
                                     || chr(13);
                --
                        end if;
                --
                    end if;

                    if nf.ir_name is not null then
            --
                        print(nf.ir_name); 
            --
                        l_define_descr := l_define_descr
                                          || nf.ir_name
                                          || ' / ';
                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME  like '''
                                 || '%'
                                 || nf.ir_name
                                 || '%'
                                 || ''' '
                                 || chr(13);
            --
                        if ( length(nf.ir_name) ) = 4 then
            --
                            l_sql := l_sql
                                     || ' '
                                     || 'and CLASSIFICATION_NAME  not like '''
                                     || '%'
                                     || nf.ir_name
                                     || '.%'
                                     || ''' '
                                     || chr(13);
            --
                        end if;
           --
                    else
                --
                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME not like '''
                                 || '%IR %'
                                 || ''' '
                                 || chr(13);
                --
                    end if;
            --
                    if nf.inss_name is not null then
            --
                        print(nf.inss_name);
            --
                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME  like '''
                                 || '%'
                                 || nf.inss_name
                                 || '%'
                                 || ''' '
                                 || chr(13);

                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME  not like '''
                                 || '%'
                                 || 'base reduzida'
                                 || '%'
                                 || ''' '
                                 || chr(13);

                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME  not like '''
                                 || '%'
                                 || 'PATRONAL'
                                 || '%'
                                 || ''' '
                                 || chr(13);

                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME  not like '''
                                 || '%'
                                 || 'Seguros'
                                 || '%'
                                 || ''' '
                                 || chr(13);
            --
                        l_define_descr := l_define_descr
                                          || nf.inss_name
                                          || ' / ';
            --
                    else
                --
                        l_sql := l_sql
                                 || ' '
                                 || 'and CLASSIFICATION_NAME not like '''
                                 || '%INSS%'
                                 || ''' '
                                 || chr(13);
                --
                    end if;

                    print('--------------------------------------------');
                    print(l_sql);
            --
                    begin
                        execute immediate l_sql
                        into l_define_classification;
            --
                        p_efd_lines.user_defined := l_define_classification;
            --
                    exception
                        when others then
            --
                            print('Não foi possível localizar define_classification. ERROR: ' || sqlerrm);
            --
            --
                            p_efd_header.document_status := 'I';
            --
                            log_efd('Não foi possível identificar User Defined Fiscal Classification com parâmetros ('
                                    || l_define_descr
                                    || '), faça a escolha manual.', '', p_efd_header.efd_header_id, 'Erro');
            --
            --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Não foi possível identificar User Defined Fiscal Classification com parâmetros ('||l_define_descr||'), faça a escolha manual.'||'<br>';
            --
                            print('End Exception');
                    end;
            --
                    print('define_classification: ' || l_define_classification);
            --  
                else
          --
                    print('Informações de Defined Fiscal Classification não informadas na nota - OK');
          --
                end if;
        --
            end if;  
      --
            if
                nf.inss_base is not null
                and nf.inss_base < nf.total_amount
            then
        --
        --Identificado base de calculo reduzida de INSS
        --
                print('Identificado base de cálculo reduzida de INSS');
        --
                declare
                    l_aux  number;
                    l_aux2 number;
                begin
          --
                    print('Base reduzida de INSS Total: '
                          || nf.total_amount
                          || ' BASE INSS: ' || nf.inss_base);
          --
                    l_aux := round((nf.inss_base * 100) / nf.total_amount);
                    print('Base reduzida de INSS de :'
                          || l_aux || '%');
          --
                    p_efd_lines.intended_use := 'INSS_BASE_CALCULO_' || l_aux;
          --
                    log_efd('Identificado redução de base de INSS, utilizando : ' || p_efd_lines.intended_use, p_efd_lines.efd_line_id
                    , p_efd_header.efd_header_id);
          -- 
          --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Identificado redução de base de INSS, utilizando : '||p_efd_lines.Intended_Use||'<br>';
          -- 
                    select distinct
                        1
                    into l_aux2
                    from
                        rmais_utilizations_ws
                    where
                        classification_code = p_efd_lines.intended_use;
          --
                exception
                    when others then
          --
                        print('ERROR: ' || sqlerrm);
          --
                        p_efd_header.document_status := 'I';
          --
                        log_efd('Não foi possível identificar utilização de INSS com base reduzida, faça a escolha manual.', '', p_efd_header.efd_header_id
                        , 'Erro');
          --
          --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Não foi possível identificar utilização de INSS com base reduzida, faça a escolha manual.'||'<br>';
          --  
                end;

            end if;
      --
        end loop;          
    --
    end find_imp_det;
  --
    procedure get_po_line (
        p_efd            in out nocopy r$source,
        p_idx            in number,
        p_transaction_id number default null
    ) is
    --
        rlin         rmais_efd_lines%rowtype := p_efd.rlin(p_idx).rlin;
        rlin_old     rmais_efd_lines%rowtype := p_efd.rlin(p_idx).rlin;
        rshp         rmais_efd_shipments%rowtype;
        rhea         rmais_efd_headers%rowtype := p_efd.rhea;
        l_unit_price rmais_efd_lines.unit_price%type;
    --
        l_count      number := 0;
    --
    --r$Po t$PO; Comentado por Robson em 24/01/2023
        r$po         t$po_line;
    --
        cursor c$po (
            p_transaction number
        ) is
     /* SELECT i.*
        FROM rmais_issuer_info_v i
       WHERE i.receiver = p_Efd.rHea.Receiver_document_number
         AND i.cnpj     = p_Efd.rHea.Issuer_document_number;*/--Victor
        select /*d.fornecedor_cnpj cnpj
          , d.tomador_cnpj receiver
          , SUM(NVL(d.price_override * quantity_ship,d.unit_price * d.quantity_line)) OVER (PARTITION BY po_header_id) total_po
          , d.*
          --,  info_doc
          , nvl(destination_type_code,destination_type_dist) destination_type
          , ROW_NUMBER() OVER (PARTITION BY d.po_header_id, d.po_line_id ORDER BY d.po_line_id, d.shipment_num) seq*/
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
            uom_code_po                                       uom_code,
            nvl(unit_of_measure_po, uom_code2)                uom_desc,
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
            catalog_code_ncm,
            nvl(destination_type_code, destination_type_dist) destination_type,
            row_number()
            over(partition by d.po_header_id, d.po_line_id
                 order by
                     d.po_line_id, d.shipment_num
            )                                                 seq
        from
            rmais_ws_info p,
            json_table ( xxrmais_util_pkg.base64decode(clob_info), '$'
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
                                info_doc varchar2 ( 1 ) path '$.ERR',
                                info_term varchar2 ( 4000 ) format json with wrapper path '$.TERM',
            --info_doc VARCHAR2(4000) FORMAT JSON WITH WRAPPER PATH '$',
            --info_doc VARCHAR2(100) PATH '$.VENDOR_SITE_CODE',
                                po_seq for ordinality,
                                nested path '$.LINES[*]'
                                    columns (
                                        info_po clob format json with wrapper path '$',
                                        info_item varchar2 ( 4000 ) format json with wrapper path '$.ITEM',
                                        info_ship varchar2 ( 4000 ) format json with wrapper path '$.LINE_LOCATIONS',
                                        po_line_id number path '$.PO_LINE_ID',
                                        line_type_id number path '$.LINE_TYPE_ID',
                                        line_num number path '$.LINE_NUM',
                                        item_id number path '$.ITEM_ID',
                                        category_id number path '$.CATEGORY_ID',
                                        item_description varchar2 ( 300 ) path '$.ITEM_DESCRIPTION',
                                        uom_code varchar2 ( 100 ) path '$.UOM_CODE',
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
                                                catalog_code_ncm varchar2 ( 100 ) path '$.CATALOG_CODE',
                                                uom_code2 varchar ( 100 ) path '$.UNIT_OF_MEASURE'
                                            ),
            --
                                        uom_code_po varchar2 ( 50 ) path '$.OUM.UOM_CODE',
                                        unit_of_measure_po varchar2 ( 300 ) path '$.OUM.UNIT_OF_MEASURE',
            --
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
                                        destination_type_dist varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_TYPE_CODE'
                                        ,
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
                                        retainage_withheld_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_WITHHELD_AMOUNT'
                                        ,
                                        retainage_released_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_RELEASED_AMOUNT'
                                        ,
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
                                        destination_organization_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_ORGANIZATION_ID'
                                        ,
                                        pjc_task_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PJC_TASK_ID',
                                        task_number varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_NUMBER',
                                        task_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_ID',
                                        location_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_ID',
                                        country varchar2 ( 500 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.COUNTRY',
                                        postal_code varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.POSTAL_CODE',
                                        local_description varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.DESCRIPTION',
                                        effective_start_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_START_DATE'
                                        ,
                                        effective_end_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_END_DATE'
                                        ,
                                        business_group_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BUSINESS_GROUP_ID',
                                        active_status varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTIVE_STATUS',
                                        ship_to_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.SHIP_TO_SITE_FLAG'
                                        ,
                                        receiving_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.RECEIVING_SITE_FLAG'
                                        ,
                                        bill_to_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BILL_TO_SITE_FLAG'
                                        ,
                                        office_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.OFFICE_SITE_FLAG',
                                        inventory_organization_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.INVENTORY_ORGANIZATION_ID'
                                        ,
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
                    )
                )
            d
        where
            p.transaction_id = p_transaction; --query identica a busca APEX (view com problema de performance)
    --
    begin
    --
        print('Begin Get PO LIne - TransactionId: ' || p_transaction_id);
    /*
    Comentado por Robson em 24/01/2023 ----------------------- Depois dos teste apagar declaração do cursor acima
    OPEN  c$Po (p_transaction_id);
    FETCH c$Po BULK COLLECT
    INTO  r$Po;
    CLOSE c$Po;
    */
    -- Adicionado por Robson em 24/01/2023
        r$po := rmais_process_pkg_bkp_to_worflow.cursor_po_line(p_transaction_id => p_transaction_id);
    --
        print('Fetch Collect OK r$Po.count:' || r$po.count);
    --
        if p_efd.rhea.model = '55' then
     --
            l_unit_price := ( nls_num_char(nvl(rlin.unit_price_original, rlin.unit_price)) * rlin.line_quantity ) + ( ( nvl(rlin.ipi_amount
            , 0) + nvl(rlin.icms_st_amount, 0) ) / rlin.line_quantity );
      --
        else
      --
            l_unit_price := rlin.unit_price;
      --
        end if;
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
        for rpo in (
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
                            1 = 1--i.receiver            = get_bu_cnpj(p_Efd.rHea.Receiver_document_number)
                        and i.cnpj = p_efd.rhea.issuer_document_number
                        and regexp_replace(i.po_num, '[^0-9]') = regexp_replace(
                            nvl(rlin.source_doc_number, i.po_num),
                            '[^0-9]'
                        ) --Victor
                --AND  to_number(i.line_num)  = to_number(nvl(rLin.source_doc_line_num,i.line_num))
                        and i.item_number = nvl(rlin.item_code_efd, i.item_number)
                        and i.po_line_id = nvl(rlin.source_doc_line_id, i.po_line_id)
                        and nvl(i.receipt_num, 'NA') = nvl(rlin.receipt_num,
                                                           nvl(i.receipt_num, 'NA'))
                        and nvl(i.receipt_line_num, 'NA') = nvl(rlin.receipt_line_num,
                                                                nvl(i.receipt_line_num, 'NA'))
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

            print(round(l_unit_price, 2)
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
                    round(l_unit_price, 2) = round(
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
          --
                    exit;
          --
                end if;
        --
            end if;
      
      ----

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
                p_efd.rlin(p_idx).rlin.receipt_num := rpo.receipt_num;
                p_efd.rlin(p_idx).rlin.receipt_line_num := rpo.receipt_line_num;                 
        --
                p_efd.rhea.party_name := rpo.vendor_name;
        --
                p_efd.rhea.currency_code := rpo.currency_code;
                p_efd.rhea.source_doc_info := rpo.info_doc;
                p_efd.rhea.term_info := rpo.info_term;
                p_efd.rhea.vendor_site_code := rpo.vendor_site_code;
        --
        --
                rshp.efd_line_id := rlin.efd_line_id;
                rshp.ship_to_organization_id := rpo.ship_to_organization_id;
                rshp.ship_to_location_id := rpo.ship_to_location_id;
                rshp.source_doc_shipment_id := rpo.line_location_id;
                rshp.quantity_to_receive := rlin.line_quantity;
        --
                l_count := 1;
        --
                g_po_find := true;
        --
                print('Localizado pelo line_id ');
        --
                exit;
        --
        
        --
        --
            end if;
      --
--      Print(rPo.po_line_id||'.'||nvl(rPo.line_location_id,0)||' '||CASE WHEN g_shipments.exists(rPo.po_line_id||'.'||nvl(rPo.line_location_id,0)) THEN ' Exists' ELSE ' Not Exists' END);
      --
            print('Status Linha consistencia: ' || p_efd.rlin(p_idx).rlin.status);
      --        
            if nvl(p_efd.rlin(p_idx).rlin.status,
                   '$') <> 'MANUAL' then
        --
                if (
                    ( (
           -- round(rLin.line_quantity,     3) IN( round(nvl(rPo.quantity_ship,0),3),  round(nvl(rPo.quantity_line,0),3))
                        round(rlin.line_quantity, 3) = ( round(
                            nvl(
                                nvl(rpo.quantity_ship, rpo.quantity_line),
                                0
                            ),
                            3
                        ) )
            --round(rLin.line_quantity,     3) <=( round(nvl(nvl(rPo.quantity_ship,rPo.quantity_line),0),3)) 22/08/2021
                        and round(l_unit_price, 2) = round(
                            nvl(rpo.unit_price, 0),
                            2
                        )
                    )
                    or (
                        l_count = 0
                        and ( round(rlin.line_amount, 2) in ( round(nvl(rpo.unit_price, 0) * nvl(rpo.quantity_ship, 0),
                                                                    2), round(nvl(rpo.unit_price, 0) * nvl(rpo.quantity_ship, 0),
                                                                              2) ) 
          --  OR round(p_Efd.rHea.total_amount,2)  =  round(nvl(rPo.total_po,     0),2) 22/08/2021
                                                                               )
                    ) )
                    and not g_shipments.exists(rpo.po_line_id
                                               || '.' || nvl(rpo.line_location_id, 0))
                )
            --AND nvl(rLin.source_doc_number ,rPo.po_num) = rPo.po_num
                 then
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
                        ( round(l_unit_price, 2) <> round(
                            nvl(rpo.unit_price, 0),
                            2
                        )
                        or --alteração de valores caso seja determinada linha automática com PO Guardachuva
                         trunc(l_unit_price, 2) <> trunc(
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
                    rlin.item_info := rpo.info_item;
          -- 
                    rlin.receipt_num := rpo.receipt_num;
                    rlin.receipt_line_num := rpo.receipt_line_num;
                           
        --
  --      rLin.shipto_info             := rPo.info_ship;
                    rlin.item_code_efd := rpo.item_number;
                    rlin.item_descr_efd := rpo.description;
                    rlin.uom_to := rpo.uom_code;
                    rlin.uom_to_desc := rpo.uom_desc;
                    rlin.destination_type := rpo.destination_type;
                    rlin.fiscal_classification_to := rpo.ncm;
                    rlin.catalog_code_ncm := rpo.catalog_code_ncm;
                    rhea.currency_code := rpo.currency_code;
                    rhea.term_info := rpo.info_term;
                    rhea.vendor_site_code := rpo.vendor_site_code;
          --
                    rhea.party_name := rpo.vendor_name;
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
                    g_po_find := true;
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
                    || ' Não localizada.',
                    p_efd.rlin(p_idx).rlin.efd_line_id,
                    p_efd.rhea.efd_header_id);
      --
        elsif
            l_count = 0
            and nvl(p_efd.rlin(p_idx).rlin.status,
                    'X') not in ( 'INVALID', 'MANUAL' )
        then
      --
            print('Buscando Po considerando por valor unitário e quantidade parcial');
      --
            for rpo in (
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
                                i.receiver = get_bu_cnpj(p_efd.rhea.receiver_document_number)
                            and i.cnpj = p_efd.rhea.issuer_document_number
                            and i.item_number = nvl(rlin.item_code_efd, i.item_number)
                            and regexp_replace(i.po_num, '[^0-9]') = regexp_replace(
                                nvl(rlin.source_doc_number, i.po_num),
                                '[^0-9]'
                            ) --Victor
                            and i.po_line_id = nvl(rlin.source_doc_line_id, i.po_line_id)
                            and nvl(i.receipt_num, 'NA') = nvl(rlin.receipt_num,
                                                               nvl(i.receipt_num, 'NA'))
                            and nvl(i.receipt_line_num, 'NA') = nvl(rlin.receipt_line_num,
                                                                    nvl(i.receipt_line_num, 'NA'))
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
            ) loop
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

                print(round(l_unit_price, 2)
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
                    p_efd.rhea.currency_code := rpo.currency_code;
                    p_efd.rhea.source_doc_info := rpo.info_doc;
                    p_efd.rhea.term_info := rpo.info_term;
                    p_efd.rhea.vendor_site_code := rpo.vendor_site_code;
          --
                    g_po_find := true;
          --
          --
                end if;
        --
  --      Print(rPo.po_line_id||'.'||nvl(rPo.line_location_id,0)||' '||CASE WHEN g_shipments.exists(rPo.po_line_id||'.'||nvl(rPo.line_location_id,0)) THEN ' Exists' ELSE ' Not Exists' END);
        --
                print('Status Linha parcial consistencia: ' || p_efd.rlin(p_idx).rlin.status);
                if nvl(p_efd.rlin(p_idx).rlin.status,
                       '$') <> 'MANUAL' then
          --
                    if (
                        ( (
             -- round(rLin.line_quantity,     3) IN( round(nvl(rPo.quantity_ship,0),3),  round(nvl(rPo.quantity_line,0),3))
                            round(rlin.line_quantity, 3) <= ( round(
                                nvl(
                                    nvl(rpo.quantity_ship, rpo.quantity_line),
                                    0
                                ),
                                3
                            ) )
                            and round(l_unit_price, 2) = round(
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
                    )
              --AND nvl(rLin.source_doc_number ,rPo.po_num) = rPo.po_num
                     then
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
                        if
                            ( round(l_unit_price, 2) <> round(
                                nvl(rpo.unit_price, 0),
                                2
                            )
                            or --alteração de valores caso seja determinada linha automática com PO Guardachuva
                             trunc(l_unit_price, 2) <> trunc(
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
            --
                        rlin.source_doc_id := rpo.po_header_id;
                        rlin.source_doc_line_id := rpo.po_line_id;
                        rlin.source_doc_line_num := rpo.line_num;
                        rlin.source_doc_number := rpo.po_num;
                        rlin.line_location_id := rpo.line_location_id;
                        rlin.status := 'AUTO';
                        rlin.order_info := rpo.info_po;
                        rlin.item_info := rpo.info_item;
    --      rLin.shipto_info             := rPo.info_ship;
                        rlin.item_code_efd := rpo.item_number;
                        rlin.item_descr_efd := rpo.description;
                        rlin.uom_to := rpo.uom_code;
                        rlin.uom_to_desc := rpo.uom_desc;
                        rlin.destination_type := rpo.destination_type;
                        rlin.fiscal_classification_to := rpo.ncm;
                        rlin.catalog_code_ncm := rpo.catalog_code_ncm;
                        rhea.currency_code := rpo.currency_code;
                        rhea.term_info := rpo.info_term;
                        rhea.vendor_site_code := rpo.vendor_site_code;
            --
                        rhea.party_name := rpo.vendor_name;
            -- 
                        rlin.receipt_num := rpo.receipt_num;
                        rlin.receipt_line_num := rpo.receipt_line_num;                 
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
                        g_po_find := true;
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
      --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Ordem de Compra '||rLin.source_doc_number||' selecionada automaticamente pelo sistema.'||'<br>';
      --
            if rshp.source_doc_shipment_id is null then
         --
                log_efd('Atenção! Dados de entrega não localizado para Ordem de Compra '
                        || rlin.source_doc_number
                        || ' selecionada.',
                        rlin.efd_line_id,
                        p_efd.rhea.efd_header_id);
         --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Atenção! Dados de entrega não localizado para Ordem de Compra '||rLin.source_doc_number||' selecionada.'||'<br>';
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
                            || ' Não localizada.',
                            p_efd.rlin(p_idx).rlin.efd_line_id,
                            p_efd.rhea.efd_header_id);
          --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' PO '||p_Efd.rLin(p_Idx).rLin.source_doc_number||' Não localizada.'||'<br>';
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
        --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Mais de uma Ordem de Compra encontrada. Favor selecionar manualmente.'||'<br>';
        --
                g_po_find := true;
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
        p_cnpj in varchar2,
        p_type in varchar2
    ) return clob is
        l_response clob;
        l_ctrl     varchar2(300);
        l_body     varchar2(600);
  --
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
        --
      /*  SELECT json_value(receiver_info,'$.DATA.BU_NAME')
        INTO l_bu
        FROM rmais_efd_headers
        WHERE efd_header_id = :P11_EFD_HEADER_ID;
        --
        l_body := REPLACE(l_body,'$BU$',l_bu);
      */  --
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
                      || get_bu_cnpj(p_cnpj)
                      || '","bu": "$BU$"}';
      --
            print(get_parameter('GET_'
                                || p_type || '_URL')
                  || '/' || get_bu_cnpj(p_cnpj));
      --
            return get_response(get_parameter('GET_'
                                              || p_type || '_URL')
                                || '/' || get_bu_cnpj(p_cnpj));
      --
      --
        end if;
    --
    exception
        when others then
            print('Get Issuer ERROR: ' || sqlerrm);
    end;
  --
    function return_filename_croped (
        p_filename       varchar2,
        p_extension_flag varchar2 default 'Y'
    ) return varchar2 as
        l_return varchar2(100);
    begin
        select
            case
                when length(p_filename) < 50 then
                    p_filename
                else
                    substr(p_filename,
                           length(p_filename) - 50)
            end filename
        into l_return
        from
            dual;

        if p_extension_flag = 'N' then
            l_return := substr(l_return,
                               1,
                               instr(l_return, '.', -1) - 1);

        end if;

        return l_return;
    exception
        when others then
            return p_filename;
    end return_filename_croped;
  --
    function get_invoice_v2 (
        p_header_id in number
    ) return clob is
    begin
    --
        for r in (
            with tp_cfop as (
                select
                    a.efd_header_id,
                    max(a.fiscal_classification) cfop
                from
                    rmais_efd_lines a
                where
                    a.cfop_from is not null
                group by
                    a.efd_header_id
            ), l as (
                select
                    l.efd_header_id,
                    l.line_number,
                    nvl(l.line_amount, l.line_quantity * l.unit_price) + nvl(l.freight_line_amount, 0)                                                        line_amount
                    ,
                    nvl(l.ipi_amount, 0) + nvl(l.freight_line_amount, 0) - nvl(l.discount_line_amount, 0) + nvl(l.insurance_line_amount
                    , 0) + nvl(l.icms_st_amount, 0) dif_nfe,
                    nvl(l.uom_to_desc, uom_to)                                                                                                                uom_to
                    ,
                    l.fiscal_classification_to
           --, NVL(l.item_info.DESCRIPTION,l.item_descr_efd) item_desc
                    ,
                    nvl(
                        nvl(l.item_info.description,
                            l.item_descr_efd),
                        l.order_info.item_description
                    )                                                                                                                                         item_desc
                    ,
                    nvl(l.item_info.item_number,
                        l.item_code_efd)                                                                                                                      item_code
                        ,
                    l.line_quantity,
                    l.unit_price,
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
                    l.fiscal_classification,
                    nvl(
                        max((
                            select
                                max(determining_factor)
                            from
                                rmais_efd_taxes tx
                            where
                                tx.efd_line_id = l.efd_line_id
                        )),
                        rmais_process_pkg_bkp_to_worflow.get_parameter('DETERM_FACTOR')
                    )                                                                                                                                         determining_factor
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
                    l.intended_use,
                    (
                        select distinct
                            classification_name
                        from
                            rmais_utilizations_ws
                        where
                            classification_code = l.intended_use
                    )                                                                                                                                         intended_use_descr
                    ,
                    l.receipt_num,
                    l.receipt_line_num,
                    nvl(l.freight_line_amount, 0)                                                                                                             freight_line_amount
                    ,
                    l.account_cc,
                    l.item_code_efd
                from
                    rmais_efd_lines l --adicionado busca WS 17/02/2022
                where
                    1 = 1-- ROWNUM <=10
                group by
                    l.efd_header_id,
                    l.line_number,
                    l.line_amount,
                    l.ipi_amount,
                    l.freight_line_amount,
                    l.discount_line_amount,
                    l.insurance_line_amount,
                    l.icms_st_amount,
                    nvl(l.uom_to_desc, uom_to),
                    l.fiscal_classification_to,
                    nvl(
                        nvl(l.item_info.description,
                            l.item_descr_efd),
                        l.order_info.item_description
                    ),
                    nvl(l.item_info.item_number,
                        l.item_code_efd),
                    l.line_quantity,
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
                    l.receipt_num,
                    l.receipt_line_num,
                    l.account_cc,
                    l.item_code_efd
            )
            select
                    json_object(
                        'InvoiceNumber' is h.document_number,
                                'InvoiceCurrency' is nvl(h.currency_code, 'BRL'),
                                'PaymentCurrency' is nvl(h.currency_code, 'BRL'),
                                'InvoiceAmount' is h.total_amount,
                                'InvoiceDate' is to_char(h.issue_date, 'RRRR-MM-DD')
           --,'BusinessUnit'                        IS nvl(h.receiver_info.DATA.BU_NAME, h.receiver_name)
                                ,
                                'BusinessUnit' is nvl(
                            nvl(h.receiver_info.data.bu_name,
                                h.receiver_info.bu_name),
                            'Não localizada'
                        ) --HDI Seguros S.A. BU
           --,'ProcurementBU'                       IS nvl(nvl(h.receiver_info.DATA.BU_NAME,h.receiver_info.BU_NAME), 'Não localizada')
       --    ,'Supplier'                            IS coalesce(h.issuer_info.DATA.PARTY_NAME,(
                        ,
                                'Supplier' is nvl(h.party_name,
                                                  nvl(
                                                                          nvl((
                                                                              select
                                                                                  max(l.order_info.vendor_name)
                                                                              from
                                                                                  rmais_efd_lines l
                                                                              where
                                                                                  l.efd_header_id = h.efd_header_id
                                                                          ),
                                                                              (
                                                                              select distinct
                                                                                  party_name
                                                                              from
                                                                                  (
                                                                                      select distinct
                                                                                          party_name,
                                                                                          party_id -- into l_aux
                                                                                      from
                                                                                          json_table(replace(
                                                                                              replace(h.issuer_info, '"DATA":{', '"DATA": [{'
                                                                                              ),
                                                                                              '}}}',
                                                                                              '}}]}'
                                                                                          ),
                                                                              '$'
                                                                                              columns(
                                                                                                  nested path '$.DATA[*]'
                                                                                                      columns(
                                                                                                          p_tax_payer_number varchar2
                                                                                                          (4000) path '$.P_TAX_PAYER_NUMBER'
                                                                                                          ,
                                                                              party_name varchar2(4000) path '$.PARTY_NAME',
                                                                              party_name2 varchar2(4000) path '$.PARTY_NAME',
                                                                              party_id varchar2(4000) path '$.PARTY_ID',
                                                                              nested path '$.ADDRESS[*]'
                                                                                                              columns(
                                                                                                                  address1 varchar2(4000
                                                                                                                  ) path '$.ADDRESS1'
                                                                                                                  ,
                                                                              address2 varchar2(4000) path '$.ADDRESS2',
                                                                              address3 varchar2(4000) path '$.ADDRESS3',
                                                                              address4 varchar2(4000) path '$.ADDRESS4',
                                                                              city varchar2(4000) path '$.CITY',
                                                                              postal_code varchar2(4000) path '$.POSTAL_CODE',
                                                                              state varchar2(4000) path '$.STATE',
                                                                              vendor_site_code varchar2(4000) path '$.VENDOR_SITE_CODE'
                                                                                                              )
                                                                                                      )
                                                                                              )
                                                                                          )
                                                                                      order by
                                                                                          party_id desc
                                                                                  )
                                                                              where
                                                                                  rownum = 1
                                                                          )),
                                                                          'NAO LOCALIZADO'
                                                                      )),
                                'SupplierSite' is nvl(h.vendor_site_code, h.issuer_document_number),
                                'AccountingDate' is to_char(sysdate, 'RRRR-MM-DD')
          -- ,'PaymentTerms'                        IS CASE WHEN nvl(h.document_type,'PO') = 'NA' THEN (SELECT NAME FROM rmais_terms_ws WHERE term_id = h.payment_term_id) ELSE h.term_info.TERMS END
           --,'TermsDate'                           IS to_char(h.issue_date + h.term_info.DUE_DAYS,'RRRR-MM-DD')
                                ,
                                'TermsDate' is to_char(h.issue_date, 'RRRR-MM-DD'),
                                'LegalEntityIdentifier' is h.receiver_document_number,
                                'TaxationCountry' is 'Brazil'
         --  ,'invoiceDff'                          IS (
         --  SELECT json_arrayagg(json_object (
          -- 'apTipoNff' IS CASE WHEN h.model = '55' THEN 'Geral' ELSE 'Serviços Tomados' END))FROM dual)
           -- ,'RegistrationId'                     IS h.org_id
          
          -- ativar para produçao ,'FirstPartyTaxRegistrationId'           IS h.org_id
          -- Desativar linha abaixo para produção
                                ,
                                'FirstPartyTaxRegistrationId' is
                            case
                                when h.org_id = '300000024270757'
                                     and h.issue_date <= to_date('2022-10-16',
                                    'YYYY-MM-DD') then
                                    '300000024270758'
                                else
                                    to_char(h.org_id)
                            end,
                                'FirstPartyTaxRegistrationNumber' is h.receiver_document_number
          --,'LegalEntity' is 'HDI Seguros S.A.'
          
          --,'PayGroup'                             IS CASE WHEN nvl(h.PAYMENT_INDICATOR,'N') = 'N' THEN '' ELSE nvl(RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.Get_Parameter('GET_NO_PAY'),'NAO GERA PAGAMENTO') END --21_09_2021 adicionado nao gera pagamento
                                ,
                                'InvoiceSource' is 'RECEBEMAIS' 
         -- ,'Description'                          IS ''
/*"invoiceDff": [{
        "__FLEX_Context": "ISVCLS_BRA",
            "__FLEX_Context_DisplayValue": "ISV Additional Information",
            "isvModel": "1",
            "isvSerie": null,
            "isvSubserie": "3",
            "isvAccessKey": "1000002020"
    }],
    
07	Nota Fiscal de Serviço de Transporte
1A	1A
21	Nota Fiscal de Serviço de Comunicação
22	Nota Fiscal de Serviço de Telecomunicações
32	Fatura
38	Nota Fiscal Fatura de Serviços
39	Nota Fiscal de Serviços Eletrônica
40	Nota Fiscal de Serviços Avulsa
41	Nota Fiscal de Serviços Avulsa Eletrônica
42	Nota Fiscal de Serviço Simplificada
43	Recibo
90	Nota Fiscal de Serviço
99	Outros
    
    
    */
           --'Geral'
                                ,
                                'invoiceDff' is(
                            select
                                json_arrayagg(
                                    json_object(
                                        '__FLEX_Context' is 'ISVCLS_BRA',
                                                '__FLEX_Context_DisplayValue' is 'ISV Additional Information',
                                                'isvModel' is
                                            case
                                                when h.model = '57' then
                                                    '57'
                                                when h.model = '21' then
                                                    '21'
                                                when h.model = '22' then
                                                    '22'
                                                when h.model = 'NF' then
                                                    '32'
                                                when h.model = '00' then
                                                    '39'
                                                when h.model = '55'
                                                     and h.issuer_address_city_code = '5300108'
                                                     and instr(f.cfop, '.') > 0 then
                                                    '39'
                                                when h.model = '55' then
                                                    '55'
                                                else
                                                    '99'
                                            end,
                                                'isvSerie' is
                                            case
                                                when h.model in('55', '57', '67') then
                                                    h.series
                                                else
                                                    'SS'
                                            end,
                                                'isvSubserie' is '',
                                                'isvAccessKey' is h.access_key_number absent on null)
                                )
                            from
                                dual
                        ),
                                'invoiceLines' is(
                            select
                                json_arrayagg(
                                    json_object(
                                        'LineNumber' is l.line_number,
                                                'LineAmount' is l.line_amount,
                                                'AccountingDate' is to_char(sysdate, 'RRRR-MM-DD'),
                                                'UOM' is l.uom_to,
                                                'LineType' is 'Item',
                                                'Description' is l.item_desc,
                                                'Item' is l.item_code
           --,'Quantity'                            IS CASE h.model WHEN '00' THEN null ELSE l.line_quantity END
                                                ,
                                                'Quantity' is l.line_quantity,
                                                'UnitPrice' is l.unit_price + round((nvl(l.freight_line_amount, 0) / l.line_quantity)
                                                ,
                                                                                    2),
                                                'ProductType' is 'Services'
           --, decode(l.source_document_type,'NA','ProductType','Withholding')          IS CASE WHEN l.source_document_type = 'NA' THEN l.item_type_na ELSE NULL END
                                                ,
                                                'Withholding' is
                                            case
                                                when h.withholding in('ISS_RET_2.00', 'ISS200') then
                                                    'ISS_200'
                                                when h.withholding in('ISS_RET_2.01', 'ISS201') then
                                                    'ISS_201'
                                                else
                                                    h.withholding
                                            end 
           --,'ProductType'                         IS NULL
                                            ,
                                                'TransactionBusinessCategoryCodePath' is 'PURCHASE_TRANSACTION/OPERATION FISCAL CODE/'
                                                                                         ||
                                            case
                                                when h.model in('55', '57', '67') then
                                                    to_char(l.cfop_to)
                                                else
                                                    case
                                                        when h.issuer_address_state = h.receiver_address_state then
                                                                '1'
                                                        else
                                                            '2'
                                                    end
                                                    || '933'
                                            end,
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
                                                'ReceiptNumber' is l.receipt_num,
                                                'ReceiptLineNumber' is l.receipt_line_num
		   
           /*,'ProductFiscalClassification'         IS CASE h.model WHEN '00' THEN '|'||lpad(REPLACE(l.fiscal_classification,'.',''),4,'0')||'|' ELSE l.fiscal_classification_to END
           ,'ProductFiscalClassificationCode'     IS CASE h.model WHEN '00' THEN '|'||lpad(REPLACE(l.fiscal_classification,'.',''),4,'0')||'|' ELSE l.fiscal_classification_to END
           , 'ProductFiscalClassificationType'    IS nvl(l.CATALOG_CODE_NCM,'LACLS_NCM_SERVICE_CODE')*/,
                                                'ProductFiscalClassification' is null-- CASE h.model WHEN '00' THEN null ELSE l.fiscal_classification_to END
                                                ,
                                                'ProductFiscalClassificationCode' is null--CASE h.model WHEN '00' THEN null ELSE l.fiscal_classification_to END
                                                ,
                                                'ProductFiscalClassificationType' is null--CASE h.model WHEN '00' THEN null ELSE nvl(l.CATALOG_CODE_NCM,'LACLS_NCM_SERVICE_CODE') end --ALTWRAR CONSISTENCIA VERIFICAR PO SE EXISTE ITEM
                                                ,
                                                'ProductCategory' is l.product_category,
                                                'UserDefinedFiscalClassification' is
                                            case
                                                when l.item_code_efd <> 'O10004' then
                                                    l.user_defined
                                                else
                                                    null
                                            end,
                                                'IntendedUseCode' is l.intended_use,
                                                'IntendedUse' is l.intended_use_descr,
                                                'DistributionCombination' is l.account_cc absent on null)
                                returning clob)
                            from
                                l
                            where
                                    1 = 1
                                and l.efd_header_id = h.efd_header_id
                        ),
                                'invoiceInstallments' is(
                            select
                                json_arrayagg(
                                    json_object(
                                        'InstallmentNumber' is 1,
                                                'FirstDiscountDate' is to_char(
                                            nvl(first_due_date, sysdate),
                                            'RRRR-MM-DD'
                                        ),--json_value(l2.order_info,'$.LINE_LOCATIONS.NEED_BY_DATE'),--to_char(first_due_date,'RRRR-MM-DD'),
             --'DueDate'                    IS to_char(nvl(first_due_date,sysdate),'RRRR-MM-DD'),--json_value(l2.order_info,'$.LINE_LOCATIONS.NEED_BY_DATE'),--to_char(first_due_date,'RRRR-MM-DD'),
                                                'DueDate' is nvl((
                                            select
                                                to_char(to_timestamp_tz(json_value(order_info, '$.LINES.LINE_LOCATIONS.NEED_BY_DATE')
                                                ,
                                                        'RRRR-MM-DD"T"HH24:MI:SS TZR'),
                                                        'RRRR-MM-DD')
                                            from
                                                rmais_efd_lines
                                            where
                                                    efd_header_id = p_header_id
                                                and rownum = 1
                                        ),
                                                                 to_char(
                                                                                                         nvl(first_due_date, sysdate)
                                                                                                         ,
                                                                                                         'RRRR-MM-DD'
                                                                                                     )),
                                                'GrossAmount' is h.total_amount,
                                                'FirstDiscountAmount' is nvl(h.discount_amount, 0),
                                                'PaymentMethod' is nvl(
                                            xxrmais_util_v2_pkg.get_metodo_pagamento(h.efd_header_id),
                                            decode(
                                                                                        to_char(length(regexp_replace(h.boleto_cod, '[^0-9]'
                                                                                        ))),
                                                                                        '47',
                                                                                        'BOLETO',
                                                                                        '48',
                                                                                        'CONCESSIONARIAS',
                                                                                        'BAIXA MANUAL'
                                                                                    )
                                        )
                                    absent on null)
                                )
                            from
                                dual
                            where
                                h.discount_amount is not null
                                or h.boleto_cod is not null
                                or xxrmais_util_v2_pkg.get_metodo_pagamento(h.efd_header_id) is not null
                        )/*
             --,
             'invoiceInstallmentDff'      is (SELECT json_arrayagg(json_object (
                 '_Payment__mode'         is null--'W'
                 ))from dual)
             )) from dual ),*/,
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
             --'FileName'                   IS AT.filename,
                                            'FileName' is return_filename_croped(at.filename),--substr(SUBSTR(upper(AT.filename),1,INSTR(upper(AT.filename),'.PDF')-1),1,50)||SUBSTR(upper(AT.filename),INSTR(upper(AT.filename),'.PDF'),4),
             --'Title'                      IS  replace(replace(AT.filename,'.pdf',''),'.PDF',''),
                                            'Title' is return_filename_croped(at.filename, 'N'),--replace(replace(substr(SUBSTR(upper(AT.filename),1,INSTR(upper(AT.filename),'.PDF')-1),1,50)||SUBSTR(upper(AT.filename),INSTR(upper(AT.filename),'.PDF'),4),'.pdf',''),'.PDF',''),
             -- substr(SUBSTR(upper(AT.filename),1,INSTR(upper(AT.filename),'.PDF')-1),1,50)||SUBSTR(upper(AT.filename),INSTR(upper(AT.filename),'.PDF'),4)
             --'Description'                IS replace(replace(AT.filename,'.pdf',''),'.PDF',''),
                                            'Description' is return_filename_croped(at.filename, 'N'),--replace(replace(substr(SUBSTR(upper(AT.filename),1,INSTR(upper(AT.filename),'.PDF')-1),1,50)||SUBSTR(upper(AT.filename),INSTR(upper(AT.filename),'.PDF'),4),'.pdf',''),'.PDF',''),
                                            'Category' is
                                        case
                                            when at.filename is not null then
                                                'From Supplier'
                                            else
                                                ''
                                        end,
                                            'FileContents' is at.clob_file
                                returning clob)
                            absent on null returning clob)
                        from
                            dual
                    ) absent on null returning clob)
                doc
            from
                rmais_efd_headers h,
                rmais_attachments at,
                tp_cfop           f
            where
                    h.efd_header_id = p_header_id
                and h.efd_header_id = at.efd_header_id (+)
                and h.efd_header_id = f.efd_header_id (+)
        ) loop
      --
      --Print('Getting Invoice: '||r.doc);
      --
            return r.doc;
      --
        end loop;
    --
    end;
  --
  --
    function get_invoice (
        p_header_id in number
    ) return clob is
    begin
    --
        for r in (
            with l as (
                select
                    l.efd_header_id,
                    l.line_number,
                    l.line_amount,
                    nvl(l.ipi_amount, 0) + nvl(l.freight_line_amount, 0) - nvl(l.discount_line_amount, 0) + nvl(l.insurance_line_amount
                    , 0) + nvl(l.icms_st_amount, 0) dif_nfe,
                    l.uom_to,
                    nvl(l.item_info.description,
                        l.item_descr_efd)                                                                                                                     item_desc
                        ,
                    nvl(l.item_info.item_number,
                        l.item_code_efd)                                                                                                                      item_code
                        ,
                    l.line_quantity,
                    l.unit_price,
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
                    nvl(
                        nvl(l.order_info.line_locations.shipment_num,
                            l.line_number),
                        1
                    )                                                                                                                                         shipment_num
                    ,
                    l.fiscal_classification,
                    nvl(
                        max((
                            select
                                max(determining_factor)
                            from
                                rmais_efd_taxes tx
                            where
                                tx.efd_line_id = l.efd_line_id
                        )),
                        rmais_process_pkg_bkp_to_worflow.get_parameter('DETERM_FACTOR')
                    )                                                                                                                                         determining_factor
                from
                    rmais_efd_lines l
                where
                    1 = 1-- ROWNUM <=10
                group by
                    l.efd_header_id,
                    l.line_number,
                    l.line_amount,
                    l.ipi_amount,
                    l.freight_line_amount,
                    l.discount_line_amount,
                    l.insurance_line_amount,
                    l.icms_st_amount,
                    l.uom_to,
                    nvl(l.item_info.description,
                        l.item_descr_efd),
                    nvl(l.item_info.item_number,
                        l.item_code_efd),
                    l.line_quantity,
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
                    nvl(l.order_info.line_locations.shipment_num,
                        1),
                    l.fiscal_classification
            )
            select
                    json_object(
                        'InvoiceNumber' is h.document_number,
                                'InvoiceCurrency' is h.currency_code,
                                'PaymentCurrency' is h.currency_code,
                                'InvoiceAmount' is h.total_amount,
                                'InvoiceDate' is to_char(h.issue_date, 'RRRR-MM-DD'),
                                'BusinessUnit' is nvl(
                            nvl(h.receiver_info.data.bu_name,
                                h.receiver_info.bu_name),
                            h.receiver_name
                        ),
                                'Supplier' is coalesce(h.issuer_info.data.party_name,
                                                       (
                                                                          select
                                                                              max(l.order_info.vendor_name)
                                                                          from
                                                                              rmais_efd_lines l
                                                                          where
                                                                              l.efd_header_id = h.efd_header_id
                                                                      ),
                                                       h.issuer_name),
                                'SupplierSite' is nvl(h.vendor_site_code, '0001'),
                                'AccountingDate' is to_char(sysdate, 'RRRR-MM-DD'),
                                'PaymentTerms' is h.term_info.terms
           --,'TermsDate'                           IS to_char(h.issue_date + h.term_info.DUE_DAYS,'RRRR-MM-DD')
                                ,
                                'TermsDate' is to_char(h.issue_date, 'RRRR-MM-DD'),
                                'LegalEntityIdentifier' is h.receiver_document_number,
                                'TaxationCountry' is 'Brazil',
                                'FirstPartyTaxRegistrationNumber' is h.receiver_document_number,
                                'invoiceLines' is(
                            select
                                json_arrayagg(
                                    json_object(
                                        'LineNumber' is l.line_number,
                                                'LineAmount' is l.line_amount--CASE WHEN h.model = '55' THEN l.line_amount + l.dif_nfe ELSE l.line_amount END
                                                ,
                                                'AccountingDate' is to_char(sysdate, 'RRRR-MM-DD'),
                                                'UOM' is l.uom_to,
                                                'LineType' is 'Item',
                                                'Description' is l.item_desc,
                                                'Item' is l.item_code,
                                                'Quantity' is l.line_quantity,
                                                'UnitPrice' is l.unit_price,
                                                'ProductType' is l.item_type,
                                                'TransactionBusinessCategoryCodePath' is 'PURCHASE_TRANSACTION/OPERATION FISCAL CODE/1933'
                                                ,
                                                'ProductFiscalClassification' is l.fiscal_classification,
                                                'ProductFiscalClassificationCode' is l.fiscal_classification,
                                                'ProductFiscalClassificationType' is l.determining_factor,
                                                'PurchaseOrderNumber' is l.source_doc_number,
                                                'PurchaseOrderLineNumber' is l.source_doc_line_num,
                                                'PurchaseOrderScheduleLineNumber' is l.shipment_num
                                    )
                                returning clob)
                            from
                                l
                            where
                                    1 = 1
                                and l.efd_header_id = h.efd_header_id
                        )
                    returning clob)
                doc
            from
                rmais_efd_headers h
            where
                h.efd_header_id = p_header_id
        ) loop
      --
      --Print('Getting Invoice: '||r.doc);
      --
            return r.doc;
      --
        end loop;
    --
    end;
  --
  --
    procedure send_invoice (
        p_header_id in number
    ) is

        l_return clob;
        l_body   clob := get_invoice(p_header_id);
        l_url    varchar2(4000) := get_parameter('SEND_INVOICE_AP_URL');
    begin
    --
    --print('BODY BEFORE '||l_body);
    --
    --l_body := '{"BASE64":"'||replace(translate(xxrmais_util_pkg.base64encode(xxrmais_util_pkg.clob_to_blob(l_body)), chr(10) || chr(13) || chr(09), ' '),' ','')||'"}';
        l_body :=
            json_object(
                'BASE64' value regexp_replace(
                    text2base64(l_body),
                    '[^[:alnum:][:print:]]'
                )
            );
    --
    --Print(Get_ws||l_url);
    --
        l_return := get_response(l_url, l_body, 'POST');
    --
        print(l_return);
    --
        for r in (
            select
                json_value(l_return, '$.code')    as code,
                json_value(l_return, '$.retorno') as retorno
            from
                dual
        ) loop
      --
            log_efd(
                nvl(r.retorno, 'Enviado para ERP'),
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
            commit;
      --
        end loop;
    --
    exception
        when others then
            print('Send Invoice ERROR: ' || sqlerrm);
    end;
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
        for nf in (
            select
                nvl(blob_file, pdf_file)         pdf_file,
                nvl(blob_filename, pdf_filename) pdf_filename,
                model,
                access_key_number,
                issuer_address_city_code,
                document_number
            from
                rmais_efd_headers
            where
                efd_header_id = p_efd_header_id
        ) loop
        --
            print(nf.model);
            if nf.model in ( '55', '57', '67' ) then
          --chamada para ws base64 de layout via xml
                declare
                    l_clob           clob;
                    l_transaction_id number;
                    l_reponse        clob;
                begin
            --
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
            --COMMIT;
            --
                    declare
                        l_body clob;          --  http://150.230.68.115/luznfe/rest.php?class=getPDF&method=executar
                        l_url  varchar2(300) := rmais_process_pkg_bkp_to_worflow.get_parameter('URL_GET_PDF');
                                    
            --UTL_URL.Escape(RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.Get_Parameter('URL_GENERATE_PFD','TEXT_VALUE'), True);--'http://150.230.68.115/luznfe/rest.php?class=getPDF&method=executar'; --parametrizar endereço
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
                        print('l_url: ' || l_url);
            --
                        print('l_body: ' || l_body);
            --
                        l_reponse := get_response2(
                            utl_url.escape(l_url),
                            l_body,
                            'POST'
                        );
            --
                        print('l_reponse: ' || l_reponse);
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
                                                               when upper(nf.pdf_filename) like '%.PDF%' then
                                                                   'PDF'
                                                               when upper(nf.pdf_filename) like '%.JPG%' then
                                                                   'JPG'
                                                               when upper(nf.pdf_filename) like '%.GIF%' then
                                                                   'GIF'
                                                               when upper(nf.pdf_filename) like '%.PNG%' then
                                                                   'PNG'
                                                               when upper(nf.pdf_filename) like '%.XLS%' then
                                                                   'XLS'
                                                               when upper(nf.pdf_filename) like '%.CSV%' then
                                                                   'CSV'
                                                               when upper(nf.pdf_filename) like '%.ZIP%' then
                                                                   'ZIP'
                                                               else
                                                                   ''
                                                           end,
                                                           sysdate );
            --
                else
                    if
                        nf.issuer_address_city_code in ( '3550308', -- Sao paulo
                         '3505708',  -- Batueri
                         '3547809',  -- Santo Andre
                         '3552502',  -- Suzano
                         '3548708',  -- Sao Bernardo
                                                         '3106200',  -- Belo Horizonte
                                                          '3524303',  -- Jaboticabal
                                                          '4128104',  --Umuarama
                                                          '3516200',  --Franca
                                                          '3523909',  --itu
                                                         '3518800'   --Londrina
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
                                l_url  varchar2(300) := rmais_process_pkg_bkp_to_worflow.get_parameter('URL_GET_PDF'); --parametrizar endereço
                            begin
                                l_body :=
                                    json_object(
                                        'transaction_id' value l_transaction_id,
                                        'method' value null,-- nf.issuer_address_city_code,
                                        'url' value l_link
                                    );
                --
                                print('l_url: ' || l_url);
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
    --
    procedure send_boleto (
        p_efd_header_id in number
    ) as
        l_body     clob;
        l_url      varchar2(500) := '/api/ap/v1/slip';
        l_response varchar2(1000);
  --
    begin
    --
        select
            json_object(
                'invoice_num' value rmh.document_number,
                        'invoice_date' value to_char(rmh.issue_date, 'YYYY-MM-DD'),
                        'due_date' value to_char(rmh.first_due_date, 'YYYY-MM-DD'),--verificar data de pagamento
                        'amount' value --rmh.total_amount,
                    case
                        when length(replace(rmh.boleto_cod, ' ', '')) = 47 then
                                case
                                    when to_number(nls_num_char(substr(
                                        replace(rmh.boleto_cod, ' ', ''),
                                        38,
                                        8
                                    )
                                                                || '.' || substr(
                                        replace(rmh.boleto_cod, ' ', ''),
                                        46
                                    ))) > 0 then
                                        to_number(nls_num_char(substr(
                                            replace(rmh.boleto_cod, ' ', ''),
                                            38,
                                            8
                                        )
                                                               || '.' || substr(
                                            replace(rmh.boleto_cod, ' ', ''),
                                            46
                                        )))
                                    else
                                        rmh.total_amount
                                end
                        else
                            rmh.total_amount
                    end,
                        'barcode' value regexp_replace(rmh.boleto_cod, '[^[:digit:]]'),
                        'cnpj_paying' value '29980158000157',-- teste de erro de boletormh.receiver_document_number,
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
            )
        into l_body
        from
            rmais_efd_headers rmh
        where
            efd_header_id = p_efd_header_id;
                   
    --
        begin
            l_body := replace(
                asciistr(l_body),
                '\',
                '\u'
            );
            null;
        exception
            when others then
     --
                null;
     --
        end;

        l_response := get_response(l_url, l_body, 'POST');
    --ge
        if (
            l_response is not null
            and json_value(l_response, '$.id') is null
        )
        or l_response is null then
      --
            print('Falha ao enviar boleto - Contacte o administrador!' || l_response);
            print(apex_web_service.g_status_code);
            print(sqlerrm);
      --
            xxrmais_util_v2_pkg.create_event(p_efd_header_id, 'Boleto', 'Falha ao gerar boleto '
                                                                        || l_response
                                                                        || 'Error: '
                                                                        || sqlerrm, 'Sistema');
      --
            log_efd('Falha ao enviar boleto.', '', p_efd_header_id);
      --
      --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Falha ao enviar boleto.'||'<br>';
      --
        else
      --
            print('l_response: ' || l_response);
      --
      --Log_Efd('Boleto aguardando confirmação de integração!','', p_efd_header_id);
      --
            xxrmais_util_v2_pkg.create_event(p_efd_header_id, 'Boleto', 'Boleto aguardando confirmação de integração!', 'Sistema');
      --
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
                                                       json_value(l_response, '$.id'),
                                                       'N' );
        --
            exception
                when others then
        --
                    print('Erro ao gravar controle: ' || sqlerrm);
        --
            end;

        end if;
    --
        print(apex_web_service.g_status_code);
    exception
        when others then
    --
            log_efd('Falha geral ao enviar boleto. Erro: ' || sqlerrm, '', p_efd_header_id);
    --
    --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Falha geral ao enviar boleto. Erro: '||sqlerrm||'<br>';
    --
    end send_boleto;
  --
    procedure status_boleto (
        p_count number default 3
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
                l_resp := get_response(l_url, '', 'GET');
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
                        update rmais_boletos_log
                        set
                            count_process = count_process + 1,
                            log = 'Error Exception: ' || l_r,
                            last_update_date = sysdate,
                            last_user = '-1',
                            status = 'E'
                        where
                            id = reg.id;

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
    end;
  --
    procedure send_invoice_v2 (
        p_header_id      in number,
        p_flag_retention in varchar2 default 'Y',
        p_app_user       varchar2 default null
    ) is
    --
        l_transaction_id number;
    --
        l_return         clob;
        l_body           clob;
        l_body_send      clob;
    --
        l_cod_boleto     rmais_efd_headers.boleto_cod%type;
    --
        l_model          varchar2(100);
    --l_url  VARCHAR2(4000) := get_Parameter('SEND_INVOICE_AP_URL');
        l_status         rmais_efd_headers.document_status%type;
    begin
    --
        select
            document_status
        into l_status
        from
            rmais_efd_headers
        where
            efd_header_id = p_header_id;
    --
        if l_status in ( 'T', 'Y' ) then
            print('já integrado');
            return;
        end if;
    --
        generate_attachments(p_header_id);
     --
        l_body := get_invoice_v2(p_header_id);
     --
     
    --print('BODY BEFORE '||l_body);
    --
    --l_body := '{"BASE64":"'||replace(translate(xxrmais_util_pkg.base64encode(xxrmais_util_pkg.clob_to_blob(l_body)), chr(10) || chr(13) || chr(09), ' '),' ','')||'"}';
    --l_body := json_object('BASE64' VALUE regexp_replace(text2base64(l_body),'[^[:alnum:][:print:]]'));
    --
        l_body := xxrmais_util_pkg.base64encode(xxrmais_util_pkg.clob_to_blob(l_body));
    --
        rmais_process_pkg_bkp_to_worflow.insert_ws_info(
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
        print(l_body_send);
    --
        begin
      --
            select
                model,
                boleto_cod
            into
                l_model,
                l_cod_boleto
            from
                rmais_efd_headers
            where
                efd_header_id = p_header_id;
      --
        exception
            when others then
                print('Modelo não localizado: ' || sqlerrm);
        end;
    --
        if nvl(xxrmais_util_pkg.g_test, 'T') = 'T' then
      --
            declare
      --http://140.238.190.67:9000/api/payables/v2/createInvoiceService
      --l_url varchar2(400) := 'http://10.0.0.253:9000/api/payables/v2/createInvoiceService'||case when l_model IN ('00','55','57','67') then '/N' else '/S' end ;
                l_url      varchar2(400) := get_ws || '/api/payables/v2/createInvoiceService/N';--||case when l_model IN ('00','55','57','67') then '/N' else '/S' end ;
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
                l_check    boolean := false;
      --
            begin
        --
                print('URL: ' || l_url);
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
                            if l_response like '%"code":%'
                               or l_response like '%DocumentId%' then
                --
                                l_check := true;
                --
                                for r in (
                                    select
                                        json_value(l_response, '$.code')    as code,
                                        json_value(l_response, '$.retorno') as retorno
                                    from
                                        dual
                                ) loop
                    --Sem dados para cria\u00e7\u00e3o da Nota Fiscal para pagamento! 
                                    log_efd(
                                        nvl(r.retorno, 'Enviado para ERP (AP)'),
                                        null,
                                        p_header_id,
                                        case
                                            when r.code between '400' and 501 then
                                                    'Erro'
                                            else
                                                'Integrado'
                                        end
                                    );
                    --
                    --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Enviado para ERP (AP)'||'<br>';
                    --
                                    declare
                                        l_status rmais_efd_headers.document_status%type;
                                    begin
                      --
                                        l_status :=
                                            case
                                                when to_number(regexp_replace(r.code, '[^[:digit:]]')) not between 200 and 299 then
                                                    'E'
                                                when p_app_user is not null then
                                                    'Y'
                                                else
                                                    'T'
                                            end;
                      --
                                        update rmais_efd_headers
                                        set
                                            document_status = l_status,
                                            last_update_date = sysdate,
                                            last_updated_by = nvl(p_app_user, last_updated_by)
                                        where
                                            efd_header_id = p_header_id;
                      --
                      --
                                        commit;
                      --
                      /*Inclusão erickson send boleto 08/03/2023*/
                                        if
                                            l_model in ( '06', '21', '22', '28', '29' )
                                            and l_cod_boleto is not null
                                            and l_status in ( 'T', 'Y' )
                                        then
                                            send_boleto(p_header_id);
                                        end if;
                      --  
                      -- Retirado por Robson em 10/01/2023 if nvl(r.retorno,'Enviado para ERP (AP)') = 'Enviado para ERP (AP)' then 
                                        if
                                            nvl(r.retorno, 'Enviado para ERP (AP)') = 'Enviado para ERP (AP)'
                                            and p_flag_retention = 'Y'
                                            and l_status in ( 'T', 'Y' )
                                        then
                        --
                                            print('Enviando retenção');
                        --
                                            l_body := xxrmais_util_pkg.base64decode(replace(
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
                                            ));
                        --
                                            send_hold_invoice_ap(l_body, p_header_id);
                        --
                                        end if;

                                    end;

                                end loop;
                  --Transaction_id: 76457
                            elsif l_response like '%Sem dados para cria\u00e7\u00e3o da Nota Fiscal para pagamento! %'
                                  or l_response like '%<html %'
                            or l_response like '%Nota Fiscal%foi%bilizado para pagamento%'
                            or l_response like '%Nota Fiscal j\u00e1 criada no ERP!%' then
                  --
                                for r in (
                                    select
                                        json_value(l_response, '$.code')    as code,
                                        json_value(l_response, '$.retorno') as retorno
                                    from
                                        dual
                                ) loop
                    --Sem dados para cria\u00e7\u00e3o da Nota Fiscal para pagamento! 
                                    log_efd(
                                        nvl(r.retorno, 'Erro entre em contato com o administrador'),
                                        null,
                                        p_header_id,
                                        'ERRO'
                                    );
                    --
                    --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||nvl(r.retorno,' Erro entre em contato com o administrador.')||'<br>';
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
                                end loop;
                  --
                                return;
                --  
                            end if;
              --
                        end if;
            --
                    end loop;

                    utl_http.end_response(resp);
            --
                    if not l_check then
               --
                        log_efd('Erro ao enviar documento, contacte o adminitrador', null, p_header_id, 'Erro');
                --
                --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Erro ao enviar documento, contacte o adminitrador'||'<br>';
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

                exception
                    when utl_http.end_of_body then
                        utl_http.end_response(resp);
                    when others then
                        utl_http.end_response(resp);
                end;
          --
                xxrmais_util_v2_pkg.set_workflow(p_header_id,
                                                 g_log_workflow,
                                                 nvl(
                                 v('APP_USER'),
                                 '-1'
                             ));
          --
            exception
                when others then
          --
                    print('Erro ao chamar WS: ' || sqlerrm);
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
    end;
  --
    function get_registrationid (
        p_cnpj varchar2
    ) return varchar2 as
        l_url  varchar2(1000) := rmais_process_pkg_bkp_to_worflow.get_parameter('GET_TAX_REGISTRATION')
                                || '/';
        l_resp clob;
    begin
    --
        l_url := l_url || p_cnpj;
        print('URL get_registration: ' || l_url);
        l_resp := rmais_process_pkg_bkp_to_worflow.get_response(l_url);
        print('l_resp Reg_id:' || l_resp);
        return nvl(
            json_value(l_resp, '$.BU_ID'),
            json_value(l_resp, '$.RegistrationId')
        );
    --
    exception
        when others then
            return '';
    end get_registrationid;
  --
    procedure get_document_type (
        p_efd_header_id number,
        p_source_type   in out varchar2,
        p_det           in out varchar2
    ) as
        l_aux            number;
        l_det_corretagem varchar2(30) := 'corretagem';
    begin
    --
        select
            1
        into l_aux
        from
            rmais_efd_headers
        where
                efd_header_id = p_efd_header_id
            and upper(additional_information) like upper('%'
                                                         || l_det_corretagem || '%')
        union
        select
            1
        from
            rmais_efd_lines
        where
                efd_header_id = p_efd_header_id
            and upper(item_description) like upper('%'
                                                   || l_det_corretagem || '%');
    --
        p_det := upper(l_det_corretagem);
        p_source_type := 'NA';
    --
    exception
        when others then
    --
            p_source_type := 'PO';
    --
    end get_document_type;
  --
    procedure main (
        p_header_id in number default null,
        p_acces_key in varchar2 default null,
        p_flag_auto in varchar2 default 'N' --processo automatico ou debug Y  
        ,
        p_send_erp  in varchar2 default null
    ) as
    --
        type t$issuer is
            table of rmais_issuer_info%rowtype index by varchar2(100);
    --
        t_issuer          t$issuer;
    --
        type t$receiv is
            table of rmais_receiver_info%rowtype index by varchar2(100);
    --
        t_receiv          t$receiv;
    --
        l_body_po         varchar2(500);
    --
        ix_l              number;
    --
        r_efd             r$source;
    --
        l_transaction_id  number;
    --
        l_determinant     varchar2(30) := null;
    --
        l_defined_role    varchar2(400);
        l_source          varchar2(400);
        l_item            varchar2(400);
        l_role            varchar2(400);
    --
        l_flag_retention  varchar2(1);
        l_flag_nf_op      varchar2(1);
    -- 
        l_flag_log        number(1);
        teste_vx          number := 0;
        teste_zz          varchar(50);-- Robson 22/03/2023
        l_new_doc_number  rmais_efd_headers.document_number%type;
    --
        l_body_simp       clob; -- Robson 31/05/2023
        l_resp_simp       varchar2(100); -- Robson 31/05/2023
    --
        l_header_workflow number;
    begin
    --
    /*Workflow erickson 04/07/2023*/
        rmais_process_pkg_bkp_to_worflow.g_log_workflow := null;
    --
        g_shipments.delete;
    --
        g_po_find := false;
    --
        l_defined_role := null;
        l_source := null;
        l_item := null;
        l_role := null;
    --
        execute immediate 'truncate table rmais_log';
    --
        execute immediate 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''.,''';
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
       --AND  TRUNC(creation_date) >= TRUNC(SYSDATE-35)
       --AND  receiver_document_number = '45246402000109'
                and ( ( document_status is null
                        and nvl(p_header_id, p_acces_key) is null )
                      or nvl(p_header_id, p_acces_key) is not null )
                and ( ( efd_header_id = p_header_id
                        and p_header_id is not null )
                      or ( p_header_id is null ) )
                and ( ( access_key_number = p_acces_key
                        and p_acces_key is not null )
                      or ( p_acces_key is null ) )
                and nvl(document_status, 'A') not in ( 'T', 'AU', 'AP', 'AI' )
        ) loop
      -- Robson 31/05/2023 Start
            if length(r.issuer_document_number) = 14 then
                l_body_simp := rmais_process_pkg_bkp_to_worflow.get_response2('http://152.67.41.84:9000/api/consultas/v1/simplesNacional/' || r.issuer_document_number
                );
                if json_value(l_body_simp, '$.resultado') = 'true' then
                    update rmais_efd_headers a
                    set
                        a.simple_national_indicator =
                            case
                                when nvl(
                                    json_value(l_body_simp, '$.opcao_pelo_simples'),
                                    'false'
                                ) = 'true' then
                                    'S'
                            end
                    where
                        a.efd_header_id = r.efd_header_id;

                end if;

            end if;
      -- Robson 31/05/2023 End
      
      -- Robson 22/03/2023 Start
            select
                max(to_char(a.issue_date, 'YYYY') || to_char(to_number(substr(a.document_number, 5)))) new_document_number
            into l_new_doc_number
            from
                rmais_efd_headers a
            where
                    a.efd_header_id = r.efd_header_id
                and to_char(a.issue_date, 'YYYY') = substr(a.document_number, 1, 4);

            if l_new_doc_number is not null then
                select
                    count(*)
                into l_flag_log
                from
                    rmais_efd_lin_valid
                where
                        efd_header_id = r.efd_header_id
                    and instr(message_text, 'Número do documento alterado pelo sistema') > 0;

                if l_flag_log = 0 then
                    update rmais_efd_headers a
                    set
                        a.original_document_number = a.document_number,
                        a.document_number = l_new_doc_number
                    where
                        a.efd_header_id = r.efd_header_id;

                    log_efd('Número do documento alterado pelo sistema. (Número Original: '
                            || r.document_number
                            || ')', null, r.efd_header_id, 'Evento');
                --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Número do documento alterado pelo sistema. (Número Original: '||r.document_number||')'||'<br>';
                end if;

            end if;
      -- Robson 22/03/2023 end
            l_defined_role := null;
            l_source := null;
            l_item := null;
            l_role := null;
      --
            begin
      --
                r_efd.rhea := r;
                if
                    l_new_doc_number is not null
                    and l_flag_log = 0
                then
                    r_efd.rhea.document_number := l_new_doc_number;
                end if;
      --
                log_del(r.efd_header_id);
      --
                if
                    p_flag_auto = 'Y'
                    and r.define_det_entry_type is null
                then --checar para verificar se nota está no setup para derivação
            --
                    get_definition_type(
                        p_efd_header_id    => r.efd_header_id,
                                  --p_model => '98',
                        p_source_type      => l_source,
                        p_item             => l_item,
                        p_role_application => l_role,
                        p_defined_role     => l_defined_role
                    );
            --
                    print('');
                    print('***Setup de definição: '
                          || l_defined_role || ' ***');
                    print('Regra: ' || l_defined_role);
                    print('Source: ' || l_source);
                    print('Item: ' || l_item);
                    print('type: ' || l_role);
            --
                    if l_defined_role = 'NA' then
              --
                        r_efd.rhea.source_type := l_source;
              --
                        update rmais_efd_lines
                        set
                            source_document_type = 'NA',
                            item_code_efd = l_item,
                            status = 'AUTO'
                        where
                            efd_header_id = r.efd_header_id;

                        commit;
              --
                    elsif l_defined_role = 'PO' then
               --
                        null;
               --
                    elsif l_defined_role = 'MT' then
               --
                        if l_role = 'item_default' then 
                 --
                            g_po_find := false;
                 --
                 --
                            update rmais_efd_lines
                            set
                                source_document_type = 'NA',
                                item_code_efd = l_item
                            where
                                efd_header_id = r.efd_header_id;
                  --
                            commit;
                  --
                 --
                        else
                  --
                            r_efd.rhea.source_type := l_source;
                  --
                            update rmais_efd_lines
                            set
                                source_document_type = l_source,
                                item_code_efd = l_item
                            where
                                efd_header_id = r.efd_header_id;

                            commit;
                  --
                        end if;  
               -- 
                    end if;
            -- 
                elsif
                    nvl(p_flag_auto, 'N') = 'N'
                    and r.define_det_entry_type is null
                then
             --
                    print('Definicao nula, buscando definição');
             --
                    begin
               --
                        select
                            a.type
                        into l_role
                        from
                            rmais_efd_lines        rml,
                            rmais_define_det_entry a
                        where
                                1 = 1-- a.efd_header_id = rml.efd_header_id
                            and rml.item_code_efd is not null
                            and rml.line_number = 1
                            and rml.efd_header_id = r.efd_header_id
                            and a.model = r.model
                            and ( a.value1 = rml.item_code_efd
                                  or nvl(a.item, 'X') = rml.item_code_efd )
                            and rownum = 1;
               --
                        print('Definição: ' || l_role);
               --
                    exception
                        when others then
              --
                            print('Definição não encontrada!');
              --
                    end;

                end if;

            end;

            if nvl(r_efd.rhea.source_type,
                   'PO') <> 'NA' then
        --
                insert_ws_info(l_transaction_id);
        --
                l_transaction_id := rmais_process_pkg_bkp_to_worflow.set_transaction_po_arrays(r.issuer_document_number,
                                                                                               get_bu_cnpj(r.receiver_document_number
                                                                                               ),
                                                                                               l_transaction_id);
        --
        --
            end if;
      --l_transaction_id := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.set_transaction_po_arrays(r.issuer_document_number,r.receiver_document_number,l_transaction_id);
      --
      /*l_body_po := json_object('cnpj_tomador'          VALUE r.receiver_document_number,
                               'cnpj_fornecedor'       VALUE r.issuer_document_number,
                               'data_promessa_inicial' VALUE to_char(add_months(SYSDATE,-6),'dd/mm/rrrr'),
                               'data_promessa_final'   VALUE to_char(add_months(SYSDATE, 6),'dd/mm/rrrr'));*/
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
            if not t_issuer.exists(r.issuer_document_number) then
        --
                t_issuer(r.issuer_document_number).receiver := r.receiver_document_number;
                t_issuer(r.issuer_document_number).info := get_taxpayer(r.issuer_document_number, 'ISSUER');
        --victor
                r_efd.rhea.issuer_info := t_issuer(r.issuer_document_number).info;
                print('issuer_info :' || t_issuer(r.issuer_document_number).info);
        
        --
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
        --t_issuer(r.issuer_document_number).docs := Get_Po_list (l_body_po);
                t_issuer(r.issuer_document_number).cnpj := r.issuer_document_number;
        --
                ins_issuer(t_issuer(r.issuer_document_number));
        --
            end if;
      --
            if r_efd.rhea.issuer_info is null then
        --
                begin
          --
                    for r1 in (
                        select
                            a.info.data.party_id taxpayer_id,
                            a.info
                        from
                            rmais_issuer_info a
                        where
                            cnpj = r.issuer_document_number
                    ) loop
            --
                        print('Carregando Issuer ' || r1.taxpayer_id);
            --
                        r_efd.rhea.issuer_info := r1.info;
                        r_efd.rhea.issuer_taxpayer_id := r1.taxpayer_id;
            --
                        print('r1.info: ' || r1.info);
                        print('r_Efd.rHea.issuer_info: ' || r_efd.rhea.issuer_info);
            --
                        r_efd.rhea.vendor_site_code := json_value(r1.info, '$.DATA.ADDRESS.VENDOR_SITE_CODE');
            --
                    end loop;
          --
                exception
                    when others then
                        print('Falha ao carregar informações do Fornecedor '
                              || r.issuer_document_number
                              || ' ' || sqlerrm);
                end;
        --
            end if;
      --

            if not t_receiv.exists(r.receiver_document_number) then
        --
                t_receiv(r.receiver_document_number).type := 'RECEIVER';
                t_receiv(r.receiver_document_number).info := get_taxpayer(r.receiver_document_number, 'RECEIVER');

                t_receiv(r.receiver_document_number).cnpj := r.receiver_document_number;
        --
                ins_receiv(t_receiv(r.receiver_document_number));
        --
            end if;
     
    --IF r.receiver_taxpayer_id IS NULL THEN
        --
            begin
          --
                for r1 in (
                    select
                        a.info.data.establishment_id taxpayer_id,
                        a.info
                    from
                        rmais_receiver_info a
                    where
                        cnpj = r.receiver_document_number
                ) loop
            --
                    print('Carregando Receiver ' || r1.taxpayer_id);
            --
                    if r1.info not like ( '%[%' ) then --Victor 23/03/2023
                        r_efd.rhea.receiver_info := r1.info;
                        print('1 - r_Efd.rHea.receiver_info: ' || r_efd.rhea.receiver_info);
            --
                    else--Victor 23/03/2023
              --
                        select
                            base
                        into r_efd.rhea.receiver_info
                        from
                            json_table ( r1.info, '$'
                                columns (
                                    po_seq for ordinality,
                                    nested path '$.DATA[*]'
                                        columns (
                                            base clob format json with wrapper path '$'
                                        )
                                )
                            )
                        where
                            rownum = 1;
              --   
                        print('2 - r_Efd.rHea.receiver_info: ' || r_efd.rhea.receiver_info);   
              --
                    end if;--Victor 23/03/2023 FIM
            --
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
        --
    --END IF;
     --
      
      --
            if nvl(r_efd.rhea.document_status,
                   'N') in ( 'N', 'I', 'E' ) then
        --
                r_efd.rhea.document_status := 'V';
        --
            end if;
      --
      --Print('Fornec Info: '||r_Efd.rHea.issuer_info);
      --Print('Receiv Info: '||r_Efd.rHea.receiver_info);
      --
            ix_l := 0;
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
                set_line_info(r_efd, ix_l);
        --
                print('role: ' || l_role);
        --
        --Inclusão de combinação contábil
                r_efd.rlin(ix_l).rlin.account_cc := xxrmais_util_v2_pkg.get_filial(r_efd.rhea.efd_header_id,
                                                                                   r_efd.rhea.receiver_document_number,
                                                                                   l_role);
        --
                print('Combination: ' || r_efd.rlin(ix_l).rlin.account_cc);
        -- Identificando o tipo de linha
        --

                if nvl(r_efd.rlin(ix_l).rlin.status,
                       '$') = '$' then--NOT IN ('MANUAL','VALID') THEN
          --
          --r_Efd.rLin(ix_l).rLin.source_document_type := get_cfop_lin_type(r_Efd.rLin(ix_l).rLin.cfop_from); --comentar
          --
                    if r_efd.rlin(ix_l).rlin.item_code_efd is null then
            --
                        get_item_erp(r_efd.rhea.issuer_document_number,
                                     r_efd.rhea.receiver_document_number,
                                     r_efd.rlin(ix_l).rlin.item_description,
                                     r_efd.rlin(ix_l).rlin.item_code_efd,
                                     r_efd.rlin(ix_l).rlin.item_descr_efd,
                                     r_efd.rlin(ix_l).rlin.uom_to,
                                     r_efd.rlin(ix_l).rlin.uom_to_desc,
                                     r_efd.rlin(ix_l).rlin.fiscal_classification_to,
                                     r_efd.rlin(ix_l).rlin.catalog_code_ncm,
                                     r_efd.rlin(ix_l).rlin.item_type);
            --r_Efd.rLin(ix_l).rLin.account_cc := XXRMAIS_UTIL_V2_PKG.get_filial(r_Efd.rHea.efd_header_id,r_Efd.rHea.receiver_document_number);
            --
                    end if;
          --
                end if;
      --BEGIN
                if nvl(r_efd.rlin(ix_l).rlin.source_document_type,
                       'PO') = 'PO' then
          --
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
                    get_po_line(r_efd, ix_l, l_transaction_id);
          --
                else
          --
                    print('*** Linha identificada como S/ Pedido ***');
          --
          /*Fatura de Aluguel*/
                    if
                        r_efd.rhea.model = '97'
                        and length(r_efd.rhea.issuer_document_number) = 11
                        and r_efd.rlin(ix_l).rlin.user_defined is null
                    then
                        print('alterando NOP0024');
                        r_efd.rlin(ix_l).rlin.user_defined := 'NOP0024';
                    end if;
          --
                    r_efd.rlin(ix_l).rlin.status := '';
          --
                    r_efd.rhea.source_type := 'NA';
          --
                    print('r_Efd.rLin(ix_l).rLin.item_code_efd: '
                          || r_efd.rlin(ix_l).rlin.item_code_efd
                          || ' r_Efd.rLin(ix_l).rLin.item_descr_efd: ' || r_efd.rlin(ix_l).rlin.item_descr_efd);
          --          
                    if
                        r_efd.rlin(ix_l).rlin.item_code_efd is not null
                        and r_efd.rlin(ix_l).rlin.item_descr_efd is null
                    then
            --
                        print('Buscando informações do item!');
            --pegar informações do item O10004
            --
                        declare
                            l_id              number;
                            l_transaction_id2 number;
                            l_clob            clob;
                        begin
                  
                  --
                            l_id := rmais_ws_info_s.nextval;
                  --
                            rmais_process_pkg_bkp_to_worflow.insert_ws_info(l_id, 'GET_ITEM');
                  --
                            l_transaction_id2 := rmais_process_pkg_bkp_to_worflow.get_itens(l_id,
                                                                                            r_efd.rlin(ix_l).rlin.item_code_efd,
                                                                                            '');
                  --
                            print('Transaction_id Item: ' || l_transaction_id2);
                  --
                            if l_transaction_id2 is not null then 
                    --

                                select
                                    nvl(item_number,
                                        r_efd.rlin(ix_l).rlin.item_code_efd),
                                    primary_uom_code unit_of_measure,
                                    description,
                                    catalog_code,
                                    ncm               
                                --,PROD_FISCAL_CLASS_TYPE 
                                    ,
                                    inventory_item_flag,
                                    unit_of_measure  uom_desc
                                into
                                    r_efd.rlin(ix_l).rlin.item_code_efd,
                                    r_efd.rlin(ix_l).rlin.uom_to,
                                    r_efd.rlin(ix_l).rlin.item_descr_efd,
                                    r_efd.rlin(ix_l).rlin.catalog_code_ncm,
                                    r_efd.rlin(ix_l).rlin.fiscal_classification_to,
                                    r_efd.rlin(ix_l).rlin.item_type,
                                    r_efd.rlin(ix_l).rlin.uom_to_desc
                                from
                                    rmais_ws_info p,
                                    json_table ( replace(
                                            replace(
                                                xxrmais_util_pkg.base64decode(p.clob_info),
                                                '"DATA":{"',
                                                '"DATA":[{"'
                                            ),
                                            '}}}',
                                            '}}]}'
                                        ), '$'
                                            columns (
                                                nested path '$.DATA[*]'
                                                    columns (
                                                        organization_name varchar2 ( 400 ) path '$.ORGANIZATION_NAME',
                                                        item_number varchar2 ( 400 ) path '$.ITEM_NUMBER',
                                                        unit_of_measure varchar2 ( 400 ) path '$.UNIT_OF_MEASURE',
                                                        primary_uom_code varchar2 ( 400 ) path '$.PRIMARY_UOM_CODE',
                                                        description varchar2 ( 1000 ) path '$.DESCRIPTION',
                                                        catalog_code varchar2 ( 400 ) path '$.CATALOG_CODE',
                                                        ncm varchar2 ( 400 ) path '$.NCM',
                                                        prod_fiscal_class_type varchar2 ( 400 ) path '$.PROD_FISCAL_CLASS_TYPE',
                                                        inventory_item_flag varchar2 ( 1 ) path '$.INVENTORY_ITEM_FLAG'
                                                    )
                                            )
                                        )
                                    d
                                where
                                    p.transaction_id = l_transaction_id2
                                      --ORDER BY ITEM_NUMBER ASC
                                    ;

                                print('Busca de Item finalizada transaction_id: ' || l_transaction_id2);
                     --      
                            end if;
                  --
                        exception
                            when others then
                  --
                                print('Não foi possível localicar item automáticamente: ' || sqlerrm);
                  --
                        end;
            --
                    end if;
          --
         --nao funciona aqui
          --
         /* BEGIN
            --
            IF r_Efd.rLin(ix_l).rLin.item_code_efd IS NULL AND r_Efd.rLin(ix_l).rLin.item_code IS NOT NULL THEN
              --
              r_Efd.rLin(ix_l).rLin.item_code_efd := get_item_na(r_Efd.rHea.issuer_document_number , r_Efd.rLin(ix_l).rLin.item_code);
              --
            END IF;
            --
          EXCEPTION WHEN OTHERS THEN
            --
            Print('Falha ao buscar De/Para de Item - Erro:'||SQLERRM);
            --
          END;*/
          --
                    print('DOCUMENT STATUS DEBUG r_Efd.rHea.document_status:' || r_efd.rhea.document_status);
          --
                    if r_efd.rlin(ix_l).rlin.item_code_efd is null then
            --
                        log_efd('Item não informado. Favor informar o item e revalidar documento.',
                                r_efd.rlin(ix_l).rlin.efd_line_id,
                                r_efd.rhea.efd_header_id);
            --
            --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Item não informado. Favor informar o item e revalidar documento.'||'<br>';
            --            
                        r_efd.rlin(ix_l).rlin.status := 'INVALID';
            --
                    end if;
          --
          /*if r_Efd.rHea.payment_term_id is null then
            --
            r_Efd.rLin(ix_l).rLin.status := 'INVALID';
            --
            Log_Efd('Condição de pagamento não informada','', r_Efd.rHea.efd_header_id,'Erro');
            --
          end if;*/
          --
                end if;
        --
                print('r_Efd.rLin(ix_l).rLin.status              : ' || r_efd.rlin(ix_l).rlin.status);
                print('r_Efd.rLin(ix_l).rLin.source_doc_line_id  : ' || r_efd.rlin(ix_l).rlin.source_doc_line_id);
                print('r_Efd.rLin(ix_l).rLin.source_document_type: ' || r_efd.rlin(ix_l).rlin.source_document_type);
        --
                if nvl(r_efd.rlin(ix_l).rlin.status,
                       '$') = 'INVALID'
                or (
                    r_efd.rlin(ix_l).rlin.source_doc_line_id is null
                    and nvl(r_efd.rlin(ix_l).rlin.source_document_type,
                            'PO') = 'PO'
                ) then
          --
                    r_efd.rhea.document_status := 'I';
          --
                end if;
        --
                if (
                    r_efd.rlin(ix_l).rlin.cfop_to is not null
                    and nvl(r_efd.rlin(ix_l).rlin.status,
                            'MANUAL') in ( 'INVALID', 'MANUAL' )
                )
                or nvl(r_efd.rhea.model,
                       '00') in ( '99', '00' ) then
           --
                    print('Buscando Informações de Impostos...');
           --
           --Get_Taxes(r_Efd, ix_l
           --
                    if
                        ( nvl(p_flag_auto, 'N') = 'Y'
                        or nvl(p_send_erp, 'N') = 'Y' )
                        and r_efd.rhea.model not in ( '55', '57', '67' )
                    then
             --
                        find_imp_det(r_efd.rhea,
                                     r_efd.rlin(ix_l).rlin);
             --
                    end if;
           --  
                end if;
        --
                if
                    r_efd.rlin(ix_l).rlin.cfop_to is null
                    and nvl(r_efd.rhea.model,
                            '00') in ( '55', '57' )
                then --AND r_Efd.rLin(ix_l).rLin.destination_type = 'EXPENSE' THEN
          --
                    print('r_Efd.rLin(ix_l).rLin.cfop_from: ' || r_efd.rlin(ix_l).rlin.cfop_from);
                    print('r_Efd.rLin(ix_l).rLin.cfop_to: ' || r_efd.rlin(ix_l).rlin.cfop_to);
                    print('Novo cfop_to: '
                          ||
                        case
                            when substr(r_efd.rlin(ix_l).rlin.cfop_from,
                                        1,
                                        1) in(1, 5) then
                                1
                            else
                                2
                        end
                          || substr(r_efd.rlin(ix_l).rlin.cfop_from,
                                    2));

                    r_efd.rlin(ix_l).rlin.cfop_to :=
                        case
                            when substr(r_efd.rlin(ix_l).rlin.cfop_from,
                                        1,
                                        1) in ( 1, 5 ) then
                                1
                            else
                                2
                        end
                        || substr(r_efd.rlin(ix_l).rlin.cfop_from,
                                  2);
          /*BEGIN
            --
            SELECT case when r_Efd.rHea.ISSUER_ADDRESS_STATE <> r_Efd.rHea.RECEIVER_ADDRESS_STATE then '2' else '1' end|| cfop.cfop_in , cfop.utilization_id
             INTO r_Efd.rLin(ix_l).rLin.cfop_to,
                  r_Efd.rLin(ix_l).rLin.utilization_id
             FROM RMAIS_CFOP_OUT_IN cfop,
                  rmais_utilization_cfop util
              WHERE cfop.utilization_id = util.id
                AND cfop.cfop_out = SUBSTR(r_Efd.rLin(ix_l).rLin.cfop_from,2,3);
             --
          EXCEPTION WHEN no_data_found THEN
            --
            r_Efd.rHea.document_status := 'I';
            --
            Log_Efd('Setup de De/Para de CFOP não localizado.', r_Efd.rLin(ix_l).rLin.efd_line_id, r_Efd.rHea.efd_header_id);
            --
            WHEN too_many_rows THEN
            --
            r_Efd.rHea.document_status := 'I';
            --
            Log_Efd('Mais de uma utilização para o CFOP de saída, faça o preenchimento manual.', r_Efd.rLin(ix_l).rLin.efd_line_id, r_Efd.rHea.efd_header_id);
            --  
          END;*/
          --
                end if;
          --
      --END LOOP;
        --
                begin
          --
                    r_efd.rlin(ix_l).rlin.last_update_date := sysdate;
          --
                    r_efd.rlin(ix_l).rlin.status := nvl(r_efd.rlin(ix_l).rlin.status,
                                                        'VALID');
          --
                    print('Combination2: ' || r_efd.rlin(ix_l).rlin.account_cc);
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
                        log_efd('Falha ao atualizar linha...' || sqlerrm, rl.efd_line_id, rl.efd_header_id);
            --
            --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Falha ao atualizar linha...'||SQLERRM||'<br>';
            --
                end;
        --
                print('Status Linha: ' || r_efd.rlin(ix_l).rlin.status);
        --
                if nvl(r_efd.rlin(ix_l).rlin.status,
                       'VALID') <> 'INVALID' then
             --
                    print('Buscando Informações de Impostos...');
             --
                    get_taxes_v2(r_efd.rlin(ix_l).rlin.efd_line_id);
             --
             /*DECLARE
             l_r VARCHAR2(1);
             BEGIN
               --
               l_r := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.CHECK_TAX_LINE(r_Efd.rLin(ix_l).rLin.efd_line_id);
               --
               IF l_r = 'F' THEN
                 --
                Log_Efd('Identificado divergência entre cálculo de imposto, verifique o detalhe da linha.', r_Efd.rLin(ix_l).rLin.efd_line_id, r_Efd.rLin(ix_l).rLin.efd_header_Id);
                --
               END IF;
               --
             EXCEPTION WHEN OTHERS THEN
               NULL;
             END;*/
                end if;

            end loop;

            print('Final do loop');
      --
            r_efd.rhea.org_id := get_registrationid(r_efd.rhea.receiver_document_number);
      -- verificar se a NF vai para o ap ou FDC e buscar RegistrationId
            print('r_Efd.rHea.org_id: ' || r_efd.rhea.org_id);
      --
     /* IF XXRMAIS_UTIL_V2_PKG.get_destination(r_Efd.rHea.efd_header_id) ='EXPENSE' THEN
        --
        r_Efd.rHea.org_id := get_RegistrationId(r_Efd.rHea.receiver_document_number);
        --
        IF r_Efd.rHea.org_id IS NULL THEN
          --
          Log_Efd('Não foi possível buscar RegistrationId.',NULL, r_Efd.rHea.efd_header_id);
          --
          r_Efd.rHea.document_status := 'I';
          --
        END IF;
        --
      END IF;*/
      --
            print('Check issuer');
      --
            if r_efd.rhea.issuer_info not like '%PARTY_NAME%' then
          --
                r_efd.rhea.document_status := 'I';
          --
          /*workflow*/
          --
                log_efd('Fornecedor não localizado no ERP, verificar cadastro Oracle.',
                        '',
                        r_efd.rhea.efd_header_id,
                        'ERRO');
          --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Fornecedor não localizado no ERP, verificar cadastro Oracle.'||'<br>';
                print('passou aqui');
          --
            else
          --
          --Verificar duplicidade
          --  declare
                declare
                    l_aux varchar2(1000);
                begin
                    select distinct
                        party_name
                    into l_aux
                    from
                        json_table ( replace(
                            replace(r_efd.rhea.issuer_info,
                                    '"DATA":{',
                                    '"DATA": [{'),
                            '}}}',
                            '}}]}'
                        ), '$'
                            columns (
                                nested path '$.DATA[*]'
                                    columns (
                                        p_tax_payer_number varchar2 ( 4000 ) path '$.P_TAX_PAYER_NUMBER',
                                        party_name varchar2 ( 4000 ) path '$.PARTY_NAME',
                                        party_name2 varchar2 ( 4000 ) path '$.PARTY_NAME',
                                        nested path '$.ADDRESS[*]'
                                            columns (
                                                address1 varchar2 ( 4000 ) path '$.ADDRESS1',
                                                address2 varchar2 ( 4000 ) path '$.ADDRESS2',
                                                address3 varchar2 ( 4000 ) path '$.ADDRESS3',
                                                address4 varchar2 ( 4000 ) path '$.ADDRESS4',
                                                city varchar2 ( 4000 ) path '$.CITY',
                                                postal_code varchar2 ( 4000 ) path '$.POSTAL_CODE',
                                                state varchar2 ( 4000 ) path '$.STATE',
                                                vendor_site_code varchar2 ( 4000 ) path '$.VENDOR_SITE_CODE'
                                            )
                                    )
                            )
                        );
            	--	where vendor_site_code = :P11_ISSUER_DOCUMENT_NUMBER
                 --   and rownum = 1;
                exception
                    when too_many_rows then
              --
              --Log_Efd('Cadastro de fornecedor em duplicidade no ERP, verificar cadastro Oracle.','', r_Efd.rHea.efd_header_id,'ERRO');
              --
                        declare
                --
                            l_aux varchar2(1000);
                        begin
                  --
                            select distinct
                                party_name
                            into l_aux
                            from
                                (
                                    select distinct
                                        party_name,
                                        party_id -- into l_aux
                                    from
                                        json_table ( replace(
                                            replace(r_efd.rhea.issuer_info,
                                                    '"DATA":{',
                                                    '"DATA": [{'),
                                            '}}}',
                                            '}}]}'
                                        ), '$'
                                            columns (
                                                nested path '$.DATA[*]'
                                                    columns (
                                                        p_tax_payer_number varchar2 ( 4000 ) path '$.P_TAX_PAYER_NUMBER',
                                                        party_name varchar2 ( 4000 ) path '$.PARTY_NAME',
                                                        party_name2 varchar2 ( 4000 ) path '$.PARTY_NAME',
                                                        party_id varchar2 ( 4000 ) path '$.PARTY_ID',
                                                        nested path '$.ADDRESS[*]'
                                                            columns (
                                                                address1 varchar2 ( 4000 ) path '$.ADDRESS1',
                                                                address2 varchar2 ( 4000 ) path '$.ADDRESS2',
                                                                address3 varchar2 ( 4000 ) path '$.ADDRESS3',
                                                                address4 varchar2 ( 4000 ) path '$.ADDRESS4',
                                                                city varchar2 ( 4000 ) path '$.CITY',
                                                                postal_code varchar2 ( 4000 ) path '$.POSTAL_CODE',
                                                                state varchar2 ( 4000 ) path '$.STATE',
                                                                vendor_site_code varchar2 ( 4000 ) path '$.VENDOR_SITE_CODE'
                                                            )
                                                    )
                                            )
                                        )
                                    order by
                                        party_id desc
                                )
                            where
                                rownum = 1;

                        exception
                            when others then
                --
                                r_efd.rhea.document_status := 'I';
                --
                /*workflow*/
                                log_efd('Não foi possível buscar cadastro do fornecedor.',
                                        '',
                                        r_efd.rhea.efd_header_id,
                                        'ERRO');
                --
                --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Não foi possível buscar cadastro do fornecedor.'||'<br>';
                --
                        end;
              --
                end;
            end if;

            print('Entrando no update header');
            begin
        --
                print('Atualizando Header OK');
        --
                begin
                    print('Debug1 :' || r.efd_header_id);
                    print('Update header...'
                          || r_efd.rhea.document_status
                          || 'ID:'
                          || r.efd_header_id
                          || ' ' || r_efd.rhea.efd_header_id);

                exception
                    when others then
          --
                        print('Erros de variáveis ' || sqlerrm);
          --
                end;
        --
                r_efd.rhea.last_update_date := sysdate;
        --
                begin
        --
                    update rmais_efd_headers
                    set
                        document_status = r_efd.rhea.document_status,
                        issuer_info = r_efd.rhea.issuer_info,
                        issuer_taxpayer_id = r_efd.rhea.issuer_taxpayer_id,
                        vendor_site_code =
                            case
                                when r_efd.rhea.issuer_info like '%PARTY_NAME%' then
                                    r_efd.rhea.vendor_site_code
                                else
                                    vendor_site_code
                            end,
                        receiver_info = r_efd.rhea.receiver_info,
                        receiver_taxpayer_id = r_efd.rhea.receiver_taxpayer_id,
                        currency_code = r_efd.rhea.currency_code,
                        source_doc_info = r_efd.rhea.source_doc_info,
                        term_info = r_efd.rhea.term_info,
                        document_type = r_efd.rhea.source_type,
                        withholding = r_efd.rhea.withholding,
                        party_name = r_efd.rhea.party_name,
                        define_det_entry_type = nvl(define_det_entry_type, l_role),
                        org_id = r_efd.rhea.org_id
                    where
                        efd_header_id = r.efd_header_id;
        --
                    commit;
        --
                end;

                print('Update After header...' || r_efd.rhea.document_status);
        --
            exception
                when others then
                    begin
          --
                        print('Error: ' || sqlerrm);
          --
                        if 1 = 1 then--r_Efd.rHea.SOURCE_DOCUMENT_TYPE = 'NA' then --paliativo para erro lob NA
          --
                            begin   
              --
                                print('N ' || substr(r_efd.rhea.issuer_info,
                                                     1,
                                                     2));
              --
                            exception
                                when others then
             --
                                    null;
             --
           
           --   
           --

            --
                                    t_issuer(r_efd.rhea.issuer_document_number).receiver := r_efd.rhea.receiver_document_number;
                                    t_issuer(r_efd.rhea.issuer_document_number).info := get_taxpayer(r_efd.rhea.issuer_document_number
                                    ,
                                                                                                     'ISSUER');--p_cnpj IN VARCHAR2, p_type
            --victor
                                    if rmais_global_pkg.g_enable_log = 'Y' then
              --dbms_output.put_line(substr((t_issuer(r.issuer_document_number).info),1,3600));
                                        null;
                                    end if;
            --
                                    begin
                                        if l_transaction_id is not null then
                  --
                                            select
                                                xxrmais_util_pkg.base64decode(clob_info) clob_info
                                            into t_issuer(r_efd.rhea.issuer_document_number).docs
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
            --t_issuer(r.issuer_document_number).docs := Get_Po_list (l_body_po);
                                    t_issuer(r_efd.rhea.issuer_document_number).cnpj := r_efd.rhea.issuer_document_number;
            --
                                    ins_issuer(t_issuer(r_efd.rhea.issuer_document_number));
            --
            --
                                    begin
                                        for r1 in (
                                            select
                                                a.info.data.party_id taxpayer_id,
                                                a.info
                                            from
                                                rmais_issuer_info a
                                            where
                                                cnpj = r_efd.rhea.issuer_document_number
                                        ) loop
                --
                                            print('Carregando Issuer ' || r1.taxpayer_id);
                --
                                            r_efd.rhea.issuer_info := r1.info;
                                            r_efd.rhea.issuer_taxpayer_id := r1.taxpayer_id;
                --
                --'print('r1.info: '||r1.info);
                --
                                            r_efd.rhea.vendor_site_code := json_value(r1.info, '$.DATA.ADDRESS.VENDOR_SITE_CODE');
                --
                                            print('Vendor_site_code: ' || r_efd.rhea.vendor_site_code);
    			--
                                        end loop;
              --
                                    exception
                                        when others then
                                            begin
        		     --
                                                select
                                                    a.info,
                                                    vendor_site_code
                                                into
                                                    r_efd.rhea.issuer_info,
                                                    r_efd.rhea.issuer_taxpayer_id
                                                from
                                                        json_table ( ( t_issuer(r_efd.rhea.issuer_document_number).info ), '$.DATA[*]'
                                                            columns (
                                  --         NESTED         PATH '$.DATA' COLUMNS(
                                                                info clob format json with wrapper path '$',
                                                                party_name varchar2 ( 3000 ) path '$.PARTY_NAME',
                                                                nested path '$.ADDRESS[*]'
                                                                    columns (
                                                                        vendor_site_code varchar2 ( 3000 ) path '$.VENDOR_SITE_CODE'
                                                                    )
                                                            )
                                                        )
                                                    a
                                                where
                                                        vendor_site_code = r_efd.rhea.issuer_document_number
                                                    and rownum = 1;
        			 --
                                                print('Vendo_site_code armazenado na exceção');
        			 --
                                            exception
                                                when others then
        		    --
                                                    print('Falha ao carregar informações do Fornecedor '
                                                          || r_efd.rhea.issuer_document_number
                                                          || ' ' || sqlerrm);
        			--
                                            end;
                                    end;

                            end;

                            print('TEST: ' || substr(r_efd.rhea.issuer_info,
                                                     1,
                                                     2));

                            begin
                                print('TEST Rec: ' || substr(r_efd.rhea.receiver_info,
                                                             1,
                                                             2));
                            exception
                                when others then
                --
                                    t_receiv(r_efd.rhea.receiver_document_number).type := 'RECEIVER';
                                    t_receiv(r_efd.rhea.receiver_document_number).info := get_taxpayer(r_efd.rhea.receiver_document_number
                                    ,
                                                                                                       'RECEIVER');

                                    print('retorno receiver: ' || t_receiv(r_efd.rhea.receiver_document_number).info);
                                    t_receiv(r_efd.rhea.receiver_document_number).cnpj := r_efd.rhea.receiver_document_number;
                --
                                    ins_receiv(t_receiv(r_efd.rhea.receiver_document_number));
                --

            --IF r.receiver_taxpayer_id IS NULL THEN
                --
                                    begin
                  --
                                        for r1 in (
                                            select
                                                a.info.data.establishment_id taxpayer_id,
                                                a.info
                                            from
                                                rmais_receiver_info a
                                            where
                                                cnpj = r_efd.rhea.receiver_document_number
                                        ) loop
                    --
                                            print('Carregando Receiver ' || r1.taxpayer_id);
                    --
                                            r_efd.rhea.receiver_info := r1.info;
                                            print('receiver info: ' || r_efd.rhea.receiver_info);
                                            r_efd.rhea.receiver_taxpayer_id := r1.taxpayer_id;
                    --
                                        end loop;
                  --
                                    exception
                                        when others then
                                            print('Falha ao carregar informações do Estabelecimento '
                                                  || r_efd.rhea.receiver_document_number
                                                  || ' ' || sqlerrm);
                                    end;

                                    print('TEST Rec exception: ' || substr(r_efd.rhea.receiver_info,
                                                                           1,
                                                                           2));
            --
                                    begin
            --
                                        update rmais_efd_headers
                                        set
                                            document_status = r_efd.rhea.document_status,
                                            issuer_info = r_efd.rhea.issuer_info,
                                            issuer_taxpayer_id = r_efd.rhea.issuer_taxpayer_id,
                                            vendor_site_code =
                                                case
                                                    when r_efd.rhea.issuer_info like '%PARTY_NAME%' then
                                                        r_efd.rhea.vendor_site_code
                                                    else
                                                        vendor_site_code
                                                end,
                                            receiver_info = r_efd.rhea.receiver_info,
                                            receiver_taxpayer_id = r_efd.rhea.receiver_taxpayer_id,
                                            currency_code = r_efd.rhea.currency_code,
                                            source_doc_info = r_efd.rhea.source_doc_info,
                                            term_info = r_efd.rhea.term_info,
                                            document_type = r_efd.rhea.source_type,
                                            withholding = r_efd.rhea.withholding,
                                            party_name = r_efd.rhea.party_name,
                                            define_det_entry_type = l_role,
                                            org_id = r_efd.rhea.org_id
                                        where
                                            efd_header_id = r.efd_header_id;
            --
                                        commit;
            --
                                    exception
                                        when others then
              --
                                            print('Error Update headers 2: ' || sqlerrm);
              --
                                    end;
            --
                            end;

                        end if;
          --
                    exception
                        when others then
                            log_efd('Falha ao atualizar Header ' || sqlerrm, '', r.efd_header_id);
          --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Falha ao atualizar Header '||SQLERRM||'<br>';
                    end;
            end;
      --
      -- Envio de NF caso esteja validada
      --
            print('l_role: ' || l_role);
            print('g_po_find: ' ||
                case
                    when g_po_find then
                        'TRUE'
                    else
                        'FALSE'
                end
            );
      --
            teste_zz :=
                case
                    when g_po_find then
                        'TRUE'
                    else
                        'FALSE'
                end; -- teste Robson 17/04/2023
      --insert into TEST_CONF_ORIG_DOC (ID_CONF_ORIG_DOC,DESC_CONF_ORIG_DOC) values (r.efd_header_id,'1-teste_zz = '||teste_zz);
      --insert into TEST_CONF_ORIG_DOC (ID_CONF_ORIG_DOC,DESC_CONF_ORIG_DOC) values (r.efd_header_id,'1-teste_vx = '||teste_vx);
            if
                not g_po_find
                and l_role in ( 'item_default', 'find_po' )
                and nvl(r_efd.rhea.document_status,
                        'I') <> 'V'
                and p_flag_auto = 'Y'
            then
        --

                print('Buscando item de regra default');
        --
                begin
                    select
                        value1
                    into l_item
                    from
                        rmais_define_det_entry
                    where
                            model = r_efd.rhea.model
                        and type = 'item_default';
          --
                    r_efd.rhea.define_det_entry_type := 'item_default';
          --
                exception
                    when others then
          --  
                        null;
          --
                end;

        --
                update rmais_efd_headers
                set
                    document_type = 'NA',
                    define_det_entry_type = 'item_default'
                where
                    efd_header_id = r.efd_header_id;
         --
                begin
                    insert into test_conf_orig_doc (
                        id_conf_orig_doc,
                        desc_conf_orig_doc
                    ) values ( r.efd_header_id,
                               '3- r_Efd.rHea.define_det_entry_type = ' || r_efd.rhea.define_det_entry_type );

                exception
                    when others then
                        null;
                end;

                update rmais_efd_lines
                set
                    source_document_type = 'NA',
                    item_code_efd = l_item,
                    status = 'AUTO'
                where
                    efd_header_id = r.efd_header_id;

                commit;
          --        
                print('Revalidando documento trocando PO para NA, não econtrado pedido para nota');
          --        
                teste_vx := 1;
                main(
                    p_header_id => r.efd_header_id,
                    p_send_erp  => 'Y'
                );
        --
            end if;
      /*l_source       := null;
      l_item         := null;
      l_role         := null; then*/
            begin
        --
                print('Passo1-> MODEL: '
                      || r.model
                      || ', define_det_entry_type: '
                      || r_efd.rhea.define_det_entry_type
                      || ', l_role: ' || l_role);

                print('r_Efd.rHea.document_status: ' || r_efd.rhea.document_status);
                print('Parametro: ' || nvl(
                    rmais_process_pkg_bkp_to_worflow.get_parameter('SEND_ERP_AUTO'),
                    '2'
                ));
                print('Status da linha: ' || get_status_lines(r_efd.rhea.efd_header_id));
                if
                    nvl(r_efd.rhea.document_status,
                        'I') = 'V'
                    and (
                        nvl(
                            rmais_process_pkg_bkp_to_worflow.get_parameter('SEND_ERP_AUTO'),
                            '2'
                        ) = '1'
                        and 1 = 1
                    )
                    and get_status_lines(r_efd.rhea.efd_header_id) in ( 'AUTO', 'VALID' )
                    and p_send_erp = 'Y'
                then --
            -- somente documentos com pedido ou sem pedido com item específico
                    commit; -- Ver se é aqui ou dentro do if abaixo
                    print('Passo2-> MODEL: '
                          || r.model
                          || ', define_det_entry_type: '
                          || r.define_det_entry_type
                          || ', l_role: ' || l_role);
            --X Robson em 10/01/2023
                    select
                        max(a.flag_retention),
                        nvl(
                            max(a.flag_nf_op),
                            'Y'
                        )
                    into
                        l_flag_retention,
                        l_flag_nf_op
                    from
                        rmais_define_det_entry a
                    where
                            a.model = r.model
                        and a.type = nvl(r.define_det_entry_type, l_role);
            --
                    print('Passo3-> MODEL: '
                          || r.model
                          || ', define_det_entry_type: '
                          || r.define_det_entry_type
                          || ', l_role: ' || l_role);

                    print('l_flag_retention: '
                          || l_flag_retention
                          || ', l_flag_nf_op: ' || l_flag_nf_op);
            --
                    if l_flag_nf_op = 'Y' then
            --X
                        print('Enviando (send_invoice_v2) documento ao Oracle!!!');
                        send_invoice_v2(r_efd.rhea.efd_header_id,
                                        l_flag_retention);
                    else
                        print('Enviando (Update_Invoice) documento ao Oracle!!!');
                        update_invoice(r_efd.rhea.efd_header_id);
                    end if;
            --
                    null;
            --
                else
                    l_header_workflow := r_efd.rhea.efd_header_id;
                    commit;
                    xxrmais_util_v2_pkg.set_workflow(l_header_workflow,
                                                     g_log_workflow,
                                                     nvl(
                                     v('APP_USER'),
                                     '-1'
                                 ));

                end if;
        --
        --Se nota for sem pedido e com item generico deverá fazer update no Oracle ou caso a nota não esteja no Oracle colocar novo status como Aguardando criação da NF no ERP
            end;
        --
        
        --
        end loop;
    --
    --commit;
    --
    exception
        when others then
            print('Falha no processamento de NFs ' || sqlerrm);
    end;
  --
    function get_itens (
        p_transaction_id number,
        p_item           varchar2,
        p_item_descr     varchar2
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
    "org_code": "HDI_ORG_MESTRE"
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
     -- 
        return to_number ( json_value(get_response(
            get_parameter('GET_ITENS_URL'),
            l_body
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
        return p_cnpj;
      --
        select distinct
            cnpj_bu
        into l_return
        from
            rmais_bu_orgs
        where
            ( to_number(cnpj_bu) = to_number(p_cnpj)
              or to_number(cnpj_lru) = to_number(p_cnpj) );
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
  --
    procedure get_definition_type (
        p_efd_header_id    number default null,
        p_model            varchar2 default '00',
        p_source_type      in out varchar2,
        p_item             in out varchar2,
        p_role_application out varchar2,
        p_defined_role     out varchar2
    ) as

        l_model varchar2(10);
        l_type  varchar2(10);
--
--
        procedure get_definition_type_mista (
            p_efd_header_id varchar2,
            p_model         varchar2,
            p_source        in out varchar2,
            p_item          in out varchar2,
            l_type          varchar2,
            p_type_role     in out varchar2
        ) as
  --
            l_source_type_bkp varchar2(100) := p_source;
  --
            function get_type_find (
                p_efd_header_id number,
                p_value1        varchar2
            ) return varchar2 as
                l_aux            number;
                l_det_corretagem varchar2(1000) := p_value1;
            begin
    --
                select distinct
                    1
                into l_aux
                from
                    rmais_efd_headers
                where
                        efd_header_id = p_efd_header_id
                    and upper(additional_information) like upper('%'
                                                                 || replace(l_det_corretagem, ' ', '%') || '%')
                union
                select
                    1
                from
                    rmais_efd_lines
                where
                        efd_header_id = p_efd_header_id
                    and upper(item_description) like upper('%'
                                                           || replace(l_det_corretagem, ' ', '%') || '%')
    --
                union
                select
                    1
                from
                    rmais_lista_servicos rs,
                    rmais_efd_lines      rml
                where
                    upper(descricao) like upper('%'
                                                || replace(l_det_corretagem, ' ', '%') || '%')
                    and rml.fiscal_classification = rs.codigo_servico
                    and rml.efd_header_id = p_efd_header_id;
     --
                print('ENCONTRADO BUSCA GET_TyPE_FIND');
    --
                return 'OK';
    --
            exception
                when others then
    --
                    print('NÃO ENCONTRADO BUSCA GET_TyPE_FIND parameter: ' || l_det_corretagem);
    --
                    return null;
    --
            end get_type_find;
  --
            function check_find_text_po (
                p_efd_header_id number,
                p_value1        varchar2,
                p_type          varchar2
            ) return varchar2 as
                l_aux number;
            begin
    --
                select distinct
                    1
                into l_aux
                from
                    rmais_efd_lines
                where
                        efd_header_id = p_efd_header_id
                    and source_doc_number is not null;
    --
                print('Documento considerado C/ PEDIDO, pedido informado na linha');
    --
                return 'PO';
    --
            exception
                when others then
    --
                    return null;
    --
            end;
  --
        begin
  --
            for reg in (
                select
                    type, -- // item_defaul só pode ter 1 por modelo, caso nenhuma opção seja atendida o item cadastrado e associado
                    value1,
                    source_doc,
                    item,
                    conta,
                    priority
                from
                    rmais_define_det_entry
                where
                        model = p_model
                    and type in (
                        case
                            when l_type = 'NA' then
                                'item_default'
                            else
                                type
                        end,
                        case
                            when l_type = 'NA' then
                                'find'
                            else
                                type
                        end
                    )
                order by
                    priority asc
            ) loop
    --
                print('Prioridade: ' || reg.priority);
                print('Tipo      :' || reg.type);
                print('Valor     : ' || reg.value1);
                print('Source    : ' || reg.source_doc);
                print('Item      : ' || reg.item);
    --
                if reg.type = 'find' then--find - procurar palavara chave na descrição da nota
      --
                    p_source := null;
                    p_source := get_type_find(p_efd_header_id, reg.value1);
      --
                    if p_source is not null then 
        --
                        p_item := reg.item;
        --
                        p_source := reg.source_doc;
        --
                        p_type_role := reg.type;
        --
                        return;
        --
                    end if;
      --
                    p_source := nvl(p_source, l_source_type_bkp);
      --
                elsif reg.type = 'find_text_po' then  --find_text_po se existe pedido informado na linha
      --
                    p_source := null;
      --
                    p_source := check_find_text_po(p_efd_header_id, reg.value1, reg.type);
        --
                    if p_source is not null then 
        --
                        p_item := reg.item;
        --
                        p_source := reg.source_doc;
        --
                        p_type_role := reg.type;
        --
                        return;
        --
                    end if;
      --
                    p_source := nvl(p_source, l_source_type_bkp);
      -- 
                elsif reg.type = 'find_po' then
      --
                    p_source := 'PO';
      -- 
                    p_source := reg.source_doc;
      --
                    p_type_role := reg.type;
      --
                    return;
      -- 
                elsif reg.type = 'item_default' then
        --
                    p_item := reg.value1;
        --
                    p_source := reg.source_doc;
        --
                    p_type_role := reg.type;
        --
                    return;
        --   
                end if;
    --
                null;
    --
            end loop;                
  --
            print('Final da get_definition_type_mista');
  --
        end get_definition_type_mista;
--
    begin
--
        select
            model
        into l_model
        from
            rmais_efd_headers
        where
            efd_header_id = p_efd_header_id;
--
        print('get_definition_type');
--
        select
            type
        into l_type
        from
            rmais_define_roles_entry rl
        where
            rl.model = l_model;
 --
        print('Modelo: ' || l_model);
        print('Tipo  : ' || l_type);
 --
        p_defined_role := l_type;
 --
        if l_type = 'PO' then
   --
            print('Setup definido como C/ Pedido');
   --
            return;
   --
        elsif l_type = 'NA' then
   --
            print('Setup definido como S/ Pedido');
   --
            begin
     --
                select
                    value1
                into p_item
                from
                    rmais_define_det_entry
                where
                        model = l_model
                    and type = 'item_default';
      --
                print('Item Identificado no setup, ITEM: ' || p_item);
                return;
      --
            exception
                when others then
      --
                    print('Setup de item não efetuado na base');
      --
                    return;
      --
            end;      
   --
        elsif l_type = 'MT' then
   --
            null;
            get_definition_type_mista(p_efd_header_id, l_model, p_source_type, p_item, l_type,
                                      p_role_application);
   --  
        end if;
 --
    exception
        when others then
  --
            print('Modelo não cadastrado no setup de definição de com pedido ou sem pedido Modelo: ' || p_model);
  --
    end;
--
    procedure send_hold_invoice_ap (
        p_nf            in out clob,
        p_efd_header_id number
    ) as
--
        l_url       clob := get_ws || '/api/payables/v2/holdInvoiceService';
--
        l_body      clob;
--
        l_hold_name rmais_hold_setup.hold_name%type;
--
        l_response  clob;
--
        l_nf        clob;
--
    begin
  --
        print('Iniciando processo de integração de retenção manual');
  --
        l_nf := nvl(p_nf,
                    get_invoice_v2(p_efd_header_id));
  --
        print('Nf: ');
  --print(p_nf);
        print('');
  --
        print('Iniciando envio de retenção');
  --
        select
            hold_name
        into l_hold_name
        from
            rmais_hold_setup
        where
            rownum = 1;
  --
        l_body :=
            json_object(
                'BusinessUnit' value json_value(l_nf, '$.BusinessUnit'),
                        'InvoiceNumber' value json_value(l_nf, '$.InvoiceNumber'),
                        'Supplier' value json_value(l_nf, '$.Supplier'),
                        'HoldName' value l_hold_name
            );
  --
        print('l_body: ' || l_body);
  --
        l_response := rmais_process_pkg_bkp_to_worflow.get_response2(l_url, l_body, 'POST');
  --
        print('l_response: ' || substr(l_response, 1, 2000));
  --
        if json_value(l_response, '$.HoldId') is not null then
    --
    --Log_Efd('Retenção enviada ao AP.','', p_efd_header_id);
    --
            xxrmais_util_v2_pkg.create_event(p_efd_header_id,
                                             'Retenção AP',
                                             'Retenção realizada no AP',
                                             v('USER')); 
    --
            print('Retenção enviada ao AP.');
    --
        else
    --
            log_efd('Não foi possível criar retenção, contacte o administrador.', '', p_efd_header_id, 'Erro');
    --
    --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Não foi possível criar retenção, contacte o administrador.'||'<br>';
    --
            print('Não foi possível criar retenção, contacte o administrador.');
    --
            print(l_response);
    --
        end if;
  -- 
    end send_hold_invoice_ap;
--
    procedure update_invoice (
        p_header_id in number
    ) is

        l_url_mod    constant varchar2(1000) := rmais_process_pkg_bkp_to_worflow.get_parameter('GET_URL_UPDATE_MODEL');--'http://152.67.41.84:9000/api/payables/v2/updateInvoiceModel';
        l_url_att    constant varchar2(1000) := rmais_process_pkg_bkp_to_worflow.get_parameter('GET_URL_UPDATE_ATTACH');--'http://152.67.41.84:9000/api/payables/v2/updateInvoiceAttach';
        l_response   clob; -- l_response varchar2(4000);
        l_body_doc   clob;
        l_body_att   clob;
        l_flag_falha number;
    begin
        generate_attachments(p_header_id);
    --
        print('Iniciando update invoice');
    --
        with tp_cfop as (
            select
                a.efd_header_id,
                max(a.fiscal_classification) cfop
            from
                rmais_efd_lines a
            where
                a.cfop_from is not null
            group by
                a.efd_header_id
        ), tp_efd as (
            select
                nvl(a.original_document_number, a.document_number) invoicenumber,
                a.series,
                a.access_key_number,
                nvl(
                    nvl(a.receiver_info.data.bu_name,
                        a.receiver_info.bu_name),
                    'HDI Seguros S.A. BU'
                )                                                  businessunit,--'INATIVO-HDI Seguros S.A. BU' BusinessUnit,
                a.org_id,
                   -- case when a.org_id = 300000024270757 and a.issue_date <= to_date('2022-10-16','YYYY-MM-DD') then 'INATIVO-HDI Seguros S.A. BU' else nvl(nvl(A.RECEIVER_INFO.DATA.BU_NAME,a.receiver_info.BU_NAME)) end  BusinessUnit,--, 'HDI Seguros S.A. BU') BusinessUnit,--'INATIVO-HDI Seguros S.A. BU' BusinessUnit,
                   -- case when h.org_id = 300000024270757 and a.issue_date <= to_date('2022-10-16','YYYY-MM-DD') then 'INATIVO-HDI Seguros S.A. BU' else nvl(nvl(A.RECEIVER_INFO.DATA.BU_NAME,a.receiver_info.BU_NAME)) end  BusinessUnit,--, 'HDI Seguros S.A. BU') BusinessUnit,--'INATIVO-HDI Seguros S.A. BU' BusinessUnit,
                   -- case when h.org_id = 300000024270757 and a.issue_date <= to_date('2022-10-16','YYYY-MM-DD') then '300000024270758' else to_char(a.org_id)  end org_id,

                coalesce(a.issuer_info.data.party_name,
                         (
                    select
                        max(b.order_info.vendor_name)
                    from
                        rmais_efd_lines b
                    where
                        b.efd_header_id = a.efd_header_id
                ),
                         a.issuer_name)                            supplier, --'HI SERVICE TERCEIRIZACAO LTDA' Supplier,
                nvl(a.vendor_site_code, a.issuer_document_number)  suppliersite, --'01861019000195' SupplierSite,
                case
                    when a.model = '57' then
                        '57'
                    when a.model = '21' then
                        '21'
                    when a.model = '22' then
                        '22'
                    when a.model = 'NF' then
                        '32'
                    when a.model = '00' then
                        '39'
                    when a.model = '55'
                         and a.issuer_address_city_code = '5300108'
                         and instr(f.cfop, '.') > 0 then
                        '39' -- Robson 16/03/2023
                    when a.model = '55' then
                        '55'
                    else
                        '99'
                end                                                model,
                return_filename_croped(b.filename)                 filename,
                return_filename_croped(b.filename, 'N')            title,
                return_filename_croped(b.filename, 'N')            description,
                case
                    when b.filename is not null then
                        'From Supplier'
                end                                                category,
                b.clob_file                                        filecontents,
                a.receiver_document_number
            from
                rmais_efd_headers a,
                rmais_attachments b,
                tp_cfop           f
            where
                    a.efd_header_id = p_header_id
                and a.efd_header_id = b.efd_header_id (+)
                and a.efd_header_id = f.efd_header_id (+)
        )
        select
                json_object(
                    'InvoiceNumber' value to_char(c.invoicenumber),
                            'BusinessUnit' value c.businessunit,
                            'Supplier' value c.supplier,
                            'SupplierSite' value c.suppliersite,
                            'Model' value c.model,
                            'Serie' value
                        case
                            when c.model in('55', '57', '67') then
                                c.series
                            else
                                'SS'
                        end,
                            'AccessKey' value c.access_key_number,
                      --  'FirstPartyTaxRegistrationNumber' value c.receiver_document_number
                            'FirstPartyTaxRegistrationId' value c.org_id
                )
            a,
                json_object(
                    'InvoiceNumber' value to_char(c.invoicenumber),
                            'BusinessUnit' value c.businessunit,
                            'Supplier' value c.supplier,
                            'SupplierSite' value c.suppliersite,
                            'FileName' value c.filename,
                            'Title' value c.title,
                            'Description' value c.description,
                            'Category' value c.category,
                            'FileContents' value replace(
                        replace(
                            replace(
                                replace(c.filecontents,
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
                returning clob)
            b
        into
            l_body_doc,
            l_body_att
        from
            tp_efd c;
    
    --
        print('processar att ('
              || length(l_body_att) || ')');
    --
        if rmais_global_pkg.g_enable_log = 'Y' then
      --
            xxrmais_util_v2_pkg.g_test := 'CLOB';
            xxrmais_util_v2_pkg.print_clob_to_output(l_body_att);
      --
        end if;
    --  
        l_response := rmais_process_pkg_bkp_to_worflow.get_response2(l_url_att, l_body_att, 'POST');
    --
        print('l_response att = #'
              || json_value(l_response, '$.retorno') || '#');
    --
        if json_value(l_response, '$.retorno') = '201' then
        --
            print('l_body_doc: ' || l_body_doc);
        --
            l_response := rmais_process_pkg_bkp_to_worflow.get_response2(l_url_mod, l_body_doc, 'POST');
        --
            print('l_reponse1 doc: ' || l_response);
        --
            if json_value(l_response, '$.retorno') = '200' then
                l_flag_falha := 0;
            else
                l_flag_falha := 1;
            end if;

        elsif json_value(l_response, '$.retorno') = 'Nota Fiscal não localizada! ' then
            l_flag_falha := 3;
        else
            l_flag_falha := 2;
        end if;

        print('chegou');
        update rmais_efd_headers a
        set
            a.document_status =
                case
                    when l_flag_falha = 0 then
                        'UP'
                    when l_flag_falha in ( 1, 2 ) then
                        'E'
                    when l_flag_falha = 3 then
                        'AC'
                end
        where
            a.efd_header_id = p_header_id;

        commit;
    --
        if l_flag_falha = 1 then
            log_efd('Erro ao atualizar informações adicionais. ('
                    || json_value(l_response, '$.retorno')
                    || ')',
                    '',
                    p_header_id,
                    'Erro');
        --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Erro ao atualizar informações adicionais. ('||JSON_VALUE(l_response,'$.retorno')||')'||'<br>';
        elsif l_flag_falha = 2 then
            log_efd('Erro ao atualizar anexo do documento. ('
                    || json_value(l_response, '$.retorno')
                    || ')',
                    '',
                    p_header_id,
                    'Erro');
        --RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow := RMAIS_PROCESS_PKG_BKP_TO_WORFLOW.g_log_workflow ||' Erro ao atualizar anexo do documento. ('||JSON_VALUE(l_response,'$.retorno')||')'||'<br>';
        end if;
    --
        print('Update headers Flag: Erro ao atualizar anexo do documento. ('
              || json_value(l_response, '$.retorno')
              || ')' || l_flag_falha);
    --
        xxrmais_util_v2_pkg.set_workflow(p_header_id,
                                         g_log_workflow,
                                         nvl(
                         v('APP_USER'),
                         '-1'
                     ));
    --
    end update_invoice;
--
    procedure update_devolucao (
        p_header_id         in number,
        p_header_id_anexo   in number,
        p_id_nota_devolucao in number
    ) is

        l_url_att               constant varchar2(1000) := rmais_process_pkg_bkp_to_worflow.get_parameter('GET_URL_UPDATE_ATTACH');--'http://152.67.41.84:9000/api/payables/v2/updateInvoiceAttach';
        l_response              clob; -- l_response varchar2(4000);    
        l_body_att              clob;
        l_flag_falha            number;
        l_status_nota_devolucao rmais_notas_devolucao.status%type;
    begin
        generate_attachments(p_header_id_anexo);
    --
        print('Iniciando update invoice');
    --
        with tp_cfop as (
            select
                a.efd_header_id,
                max(a.fiscal_classification) cfop
            from
                rmais_efd_lines a
            where
                a.cfop_from is not null
            group by
                a.efd_header_id
        ), tp_efd as (
            select
                a.document_number                                 invoicenumber,
                a.series,
                a.access_key_number,
                nvl(
                    nvl(a.receiver_info.data.bu_name,
                        a.receiver_info.bu_name),
                    'HDI Seguros S.A. BU'
                )                                                 businessunit,--'INATIVO-HDI Seguros S.A. BU' BusinessUnit,
                a.org_id,
                coalesce(a.issuer_info.data.party_name,
                         (
                    select
                        max(b.order_info.vendor_name)
                    from
                        rmais_efd_lines b
                    where
                        b.efd_header_id = a.efd_header_id
                ),
                         a.issuer_name)                           supplier, --'HI SERVICE TERCEIRIZACAO LTDA' Supplier,
                nvl(a.vendor_site_code, a.issuer_document_number) suppliersite, --'01861019000195' SupplierSite,
                case
                    when a.model = '57' then
                        '57'
                    when a.model = '21' then
                        '21'
                    when a.model = '22' then
                        '22'
                    when a.model = 'NF' then
                        '32'
                    when a.model = '00' then
                        '39'
                    when a.model = '55'
                         and a.issuer_address_city_code = '5300108'
                         and instr(f.cfop, '.') > 0 then
                        '39' -- Robson 16/03/2023
                    when a.model = '55' then
                        '55'
                    else
                        '99'
                end                                               model
            from
                rmais_efd_headers a,
                rmais_attachments b,
                tp_cfop           f
            where
                    a.efd_header_id = p_header_id
                and a.efd_header_id = b.efd_header_id (+)
                and a.efd_header_id = f.efd_header_id (+)
        ), tp_efd_anexo as (
            select
                return_filename_croped(b.filename)      filename,
                return_filename_croped(b.filename, 'N') title,
                return_filename_croped(b.filename, 'N') description,
                case
                    when b.filename is not null then
                        'From Supplier'
                end                                     category,
                b.clob_file                             filecontents,
                a.receiver_document_number
            from
                rmais_efd_headers a,
                rmais_attachments b,
                tp_cfop           f
            where
                    a.efd_header_id = p_header_id_anexo
                and a.efd_header_id = b.efd_header_id (+)
                and a.efd_header_id = f.efd_header_id (+)
        )
        select
                json_object(
                    'InvoiceNumber' value to_char(c.invoicenumber),
                            'BusinessUnit' value c.businessunit,
                            'Supplier' value c.supplier,
                            'SupplierSite' value c.suppliersite,
                            'FileName' value a.filename,
                            'Title' value a.title,
                            'Description' value a.description,
                            'Category' value a.category,
                            'FileContents' value replace(
                        replace(
                            replace(
                                replace(a.filecontents,
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
                returning clob)
            b
        into l_body_att
        from
            tp_efd       c,
            tp_efd_anexo a;    
    --
        print('processar att ('
              || length(l_body_att) || ')');
    --
        if rmais_global_pkg.g_enable_log = 'Y' then
      --
            xxrmais_util_v2_pkg.g_test := 'CLOB';
            xxrmais_util_v2_pkg.print_clob_to_output(l_body_att);
      --
        end if;
    --  
    --RETURN;
        l_response := rmais_process_pkg_bkp_to_worflow.get_response2(l_url_att, l_body_att, 'POST');
    --
        print('l_response att = #'
              || json_value(l_response, '$.retorno') || '#');
    --
        if json_value(l_response, '$.retorno') = '201' then
            l_flag_falha := 0;
        else
            l_flag_falha := 2;
        end if;

        print('chegou');
        update rmais_efd_headers a
        set
            a.document_status =
                case
                    when l_flag_falha = 0 then
                        'AI'
                    when l_flag_falha in ( 2 ) then
                        'E'
                end
        where
            a.efd_header_id = p_header_id_anexo;

        commit;
    --
        if l_flag_falha = 2 then
            log_efd('Erro ao atualizar anexo do documento. ('
                    || json_value(l_response, '$.retorno')
                    || ')',
                    '',
                    p_header_id_anexo,
                    'Erro');

            l_status_nota_devolucao := 'E';
        else
            l_status_nota_devolucao := 'AI';
        end if;
    --
        update rmais_notas_devolucao
        set
            status = l_status_nota_devolucao
        where
            id_nd = p_id_nota_devolucao;
    --
        print('Update headers Flag: ' || l_flag_falha);
    --
    end update_devolucao;
--
    procedure reprocess_waiting_crete_doc_run is
    begin
        for c in (
                /*with
                    TP_PROC_CTRL as (
                        select  B.EFD_HEADER_ID
                        from    RMAIS_REPROCESS_CTRL B
                        where   B.FLAG_REPROCESS_CTRL = 1
                    )*/
            select
                a.efd_header_id
            from
                rmais_efd_headers a
                        --,TP_PROC_CTRL B
            where
                    1 = 1-- A.EFD_HEADER_ID = B.EFD_HEADER_ID (+)
                and a.document_status = 'AC'
                  -- and     a.efd_header_id = 522504
                and not exists (
                    select
                        1
                    from
                        rmais_reprocess_ctrl b
                    where
                        a.efd_header_id = b.efd_header_id
                )
                and rownum = 1
        ) loop
        --rmais_global_pkg.g_enable_log := 'Y';
            insert into rmais_reprocess_ctrl values ( 1,
                                                      c.efd_header_id );

            rmais_process_pkg_bkp_to_worflow.update_invoice(p_header_id => c.efd_header_id);
        end loop;
    end reprocess_waiting_crete_doc_run;
--
    function cursor_po_line (
        p_transaction_id number
    ) return t$po_line is

        r$po t$po_line;
        cursor c$po (
            p_transaction number
        ) is
        select distinct
            a.line_location_id,
            a.cnpj,
            a.receiver,
            a.total_po,
            a.po_header_id,
            a.po_num,
            a.po_type,
            a.tomador,
            a.tomador_cnpj,
            a.prc_bu_id,
            a.vendor_name,
            a.vendor_id,
            a.vendor_site_id,
            a.vendor_site_code,
            a.fornecedor_cnpj,
            a.currency_code,
            a.info_doc,
            a.info_term,
            a.po_seq,
            a.info_po,
            a.info_item,
            a.info_ship,
            a.po_line_id,
            a.line_type_id,
            a.line_num,
            a.item_id,
            a.category_id,
            a.item_description,
            nvl(a.primary_uom_code,
                max(a.primary_uom_code)
                over(partition by a.line_location_id))                uom_code,
            nvl(a.uom_code_po,
                max(a.uom_code_po)
                over(partition by a.line_location_id))                uom_desc,
                --nvl(UNIT_OF_MEASURE_PO,UOM_CODE2) UOM_DESC -- baseado no get_po_line
            a.unit_price,
            a.quantity_line,
            a.prc_bu_id_lin,
            a.req_bu_id_lin,
            a.taxable_flag_lin,
            a.order_type_lookup_code,
            a.purchase_basis,
            a.matching_basis,
            a.destination_type_code,
            a.trx_business_category,
            a.prc_bu_id_loc,
            a.req_bu_id_loc,
            a.product_type,
            a.assessable_value,
            a.quantity_ship,
            a.quantity_received,
            a.quantity_accepted,
            a.quantity_rejected,
            a.quantity_billed,
            a.quantity_cancelled,
            a.ship_to_location_id,
            to_char(a.need_by_date)                               need_by_date,
            to_char(a.promised_date)                              promised_date,
            a.last_accept_date,
            a.price_override,
            a.taxable_flag,
            a.receipt_required_flag,
            a.ship_to_organization_id,
            a.shipment_num,
            a.shipment_type,
            a.funds_status,
            a.destination_type_dist,
            a.prc_bu_id_dist,
            a.req_bu_id_dist,
            a.encumbered_flag,
            a.unencumbered_quantity,
            a.amount_billed,
            a.amount_cancelled,
            a.quantity_financed,
            a.amount_financed,
            a.quantity_recouped,
            a.amount_recouped,
            a.retainage_withheld_amount,
            a.retainage_released_amount,
            a.tax_attribute_update_code,
            a.po_distribution_id,
            a.budget_date,
            a.close_budget_date,
            a.dist_intended_use,
            a.set_of_books_id,
            a.code_combination_id,
            a.quantity_ordered,
            a.quantity_delivered,
            a.consignment_quantity,
            a.req_distribution_id,
            a.deliver_to_location_id,
            a.deliver_to_person_id,
            a.rate_date,
            a.rate,
            a.accrued_flag,
            a.encumbered_amount,
            a.unencumbered_amount,
            a.destination_organization_id,
            a.pjc_task_id,
            a.task_number,
            a.task_id,
            a.location_id,
            a.country,
            a.postal_code,
            a.local_description,
            a.effective_start_date,
            a.effective_end_date,
            a.business_group_id,
            a.active_status,
            a.ship_to_site_flag,
            a.receiving_site_flag,
            a.bill_to_site_flag,
            a.office_site_flag,
            a.inventory_organization_id,
            a.action_occurrence_id,
            a.location_code,
            a.location_name,
            a.style,
            a.address_line_1,
            a.address_line_2,
            a.address_line_3,
            a.address_line_4,
            a.region_1,
            a.region_2,
            a.town_or_city,
            a.line_seq,
            nvl(a.inventory_item_id,
                max(a.inventory_item_id)
                over(partition by a.line_location_id))                inventory_item_id,
            nvl(a.primary_uom_code,
                max(a.primary_uom_code)
                over(partition by a.line_location_id))                primary_uom_code,
            nvl(a.item_type,
                max(a.item_type)
                over(partition by a.line_location_id))                item_type,
            nvl(a.inventory_item_flag,
                max(a.inventory_item_flag)
                over(partition by a.line_location_id))                inventory_item_flag,
            a.tax_code,
            nvl(a.enabled_flag,
                max(a.enabled_flag)
                over(partition by a.line_location_id))                enabled_flag,
            nvl(a.item_number,
                max(a.item_number)
                over(partition by a.line_location_id))                item_number,
            nvl(a.description,
                max(a.description)
                over(partition by a.line_location_id))                descr, -- substituir DESCRIPTION na get_po_line por DESCR
            nvl(a.long_description,
                max(a.long_description)
                over(partition by a.line_location_id))                long_description,
            a.ncm,
            a.catalog_code_ncm,
            nvl(a.destination_type_code, a.destination_type_dist) destination_type,
            a.match_option,
            nvl(a.receipt_num,
                max(a.receipt_num)
                over(partition by a.line_location_id))                receipt_num,
            nvl(a.receipt_line_num,
                max(a.receipt_line_num)
                over(partition by a.line_location_id))                receipt_line_num,
            nvl(a.receipt_quantity_deliv,
                max(a.receipt_quantity_deliv)
                over(partition by a.line_location_id))                receipt_quantity_deliv
        from
            (
                select
                    p.transaction_id,
                    d.fornecedor_cnpj               cnpj,
                    d.tomador_cnpj                  receiver,
                    sum(nvl(d.price_override * quantity_ship, d.unit_price * d.quantity_line))
                    over(partition by po_header_id) total_po,
                            --SUM(NVL(nls_num_char(D.price_override) * nls_num_char(quantity_ship),nls_num_char(D.UNIT_PRICE) * nls_num_char(D.QUANTITY_LINE))) OVER (PARTITION BY PO_HEADER_ID) TOTAL_PO
                    d.*
                from
                    rmais_ws_info p,
                    json_table ( replace(
                            replace(
                                replace(
                                    replace(
                                        xxrmais_util_pkg.base64decode(p.clob_info),
                                        '"RECEIPT":{',
                                        '"RECEIPT":[{'
                                    ),
                                    '"DESTINATION_TYPE_CODE":"RECEIVING"}}',
                                    '"DESTINATION_TYPE_CODE":"RECEIVING"}]}'
                                ),
                                '"LINE_LOCATIONS":{',
                                '"LINE_LOCATIONS":[{'
                            ),
                            '},"ITEM":',
                            '}],"ITEM":'
                        ), '$'
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
                                        nested path '$.LINES[*]'
                                            columns (
                                                info_po varchar2 ( 4000 ) format json with wrapper path '$',
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
                                                nested path '$.LINE_LOCATIONS[*].RECEIPT[*]'
                                                    columns ( -- Adicionado 23/01/2023 Robson
                                                        receipt_num varchar2 ( 900 ) path '$.RECEIPT_NUM',
                                                        receipt_line_num varchar2 ( 900 ) path '$.LINE_NUM',
                                                        receipt_quantity_deliv varchar2 ( 900 ) path '$.QUANTITY_DELIVERED',
                                                        input_tax_classification_code varchar2 ( 900 ) path '$.TAX_CLASSIFICATION_CODE'
                                                        ,
                                                --TAX_RATE VARCHAR2(900) path '$.PERCENTAGE_RATE'
                                                        tax_rate2 varchar2 ( 900 ) path '$.PERCENTAGE_RATE'
                                                    ),
                                                prc_bu_id_lin number path '$.PRC_BU_ID',
                                                req_bu_id_lin number path '$.REQ_BU_ID',
                                                taxable_flag_lin varchar2 ( 100 ) path '$.TAXABLE_FLAG',
                                                order_type_lookup_code varchar2 ( 100 ) path '$.ORDER_TYPE_LOOKUP_CODE',
                                                purchase_basis varchar2 ( 100 ) path '$.PURCHASE_BASIS',
                                                matching_basis varchar2 ( 100 ) path '$.MATCHING_BASIS',
                                                line_seq for ordinality,
                                                nested path '$.ITEM'
                                                    columns (
                                                --info_item CLOB FORMAT JSON path '$[*]',
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
                                                        catalog_code_ncm varchar2 ( 100 ) path '$.CATALOG_CODE',
                                                        uom_code varchar ( 100 ) path '$.UNIT_OF_MEASURE'
                                                    ),
                                                line_location_id number path '$.LINE_LOCATIONS.LINE_LOCATION_ID',
                                                match_option varchar ( 100 ) path '$.LINE_LOCATIONS.MATCH_OPTION', -- Adicionado 23/01/2023 Robson
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
                                                destination_type_dist varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_TYPE_CODE'
                                                ,
                                                prc_bu_id_dist number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PRC_BU_ID',
                                                req_bu_id_dist number path '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_BU_ID',
                                                encumbered_flag varchar2 ( 10 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_FLAG'
                                                ,
                                                unencumbered_quantity number path '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_QUANTITY'
                                                ,
                                                amount_billed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_BILLED',
                                                amount_cancelled number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_CANCELLED',
                                                quantity_financed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_FINANCED',
                                                amount_financed number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_FINANCED',
                                                quantity_recouped number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_RECOUPED',
                                                amount_recouped number path '$.LINE_LOCATIONS.DISTRIBUTIONS.AMOUNT_RECOUPED',
                                                retainage_withheld_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_WITHHELD_AMOUNT'
                                                ,
                                                retainage_released_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RETAINAGE_RELEASED_AMOUNT'
                                                ,
                                                tax_attribute_update_code varchar2 ( 100 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.TAX_ATTRIBUTE_UPDATE_CODE'
                                                ,
                                                po_distribution_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PO_DISTRIBUTION_ID',
                                                budget_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.BUDGET_DATE',
                                                close_budget_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.CLOSE_BUDGET_DATE'
                                                ,
                                                dist_intended_use varchar2 ( 500 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.DIST_INTENDED_USE'
                                                ,
                                                set_of_books_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.SET_OF_BOOKS_ID',
                                                code_combination_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.CODE_COMBINATION_ID',
                                                quantity_ordered number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_ORDERED',
                                                quantity_delivered number path '$.LINE_LOCATIONS.DISTRIBUTIONS.QUANTITY_DELIVERED',
                                                consignment_quantity number path '$.LINE_LOCATIONS.DISTRIBUTIONS.CONSIGNMENT_QUANTITY'
                                                ,
                                                req_distribution_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.REQ_DISTRIBUTION_ID',
                                                deliver_to_location_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_LOCATION_ID'
                                                ,
                                                deliver_to_person_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DELIVER_TO_PERSON_ID'
                                                ,
                                                rate_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE_DATE',
                                                rate number path '$.LINE_LOCATIONS.DISTRIBUTIONS.RATE',
                                                accrued_flag varchar2 ( 50 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.ACCRUED_FLAG',
                                                encumbered_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.ENCUMBERED_AMOUNT',
                                                unencumbered_amount number path '$.LINE_LOCATIONS.DISTRIBUTIONS.UNENCUMBERED_AMOUNT',
                                                destination_organization_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.DESTINATION_ORGANIZATION_ID'
                                                ,
                                                pjc_task_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.PJC_TASK_ID',
                                                task_number varchar2 ( 200 ) path '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_NUMBER',
                                                task_id number path '$.LINE_LOCATIONS.DISTRIBUTIONS.TASKS.TASK_ID',
                                                location_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_ID',
                                                country varchar2 ( 500 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.COUNTRY',
                                                postal_code varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.POSTAL_CODE',
                                                local_description varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.DESCRIPTION'
                                                ,
                                                effective_start_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_START_DATE'
                                                ,
                                                effective_end_date varchar2 ( 50 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.EFFECTIVE_END_DATE'
                                                ,
                                                business_group_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BUSINESS_GROUP_ID',
                                                active_status varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTIVE_STATUS'
                                                ,
                                                ship_to_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.SHIP_TO_SITE_FLAG'
                                                ,
                                                receiving_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.RECEIVING_SITE_FLAG'
                                                ,
                                                bill_to_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.BILL_TO_SITE_FLAG'
                                                ,
                                                office_site_flag varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.OFFICE_SITE_FLAG'
                                                ,
                                                inventory_organization_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.INVENTORY_ORGANIZATION_ID'
                                                ,
                                                action_occurrence_id number path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ACTION_OCCURRENCE_ID'
                                                ,
                                                location_code varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_CODE'
                                                ,
                                                location_name varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.LOCATION_NAME'
                                                ,
                                                style varchar2 ( 100 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.STYLE',
                                                address_line_1 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_1'
                                                ,
                                                address_line_2 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_2'
                                                ,
                                                address_line_3 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_3'
                                                ,
                                                address_line_4 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.ADDRESS_LINE_4'
                                                ,
                                                region_1 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_1',
                                                region_2 varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.REGION_2',
                                                town_or_city varchar2 ( 300 ) path '$.LINE_LOCATIONS.SHIP_TO_LOCATION.TOWN_OR_CITY'
                                            )
                                    )
                            )
                        )
                    d
                where
                    p.transaction_id = p_transaction_id
            ) a --105736 :G_TRANSACTION_ID) A
        where
            a.match_option is not null
        order by
            a.po_num,
            a.line_num;

    begin
        print('Begin Cursor_Po_Line - TransactionId: ' || p_transaction_id);
        open c$po(p_transaction_id);
        fetch c$po
        bulk collect into r$po;
        close c$po;
        return r$po;
    exception
        when others then
            print('Erro ao montar o cursor na Cursor_PO_Line: ' || sqlerrm);
            return null;
    end cursor_po_line;
--
    function cancel_nf_erp (
        p_header_id in number
    ) return varchar2 as

        l_url_mod  constant varchar2(1000) := rmais_process_pkg_bkp_to_worflow.get_parameter('GET_URL_CANCEL_INVOICE');--'http://152.67.41.84:9000/api/payables/v2/cancelInvoiceService';
                                          
    ---l_url_att constant varchar2(1000) := 'http://152.67.41.84:9000/api/payables/v2/updateInvoiceAttach';
        l_response varchar2(4000);
        l_body_doc clob;
        l_body_att clob;
        l_status   varchar2(2);
    begin
    --
        print('Iniciando Cancelamento da NF no ERP');
    --
        with tp_efd as (
            select
                a.document_number                                 invoicenumber,
                a.series,
                a.access_key_number,
                nvl(
                    nvl(a.receiver_info.data.bu_name,
                        a.receiver_info.bu_name),
                    'HDI Seguros S.A. BU'
                )                                                 businessunit,--'INATIVO-HDI Seguros S.A. BU' BusinessUnit,
                coalesce(a.issuer_info.data.party_name,
                         (
                    select
                        max(b.order_info.vendor_name)
                    from
                        rmais_efd_lines b
                    where
                        b.efd_header_id = a.efd_header_id
                ),
                         a.issuer_name)                           supplier, --'HI SERVICE TERCEIRIZACAO LTDA' Supplier,
                nvl(a.vendor_site_code, a.issuer_document_number) suppliersite, --'01861019000195' SupplierSite,
                case a.model
                    when '57' then
                        '57'
                    when '21' then
                        '21'
                    when '22' then
                        '22'
                    when 'NF' then
                        '32'
                    when '00' then
                        '39'
                    when '55' then
                        '55'
                    else
                        '99'
                end                                               model
            from
                rmais_efd_headers a
            where
                a.efd_header_id = p_header_id
        )
        select
                json_object(
                    'InvoiceNumber' value to_char(c.invoicenumber),
                            'BusinessUnit' value c.businessunit,
                            'Supplier' value c.supplier,
                            'SupplierSite' value c.suppliersite
                )
            a
        into l_body_doc
        from
            tp_efd c;

        print('l_body_doc: ' || l_body_doc);
        l_response := rmais_process_pkg_bkp_to_worflow.get_response2(l_url_mod, l_body_doc, 'POST');
    --
        print('l_reponse1: ' || l_response);
    --
        if l_response = 'The current action Cancel Invoice has completed successfully.' then
            l_status := 'CE';
            xxrmais_util_v2_pkg.create_event(
                p_efd_header_id => p_header_id,
                p_event         => 'Sucesso de atualização ERP',
                p_msg           => 'Sucesso',
                p_user          => 'Sistema'
            );

        else
            l_status := 'EE';
            xxrmais_util_v2_pkg.create_event(
                p_efd_header_id => p_header_id,
                p_event         => 'Erro atualização doc. ERP',
                p_msg           => l_response,
                p_user          => 'Sistema'
            );

        end if;
    --
        print('Iniciar Update headers l_status: ' || l_status);
    --
        update rmais_efd_headers a
        set
            a.document_status = l_status
        where
            a.efd_header_id = p_header_id;

        commit;
    --
        print('Update headers finalizado');
        return l_response;
    end cancel_nf_erp;
--
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
--
    procedure reprocess_header (
        p_efd_header_id      number,
        p_flag_change_num_nf varchar2 default 'S',
        p_user               in varchar2
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
                and document_status = 'CE'
        ) loop
            if p_flag_change_num_nf = 'S' then
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

            end if;
      --

            update rmais_efd_headers
            set
                document_status = 'I',
                document_number =
                    case
                        when p_flag_change_num_nf = 'S' then
                            r_nf
                        else
                            document_number
                    end
            where
                efd_header_id = p_efd_header_id;
      --
            xxrmais_util_v2_pkg.create_event(rp.efd_header_id, 'NF Reprocessada', 'NF reprocessada: ' || r_nf, 'SISTEMA');
      --
        end loop;
    --
        commit;
    --
        xxrmais_util_v2_pkg.set_workflow(p_efd_header_id,
                                         'Nota reprocessada',
                                         nvl(
                         v('APP_USER'),
                         '-1'
                     ));
    --
        print('Terminando');
    end reprocess_header;
--
    procedure split_line (
        p_line_id number,
        p_arr     varchar2
    ) as
        l_rowl rmais_efd_lines%rowtype;
    begin
    --
    --
    --execute immediate 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '''||'.,'||'''';
    --execute immediate 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '''||'.,'||'''';
	--
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
        l_rowl.efd_line_id_parent := l_rowl.efd_line_id; --linha inicial mesmo id do efd_line_id
    --
        l_rowl.cfop_to := null;
        l_rowl.utilization_id := null;
    --l_rowl.utilization_code := null;
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
                null;
        end;
--
        if (
            l_rowl.efd_line_id_parent is null
            and l_rowl.line_amount_original is null
        )
        or --split inicial
         ( l_rowl.efd_line_id_parent = l_rowl.efd_line_id ) then --garantindo que está na primeira linha mesmo após splitado

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
            for c in (
                with tp_split as (
                    select
                        p_arr seq_id
                    from
                        dual
                )
                select
                    regexp_substr(a.seq_id, '[^,]+', 1, level) seq_id
                from
                    tp_split a
                connect by
                    level <= regexp_count(a.seq_id, ',') + 1
            ) loop
        --
                l_rowl.efd_line_id := nvl(l_rowl.efd_line_id, rmais_efd_lines_s.nextval);
        --
                begin
                    select
                        c001                                              pedido,
                        n001                                              po_line_id,
                        c009                                              po_header_id,
                        n005                                              line_location_id,
                        c006                                              info_po,
                        c007                                              item_number,
                        c002                                              item_description,
                        c012                                              item_info,
                        c003                                              uom_code,
                        n002                                              line_num,
                        nls_num_char(c010)                                unit_price,
                        replace(
                            to_char(n004),
                            '.',
                            ','
                        )                                                 quantity_line,
                        ( to_number(replace(c010, '.', ',')) * ( n004 ) ) tot,-- + replace(nvl(c017,'0'),'.',',')tot,
                        'PO'                                              typ,
                        'MANUAL'                                          status,
                        decode(c017, 'P', '', c018)                       receipt_num,
                        decode(c017, 'P', '', c019)                       receipt_line_num
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
                        l_rowl.receipt_num,
                        l_rowl.receipt_line_num
                    from
                        apex_collections
                    where
                            collection_name = 'RMAIS_PO_OK'
                        and seq_id = c.seq_id;

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
    end split_line;
--
    procedure integrar_anexo_devolucao is
        p_header_id       number;
        p_header_id_anexo number;
    begin
        for rw in (
            select
                *
            from
                rmais_notas_devolucao
            where
                status in ( 'AU', 'AP' )
                and rownum < 10
        ) loop
            begin
                select
                    efd_header_id
                into p_header_id
                from
                    rmais_efd_headers
                where
                    access_key_number = rw.access_key_number_purchase;

                select
                    efd_header_id
                into p_header_id_anexo
                from
                    rmais_efd_headers
                where
                    access_key_number = rw.access_key_number_devolution;

                rmais_process_pkg_bkp_to_worflow.update_devolucao(p_header_id, p_header_id_anexo, rw.id_nd);
            exception
                when no_data_found then
                    update rmais_efd_headers
                    set
                        document_status = 'AP'
                    where
                        efd_header_id = p_header_id_anexo;

                    update rmais_notas_devolucao
                    set
                        status = 'AP',
                        data_update = sysdate
                    where
                        id_nd = rw.id_nd;

            end;
        end loop;
    end integrar_anexo_devolucao;
    --
    procedure get_fornecedor_apex (
        p_issuer_document_number    in out varchar2,
        p_efd_header_id             in out number,
        p_bu_name                   in out varchar2,
        p_issuer_name               in out varchar2,
        p_issuer_address            in out varchar2,
        p_issuer_address_number     in out varchar2,
        p_issuer_address_complement in out varchar2,
        p_issuer_address_city_code  in out varchar2,
        p_issuer_address_city_name  in out varchar2,
        p_issuer_address_zip_code   in out varchar2,
        p_issuer_address_state      in out varchar2,
        p_g_retcode                 in out varchar2
    ) as

        l_url      varchar2(300) := '/api/report/fornecedor/getFornecedor/';
        l_response clob;
        l_ctrl     varchar2(300);
        l_body     varchar2(600) := '{"cnpj": "'
                                || p_issuer_document_number
                                || '","bu": "$BU$"}';
--
    begin
  --
        declare
            l_bu varchar2(400);
        begin
    --
            if p_bu_name is null then
        --
                select
                    json_value(receiver_info, '$.DATA.BU_NAME')
                into l_bu
                from
                    rmais_efd_headers
                where
                    efd_header_id = p_efd_header_id;
        --
                l_body := replace(l_body, '$BU$', l_bu);
        --
            else
      --
                l_body := replace(l_body, '$BU$', p_bu_name);
      --
            end if;
    --
            null;
    --
        exception
            when others then
                l_body := replace(l_body, '$BU$', p_bu_name);
        end;
  --
        l_response := rmais_process_pkg_bkp_to_worflow.get_response(l_url, l_body);
  --
        if l_response not like '%PARTY_NAME%' then
    --
            begin
                select
                    *
                into
                    p_issuer_document_number,
                    p_issuer_name,
                    l_ctrl,
                    p_issuer_address,
                    p_issuer_address_number,
                    p_issuer_address_complement,
                    p_issuer_address_city_code,
                    p_issuer_address_city_name,
                    p_issuer_address_zip_code,
                    p_issuer_address_state
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
                            rmais_efd_headers
                        where
                            issuer_document_number = regexp_replace(p_issuer_document_number, '[^0-9]', '')
                        order by
                            creation_date desc
                    )
                where
                    rownum = 1;

                p_g_retcode := '';
            exception
                when others then
                    p_g_retcode := 'Fornecedor não localizado!';
            end;
        else
     --
            p_g_retcode := '';
    --
            begin
      --
                select distinct
                    p_tax_payer_number,
                    party_name,
                    party_name2,
                    address1,
                    address2,
                    address3,
                    address4,
                    city,
                    replace(postal_code, '-', ''),
                    state
                into
                    p_issuer_document_number,
                    p_issuer_name,
                    l_ctrl,
                    p_issuer_address,
                    p_issuer_address_number,
                    p_issuer_address_complement,
                    p_issuer_address_city_code,
                    p_issuer_address_city_name,
                    p_issuer_address_zip_code,
                    p_issuer_address_state
                from
                    json_table ( replace(
                        replace(l_response, '"DATA":{', '"DATA": [{'),
                        '}}}',
                        '}}]}'
                    ), '$'
                        columns (
                            nested path '$.DATA'
                                columns (
                                    p_tax_payer_number varchar2 ( 4000 ) path '$.P_TAX_PAYER_NUMBER',
                                    party_name varchar2 ( 4000 ) path '$.PARTY_NAME',
                                    party_name2 varchar2 ( 4000 ) path '$.PARTY_NAME',
                                    nested path '$.ADDRESS[*]'
                                        columns (
                                            address1 varchar2 ( 4000 ) path '$.ADDRESS1',
                                            address2 varchar2 ( 4000 ) path '$.ADDRESS2',
                                            address3 varchar2 ( 4000 ) path '$.ADDRESS3',
                                            address4 varchar2 ( 4000 ) path '$.ADDRESS4',
                                            city varchar2 ( 4000 ) path '$.CITY',
                                            postal_code varchar2 ( 4000 ) path '$.POSTAL_CODE',
                                            state varchar2 ( 4000 ) path '$.STATE',
                                            vendor_site_code varchar2 ( 4000 ) path '$.VENDOR_SITE_CODE'
                                        )
                                )
                        )
                    )
                where
                        vendor_site_code = p_issuer_document_number
                    and rownum = 1;

            exception
                when others then
       --
                    select distinct
                        p_tax_payer_number,
                        party_name,
                        party_name2,
                        address1,
                        address2,
                        address3,
                        address4,
                        city,
                        replace(postal_code, '-', ''),
                        state
                    into
                        p_issuer_document_number,
                        p_issuer_name,
                        l_ctrl,
                        p_issuer_address,
                        p_issuer_address_number,
                        p_issuer_address_complement,
                        p_issuer_address_city_code,
                        p_issuer_address_city_name,
                        p_issuer_address_zip_code,
                        p_issuer_address_state
                    from
                        json_table ( l_response, '$'
                            columns (
                                nested path '$.DATA'
                                    columns (
                                        p_tax_payer_number varchar2 ( 4000 ) path '$.P_TAX_PAYER_NUMBER',
                                        party_name varchar2 ( 4000 ) path '$.PARTY_NAME',
                                        party_name2 varchar2 ( 4000 ) path '$.PARTY_NAME',
                                        nested path '$.ADDRESS[*]'
                                            columns (
                                                address1 varchar2 ( 4000 ) path '$.ADDRESS1',
                                                address2 varchar2 ( 4000 ) path '$.ADDRESS2',
                                                address3 varchar2 ( 4000 ) path '$.ADDRESS3',
                                                address4 varchar2 ( 4000 ) path '$.ADDRESS4',
                                                city varchar2 ( 4000 ) path '$.CITY',
                                                postal_code varchar2 ( 4000 ) path '$.POSTAL_CODE',
                                                state varchar2 ( 4000 ) path '$.STATE',
                                                vendor_site_code varchar2 ( 4000 ) path '$.VENDOR_SITE_CODE'
                                            )
                                    )
                            )
                        )
                    where
                            vendor_site_code = p_issuer_document_number
                        and rownum = 1;
       --
            end;
    --
        end if;
  --
    exception
        when others then
            raise_application_error(-20011, 'Não foi possível consumir WS para busca de fornecedor');
    end get_fornecedor_apex;
    --
end rmais_process_pkg_bkp_to_worflow;
/


-- sqlcl_snapshot {"hash":"cb42945f1ff3d37567da6cc7e851621310ff0396","type":"PACKAGE_BODY","name":"RMAIS_PROCESS_PKG_BKP_TO_WORFLOW","schemaName":"RMAIS","sxml":""}