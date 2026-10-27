# Escopo do MVP x app atual (main em 27/10/2026)

Comparação entre `escopo-mvp.md` + `mapa-de-telas-e-fluxos-mvp.md` e o que está
na `main`. Inclui a diretriz nova do Giovany (27/10): **as tarefas viram
minijogos** (caça-palavras, quebra-cabeças e parecidos), porque a Liga usa o
tempo de tela como contraturno escolar.

Legenda: ✅ feito · 🟡 parcial · ❌ falta

## 1. Minijogos (a maior diferença)

| Escopo / diretriz | App hoje |
| --- | --- |
| Tarefas em formato de jogo (caça-palavras, quebra-cabeças...) | ❌ Todos os módulos são pergunta de múltipla escolha ou texto |
| MVP: "Cruzadas da Liga" e "Desafio Relâmpago" (7.8) | ❌ Não existem |
| Pós-MVP: quebra-cabeças de conteúdo, jogo da memória, Tetris do Saber | ❌ (fora do MVP pelo escopo, mas o Giovany adiantou o quebra-cabeça) |

## 2. Foto + IA

| Escopo | App hoje |
| --- | --- |
| Câmera, galeria, enviar para a IA, matéria identificada, explicação | ✅ |
| Confirmar foto com corte/enquadramento (4.8) | ❌ |
| Erro de análise com dicas de nova foto (4.11) | 🟡 mensagem genérica |
| Digitar atividade quando a foto falha (4.12) | ❌ |
| Status correto / parcial / revisar / ilegível (4.10, 8.1) | 🟡 depende da resposta da IA |
| "Gerar questão parecida" e "Tentar de novo" (4.10) | ❌ |

## 3. Detetive da Leitura

| Escopo | App hoje |
| --- | --- |
| Texto curto, perguntas de ideia principal / inferência / localizar | ✅ |
| Pista no texto e explicação por pergunta | ✅ |
| Pedir pista antes de responder, cada acerto libera parte do caso (7.6, 4.22) | 🟡 responde tudo e corrige no fim |
| Aumentar fonte, marcar pista no texto (4.21) | ❌ |

## 4. Oficina de Texto

| Escopo | App hoje |
| --- | --- |
| Tema, planejamento, escrita, feedback da Luma, reescrita, XP pela evolução | ✅ |
| Comparar versão 1 e 2 | ✅ |
| Histórico de textos anteriores, rascunho salvo (4.14, 4.16) | ❌ |

## 5. Arena Matemática

| Escopo | App hoje |
| --- | --- |
| Desafios por tema, dica, passo a passo, XP | ✅ (4 temas, múltipla escolha) |
| Campo de resposta digitada, rodada com várias questões e tela de conclusão (4.26-4.28) | 🟡 uma questão por vez |
| Tabuada, sequências, medidas e geometria (7.7, 12) | 🟡 só operações, frações, problemas, lógica |

## 6. Trilha do Teo (Ciências e Geografia)

✅ Feita, além do que o escopo pedia para o MVP ("fase inicial menor").

## 7. XP, missões e medalhas

| Escopo | App hoje |
| --- | --- |
| XP, nível, sequência diária, missões do dia, medalhas | ✅ |
| Menu: Home, Mapa, Missões, Progresso, Perfil (sem ranking) | ✅ (aba "Conquistas") |
| XP por área, pontos fortes / a praticar, evolução semanal (8.12, 4.31) | ❌ |
| Abas de missões (Hoje, Recomendadas, por área) e status bloqueada / em andamento (8.11) | 🟡 só missões do dia |
| "Continuar Missão" na Home (7.2) | ❌ |
| Limite diário de XP para evitar uso compulsivo (req. 12.1) | 🟡 limite por atividade, não por dia |

## 8. LGPD e Área dos responsáveis

| Escopo | App hoje |
| --- | --- |
| Consentimento, termos, autorização da IA, cópia e exclusão dos dados | ✅ |
| Bloqueio para adultos | ✅ (conta de multiplicação, o escopo fala em PIN/senha) |
| Tempo de uso educativo, missões feitas, áreas praticadas e com dificuldade | ❌ |
| Resumo / relatório semanal com sugestão de apoio (7.10, 4.35) | ❌ |

## 9. Mapa

O escopo lista seis áreas: Ilha dos Números, Biblioteca Viva, Oficina de
Texto, Laboratório do Teo, Arquivo da Mila, Oficina do Zuri. Mila e Zuri estão
sendo feitos em outras threads.

## O que este PR faz

1. Copia os três documentos de produto para `docs/produto/`.
2. Cria o módulo **Jogos da Liga** com três minijogos que usam o conteúdo das
   matérias: **Caça-palavras** (achar a palavra pela definição), **Quebra-cabeça**
   (montar frases, sequências e linhas do tempo na ordem certa) e
   **Desafio Relâmpago** (60 segundos de contas, do jeito do escopo 7.8).
3. Liga os jogos às tarefas: card "Jogos da Liga" na Home e um bloco
   "Treine jogando" no fim de cada módulo (Arena Matemática com o Desafio
   Relâmpago; Detetive da Leitura e Oficina de Texto com caça-palavras e
   quebra-cabeça de Português; Trilha do Teo com os de Ciências e Geografia).
4. XP dos jogos pelo servidor (Edge Function `minijogo`, migration
   `0008_minijogos.sql`): missão do dia "Vencer um Jogo da Liga", medalha
   "Mestre dos Jogos" e só os 15 primeiros jogos do dia valem XP, como o
   documento de requisitos pede (12.1) para evitar uso compulsivo.

Ficam para os próximos passos: Cruzadas da Liga, relatório semanal dos
responsáveis, "Digitar atividade" e "Gerar questão parecida" na Foto + IA,
progresso por área.
