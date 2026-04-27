-- liquibase formatted sql
-- changeset RMAIS:1777295651883 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_grupo_usuario_ac.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_grupo_usuario_ac.sql:null:137d7bff482beb7bd7855ca793d77cc22de86b91:create

create table tb_grupo_usuario_ac (
    id_grupo_usuario     number not null enable,
    num_grupo_usuario_ac number not null enable,
    id_acesso            number
);

create unique index tb_grupo_usuario_ac_pk on
    tb_grupo_usuario_ac (
        id_grupo_usuario,
        num_grupo_usuario_ac
    );

alter table tb_grupo_usuario_ac
    add constraint tb_grupo_usuario_ac_pk
        primary key ( id_grupo_usuario,
                      num_grupo_usuario_ac )
            using index tb_grupo_usuario_ac_pk enable;

