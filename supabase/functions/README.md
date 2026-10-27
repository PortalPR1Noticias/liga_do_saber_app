# Edge Functions da Liga do Saber

## explicar-foto (Foto + IA)

Recebe a foto da lição enviada pelo app, pede à OpenAI uma explicação passo
a passo no tom do personagem da matéria e grava o resultado
em `correcoes_ia`. A foto não é guardada no Supabase: ela passa pela função e
segue só para a IA (a chamada usa `store: false`, para a OpenAI não guardar a
conversa).

- Chave da IA: secret `OPENAI_API_KEY` (fica só no servidor, nunca no app).
- Opcionais: `OPENAI_MODEL` (padrão `gpt-6-sol`; `gpt-6-luna` custa bem menos) e
  `LIMITE_FOTOS_POR_DIA` (padrão 30 por criança).
- A função confere o login sozinha, então o "Verify JWT" do Supabase fica
  desligado (`--no-verify-jwt`).

### Publicar pelo painel do Supabase

1. Edge Functions > Secrets: crie `OPENAI_API_KEY` com a chave de
   https://platform.openai.com/api-keys (a conta precisa ter créditos).
2. Edge Functions > Deploy a new function > Via Editor. Nome:
   `explicar-foto`. Cole o conteúdo de `explicar-foto/index.ts` e publique.
3. Na página da função, em Details, desligue "Enforce JWT verification" e salve.

### Publicar pela linha de comando

```bash
npx supabase login
npx supabase link --project-ref hhcdsnfcthyqpxinoyzi
npx supabase secrets set OPENAI_API_KEY=sk-...
npx supabase functions deploy explicar-foto --no-verify-jwt
```
