SELECT t_components.name, t_states.name, t_stats.msg
    FROM t_updates
        INNER JOIN t_stats ON t_updates.id = t_stats.id_update
        INNER JOIN t_locales ON t_updates.id_locale = t_locales.id
        INNER JOIN t_states ON t_stats.id_state = t_states.id
        INNER JOIN t_components ON t_updates.id_component = t_components.id
    WHERE
	t_updates.active = 1 AND
        t_updates.id IN (
            SELECT DISTINCT t_components.id
            FROM t_components
                INNER JOIN t_updates ON t_updates.id_component = t_components.id
                INNER JOIN t_locales ON t_updates.id_locale = t_locales.id
                INNER JOIN t_stats ON t_stats.id_update = t_stats.id
                INNER JOIN t_states ON t_stats.id_state = t_states.id
            WHERE t_updates.active = 1 AND t_stats.msg > 0 AND t_states.name = 'translated' AND t_locales.name = 'LOCALE'
        )
    ORDER BY t_components.name, t_states.name;
