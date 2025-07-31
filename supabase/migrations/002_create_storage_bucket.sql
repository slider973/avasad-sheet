-- Créer le bucket pour les PDFs de validation
INSERT INTO storage.buckets (id, name, public)
VALUES ('validation-pdfs', 'validation-pdfs', false)
ON CONFLICT (id) DO NOTHING;

-- Politique pour permettre aux employés d'uploader leurs PDFs
CREATE POLICY "Employees can upload their PDFs"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'validation-pdfs' AND
  auth.uid()::text = (storage.foldername(name))[3] -- Le 3ème segment est l'employee_id
);

-- Politique pour permettre aux employés de voir leurs propres PDFs
CREATE POLICY "Employees can view their PDFs"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'validation-pdfs' AND
  auth.uid()::text = (storage.foldername(name))[3]
);

-- Politique pour permettre aux managers de voir les PDFs qu'ils doivent valider
CREATE POLICY "Managers can view PDFs for validation"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'validation-pdfs' AND
  EXISTS (
    SELECT 1 FROM validation_requests
    WHERE pdf_path = name
    AND manager_id = auth.uid()
  )
);

-- Politique pour permettre aux employés de supprimer leurs PDFs en attente
CREATE POLICY "Employees can delete pending PDFs"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'validation-pdfs' AND
  auth.uid()::text = (storage.foldername(name))[3] AND
  EXISTS (
    SELECT 1 FROM validation_requests
    WHERE pdf_path = name
    AND status = 'pending'
  )
);