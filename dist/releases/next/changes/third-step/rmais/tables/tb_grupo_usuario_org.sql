-- liquibase formatted sql
-- changeset RMAIS:1777295651909 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_grupo_usuario_org.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_grupo_usuario_org.sql:null:f452f62b486b909433d5cbf704e2651a91a268f4:create

create table tb_grupo_usuario_org (
    id_grupo_usuario number,
    id_org           number
);

