comment on table rmais_user_groups is
    'Table for user groups in RecebeMais project.';

comment on column rmais_user_groups.group_id is
    'Unique identifier for the group.';

comment on column rmais_user_groups.group_name is
    'Name of the group.';

comment on column rmais_user_groups.status is
    'Status: Y=Active, N=Inactive.';


-- sqlcl_snapshot {"hash":"ee679a3d3f57e53a89cba114f0861fa1cf86c1db","type":"COMMENT","name":"rmais_user_groups","schemaName":"sch_rmais_dev","sxml":""}