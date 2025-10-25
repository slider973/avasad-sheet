# Guide de Dépannage - Permissions des Rappels de Pointage

## 🔧 Problème : L'application ne détecte pas les permissions activées

### Symptômes
- Vous avez activé les notifications dans les paramètres système
- L'application continue d'afficher que les rappels sont désactivés
- Le bouton d'activation des rappels ne fonctionne pas

### Solutions

#### Solution 1 : Redémarrage de l'application
1. Fermez complètement l'application (pas seulement la mettre en arrière-plan)
2. Rouvrez l'application
3. Allez dans Paramètres > Rappels de Pointage
4. L'application devrait maintenant détecter les permissions

#### Solution 2 : Vérification des permissions système
1. **Sur iOS :**
   - Allez dans Réglages > Notifications
   - Trouvez "Time Sheet" dans la liste
   - Vérifiez que "Autoriser les notifications" est activé
   - Vérifiez que les options de style sont configurées

2. **Sur Android :**
   - Allez dans Paramètres > Applications > Time Sheet
   - Appuyez sur "Autorisations" ou "Permissions"
   - Vérifiez que "Notifications" est autorisé

#### Solution 3 : Réinitialisation des paramètres de rappels
1. Dans l'application, allez dans Paramètres > Rappels de Pointage
2. Si les rappels sont activés, désactivez-les
3. Fermez et rouvrez l'application
4. Réessayez d'activer les rappels

## 🔄 Fonctionnement de la Détection Automatique

L'application vérifie automatiquement les permissions dans les cas suivants :

### Au Démarrage de la Page
- Quand vous ouvrez la page des rappels de pointage
- Vérifie si les rappels activés ont toujours les permissions nécessaires
- Désactive automatiquement les rappels si les permissions ont été révoquées

### Retour au Premier Plan
- Quand vous revenez dans l'application après l'avoir mise en arrière-plan
- Détecte si vous avez activé les permissions dans les paramètres système
- Affiche un message vous proposant d'activer les rappels si les permissions sont maintenant accordées

### Messages d'Information
L'application affiche différents messages selon la situation :

- **Permissions accordées** : "Les permissions de notification sont maintenant accordées. Vous pouvez activer les rappels."
- **Permissions révoquées** : "Les rappels ont été désactivés car les permissions de notification ont été révoquées."

## 📱 Instructions Spécifiques par Plateforme

### iOS
1. **Première activation :**
   - L'application demande automatiquement les permissions
   - Appuyez sur "Autoriser" dans la popup système

2. **Si refusé initialement :**
   - Allez dans Réglages > Notifications > Time Sheet
   - Activez "Autoriser les notifications"
   - Revenez dans l'application
   - Un message vous proposera d'activer les rappels

3. **Permissions révoquées :**
   - Les rappels se désactivent automatiquement
   - Réactivez dans Réglages > Notifications > Time Sheet
   - Revenez dans l'application pour réactiver les rappels

### Android
1. **Première activation :**
   - L'application demande automatiquement les permissions
   - Appuyez sur "Autoriser" dans la popup système

2. **Si refusé initialement :**
   - Allez dans Paramètres > Applications > Time Sheet > Autorisations
   - Activez "Notifications"
   - Revenez dans l'application
   - Un message vous proposera d'activer les rappels

3. **Permissions révoquées :**
   - Les rappels se désactivent automatiquement
   - Réactivez dans les paramètres système
   - Revenez dans l'application pour réactiver les rappels

## 🚨 Cas d'Erreur Courants

### Erreur : "Notifications désactivées"
**Cause :** Les permissions ont été définitivement refusées
**Solution :**
1. Appuyez sur "Ouvrir les paramètres" dans le dialogue
2. Activez les notifications pour Time Sheet
3. Revenez dans l'application
4. Réessayez d'activer les rappels

### Erreur : "Autorisation requise"
**Cause :** Permissions temporairement refusées
**Solution :**
1. Appuyez sur "Paramètres" pour ouvrir les paramètres système
2. Ou appuyez sur "Réessayer plus tard" et réessayez dans l'application

### Les rappels ne se déclenchent pas
**Causes possibles :**
1. **Mode Ne Pas Déranger activé**
   - Vérifiez les paramètres de Ne Pas Déranger
   - Configurez des exceptions pour Time Sheet si nécessaire

2. **Économie de batterie**
   - Sur Android, ajoutez Time Sheet aux applications exemptées d'optimisation de batterie
   - Sur iOS, vérifiez que l'actualisation en arrière-plan est activée

3. **Horaires incorrects**
   - Vérifiez que les heures de rappel sont correctement configurées
   - Vérifiez que les jours actifs incluent le jour actuel

## 🔍 Diagnostic Avancé

### Vérification des Logs
Si le problème persiste, vérifiez les logs de l'application :
1. Les messages de permission apparaissent dans les logs de débogage
2. Recherchez les messages contenant "permission" ou "notification"

### Test Manuel
1. Configurez un rappel pour dans 2-3 minutes
2. Mettez l'application en arrière-plan
3. Attendez l'heure du rappel
4. Vérifiez si la notification apparaît

### Réinitialisation Complète
En dernier recours :
1. Désinstallez l'application
2. Réinstallez-la
3. Reconfigurez vos paramètres
4. Réactivez les rappels

## 📞 Support

Si aucune de ces solutions ne fonctionne :
1. Notez votre modèle d'appareil et version du système
2. Notez les étapes exactes que vous avez suivies
3. Contactez le support technique avec ces informations

## ✅ Vérification du Bon Fonctionnement

Pour confirmer que tout fonctionne correctement :

1. **Permissions accordées** ✓
   - Les notifications sont autorisées dans les paramètres système
   - L'application affiche "Les rappels sont activés"

2. **Configuration valide** ✓
   - Les heures de rappel sont logiques (sortie après entrée)
   - Au moins un jour actif est sélectionné
   - Les paramètres de répétition sont dans les limites

3. **Test de notification** ✓
   - Configurez un rappel test pour dans quelques minutes
   - La notification apparaît à l'heure prévue
   - Appuyer sur la notification ouvre l'application

---

**Dernière mise à jour :** Septembre 2025  
**Version de l'application :** Compatible avec toutes les versions récentes