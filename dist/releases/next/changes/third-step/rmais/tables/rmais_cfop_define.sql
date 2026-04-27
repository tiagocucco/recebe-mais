-- liquibase formatted sql
-- changeset RMAIS:1777295650444 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_cfop_define.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_cfop_define.sql:null:b335a926dfc490f3f914c574a5f9ab79fab813ac:create

create table rmais_cfop_define (
    cfop          varchar2(4 byte),
    descricao     varchar2(400 byte),
    tipo          varchar2(100 byte),
    creation_date date
);

alter table rmais_cfop_define add unique ( cfop )
    using index enable;

