-- liquibase formatted sql
-- changeset RMAIS:1777295651498 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_period_entry.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_period_entry.sql:null:5b187fe5f617dfe7d6cfa748e551022effd62290:create

create table rmais_period_entry (
    date_ini      date,
    date_fim      date,
    user_create   varchar2(300 byte),
    creation_date date
);

