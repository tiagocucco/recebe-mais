create or replace package body rmais_global_pkg is
  --
  /*=========================================================================+
  |                                                                          |
  | Packate:   RMAIS_util_pkg                                                   |
  |                                                                          |
  | Description: Esta package é utilizada para controlar informações globais |
  |              do processo de Integração DFE-Receiver X Oracle EBS         |
  |                                                                          |
  |  Criado por Crystian S. Bezerra - 01/08/2016                             |
  |                                                                          |
  |  Alterado por Crystian S. Bezerra - 21/02/2019                           |
  |  #001 Ajuste da package para corrigir problemas de ENCODING no ambiente  |
  |                                                                          |
  |                                                                          |
  +=========================================================================*/
  ---
    procedure print (
        p_msg clob
    ) is
        ixi number := 0;
        ixf number := 32000;
    begin
    --
        g_log := g_log
                 || chr(10)
                 || p_msg;
    --
        while nvl(ixf, 0) > 0 loop
      --
            if g_enable_log = 'Y' then
        --
                dbms_output.put_line(substr(p_msg, 1, 3500));
        --
            end if;
      --
            ixi := ixi + 32000;
      --
            if nvl(
                length(substr(p_msg, ixi)),
                0
            ) < 32000 then
        --
                ixf := length(substr(p_msg, ixi));
        --
            end if;
      --
        end loop;
    --
    exception
        when others then
            if g_enable_log = 'Y' then
        --
                dbms_output.put_line('Erro Print: ' || substr(p_msg, 1, 50));
        --
            end if;
    end print;
  --
    function get_nls (
        pget varchar2 default 'NLS_CHARACTERSET'
    ) return varchar2 is
        vret nls_database_parameters.value%type;
    begin
    --
        select
            value
        into vret
        from
            nls_database_parameters
        where
            parameter = pget;
    --
        return vret;
    --
    exception
        when others then
            return null;
    end;
  --
    function get_charset (
        pchrset varchar2 default null
    ) return number is
    begin
        return nvl(
            nls_charset_id(nvl(pchrset, get_nls)),
            dbms_lob.default_csid
        );
    end;
  --
    procedure info (
        pmsg varchar2
    ) is
    begin
    --
        print(' ');
        print(rpad('-',
                   length(pmsg) + 8,
                   '-'));
        print('--- '
              || pmsg || ' ---');
        print(rpad('-',
                   length(pmsg) + 8,
                   '-'));
    --
    end;
  --
    procedure clearglobal is
    begin
    --
        g_tipo := '';
        g_ftp_host := '';
        g_ftp_port := '';
        g_ftp_user := '';
        g_ftp_pwd := '';
        g_ftp_root := '';
        g_serie := '';
        g_dir_name := '';
        g_dir_path := '';
        g_dir_path_temp := '';
        g_dir_path_even := '';
        g_dir_path_proc := '';
        g_dir_path_pend := '';
        g_dir_invalid := '';
        g_dir_noxml := '';
  --g_Errbuf        := '';
  --g_Retcode       := '';
  --g_enable_log    := '';
    --
    end;
  --
    function getclob return clob is
    begin
        return g_clob;
    end;
  --
    function getblob return blob is
    begin
        return g_blob;
    end;
  --
    procedure padstring (
        p_text in out nocopy varchar2
    ) is
        l_units number;
    begin
    --
        if length(p_text) mod 8 > 0 then
            l_units := trunc(length(p_text) / 8) + 1;
            p_text := rpad(p_text, l_units * 8, g_pad_chr);
        end if;
    --
    exception
        when others then
            dbms_output.put_line(p_text);
    end;
  --
    function get_dfe_path (
        pcode   varchar2,
        psufixo varchar2 := ''
    ) return varchar2 is
    begin
    --
        for r in (
            select
                cast(p.source as varchar2(4000)) directory_path,
                p.control                        directory_name,
                p.context                        description,
                p.text_value                     attribute1,
                p.text_value2                    attribute2,
                p.text_value3                    attribute3,
                p.text_value4                    attribute4,
                p.text_value5                    attribute5,
                p.text_value6                    attribute6,
                p.text_value7                    attribute7,
                p.text_value8                    attribute8,
                p.text_value9                    attribute9
            from
                rmais_source_ctrl p
            where
                p.control like 'RMAIS_DFE%'
                and p.control = pcode || psufixo
        ) loop
      --
            print(rpad(pcode || psufixo, 20, '.')
                  || ':'
                  || r.directory_path
                  || ':' || r.description);
      --
            if pcode = 'RMAIS_DFE_SERIE' then
        --
                return r.attribute1;
        --
            end if;
      --
            if pcode || psufixo = 'RMAIS_DFE_FTP' then
        --
                g_ftp_host := r.attribute2;
                g_ftp_port := r.attribute3;
                g_ftp_user := r.attribute4;
                g_ftp_pwd := r.attribute5;
                g_ftp_root := r.attribute6;
        --
            end if;
      --
            return nvl(r.attribute1, r.directory_path);
      --
        end loop;
    --
        return '';
    --
    exception
        when others then
            print('Get_DFE_Path Error: ' || sqlerrm);
            return '';
    end;
  --
    procedure init (
        ptipo varchar2
    ) is
    begin
    --
        g_tipo := nvl(ptipo, 'FTP');
    --
        print('Carregando os diretórios de '
              || g_tipo || '...');
    --
        g_dir_name := 'RMAIS_DFE_' || g_tipo;
    --
        g_serie := get_dfe_path('RMAIS_DFE_SERIE');
        g_dir_path_temp := get_dfe_path('RMAIS_DFE_FTP');
        g_dir_invalid := get_dfe_path('RMAIS_DFE_INVALID');
        g_dir_noxml := get_dfe_path('RMAIS_DFE_NOXML');
        g_dir_dflt_proc := get_dfe_path('RMAIS_DFE_PRO');
        g_dir_dflt_pend := get_dfe_path('RMAIS_DFE_DIR');
    --
        g_dir_path := get_dfe_path(g_dir_name);
        g_dir_path_even := get_dfe_path(g_dir_name, '_EVEN');
        g_dir_path_proc := get_dfe_path(g_dir_name, '_PROC');
        g_dir_path_pend := get_dfe_path(g_dir_name, '_PEND');
    --
        print('');
        print('g_Serie........:' || g_serie);
        print('g_Dir_Name.....:' || g_dir_name);
        print('g_Dir_Path.....:' || g_dir_path);
        print('g_Dir_Path_Even:' || g_dir_path_even);
        print('g_Dir_Path_Proc:' || g_dir_path_proc);
        print('g_Dir_Path_Pend:' || g_dir_path_pend);
        print('g_Dir_Path_Temp:' || g_dir_path_temp);
        print('g_Dir_Invalid..:' || g_dir_invalid);
        print('g_Dir_NOXML....:' || g_dir_noxml);
        print('g_Dir_Dflt_Pend:' || g_dir_dflt_pend);
        print('g_Dir_Dflt_Proc:' || g_dir_dflt_proc);
    --
        begin
      --
            dbms_session.set_nls('NLS_NUMERIC_CHARACTERS', '''.,''');
      --
        exception
            when others then
                null;
        end;
    --
    exception
        when others then
            print('Init...' || sqlerrm);
    end;
  --
    function gerador_cod_confirma return varchar2 is
        vn varchar2(50);
    begin
        vn := dbms_random.string('U', 2)
              || round(dbms_random.value(10, 99));

        return vn;
    end; 
  ---
end rmais_global_pkg;
/


-- sqlcl_snapshot {"hash":"841aac91576d28c916f85ec157d7d2d4535e516a","type":"PACKAGE_BODY","name":"RMAIS_GLOBAL_PKG","schemaName":"RMAIS","sxml":""}