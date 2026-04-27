-- liquibase formatted sql
-- changeset RMAIS:1777295651420 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_nf_reval.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_nf_reval.sql:null:59eed30d610bb765b80fc1b1abaca59bb9dbe0f6:create

create table rmais_nf_reval (
    efd_header_id number,
    start_date    date,
    end_date      date
);

