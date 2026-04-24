create or replace force editionable view rmais_vw_acessos (
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
    with tp_grupo_usuario_ac as (
        select
            b1.*
        from
            tb_grupo_usuario_ac b1
        where
            b1.id_grupo_usuario = v('P1001_ID_G')
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
            tb_acesso a
        where
            a.desc_n1 is not null -- Remover após implantação
            and ( nvl(
                v('F_RMAIS'),
                0
            ) = 1
                  or ( v('F_RMAIS') is null
                       and a.rmais = 0 ) )
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
            tb_acesso a
        where
            ( nvl(
                v('F_RMAIS'),
                0
            ) = 1
              or ( v('F_RMAIS') is null
                   and a.rmais = 0 ) )
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
            || lpad(a.n2, 3, '0') parent_id,
            a.desc_n3             title, --||' ('||A.ID_ACESSO||')'
            a.id_acesso           value,
            3                     type,
            null                  tooltip,
            case
                when a.icon3 is null then
                    null
                else
                    a.icon3
            end                   icon,
            case
                when b.id_acesso is not null then
                    1
            end                   selected,
            null                  expanded,
            1                     checkbox,
            0                     as unselectable
        from
            tb_acesso           a,
            tp_grupo_usuario_ac b
        where
                a.id_acesso = b.id_acesso (+)
            and ( nvl(
                v('F_RMAIS'),
                0
            ) = 1
                  or ( v('F_RMAIS') is null
                       and a.rmais = 0 ) )
    )
    select
        a.id,
        a.parent_id,
        a.title,
        a.value,
        a.type,
        a.tooltip,
        'fa ' || a.icon icon,
        a.selected,
        a.expanded,
        a.checkbox,
        a.unselectable
    from
        tp_acessos a
    order by
        a.id;


-- sqlcl_snapshot {"hash":"33acb86c6cba3d9b8bb149723ba77ff52d0cf632","type":"VIEW","name":"RMAIS_VW_ACESSOS","schemaName":"RMAIS","sxml":""}