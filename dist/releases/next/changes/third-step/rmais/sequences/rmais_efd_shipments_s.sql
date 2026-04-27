-- liquibase formatted sql
-- changeset RMAIS:1777295649996 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_efd_shipments_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_efd_shipments_s.sql:null:1c28f93be6cca2ba501d724e4700594224903fac:create

create sequence rmais_efd_shipments_s minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder
nocycle nokeep noscale global;

