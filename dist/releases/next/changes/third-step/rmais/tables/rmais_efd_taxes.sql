-- liquibase formatted sql
-- changeset RMAIS:1777295651092 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_efd_taxes.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_efd_taxes.sql:null:96699fb4ed5c0aa627a62f877ecb00908895f81f:create

create table rmais_efd_taxes (
    id                   number,
    efd_line_id          number not null enable,
    condition_group_code varchar2(100 byte),
    tax_rate_code        varchar2(100 byte),
    tax_regime_code      varchar2(100 byte),
    tax                  varchar2(100 byte),
    rate_type_code       varchar2(100 byte),
    percentage_rate      number,
    active_flag          varchar2(1 byte),
    attribute1           varchar2(1000 byte),
    attribute2           varchar2(1000 byte),
    attribute3           varchar2(1000 byte),
    attribute4           varchar2(1000 byte),
    attribute5           varchar2(1000 byte),
    attribute6           varchar2(1000 byte),
    creation_date        date not null enable,
    update_date          date,
    determining_factor   varchar2(1000 byte),
    base_rate            number
);

alter table rmais_efd_taxes add unique ( id )
    using index enable;

