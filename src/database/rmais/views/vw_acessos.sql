create or replace force editionable view vw_acessos (
    id,
    parent_id,
    title,
    value,
    type,
    tooltip,
    icon,
    selected,
    expanded,
    checkbox,
    unselectable
) as
    with tp_grupos_usuarios_ac as (
        select
            *
        from
            tb_grupos_usuarios_ac
        where
            id_grupo_usuario = v('P504_ID_G')
    ), tp_ac as (
        select
            *
        from
            tb_acessos
        where
            nvl(flag_tipo,
                v('P504_FLAG_TIPO')) = v('P504_FLAG_TIPO')
    ), tp_acessos as (
        select
            lpad(a.n1, 2, '0') id,
            '0'                as parent_id,
            a.desc_n1          title,
            null               value,
            1                  type,
            null               tooltip,
            a.icon1            as icon,
            0                  selected,
            null               expanded,
            1                  checkbox,
            0                  as unselectable
        from
            tp_ac a
        where
            a.desc_n1 is not null -- Remover após implantação
        group by
            a.n1,
            a.desc_n1,
            a.icon1
        union all
        select
            lpad(a.n1, 2, 00)
            || lpad(a.n2, 3, '0') id,
            lpad(a.n1, 2, 00)     as parent_id,
            a.desc_n2             title,
            null                  value,
            2                     type,
            null                  tooltip,
            a.icon2               as icon,
            0                     selected,
            null                  expanded,
            1                     checkbox,
            0                     as unselectable
        from
            tp_ac a
        where
            a.desc_n1 is not null -- Remover após implantação
        group by
            a.n1,
            a.n2,
            a.desc_n2,
            a.icon2
        union all
        select
            lpad(a.n1, 2, 00)
            || lpad(a.n2, 3, '0')
            || lpad(a.n3, 3, '0') id,
            lpad(a.n1, 2, 00)
            || lpad(a.n2, 3, '0') as parent_id,
            a.desc_n3
            || ' ('
            || a.id_acesso
            || ')'                title,
            a.id_acesso           value,
            3                     type,
            null                  tooltip,
            case
                when a.icon3 is null then
                    'fa-padlock'
                else
                    a.icon3
            end                   as icon,
            case
                when b.id_acesso is not null then
                    1
            end                   selected,
            null                  expanded,
            1                     checkbox,
            0                     as unselectable
        from
            tp_ac                 a,
            tp_grupos_usuarios_ac b
        where
                a.id_acesso = b.id_acesso (+)
            and a.desc_n1 is not null -- Remover após implantação)
    )
    select
        id,
        parent_id,
        title,
        value,
        type,
        tooltip,
        'fa ' || icon icon,
        selected,
        expanded,
        checkbox,
        unselectable
    from
        tp_acessos
    order by
        id;


-- sqlcl_snapshot {"hash":"3c329291023898a19281bf5c97ec95952696ff7c","type":"VIEW","name":"VW_ACESSOS","schemaName":"RMAIS","sxml":""}