-- liquibase formatted sql
-- changeset RMAIS:1777295651288 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_item_info.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_item_info.sql:null:0da3a5bca6b4251c58d8bed0ba48559a304563ee:create

create table rmais_item_info (
    transation_id          number,
    organization_name      varchar2(400 byte),
    item_number            varchar2(400 byte),
    unit_of_measure        varchar2(400 byte),
    description            varchar2(1000 byte),
    catalog_code           varchar2(400 byte),
    ncm                    varchar2(400 byte),
    prod_fiscal_class_type varchar2(400 byte)
);

alter table rmais_item_info add unique ( transation_id )
    using index enable;

