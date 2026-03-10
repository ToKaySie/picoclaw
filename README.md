# PicoClaw — Déploiement Render

PicoClaw est un agent IA ultra-léger déployé sur [Render](https://render.com) via Docker. Il utilise **Ollama Cloud** comme fournisseur d'IA (modèle `qwen3.5:397b-cloud`), **Supabase** via MCP pour la mémoire persistante, et un **bot Telegram** comme interface de communication.

Aucune clé sensible n'est stockée dans ce dépôt : toutes les valeurs sont injectées dynamiquement via des variables d'environnement au démarrage du conteneur.

---

## Variables d'environnement

Configurez ces 5 variables dans le panneau **Environment** de votre service Render :

| Variable | Description | Où la trouver |
|---|---|---|
| `OLLAMA_API_KEY` | Clé API pour accéder à Ollama Cloud | Dashboard Ollama Cloud |
| `OLLAMA_API_BASE` | URL de base de l'API Ollama (ex : `https://api.ollama.com`) | Dashboard Ollama Cloud |
| `SUPABASE_API_KEY` | Clé API `service_role` de votre projet Supabase | [Supabase Dashboard](https://app.supabase.com) → Settings → API → `service_role` key |
| `TELEGRAM_BOT_TOKEN` | Token du bot Telegram | [@BotFather](https://t.me/BotFather) sur Telegram → `/mybots` → API Token |
| `TELEGRAM_USER_ID` | ID Telegram numérique de l'utilisateur autorisé | [@userinfobot](https://t.me/userinfobot) sur Telegram |

---

## Table de mémoire Supabase

L'agent PicoClaw utilise une table `agent_memory` dans Supabase pour stocker sa mémoire persistante. L'agent tentera de la créer automatiquement via MCP, mais si cela échoue, créez-la manuellement.

### Création manuelle dans Supabase

1. Allez sur [app.supabase.com](https://app.supabase.com)
2. Sélectionnez votre projet → **SQL Editor**
3. Exécutez ce SQL :

```sql
CREATE TABLE IF NOT EXISTS agent_memory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Mise à jour automatique du timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER agent_memory_updated_at
  BEFORE UPDATE ON agent_memory
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
```

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
├── AGENTS.md           # Instructions de comportement de l'agent
├── .gitignore          # Exclut les fichiers sensibles
└── README.md           # Ce fichier
```

## Fonctionnement

Au démarrage du conteneur, le script `entrypoint.sh` :
1. Vérifie que les 5 variables d'environnement sont définies
2. Copie `AGENTS.md` dans le workspace PicoClaw
3. Génère dynamiquement `/app/config.json` avec les valeurs injectées (incluant le serveur MCP Supabase)
4. Lance PicoClaw avec `PICOCLAW_CONFIG=/app/config.json picoclaw gateway`

Si une variable est manquante, le conteneur s'arrête avec un message d'erreur explicite dans les logs.
