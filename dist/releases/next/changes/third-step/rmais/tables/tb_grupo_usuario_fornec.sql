-- liquibase formatted sql
-- changeset RMAIS:1777295651898 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_grupo_usuario_fornec.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_grupo_usuario_fornec.sql:null:7f7ca1869593d32867b3f9eaa2212e14571a4ae4:create

create table tb_grupo_usuario_fornec (
    id_grupo_usuario       number,
    issuer_document_number varchar2(15 byte)
);

