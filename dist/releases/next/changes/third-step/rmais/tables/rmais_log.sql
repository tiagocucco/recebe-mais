-- liquibase formatted sql
-- changeset RMAIS:1777295651324 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_log.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_log.sql:null:164a51b36470aa13d62e587f349a864bc623dd6e:create

create table rmais_log (
    dat timestamp(6),
    log varchar2(4000 byte)
);

