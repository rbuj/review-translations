SELECT COUNT(t_locales.name)
    FROM t_locales
    WHERE
        t_locales.id IN (
            SELECT t_updates.id_locale FROM t_updates
                INNER JOIN t_stats ON t_updates.id = t_stats.id_update
                INNER JOIN t_states ON t_stats.id_state = t_states.id
            WHERE t_updates.active = 1 AND t_states.name='translated' AND t_stats.msg > 0);
