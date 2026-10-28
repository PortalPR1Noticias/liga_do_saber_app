// Liga do Saber - Edge Function "minijogo" (Jogos da Liga).
//
// O conteúdo da escola em formato de jogo:
// acao "novo" com jogo:
//   - "caca_palavras": a IA escolhe palavras do tema e escreve uma pista
//     para cada uma; a função esconde as palavras numa grade 10x10. As
//     posições ficam em `correcoes_ia` e não vão ao app.
//   - "quebra_cabeca": a IA cria peças com uma ordem certa (pedaços de
//     frase, números, etapas de um processo); a função embaralha.
//   - "relampago": 40 contas para 60 segundos, geradas aqui mesmo, sem IA.
//   - "cruzadas": a IA escolhe palavras do tema com pista; a função cruza
//     as palavras numa grade (cruzadas.ts). As respostas ficam no servidor.
// acao "conferir_palavra": confere a palavra marcada na grade. Achar todas
//   vale 20 XP.
// acao "conferir_ordem": diz quais peças estão no lugar. Montar de
//   primeira vale 20 XP; depois, 10.
// acao "conferir_cruzada": confere a palavra digitada para uma pista. Do
//   segundo erro em diante, a resposta traz uma dica (as primeiras letras).
//   Completar vale 20 XP; se precisou de dica, 10.
// acao "fechar_relampago": confere as respostas da rodada: 5 XP + 2 por
//   acerto, até 25.
//
// Todo XP tem a origem 'minijogo'. Para o tempo de tela não virar uso
// compulsivo, só os primeiros jogos do dia dão XP
// (`MINIJOGOS_COM_XP_POR_DIA`, padrão 15); depois disso dá para jogar por
// diversão.
//
// Só o ano escolar e a matéria vão para a OpenAI (nada escrito pela
// criança), então não depende de `responsaveis.autoriza_ia`.
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
  type Perfil,
} from "../_shared/liga.ts";
import { montarCruzadas, paraGrade, type PalavraCruzada } from "./cruzadas.ts";

const TIPO = "minijogo";
const LIMITE_DIARIO = Number(Deno.env.get("LIMITE_MINIJOGOS_POR_DIA") ?? "60");
const COM_XP_POR_DIA = Number(Deno.env.get("MINIJOGOS_COM_XP_POR_DIA") ?? "15");
const XP_CACA_PALAVRAS = 20;
const XP_QUEBRA_DE_PRIMEIRA = 20;
const XP_QUEBRA_DEPOIS = 10;
const XP_RELAMPAGO_MAXIMO = 25;
const XP_CRUZADAS_SEM_DICA = 20;
const XP_CRUZADAS_COM_DICA = 10;
const TAMANHO_DA_GRADE = 10;
const SEGUNDOS_DO_RELAMPAGO = 60;

const MATERIAS: Record<string, { nome: string; voz: string; temas: string[] }> = {
  portugues: {
    nome: "Língua Portuguesa",
    voz: VOZES.luma,
    temas: [
      "classes de palavras",
      "sinônimos e antônimos",
      "vocabulário de contos e fábulas",
      "pontuação",
      "gêneros textuais",
      "ortografia (s, ss, ç, x, ch)",
      "palavras do dia a dia da escola",
    ],
  },
  matematica: {
    nome: "Matemática",
    voz: VOZES.nico,
    temas: [
      "nomes das operações e seus termos",
      "figuras geométricas",
      "medidas de tempo, comprimento e massa",
      "frações",
      "sistema de numeração",
      "sequências e padrões",
    ],
  },
  ciencias: {
    nome: "Ciências",
    voz: VOZES.teo,
    temas: [
      "corpo humano",
      "plantas",
      "animais e ecossistemas",
      "ciclo da água",
      "Sistema Solar",
      "materiais e misturas",
    ],
  },
  geografia: {
    nome: "Geografia",
    voz: VOZES.teo,
    temas: [
      "mapas e orientação",
      "biomas do Brasil",
      "relevo e rios",
      "clima e tempo",
      "campo e cidade",
      "regiões do Brasil",
    ],
  },
};

const ESQUEMA_CACA_PALAVRAS = {
  type: "object",
  additionalProperties: false,
  required: ["titulo", "palavras"],
  properties: {
    titulo: { type: "string" },
    palavras: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["palavra", "pista"],
        properties: {
          palavra: { type: "string" },
          pista: { type: "string" },
        },
      },
    },
  },
};

const ESQUEMA_QUEBRA_CABECA = {
  type: "object",
  additionalProperties: false,
  required: ["titulo", "instrucao", "pecas", "explicacao"],
  properties: {
    titulo: { type: "string" },
    instrucao: { type: "string" },
    pecas: {
      type: "array",
      items: { type: "string" },
      description: "As peças já na ordem certa.",
    },
    explicacao: { type: "string" },
  },
};

const IDEIAS_DE_QUEBRA_CABECA: Record<string, string> = {
  portugues:
    "montar uma frase a partir de pedaços, colocar em ordem as partes de uma pequena história (começo, meio e fim) ou as etapas de um bilhete ou receita",
  matematica:
    "ordenar números, frações ou medidas do menor para o maior, ou colocar em ordem os passos para resolver um problema",
  ciencias:
    "colocar em ordem as etapas de um processo (ciclo da água, germinação de uma semente, digestão, ciclo de vida de um animal)",
  geografia:
    "ordenar lugares do menor para o maior (casa, bairro, cidade, estado, país), as etapas de um caminho no mapa ou de um processo da natureza",
};

function sortear<T>(lista: T[]): T {
  return lista[Math.floor(Math.random() * lista.length)];
}

function embaralhar<T>(lista: T[]): T[] {
  const copia = [...lista];
  for (let i = copia.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copia[i], copia[j]] = [copia[j], copia[i]];
  }
  return copia;
}

function materiaDoPedido(ctx: Contexto) {
  const chave = String(ctx.corpo.materia);
  const materia = MATERIAS[chave];
  if (!materia) throw new ErroDaLiga(400, "Escolha uma matéria.");
  return { chave, materia };
}

/// Quantos jogos já deram XP nas últimas 24 horas.
async function podeGanharXp(ctx: Contexto, perfil: Perfil): Promise<boolean> {
  const desde = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { count } = await ctx.servico
    .from("eventos_xp")
    .select("id", { count: "exact", head: true })
    .eq("perfil_crianca_id", perfil.id)
    .eq("origem", TIPO)
    .gte("created_at", desde);
  return (count ?? 0) < COM_XP_POR_DIA;
}

async function darXp(ctx: Contexto, perfil: Perfil, xp: number, id: string) {
  if (xp <= 0) return { xp: 0, progresso: null };
  if (!(await podeGanharXp(ctx, perfil))) {
    return {
      xp: 0,
      progresso: null,
      aviso: "Hoje você já ganhou o XP dos jogos. Amanhã tem mais!",
    };
  }
  const progresso = await concederXp(ctx, perfil, xp, TIPO, id);
  return { xp: progresso ? xp : 0, progresso };
}

async function guardar(
  ctx: Contexto,
  perfil: Perfil,
  resumo: string,
  estado: Record<string, unknown>,
  modelo: string,
): Promise<string> {
  const { data: linha, error } = await ctx.servico
    .from("correcoes_ia")
    .insert({
      perfil_crianca_id: perfil.id,
      tipo: TIPO,
      entrada_resumo: resumo.slice(0, 500),
      resposta_json: estado,
      modelo_usado: modelo,
    })
    .select("id")
    .single();
  if (error) throw error;
  return linha.id as string;
}

async function carregarJogo(ctx: Contexto, jogo: string) {
  const perfil = await carregarPerfil(ctx);
  const jogoId = ctx.corpo.jogo_id;
  if (typeof jogoId !== "string") throw new ErroDaLiga(400, "Faltou o jogo.");
  const { data: linha } = await ctx.servico
    .from("correcoes_ia")
    .select("id, resposta_json, created_at")
    .eq("id", jogoId)
    .eq("perfil_crianca_id", perfil.id)
    .eq("tipo", TIPO)
    .maybeSingle();
  const estado = linha?.resposta_json as Record<string, unknown> | undefined;
  if (!linha || estado?.jogo !== jogo) {
    throw new ErroDaLiga(404, "Jogo não encontrado.");
  }
  return {
    perfil,
    id: linha.id as string,
    estado,
    criadoEm: new Date(linha.created_at as string),
  };
}

async function salvar(ctx: Contexto, id: string, estado: Record<string, unknown>) {
  await ctx.servico.from("correcoes_ia").update({ resposta_json: estado }).eq("id", id);
}

// ---------------------------------------------------------------- caça-palavras

type Casa = [number, number];
type PalavraNaGrade = { palavra: string; pista: string; casas: Casa[] };

/// Esconde as palavras numa grade. Do 6º ano em diante, elas também podem
/// estar de trás para frente.
function montarGrade(
  palavras: { palavra: string; pista: string }[],
  anoEscolar: number,
) {
  const n = TAMANHO_DA_GRADE;
  const grade: (string | null)[][] = Array.from({ length: n }, () =>
    Array(n).fill(null)
  );
  const direcoes: Casa[] = [[0, 1], [1, 0], [1, 1], [-1, 1]];
  if (anoEscolar >= 6) direcoes.push([0, -1], [-1, 0]);
  const colocadas: PalavraNaGrade[] = [];

  for (const { palavra, pista } of palavras) {
    const letras = paraGrade(palavra);
    for (let tentativa = 0; tentativa < 300; tentativa++) {
      const [dl, dc] = sortear(direcoes);
      const l0 = Math.floor(Math.random() * n);
      const c0 = Math.floor(Math.random() * n);
      const casas: Casa[] = [];
      let cabe = true;
      for (let k = 0; k < letras.length; k++) {
        const l = l0 + dl * k;
        const c = c0 + dc * k;
        if (l < 0 || c < 0 || l >= n || c >= n) {
          cabe = false;
          break;
        }
        const atual = grade[l][c];
        if (atual !== null && atual !== letras[k]) {
          cabe = false;
          break;
        }
        casas.push([l, c]);
      }
      if (!cabe) continue;
      casas.forEach(([l, c], k) => (grade[l][c] = letras[k]));
      colocadas.push({ palavra: palavra.toUpperCase(), pista, casas });
      break;
    }
  }

  const alfabeto = "ABCDEFGHIJLMNOPQRSTUVXZ";
  const linhas = grade.map((linha) =>
    linha.map((letra) => letra ?? sortear([...alfabeto])).join("")
  );
  return { linhas, colocadas };
}

async function novoCacaPalavras(ctx: Contexto, perfil: Perfil) {
  const { chave, materia } = materiaDoPedido(ctx);
  const tema = sortear(materia.temas);
  const { dados, modelo } = await perguntarIA({
    instrucoes: `Você é ${materia.voz} Você cria o caça-palavras dos "Jogos da Liga" para uma criança do ${perfil.ano_escolar}º ano do ensino fundamental no Brasil. Siga a BNCC desse ano em ${materia.nome}.

Crie um caça-palavras sobre o tema pedido:
- "titulo": nome curto e divertido.
- "palavras": exatamente 6 palavras importantes do tema para esse ano. Cada uma com 3 a 9 letras, uma palavra só (sem espaço nem hífen), escrita com a acentuação correta.
- "pista" de cada palavra: uma frase curta que ensina o significado ou o uso, sem escrever a palavra nem parte dela. A criança vai achar a palavra pela pista.

Confira se cada pista leva a uma resposta só e se as informações estão corretas.

${REGRAS_DE_SEGURANCA}`,
    entrada: `Tema: ${tema}.`,
    nomeDoEsquema: "caca_palavras",
    esquema: ESQUEMA_CACA_PALAVRAS,
  });

  const vistas = new Set<string>();
  const candidatas = (dados.palavras as { palavra: string; pista: string }[])
    .filter(({ palavra, pista }) => {
      const letras = paraGrade(palavra);
      if (letras.length < 3 || letras.length > TAMANHO_DA_GRADE) return false;
      if (vistas.has(letras) || !pista) return false;
      vistas.add(letras);
      return true;
    })
    .slice(0, 6);
  // As maiores primeiro: são as mais difíceis de encaixar.
  candidatas.sort((a, b) => paraGrade(b.palavra).length - paraGrade(a.palavra).length);
  const { linhas, colocadas } = montarGrade(candidatas, perfil.ano_escolar);
  if (colocadas.length < 3) {
    throw new ErroDaLiga(502, "As palavras não couberam na grade. Tente de novo.");
  }
  const palavras = embaralhar(colocadas);

  const id = await guardar(
    ctx,
    perfil,
    `caca_palavras ${chave}: ${tema}`,
    {
      jogo: "caca_palavras",
      materia: chave,
      titulo: dados.titulo,
      linhas,
      palavras,
      encontradas: [],
      terminou: false,
    },
    modelo,
  );

  return resposta(200, {
    jogo_id: id,
    materia: chave,
    titulo: dados.titulo,
    linhas,
    pistas: palavras.map((p) => ({ pista: p.pista, letras: p.casas.length })),
    xp_possivel: XP_CACA_PALAVRAS,
  });
}

function lerCasa(valor: unknown): Casa | null {
  if (!Array.isArray(valor) || valor.length !== 2) return null;
  const [l, c] = valor;
  return Number.isInteger(l) && Number.isInteger(c) ? [l, c] : null;
}

async function conferirPalavra(ctx: Contexto): Promise<Response> {
  const { perfil, id, estado } = await carregarJogo(ctx, "caca_palavras");
  const inicio = lerCasa(ctx.corpo.inicio);
  const fim = lerCasa(ctx.corpo.fim);
  if (!inicio || !fim) throw new ErroDaLiga(400, "Marque uma palavra na grade.");

  const palavras = estado.palavras as PalavraNaGrade[];
  const encontradas = estado.encontradas as number[];
  const igual = (a: Casa, b: Casa) => a[0] === b[0] && a[1] === b[1];
  const indice = palavras.findIndex(({ casas }, i) => {
    if (encontradas.includes(i)) return false;
    const primeira = casas[0];
    const ultima = casas[casas.length - 1];
    return (igual(primeira, inicio) && igual(ultima, fim)) ||
      (igual(primeira, fim) && igual(ultima, inicio));
  });
  if (indice < 0) return resposta(200, { achou: false });

  const agora = [...encontradas, indice];
  const terminou = agora.length === palavras.length;
  const premio = terminou && !estado.terminou
    ? await darXp(ctx, perfil, XP_CACA_PALAVRAS, id)
    : { xp: 0, progresso: null };
  await salvar(ctx, id, { ...estado, encontradas: agora, terminou });

  return resposta(200, {
    achou: true,
    indice,
    palavra: palavras[indice].palavra,
    casas: palavras[indice].casas,
    terminou,
    ...premio,
  });
}

// ---------------------------------------------------------------- quebra-cabeça

async function novoQuebraCabeca(ctx: Contexto, perfil: Perfil) {
  const { chave, materia } = materiaDoPedido(ctx);
  const tema = sortear(materia.temas);
  const { dados, modelo } = await perguntarIA({
    instrucoes: `Você é ${materia.voz} Você cria o quebra-cabeça de ordenar dos "Jogos da Liga" para uma criança do ${perfil.ano_escolar}º ano do ensino fundamental no Brasil. Siga a BNCC desse ano em ${materia.nome}.

O quebra-cabeça é uma lista de peças que a criança precisa colocar na ordem certa. Ideias para ${materia.nome}: ${IDEIAS_DE_QUEBRA_CABECA[chave]}.

Crie um quebra-cabeça sobre o tema pedido:
- "titulo": nome curto e divertido.
- "instrucao": 1 frase dizendo o que ordenar (por exemplo, "Coloque as etapas na ordem em que acontecem").
- "pecas": 4 a 6 peças curtas (até 8 palavras cada), JÁ NA ORDEM CERTA. A ordem precisa ser uma só, sem dúvida: nada de peças que poderiam trocar de lugar.
- "explicacao": 1 ou 2 frases, na voz do personagem, explicando por que essa é a ordem.

Confira se as informações estão corretas.

${REGRAS_DE_SEGURANCA}`,
    entrada: `Tema: ${tema}.`,
    nomeDoEsquema: "quebra_cabeca",
    esquema: ESQUEMA_QUEBRA_CABECA,
  });

  const certas = (dados.pecas as string[]).filter((p) => p.trim()).slice(0, 6);
  if (certas.length < 3 || new Set(certas).size !== certas.length) {
    throw new ErroDaLiga(502, "As peças se misturaram demais. Tente de novo.");
  }
  // posicoes[k] = em que posição da ordem certa está a peça k embaralhada.
  let posicoes = embaralhar(certas.map((_, i) => i));
  while (posicoes.every((p, k) => p === k)) posicoes = embaralhar(posicoes);
  const pecas = posicoes.map((p) => certas[p]);
  // correta[i] = qual peça embaralhada vai na posição i.
  const correta = certas.map((_, i) => posicoes.indexOf(i));

  const id = await guardar(
    ctx,
    perfil,
    `quebra_cabeca ${chave}: ${tema}`,
    {
      jogo: "quebra_cabeca",
      materia: chave,
      titulo: dados.titulo,
      instrucao: dados.instrucao,
      pecas,
      correta,
      explicacao: dados.explicacao,
      tentativas: 0,
      resolvido: false,
    },
    modelo,
  );

  return resposta(200, {
    jogo_id: id,
    materia: chave,
    titulo: dados.titulo,
    instrucao: dados.instrucao,
    pecas,
    xp_possivel: XP_QUEBRA_DE_PRIMEIRA,
  });
}

async function conferirOrdem(ctx: Contexto): Promise<Response> {
  const { perfil, id, estado } = await carregarJogo(ctx, "quebra_cabeca");
  const correta = estado.correta as number[];
  const ordem = ctx.corpo.ordem;
  if (
    !Array.isArray(ordem) || ordem.length !== correta.length ||
    !ordem.every(Number.isInteger) ||
    new Set(ordem).size !== correta.length
  ) {
    throw new ErroDaLiga(400, "Use todas as peças, uma vez cada.");
  }

  const noLugar = correta.map((c, i) => ordem[i] === c);
  const resolvido = noLugar.every(Boolean);
  const tentativas = Number(estado.tentativas ?? 0);
  const premio = resolvido && !estado.resolvido
    ? await darXp(
      ctx,
      perfil,
      tentativas === 0 ? XP_QUEBRA_DE_PRIMEIRA : XP_QUEBRA_DEPOIS,
      id,
    )
    : { xp: 0, progresso: null };
  await salvar(ctx, id, {
    ...estado,
    tentativas: tentativas + 1,
    resolvido: Boolean(estado.resolvido) || resolvido,
  });

  return resposta(200, {
    resolvido,
    no_lugar: noLugar,
    explicacao: resolvido ? estado.explicacao : "",
    ...premio,
  });
}

// ---------------------------------------------------------------- relâmpago

type Conta = { conta: string; resposta: number };

function inteiro(min: number, max: number): number {
  return min + Math.floor(Math.random() * (max - min + 1));
}

/// Contas do Desafio Relâmpago, mais difíceis conforme o ano escolar.
function gerarConta(tema: string, ano: number): Conta {
  const maxTabuada = ano <= 3 ? 5 : 10;
  switch (tema) {
    case "tabuada": {
      const a = inteiro(2, maxTabuada);
      const b = inteiro(1, 10);
      return { conta: `${a} × ${b}`, resposta: a * b };
    }
    case "soma": {
      const limite = ano <= 3 ? 20 : ano <= 5 ? 100 : 500;
      const a = inteiro(1, limite);
      const b = inteiro(1, limite);
      return Math.random() < 0.5
        ? { conta: `${a} + ${b}`, resposta: a + b }
        : { conta: `${Math.max(a, b)} − ${Math.min(a, b)}`, resposta: Math.abs(a - b) };
    }
    case "divisao": {
      const b = inteiro(2, maxTabuada);
      const r = inteiro(1, 10);
      return { conta: `${b * r} ÷ ${b}`, resposta: r };
    }
    default:
      return gerarConta(sortear(["tabuada", "soma", "divisao"]), ano);
  }
}

async function novoRelampago(ctx: Contexto, perfil: Perfil) {
  const tema = String(ctx.corpo.tema);
  if (!["tabuada", "soma", "divisao", "misturado"].includes(tema)) {
    throw new ErroDaLiga(400, "Escolha o tipo de conta.");
  }
  const contas = Array.from({ length: 40 }, () => gerarConta(tema, perfil.ano_escolar));
  const id = await guardar(
    ctx,
    perfil,
    `relampago: ${tema}`,
    { jogo: "relampago", tema, contas, fechado: false },
    "sem_ia",
  );
  return resposta(200, { jogo_id: id, contas, segundos: SEGUNDOS_DO_RELAMPAGO });
}

async function fecharRelampago(ctx: Contexto): Promise<Response> {
  const { perfil, id, estado, criadoEm } = await carregarJogo(ctx, "relampago");
  const respostas = ctx.corpo.respostas;
  if (!Array.isArray(respostas)) throw new ErroDaLiga(400, "Faltaram as respostas.");

  const contas = estado.contas as Conta[];
  const respondidas = Math.min(respostas.length, contas.length);
  let acertos = 0;
  for (let i = 0; i < respondidas; i++) {
    if (respostas[i] === contas[i].resposta) acertos++;
  }
  // Uma rodada fechada muito depois do tempo (app em segundo plano) não dá XP.
  const segundos = (Date.now() - criadoEm.getTime()) / 1000;
  const noTempo = segundos <= SEGUNDOS_DO_RELAMPAGO + 60;
  const xp = acertos === 0 || !noTempo
    ? 0
    : Math.min(XP_RELAMPAGO_MAXIMO, 5 + 2 * acertos);
  const premio = estado.fechado
    ? { xp: 0, progresso: null }
    : await darXp(ctx, perfil, xp, id);
  await salvar(ctx, id, { ...estado, fechado: true, acertos });

  return resposta(200, { acertos, respondidas, ...premio });
}

// ---------------------------------------------------------------- cruzadas

type PalavraNaCruzada = PalavraCruzada & { erros: number; acertou: boolean };

async function novasCruzadas(ctx: Contexto, perfil: Perfil) {
  const { chave, materia } = materiaDoPedido(ctx);
  const tema = sortear(materia.temas);
  const { dados, modelo } = await perguntarIA({
    instrucoes: `Você é ${materia.voz} Você cria as "Cruzadas da Liga" (palavras cruzadas) para uma criança do ${perfil.ano_escolar}º ano do ensino fundamental no Brasil. Siga a BNCC desse ano em ${materia.nome}.

Crie palavras cruzadas sobre o tema pedido:
- "titulo": nome curto e divertido.
- "palavras": exatamente 8 palavras importantes do tema para esse ano. Cada uma com 3 a 10 letras, uma palavra só (sem espaço nem hífen), escrita com a acentuação correta. Prefira palavras com letras comuns (A, E, O, R, S), que cruzam com mais facilidade.
- "pista" de cada palavra: uma frase curta que ensina o significado ou o uso, sem escrever a palavra nem parte dela. A criança vai digitar a palavra a partir da pista.

Confira se cada pista leva a uma resposta só e se as informações estão corretas.

${REGRAS_DE_SEGURANCA}`,
    entrada: `Tema: ${tema}.`,
    nomeDoEsquema: "cruzadas",
    esquema: ESQUEMA_CACA_PALAVRAS,
  });

  const cruzadas = montarCruzadas(
    dados.palavras as { palavra: string; pista: string }[],
  );
  if (cruzadas.palavras.length < 4) {
    throw new ErroDaLiga(502, "As palavras não se cruzaram. Tente de novo.");
  }
  const palavras: PalavraNaCruzada[] = cruzadas.palavras.map((p) => ({
    ...p,
    erros: 0,
    acertou: false,
  }));

  const id = await guardar(
    ctx,
    perfil,
    `cruzadas ${chave}: ${tema}`,
    {
      jogo: "cruzadas",
      materia: chave,
      titulo: dados.titulo,
      linhas: cruzadas.linhas,
      colunas: cruzadas.colunas,
      palavras,
      usou_dica: false,
      terminou: false,
    },
    modelo,
  );

  return resposta(200, {
    jogo_id: id,
    materia: chave,
    titulo: dados.titulo,
    linhas: cruzadas.linhas,
    colunas: cruzadas.colunas,
    pistas: palavras.map((p) => ({
      numero: p.numero,
      direcao: p.direcao,
      linha: p.linha,
      coluna: p.coluna,
      letras: p.letras.length,
      pista: p.pista,
    })),
    xp_possivel: XP_CRUZADAS_SEM_DICA,
  });
}

/// Dica depois de errar: as primeiras letras, uma a mais a cada erro, até
/// a metade da palavra (o resto a criança descobre pela pista).
function dicaDaPalavra(letras: string, erros: number): string {
  if (erros < 2) return "";
  const mostrar = Math.min(erros - 1, Math.max(1, Math.floor(letras.length / 2)));
  return `Começa com ${letras.slice(0, mostrar)}...`;
}

async function conferirCruzada(ctx: Contexto): Promise<Response> {
  const { perfil, id, estado } = await carregarJogo(ctx, "cruzadas");
  const palavras = estado.palavras as PalavraNaCruzada[];
  const indice = ctx.corpo.indice;
  if (
    typeof indice !== "number" || !Number.isInteger(indice) ||
    indice < 0 || indice >= palavras.length
  ) {
    throw new ErroDaLiga(400, "Escolha uma pista.");
  }
  const palavra = palavras[indice];
  const tentativa = paraGrade(String(ctx.corpo.resposta ?? ""));
  if (tentativa.length !== palavra.letras.length) {
    throw new ErroDaLiga(400, `A palavra tem ${palavra.letras.length} letras.`);
  }

  if (palavra.acertou) {
    return resposta(200, {
      certa: true,
      indice,
      palavra: palavra.palavra,
      letras: palavra.letras,
      terminou: Boolean(estado.terminou),
    });
  }

  if (tentativa !== palavra.letras) {
    palavra.erros++;
    const dica = dicaDaPalavra(palavra.letras, palavra.erros);
    await salvar(ctx, id, {
      ...estado,
      palavras,
      usou_dica: Boolean(estado.usou_dica) || dica !== "",
    });
    return resposta(200, { certa: false, indice, dica });
  }

  palavra.acertou = true;
  const terminou = palavras.every((p) => p.acertou);
  const premio = terminou && !estado.terminou
    ? await darXp(
      ctx,
      perfil,
      estado.usou_dica ? XP_CRUZADAS_COM_DICA : XP_CRUZADAS_SEM_DICA,
      id,
    )
    : { xp: 0, progresso: null };
  await salvar(ctx, id, { ...estado, palavras, terminou });

  return resposta(200, {
    certa: true,
    indice,
    palavra: palavra.palavra,
    letras: palavra.letras,
    terminou,
    ...premio,
  });
}

// ---------------------------------------------------------------- entrada

async function novo(ctx: Contexto): Promise<Response> {
  const perfil = await carregarPerfil(ctx);
  await conferirLimiteDiario(
    ctx,
    perfil,
    TIPO,
    LIMITE_DIARIO,
    "Você já jogou muito hoje. Que tal descansar e voltar amanhã?",
  );
  switch (ctx.corpo.jogo) {
    case "caca_palavras":
      return novoCacaPalavras(ctx, perfil);
    case "quebra_cabeca":
      return novoQuebraCabeca(ctx, perfil);
    case "relampago":
      return novoRelampago(ctx, perfil);
    case "cruzadas":
      return novasCruzadas(ctx, perfil);
    default:
      throw new ErroDaLiga(400, "Jogo desconhecido.");
  }
}

servir("os Jogos da Liga", (ctx) => {
  switch (ctx.corpo.acao) {
    case "novo":
      return novo(ctx);
    case "conferir_palavra":
      return conferirPalavra(ctx);
    case "conferir_ordem":
      return conferirOrdem(ctx);
    case "conferir_cruzada":
      return conferirCruzada(ctx);
    case "fechar_relampago":
      return fecharRelampago(ctx);
    default:
      throw new ErroDaLiga(400, "Ação desconhecida.");
  }
});
