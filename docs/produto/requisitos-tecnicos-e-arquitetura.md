# Documento De Requisitos Tecnicos E Arquitetura Inicial

# Liga do Saber

## 1. Objetivo Do Documento

Este documento define os requisitos tecnicos e a arquitetura inicial do MVP da **Liga do Saber**, com foco em app mobile, backend, banco de dados, armazenamento de imagens, integracao com IA, seguranca, privacidade e organizacao do desenvolvimento.

Ele complementa:

- `escopo-mvp-liga-do-saber.md`
- `mapa-de-telas-e-fluxos-mvp-liga-do-saber.md`

## 2. Decisao Tecnica Recomendada Para O MVP

## 2.1 Stack Principal

### App Mobile

**Tecnologia recomendada:** Flutter.

Motivos:

- Uma base de codigo para Android e iOS.
- Excelente suporte a interfaces visuais customizadas.
- Boa performance para animacoes, cards, mapas e experiencias gamificadas.
- Ecossistema maduro para camera, upload de imagem, autenticacao e notificacoes.
- Facilidade de manter identidade visual consistente entre plataformas.

### Backend

**Tecnologia recomendada para MVP:** Supabase.

Motivos:

- PostgreSQL gerenciado.
- Autenticacao pronta.
- Storage para imagens.
- Row Level Security.
- Edge Functions para operacoes sensiveis.
- Agilidade para validar o produto sem montar infraestrutura completa.

### IA

**Abordagem recomendada:** integracao com API de IA multimodal por meio do backend.

Regras:

- O app Flutter nao deve chamar a IA diretamente.
- A chave da IA deve ficar apenas no backend.
- Toda imagem ou texto enviado deve passar por uma funcao segura no servidor.
- As respostas da IA devem ser normalizadas em JSON antes de chegar ao app.

### Banco De Dados

**Tecnologia:** PostgreSQL via Supabase.

### Storage

**Tecnologia:** Supabase Storage.

Uso:

- Guardar imagens de atividades temporariamente.
- Guardar avatares e assets quando necessario.
- Definir politica de expiracao ou limpeza de imagens escolares.

## 3. Arquitetura Geral

## 3.1 Visao Em Camadas

```text
App Flutter
  -> Camada de UI
  -> Camada de Estado
  -> Repositorios
  -> Cliente API/Supabase

Supabase
  -> Auth
  -> PostgreSQL
  -> Storage
  -> Edge Functions

Servicos De IA
  -> Analise de imagem
  -> Correcao textual
  -> Tutoria educacional
  -> Geracao de exercicios
```

## 3.2 Fluxo De IA

```text
Crianca envia foto no app
  -> App comprime imagem
  -> App envia imagem para Storage
  -> App chama Edge Function
  -> Edge Function busca imagem
  -> Edge Function chama API de IA
  -> IA retorna resposta estruturada
  -> Edge Function valida e normaliza JSON
  -> Backend salva correcao
  -> App exibe resultado
```

## 3.3 Principio De Seguranca

O app deve ser considerado um cliente nao confiavel. Qualquer operacao sensivel deve ser validada no backend.

Isso inclui:

- Chamada para IA.
- Calculo final de XP.
- Registro de progresso.
- Acesso a dados do responsavel.
- Acesso a imagens enviadas.

## 4. Estrutura Recomendada Do Projeto Flutter

## 4.1 Organizacao De Pastas

```text
lib/
  main.dart
  app/
    liga_do_saber_app.dart
    router.dart
    theme.dart
    app_config.dart
  core/
    constants/
    errors/
    networking/
    storage/
    utils/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    onboarding/
      presentation/
    child_profile/
      data/
      domain/
      presentation/
    home/
      data/
      domain/
      presentation/
    photo_solver/
      data/
      domain/
      presentation/
    writing_workshop/
      data/
      domain/
      presentation/
    reading_detective/
      data/
      domain/
      presentation/
    math_arena/
      data/
      domain/
      presentation/
    missions/
      data/
      domain/
      presentation/
    progress/
      data/
      domain/
      presentation/
    parent_area/
      data/
      domain/
      presentation/
    profile/
      data/
      domain/
      presentation/
  shared/
    models/
    repositories/
    services/
    design_system/
assets/
  images/
  mascots/
  icons/
  animations/
  fonts/
```

## 4.2 Padrao De Arquitetura No Flutter

Recomendacao para MVP:

- Separar por feature.
- Usar repositorios para acesso a dados.
- Usar modelos tipados.
- Manter UI desacoplada de chamadas diretas ao Supabase/IA.

Padrao recomendado:

```text
Presentation -> Controller/State -> Repository -> Data Source -> Supabase/API
```

## 4.3 Gerenciamento De Estado

Opcoes:

- Riverpod
- Bloc/Cubit
- Provider

Recomendacao:

**Riverpod**, por equilibrar simplicidade, testabilidade e escalabilidade.

Uso sugerido:

- Auth state.
- Perfil da crianca.
- Home data.
- Fluxo de foto.
- Estados de IA.
- Progresso.

## 4.4 Navegacao

Recomendacao:

**go_router**.

Motivos:

- Rotas declarativas.
- Guards de autenticacao.
- Deep links futuros.
- Boa integracao com Flutter moderno.

Rotas iniciais:

```text
/
/onboarding
/login
/child-profile
/avatar
/home
/photo
/photo/confirm
/ai/processing
/ai/result/:id
/writing
/writing/plan
/writing/editor
/writing/feedback/:id
/reading
/reading/case/:id
/math
/missions
/map
/progress
/profile
/parent
```

## 5. Design System Tecnico

## 5.1 Tokens De Cor

```text
primaryBlue: #2563EB
progressGreen: #22C55E
achievementYellow: #FACC15
actionCoral: #FB7185
adventurePurple: #8B5CF6
softWhite: #F8FAFC
textGraphite: #1F2937
deepBlue: #071B3A
deepPurple: #1E124D
cardDark: #111B3D
```

## 5.2 Tipografia

Recomendacao:

- Interface: Nunito, Fredoka ou Rubik Rounded.
- Logo: lettering proprio ja definido na marca.

Regras:

- Tamanhos legiveis para 9 a 12 anos.
- Evitar textos longos em cards.
- Usar alto contraste em fundos escuros.
- Nao depender apenas de cor para indicar estado.

## 5.3 Componentes Base

Criar componentes reutilizaveis:

- `LigaButton`
- `MissionCard`
- `ProgressBar`
- `XPBadge`
- `CharacterCard`
- `SkillChip`
- `BottomNav`
- `LoadingMission`
- `AiFeedbackCard`
- `PhotoCaptureFrame`
- `WritingScorePanel`
- `ReadingClueCard`

## 6. Backend Supabase

## 6.1 Modulos Supabase

Usar:

- Supabase Auth
- PostgreSQL
- Storage
- Edge Functions
- Row Level Security

## 6.2 Ambientes

Criar ambientes separados:

- Development
- Staging
- Production

Variaveis por ambiente:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
AI_API_KEY
AI_PROVIDER
APP_ENV
IMAGE_BUCKET_NAME
```

Regras:

- `SUPABASE_SERVICE_ROLE_KEY` nunca deve ir para o app.
- `AI_API_KEY` nunca deve ir para o app.
- O app usa apenas `SUPABASE_URL` e `SUPABASE_ANON_KEY`.

## 7. Modelo De Dados Inicial

## 7.1 Tabela: responsaveis

Representa o adulto responsavel pela conta.

Campos:

```text
id uuid pk
auth_user_id uuid unique not null
nome text not null
email text not null
created_at timestamptz
updated_at timestamptz
```

## 7.2 Tabela: perfis_criancas

Representa o perfil infantil.

Campos:

```text
id uuid pk
responsavel_id uuid fk
apelido text not null
ano_escolar int
avatar_id text
nivel int default 1
xp_total int default 0
sequencia_dias int default 0
ultima_atividade_em timestamptz
created_at timestamptz
updated_at timestamptz
```

## 7.3 Tabela: materias

Campos:

```text
id text pk
nome text not null
descricao text
personagem_id text
ordem int
ativa boolean default true
```

Materias iniciais:

- portugues
- matematica
- ciencias
- historia
- geografia
- criatividade

## 7.4 Tabela: habilidades

Campos:

```text
id text pk
materia_id text fk
nome text not null
descricao text
ano_escolar_min int
ano_escolar_max int
ativa boolean default true
```

Exemplos:

- ideia_principal
- inferencia
- pontuacao
- producao_paragrafo
- operacoes_basicas
- fracoes_simples

## 7.5 Tabela: missoes

Campos:

```text
id uuid pk
titulo text not null
descricao text
tipo text not null
materia_id text fk
habilidade_id text fk
dificuldade text
xp_base int
conteudo jsonb
ativa boolean default true
created_at timestamptz
updated_at timestamptz
```

Tipos:

- leitura
- escrita
- matematica
- foto
- desafio_relampago
- cruzadas

## 7.6 Tabela: progresso_missoes

Campos:

```text
id uuid pk
perfil_crianca_id uuid fk
missao_id uuid fk
status text
tentativas int default 0
xp_recebido int default 0
iniciada_em timestamptz
concluida_em timestamptz
created_at timestamptz
updated_at timestamptz
```

Status:

- nao_iniciada
- em_andamento
- concluida
- revisao_recomendada

## 7.7 Tabela: atividades_foto

Campos:

```text
id uuid pk
perfil_crianca_id uuid fk
storage_path text
materia_detectada text
tipo_atividade text
status text
created_at timestamptz
updated_at timestamptz
```

Status:

- enviada
- processando
- corrigida
- ilegivel
- erro
- fora_do_escopo

## 7.8 Tabela: correcoes_ia

Campos:

```text
id uuid pk
perfil_crianca_id uuid fk
atividade_foto_id uuid null fk
missao_id uuid null fk
tipo text not null
entrada_resumo text
resposta_json jsonb not null
xp_sugerido int default 0
modelo_usado text
created_at timestamptz
```

Tipos:

- foto
- texto
- leitura
- matematica
- geracao_exercicio

## 7.9 Tabela: producoes_textuais

Campos:

```text
id uuid pk
perfil_crianca_id uuid fk
missao_id uuid null fk
tema text not null
planejamento jsonb
texto_original text
texto_reescrito text
feedback_json jsonb
status text
xp_recebido int default 0
created_at timestamptz
updated_at timestamptz
```

Status:

- rascunho
- aguardando_feedback
- feedback_recebido
- reescrito
- concluido

## 7.10 Tabela: respostas_leitura

Campos:

```text
id uuid pk
perfil_crianca_id uuid fk
missao_id uuid fk
pergunta_id text
resposta text
status text
feedback_json jsonb
xp_recebido int default 0
created_at timestamptz
```

## 7.11 Tabela: badges

Campos:

```text
id text pk
nome text not null
descricao text
icone text
criterio jsonb
ativa boolean default true
```

## 7.12 Tabela: badges_criancas

Campos:

```text
id uuid pk
perfil_crianca_id uuid fk
badge_id text fk
conquistado_em timestamptz
```

## 7.13 Tabela: relatorios_semanais

Campos:

```text
id uuid pk
perfil_crianca_id uuid fk
semana_inicio date
semana_fim date
resumo_json jsonb
created_at timestamptz
```

## 8. Row Level Security

## 8.1 Regra Geral

Cada responsavel so pode acessar:

- seus proprios dados;
- perfis de criancas vinculados a ele;
- atividades, progresso e relatorios desses perfis.

## 8.2 Operacoes Restritas Ao Backend

Somente Edge Functions com permissao elevada devem:

- calcular XP final;
- gravar correcao oficial da IA;
- atualizar sequencia diaria;
- processar imagem;
- gerar relatorio semanal;
- acessar service role;
- limpar imagens antigas.

## 9. Edge Functions Recomendadas

## 9.1 `analisar_atividade_foto`

Entrada:

```json
{
  "perfil_crianca_id": "",
  "storage_path": ""
}
```

Responsabilidades:

- Validar dono do perfil.
- Baixar imagem do storage.
- Chamar IA multimodal.
- Normalizar resposta.
- Salvar em `atividades_foto` e `correcoes_ia`.
- Retornar resultado para app.

## 9.2 `corrigir_texto`

Entrada:

```json
{
  "perfil_crianca_id": "",
  "producao_textual_id": "",
  "texto": "",
  "tema": "",
  "ano_escolar": 5
}
```

Responsabilidades:

- Corrigir texto.
- Gerar feedback adequado.
- Sugerir reescrita.
- Salvar feedback.

## 9.3 `avaliar_resposta_leitura`

Entrada:

```json
{
  "perfil_crianca_id": "",
  "missao_id": "",
  "pergunta_id": "",
  "resposta": ""
}
```

Responsabilidades:

- Avaliar resposta.
- Explicar com base no texto.
- Salvar desempenho.

## 9.4 `gerar_exercicio_parecido`

Entrada:

```json
{
  "perfil_crianca_id": "",
  "correcao_ia_id": ""
}
```

Responsabilidades:

- Criar exercicio semelhante.
- Manter dificuldade apropriada.
- Retornar conteudo estruturado.

## 9.5 `registrar_conclusao_missao`

Entrada:

```json
{
  "perfil_crianca_id": "",
  "missao_id": "",
  "resultado": {}
}
```

Responsabilidades:

- Validar conclusao.
- Calcular XP.
- Atualizar progresso.
- Atualizar badges.
- Atualizar sequencia.

## 9.6 `gerar_relatorio_semanal`

Responsabilidades:

- Consolidar atividades.
- Identificar pontos fortes.
- Identificar pontos a praticar.
- Gerar resumo para responsavel.

## 10. Contratos De API Para IA

## 10.1 Resposta De Foto

```json
{
  "tipo_atividade": "matematica",
  "materia": "matematica",
  "enunciado_extraido": "Quanto e 24 dividido por 3?",
  "resposta_detectada": "8",
  "status": "correto",
  "feedback_curto": "Boa! A resposta esta correta.",
  "explicacao": "24 dividido por 3 significa separar 24 em 3 grupos iguais. Cada grupo fica com 8.",
  "dica": "Quando tiver duvida, pense em grupos iguais.",
  "proxima_acao_recomendada": "gerar_parecida",
  "xp_sugerido": 20
}
```

## 10.2 Resposta De Texto

```json
{
  "elogio": "Voce criou uma ideia principal clara.",
  "clareza": 4,
  "organizacao": 3,
  "pontuacao": 2,
  "ortografia": 4,
  "criatividade": 5,
  "pontos_para_melhorar": [
    "Separar melhor as frases com pontos.",
    "Evitar repetir a palavra 'muito' varias vezes."
  ],
  "sugestao_de_reescrita": "Tente dividir o segundo trecho em duas frases.",
  "desafio_de_reescrita": "Reescreva o final usando pelo menos uma palavra de ligacao.",
  "xp_sugerido": 35
}
```

## 10.3 Resposta De Leitura

```json
{
  "resposta_status": "correta",
  "pista_no_texto": "No segundo paragrafo, o personagem diz que voltou porque esqueceu o mapa.",
  "explicacao": "Essa frase mostra o motivo da volta. Por isso a resposta correta e que ele voltou para buscar o mapa.",
  "dica": "Quando a pergunta pede motivo, procure palavras como 'porque', 'pois' ou 'por isso'.",
  "habilidade_trabalhada": "inferencia",
  "xp_sugerido": 15
}
```

## 11. Prompts Tecnicos Da IA

## 11.1 Prompt Base Da Tutoria

```text
Voce e a IA tutora do aplicativo Liga do Saber, um app educacional gamificado para criancas de 9 a 12 anos.

Seu papel e ajudar a crianca a aprender, nao apenas entregar respostas.

Regras:
- Use linguagem simples, clara e respeitosa.
- Comece valorizando algo que a crianca fez bem quando houver resposta dela.
- Explique erros sem humilhar.
- De dicas graduais.
- Nao entregue a resposta final imediatamente quando for melhor estimular nova tentativa.
- Para producao textual, incentive reescrita.
- Para interpretacao, aponte a pista no texto.
- Para matematica, explique o raciocinio passo a passo.
- Retorne apenas JSON valido no formato solicitado.
```

## 11.2 Prompt Para Foto

```text
Analise a imagem enviada. Identifique se ha uma atividade escolar, enunciado, resposta escrita ou texto para interpretacao.

Classifique a atividade, extraia o que for legivel e gere uma correcao pedagogica para uma crianca de 9 a 12 anos.

Se a imagem estiver ilegivel, diga isso com gentileza e sugira nova foto.

Retorne apenas JSON no schema fornecido.
```

## 11.3 Prompt Para Producao Textual

```text
Avalie o texto de uma crianca de 9 a 12 anos.

Nao de apenas nota. Mostre um ponto positivo real, indique melhorias especificas e proponha uma tarefa de reescrita pequena.

Avalie clareza, organizacao, pontuacao, ortografia e criatividade em escala de 0 a 5.

Retorne apenas JSON no schema fornecido.
```

## 11.4 Prompt Para Interpretacao

```text
Avalie a resposta da crianca com base no texto apresentado.

Explique se a resposta esta correta, incorreta ou parcialmente correta.

Sempre que possivel, aponte a pista no texto. Diferencie informacao explicita de inferencia.

Retorne apenas JSON no schema fornecido.
```

## 12. Gamificacao Tecnica

## 12.1 Calculo Inicial De XP

Regras simples para MVP:

- Missao concluida: XP base.
- Tentativa honesta: XP parcial.
- Reescrita de texto: bonus.
- Uso de pista: reduz bonus, mas nao zera progresso.
- Sequencia diaria: bonus pequeno.

Exemplo:

```text
xp_final = xp_base + bonus_reescrita + bonus_sequencia - penalidade_pistas
```

Limites:

- XP minimo por tentativa valida: 5.
- XP maximo por missao simples: 50.
- XP maximo diario no MVP pode ser limitado para evitar uso compulsivo.

## 12.2 Niveis

Regra inicial:

```text
nivel = floor(sqrt(xp_total / 100)) + 1
```

Essa regra pode ser ajustada depois.

## 12.3 Badges Iniciais

Badges sugeridos:

- Primeiro Passo: concluiu primeira missao.
- Detetive Da Leitura: concluiu 5 casos.
- Texto Melhorado: reescreveu 3 textos.
- Estrategista: concluiu 10 desafios matematicos.
- Sequencia 7 Dias: estudou em 7 dias diferentes.

## 13. Requisitos De Imagem

## 13.1 Captura

O app deve:

- Solicitar permissao de camera.
- Permitir galeria.
- Exibir moldura de enquadramento.
- Permitir recorte simples.
- Comprimir imagem antes do upload.

## 13.2 Tamanho

Recomendacao inicial:

- Converter para JPG.
- Limitar largura maxima a 1600 px.
- Comprimir mantendo legibilidade.

## 13.3 Retencao

Politica recomendada para MVP:

- Guardar imagem por tempo limitado.
- Manter correcao estruturada.
- Permitir exclusao pelo responsavel.

Sugestao:

- Imagens de atividade: apagar automaticamente apos 30 dias, salvo se o responsavel optar por manter.

## 14. Seguranca E Privacidade

## 14.1 Dados Infantis

Como o app e voltado para criancas, a privacidade deve ser tratada como requisito central.

Regras:

- Conta principal deve ser do responsavel.
- Crianca nao deve ter perfil publico.
- Nao permitir chat livre entre criancas no MVP.
- Nao exibir ranking publico.
- Nao coletar escola, endereco ou dados sensiveis sem necessidade.
- Permitir exclusao de dados.

## 14.2 Consentimento

No onboarding/cadastro:

- Termos de uso.
- Politica de privacidade.
- Consentimento do responsavel.

## 14.3 Logs

Nao registrar em logs:

- Chaves de API.
- Imagens em base64.
- Conteudo completo de texto da crianca sem necessidade.
- Dados sensiveis.

## 14.4 Moderacao

Todo envio para IA deve passar por validacoes:

- Tamanho maximo.
- Tipo de arquivo.
- Conteudo fora do escopo.
- Conteudo sensivel.

## 15. Requisitos De Performance

## 15.1 App

- Home deve carregar em ate 2 segundos apos login, em conexao normal.
- Animacoes devem ser leves.
- Imagens devem usar cache.
- Evitar rebuilds desnecessarios.

## 15.2 IA

- Mostrar loading amigavel durante analise.
- Se passar de 10 segundos, mostrar mensagem intermediaria.
- Se falhar, oferecer nova tentativa.

## 15.3 Offline Parcial

No MVP:

- App pode abrir Home com dados em cache.
- IA e envio de foto exigem internet.
- Missoes previamente baixadas podem ser lidas, se implementado cache simples.

## 16. Requisitos De Acessibilidade

- Texto com bom contraste.
- Botoes tocaveis com area confortavel.
- Nao depender apenas de cor para status.
- Feedback textual e visual.
- Tamanho de fonte ajustavel em leitura.
- Evitar excesso de elementos animados em telas de leitura e escrita.

## 17. Notificacoes

No MVP, notificacoes devem ser simples e opcionais.

Tipos:

- Lembrete de missao diaria.
- Sequencia em risco.
- Relatorio semanal para responsavel.

Regras:

- Nao usar notificacoes excessivas.
- Responsavel deve poder desativar.

## 18. Analytics Do Produto

Eventos importantes:

```text
app_opened
onboarding_completed
child_profile_created
mission_started
mission_completed
photo_uploaded
ai_result_received
ai_result_failed
writing_started
writing_feedback_received
writing_rewritten
reading_case_started
reading_case_completed
math_challenge_completed
parent_report_viewed
```

Metricas principais:

- Ativacao: concluiu primeira missao.
- Retencao: voltou em D1, D7.
- Uso de IA: fotos enviadas e corrigidas.
- Escrita: textos reescritos.
- Leitura: casos concluidos.
- Tempo medio de sessao.
- Taxa de erro da IA.

## 19. Testes

## 19.1 Testes Flutter

Tipos:

- Unit tests para regras de XP.
- Unit tests para modelos.
- Widget tests para componentes principais.
- Tests de navegacao basica.

## 19.2 Testes Backend

Tipos:

- Teste de RLS.
- Teste de Edge Functions.
- Teste de schemas de IA.
- Teste de permissao de storage.

## 19.3 Testes De IA

Criar massa de exemplos:

- Foto legivel de matematica.
- Foto ilegivel.
- Questao de interpretacao.
- Texto curto com erros.
- Texto bom para a idade.
- Conteudo fora do escopo.

Validar:

- JSON valido.
- Tom adequado.
- Nao entrega resposta quando deveria dar dica.
- Explicacao compreensivel.

## 20. Plano De Desenvolvimento Por Sprints

## Sprint 0: Preparacao

Objetivo:

Criar base tecnica.

Entregas:

- Criar projeto Flutter.
- Configurar tema.
- Configurar roteamento.
- Configurar Supabase.
- Criar estrutura de pastas.
- Adicionar assets da marca.
- Criar design system inicial.

## Sprint 1: Autenticacao E Perfil

Entregas:

- Splash.
- Onboarding.
- Cadastro/login do responsavel.
- Criacao de perfil da crianca.
- Escolha de avatar.
- Home inicial com dados mockados ou reais.

## Sprint 2: Home E Missoes

Entregas:

- Home final do MVP.
- Cards principais.
- XP/nivel/sequencia.
- Missoes recomendadas.
- Navegacao inferior.

## Sprint 3: Foto + IA

Entregas:

- Captura de foto.
- Galeria.
- Confirmar foto.
- Upload para storage.
- Edge Function de analise.
- Resultado da IA.
- Estados de erro.

## Sprint 4: Oficina De Texto

Entregas:

- Planejamento.
- Editor de texto.
- Correcao com IA.
- Feedback.
- Reescrita.
- Resultado com XP.

## Sprint 5: Detetive Da Leitura

Entregas:

- Lista de casos.
- Leitura.
- Perguntas.
- Feedback.
- Conclusao.
- Registro de progresso.

## Sprint 6: Arena Matematica, Progresso E Responsaveis

Entregas:

- Desafios matematicos.
- Tela de progresso.
- Badges iniciais.
- Area dos responsaveis.
- Relatorio semanal simples.

## Sprint 7: Polimento E Beta

Entregas:

- Ajustes de UI.
- Testes.
- Tratamento de erros.
- Performance.
- Revisao de seguranca.
- Build Android.
- Preparacao para iOS.

## 21. Decisoes Pendentes

Antes da implementacao completa, decidir:

- Supabase ou Firebase definitivamente.
- Provedor principal de IA.
- Modelo exato de IA multimodal.
- Politica final de retencao de imagens.
- Se havera assinatura ja no MVP.
- Fonte oficial de interface.
- Formato final dos assets dos mascotes.
- Nivel de conteudo por ano escolar na primeira versao.
- Idioma inicial apenas Portugues do Brasil.

## 22. Riscos Tecnicos

## 22.1 IA Lendo Imagem Errado

Mitigacao:

- Confirmar enunciado extraido.
- Permitir editar/digitar atividade.
- Mostrar incerteza quando necessario.

## 22.2 Custo De IA

Mitigacao:

- Comprimir imagens.
- Limitar numero diario no MVP.
- Cachear resultados.
- Usar chamadas mais simples quando nao precisar de visao.

## 22.3 Conteudo Inadequado

Mitigacao:

- Guardrails.
- Moderacao.
- Respostas restritas a finalidade educacional.

## 22.4 Complexidade Visual

Mitigacao:

- Criar design system cedo.
- Reutilizar componentes.
- Comecar com home funcional antes de animacoes complexas.

## 22.5 Privacidade Infantil

Mitigacao:

- Conta do responsavel.
- Dados minimos.
- RLS.
- Sem interacao social no MVP.
- Exclusao de dados.

## 23. Criterios Tecnicos Para MVP Pronto

O MVP tecnico pode ser considerado pronto quando:

- Usuario responsavel consegue criar conta.
- Crianca consegue criar perfil.
- Home carrega com progresso.
- Crianca consegue enviar foto.
- IA retorna correcao estruturada.
- Crianca consegue escrever texto e receber feedback.
- Crianca consegue concluir caso de leitura.
- XP e progresso sao registrados.
- Responsavel consegue ver resumo.
- Dados sensiveis nao ficam expostos no app.
- App tem build Android funcional.
- Estrutura esta preparada para build iOS.

## 24. Proxima Etapa Recomendada

Com a arquitetura definida, a proxima etapa e iniciar a **Sprint 0**, criando o projeto Flutter, configurando a estrutura base, tema visual da Liga do Saber, rotas principais e assets iniciais.

Antes disso, recomenda-se copiar os assets aprovados para uma pasta organizada do projeto:

```text
assets/
  brand/
  icons/
  mascots/
  backgrounds/
```

Depois, podemos criar a primeira versao navegavel com telas estaticas, ainda sem backend, para validar fluxo e visual antes de integrar IA.

