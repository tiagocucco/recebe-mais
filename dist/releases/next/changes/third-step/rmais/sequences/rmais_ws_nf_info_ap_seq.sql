-- liquibase formatted sql
-- changeset RMAIS:1777295650128 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_ws_nf_info_ap_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_ws_nf_info_ap_seq.sql:null:d724a878c2996b658b6def027507dc7576f1504a:create

create sequence rmais_ws_nf_info_ap_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder
nocycle nokeep noscale global;

