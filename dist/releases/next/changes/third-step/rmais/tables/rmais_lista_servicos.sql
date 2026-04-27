-- liquibase formatted sql
-- changeset RMAIS:1777295651310 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_lista_servicos.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_lista_servicos.sql:null:e6ef7b7f59a311a75268d3135a1a26d5db8901e8:create

create table rmais_lista_servicos (
    codigo_servico varchar2(10 byte),
    descricao      varchar2(500 byte)
);

alter table rmais_lista_servicos add unique ( codigo_servico )
    using index enable;

