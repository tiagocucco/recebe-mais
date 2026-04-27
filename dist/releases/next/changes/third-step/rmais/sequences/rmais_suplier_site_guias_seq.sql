-- liquibase formatted sql
-- changeset RMAIS:1777295650084 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_suplier_site_guias_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_suplier_site_guias_seq.sql:null:ca543a6670c82e615095875cb0a54254f539fc6a:create

create sequence rmais_suplier_site_guias_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache
20 noorder nocycle nokeep noscale global;

