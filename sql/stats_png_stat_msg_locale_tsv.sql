SELECT t_components.name, t_states.name, t_stats.msg
FROM t_components
    INNER JOIN t_updates ON t_components.id = t_updates.id_component
    INNER JOIN t_locales ON t_updates.id_locale = t_locales.id
    INNER JOIN t_stats ON t_updates.id = t_stats.id_update
    INNER JOIN t_states ON t_stats.id_state = t_states.id
WHERE t_updates.id IN (
    SELECT t_updates.id
    FROM t_updates
        INNER JOIN t_stats ON t_updates.id = t_stats.id_update
        INNER JOIN t_locales ON t_updates.id_locale = t_locales.id
        INNER JOIN t_states ON t_stats.id_state = t_states.id
    WHERE t_updates.active = 1 AND t_stats.msg > 0 AND t_locales.name = 'LOCALE' AND t_states.name = 'translated')
ORDER BY t_components.name, t_states.name;
