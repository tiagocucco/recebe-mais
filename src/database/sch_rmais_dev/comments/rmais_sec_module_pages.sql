comment on table rmais_sec_module_pages is
    'Relaciona módulos funcionais às páginas do APEX, definindo composição funcional e navegação.';

comment on column rmais_sec_module_pages.access_id is
    'Identificador da página (catálogo técnico em RMAIS_USERS_ACCESS).';

comment on column rmais_sec_module_pages.created_by is
    'Usuário responsável pela criação do registro.';

comment on column rmais_sec_module_pages.creation_date is
    'Data de criação do registro.';

comment on column rmais_sec_module_pages.display_order is
    'Ordem de exibição da página dentro do módulo.';

comment on column rmais_sec_module_pages.inactive_date is
    'Data de inativação do vínculo.';

comment on column rmais_sec_module_pages.is_default is
    'Indica se é a página padrão (landing page) do módulo. Y=Sim, N=Não.';

comment on column rmais_sec_module_pages.module_id is
    'Identificador do módulo funcional.';

comment on column rmais_sec_module_pages.module_page_id is
    'Identificador único do relacionamento módulo x página.';

comment on column rmais_sec_module_pages.show_in_menu is
    'Indica se a página deve aparecer na navegação/menu do módulo. Y=Sim, N=Não.';

comment on column rmais_sec_module_pages.status is
    'Status do vínculo: Y=Ativo, N=Inativo.';

comment on column rmais_sec_module_pages.updated_by is
    'Usuário responsável pela última atualização do registro.';

comment on column rmais_sec_module_pages.updated_date is
    'Data da última atualização do registro.';


-- sqlcl_snapshot {"hash":"a0a859eee2dd5bffdf41736ebb2b70821067a67d","type":"COMMENT","name":"rmais_sec_module_pages","schemaName":"sch_rmais_dev","sxml":""}