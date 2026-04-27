-- liquibase formatted sql
-- changeset RMAIS:1777295649987 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_efd_lines_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_efd_lines_s.sql:null:5324b799cceb09113810bf2a3691f5729adf67b3:create

create sequence rmais_efd_lines_s minvalue 1 maxvalue 9999999999 increment by 1 /* start with n */ nocache noorder cycle nokeep noscale
global;

