// Liga do Saber - Edge Function "atelie-zuri" (Zuri, Ateliê do Zuri).
//
// O Ateliê é feito de minijogos para o contraturno escolar. A IA cria o
// conteúdo do ano escolar da criança e o servidor monta o jogo:
// - "caca_palavras": caça-palavras com palavras de um tema da escola. A
//   grade é montada aqui, não pela IA.
// - "mapa_mental": monte o mapa mental, encaixando cada ideia no ramo certo.
// - "ordem_projeto": quebra-cabeça com as etapas de um projeto escolar
//   embaralhadas, para pôr em ordem.
//
// acao "novo_jogo": cria o jogo. A solução fica guardada em `correcoes_ia`
//   e não vai ao app (no caça-palavras as palavras são públicas, como no
//   papel, mas as posições não).
// acao "conferir": confere a jogada. Resolver de primeira vale 20 XP;
//   depois de errar, 10 XP; depois de ver a solução, não vale XP.
// acao "revelar": mostra a solução e a explicação do Zuri.
// acao "planejar_projeto": a criança escreve o tema do projeto dela e o
//   Zuri devolve um mapa mental, os passos do projeto e um desafio criativo
//   (15 XP por projeto).
//
// Os jogos só mandam à OpenAI o ano escolar e o tipo de jogo, como a Trilha
// do Teo. Já o "planejar_projeto" manda o texto da criança e por isso exige
// `responsaveis.autoriza_ia` (LGPD art. 14), como a Oficina de Texto.
//
// Deploy: veja supabase/functions/README.md.

import {
  carregarPerfil,
  concederXp,
  conferirLimiteDiario,
  ErroDaLiga,
  perguntarIA,
  REGRAS_DE_SEGURANCA,
  resposta,
  servir,
  VOZES,
  type Contexto,
} from "../_shared/liga.ts";

const TIPO_JOGO = "atelie";
const TIPO_PROJETO = "projeto";
const LIMITE_JOGOS = Number(Deno.env.get("LIMITE_JOGOS_ZURI_POR_DIA") ?? "40");
const LIMITE_PROJETOS = Number(Deno.env.get("LIMITE_PROJETOS_POR_DIA") ?? "10");
const XP_DE_PRIMEIRA = 20;
const XP_DEPOIS_DE_ERRAR = 10;
const XP_DO_PROJETO = 15;
const TAMANHO_MAXIMO_DO_TEMA = 200;

const SEM_AUTORIZACAO =
  "Peça para um adulto liberar os projetos com IA na Área dos responsáveis.";

type Jogo = "caca_palavras" | "mapa_mental" | "ordem_projeto";
type Celula = [number, number];

// ---------------------------------------------------------------------------
// Conteúdo de cada jogo (o que a IA cria).

const ESQUEMAS: Record<Jogo, Record<string, unknown>> = {
  caca_palavras: {
    type: "object",
    additionalProperties: false,
    required: ["titulo", "introducao", "palavras", "explicacao"],
    properties: {
      titulo: { type: "string" },
      introducao: { type: "string" },
      palavras: {
        type: "array",
        items: { type: "string" },
        description: "Palavras simples, sem espaço nem hífen.",
      },
      explicacao: { type: "array", items: { type: "string" } },
    },
  },
  mapa_mental: {
    type: "object",
    additionalProperties: false,
    required: ["titulo", "introducao", "ideia_central", "ramos", "explicacao"],
    properties: {
      titulo: { type: "string" },
      introducao: { type: "string" },
      ideia_central: { type: "string" },
      ramos: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          required: ["titulo", "ideias"],
          properties: {
            titulo: { type: "string" },
            ideias: { type: "array", items: { type: "string" } },
          },
        },
      },
      explicacao: { type: "array", items: { type: "string" } },
    },
  },
  ordem_projeto: {
    type: "object",
    additionalProperties: false,
    required: ["titulo", "introducao", "etapas", "explicacao"],
    properties: {
      titulo: { type: "string" },
      introducao: { type: "string" },
      etapas: {
        type: "array",
        items: { type: "string" },
        description: "Etapas na ordem certa.",
      },
      explicacao: { type: "array", items: { type: "string" } },
    },
  },
};

const PEDIDOS: Record<Jogo, string> = {
  caca_palavras: `Crie um caça-palavras:
- "titulo": nome curto e divertido com o tema.
- "introducao": 1 ou 2 frases, na voz do Zuri, apresentando o tema.
- "palavras": 6 a 8 palavras importantes do tema, de 3 a 9 letras, cada uma uma palavra só (sem espaço nem hífen), em português.
- "explicacao": 2 ou 3 frases curtas, na voz do Zuri, ligando as palavras ao tema.`,
  mapa_mental: `Crie um jogo de montar mapa mental:
- "titulo": nome curto e divertido.
- "introducao": 1 ou 2 frases, na voz do Zuri, contando o que ele quer organizar.
- "ideia_central": o assunto do centro do mapa, em poucas palavras.
- "ramos": exatamente 3 ramos com título curto, cada um com 2 ou 3 ideias curtas (no máximo 4 palavras cada). Cada ideia deve pertencer claramente a um só ramo; nenhuma ideia repetida.
- "explicacao": 2 a 3 passos curtos, na voz do Zuri, mostrando por que cada grupo de ideias combina.`,
  ordem_projeto: `Crie um quebra-cabeça de etapas de um projeto escolar (uma maquete, um cartaz, uma feira de ciências, uma horta, um jornal da turma, um experimento seguro etc.):
- "titulo": nome do projeto, curto e divertido.
- "introducao": 1 ou 2 frases, na voz do Zuri, apresentando o projeto.
- "etapas": 4 a 6 etapas curtas (no máximo 8 palavras cada), na ordem certa e sem ambiguidade (por exemplo: escolher o tema, pesquisar, planejar, montar, revisar, apresentar).
- "explicacao": 2 a 3 passos curtos, na voz do Zuri, dizendo por que essa ordem funciona.
Nada de tesoura afiada, fogo, cola quente ou eletricidade.`,
};

function instrucoesDoJogo(anoEscolar: number, jogo: Jogo): string {
  return `Você é ${VOZES.zuri} Você cria minijogos do "Ateliê do Zuri" para uma criança do ${anoEscolar}º ano do ensino fundamental no Brasil, no contraturno escolar. Use um assunto da BNCC desse ano (de qualquer matéria) e treine organizar ideias e planejar projetos.

${PEDIDOS[jogo]}

Use só informações corretas e confira tudo antes de responder.

${REGRAS_DE_SEGURANCA}`;
}

// ---------------------------------------------------------------------------
// Montagem dos jogos.

function embaralhar<T>(itens: T[]): T[] {
  const copia = [...itens];
  for (let i = copia.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copia[i], copia[j]] = [copia[j], copia[i]];
  }
  return copia;
}

/// Ordem embaralhada que nunca é a original (senão o jogo já vem resolvido).
function ordemEmbaralhada(tamanho: number): number[] {
  const original = [...Array(tamanho).keys()];
  for (let tentativa = 0; tentativa < 20; tentativa++) {
    const ordem = embaralhar(original);
    if (ordem.some((valor, i) => valor !== i)) return ordem;
  }
  return original.reverse();
}

/// Palavra só com letras maiúsculas sem acento, como num caça-palavras.
function chaveDaPalavra(palavra: string): string {
  return palavra
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toUpperCase()
    .replace(/[^A-Z]/g, "");
}

/// Monta a grade do caça-palavras. Até o 3º ano as palavras ficam só na
/// horizontal e na vertical; depois entram diagonais e, do 6º ano em
/// diante, palavras de trás para frente.
function montarGrade(palavras: string[], anoEscolar: number) {
  const tamanho = anoEscolar <= 3 ? 8 : anoEscolar <= 5 ? 10 : 12;
  const direcoes: Celula[] = [[0, 1], [1, 0]];
  if (anoEscolar >= 4) direcoes.push([1, 1]);
  if (anoEscolar >= 6) direcoes.push([0, -1], [-1, 0], [-1, -1], [1, -1]);

  const grade: string[][] = Array.from(
    { length: tamanho },
    () => Array(tamanho).fill(""),
  );
  const colocadas: { texto: string; chave: string; inicio: Celula; fim: Celula }[] = [];
  const vistas = new Set<string>();

  for (const texto of palavras) {
    const chave = chaveDaPalavra(texto);
    if (chave.length < 3 || chave.length > tamanho || vistas.has(chave)) continue;
    for (let tentativa = 0; tentativa < 200; tentativa++) {
      const [dl, dc] = direcoes[Math.floor(Math.random() * direcoes.length)];
      const l0 = Math.floor(Math.random() * tamanho);
      const c0 = Math.floor(Math.random() * tamanho);
      const lf = l0 + dl * (chave.length - 1);
      const cf = c0 + dc * (chave.length - 1);
      if (lf < 0 || lf >= tamanho || cf < 0 || cf >= tamanho) continue;
      let cabe = true;
      for (let i = 0; i < chave.length && cabe; i++) {
        const letra = grade[l0 + dl * i][c0 + dc * i];
        cabe = letra === "" || letra === chave[i];
      }
      if (!cabe) continue;
      for (let i = 0; i < chave.length; i++) {
        grade[l0 + dl * i][c0 + dc * i] = chave[i];
      }
      colocadas.push({ texto, chave, inicio: [l0, c0], fim: [lf, cf] });
      vistas.add(chave);
      break;
    }
  }
  if (colocadas.length < 4) {
    throw new ErroDaLiga(502, "O Zuri embaralhou demais as letras. Tente de novo.");
  }

  const alfabeto = "ABCDEFGHIJLMNOPRSTUVZ";
  const linhas = grade.map((linha) =>
    linha
      .map((letra) => letra || alfabeto[Math.floor(Math.random() * alfabeto.length)])
      .join("")
  );
  return { linhas, colocadas };
}

/// Monta o jogo a partir do conteúdo da IA. Devolve o que vai ao app
/// (`publico`) e o que fica guardado no servidor (`solucao`).
function montarJogo(
  jogo: Jogo,
  dados: Record<string, unknown>,
  anoEscolar: number,
): { publico: Record<string, unknown>; solucao: Record<string, unknown> } {
  switch (jogo) {
    case "caca_palavras": {
      const { linhas, colocadas } = montarGrade(
        (dados.palavras as string[]) ?? [],
        anoEscolar,
      );
      return {
        publico: {
          grade: linhas,
          palavras: colocadas.map(({ texto, chave }) => ({ texto, chave })),
        },
        solucao: {
          grade: linhas,
          palavras: colocadas,
        },
      };
    }
    case "mapa_mental": {
      const ramos = (dados.ramos as { titulo: string; ideias: string[] }[]) ?? [];
      const pecas = embaralhar(
        ramos.flatMap((ramo, r) => ramo.ideias.map((texto) => ({ texto, ramo: r }))),
      );
      if (ramos.length < 2 || pecas.length < 4) {
        throw new ErroDaLiga(502, "O mapa do Zuri saiu torto. Tente de novo.");
      }
      return {
        publico: {
          ideia_central: dados.ideia_central,
          ramos: ramos.map((ramo) => ramo.titulo),
          pecas: pecas.map((peca) => peca.texto),
        },
        solucao: { ramo_de_cada_peca: pecas.map((peca) => peca.ramo) },
      };
    }
    case "ordem_projeto": {
      const etapas = (dados.etapas as string[]) ?? [];
      if (etapas.length < 3) {
        throw new ErroDaLiga(502, "O quebra-cabeça do Zuri perdeu peças. Tente de novo.");
      }
      // pecas[i] = etapas[ordem[i]]: a peça i é a etapa número ordem[i].
      const ordem = ordemEmbaralhada(etapas.length);
      return {
        publico: { pecas: ordem.map((i) => etapas[i]) },
        solucao: { etapa_de_cada_peca: ordem },
      };
    }
  }
}

/// Confere a jogada e devolve um booleano por item (palavra, peça ou
/// posição) e se o jogo foi resolvido.
function conferirJogada(
  jogo: Jogo,
  solucao: Record<string, unknown>,
  jogada: unknown,
): { certos: boolean[]; resolvido: boolean } {
  if (!Array.isArray(jogada)) throw new ErroDaLiga(400, "Jogada inválida.");
  switch (jogo) {
    case "caca_palavras": {
      // jogada: [{ palavra: índice, inicio: [l, c], fim: [l, c] }]
      const grade = solucao.grade as string[];
      const palavras = solucao.palavras as { chave: string }[];
      const certos = palavras.map(() => false);
      for (const achado of jogada) {
        const indice = achado?.palavra;
        if (!Number.isInteger(indice) || indice < 0 || indice >= palavras.length) {
          continue;
        }
        const lido = letrasEntre(grade, achado.inicio, achado.fim);
        const chave = palavras[indice].chave;
        if (lido === chave || lido === [...chave].reverse().join("")) {
          certos[indice] = true;
        }
      }
      return { certos, resolvido: certos.every(Boolean) };
    }
    case "mapa_mental": {
      // jogada: o ramo escolhido para cada peça.
      const certo = solucao.ramo_de_cada_peca as number[];
      const certos = certo.map((ramo, i) => jogada[i] === ramo);
      return { certos, resolvido: certos.every(Boolean) };
    }
    case "ordem_projeto": {
      // jogada: as peças na ordem que a criança montou.
      const etapaDaPeca = solucao.etapa_de_cada_peca as number[];
      const certos = etapaDaPeca.map((_, posicao) =>
        Number.isInteger(jogada[posicao]) &&
        etapaDaPeca[jogada[posicao]] === posicao
      );
      return { certos, resolvido: certos.every(Boolean) };
    }
  }
}

/// Letras da grade numa linha reta (horizontal, vertical ou diagonal).
function letrasEntre(grade: string[], inicio: unknown, fim: unknown): string {
  if (!Array.isArray(inicio) || !Array.isArray(fim)) return "";
  const [l0, c0] = inicio.map(Number);
  const [lf, cf] = fim.map(Number);
  const dl = Math.sign(lf - l0);
  const dc = Math.sign(cf - c0);
  const passos = Math.max(Math.abs(lf - l0), Math.abs(cf - c0));
  const reta = l0 === lf || c0 === cf || Math.abs(lf - l0) === Math.abs(cf - c0);
  if (!reta) return "";
  let lido = "";
  for (let i = 0; i <= passos; i++) {
    lido += grade[l0 + dl * i]?.[c0 + dc * i] ?? "";
  }
  return lido;
}

/// Solução que o app recebe quando o jogo termina (resolveu ou revelou).
function solucaoParaOApp(jogo: Jogo, solucao: Record<string, unknown>) {
  switch (jogo) {
    case "caca_palavras":
      return {
        posicoes: (solucao.palavras as { inicio: Celula; fim: Celula }[]).map(
          ({ inicio, fim }) => ({ inicio, fim }),
        ),
      };
    case "mapa_mental":
      return { ramo_de_cada_peca: solucao.ramo_de_cada_peca };
    case "ordem_projeto":
      return { etapa_de_cada_peca: solucao.etapa_de_cada_peca };
  }
}

// ---------------------------------------------------------------------------
// Ações.

async function carregarJogo(ctx: Contexto) {
  const perfil = await carregarPerfil(ctx);
  const jogoId = ctx.corpo.jogo_id;
  if (typeof jogoId !== "string") throw new ErroDaLiga(400, "Faltou o jogo.");
  const { data: linha } = await ctx.servico
    .from("correcoes_ia")
    .select("id, resposta_json")
    .eq("id", jogoId)
    .eq("perfil_crianca_id", perfil.id)
    .eq("tipo", TIPO_JOGO)
    .maybeSingle();
  if (!linha) throw new ErroDaLiga(404, "Jogo não encontrado.");
  return {
    perfil,
    id: linha.id as string,
    estado: linha.resposta_json as Record<string, unknown>,
  };
}

async function salvarEstado(
  ctx: Contexto,
  id: string,
  estado: Record<string, unknown>,
  xp?: number,
) {
  await ctx.servico
    .from("correcoes_ia")
    .update({
      resposta_json: estado,
      ...(xp === undefined ? {} : { xp_sugerido: xp }),
    })
    .eq("id", id);
}

async function novoJogo(ctx: Contexto): Promise<Response> {
  const perfil = await carregarPerfil(ctx);
  const jogo = String(ctx.corpo.jogo) as Jogo;
  if (!(jogo in ESQUEMAS)) throw new ErroDaLiga(400, "Escolha um jogo do Ateliê.");
  await conferirLimiteDiario(
    ctx,
    perfil,
    TIPO_JOGO,
    LIMITE_JOGOS,
    "Você jogou muito hoje! Amanhã o Zuri traz jogos novos.",
  );

  const { dados, modelo } = await perguntarIA({
    instrucoes: instrucoesDoJogo(perfil.ano_escolar, jogo),
    entrada: "Crie o próximo jogo.",
    nomeDoEsquema: `jogo_${jogo}`,
    esquema: ESQUEMAS[jogo],
  });
  const { publico, solucao } = montarJogo(jogo, dados, perfil.ano_escolar);

  const { data: linha, error } = await ctx.servico
    .from("correcoes_ia")
    .insert({
      perfil_crianca_id: perfil.id,
      tipo: TIPO_JOGO,
      entrada_resumo: `${jogo}: ${String(dados.titulo ?? "")}`.slice(0, 500),
      resposta_json: {
        jogo,
        titulo: dados.titulo,
        explicacao: dados.explicacao,
        solucao,
        tentativas: 0,
        revelado: false,
        resolvido: false,
      },
      modelo_usado: modelo,
    })
    .select("id")
    .single();
  if (error) throw error;

  return resposta(200, {
    jogo_id: linha.id,
    jogo,
    titulo: dados.titulo,
    introducao: dados.introducao,
    ...publico,
    xp_possivel: XP_DE_PRIMEIRA,
  });
}

async function conferir(ctx: Contexto): Promise<Response> {
  const { perfil, id, estado } = await carregarJogo(ctx);
  const jogo = estado.jogo as Jogo;
  const solucao = estado.solucao as Record<string, unknown>;
  const { certos, resolvido } = conferirJogada(jogo, solucao, ctx.corpo.jogada);

  const tentativas = Number(estado.tentativas ?? 0);
  let xp = 0;
  if (resolvido && !estado.resolvido && !estado.revelado) {
    xp = tentativas === 0 ? XP_DE_PRIMEIRA : XP_DEPOIS_DE_ERRAR;
  }
  await salvarEstado(
    ctx,
    id,
    {
      ...estado,
      tentativas: tentativas + 1,
      resolvido: Boolean(estado.resolvido) || resolvido,
    },
    resolvido ? xp : undefined,
  );

  const progresso = await concederXp(ctx, perfil, xp, TIPO_JOGO, id);

  return resposta(200, {
    resolvido,
    certos,
    ...(resolvido
      ? { explicacao: estado.explicacao, ...solucaoParaOApp(jogo, solucao) }
      : { explicacao: [] }),
    xp: progresso ? xp : 0,
    progresso,
  });
}

async function revelar(ctx: Contexto): Promise<Response> {
  const { id, estado } = await carregarJogo(ctx);
  if (!estado.revelado) {
    await salvarEstado(ctx, id, { ...estado, revelado: true });
  }
  return resposta(200, {
    explicacao: estado.explicacao,
    ...solucaoParaOApp(estado.jogo as Jogo, estado.solucao as Record<string, unknown>),
  });
}

// ---------------------------------------------------------------------------
// Meu projeto: o tema escrito pela criança vira mapa mental e etapas.

const ESQUEMA_DO_PROJETO = {
  type: "object",
  additionalProperties: false,
  required: ["adequado", "titulo", "ideia_central", "ramos", "passos", "desafio_criativo"],
  properties: {
    adequado: {
      type: "boolean",
      description: "false se o tema não for adequado para uma criança.",
    },
    titulo: { type: "string" },
    ideia_central: { type: "string" },
    ramos: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["titulo", "ideias"],
        properties: {
          titulo: { type: "string" },
          ideias: { type: "array", items: { type: "string" } },
        },
      },
    },
    passos: { type: "array", items: { type: "string" } },
    desafio_criativo: { type: "string" },
  },
};

function instrucoesDoProjeto(anoEscolar: number): string {
  return `Você é ${VOZES.zuri} Uma criança do ${anoEscolar}º ano do ensino fundamental no Brasil vai mandar o tema de um projeto ou trabalho escolar. Ajude a organizar as ideias, sem fazer o trabalho por ela.

Responda:
- "adequado": false se o tema não for adequado para uma criança (nesse caso deixe os outros campos curtos e neutros, sem falar do tema).
- "titulo": um título criativo para o projeto.
- "ideia_central": o centro do mapa mental, em poucas palavras.
- "ramos": 3 a 5 ramos do mapa mental, cada um com um título curto e 2 a 4 ideias curtas, que sejam perguntas ou caminhos para a criança pesquisar (não respostas prontas).
- "passos": 4 a 6 etapas do projeto em ordem (pesquisar, planejar, criar, revisar, apresentar), cada uma com uma ação concreta para a idade.
- "desafio_criativo": uma ideia divertida e segura para deixar a apresentação mais criativa.

Use só informações corretas. Se a criança escrever dados pessoais, ignore-os e não os repita.

${REGRAS_DE_SEGURANCA}`;
}

async function planejarProjeto(ctx: Contexto): Promise<Response> {
  const perfil = await carregarPerfil(ctx, {
    exigirAutorizacaoIA: SEM_AUTORIZACAO,
  });
  const tema = typeof ctx.corpo.tema === "string" ? ctx.corpo.tema.trim() : "";
  if (tema.length < 3) {
    throw new ErroDaLiga(400, "Conte qual é o tema do seu projeto.");
  }
  if (tema.length > TAMANHO_MAXIMO_DO_TEMA) {
    throw new ErroDaLiga(400, "Escreva o tema em poucas palavras.");
  }
  await conferirLimiteDiario(
    ctx,
    perfil,
    TIPO_PROJETO,
    LIMITE_PROJETOS,
    "Já são muitos projetos hoje! Que tal tirar um do papel?",
  );

  const { dados: projeto, modelo } = await perguntarIA({
    instrucoes: instrucoesDoProjeto(perfil.ano_escolar),
    entrada: `Tema do projeto: ${tema}`,
    nomeDoEsquema: "projeto_zuri",
    esquema: ESQUEMA_DO_PROJETO,
  });
  if (!projeto.adequado) {
    throw new ErroDaLiga(
      422,
      "Esse tema não dá para o Ateliê. Escolha outro ou peça ajuda a um adulto.",
    );
  }

  const { data: linha, error } = await ctx.servico
    .from("correcoes_ia")
    .insert({
      perfil_crianca_id: perfil.id,
      tipo: TIPO_PROJETO,
      entrada_resumo: tema,
      resposta_json: projeto,
      xp_sugerido: XP_DO_PROJETO,
      modelo_usado: modelo,
    })
    .select("id")
    .single();
  if (error) throw error;

  const progresso = await concederXp(ctx, perfil, XP_DO_PROJETO, TIPO_PROJETO, linha.id);

  return resposta(200, {
    projeto_id: linha.id,
    titulo: projeto.titulo,
    ideia_central: projeto.ideia_central,
    ramos: projeto.ramos,
    passos: projeto.passos,
    desafio_criativo: projeto.desafio_criativo,
    xp: progresso ? XP_DO_PROJETO : 0,
    progresso,
  });
}

servir("o Ateliê do Zuri", (ctx) => {
  switch (ctx.corpo.acao) {
    case "novo_jogo":
      return novoJogo(ctx);
    case "conferir":
      return conferir(ctx);
    case "revelar":
      return revelar(ctx);
    case "planejar_projeto":
      return planejarProjeto(ctx);
    default:
      throw new ErroDaLiga(400, "Ação desconhecida.");
  }
});
