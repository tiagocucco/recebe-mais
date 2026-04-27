-- liquibase formatted sql
-- changeset RMAIS:1777295650284 stripComments:false  logicalFilePath:third-step\rmais\tables\rmais_backup_user_rules.sql
-- sqlcl_snapshot src/database/rmais/tables/rmais_backup_user_rules.sql:null:51b6e4bd205db9636b17fda40c7e410a42150969:create

create table rmais_backup_user_rules (
    id_app    number,
    user_name varchar2(100 byte),
    rules     varchar2(4000 byte) not null enable,
    data      date not null enable
);

alter table rmais_backup_user_rules
    add constraint rmais_backup_user_rules_pk
        primary key ( id_app,
                      user_name,
                      rules,
                      data )
            using index enable;

