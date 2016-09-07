SELECT COUNT(result)
    FROM
        (SELECT t_locales.name AS result, SUM(t_stats.w_or) AS sum_w_or
            FROM t_stats
                INNER JOIN t_updates ON t_stats.id_update = t_updates.id
                INNER JOIN t_locales ON t_updates.id_locale = t_locales.id
                INNER JOIN t_components ON t_updates.id_component = t_components.id
                INNER JOIN t_states ON t_stats.id_state = t_states.id
                WHERE t_updates.active = 1 AND t_states.name='translated'
            GROUP BY t_locales.name)
    WHERE sum_w_or > 0;
