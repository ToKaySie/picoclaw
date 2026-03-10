# Déploiement de PicoClaw sur Render

## Description de l'implémentation

Ce projet configure un déploiement cloud complet de **PicoClaw** (agent IA ultra-léger) sur **Render** (offre gratuite). L'architecture repose sur :
- **Ollama Cloud** comme fournisseur d'IA (modèle `qwen3.5:397b-cloud`)
- **Supabase via MCP (Model Context Protocol)** pour la mémoire persistante
- **Telegram** comme interface utilisateur (bot)
- **Docker** pour le conteneur de déploiement

Aucune clé sensible n'est stockée dans le dépôt : toutes les valeurs sont injectées via des variables d'environnement Render.

## Déroulement technique

### 1. Structure du dépôt
```
/
├── Dockerfile          # Image Docker légère basée sur debian:bookworm-slim
├── entrypoint.sh       # Script de démarrage (génère config.json avec MCP)
├── AGENTS.md           # Instructions de comportement de l'agent
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
| `SUPABASE_ACCESS_TOKEN` | Personal Access Token Supabase |
| `SUPABASE_PROJECT_REF` | Référence du projet Supabase |
| `TELEGRAM_BOT_TOKEN` | Token du bot Telegram |
| `TELEGRAM_USER_ID` | ID Telegram de l'utilisateur autorisé |

### 3. Flux de démarrage du conteneur
1. Le conteneur démarre avec `entrypoint.sh`
2. Le script vérifie les 6 variables d'environnement
3. Copie `AGENTS.md` dans le workspace PicoClaw
4. Un fichier `config.json` est généré dynamiquement dans `/app/` incluant le serveur MCP
5. PicoClaw est lancé avec `PICOCLAW_CONFIG=/app/config.json picoclaw gateway`

## Résultat final attendu

- Un agent IA capable de retenir des informations via Supabase
- Aucune clé en dur dans aucun fichier
- Bot Telegram fonctionnel et sécurisé par User ID
- Contrainte mémoire respectée (512 Mo RAM, 0.1 CPU)

## Todo-list d'implémentation

- [x] Créer le fichier `.gitignore`
- [x] Créer le fichier `entrypoint.sh` avec validation des env vars et génération de config.json
- [x] Créer le fichier `Dockerfile` léger
- [x] Créer le fichier `AGENTS.md` pour le comportement et MCP
- [x] Créer le fichier `README.md` avec documentation complète
- [x] Vérifier qu'aucune clé sensible n'est en dur dans les fichiers
- [x] Vérifier la syntaxe du script shell
- [x] Vérifier les fins de ligne LF sur tous les fichiers
- [x] Test réussi ? ✅ Confirmé par l'utilisateur le 10/03/2026

---

> ✅ **Implémentation validée le 10/03/2026** — Déploiement PicoClaw sur Render totalement fonctionnel.
>
> **Statut final :**
> - Modèle : `qwen3.5:397b-cloud` (Ollama)
> - Mémoire : Supabase via MCP (Table `agent_memory`)
> - Connectivité : Telegram Bot (authentifié)
> - Environnement : Render Free (Stable)
