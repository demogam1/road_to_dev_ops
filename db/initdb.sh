#!/bin/bash
set -euo pipefail

: "${POSTGRES_USER:=postgres}"      # fourni par l'image
: "${POSTGRES_DB:=app}"             # DB cible

# Connexion directe à la DB
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<SQL
---------------------------------------------------------------------
-- EXTENSIONS
---------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

---------------------------------------------------------------------
-- USERS
---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email       TEXT UNIQUE NOT NULL,
  password    TEXT NOT NULL,
  firstname   TEXT,
  lastname    TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

---------------------------------------------------------------------
-- SESSIONS / API TOKENS
---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_sessions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash   TEXT NOT NULL,
  user_agent   TEXT,
  ip_address   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at   TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires ON user_sessions(expires_at);

---------------------------------------------------------------------
-- TODO LISTS
---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS todo_lists (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_todo_lists_owner ON todo_lists(owner_id);

---------------------------------------------------------------------
-- TODOS
---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS todos (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  list_id      UUID NOT NULL REFERENCES todo_lists(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'todo',
  priority     SMALLINT NOT NULL DEFAULT 3,
  due_at       TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_status   CHECK (status IN ('todo','doing','done','archived')),
  CONSTRAINT chk_priority CHECK (priority BETWEEN 1 AND 5)
);

CREATE INDEX IF NOT EXISTS idx_todos_list ON todos(list_id);

---------------------------------------------------------------------
-- SHARING / PERMISSIONS
---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS todo_list_permissions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  list_id      UUID NOT NULL REFERENCES todo_lists(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role         TEXT NOT NULL,                      -- viewer / editor
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_role CHECK (role IN ('viewer','editor')),
  UNIQUE (list_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_permissions_user ON todo_list_permissions(user_id);

---------------------------------------------------------------------
-- AUDIT LOG
---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
  action      TEXT NOT NULL,
  target_id   UUID,
  details     JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_date ON audit_log(created_at);

---------------------------------------------------------------------
-- TRIGGER updated_at
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS \$\$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END
\$\$;

-- Sur users
DROP TRIGGER IF EXISTS trg_users_touch ON users;
CREATE TRIGGER trg_users_touch
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- Sur todo_lists
DROP TRIGGER IF EXISTS trg_todo_lists_touch ON todo_lists;
CREATE TRIGGER trg_todo_lists_touch
BEFORE UPDATE ON todo_lists
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- Sur todos
DROP TRIGGER IF EXISTS trg_todos_touch ON todos;
CREATE TRIGGER trg_todos_touch
BEFORE UPDATE ON todos
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
SQL
