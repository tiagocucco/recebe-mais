-- liquibase formatted sql
-- changeset RMAIS:1777295652206 stripComments:false  logicalFilePath:third-step\rmais\tables\zx_rules_b.sql
-- sqlcl_snapshot src/database/rmais/tables/zx_rules_b.sql:null:180a09ae24428d9114a7c6ada670b0597f3a56b6:create

create table zx_rules_b (
    tax_rule_code              varchar2(120 byte),
    tax                        varchar2(120 byte),
    tax_regime_code            varchar2(120 byte),
    service_type_code          varchar2(120 byte),
    application_id             number(22, 0),
    recovery_type_code         varchar2(120 byte),
    priority                   number(22, 0),
    det_factor_templ_code      varchar2(120 byte),
    system_default_flag        varchar2(4 byte),
    effective_from             date,
    effective_to               date,
    enabled_flag               varchar2(4 byte),
    record_type_code           varchar2(120 byte),
    creation_date              timestamp(6),
    last_update_date           timestamp(6),
    request_id                 number(22, 0),
    tax_event_class_code       varchar2(120 byte),
    program_login_id           number(22, 0),
    tax_rule_id                number(22, 0),
    content_owner_id           number(22, 0),
    created_by                 varchar2(256 byte),
    last_updated_by            varchar2(256 byte),
    last_update_login          varchar2(128 byte),
    object_version_number      number(22, 0),
    determining_factor_cq_code varchar2(120 byte),
    geography_type             varchar2(120 byte),
    geography_id               number(22, 0),
    tax_law_ref_code           varchar2(120 byte),
    last_update_mode_flag      varchar2(4 byte),
    never_been_enabled_flag    varchar2(4 byte),
    event_class_mapping_id     number(22, 0),
    program_name               varchar2(120 byte),
    program_app_name           varchar2(200 byte),
    tax_status_code            varchar2(120 byte),
    reporting_type_code        varchar2(120 byte),
    periodicity_code           varchar2(120 byte)
);

