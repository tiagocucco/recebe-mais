-- liquibase formatted sql
-- changeset RMAIS:1777295651637 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_temp_bfile.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_temp_bfile.sql:null:99fc1f64213569fca1f1a4ab0a6685b76be4028e:create

create global temporary table rmais_temp_bfile (
    b_file bfile
) on commit delete rows;

