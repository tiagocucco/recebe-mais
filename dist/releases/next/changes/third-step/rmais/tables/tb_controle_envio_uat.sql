-- liquibase formatted sql
-- changeset RMAIS:1777295651827 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_controle_envio_uat.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_controle_envio_uat.sql:null:89e90087afa7999ecfa810328ec84fe1eae8b5c4:create

create table tb_controle_envio_uat (
    header_id number,
    headers   number
);

