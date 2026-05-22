comment on table rmais_sec_group_module_perm is
    'Relaciona grupos aos módulos e define as permissões funcionais (capabilities) por módulo.';

comment on column rmais_sec_group_module_perm.admin_flag is
    'Permite administração avançada do módulo.';

comment on column rmais_sec_group_module_perm.approve_flag is
    'Permite aprovação/liberação no módulo.';

comment on column rmais_sec_group_module_perm.created_by is
    'Usuário responsável pela criação do registro.';

comment on column rmais_sec_group_module_perm.creation_date is
    'Data de criação do registro.';

comment on column rmais_sec_group_module_perm.delete_flag is
    'Permite exclusão no módulo.';

comment on column rmais_sec_group_module_perm.edit_flag is
    'Permite criação/edição de dados no módulo.';

comment on column rmais_sec_group_module_perm.group_id is
    'Identificador do grupo de usuários.';

comment on column rmais_sec_group_module_perm.group_module_perm_id is
    'Identificador único do relacionamento grupo x módulo.';

comment on column rmais_sec_group_module_perm.inactive_date is
    'Data de inativação do vínculo.';

comment on column rmais_sec_group_module_perm.module_id is
    'Identificador do módulo funcional.';

comment on column rmais_sec_group_module_perm.process_flag is
    'Permite processamento/reprocessamento no módulo.';

comment on column rmais_sec_group_module_perm.status is
    'Status do vínculo: Y=Ativo, N=Inativo.';

comment on column rmais_sec_group_module_perm.updated_by is
    'Usuário responsável pela última atualização do registro.';

comment on column rmais_sec_group_module_perm.updated_date is
    'Data da última atualização do registro.';

comment on column rmais_sec_group_module_perm.view_flag is
    'Permite visualização/consulta no módulo.';


-- sqlcl_snapshot {"hash":"cea896add7d34f4a0b225e88f0ef110ee1f1bcea","type":"COMMENT","name":"rmais_sec_group_module_perm","schemaName":"sch_rmais_dev","sxml":""}