# Ajout de la génération LaTeX → PDF dans PicoClaw

## Description de l'implémentation

Ajouter la capacité à l'agent PicoClaw de générer des fiches de révision (ou tout document)
en **LaTeX**, de les compiler en **PDF**, et de partager un lien de téléchargement à l'utilisateur.

Le système utilise :
- **Tectonic** : compilateur LaTeX très léger (binaire unique ~25Mo, pas besoin de TeX Live complet)
- **Supabase Storage** : pour stocker les PDF et les rendre téléchargeables via une URL publique
- **Tools PicoClaw** : `write_file` + `exec` (outils intégrés, pas de MCP supplémentaire)

## Déroulement technique

### Flux de génération
```
Utilisateur demande une fiche de révision
        ↓
L'IA génère le code LaTeX
        ↓
write_file → /root/.picoclaw/workspace/document.tex
        ↓
exec → tectonic document.tex (compile en PDF)
        ↓
exec → curl pour upload sur Supabase Storage
        ↓
L'IA envoie le lien de téléchargement sur Telegram
```

### Modifications nécessaires

1. **Dockerfile** : ajouter l'installation de `tectonic` + `curl`
2. **entrypoint.sh** : ajouter la variable `SUPABASE_ANON_KEY` + activer Storage dans MCP URL
3. **AGENTS.md** : ajouter les instructions pour la génération LaTeX/PDF
4. **Supabase** : créer un bucket `pdfs` public
5. **Render** : ajouter la variable `SUPABASE_ANON_KEY`

## Résultat final attendu

- L'utilisateur demande "Crée-moi une fiche de révision sur la Révolution française"
- L'IA génère le LaTeX, compile, upload, et envoie le lien du PDF
- Le PDF est téléchargeable via Supabase Storage

## Todo-list d'implémentation

- [x] Ajouter tectonic dans le Dockerfile
- [x] Ajouter `SUPABASE_ANON_KEY` comme variable d'environnement
- [x] Activer Supabase Storage dans la config MCP
- [x] Ajouter les instructions LaTeX/PDF dans AGENTS.md
- [x] Mettre à jour README.md avec les nouvelles variables
- [x] Push sur GitHub
- [x] Test réussi ? ✅ Confirmé par l'utilisateur (le PDF s'envoie bien directement dans Telegram !)

---

> ✅ **Fonctionnalité validée le 10/03/2026**
> Le flux complet fonctionne parfaitement : l'IA écrit le `.tex`, le script le compile silencieusement avec Tectonic, l'upload dans Supabase Storage, et le bot l'envoie nativement sur Telegram via l'API.
>
> ⚠️ **Note sur la performance :**
> L'utilisation d'un modèle aussi colossal que `qwen3.5:397b-cloud` pour générer un document LaTeX de plusieurs pages peut prendre un certain temps à cause du "thinking" et du temps de réponse de l'API externe (jusqu'à 6 minutes constatées). C'est un délai normal pour un modèle de presque 400 milliards de paramètres !
