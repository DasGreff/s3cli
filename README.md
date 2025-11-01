# S3 CLI Container - Nettoyage automatique

Conteneur Docker pour surveiller et nettoyer automatiquement les fichiers anciens dans les buckets S3.

## Fonctionnalités

- 🧹 **Nettoyage automatique** : Suppression des fichiers de plus de X jours
- 👀 **Mode surveillance** : Affichage coloré sans suppression (sécurisé)
- 🔄 **Exécution flexible** : Mode continu ou unique
- 🎯 **Multi-buckets** : Support de plusieurs buckets/dossiers
- 🌐 **Compatibilité S3** : AWS S3, Wasabi, MinIO, etc.

## Configuration

### Variables d'environnement essentielles

```bash
# Connexion S3
AWS_ACCESS_KEY_ID=votre_access_key
AWS_SECRET_ACCESS_KEY=votre_secret_key
AWS_DEFAULT_REGION=eu-west-2
ENDPOINT_URL=https://s3.eu-west-2.wasabisys.com/

# Buckets à traiter (séparés par |)
BUCKET_NAME="bucket1|bucket2/dossier"

# Configuration
MODE=clean          # Décommentez pour activer la suppression
FILE_AGE=90         # Âge limite en jours (défaut: 90)
RUN_ONCE=true       # Exécution unique (défaut: false)
```

## Modes de fonctionnement

- **Mode surveillance** (défaut) : Affiche les fichiers avec codes couleur, aucune suppression
- **Mode nettoyage** (`MODE=clean`) : Supprime les fichiers de plus de `FILE_AGE` jours

## Utilisation

### Exécution rapide

```bash
# Mode surveillance (sécurisé)
docker run --rm --env-file env s3cli:latest

# Mode nettoyage
docker run --rm --env-file env -e MODE=clean s3cli:latest

# Test unique
docker run --rm --env-file env -e RUN_ONCE=true s3cli:latest
```

### Docker Compose

```yaml
services:
  s3cli-cleaner:
    build: .
    env_file: env
    environment:
      - MODE=clean
      - RUN_ONCE=true
    restart: unless-stopped
```

## Exemple de sortie

```
Configuration: FILE_AGE=90 jours, SLEEP_TIME=86400 secondes
--- Running Cleaning at Fri Oct 25 10:30:00 UTC 2025 ---
--- Parcours de backup ---
backup-2025-07-15.tgz : 102 jours (SUPPRIMÉ en mode clean)
backup-2025-10-20.tgz : 5 jours
--- RUN_ONCE is true, exiting after one run ---
```

## Workflow recommandé

1. **Test** : Mode surveillance avec `RUN_ONCE=true`
2. **Vérification** : Examinez les fichiers qui seraient supprimés
3. **Nettoyage** : Activez `MODE=clean` une fois validé

⚠️ **Important** : Testez toujours en mode surveillance avant d'activer la suppression

## Dépannage

### Problèmes courants

- **"No credentials found"** : Vérifiez `AWS_ACCESS_KEY_ID` et `AWS_SECRET_ACCESS_KEY`
- **"Unable to locate service"** : Vérifiez `AWS_DEFAULT_REGION` et `ENDPOINT_URL`
- **Aucun fichier listé** : Vérifiez les noms de buckets et permissions S3

### Logs

```bash
docker logs s3cli-cleaner
```

## Options avancées

- `FILE_AGE=30` : Modifier le seuil d'âge (défaut: 90 jours)
- `SLEEP_TIME=3600` : Intervalle entre exécutions (défaut: 24h)
- `RUN_ONCE=true` : Exécution unique puis arrêt