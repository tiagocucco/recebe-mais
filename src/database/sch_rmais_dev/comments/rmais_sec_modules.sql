comment on table rmais_sec_modules is
    'Tabela de módulos funcionais do sistema para governança e segurança por domínio funcional.';

comment on column rmais_sec_modules.created_by is
    'Usuário responsável pela criação do registro.';

comment on column rmais_sec_modules.creation_date is
    'Data de criação do registro.';

comment on column rmais_sec_modules.description is
    'Descrição funcional do módulo.';

comment on column rmais_sec_modules.display_order is
    'Ordem de exibição do módulo nas telas administrativas.';

comment on column rmais_sec_modules.icon_class is
    'Classe de ícone (ex.: fa-file-invoice, fa-cogs, fa-users).';

comment on column rmais_sec_modules.inactive_date is
    'Data de inativação do módulo.';

comment on column rmais_sec_modules.is_system is
    'Indica se o módulo é sistêmico e protegido contra exclusão lógica. Y=Sim, N=Não.';

comment on column rmais_sec_modules.module_code is
    'Código técnico único do módulo (ex.: FISCAL, OPERACOES, DOCUMENTOS).';

comment on column rmais_sec_modules.module_id is
    'Identificador único do módulo.';

comment on column rmais_sec_modules.module_name is
    'Nome funcional do módulo exibido ao usuário.';

comment on column rmais_sec_modules.status is
    'Status do módulo: Y=Ativo, N=Inativo.';

comment on column rmais_sec_modules.updated_by is
    'Usuário responsável pela última atualização do registro.';

comment on column rmais_sec_modules.updated_date is
    'Data da última atualização do registro.';


-- sqlcl_snapshot {"hash":"d25e4929b120c812526a23ae37d933975947166a","type":"COMMENT","name":"rmais_sec_modules","schemaName":"sch_rmais_dev","sxml":""}