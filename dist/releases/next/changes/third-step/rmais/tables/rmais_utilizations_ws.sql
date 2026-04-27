-- liquibase formatted sql
-- changeset RMAIS:1777295651750 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_utilizations_ws.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_utilizations_ws.sql:null:fb5e5a9bc1711ec2807c2f4afeeec5711e9b8ddb:create

create table rmais_utilizations_ws (
    classification_id        number,
    classification_code      varchar2(4000 byte),
    classification_name      varchar2(4000 byte),
    apex$sync_step_static_id varchar2(255 byte),
    apex$row_sync_timestamp  timestamp(6) with time zone,
    name                     varchar2(4000 byte),
    term_id                  number,
    due_days                 number,
    description              varchar2(4000 byte),
    due_percent              number,
    sequence_num             number,
    discount_days            number,
    discount_percent         number
);

