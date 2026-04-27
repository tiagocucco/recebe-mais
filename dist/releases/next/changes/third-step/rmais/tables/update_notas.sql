-- liquibase formatted sql
-- changeset RMAIS:1777295652016 stripComments:false  logicalFilePath:third-step\rmais\tables\update_notas.sql
-- sqlcl_snapshot src/database/rmais/tables/update_notas.sql:null:e70403f8dcb6ab92f2f33655f79f592d6669e995:create

create table update_notas (
    data_get date,
    msg      varchar2(10 byte)
);

