-- liquibase formatted sql
-- changeset RMAIS:1777295649970 stripComments:false  logicalFilePath:third-step\rmais\sequences\rmais_efd_distributions_s.sql
-- sqlcl_snapshot src/database/rmais/sequences/rmais_efd_distributions_s.sql:null:9759e838d49e90979927d03ec4e8466f7fa3229d:create

create sequence rmais_efd_distributions_s minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 /* start with n */ cache 20
noorder nocycle nokeep noscale global;

