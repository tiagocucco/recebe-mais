-- liquibase formatted sql
-- changeset RMAIS:1777295652068 stripComments:false  logicalFilePath:third-step\rmais\tables\zx_condition_details.sql
-- sqlcl_snapshot src/database/rmais/tables/zx_condition_details.sql:null:966835c8aaf7c886ceffe7f30c45af6d01c1c63f:create

create table zx_condition_details (
    condition_detail_id           number(22, 0),
    condition_id                  number(22, 0),
    condition_group_code          varchar2(200 byte),
    determining_factor_class_code varchar2(120 byte),
    determining_factor_cq_code    varchar2(120 byte),
    determining_factor_code       varchar2(120 byte),
    operator_code                 varchar2(120 byte),
    tax_regime_code               varchar2(120 byte),
    tax_parameter_code            varchar2(120 byte),
    data_type_code                varchar2(120 byte),
    numeric_value                 number(22, 0),
    date_value                    date,
    alphanumeric_value            varchar2(4000 byte),
    record_type_code              varchar2(120 byte),
    creation_date                 timestamp(6),
    last_update_date              timestamp(6),
    request_id                    number(22, 0),
    program_login_id              number(22, 0),
    created_by                    varchar2(256 byte),
    last_updated_by               varchar2(256 byte),
    last_update_login             varchar2(128 byte),
    object_version_number         number(22, 0),
    program_name                  varchar2(120 byte),
    program_app_name              varchar2(200 byte)
);

