create or replace type tp_fornecedores_obj as object (
        issuer_document_number    varchar2(15),
        issuer_name               varchar2(120),
        l_ctrl                    varchar2(300),
        issuer_address            varchar2(255),
        issuer_address_number     varchar2(60),
        issuer_address_complement varchar2(60),
        issuer_address_city_code  varchar2(60),
        issuer_address_city_name  varchar2(60),
        issuer_address_zip_code   number,
        issuer_address_state      varchar2(2)
);
/


-- sqlcl_snapshot {"hash":"20aff723b20709d4059c33f2784dc44de1d8f51c","type":"TYPE_SPEC","name":"TP_FORNECEDORES_OBJ","schemaName":"RMAIS","sxml":""}