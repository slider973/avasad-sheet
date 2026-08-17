-- ============================================================================
-- 00027_timesheet_entries_unique_day.sql
-- Unicité d'un pointage par utilisateur et par jour.
--
-- Motif : la saisie de pointage depuis l'application web est aujourd'hui
-- IMPOSSIBLE. `useUpsertTimesheetEntry` (timesheet-web, use-timesheet.ts)
-- écrit ainsi :
--
--     .upsert(entry, { onConflict: 'user_id,day_date' })
--
-- PostgreSQL exige une contrainte unique — ou un index d'exclusion —
-- correspondant à la spécification `ON CONFLICT`. `timesheet_entries` ne
-- portait que `timesheet_entries_pkey` (id) et la clé étrangère `user_id`,
-- son seul index sur `user_id` n'étant PAS unique. Chaque enregistrement
-- échouait donc en 42P10 :
--     « there is no unique or exclusion constraint matching the
--       ON CONFLICT specification »
--
-- Cette contrainte ne crée pas une règle nouvelle : elle formalise en base
-- l'invariant que l'application Flutter applique déjà côté client
-- (`saveTimeSheet`, local_powersync.dart : SELECT sur (user_id, day_date),
-- puis UPDATE si la ligne existe, INSERT sinon). Un utilisateur n'a qu'une
-- seule entrée par jour — c'est le modèle métier depuis l'origine, jusqu'ici
-- garanti uniquement par convention.
--
-- État vérifié en production avant écriture (2026-08-17) :
--   838 lignes, 0 doublon sur (user_id, day_date), 0 NULL sur ces colonnes.
-- La contrainte s'applique donc sans nettoyage préalable. La table est
-- petite : le verrou ACCESS EXCLUSIVE pris par ADD CONSTRAINT est négligeable
-- (pas de CREATE INDEX CONCURRENTLY, qui interdirait l'idempotence en bloc).
--
-- Impact synchronisation — aucun changement requis côté PowerSync :
--   * Pas de nouvelle table ni colonne : `powersync.yaml` et `schema.dart`
--     restent inchangés (couches 3 et 4 du workflow db-migration).
--   * Risque théorique : deux appareils hors ligne créant chacun une ligne
--     pour le même jour produiraient un conflit à l'upload. Ce cas est déjà
--     traité — `supabase_connector.dart` liste `23505` (unique_violation)
--     parmi les `_nonRecoverablePostgresCodes` : l'opération est ignorée et
--     journalisée, la file d'upload n'est jamais bloquée ni rejouée en
--     boucle. Le comportement se dégrade proprement.
--
-- Ce que cette migration NE corrige PAS : la génération de PDF reste absente
-- du web (aucune bibliothèque PDF dans timesheet-web). Le web sait télécharger
-- et signer un PDF existant, pas en produire un.
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conrelid = 'public.timesheet_entries'::regclass
       AND conname  = 'timesheet_entries_user_id_day_date_key'
  ) THEN
    ALTER TABLE public.timesheet_entries
      ADD CONSTRAINT timesheet_entries_user_id_day_date_key
      UNIQUE (user_id, day_date);
  END IF;
END
$$;

-- L'index unique créé par la contrainte couvre (user_id, day_date) et rend
-- `idx_timesheet_user` redondant pour les recherches préfixées par user_id.
-- Il est conservé volontairement : le supprimer sort du périmètre de ce
-- correctif et se décide au vu des plans d'exécution réels.

-- NB : l'enregistrement dans `public.schema_migrations` se fait manuellement
-- APRÈS application (cf. CLAUDE.md).
