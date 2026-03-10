# Déploiement de PicoClaw sur Render

## Description de l'implémentation

Ce projet configure un déploiement cloud complet de **PicoClaw** (agent IA ultra-léger) sur **Render** (offre gratuite). L'architecture repose sur :
- **Ollama Cloud** comme fournisseur d'IA (modèle `qwen3.5:0.8b`)
- **Supabase (PostgreSQL)** pour la mémoire persistante
- **Telegram** comme interface utilisateur (bot)
- **Docker** pour le conteneur de déploiement

Aucune clé sensible n'est stockée dans le dépôt : toutes les valeurs sont injectées via des variables d'environnement Render.

## Déroulement technique

### 1. Structure du dépôt
```
/
├── Dockerfile          # Image Docker légère basée sur debian:bookworm-slim
├── entrypoint.sh       # Script de démarrage (génère config.json dynamiquement)
├── .gitignore          # Exclut fichiers sensibles et artefacts
├── README.md           # Documentation de déploiement
└── docs/
    └── deploy-render.md  # Ce fichier
```

### 2. Variables d'environnement (injectées par Render)
| Variable | Description |
|---|---|
| `OLLAMA_API_KEY` | Clé API Ollama Cloud |
| `OLLAMA_API_BASE` | URL de base de l'API Ollama |
| `SUPABASE_DATABASE_URL` | URL de connexion PostgreSQL Supabase |
| `TELEGRAM_BOT_TOKEN` | Token du bot Telegram |
| `TELEGRAM_USER_ID` | ID Telegram de l'utilisateur autorisé |

### 3. Flux de démarrage du conteneur
1. Le conteneur démarre avec `entrypoint.sh`
2. Le script vérifie que toutes les 5 variables d'environnement sont définies
3. Un fichier `config.json` est généré dynamiquement dans `/app/`
4. PicoClaw est lancé avec `picoclaw gateway --config /app/config.json`

### 4. Dockerfile
- Image de base : `debian:bookworm-slim` (minimale)
- Dépendances : `wget`, `ca-certificates`, `bash`
- Télécharge le binaire PicoClaw depuis GitHub Releases
- Nettoyage du cache apt pour minimiser la taille

## Résultat final attendu

- Un dépôt GitHub contenant 4 fichiers (+ docs/) prêts à être connectés à Render
- Aucune clé en dur dans aucun fichier
- Un conteneur Docker fonctionnel qui démarre, valide les env vars, génère la config et lance PicoClaw
- Le bot Telegram répond aux messages de l'utilisateur autorisé
- Contrainte mémoire respectée (512 Mo RAM, 0.1 CPU)

## Todo-list d'implémentation

- [x] Créer le fichier `.gitignore`
- [x] Créer le fichier `entrypoint.sh` avec validation des env vars et génération de config.json
- [x] Créer le fichier `Dockerfile` léger basé sur debian:bookworm-slim
- [x] Créer le fichier `README.md` avec documentation complète
- [x] Vérifier qu'aucune clé sensible n'est en dur dans les fichiers
- [x] Vérifier la syntaxe du Dockerfile (vérification visuelle OK)
- [x] Vérifier la syntaxe du script shell (`bash -n` → exit code 0)
- [x] Vérifier les fins de ligne LF sur tous les fichiers (conversion effectuée)
- [x] Test réussi ?

---

> ✅ **Implémentation validée le 10/03/2026** — Tous les fichiers sont créés, la syntaxe est vérifiée, les fins de ligne sont en LF, et aucune clé sensible n'apparaît dans le dépôt.
>
> ✅ **Déploiement validé le 10/03/2026** — PicoClaw déployé sur Render avec succès. Bot Telegram fonctionnel. Corrections appliquées :
> - Provider `ollama/` avec `api_base` personnalisé (au lieu de `ollama_cloud/` inexistant)
> - Config générée dans `~/.picoclaw/config.json` (chemin par défaut, pas de flag `--config`)
> - Modèle `qwen3.5:397b-cloud`
> - Gateway accessible sur `0.0.0.0:3000`
