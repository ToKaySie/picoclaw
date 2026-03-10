# PicoClaw — Déploiement Render

PicoClaw est un agent IA ultra-léger déployé sur [Render](https://render.com) via Docker. Il utilise **Ollama Cloud** comme fournisseur d'IA (modèle `qwen3.5:0.8b`), **Supabase (PostgreSQL)** pour la mémoire persistante, et un **bot Telegram** comme interface de communication.

Aucune clé sensible n'est stockée dans ce dépôt : toutes les valeurs sont injectées dynamiquement via des variables d'environnement au démarrage du conteneur.

---

## Variables d'environnement

Configurez ces 5 variables dans le panneau **Environment** de votre service Render :

| Variable | Description |
|---|---|
| `OLLAMA_API_KEY` | Clé API pour accéder à Ollama Cloud |
| `OLLAMA_API_BASE` | URL de base de l'API Ollama (ex : `https://api.ollama.com`) |
| `SUPABASE_DATABASE_URL` | URL de connexion PostgreSQL Supabase (format `postgresql://...`) |
| `TELEGRAM_BOT_TOKEN` | Token du bot Telegram fourni par [@BotFather](https://t.me/BotFather) |
| `TELEGRAM_USER_ID` | ID Telegram de l'utilisateur autorisé (un seul utilisateur) |

---

## Déploiement sur Render

### Étape 1 — Connecter le dépôt GitHub

Créez un nouveau **Web Service** sur [Render](https://dashboard.render.com) et connectez ce dépôt GitHub. Render détectera automatiquement le `Dockerfile`.

### Étape 2 — Choisir l'offre Free

Sélectionnez l'offre **Free** (512 Mo RAM, 0.1 CPU). PicoClaw est conçu pour fonctionner dans ces limites.

### Étape 3 — Ajouter les variables d'environnement

Dans l'onglet **Environment**, ajoutez les 5 variables listées ci-dessus avec leurs valeurs respectives.

### Étape 4 — Déployer

Cliquez sur **Deploy**. Render construira l'image Docker, démarrera le conteneur, et PicoClaw sera accessible via votre bot Telegram.

---

## Structure du projet

```
├── Dockerfile          # Image Docker légère (debian:bookworm-slim)
├── entrypoint.sh       # Validation des env vars + génération de config.json
├── .gitignore          # Exclut les fichiers sensibles
└── README.md           # Ce fichier
```

## Fonctionnement

Au démarrage du conteneur, le script `entrypoint.sh` :
1. Vérifie que les 5 variables d'environnement sont définies
2. Génère dynamiquement `/app/config.json` avec les valeurs injectées
3. Lance PicoClaw avec `picoclaw gateway --config /app/config.json`

Si une variable est manquante, le conteneur s'arrête avec un message d'erreur explicite dans les logs.
