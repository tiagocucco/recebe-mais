-- liquibase formatted sql
-- changeset RMAIS:1777295651808 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_acesso.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_acesso.sql:null:c8071f921b09823c1a2838943a72990aa854959e:create

create table tb_acesso (
    id_acesso   number not null enable,
    desc_acesso varchar2(100 byte),
    num_seq     number,
    desc_n1     varchar2(120 byte),
    desc_n2     varchar2(120 byte),
    desc_n3     varchar2(120 byte),
    n1          number,
    n2          number,
    n3          number,
    icon1       varchar2(30 byte),
    icon2       varchar2(30 byte),
    icon3       varchar2(30 byte),
    rmais       number
);

create unique index tb_acesso_pk on
    tb_acesso (
        id_acesso
    );

alter table tb_acesso
    add constraint tb_acesso_pk primary key ( id_acesso )
        using index tb_acesso_pk enable;

