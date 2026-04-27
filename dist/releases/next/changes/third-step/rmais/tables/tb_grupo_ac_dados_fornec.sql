-- liquibase formatted sql
-- changeset RMAIS:1777295651835 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_grupo_ac_dados_fornec.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_grupo_ac_dados_fornec.sql:null:fa26a13965efab3bacd2758d6324258ad16c2546:create

create table tb_grupo_ac_dados_fornec (
    id_grupo_acesso_dados  number,
    issuer_document_number varchar2(15 byte)
);

