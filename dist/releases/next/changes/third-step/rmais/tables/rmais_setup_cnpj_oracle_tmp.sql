-- liquibase formatted sql
-- changeset RMAIS:1777295651550 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_setup_cnpj_oracle_tmp.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_setup_cnpj_oracle_tmp.sql:null:ca203a6056d7671c366d5e74dac25fed6b8b188f:create

create table rmais_setup_cnpj_oracle_tmp (
    city                     varchar2(4000 byte),
    bu_id                    number,
    state                    varchar2(4000 byte),
    bu_name                  varchar2(4000 byte),
    address1                 varchar2(4000 byte),
    address2                 varchar2(4000 byte),
    address3                 varchar2(4000 byte),
    address4                 varchar2(4000 byte),
    cnpj_seq                 number,
    location_id              number,
    postal_code              varchar2(4000 byte),
    legal_entity_id          number,
    registered_name          varchar2(4000 byte),
    registered_name_le       varchar2(4000 byte),
    registration_number      number,
    registration_number_le   number,
    apex$sync_step_static_id varchar2(255 byte),
    apex$row_sync_timestamp  timestamp(6) with time zone,
    legal_entity_name        varchar2(4000 byte),
    addr_element_attribute2  number,
    classification_id        number,
    classification_code      varchar2(4000 byte),
    classification_name      varchar2(4000 byte),
    main_establishment_flag  varchar2(4000 byte),
    lru_name                 varchar2(4000 byte),
    cnpj_base                number
);

