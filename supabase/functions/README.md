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

## Módulos com IA e XP

Antes de publicar as funções abaixo, rode a migration
`supabase/migrations/0003_progresso_xp_missoes.sql` no SQL Editor. Ela cria
a função `conceder_xp` (XP, nível, sequência de dias, missões do dia e
medalhas) que todas as funções usam, inclusive a `explicar-foto`.

| Função | Módulo | O que faz |
| --- | --- | --- |
| `detetive-leitura` | Detetive da Leitura (Luma) | Cria um caso (texto + 3 perguntas) e corrige as respostas: 10 XP por acerto. |
| `desafio-matematica` | Arena Matemática (Nico) | Cria um desafio do ano escolar e corrige: 20 XP de primeira, 10 depois de errar, 0 depois de ver o passo a passo. |
| `oficina-texto` | Oficina de Texto (Luma) | Feedback da versão 1 (15 XP) e avaliação da reescrita (10 a 34 XP, pela evolução). |

As três usam o código comum de `_shared/liga.ts`, o mesmo secret
`OPENAI_API_KEY` e o mesmo `OPENAI_MODEL`. As respostas certas ficam
guardadas em `correcoes_ia` e nunca vão para o app, e todo XP é dado no
servidor. Limites diários opcionais (secrets): `LIMITE_CASOS_POR_DIA`
(padrão 15), `LIMITE_DESAFIOS_POR_DIA` (40) e `LIMITE_TEXTOS_POR_DIA` (20).

O texto que a criança escreve na Oficina vai para a OpenAI (`store: false`)
e fica guardado em `producoes_textuais` para o responsável acompanhar.

### Publicar

Pela linha de comando (recomendado, porque inclui a pasta `_shared`):

```bash
npx supabase functions deploy detetive-leitura --no-verify-jwt
npx supabase functions deploy desafio-matematica --no-verify-jwt
npx supabase functions deploy oficina-texto --no-verify-jwt
npx supabase functions deploy explicar-foto --no-verify-jwt
```

Essas três funções importam `../_shared/liga.ts`, então publique pela linha
de comando (o editor do painel não leva a pasta `_shared` junto). O
`--no-verify-jwt` já deixa o "Enforce JWT verification" desligado.
