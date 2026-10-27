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
| `expedicao-teo` | Trilha do Teo (Ciências e Geografia) | Cria uma investigação do ano escolar (cena, pistas e pergunta) e corrige: 20 XP de primeira, 10 depois de errar, 0 depois de revelar a descoberta. |
| `atelie-zuri` | Oficina do Zuri (projetos e mapas mentais) | Minijogos do ano escolar: caça-palavras (grade montada no servidor), monte o mapa mental e quebra-cabeça das etapas de um projeto. 20 XP de primeira, 10 depois de errar, 0 depois de ver a solução. Em "Meu projeto", o tema escrito pela criança vira mapa mental e etapas (15 XP). XP só nos 15 primeiros jogos e 3 primeiros projetos do dia. |
| `arquivo-mila` | Arquivo da Mila (História) | Minijogos do ano escolar: caça-palavras (grade montada no servidor; achar todas vale 20 XP), linha do tempo (4 fichas para ordenar) e enigma do documento (foto, carta ou objeto antigo). 20 XP de primeira, 10 depois de errar, 0 depois de revelar. |
| `minijogo` | Jogos da Liga (caça-palavras, quebra-cabeça, Desafio Relâmpago) | Caça-palavras e quebra-cabeça criados pela IA para o ano escolar e a matéria (a grade e a ordem certa ficam no servidor); o Relâmpago gera 40 contas sem IA. Caça-palavras completo: 20 XP; quebra-cabeça: 20 de primeira, 10 depois; Relâmpago: 5 + 2 por acerto, até 25. |

Todas usam o código comum de `_shared/liga.ts`, o mesmo secret
`OPENAI_API_KEY` e o mesmo `OPENAI_MODEL`. As respostas certas ficam
guardadas em `correcoes_ia` e nunca vão para o app, e todo XP é dado no
servidor. Limites diários opcionais (secrets): `LIMITE_CASOS_POR_DIA`
(padrão 15), `LIMITE_DESAFIOS_POR_DIA` (40), `LIMITE_TEXTOS_POR_DIA` (20),
`LIMITE_EXPEDICOES_POR_DIA` (40), `LIMITE_ARQUIVO_POR_DIA` (40),
`LIMITE_JOGOS_ZURI_POR_DIA` (40) e `LIMITE_PROJETOS_POR_DIA` (10). Para
evitar uso compulsivo, a `atelie-zuri` só dá XP nos primeiros jogos e
projetos de cada 24 horas: `JOGOS_ZURI_COM_XP_POR_DIA` (padrão 15) e
`PROJETOS_COM_XP_POR_DIA` (3). Depois disso a criança ainda joga, mas sem XP.

A `minijogo` precisa da migration `supabase/migrations/0008_minijogos.sql`
(missão do dia "Vencer um Jogo da Liga" e medalha Mestre dos Jogos). Como a
Trilha do Teo, só manda à OpenAI o ano escolar e a matéria. Secrets
opcionais: `LIMITE_MINIJOGOS_POR_DIA` (padrão 60 jogos abertos por dia) e
`MINIJOGOS_COM_XP_POR_DIA` (padrão 15: depois disso a criança ainda joga,
mas sem XP, para o tempo de tela não virar uso compulsivo).

A `expedicao-teo` precisa também da migration
`supabase/migrations/0005_trilha_do_teo.sql` (missão do dia e medalha
Explorador da Liga). Ela só manda à OpenAI o ano escolar e a matéria, nada
escrito pela criança, então não depende da autorização de IA do responsável.

A `arquivo-mila` precisa da migration
`supabase/migrations/0006_arquivo_da_mila.sql` (missão do dia e medalha
Historiador da Liga). Ela também só manda à OpenAI o ano escolar e o jogo
escolhido, então não depende da autorização de IA.
Para o tempo de tela não virar uso compulsivo, só as primeiras 15 partidas
do dia dão XP (secret opcional `ARQUIVO_COM_XP_POR_DIA`); depois dá para
continuar jogando sem XP.

A `atelie-zuri` precisa da migration `supabase/migrations/0007_atelie_do_zuri.sql`
(missão do dia "Jogar na Oficina do Zuri" e medalhas Inventor da Liga e
Arquiteto de Ideias). Os minijogos só mandam à OpenAI o ano escolar e o tipo
de jogo. Já o "Meu projeto" manda o tema escrito pela criança, então exige a
autorização de IA do responsável (como a Oficina de Texto); o tema fica em
`correcoes_ia` e entra na cópia e na exclusão dos dados.

O texto que a criança escreve na Oficina vai para a OpenAI (`store: false`)
e fica guardado em `producoes_textuais` para o responsável acompanhar.

### Publicar

Pela linha de comando (recomendado, porque inclui a pasta `_shared`):

```bash
npx supabase functions deploy detetive-leitura --no-verify-jwt
npx supabase functions deploy desafio-matematica --no-verify-jwt
npx supabase functions deploy oficina-texto --no-verify-jwt
npx supabase functions deploy expedicao-teo --no-verify-jwt
npx supabase functions deploy arquivo-mila --no-verify-jwt
npx supabase functions deploy atelie-zuri --no-verify-jwt
npx supabase functions deploy minijogo --no-verify-jwt
npx supabase functions deploy explicar-foto --no-verify-jwt
```

Essas funções importam `../_shared/liga.ts`, então publique pela linha
de comando (o editor do painel não leva a pasta `_shared` junto). O
`--no-verify-jwt` já deixa o "Enforce JWT verification" desligado.
