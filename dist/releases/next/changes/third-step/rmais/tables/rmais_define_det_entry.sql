-- liquibase formatted sql
-- changeset RMAIS:1777295650568 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_define_det_entry.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_define_det_entry.sql:null:9d6fa3b9f3430745c0039521810deaa863407214:create

create table rmais_define_det_entry (
    id                      number not null enable,
    priority                number not null enable,
    type                    varchar2(100 byte) not null enable,
    value1                  varchar2(300 byte) not null enable,
    created_by              varchar2(500 byte),
    creation_date           date,
    updated_by              varchar2(500 byte),
    last_update_date        date,
    model                   varchar2(4 byte),
    source_doc              varchar2(2 byte),
    item                    varchar2(100 byte),
    conta                   varchar2(100 byte),
    flag_retention          varchar2(1 byte),
    flag_nf_op              varchar2(1 byte),
    combinacao_contabil_ger varchar2(100 byte),
    paymentmethod           varchar2(30 byte)
);

alter table rmais_define_det_entry
    add constraint rmais_define_det_entry_pk primary key ( id )
        using index enable;

