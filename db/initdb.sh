#!/bin/bash
set -euo pipefail

: "${POSTGRES_USER:=postgres}"         # fourni par l'image
: "${POSTGRES_DB:=app}"                # DB cible (docker-compose fournit aussi POSTGRES_DB)

# Connexion directe à la DB (créée automatiquement par l’image postgres si POSTGRES_DB est défini)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<SQL
-- Extension UUID (si tu veux des id UUID plutôt qu’en série)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Table TODO basique
CREATE TABLE IF NOT EXISTS todos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  description TEXT,
  status      TEXT NOT NULL DEFAULT 'todo',     -- todo / doing / done / archived
  priority    SMALLINT NOT NULL DEFAULT 3,      -- 1=haut, 3=normal, 5=bas
  due_at      TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_status CHECK (status IN ('todo','doing','done','archived')),
  CONSTRAINT chk_priority CHECK (priority BETWEEN 1 AND 5)
);

-- Déclencheur pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS \$$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END
\$$;

DROP TRIGGER IF EXISTS trg_todos_touch ON todos;
CREATE TRIGGER trg_todos_touch
BEFORE UPDATE ON todos
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
SQL
