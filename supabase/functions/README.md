# Edge Functions da Liga do Saber

## explicar-foto (Foto + IA)

Recebe a foto da lição enviada pelo app, pede ao Claude (Anthropic) uma
explicação passo a passo no tom do personagem da matéria e grava o resultado
em `correcoes_ia`. A foto não é guardada no Supabase: ela passa pela função e
segue só para a IA.

- Chave da IA: secret `ANTHROPIC_API_KEY` (fica só no servidor, nunca no app).
- Opcionais: `CLAUDE_MODEL` (padrão `claude-opus-5-5`) e
  `LIMITE_FOTOS_POR_DIA` (padrão 30 por criança).
- A função confere o login sozinha, então o "Verify JWT" do Supabase fica
  desligado (`--no-verify-jwt`).

### Publicar pelo painel do Supabase

1. Edge Functions > Secrets: crie `ANTHROPIC_API_KEY` com a chave de
   https://console.anthropic.com (Settings > API Keys).
2. Edge Functions > Deploy a new function > Via Editor. Nome:
   `explicar-foto`. Cole o conteúdo de `explicar-foto/index.ts` e publique.
3. Na página da função, em Details, desligue "Enforce JWT verification" e salve.

### Publicar pela linha de comando

```bash
npx supabase login
npx supabase link --project-ref hhcdsnfcthyqpxinoyzi
npx supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
npx supabase functions deploy explicar-foto --no-verify-jwt
```
