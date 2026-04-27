-- liquibase formatted sql
-- changeset RMAIS:1777295650059 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_match_bu_types_seq.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_match_bu_types_seq.sql:null:676ac3b18153f041b34d2a2d9ae677a3ae1ff607:create

create sequence rmais_match_bu_types_seq minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20 noorder
nocycle nokeep noscale global;

