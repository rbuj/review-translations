CREATE TABLE IF NOT EXISTS t_locales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    'name' TEXT NOT NULL UNIQUE ON CONFLICT IGNORE
);

CREATE TABLE IF NOT EXISTS t_components (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    'name' TEXT NOT NULL UNIQUE ON CONFLICT IGNORE
);

CREATE TABLE IF NOT EXISTS t_states (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    'name' TEXT NOT NULL UNIQUE ON CONFLICT IGNORE
);

CREATE TABLE IF NOT EXISTS t_updates (
    id INTEGER PRIMARY KEY,
    'id_component' INTEGER,
    'id_locale' INTEGER,
    'date_file' INTEGER DEFAULT 0,
    'date_report' INTEGER DEFAULT 0,
    'active' INTEGER DEFAULT 0,
    UNIQUE(id_component, id_locale) ON CONFLICT IGNORE,
    FOREIGN KEY(id_locale) REFERENCES t_locales(id),
    FOREIGN KEY(id_component) REFERENCES t_components(id)
);

UPDATE t_updates SET active = 0;

CREATE TABLE IF NOT EXISTS t_stats (
    id INTEGER PRIMARY KEY,
    'id_update' INTEGER,
    'id_state' INTEGER,
    'msg' INTEGER,
    'msg_div_tot' TEXT,
    'w_or' INTEGER,
    'w_div_tot_or' TEXT,
    'w_tr' INTEGER,
    'ch_or' INTEGER,
    'ch_tr' INTEGER,
    UNIQUE(id_update, id_state) ON CONFLICT IGNORE,
    FOREIGN KEY(id_update) REFERENCES t_updates(id),
    FOREIGN KEY(id_state) REFERENCES t_states(id)
);
