# Mapa De Telas E Fluxos MVP

# Liga do Saber

## 1. Objetivo Do Documento

Este documento define o mapa de telas, navegacao e fluxos principais do MVP da **Liga do Saber**. Ele serve como guia para prototipo visual, design de interface, desenvolvimento Flutter, backend e integracao com IA.

O MVP deve priorizar tres experiencias centrais:

- Enviar foto de atividade e receber correcao com IA.
- Praticar interpretacao e leitura no Detetive da Leitura.
- Produzir e melhorar textos na Oficina de Texto.

Matematica entra como modulo essencial de reforco, mas a identidade do produto deve valorizar fortemente leitura, interpretacao e producao textual.

## 2. Arquitetura Geral De Navegacao

### 2.1 Areas Principais

O app sera organizado em cinco areas principais no menu inferior:

1. **Home**
2. **Mapa**
3. **Missoes**
4. **Progresso**
5. **Perfil**

Observacao: no prototipo conceitual apareceu "Ranking", mas para o MVP recomenda-se trocar por **Progresso**, porque a experiencia deve evitar competicao publica entre criancas. Ranking pode existir depois como ranking pessoal, sem comparacao social agressiva.

### 2.2 Acoes Globais

Algumas acoes devem estar acessiveis em mais de uma tela:

- Enviar foto da atividade.
- Continuar missao.
- Ver progresso.
- Abrir perfil.
- Sair para area dos responsaveis.

### 2.3 Estrutura Simplificada

```text
Splash
  -> Onboarding
    -> Cadastro/Login Responsavel
      -> Criar Perfil Da Crianca
        -> Escolher Avatar
          -> Home / Base Da Liga

Home
  -> Enviar Foto
  -> Continuar Missao
  -> Oficina De Texto
  -> Detetive Da Leitura
  -> Arena Matematica
  -> Missoes
  -> Progresso
  -> Perfil

Perfil
  -> Area Dos Responsaveis
  -> Configuracoes
```

## 3. Principios De UX Do MVP

### 3.1 Para A Crianca

- Sempre deve haver uma proxima acao clara.
- Missoes devem durar entre 3 e 8 minutos.
- O erro deve gerar dica, nao punicao.
- Feedback visual deve ser rapido.
- Texto em tela deve ser curto, direto e legivel.
- A interface deve parecer jogo mobile moderno, nao app escolar tradicional.

### 3.2 Para O Responsavel

- Relatorios devem ser simples.
- O responsavel deve entender se a crianca praticou, evoluiu e onde precisa de apoio.
- Nao usar linguagem tecnica demais.
- Evitar mostrar apenas erros; mostrar progresso e sugestoes.

### 3.3 Para IA

- A IA deve se comportar como tutora.
- A IA deve explicar, dar pistas e incentivar nova tentativa.
- A IA deve evitar entregar resposta pronta logo de inicio.
- A IA deve adaptar o tom para criancas de 9 a 12 anos.

## 4. Mapa De Telas

## 4.1 Splash Screen

### Objetivo

Apresentar a marca e preparar o carregamento inicial do app.

### Componentes

- Fundo visual da marca.
- Icone da Liga.
- Logo Liga do Saber.
- Pequena animacao de brilho/energia.

### Acoes

- Carregar sessao.
- Verificar se existe usuario logado.
- Direcionar para Home ou Onboarding.

### Estados

- Carregando.
- Sem sessao.
- Sessao ativa.
- Erro de conexao.

### Navegacao

- Se novo usuario: Onboarding.
- Se usuario logado: Home.
- Se erro: tela simples com tentar novamente.

## 4.2 Onboarding

### Objetivo

Explicar a proposta do app em poucas telas.

### Telas Internas

1. **Aprender Vira Missao**
   - Apresenta Liga do Saber.
   - Mostra personagens.

2. **Envie Uma Atividade**
   - Explica foto + IA.

3. **Leia, Escreva E Evolua**
   - Destaca Detetive da Leitura e Oficina de Texto.

4. **Responsaveis Acompanham**
   - Explica acompanhamento sem pressao.

### Componentes

- Ilustracao ou personagem.
- Titulo curto.
- Texto curto.
- Indicador de paginas.
- Botao "Continuar".
- Botao "Pular" opcional.

### Navegacao

- Ultima tela: Cadastro/Login Responsavel.

## 4.3 Cadastro/Login Do Responsavel

### Objetivo

Criar a conta principal do adulto responsavel.

### Componentes

- Abas: Entrar / Criar Conta.
- Campo nome.
- Campo e-mail.
- Campo senha.
- Aceite de termos.
- Botao continuar.
- Link "Ja tenho conta".

### Acoes

- Criar conta.
- Entrar.
- Validar campos.
- Aceitar termos.

### Estados

- Campos vazios.
- Erro de e-mail.
- Senha fraca.
- Conta ja existente.
- Sem internet.
- Login realizado.

### Navegacao

- Criacao com sucesso: Criar Perfil Da Crianca.
- Login com perfil existente: Home.
- Login sem perfil infantil: Criar Perfil Da Crianca.

## 4.4 Criar Perfil Da Crianca

### Objetivo

Configurar o primeiro perfil infantil.

### Componentes

- Nome ou apelido.
- Ano escolar.
- Materias que quer melhorar.
- Preferencia de personagem inicial.
- Botao continuar.

### Acoes

- Informar apelido.
- Selecionar ano escolar.
- Selecionar areas de foco.

### Estados

- Nome vazio.
- Ano nao selecionado.
- Perfil criado.

### Navegacao

- Escolher Avatar.

## 4.5 Escolher Avatar

### Objetivo

Dar senso de identidade e pertencimento a Liga.

### Componentes

- Lista de avatares iniciais.
- Preview do avatar.
- Nome da crianca.
- Botao "Entrar para a Liga".

### Acoes

- Escolher avatar.
- Confirmar escolha.

### Estados

- Avatar nao selecionado.
- Avatar selecionado.

### Navegacao

- Home / Base Da Liga.

## 4.6 Home / Base Da Liga

### Objetivo

Ser o hub principal do app, com acesso rapido a missoes, foto, texto, leitura e matematica.

### Componentes

- Cabecalho com avatar, nome, nivel e XP.
- Sequencia diaria.
- Botao principal: "Continuar Missao".
- Botao destacado: "Enviar Foto Da Atividade".
- Card "Oficina De Texto".
- Card "Detetive Da Leitura".
- Card "Arena Matematica".
- Card menor de missao recomendada.
- Acesso a recompensas/badges.
- Menu inferior.

### Acoes

- Continuar missao em andamento.
- Enviar foto.
- Abrir modulo de texto.
- Abrir modulo de leitura.
- Abrir modulo de matematica.
- Ver missoes.
- Ver progresso.

### Estados

- Primeiro acesso sem missoes feitas.
- Missao em andamento.
- Missao diaria disponivel.
- Sequencia ativa.
- Sem internet.
- IA indisponivel.

### Navegacao

- Enviar Foto.
- Oficina De Texto.
- Detetive Da Leitura.
- Arena Matematica.
- Missoes.
- Progresso.
- Perfil.

### Regras

- O botao "Enviar Foto" deve estar sempre visivel na Home.
- Oficina de Texto e Detetive da Leitura devem ter destaque igual ou maior que Matematica.
- A Home nao deve exibir elementos demais ao mesmo tempo.

## 4.7 Enviar Foto Da Atividade

### Objetivo

Permitir que a crianca envie uma atividade escolar para analise e correcao por IA.

### Componentes

- Camera.
- Botao galeria.
- Moldura de enquadramento.
- Instrucao curta: "Enquadre a atividade".
- Botao tirar foto.
- Botao voltar.

### Acoes

- Abrir camera.
- Selecionar imagem.
- Capturar foto.
- Repetir captura.
- Confirmar envio.

### Estados

- Permissao de camera negada.
- Camera indisponivel.
- Foto tremida.
- Imagem escura.
- Imagem confirmada.
- Upload em andamento.

### Navegacao

- Confirmar Foto.
- Home.

## 4.8 Confirmar Foto

### Objetivo

Permitir revisar a imagem antes do envio.

### Componentes

- Preview da imagem.
- Ferramenta simples de corte.
- Botao "Usar esta foto".
- Botao "Tirar outra".
- Dica: "A atividade precisa estar legivel".

### Acoes

- Ajustar enquadramento.
- Confirmar.
- Refazer.

### Estados

- Imagem valida.
- Imagem possivelmente ilegivel.

### Navegacao

- Processando IA.
- Enviar Foto.

## 4.9 Processando IA

### Objetivo

Mostrar que a IA esta analisando a atividade.

### Componentes

- Animacao de analise.
- Personagem relacionado a materia, se detectavel.
- Mensagens curtas.
- Barra ou indicador de progresso indeterminado.

### Mensagens Possiveis

- "Lendo a atividade..."
- "Procurando pistas..."
- "Montando uma explicacao..."
- "Quase pronto..."

### Estados

- Processando.
- Demora acima do esperado.
- Falha de conexao.
- IA indisponivel.

### Navegacao

- Resultado Da IA.
- Erro De Analise.

## 4.10 Resultado Da IA

### Objetivo

Apresentar correcao, explicacao e proximo passo.

### Componentes

- Materia identificada.
- Enunciado extraido.
- Resposta detectada, se houver.
- Status: correto, parcialmente correto, precisa revisar ou nao identificado.
- Explicacao simples.
- Dica.
- Botao "Tentar de novo".
- Botao "Ver passo a passo".
- Botao "Gerar questao parecida".
- XP recebido.

### Acoes

- Ver explicacao completa.
- Refazer.
- Gerar exercicio parecido.
- Salvar em progresso.
- Voltar para Home.

### Estados

- Atividade corrigida.
- Texto parcialmente lido.
- Imagem nao compreendida.
- Questao fora do escopo.
- Conteudo sensivel ou inadequado.

### Navegacao

- Passo A Passo.
- Exercicio Parecido.
- Home.
- Enviar Foto.

## 4.11 Erro De Analise

### Objetivo

Resolver casos em que a IA nao consegue analisar a foto.

### Componentes

- Mensagem amigavel.
- Motivo provavel.
- Dicas de nova foto.
- Botao "Tirar outra foto".
- Botao "Digitar atividade".

### Mensagens

- "Nao consegui ler tudo nesta imagem."
- "Tente aproximar um pouco mais e deixar a folha bem iluminada."

### Navegacao

- Enviar Foto.
- Digitar Atividade.
- Home.

## 4.12 Digitar Atividade

### Objetivo

Ser alternativa quando a foto falha.

### Componentes

- Campo para enunciado.
- Campo opcional para resposta.
- Seletor de materia.
- Botao analisar.

### Acoes

- Digitar questao.
- Escolher materia.
- Enviar para IA.

### Navegacao

- Processando IA.
- Resultado Da IA.

## 4.13 Passo A Passo

### Objetivo

Explicar a resolucao sem apenas entregar resposta.

### Componentes

- Etapas numeradas.
- Destaques visuais.
- Dicas graduais.
- Botao "Entendi".
- Botao "Quero tentar".

### Acoes

- Avancar etapa.
- Voltar etapa.
- Tentar novamente.

### Navegacao

- Resultado Da IA.
- Tentar Novamente.

## 4.14 Oficina De Texto

### Objetivo

Desenvolver producao textual com planejamento, escrita, feedback e reescrita.

### Componentes

- Tema da missao.
- Personagem Luma ou Zuri.
- Nivel de dificuldade.
- Botao "Comecar".
- Historico de textos anteriores.

### Acoes

- Escolher tema.
- Continuar texto.
- Comecar nova producao.

### Estados

- Sem textos anteriores.
- Texto em andamento.
- Texto aguardando reescrita.

### Navegacao

- Planejar Texto.
- Escrever Texto.
- Feedback De Texto.

## 4.15 Planejar Texto

### Objetivo

Ajudar a crianca a organizar ideias antes de escrever.

### Componentes

- Pergunta guia.
- Campos curtos:
  - Ideia principal.
  - Personagens ou exemplos.
  - Onde acontece.
  - Comeco.
  - Meio.
  - Final.
- Botao "Escrever texto".

### Acoes

- Preencher ideias.
- Pular planejamento.
- Ir para escrita.

### Navegacao

- Escrever Texto.

## 4.16 Escrever Texto

### Objetivo

Permitir escrita de texto curto.

### Componentes

- Tema visivel.
- Campo de texto.
- Contador de palavras ou linhas.
- Dicas leves.
- Botao "Enviar para Luma".

### Acoes

- Escrever.
- Salvar rascunho.
- Enviar para feedback.

### Estados

- Texto vazio.
- Texto curto demais.
- Rascunho salvo.
- Enviando.

### Navegacao

- Feedback De Texto.

## 4.17 Feedback De Texto

### Objetivo

Mostrar avaliacao construtiva da IA.

### Componentes

- Elogio especifico.
- Pontos para melhorar.
- Sugestao de reescrita.
- Indicadores:
  - Clareza.
  - Organizacao.
  - Pontuacao.
  - Criatividade.
- Botao "Reescrever".
- Botao "Finalizar".

### Regras

- Feedback deve comecar por algo positivo real.
- Nao deve dar apenas nota.
- Deve pedir uma acao clara de melhoria.

### Navegacao

- Reescrever Texto.
- Resultado Texto.

## 4.18 Reescrever Texto

### Objetivo

Estimular melhoria ativa.

### Componentes

- Texto original.
- Dicas da IA.
- Novo campo de texto.
- Botao "Comparar versoes".

### Acoes

- Reescrever.
- Comparar.

### Navegacao

- Resultado Texto.

## 4.19 Resultado Texto

### Objetivo

Mostrar evolucao e recompensa.

### Componentes

- Comparacao antes/depois.
- Melhoria destacada.
- XP recebido.
- Badge, se aplicavel.
- Botao "Nova missao".
- Botao "Voltar para Home".

### Navegacao

- Oficina De Texto.
- Home.
- Progresso.

## 4.20 Detetive Da Leitura

### Objetivo

Trabalhar interpretacao de texto como investigacao.

### Componentes

- Caso/missao.
- Texto curto.
- Personagem Luma ou Mila.
- Botao "Comecar investigacao".

### Acoes

- Selecionar caso.
- Continuar caso.

### Estados

- Caso novo.
- Caso em andamento.
- Caso concluido.

### Navegacao

- Leitura Do Caso.

## 4.21 Leitura Do Caso

### Objetivo

Apresentar texto de forma legivel.

### Componentes

- Texto.
- Botao aumentar fonte.
- Botao "Marcar pista".
- Botao "Responder".

### Acoes

- Ler texto.
- Marcar trecho.
- Avancar para perguntas.

### Navegacao

- Perguntas De Interpretacao.

## 4.22 Perguntas De Interpretacao

### Objetivo

Avaliar compreensao, inferencia e vocabulario.

### Componentes

- Pergunta.
- Alternativas ou campo curto.
- Botao "Ver pista".
- Botao responder.
- Indicador de progresso do caso.

### Acoes

- Responder.
- Pedir pista.
- Avancar.

### Estados

- Resposta correta.
- Resposta incorreta.
- Resposta parcialmente correta.
- Pista usada.

### Navegacao

- Feedback De Leitura.
- Conclusao Do Caso.

## 4.23 Feedback De Leitura

### Objetivo

Explicar a resposta usando pistas do texto.

### Componentes

- Correto/incorreto.
- Trecho que prova a resposta.
- Explicacao curta.
- Botao "Proxima pista".

### Regras

- A explicacao deve apontar onde no texto estava a pista.
- Deve diferenciar "o que esta escrito" de "o que podemos concluir".

### Navegacao

- Perguntas De Interpretacao.
- Conclusao Do Caso.

## 4.24 Conclusao Do Caso

### Objetivo

Fechar a missao de leitura com senso de conquista.

### Componentes

- Resultado do caso.
- XP recebido.
- Habilidades praticadas.
- Badge, se aplicavel.
- Botao "Proximo caso".
- Botao "Home".

### Navegacao

- Detetive Da Leitura.
- Home.
- Progresso.

## 4.25 Arena Matematica

### Objetivo

Praticar matematica em missoes curtas.

### Componentes

- Lista de desafios.
- Nivel de dificuldade.
- Progresso por habilidade.
- Personagem Nico.

### Acoes

- Escolher desafio.
- Continuar desafio.

### Navegacao

- Questao Matematica.

## 4.26 Questao Matematica

### Objetivo

Resolver uma questao por vez.

### Componentes

- Enunciado.
- Campo de resposta.
- Botao dica.
- Botao responder.
- Indicador de vidas/tentativas, se usado.

### Acoes

- Responder.
- Pedir dica.
- Ver passo a passo.

### Estados

- Correto.
- Incorreto.
- Parcial.
- Dica usada.

### Navegacao

- Feedback Matematica.

## 4.27 Feedback Matematica

### Objetivo

Explicar o raciocinio.

### Componentes

- Resultado.
- Explicacao curta.
- Passo a passo opcional.
- Botao "Proxima".
- Botao "Tentar outra".

### Navegacao

- Questao Matematica.
- Conclusao Desafio Matematica.

## 4.28 Conclusao Desafio Matematica

### Objetivo

Fechar rodada com recompensa.

### Componentes

- Acertos.
- Tentativas.
- XP.
- Habilidade praticada.
- Botao "Novo desafio".
- Botao "Home".

### Navegacao

- Arena Matematica.
- Home.

## 4.29 Missoes

### Objetivo

Listar missoes diarias, recomendadas e por materia.

### Componentes

- Abas:
  - Hoje
  - Recomendadas
  - Texto
  - Leitura
  - Matematica
- Cards de missao.
- Status da missao.
- Recompensa em XP.

### Acoes

- Abrir missao.
- Filtrar por area.

### Navegacao

- Tela do modulo correspondente.
- Home.

## 4.30 Mapa

### Objetivo

Mostrar progresso narrativo por mundos/areas.

### Componentes

- Base da Liga.
- Portais por area.
- Indicador de progresso por mundo.
- Personagens.
- Missoes bloqueadas/desbloqueadas.

### Areas

- Ilha dos Numeros.
- Biblioteca Viva.
- Oficina de Texto.
- Laboratorio do Teo.
- Arquivo da Mila.
- Oficina do Zuri.

### Navegacao

- Abrir area.
- Ver missoes da area.

## 4.31 Progresso

### Objetivo

Mostrar evolucao da crianca.

### Componentes

- Nivel.
- XP total.
- Sequencia.
- Badges.
- Grafico simples por area.
- Pontos fortes.
- Pontos a praticar.

### Acoes

- Ver detalhes por area.
- Abrir badge.
- Continuar pratica recomendada.

### Navegacao

- Detalhe De Area.
- Missoes recomendadas.

## 4.32 Detalhe De Area

### Objetivo

Mostrar desempenho em uma area especifica.

### Componentes

- Area selecionada.
- Habilidades.
- Missoes concluidas.
- Taxa de acerto ou evolucao.
- Proxima recomendacao.

### Navegacao

- Missao recomendada.
- Progresso.

## 4.33 Perfil

### Objetivo

Gerenciar perfil infantil e configuracoes.

### Componentes

- Avatar.
- Nome.
- Ano escolar.
- Nivel.
- Personalizacao basica.
- Botao "Area dos responsaveis".
- Configuracoes.

### Navegacao

- Area Dos Responsaveis.
- Configuracoes.
- Home.

## 4.34 Area Dos Responsaveis

### Objetivo

Apresentar resumo de uso e evolucao.

### Componentes

- Bloqueio por senha/PIN.
- Resumo semanal.
- Tempo de estudo.
- Missoes concluidas.
- Areas praticadas.
- Dificuldades observadas.
- Sugestoes de apoio.

### Acoes

- Ver relatorio.
- Configurar conta.
- Gerenciar dados.

### Navegacao

- Relatorio Semanal.
- Configuracoes Responsavel.
- Perfil.

## 4.35 Relatorio Semanal

### Objetivo

Dar visao simples de progresso.

### Componentes

- Periodo.
- Destaques positivos.
- Area que precisa de treino.
- Atividades feitas.
- Sugestao para responsavel.

### Navegacao

- Area Dos Responsaveis.

## 4.36 Configuracoes

### Objetivo

Gerenciar preferencias basicas.

### Componentes

- Conta.
- Notificacoes.
- Privacidade.
- Termos.
- Sair.

### Navegacao

- Perfil.
- Login.

## 5. Fluxos Principais

## 5.1 Fluxo A: Primeiro Acesso

```text
Splash
  -> Onboarding 1
  -> Onboarding 2
  -> Onboarding 3
  -> Onboarding 4
  -> Cadastro Responsavel
  -> Criar Perfil Da Crianca
  -> Escolher Avatar
  -> Home
  -> Primeira Missao Recomendada
```

### Criterio De Sucesso

A crianca deve chegar na Home e entender o primeiro passo em ate 10 segundos.

## 5.2 Fluxo B: Enviar Foto E Corrigir Atividade

```text
Home
  -> Enviar Foto
  -> Confirmar Foto
  -> Processando IA
  -> Resultado Da IA
    -> Ver Passo A Passo
    -> Tentar De Novo
    -> Gerar Questao Parecida
    -> Home
```

### Criterio De Sucesso

A crianca entende o resultado da IA e sabe o que fazer depois: tentar novamente, ver explicacao ou praticar questao parecida.

## 5.3 Fluxo C: Foto Ilegivel

```text
Enviar Foto
  -> Confirmar Foto
  -> Processando IA
  -> Erro De Analise
    -> Tirar Outra Foto
    -> Digitar Atividade
    -> Home
```

### Criterio De Sucesso

O erro nao deve parecer falha da crianca. Deve orientar uma nova tentativa.

## 5.4 Fluxo D: Oficina De Texto

```text
Home
  -> Oficina De Texto
  -> Planejar Texto
  -> Escrever Texto
  -> Feedback De Texto
  -> Reescrever Texto
  -> Resultado Texto
  -> Home
```

### Criterio De Sucesso

A crianca percebe que melhorou o texto, nao apenas que recebeu correcao.

## 5.5 Fluxo E: Detetive Da Leitura

```text
Home
  -> Detetive Da Leitura
  -> Leitura Do Caso
  -> Perguntas De Interpretacao
  -> Feedback De Leitura
  -> Perguntas De Interpretacao
  -> Conclusao Do Caso
  -> Home
```

### Criterio De Sucesso

A crianca entende que interpretar e encontrar pistas no texto, nao adivinhar.

## 5.6 Fluxo F: Arena Matematica

```text
Home
  -> Arena Matematica
  -> Questao Matematica
  -> Feedback Matematica
  -> Questao Matematica
  -> Conclusao Desafio Matematica
  -> Home
```

### Criterio De Sucesso

A crianca entende o erro e consegue tentar uma questao parecida.

## 5.7 Fluxo G: Responsavel Acompanha Evolucao

```text
Perfil
  -> Area Dos Responsaveis
  -> Inserir PIN/Senha
  -> Resumo Semanal
  -> Relatorio Semanal
  -> Sugestao De Apoio
```

### Criterio De Sucesso

O responsavel entende em menos de 1 minuto o que a crianca praticou e onde precisa de apoio.

## 6. Estados Globais

## 6.1 Sem Internet

### Comportamento

- Mostrar aviso claro.
- Permitir navegar em telas ja carregadas, se possivel.
- Bloquear envio de foto e IA.
- Oferecer tentar novamente.

### Mensagem

"Sem conexao agora. Algumas missoes precisam de internet para a IA ajudar."

## 6.2 IA Indisponivel

### Comportamento

- Nao travar o app.
- Sugerir tentar novamente.
- Permitir salvar atividade para analisar depois.

### Mensagem

"A IA da Liga esta demorando para responder. Podemos tentar de novo ou guardar esta atividade."

## 6.3 Conteudo Nao Reconhecido

### Comportamento

- Informar que nao conseguiu entender.
- Pedir nova foto ou digitacao.

### Mensagem

"Nao consegui identificar a atividade com seguranca. Tente uma foto mais perto ou digite o enunciado."

## 6.4 Conteudo Fora Do Escopo

### Comportamento

- Explicar que aquele tipo de conteudo ainda nao e suportado.
- Sugerir uma acao possivel.

### Mensagem

"Essa atividade parece estar fora das missoes que consigo ajudar agora. Posso tentar ler o enunciado ou voce pode escolher outra missao."

## 6.5 Conteudo Sensivel

### Comportamento

- Responder de forma segura.
- Nao continuar conversa livre.
- Orientar responsavel quando necessario.

### Mensagem

"Esse assunto precisa de ajuda de um adulto de confianca. Chame seu responsavel para conversar com voce."

## 7. Dados Necessarios Por Tela

## 7.1 Home

- Perfil da crianca.
- Nivel.
- XP.
- Sequencia diaria.
- Missao em andamento.
- Missoes recomendadas.
- Badges recentes.

## 7.2 Enviar Foto

- Permissao de camera.
- Imagem temporaria.
- Status de upload.

## 7.3 Resultado IA

- Imagem original.
- Texto extraido.
- Materia detectada.
- Tipo de atividade.
- Feedback estruturado.
- XP calculado.

## 7.4 Oficina De Texto

- Tema.
- Planejamento.
- Texto original.
- Feedback IA.
- Texto reescrito.
- Resultado comparativo.

## 7.5 Detetive Da Leitura

- Texto.
- Perguntas.
- Pistas.
- Respostas.
- Feedback.
- Pontuacao/XP.

## 7.6 Progresso

- XP por area.
- Missoes concluidas.
- Sequencia.
- Badges.
- Habilidades praticadas.
- Areas com dificuldade.

## 8. Estrutura De Resposta Da IA

Para facilitar implementacao, as respostas da IA devem vir em formato estruturado.

## 8.1 Foto De Atividade

```json
{
  "tipo_atividade": "matematica | interpretacao | texto | objetiva | discursiva | desconhecida",
  "materia": "matematica | portugues | ciencias | historia | geografia | desconhecida",
  "enunciado_extraido": "",
  "resposta_detectada": "",
  "status": "correto | parcialmente_correto | incorreto | ilegivel | fora_do_escopo",
  "feedback_curto": "",
  "explicacao": "",
  "dica": "",
  "proxima_acao_recomendada": "tentar_novamente | ver_passo_a_passo | gerar_parecida | enviar_outra_foto",
  "xp_sugerido": 0
}
```

## 8.2 Producao Textual

```json
{
  "elogio": "",
  "clareza": 0,
  "organizacao": 0,
  "pontuacao": 0,
  "ortografia": 0,
  "criatividade": 0,
  "pontos_para_melhorar": [],
  "sugestao_de_reescrita": "",
  "desafio_de_reescrita": "",
  "xp_sugerido": 0
}
```

## 8.3 Interpretacao De Texto

```json
{
  "resposta_status": "correta | incorreta | parcial",
  "pista_no_texto": "",
  "explicacao": "",
  "dica": "",
  "habilidade_trabalhada": "ideia_principal | inferencia | vocabulario | detalhe | intencao_do_autor",
  "xp_sugerido": 0
}
```

## 9. Priorizacao De Implementacao

## 9.1 Primeiro Bloco

- Splash.
- Onboarding.
- Cadastro/Login.
- Criar perfil.
- Home.

## 9.2 Segundo Bloco

- Enviar foto.
- Confirmar foto.
- Processamento.
- Resultado da IA.
- Erro de analise.

## 9.3 Terceiro Bloco

- Oficina de Texto.
- Planejar texto.
- Escrever texto.
- Feedback.
- Reescrita.

## 9.4 Quarto Bloco

- Detetive da Leitura.
- Leitura.
- Perguntas.
- Feedback.
- Conclusao.

## 9.5 Quinto Bloco

- Arena Matematica.
- Missoes.
- Progresso.
- Perfil.
- Area dos responsaveis.

## 10. Backlog De Telas Pos-MVP

- Loja de itens visuais.
- Personalizacao avancada de avatar.
- Painel web de responsaveis.
- Painel para professores.
- Turmas.
- Simulados.
- Eventos semanais.
- Multiplayer educativo.
- Ranking entre amigos com autorizacao.
- Tetris do Saber.
- Quebra-cabecas de conteudo.
- Jogo da memoria.
- Biblioteca de textos.

## 11. Proxima Etapa Recomendada

Com o mapa de telas definido, o proximo passo e criar o **Documento De Requisitos Tecnicos E Arquitetura Inicial**, contendo:

- escolha final da stack;
- estrutura do projeto Flutter;
- modelos de dados;
- endpoints/API;
- integracao com IA;
- armazenamento de imagens;
- autenticacao;
- seguranca e privacidade;
- plano de desenvolvimento por sprints.

