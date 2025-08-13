-- Table simple pour stocker des données JSON
CREATE TABLE IF NOT EXISTS timesheet_data_json (
    id SERIAL PRIMARY KEY,
    data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index sur la date de création
CREATE INDEX IF NOT EXISTS idx_timesheet_data_json_created_at ON timesheet_data_json(created_at);

-- Index sur le champ validationRequestId dans le JSON
CREATE INDEX IF NOT EXISTS idx_timesheet_data_json_validation_request_id 
ON timesheet_data_json((data->>'validationRequestId')::int);

-- Index sur employeeId dans le JSON
CREATE INDEX IF NOT EXISTS idx_timesheet_data_json_employee_id 
ON timesheet_data_json((data->>'employeeId'));

-- Exemple d'insertion
-- INSERT INTO timesheet_data_json (data) VALUES (
--   '{"validationRequestId": 1, "employeeId": "john_doe", "employeeName": "John Doe", "entries": [...]}'::jsonb
-- );

-- Exemple de requête pour récupérer par validationRequestId
-- SELECT * FROM timesheet_data_json WHERE (data->>'validationRequestId')::int = 1;