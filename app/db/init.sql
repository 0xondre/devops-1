-- Uruchom jako użytkownik postgres (np. z Ansible: community.postgresql)
-- CREATE USER notes_user WITH PASSWORD 'zmien_mnie';
-- CREATE DATABASE notes_db OWNER notes_user;
-- Następnie połącz się z notes_db i wykonaj poniższe:

CREATE TABLE IF NOT EXISTS notes (
    id         SERIAL PRIMARY KEY,
    content    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT ALL PRIVILEGES ON TABLE notes TO notes_user;
GRANT USAGE, SELECT ON SEQUENCE notes_id_seq TO notes_user;
