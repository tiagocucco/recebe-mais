-- liquibase formatted sql
-- changeset RMAIS:1777295651852 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_grupo_acesso_dados.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_grupo_acesso_dados.sql:null:6e0610fa095416c4946c1216be10c813423677e4:create

create table tb_grupo_acesso_dados (
    id_grupo_acesso_dados number not null enable,
    desc_grupo            varchar2(50 byte)
);

create unique index tb_grupo_acesso_view_pk on
    tb_grupo_acesso_dados (
        id_grupo_acesso_dados
    );

alter table tb_grupo_acesso_dados
    add constraint tb_grupo_acesso_dados_pk primary key ( id_grupo_acesso_dados )
        using index tb_grupo_acesso_view_pk enable;

