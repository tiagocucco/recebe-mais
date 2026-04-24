alter table tb_usuario_logs
    add constraint tb_usuario_logs_fk1
        foreign key ( id_usuario )
            references tb_usuario ( id_usuario )
                on delete cascade
        enable;


-- sqlcl_snapshot {"hash":"7818f9d89629ad1824e33d904c6fa2028a146704","type":"REF_CONSTRAINT","name":"TB_USUARIO_LOGS_FK1","schemaName":"RMAIS","sxml":""}