-- liquibase formatted sql
-- changeset RMAIS:1777295650120 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_ws_info_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_ws_info_s.sql:null:afcce82b39549d41da3806d84a750fe6e6893902:create

create sequence rmais_ws_info_s minvalue 1 maxvalue 999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder nocycle
nokeep noscale global;

