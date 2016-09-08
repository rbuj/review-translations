SELECT DISTINCT MAX(result)
FROM
    (SELECT SUM(t_stats.msg) AS result
        FROM t_stats
            INNER JOIN t_updates ON t_stats.id_update = t_updates.id
            INNER JOIN t_locales ON t_updates.id_locale = t_locales.id
            INNER JOIN t_components ON t_updates.id_component = t_components.id
            INNER JOIN t_states ON t_stats.id_state = t_states.id
        WHERE t_updates.active = 1 AND t_states.name='total'
        GROUP BY t_locales.name)
;
