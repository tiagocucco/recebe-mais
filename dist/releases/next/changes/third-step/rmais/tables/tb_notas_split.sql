-- liquibase formatted sql
-- changeset RMAIS:1777295651937 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_notas_split.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_notas_split.sql:null:3b4f7ef0ea27a98ed43ca965148d684bf4e8d04b:create

create table tb_notas_split (
    efd_header_id number,
    efd_line_id   number,
    unit_price    number,
    line_quantity number,
    line_amount   number
);

