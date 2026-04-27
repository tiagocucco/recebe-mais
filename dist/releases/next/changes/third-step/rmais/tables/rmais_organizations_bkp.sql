-- liquibase formatted sql
-- changeset RMAIS:1777295651459 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_organizations_bkp.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_organizations_bkp.sql:null:7534f5418ec8c268fb3b6293cccb5f7f021699f9:create

create table rmais_organizations_bkp (
    id               number not null enable,
    cliente_id       number not null enable,
    nome             varchar2(300 byte) not null enable,
    cnpj             varchar2(14 byte) not null enable,
    endereco         varchar2(600 byte),
    numero           number,
    compl            varchar2(80 byte),
    bairro           varchar2(100 byte),
    cidade           varchar2(100 byte),
    estado           varchar2(2 byte),
    cep              varchar2(10 byte),
    bu_flag          varchar2(1 byte),
    bu_code          varchar2(200 byte),
    last_update_date date
);

