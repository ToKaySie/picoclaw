# PicoClaw — Déploiement Render

PicoClaw est un agent IA ultra-léger déployé sur [Render](https://render.com) via Docker. Il utilise **Ollama Cloud** comme fournisseur d'IA (modèle `qwen3.5:397b-cloud`), **Supabase** via MCP pour la mémoire persistante, et un **bot Telegram** comme interface de communication.

L'agent peut également **générer des PDF** à partir de code LaTeX (fiches de révision, résumés, etc.) grâce au compilateur **Tectonic** intégré.

Aucune clé sensible n'est stockée dans ce dépôt : toutes les valeurs sont injectées dynamiquement via des variables d'environnement au démarrage du conteneur.

---

## Variables d'environnement

Configurez ces 7 variables dans le panneau **Environment** de votre service Render :

| Variable | Description | Où la trouver |
|---|---|---|
| `OLLAMA_API_KEY` | Clé API pour accéder à Ollama Cloud | Dashboard Ollama Cloud |
| `OLLAMA_API_BASE` | URL de base de l'API Ollama (ex : `https://api.ollama.com`) | Dashboard Ollama Cloud |
| `SUPABASE_ACCESS_TOKEN` | Personal Access Token (PAT) Supabase | [supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens) → Generate new token |
| `SUPABASE_PROJECT_REF` | Référence de votre projet Supabase (ex : `abcdefghijklmnop`) | URL de votre projet : `https://supabase.com/dashboard/project/<project_ref>` |
| `SUPABASE_ANON_KEY` | Clé anonyme du projet Supabase (pour le Storage) | [Supabase Dashboard](https://app.supabase.com) → Settings → API → `anon` key |
| `TELEGRAM_BOT_TOKEN` | Token du bot Telegram | [@BotFather](https://t.me/BotFather) sur Telegram → `/mybots` → API Token |
| `TELEGRAM_USER_ID` | ID Telegram numérique de l'utilisateur autorisé | [@userinfobot](https://t.me/userinfobot) sur Telegram |

---

## Configuration Supabase

### Table de mémoire `agent_memory`

L'agent utilise cette table pour sa mémoire persistante. Créez-la dans **SQL Editor** :

```sql
CREATE TABLE IF NOT EXISTS agent_memory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

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

### Bucket Storage `pdfs`

Pour la génération de PDF, créez un bucket public dans Supabase :

1. Allez sur [app.supabase.com](https://app.supabase.com) → votre projet → **Storage**
2. Cliquez **New bucket** → Nom : `pdfs` → Cochez **Public bucket** → Créer
3. Dans les **Policies** du bucket, ajoutez une policy permettant l'**INSERT** pour `anon`

Ou exécutez dans **SQL Editor** :

```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('pdfs', 'pdfs', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Allow anonymous uploads"
ON storage.objects FOR INSERT
TO anon
WITH CHECK (bucket_id = 'pdfs');

CREATE POLICY "Allow public reads"
ON storage.objects FOR SELECT
TO anon
USING (bucket_id = 'pdfs');
```

---

## Déploiement sur Render

### Étape 1 — Connecter le dépôt GitHub
Créez un nouveau **Web Service** sur [Render](https://dashboard.render.com) et connectez ce dépôt GitHub.

### Étape 2 — Choisir l'offre Free
Sélectionnez l'offre **Free** (512 Mo RAM, 0.1 CPU).

### Étape 3 — Ajouter les variables d'environnement
Dans l'onglet **Environment**, ajoutez les 7 variables listées ci-dessus.

### Étape 4 — Déployer
Cliquez sur **Deploy**. Render construira l'image Docker et lancera PicoClaw.

---

## Structure du projet

```
├── Dockerfile          # Image Docker (debian:bookworm-slim + tectonic)
├── entrypoint.sh       # Validation env vars + config.json + script LaTeX
├── AGENTS.md           # Instructions de comportement + template LaTeX
├── .gitignore          # Exclut les fichiers sensibles
└── README.md           # Ce fichier
```

## Fonctionnalités

| Fonctionnalité | Comment |
|---|---|
| **Chat IA** | Via Telegram avec le modèle Ollama Cloud |
| **Mémoire persistante** | Table `agent_memory` dans Supabase via MCP |
| **Génération de PDF** | LaTeX → Tectonic → Upload Supabase Storage |
