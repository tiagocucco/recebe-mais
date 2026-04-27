-- liquibase formatted sql
-- changeset RMAIS:1777295651842 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_grupo_ac_dados_org.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_grupo_ac_dados_org.sql:null:f596615a359f56449faf52083b62441d3243d3ac:create

create table tb_grupo_ac_dados_org (
    id_grupo_acesso_dados number,
    id_org                number
);

