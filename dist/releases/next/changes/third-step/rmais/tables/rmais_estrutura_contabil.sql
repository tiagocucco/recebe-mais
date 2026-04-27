-- liquibase formatted sql
-- changeset RMAIS:1777295651132 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_estrutura_contabil.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_estrutura_contabil.sql:null:651afccb285caefa6fea2999fefb04232790de94:create

create table rmais_estrutura_contabil (
    lru                      varchar2(4000 byte),
    ledger_id                number,
    flex_value               varchar2(50 byte),
    description              varchar2(4000 byte),
    flex_value_id            number,
    legal_entity_id          number,
    flex_value_set_id        number,
    apex$sync_step_static_id varchar2(255 byte),
    apex$row_sync_timestamp  timestamp(6) with time zone
);

