CREATE TABLE IF NOT EXISTS t_projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    'project' TEXT NOT NULL UNIQUE,
    'date_file' INTEGER DEFAULT 0,
    'date_report' INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS t_locales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    'locale' TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS t_updates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    'id_project' INTEGER,
    'id_locale' INTEGER,
    'date_file' INTEGER DEFAULT 0,
    'date_report' INTEGER DEFAULT 0,
    UNIQUE(id_project, id_locale) ON CONFLICT IGNORE,
    FOREIGN KEY(id_project) REFERENCES t_projects(id),
    FOREIGN KEY(id_locale) REFERENCES t_locales(id)
);
