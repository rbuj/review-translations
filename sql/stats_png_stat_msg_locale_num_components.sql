SELECT COUNT(t_components.name)
    FROM t_components
    WHERE
        t_components.id IN (
            SELECT t_updates.id_component FROM t_updates
                INNER JOIN t_stats ON t_updates.id = t_stats.id_update
                INNER JOIN t_states ON t_stats.id_state = t_states.id
                INNER JOIN t_components ON t_updates.id_component = t_components.id
                INNER JOIN t_locales ON t_updates.id_locale = t_locales.id
            WHERE t_updates.active = 1 AND t_states.name='translated' AND t_stats.msg > 0 AND t_locales.name = 'LOCALE');
