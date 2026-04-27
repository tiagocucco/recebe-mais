-- liquibase formatted sql
-- changeset RMAIS:1777295651048 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_efd_serv_cod.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_efd_serv_cod.sql:null:8b1a1ff79e6898acc1d984001d035b6f04347da7:create

create table rmais_efd_serv_cod (
    cod_cidade       number not null enable,
    desc_cidade      varchar2(500 byte),
    serv_num_pref    number not null enable,
    serv_num_univ    varchar2(20 byte) not null enable,
    descr            varchar2(1000 byte),
    created_by       number,
    create_date      date,
    updated_by       number,
    last_update_date date
);

