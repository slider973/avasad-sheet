# Test de la nouvelle architecture PDF avec signature

## Architecture implémentée

### 1. Génération côté client
- Le PDF est généré côté client avec la signature du manager récupérée depuis Isar
- Utilisation de `GeneratePdfUseCase` existant avec les paramètres de signature
- La signature est encodée en base64 pour la transmission

### 2. Transmission au serveur
- Le PDF complet (avec signature) est envoyé au serveur lors de l'approbation
- Nouvelle méthode `approveValidationWithSignedPdf` dans le repository
- Le serveur reçoit le PDF en `List<int>` via Serverpod

### 3. Stockage côté serveur
- Le serveur remplace simplement l'ancien PDF par le nouveau PDF signé
- Plus aucune signature n'est stockée en base de données
- Le PDF signé est sauvegardé dans `/tmp/` avec un nom unique

## Points clés de l'implémentation

### ApproveValidationUseCase
```dart
// Récupération de la signature depuis Isar
final managerSignatureBytes = await getSignatureUseCase.execute();

// Génération du PDF avec signature
final pdfParams = GeneratePdfParams(
  monthNumber: month,
  year: year,
  managerSignature: base64Encode(managerSignatureBytes),
  managerName: managerName,
);

final pdfResult = await generatePdfUseCase.call(pdfParams);

// Envoi au serveur
return await repository.approveValidationWithSignedPdf(
  validationId: params.validationId,
  signedPdfBytes: pdfBytes,
  managerName: managerName,
  comment: params.comment,
);
```

### Endpoint Serverpod
```dart
Future<ValidationRequest> approveValidation(
  Session session,
  int validationId,
  String managerName,
  String? comment,
  List<int>? signedPdfBytes, // PDF signé optionnel
) async {
  // Si un PDF signé est fourni, le sauvegarder
  if (signedPdfBytes != null && signedPdfBytes.isNotEmpty) {
    final fileName = 'timesheet_${validationId}_approved_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '/tmp/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(signedPdfBytes);
    validation.pdfPath = filePath;
  }
  // ...
}
```

## Avantages de cette approche

✅ **Sécurité** : La signature reste uniquement en local (Isar)
✅ **Performance** : Pas de génération PDF côté serveur
✅ **Simplicité** : Le serveur reçoit un PDF prêt à l'emploi
✅ **Réutilisation** : Utilise les use cases existants
✅ **Cohérence** : Même processus de génération PDF que pour l'employé

## Flux complet

1. Manager clique sur "Approuver"
2. Le système récupère la signature du manager depuis Isar
3. Le PDF est généré côté client avec toutes les données et la signature
4. Le PDF complet est envoyé au serveur
5. Le serveur sauvegarde le PDF et met à jour le statut de validation
6. Le PDF signé est maintenant disponible pour téléchargement

## Migration effectuée

- Suppression de la colonne `managerSignature` de la table `validation_requests`
- Migration SQL créée et appliquée
- Tous les endpoints mis à jour pour ne plus utiliser cette colonne

## Tests à effectuer

1. Créer une validation
2. Approuver avec signature
3. Télécharger le PDF approuvé
4. Vérifier que la signature apparaît bien dans le PDF
5. Vérifier qu'aucune signature n'est stockée en BDD