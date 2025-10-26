# S3 CLI Container - Nettoyage automatique

## Description

Ce projet fournit un conteneur Docker permettant de surveiller et nettoyer automatiquement les fichiers anciens dans des buckets S3 compatibles (AWS S3, Wasabi, MinIO, etc.). Le conteneur liste les fichiers, affiche leur âge avec des codes couleur et peut supprimer automatiquement les fichiers de plus de X jours (configurable).

## Fonctionnalités

- 🧹 **Nettoyage automatique** : Suppression des fichiers de plus de X jours (configurable)
- 👀 **Mode surveillance** : Affichage coloré de l'âge des fichiers sans suppression
- 📊 **Reporting détaillé** : Codes couleur pour visualiser l'âge des fichiers
- 🔄 **Exécution flexible** : Mode continu (24h) ou unique (`RUN_ONCE`)
- 🎯 **Multi-buckets** : Support de plusieurs buckets/dossiers simultanément
- 🌐 **Compatibilité S3** : Fonctionne avec AWS S3, Wasabi, MinIO et autres services compatibles

## Configuration

### Variables d'environnement

#### Configuration AWS/S3 (obligatoire)
- `AWS_ACCESS_KEY_ID` : Clé d'accès AWS/S3
- `AWS_SECRET_ACCESS_KEY` : Clé secrète AWS/S3  
- `AWS_DEFAULT_REGION` : Région AWS (ex: eu-west-2)
- `ENDPOINT_URL` : URL du service S3 (pour services non-AWS comme Wasabi)

#### Configuration du nettoyage
- `BUCKET_NAME` : Liste des buckets/dossiers séparés par `|` (pipe)
- `MODE` : Mode d'opération
  - Non défini ou commenté : **Mode surveillance** (affichage uniquement)
  - `clean` : **Mode nettoyage** (suppression effective des fichiers)
- `FILE_AGE` : Âge limite en jours pour la suppression (défaut: 90, défini automatiquement)
- `RUN_ONCE` : Si "true", exécute une seule fois puis s'arrête (défaut: false)
- `SLEEP_TIME` : Intervalle en secondes entre les exécutions (défaut: 86400 = 24h, défini automatiquement)

### Exemple de configuration

```bash
# Configuration S3
AWS_ACCESS_KEY_ID=votre_access_key
AWS_SECRET_ACCESS_KEY=votre_secret_key
AWS_DEFAULT_REGION=eu-west-2
ENDPOINT_URL=https://s3.eu-west-2.wasabisys.com/

# Buckets à surveiller (séparés par |)
BUCKET_NAME="mon-bucket|mon-bucket/dossier1|mon-bucket/dossier2"

# Mode de fonctionnement
#MODE=clean  # Décommentez pour activer le nettoyage

# Configuration avancée
FILE_AGE=90        # Âge limite en jours
RUN_ONCE=true      # Exécution unique puis arrêt
SLEEP_TIME=86400   # Intervalle entre exécutions (24h)
```

## Modes de fonctionnement

### Mode surveillance (défaut)
- ✅ Liste tous les fichiers des buckets configurés
- 📊 Affiche l'âge de chaque fichier avec codes couleur
- ⚠️ **Aucune suppression** - mode sécurisé pour vérification

### Mode nettoyage
- 🧹 Supprime automatiquement les fichiers de plus de `FILE_AGE` jours
- 📝 Affiche les suppressions effectuées
- ⚠️ **Suppression définitive** - utilisez avec précaution

## Codes couleur

Le script utilise des codes couleur pour faciliter la lecture :

- 🟢 **Vert** : Nom des fichiers
- 🟡 **Jaune** : Fichiers récents (< `FILE_AGE` jours)
- 🟣 **Magenta** : Fichiers anciens (> `FILE_AGE` jours, candidats à la suppression)
- 🔵 **Bleu** : Nom des buckets en cours de traitement
- 🔴 **Rouge** : Actions de suppression (mode clean uniquement)

## Utilisation

### 1. Configuration

Modifiez le fichier `env` avec vos paramètres :

```bash
AWS_ACCESS_KEY_ID=votre_access_key
AWS_SECRET_ACCESS_KEY=votre_secret_key
AWS_DEFAULT_REGION=eu-west-2
ENDPOINT_URL=https://s3.eu-west-2.wasabisys.com/
BUCKET_NAME="bucket1|bucket2/dossier|bucket3"
FILE_AGE=90
SLEEP_TIME=86400
RUN_ONCE=true
```

### 3. Exécution

#### Mode surveillance (recommandé pour débuter)
```bash
docker run --rm \
  --env-file env \
  s3cli:latest
```

#### Mode nettoyage (suppression effective)
```bash
docker run --rm \
  --env-file env \
  -e MODE=clean \
  s3cli:latest
```

#### Exécution unique (recommandé pour tests)
```bash
docker run --rm \
  --env-file env \
  -e RUN_ONCE=true \
  s3cli:latest
```

#### Exécution en arrière-plan
```bash
docker run -d \
  --name s3cli-cleaner \
  --env-file env \
  -e MODE=clean \
  s3cli:latest
```

### 4. Exemple avec docker-compose

```yaml
services:
  s3cli-cleaner:
    build: .
    container_name: s3cli-cleaner
    env_file:
      - env
    environment:
      - MODE=clean        # Supprimez cette ligne pour le mode surveillance
      - FILE_AGE=90       # Optionnel, défaut: 90 jours
      - SLEEP_TIME=86400  # Intervalle entre exécutions (24h par défaut)
      # - RUN_ONCE=true   # Décommentez pour exécution unique
    restart: unless-stopped
```

## Fonctionnement détaillé

### Cycle d'exécution

1. **Initialisation** : Définition des valeurs par défaut (`FILE_AGE=90`, `SLEEP_TIME=86400`)
2. **Scan des buckets** : Le container parcourt chaque bucket/dossier configuré
3. **Analyse des fichiers** : Pour chaque fichier, calcule l'âge en jours
4. **Affichage coloré** : Présente les résultats avec codes couleur
5. **Action conditionnelle** : 
   - Mode surveillance : Affichage uniquement
   - Mode clean : Suppression des fichiers > `FILE_AGE` jours
6. **Pause** : 
   - `RUN_ONCE=true` : Arrêt après une exécution
   - Sinon : Attente de `SLEEP_TIME` secondes avant le prochain cycle

### Format des dates

Le script analyse les fichiers avec des dates au format `YYYY-MM-DD` dans leur nom ou métadonnées S3.

### Critères de suppression

- ⏱️ **Âge** : Plus de X jours (configurable via `FILE_AGE`)
- 📁 **Scope** : Tous les buckets/dossiers configurés
- 🔄 **Fréquence** : Vérification toutes les 24h (ou unique si `RUN_ONCE=true`)

## Exemples de sortie

### Mode surveillance
```
Configuration: FILE_AGE=90 jours, SLEEP_TIME=86400 secondes
--- Running Cleaning at Fri Oct 25 10:30:00 UTC 2025 ---
--- Parcours de backup ---
backup-2025-07-15.tgz : 102 jours
backup-2025-10-20.tgz : 5 jours
--- Parcours de backup/Mysql_Backup ---
mysql-dump-2025-06-01.sql.gz : 146 jours
--- RUN_ONCE is true, exiting after one run ---
```

### Mode nettoyage
```
Configuration: FILE_AGE=90 jours, SLEEP_TIME=86400 secondes
--- Running Cleaning at Fri Oct 25 10:30:00 UTC 2025 ---
--- Parcours de backup ---
backup-2025-07-15.tgz : 102 jours
Suppression de backup-2025-07-15.tgz dans backup
backup-2025-10-20.tgz : 5 jours
--- Sleeping 24h ---
```

## Sécurité et bonnes pratiques

### Recommandations de sécurité
- 🔐 **Test préalable** : Utilisez toujours le mode surveillance avant le mode clean
- 📋 **Backup des credentials** : Stockez les fichiers `.env` avec permissions 600
- 🎯 **Buckets spécifiques** : Limitez aux buckets de sauvegarde uniquement
- 📝 **Logs de surveillance** : Conservez les logs pour audit

### Workflow recommandé

1. **Phase de test** : Lancez en mode surveillance avec exécution unique
   ```bash
   docker run --rm --env-file env -e RUN_ONCE=true s3cli:latest
   ```

2. **Vérification** : Examinez la sortie et identifiez les fichiers qui seraient supprimés

3. **Test de nettoyage** : Testez le nettoyage sur un petit échantillon
   ```bash
   docker run --rm --env-file env -e MODE=clean -e RUN_ONCE=true s3cli:latest
   ```

4. **Activation du nettoyage continu** : Une fois validé, activez le mode clean permanent
   ```bash
   docker run -d --name s3cli --env-file env -e MODE=clean s3cli:latest
   ```

## Dépannage

### Problèmes courants

#### "No credentials found"
- **Cause** : Variables AWS non définies ou incorrectes
- **Solution** : Vérifiez `AWS_ACCESS_KEY_ID` et `AWS_SECRET_ACCESS_KEY`

#### "Unable to locate service"
- **Cause** : Region ou endpoint incorrect
- **Solution** : Vérifiez `AWS_DEFAULT_REGION` et `ENDPOINT_URL`

#### Aucun fichier listé
- **Cause** : Bucket inexistant ou permissions insuffisantes
- **Solution** : Vérifiez les noms de buckets et les permissions S3

### Vérification des logs

```bash
# Conteneur en cours d'exécution
docker logs s3cli-cleaner

# Suivi en temps réel
docker logs -f s3cli-cleaner
```

### Test de connectivité

```bash
# Test rapide de connexion S3
docker run --rm --env-file env s3cli:latest aws s3 ls --endpoint-url $ENDPOINT_URL

# Test avec un bucket spécifique
docker run --rm --env-file env s3cli:latest aws s3 ls s3://votre-bucket --endpoint-url $ENDPOINT_URL
```

## Personnalisation

### Valeurs par défaut

Le script définit automatiquement les valeurs par défaut suivantes si les variables ne sont pas spécifiées :
- `FILE_AGE=90` (90 jours)
- `SLEEP_TIME=86400` (24 heures en secondes)

Ces valeurs sont affichées au démarrage du conteneur pour confirmation.

### Modification du seuil d'âge

Pour changer le seuil de jours, utilisez la variable d'environnement :
```bash
FILE_AGE=30  # Fichiers de plus de 30 jours
```

Ou directement dans la commande Docker :
```bash
docker run --rm --env-file env -e FILE_AGE=30 s3cli:latest
```

### Modification de la fréquence

Pour contrôler la fréquence d'exécution :

#### Exécution unique
```bash
RUN_ONCE=true  # Exécute une seule fois puis s'arrête
```

#### Modification de l'intervalle continu
Utilisez la variable d'environnement `SLEEP_TIME` (en secondes) :
```bash
SLEEP_TIME=3600  # 1 heure entre chaque exécution
```

Exemples d'intervalles :
- `SLEEP_TIME=3600`  : 1 heure
- `SLEEP_TIME=21600` : 6 heures  
- `SLEEP_TIME=43200` : 12 heures
- `SLEEP_TIME=86400` : 24 heures (défaut)