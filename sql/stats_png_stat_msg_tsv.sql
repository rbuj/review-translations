SELECT t_locales.name, t_states.name, SUM(t_stats.msg)
    FROM t_updates
        INNER JOIN t_stats ON t_updates.id = t_stats.id_update
        INNER JOIN t_locales ON t_updates.id_locale = t_locales.id
        INNER JOIN t_states ON t_stats.id_state = t_states.id
    WHERE
	t_updates.active = 1 AND
        t_locales.id IN (
            SELECT DISTINCT t_locales.id
            FROM t_stats
                INNER JOIN t_updates ON t_stats.id_update = t_updates.id
                INNER JOIN t_locales ON t_updates.id_locale = t_locales.id
                INNER JOIN t_states ON t_stats.id_state = t_states.id
            WHERE t_updates.active = 1 AND t_stats.msg > 0 AND t_states.name = 'translated'
        )
    GROUP BY t_states.name, t_locales.name
    ORDER BY t_locales.name;
