-- liquibase formatted sql
-- changeset RMAIS:1777295651983 stripComments:false  logicalFilePath:third-step\rmais\tables\tb_usuario_logs.sql
-- sqlcl_snapshot src/database/rmais/tables/tb_usuario_logs.sql:null:07b97ceb0759882b0f887dab8d6f23988b66295b:create

create table tb_usuario_logs (
    id_usuario   number,
    num_log      number,
    data_entrada date,
    data_saida   date,
    app_id       number
);

alter table tb_usuario_logs
    add constraint tb_usuario_logs_pk primary key ( id_usuario,
                                                    num_log )
        using index enable;

