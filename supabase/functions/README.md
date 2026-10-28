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
| `revanche-prova` | Revanche da prova (Área dos responsáveis + Missões) | O responsável manda até 10 fotos e/ou um PDF (até 6 MB e 10 páginas) de uma prova ou tarefa já feita; a IA cria de 6 a 10 questões de treino (as da prova e outras parecidas, começando pelas que a criança errou). 10 XP de primeira, 5 depois de errar; no segundo erro o herói explica e a questão volta no fim da fila, sem XP. Acertar todas vence a revanche: +30 XP e de 1 a 3 estrelas pelos acertos de primeira. |
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

A `revanche-prova` precisa da migration
`supabase/migrations/0009_revanche_da_prova.sql` (tabela `provas_treino`,
missão do dia "Treinar na Revanche da prova", medalha Virada de Jogo e a
cópia dos dados e a retenção de 12 meses incluindo os treinos). As fotos e o
PDF vão para a OpenAI, então ela exige a autorização de IA do responsável
(`responsaveis.autoriza_ia`) e não guarda os arquivos. Secret opcional:
`LIMITE_PROVAS_POR_DIA` (padrão 10 envios por criança a cada 24 horas).

```bash
npx supabase functions deploy revanche-prova --no-verify-jwt
```

## voz-heroi (heróis falando)

Transforma as explicações dos heróis em áudio MP3 com a voz de cada um
(text-to-speech da OpenAI, modelo padrão `gpt-4o-mini-tts`; troque pelo
secret `OPENAI_TTS_MODEL`). O app mostra um botão "Ouvir" com o retrato do
herói ao lado de cada explicação (Foto + IA, chefões, Revanche, Arena, Trilha,
Arquivo, Oficinas e Detetive). O texto continua sempre na tela, e o áudio
avisa "Voz criada por IA".

- Vozes: Nico `echo`, Luma `coral`, Teo `verse`, Mila `sage`, Zuri `fable`,
  cada um com instruções de jeito de falar em português do Brasil.
- Só vai para a OpenAI o texto da explicação (até 1.200 caracteres), que a
  própria IA ou o app escreveram. Nada de foto, nome ou dado da criança, e o
  áudio não é guardado. O app guarda os últimos 30 áudios na memória, então
  ouvir de novo não gera custo.
- Limites próprios, separados da cota da IA de texto (migration
  `0020_voz_dos_herois.sql`, função `reservar_uso_voz`):
  `LIMITE_VOZ_POR_DIA` (60 por criança), `LIMITE_VOZ_FAMILIA_POR_DIA` (200) e
  `LIMITE_VOZ_GLOBAL_POR_DIA` (5000), a cada 24 horas. Um áudio de 30
  segundos custa por volta de 1 centavo de dólar.

```bash
npx supabase functions deploy voz-heroi --no-verify-jwt
```

## contas-liga (logins de responsável, criança e professor)

Precisa da migration `supabase/migrations/0014_logins_crianca_professor.sql`.
O responsável cria o login de cada criança (usuário e senha, sem e-mail) no
painel dele; a função usa a service role para criar o usuário no Supabase
Auth com o e-mail interno `<usuario>@crianca.gpmkt.art.br` (nunca recebe
e-mail) e `app_metadata.papel = "crianca"`, e liga o login ao perfil. Também
troca a senha da criança. Só o responsável da criança consegue chamar.

Com a migration 0014, todas as funções dos módulos aceitam o login da
própria criança, além do responsável. Por isso, depois de rodar a migration,
publique de novo as funções (o `_shared/liga.ts` e a `explicar-foto`
mudaram), junto com a nova:

```bash
npx supabase functions deploy contas-liga --no-verify-jwt
npx supabase functions deploy detetive-leitura --no-verify-jwt
npx supabase functions deploy desafio-matematica --no-verify-jwt
npx supabase functions deploy oficina-texto --no-verify-jwt
npx supabase functions deploy expedicao-teo --no-verify-jwt
npx supabase functions deploy arquivo-mila --no-verify-jwt
npx supabase functions deploy atelie-zuri --no-verify-jwt
npx supabase functions deploy minijogo --no-verify-jwt
npx supabase functions deploy explicar-foto --no-verify-jwt
npx supabase functions deploy revanche-prova --no-verify-jwt
```

O professor cria a conta dele no app (Sou professor) e precisa confirmar o
e-mail: o painel dele só mostra as crianças que os responsáveis liberaram
para esse e-mail confirmado (`painel_professor` e `avaliacao_desempenho`,
migration 0014). Ele vê só o resumo de desempenho, nunca textos, fotos ou
provas. A Revanche da prova continua com o envio de fotos só pelo
responsável; a criança treina.

## Limites de uso da IA e cuidados de segurança (migration 0016)

Rode `supabase/migrations/0016_seguranca_limites.sql` **antes** de publicar
de novo as funções. A partir dela, cada chamada à OpenAI reserva uma vaga
pela função SQL `reservar_uso_ia` antes de chamar a IA, com três limites a
cada 24 horas:

- por criança e módulo: os `LIMITE_..._POR_DIA` de cada função (acima);
- por família (todas as crianças de um responsável):
  `LIMITE_IA_FAMILIA_POR_DIA` (padrão 300);
- no app todo: `LIMITE_IA_GLOBAL_POR_DIA` (padrão 3000). Quando estoura, a
  IA fica fechada até o dia seguinte para todo mundo: é o freio de custo.

Sem a migration 0016, as funções respondem "A Liga ainda está sendo
preparada" (a IA fica fechada em vez de ficar sem limite). Cada responsável
pode ter até 10 crianças.

```bash
npx supabase functions deploy detetive-leitura --no-verify-jwt
npx supabase functions deploy desafio-matematica --no-verify-jwt
npx supabase functions deploy oficina-texto --no-verify-jwt
npx supabase functions deploy expedicao-teo --no-verify-jwt
npx supabase functions deploy arquivo-mila --no-verify-jwt
npx supabase functions deploy atelie-zuri --no-verify-jwt
npx supabase functions deploy minijogo --no-verify-jwt
npx supabase functions deploy explicar-foto --no-verify-jwt
npx supabase functions deploy revanche-prova --no-verify-jwt
npx supabase functions deploy contas-liga --no-verify-jwt
npx supabase functions deploy voz-heroi --no-verify-jwt
```

Fora do código, confira no painel:

1. **OpenAI > Settings > Limits:** um limite mensal de gasto (budget). É a
   última barreira se algo escapar dos limites acima.
2. **Supabase > Authentication > Sign In / Providers > Email:** "Confirm
   email" ligado. Sem isso, qualquer pessoa cria uma conta com o e-mail de
   um professor antes dele e vê o painel das crianças liberadas para ele.
3. **Domínio dos logins das crianças:** os logins usam e-mails
   `@crianca.gpmkt.art.br` (subdomínio do domínio da GPLABS; nunca recebem
   e-mail). Mantenha o `gpmkt.art.br` renovado: quem for dono do domínio
   poderia pedir "esqueci a senha" e receber o link de troca de senha da
   criança. Logins criados antes com `@crianca.ligadosaber.app` passam para
   o domínio novo com a migration 0019.
