-- liquibase formatted sql
-- changeset RMAIS:1777295651536 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_reprocess_ctrl.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_reprocess_ctrl.sql:null:fbd11542dd4aa7c8d08b33f26bba5172d31e8e75:create

create table rmais_reprocess_ctrl (
    flag_reprocess_ctrl number,
    efd_header_id       number
);

