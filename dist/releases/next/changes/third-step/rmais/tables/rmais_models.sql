-- liquibase formatted sql
-- changeset RMAIS:1777295651407 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_models.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_models.sql:null:0832af95f34bec0e76e14b1f69fec75873e300bb:create

create table rmais_models (
    model          varchar2(2 byte) not null enable,
    model_name     varchar2(50 byte),
    digitavel      varchar2(1 byte),
    destination    varchar2(10 byte),
    lin_type       varchar2(2 byte),
    isv_model      varchar2(10 byte),
    bancada_boleto varchar2(1 byte),
    source         varchar2(200 byte),
    isv_name       varchar2(200 byte)
);

alter table rmais_models add constraint rmais_models_con1 unique ( model )
    using index enable;

