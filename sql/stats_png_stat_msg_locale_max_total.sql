SELECT DISTINCT MAX(result)
FROM
    (SELECT SUM(t_stats.msg) AS result
     FROM t_updates
         INNER JOIN t_stats ON t_updates.id = t_stats.id_update
         INNER JOIN t_locales ON t_updates.id_locale = t_locales.id
         INNER JOIN t_states ON t_stats.id_state = t_states.id
     WHERE t_updates.active = 1 AND t_stats.msg > 0 AND t_locales.name = 'LOCALE' AND t_states.name = 'total')
;
