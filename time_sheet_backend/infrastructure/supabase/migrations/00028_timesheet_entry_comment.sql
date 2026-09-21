-- ============================================================================
-- 00028_timesheet_entry_comment.sql
-- Commentaire libre saisi par l'employé sur une journée de pointage.
--
-- Motif : la colonne « Commentaires » du relevé de temps PDF existe depuis
-- l'origine (generate_pdf_usecase.dart, _buildTableHeader), mais elle n'a
-- jamais été alimentable par l'utilisateur. `_getCommentaire(day)` n'y place
-- que le motif d'une absence — une journée travaillée sort donc toujours avec
-- une cellule vide, alors que c'est précisément là qu'un employé veut
-- justifier un horaire inhabituel (déplacement, intervention, retard).
--
-- Portée : une ligne de `timesheet_entries` représente UN jour pour UN
-- utilisateur (invariant formalisé par la contrainte unique de la migration
-- 00027). Le commentaire appartient donc naturellement à cette table plutôt
-- qu'à une table dédiée : pas de cardinalité à gérer, pas de jointure
-- supplémentaire dans la génération du PDF, et la donnée suit l'entrée dans
-- toutes les suppressions existantes.
--
-- Nullable et sans valeur par défaut : les 838 lignes existantes conservent
-- NULL, que le code Flutter lit déjà comme chaîne vide (`as String? ?? ''`).
-- Aucune réécriture de données, aucun verrou long — ADD COLUMN sans DEFAULT
-- ne réécrit pas la table sous PostgreSQL 11+.
--
-- RLS — aucune policy à ajouter : les policies de `timesheet_entries`
-- s'appliquent à la ligne entière, pas colonne par colonne. L'employé qui
-- peut déjà écrire sa journée peut donc écrire son commentaire, et le manager
-- qui la lit via `manager_employees` le lit aussi. Vérifié : aucune policy de
-- cette table n'énumère de colonnes.
--
-- Synchronisation PowerSync — `powersync.yaml` reste inchangé : la bucket
-- `user_data` sélectionne `SELECT * FROM timesheet_entries WHERE user_id =
-- bucket.user_id`, et `manager_data` fait de même pour l'équipe. Une nouvelle
-- colonne est donc diffusée sans édition des sync rules. Seul
-- `schema.dart` (couche 4) doit déclarer la colonne, faute de quoi PowerSync
-- l'ignore silencieusement côté client.
--
-- Longueur : volontairement non contrainte. Le PDF rend la cellule en police 6
-- dans une colonne étroite ; c'est la couche de présentation qui tronque, pas
-- la base, afin qu'un commentaire long reste consultable dans l'application et
-- dans l'app web.
-- ============================================================================

ALTER TABLE public.timesheet_entries
  ADD COLUMN IF NOT EXISTS comment text;

COMMENT ON COLUMN public.timesheet_entries.comment IS
  'Commentaire libre de l''employé sur la journée. Rendu dans la colonne '
  '« Commentaires » du relevé PDF, à la suite du motif d''absence éventuel.';

-- NB : l'enregistrement dans `public.schema_migrations` se fait manuellement
-- APRÈS application (cf. CLAUDE.md).
