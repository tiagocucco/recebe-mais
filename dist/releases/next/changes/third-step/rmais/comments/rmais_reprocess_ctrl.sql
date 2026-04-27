-- liquibase formatted sql
-- changeset rmais:1777295649614 stripComments:false  logicalFilePath:third-step\rmais\comments\rmais_reprocess_ctrl.sql
-- sqlcl_snapshot src/database/rmais/comments/rmais_reprocess_ctrl.sql:null:acaba6311734df05da6cfa88afcf9844ec8da6c4:create

comment on column rmais_reprocess_ctrl.flag_reprocess_ctrl is
    '1-JOB REPROCESS_WAITING_CREATE_DOC';

