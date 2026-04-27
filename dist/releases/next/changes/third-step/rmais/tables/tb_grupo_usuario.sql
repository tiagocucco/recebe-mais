-- liquibase formatted sql
-- changeset RMAIS:1777295651867 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_grupo_usuario.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_grupo_usuario.sql:null:bbe13a1da627c296a09629b400d76aee59e9dd31:create

create table tb_grupo_usuario (
    id_grupo_usuario number not null enable,
    desc_grupo_usu   varchar2(50 byte),
    rmais            number default 0
);

create unique index tb_grupo_usuario_pk on
    tb_grupo_usuario (
        id_grupo_usuario
    );

alter table tb_grupo_usuario
    add constraint tb_grupo_usuario_pk primary key ( id_grupo_usuario )
        using index tb_grupo_usuario_pk enable;

