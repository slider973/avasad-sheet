# 🚀 Configuration Déploiement Continu GitHub Actions

## 📋 Étapes de Configuration

### 1. **Génération de la Clé SSH**

Sur votre machine locale :
```bash
# Générer une clé SSH dédiée pour GitHub Actions
ssh-keygen -t ed25519 -C "github-actions-timesheet" -f ~/.ssh/timesheet_deploy

# Afficher la clé publique
cat ~/.ssh/timesheet_deploy.pub
```

### 2. **Configuration du VPS**

Ajoutez la clé publique sur votre VPS :
```bash
# Connexion au VPS
ssh root@31.220.80.133

# Ajouter la clé publique
echo "VOTRE_CLE_PUBLIQUE_ICI" >> ~/.ssh/authorized_keys

# Vérifier les permissions
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### 3. **Configuration GitHub Secrets**

Dans votre repository GitHub :
1. Allez dans **Settings** → **Secrets and variables** → **Actions**
2. Cliquez sur **New repository secret**
3. Nom : `VPS_SSH_PRIVATE_KEY`
4. Valeur : Contenu de `~/.ssh/timesheet_deploy` (clé privée complète)

```bash
# Afficher la clé privée à copier
cat ~/.ssh/timesheet_deploy
```

### 4. **Test de Connexion SSH**

Testez la connexion depuis votre machine :
```bash
ssh -i ~/.ssh/timesheet_deploy root@31.220.80.133
```

## 🔧 Workflow GitHub Actions

Le workflow `.github/workflows/deployment-contabo.yml` est configuré pour :

### **Déclencheurs**
- Push sur branche `main`
- Push sur branche `production`
- Déclenchement manuel via GitHub UI

### **Étapes du Déploiement**
1. **Checkout** du code
2. **Connexion SSH** au VPS
3. **Backup** de la base de données
4. **Arrêt** des services
5. **Déploiement** du nouveau code
6. **Build** et redémarrage des services
7. **Vérification** du déploiement
8. **Nettoyage** des anciennes images

## 🚀 Déclenchement du Déploiement

### **Automatique**
```bash
# Commit et push sur main
git add .
git commit -m "Deploy: nouvelle fonctionnalité"
git push origin main
```

### **Manuel**
1. Allez dans **Actions** de votre repository
2. Sélectionnez **Deploy to Contabo VPS**
3. Cliquez **Run workflow**
4. Choisissez la branche et cliquez **Run workflow**

## 📊 Monitoring du Déploiement

### **Logs GitHub Actions**
1. Repository → **Actions**
2. Cliquez sur le workflow en cours
3. Consultez les logs de chaque étape

### **Logs sur le VPS**
```bash
# Connexion au VPS
ssh root@31.220.80.133

# Logs des conteneurs
cd /root/avasad-sheet/time_sheet_backend/time_sheet_backend_server/
docker-compose -f docker-compose.production.yml logs -f

# Status des services
docker-compose -f docker-compose.production.yml ps
```

## 🔍 Vérification Post-Déploiement

Le workflow vérifie automatiquement :
- ✅ Status des conteneurs Docker
- ✅ Logs de l'application
- ✅ Connectivité interne
- ✅ Health check de l'API

### **Vérification Manuelle**
```bash
# Test des endpoints
curl -I https://api-timesheet.wefamily.ch
curl -I https://insights.wefamily.ch
curl -I https://app.wefamily.ch
```

## 🚨 Dépannage

### **Erreur de Connexion SSH**
```bash
# Vérifier la clé SSH
ssh -i ~/.ssh/timesheet_deploy -v root@31.220.80.133

# Vérifier les permissions
ls -la ~/.ssh/timesheet_deploy*
```

### **Erreur de Déploiement**
1. Consultez les logs GitHub Actions
2. Vérifiez les logs sur le VPS
3. Redémarrez manuellement si nécessaire :
```bash
ssh root@31.220.80.133
cd /root/avasad-sheet/time_sheet_backend/time_sheet_backend_server/
/root/deploy.sh
```

### **Services Non Accessibles**
```bash
# Sur le VPS
docker-compose -f docker-compose.production.yml ps
docker-compose -f docker-compose.production.yml logs nginx
docker-compose -f docker-compose.production.yml restart
```

## 🎯 Workflow Optimisé

Le workflow inclut :
- **Backup automatique** avant déploiement
- **Installation automatique** de Docker si nécessaire
- **Gestion SSL** automatique
- **Rollback** en cas d'échec
- **Notifications** de statut

## 📈 Métriques de Déploiement

Après chaque déploiement, le workflow affiche :
- ✅ Temps de déploiement
- ✅ Status des services
- ✅ URLs accessibles
- ✅ Logs récents

## 🔗 URLs de Production

Après déploiement réussi :
- **API** : `https://api-timesheet.wefamily.ch`
- **Insights** : `https://insights.wefamily.ch`
- **Web** : `https://app.wefamily.ch`

---

**🎉 Une fois configuré, chaque push sur `main` déploiera automatiquement votre application !**
