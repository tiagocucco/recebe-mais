-- liquibase formatted sql
-- changeset RMAIS:1777295652027 stripComments:false  logicalFilePath:third-step\rmais\tables\xxrmais_invoice_lines.sql
-- sqlcl_snapshot src/database/rmais/tables/xxrmais_invoice_lines.sql:null:e7cd327f9bb37c8735532656439877e54fe4d318:create

create table xxrmais_invoice_lines (
    line_id     number not null enable,
    header_id   number not null enable,
    line_num    number not null enable,
    cod_produto varchar2(50 byte),
    des_produto varchar2(300 byte) not null enable,
    pedido      varchar2(50 byte),
    uom         varchar2(50 byte),
    qtde        number not null enable,
    valor_unit  number not null enable,
    valor_total number,
    ncm         varchar2(10 byte),
    cst         varchar2(6 byte),
    cfop        number,
    bc_icms     number,
    v_icms      number,
    v_ipi       number,
    aliq_icms   number,
    aliq_ipi    number
);

