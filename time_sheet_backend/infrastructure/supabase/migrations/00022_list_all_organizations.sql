-- ============================================================================
-- 00022_list_all_organizations.sql
-- `list_child_organizations()` (00010) ne retourne que les organisations
-- AYANT un parent (`parent_id IS NOT NULL`). Elle alimente le sélecteur
-- d'organisation à l'inscription (onboarding_page.dart:60 et
-- preference_form-v2.dart:170).
--
-- Conséquence : une organisation RACINE est invisible à l'inscription. Cas
-- réel du 2026-08-01 — « Interiman » est créée comme racine, un nouvel employé
-- ne peut donc pas s'y rattacher lui-même, et reste avec organization_id NULL
-- (donc incapable de soumettre la moindre validation, cf. create-validation
-- qui refuse un employé sans organisation).
--
-- Correctif : retourner TOUTES les organisations actives, racines comprises.
-- Le nom de la fonction devient un abus de langage, mais il est conservé pour
-- ne pas toucher aux deux appels côté Flutter.
--
-- NB (non traité ici, à décider) : cette RPC est aussi grantée à `anon`, ce
-- qui laisse énumérer anonymement les noms des organisations clientes.
-- L'onboarding se fait pourtant toujours authentifié (OnboardingPage n'est
-- atteinte qu'avec une session). Un `REVOKE ... FROM anon` serait cohérent
-- avec le durcissement 00021, mais mérite un test de l'inscription d'abord.
--
-- Migration idempotente.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.list_child_organizations()
RETURNS TABLE(id UUID, name TEXT) AS $$
  SELECT o.id, o.name
  FROM public.organizations o
  WHERE o.is_active = true
  ORDER BY o.name;
$$ LANGUAGE sql SECURITY DEFINER STABLE;
