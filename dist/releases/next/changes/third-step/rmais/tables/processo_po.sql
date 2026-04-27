-- liquibase formatted sql
-- changeset RMAIS:1777295650231 stripComments:false  logicalFilePath:third-step\rmais\tables\processo_po.sql
-- sqlcl_snapshot src/database/rmais/tables/processo_po.sql:null:c6b17d0c3503a4771f1380caabfa9179ca03adc1:create

create table processo_po (
    num_processo number,
    sessao       number,
    data         date
);

alter table processo_po
    add constraint processo_po_pk primary key ( num_processo )
        using index enable;

