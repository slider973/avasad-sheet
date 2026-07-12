-- ============================================================================
-- 00015_harden_validation_rls.sql
-- Durcir la sécurité du workflow de validation (architecture: PowerSync direct
-- côté client + RLS comme garde-fou ; approve/expire via Edge Functions service_role).
--
-- Ferme 3 trous des policies actuelles (00004) :
--   A) 🔴 validations_update autorise l'EMPLOYÉ -> il peut écrire status='approved'
--         sur sa propre demande = AUTO-APPROBATION.
--   B) 🟠 validations_insert ne contraint pas status -> insertion d'une demande
--         déjà 'approved'.
--   C) 🟠 manager_employees_insert n'autorise que manager/admin -> l'employé ne
--         peut pas créer la relation à la soumission, donc le manager ne reçoit
--         jamais la validation via sa bucket PowerSync manager_data.
--
-- ⚠️ À REVOIR avant application en prod (modifie la sécurité de la base).
-- Companion code: retirer l'upsert client de manager_employees dans
--   validation_repository_supabase_impl.dart (~l.78-99) — désormais géré par trigger.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) INSERT : l'employé ne crée QUE des demandes 'pending' qui le concernent,
--    et ne peut pas s'auto-désigner manager.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "validations_insert" ON public.validation_requests;
CREATE POLICY "validations_insert" ON public.validation_requests
  FOR INSERT WITH CHECK (
    employee_id = auth.uid()
    AND status = 'pending'
    AND manager_id <> auth.uid()
  );

-- ---------------------------------------------------------------------------
-- 2) UPDATE : l'employé ne peut PLUS modifier sa validation.
--    Rejet = UPDATE PowerSync par le manager assigné (status='rejected').
--    Approve = Edge Function approve-validation (service_role -> bypass RLS).
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "validations_update" ON public.validation_requests;
CREATE POLICY "validations_update" ON public.validation_requests
  FOR UPDATE
  USING (
    manager_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(employee_id))
  )
  WITH CHECK (
    manager_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(employee_id))
  );

-- ---------------------------------------------------------------------------
-- 3) Garde-fou (défense en profondeur) : transitions de statut valides + pas de
--    réassignation des parties. Les Edge Functions (service_role) ont autorité.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_validation_update()
RETURNS trigger AS $$
BEGIN
  -- Edge Functions (approve-validation, check-expired) = autorité serveur
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- Interdire la réassignation employé/manager
  IF NEW.employee_id <> OLD.employee_id OR NEW.manager_id <> OLD.manager_id THEN
    RAISE EXCEPTION 'Réassignation employé/manager interdite';
  END IF;

  -- Changement de statut : seulement depuis 'pending', et par le manager assigné
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF OLD.status <> 'pending' THEN
      RAISE EXCEPTION 'Validation déjà "%", statut non modifiable', OLD.status;
    END IF;
    IF auth.uid() <> OLD.manager_id
       AND NOT public.is_super_admin()
       AND NOT (public.is_org_admin() AND public.is_same_org(OLD.employee_id)) THEN
      RAISE EXCEPTION 'Seul le manager assigné peut changer le statut';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

DROP TRIGGER IF EXISTS trg_guard_validation_update ON public.validation_requests;
CREATE TRIGGER trg_guard_validation_update
  BEFORE UPDATE ON public.validation_requests
  FOR EACH ROW EXECUTE FUNCTION public.guard_validation_update();

-- ---------------------------------------------------------------------------
-- 4) Fiabiliser manager_employees : la relation est créée AUTOMATIQUEMENT côté
--    serveur à la création d'une validation (remplace l'upsert client bloqué par
--    RLS). SECURITY DEFINER -> contourne RLS de manager_employees.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.link_manager_on_validation()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.manager_employees (manager_id, employee_id)
  VALUES (NEW.manager_id, NEW.employee_id)
  ON CONFLICT (manager_id, employee_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

DROP TRIGGER IF EXISTS trg_link_manager_on_validation ON public.validation_requests;
CREATE TRIGGER trg_link_manager_on_validation
  AFTER INSERT ON public.validation_requests
  FOR EACH ROW EXECUTE FUNCTION public.link_manager_on_validation();
