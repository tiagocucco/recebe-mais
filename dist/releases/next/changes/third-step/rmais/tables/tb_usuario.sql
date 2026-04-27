-- liquibase formatted sql
-- changeset RMAIS:1777295651958 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_usuario.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_usuario.sql:null:a2580e03165c00e6073531123dcb7b0b40430da2:create

create table tb_usuario (
    id_usuario            number not null enable,
    id_grupo_usuario      number,
    nome_comp             varchar2(100 byte),
    nome_curto            varchar2(20 byte),
    email                 varchar2(100 byte),
    nome_usuario          varchar2(30 byte),
    password              varchar2(50 byte),
    rmais                 number default 0,
    id_grupo_acesso_dados number
);

create unique index tb_usuario_pk on
    tb_usuario (
        id_usuario
    );

alter table tb_usuario
    add constraint tb_usuario_pk primary key ( id_usuario )
        using index tb_usuario_pk enable;

alter table tb_usuario add constraint tb_usuario_uk1 unique ( nome_usuario )
    using index enable;

