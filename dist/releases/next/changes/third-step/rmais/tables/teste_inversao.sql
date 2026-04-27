-- liquibase formatted sql
-- changeset RMAIS:1777295652008 stripComments:false  logicalFilePath:third-step\rmais\tables\teste_inversao.sql
-- sqlcl_snapshot src/database/rmais/tables/teste_inversao.sql:null:5e599294b01703c5ecbbdf230f3bc48cfd49feb1:create

create table teste_inversao (
    idade  varchar2(4 char),
    altura varchar2(4 char)
);

