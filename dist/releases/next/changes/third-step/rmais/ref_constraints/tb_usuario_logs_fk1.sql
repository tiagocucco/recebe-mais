-- liquibase formatted sql
-- changeset RMAIS:1777295649809 stripComments:false  logicalFilePath:third-step\rmais\ref_constraints\tb_usuario_logs_fk1.sql
-- sqlcl_snapshot src/database/rmais/ref_constraints/tb_usuario_logs_fk1.sql:null:7818f9d89629ad1824e33d904c6fa2028a146704:create

alter table tb_usuario_logs
    add constraint tb_usuario_logs_fk1
        foreign key ( id_usuario )
            references tb_usuario ( id_usuario )
                on delete cascade
        enable;

