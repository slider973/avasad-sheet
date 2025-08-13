-- Script de test pour la table timesheet_data
-- Exécutez ce script dans votre base de données PostgreSQL

-- 1. Vérifier si la table existe
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE  table_schema = 'public'
   AND    table_name   = 'timesheet_data'
);

-- 2. Afficher la structure de la table
\d timesheet_data

-- 3. Insérer des données de test
INSERT INTO timesheet_data (
    validation_request_id,
    employee_id,
    employee_name,
    employee_company,
    month,
    year,
    entries,
    total_days,
    total_hours,
    total_overtime_hours,
    created_at,
    updated_at
) VALUES (
    1,
    'john_doe',
    'John Doe',
    'Avasad',
    7,
    2024,
    '[{"dayDate":"21-Jun-24","startMorning":"08:00","endMorning":"12:00","startAfternoon":"13:00","endAfternoon":"17:00","isAbsence":false,"hasOvertimeHours":false}]',
    20.0,
    '160:00',
    '0:00',
    NOW(),
    NOW()
) ON CONFLICT (validation_request_id) 
DO UPDATE SET 
    entries = EXCLUDED.entries,
    total_days = EXCLUDED.total_days,
    total_hours = EXCLUDED.total_hours,
    total_overtime_hours = EXCLUDED.total_overtime_hours,
    updated_at = NOW();

-- 4. Vérifier les données
SELECT * FROM timesheet_data WHERE validation_request_id = 1;

-- 5. Exemple de requête pour récupérer et décoder les entries JSON
SELECT 
    id,
    validation_request_id,
    employee_name,
    month,
    year,
    entries::json as entries_json,
    total_hours
FROM timesheet_data 
WHERE validation_request_id = 1;