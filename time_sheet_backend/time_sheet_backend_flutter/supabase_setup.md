# Configuration Supabase pour le système de validation

## IMPORTANT : Système sans authentification

La table `users` existante nécessite l'authentification Supabase. Pour votre système sans authentification, nous utilisons une table `managers` séparée.

## 1. Créer la table des managers

Exécutez ce SQL dans l'éditeur SQL de Supabase :

```sql
-- Créer la table des managers
CREATE TABLE IF NOT EXISTS managers (
  id TEXT PRIMARY KEY,
  company TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Créer un index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_managers_company ON managers(company);

-- Activer RLS
ALTER TABLE managers ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre l'accès public (pas d'auth)
CREATE POLICY "Allow public read" ON managers
  FOR SELECT
  USING (true);

CREATE POLICY "Allow public insert" ON managers
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow public update" ON managers
  FOR UPDATE
  USING (true);

CREATE POLICY "Allow public delete" ON managers
  FOR DELETE
  USING (true);
```

## 2. Vérifier que le bucket storage existe

```sql
-- Le bucket 'validation-pdfs' doit exister
-- Si ce n'est pas le cas, créez-le dans Storage > Buckets
```

## 3. Tester la configuration

1. Dans votre app, allez dans les paramètres et configurez :
   - Prénom
   - Nom
   - Entreprise (important : tous les utilisateurs de la même entreprise doivent avoir exactement le même nom)

2. Activez le "Mode Manager" pour au moins un utilisateur

3. Sur un autre appareil/utilisateur avec la même entreprise, créez une demande de validation

## Dépannage

Si vous avez l'erreur "Erreur lors de la récupération des managers" :
- Vérifiez que la table `managers` existe dans Supabase
- Vérifiez que vous avez une connexion internet
- Vérifiez que l'entreprise est bien configurée dans les paramètres
- Assurez-vous qu'au moins un manager est enregistré pour votre entreprise