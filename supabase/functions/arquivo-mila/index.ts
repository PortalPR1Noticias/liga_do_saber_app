// Liga do Saber - Edge Function "arquivo-mila" (Mila, Arquivo da Mila).
//
// Minijogos de História. acao "novo_caso": a IA cria uma partida para o ano
// escolar da criança, em um de três modos:
//   - "caca_palavras": palavras de um tema (cada uma com um fato curto); a
//     grade é montada aqui, e as posições das palavras ficam no servidor;
//   - "linha_do_tempo": 4 fichas de acontecimentos para pôr em ordem, do
//     mais antigo ao mais recente (os anos ficam no servidor);
//   - "documento": o enigma de uma fonte histórica (carta, foto, pintura,
//     objeto, jornal ou mapa), com uma pergunta de múltipla escolha.
//   O que resolve a partida fica guardado em `correcoes_ia`.
// acao "responder": confere as palavras encontradas, a ordem ou a escolha.
//   Acertar de primeira vale 20 XP; depois de errar, 10 XP (no
//   caça-palavras, achar todas vale 20); depois de revelar, não vale XP.
// acao "revelar": mostra a solução e a explicação da Mila.
//
// Só o ano escolar e o modo vão para a OpenAI (nada escrito pela criança),
// então, como a Trilha do Teo, não depende de `responsaveis.autoriza_ia`.
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

const TIPO = "arquivo";
const LIMITE_DIARIO = Number(Deno.env.get("LIMITE_ARQUIVO_POR_DIA") ?? "40");
const XP_DE_PRIMEIRA = 20;
const XP_DEPOIS_DE_ERRAR = 10;
const EVENTOS_NA_LINHA = 4;

const MODOS = ["caca_palavras", "linha_do_tempo", "documento"];

const TIPOS_DE_FONTE = ["carta", "foto", "pintura", "objeto", "jornal", "mapa"];

const CAMPOS_COMUNS = {
  titulo: { type: "string" },
  tema: {
    type: "string",
    description: "Assunto da BNCC, em 2 a 4 palavras.",
  },
  introducao: { type: "string" },
  explicacao: { type: "array", items: { type: "string" } },
  dica: {
    type: "string",
    description: "Dica para quem errou, sem entregar a resposta.",
  },
  curiosidade: { type: "string" },
};

const ESQUEMA_DO_DOCUMENTO = {
  type: "object",
  additionalProperties: false,
  required: [
    "titulo",
    "tema",
    "introducao",
    "fonte_tipo",
    "fonte",
    "origem_da_fonte",
    "pergunta",
    "opcoes",
    "correta",
    "explicacao",
    "dica",
    "curiosidade",
  ],
  properties: {
    ...CAMPOS_COMUNS,
    fonte_tipo: { type: "string", enum: TIPOS_DE_FONTE },
    fonte: { type: "string" },
    origem_da_fonte: { type: "string" },
    pergunta: { type: "string" },
    opcoes: { type: "array", items: { type: "string" } },
    correta: {
      type: "integer",
      description: "Índice (a partir de 0) da opção certa.",
    },
  },
};

const ESQUEMA_DA_LINHA = {
  type: "object",
  additionalProperties: false,
  required: [
    "titulo",
    "tema",
    "introducao",
    "eventos",
    "explicacao",
    "dica",
    "curiosidade",
  ],
  properties: {
    ...CAMPOS_COMUNS,
    eventos: {
      type: "array",
      description: "Do mais antigo para o mais recente.",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["texto", "ano", "ano_numero"],
        properties: {
          texto: { type: "string" },
          ano: {
            type: "string",
            description: 'Como mostrar a data, por exemplo "1500" ou "c. 3000 a.C.".',
          },
          ano_numero: {
            type: "integer",
            description: "O ano como número; antes de Cristo é negativo.",
          },
        },
      },
    },
  },
};

const ESQUEMA_DO_CACA_PALAVRAS = {
  type: "object",
  additionalProperties: false,
  required: ["titulo", "tema", "introducao", "palavras", "curiosidade"],
  properties: {
    titulo: CAMPOS_COMUNS.titulo,
    tema: CAMPOS_COMUNS.tema,
    introducao: CAMPOS_COMUNS.introducao,
    palavras: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["palavra", "fato"],
        properties: {
          palavra: { type: "string" },
          fato: { type: "string" },
        },
      },
    },
    curiosidade: CAMPOS_COMUNS.curiosidade,
  },
};

const BASE = (anoEscolar: number) =>
  `Você é ${VOZES.mila} Você cria casos do "Arquivo da Mila" para uma criança do ${anoEscolar}º ano do ensino fundamental no Brasil. Siga a BNCC de História desse ano (por exemplo: a criança, a família e a comunidade; o lugar onde vive; povos indígenas e africanos; Brasil colônia, império e república; migrações; trabalho e tecnologia ao longo do tempo; patrimônio e memória; antiguidade, quando for do ano).

A Mila ensina a pensar como historiadora: olhar a fonte, perguntar quem fez, quando e por quê, e separar o que a fonte mostra do que é palpite.

Use só fatos históricos corretos e confira datas e respostas antes de responder. Nunca invente uma citação de uma pessoa real. Temas difíceis da BNCC (escravidão, guerras, ditadura) podem aparecer, com respeito, sem detalhes violentos e sem opinião partidária.`;

function instrucoesDoDocumento(anoEscolar: number): string {
  return `${BASE(anoEscolar)}

Crie um caso novo e original no modo "documento":
- "titulo": nome curto de investigação.
- "tema": o assunto da BNCC trabalhado.
- "introducao": 1 ou 2 frases, na voz da Mila, contando que fonte ela achou no arquivo.
- "fonte_tipo": carta, foto, pintura, objeto, jornal ou mapa.
- "fonte": a fonte em 2 a 5 frases. Para carta ou jornal, o texto (adaptado para linguagem simples). Para foto, pintura, objeto ou mapa, uma descrição do que se vê, como se a criança estivesse olhando.
- "origem_da_fonte": de onde ela vem e de quando. Se a fonte foi criada para o caso (uma carta imaginada, por exemplo), diga isso, como "Carta imaginada de uma menina em Salvador, 1850".
- "pergunta": uma pergunta de interpretação que se responde olhando a fonte e o contexto, em 1 frase.
- "opcoes": exatamente 4 respostas curtas. Só uma certa; as erradas devem ser enganos comuns (anacronismos, confundir época, tirar conclusão sem prova). Varie a posição da certa.
- "correta": o índice da opção certa.
- "explicacao": 3 a 4 passos curtos, na voz da Mila, mostrando as pistas da fonte que levam à resposta. O último passo diz a resposta.
- "dica": uma pista extra para quem errou, sem dar a resposta.
- "curiosidade": um fato curioso e verdadeiro sobre o tema, em 1 frase.

${REGRAS_DE_SEGURANCA}`;
}

/// Os pequenos (1º a 3º ano) jogam numa grade menor, sem diagonais.
const pequeno = (anoEscolar: number) => anoEscolar <= 3;

function instrucoesDoCacaPalavras(anoEscolar: number): string {
  const [quantas, letras] = pequeno(anoEscolar) ? [5, 7] : [6, 10];
  return `${BASE(anoEscolar)}

Crie um caça-palavras novo e original:
- "titulo": nome curto e divertido.
- "tema": o assunto da BNCC trabalhado.
- "introducao": 1 ou 2 frases, na voz da Mila, contando que palavras do tema se esconderam no arquivo.
- "palavras": exatamente ${quantas} palavras importantes do tema, cada uma com 3 a ${letras} letras, uma palavra só (sem espaço nem hífen), todas diferentes. "fato" explica em 1 frase curta o que a palavra tem a ver com o tema.
- "curiosidade": um fato curioso e verdadeiro sobre o tema, em 1 frase.

${REGRAS_DE_SEGURANCA}`;
}

function instrucoesDaLinha(anoEscolar: number): string {
  return `${BASE(anoEscolar)}

Crie um caso novo e original no modo "linha do tempo":
- "titulo": nome curto de investigação.
- "tema": o assunto da BNCC trabalhado.
- "introducao": 1 ou 2 frases, na voz da Mila: as fichas do arquivo se misturaram e a criança precisa pô-las em ordem.
- "eventos": exatamente ${EVENTOS_NA_LINHA} acontecimentos ligados ao tema, do mais antigo para o mais recente, com anos diferentes. "texto" descreve o acontecimento em 1 frase curta, sem dizer o ano nem dar a ordem ("primeiro", "depois"). Para crianças pequenas, pode ser a história de um objeto ou costume (por exemplo, como as pessoas se comunicavam).
- "explicacao": 3 a 4 passos curtos, na voz da Mila, mostrando como perceber a ordem (o que precisava existir antes, que pistas cada ficha dá).
- "dica": uma pista extra para quem errou, sem dar a ordem.
- "curiosidade": um fato curioso e verdadeiro sobre o tema, em 1 frase.

${REGRAS_DE_SEGURANCA}`;
}

/// Ordem embaralhada (nunca a certa) em que as fichas aparecem no app: a
/// posição i mostra o evento cronológico `embaralhado[i]`.
function embaralhar(quantidade: number): number[] {
  const indices = Array.from({ length: quantidade }, (_, i) => i);
  do {
    for (let i = indices.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [indices[i], indices[j]] = [indices[j], indices[i]];
    }
  } while (indices.every((valor, i) => valor === i));
  return indices;
}

type Evento = { texto: string; ano: string; ano_numero: number };

/// Linha, coluna e direção (passo na linha e na coluna) da primeira letra.
type Posicao = [number, number, number, number];
type PalavraNaGrade = {
  palavra: string;
  chave: string;
  fato: string;
  posicao: Posicao;
};

const sorteio = (n: number) => Math.floor(Math.random() * n);

/// Maiúsculas sem acento, só letras: como a palavra aparece na grade.
function chaveDa(palavra: string): string {
  return palavra
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toUpperCase()
    .replace(/[^A-Z]/g, "");
}

/// Esconde as palavras numa grade quadrada (para a direita, para baixo e,
/// para os maiores, na diagonal) e completa com letras sorteadas. Palavras
/// que não couberem ficam de fora.
function montarGrade(
  palavras: { palavra: string; fato: string }[],
  tamanho: number,
  diagonais: boolean,
): { grade: string[]; colocadas: PalavraNaGrade[] } {
  const direcoes: [number, number][] = diagonais
    ? [[0, 1], [1, 0], [1, 1]]
    : [[0, 1], [1, 0]];
  const grade = Array.from({ length: tamanho }, () =>
    Array<string>(tamanho).fill("")
  );
  const vistas = new Set<string>();
  const candidatas = palavras
    .map((p) => ({ ...p, chave: chaveDa(p.palavra) }))
    .filter((p) => {
      const ok = p.chave.length >= 3 && p.chave.length <= tamanho &&
        !vistas.has(p.chave);
      vistas.add(p.chave);
      return ok;
    });
  const colocadas: PalavraNaGrade[] = [];
  // As maiores primeiro, porque são as mais difíceis de encaixar.
  for (const p of [...candidatas].sort((a, b) => b.chave.length - a.chave.length)) {
    for (let tentativa = 0; tentativa < 200; tentativa++) {
      const [dl, dc] = direcoes[sorteio(direcoes.length)];
      const l = sorteio(tamanho - dl * (p.chave.length - 1));
      const c = sorteio(tamanho - dc * (p.chave.length - 1));
      const cabe = [...p.chave].every((letra, i) => {
        const atual = grade[l + dl * i][c + dc * i];
        return atual === "" || atual === letra;
      });
      if (!cabe) continue;
      [...p.chave].forEach((letra, i) => {
        grade[l + dl * i][c + dc * i] = letra;
      });
      colocadas.push({ ...p, posicao: [l, c, dl, dc] });
      break;
    }
  }
  const alfabeto = "ABCDEFGHIJLMNOPQRSTUVXZ";
  return {
    grade: grade.map((linha) =>
      linha.map((letra) => letra || alfabeto[sorteio(alfabeto.length)]).join("")
    ),
    // Na lista do app, na ordem que a IA mandou.
    colocadas: candidatas
      .map((p) => colocadas.find((c) => c.chave === p.chave))
      .filter((c): c is PalavraNaGrade => c !== undefined),
  };
}

async function carregarCaso(ctx: Contexto) {
  const perfil = await carregarPerfil(ctx);
  const casoId = ctx.corpo.caso_id;
  if (typeof casoId !== "string") throw new ErroDaLiga(400, "Faltou o caso.");
  const { data: linha } = await ctx.servico
    .from("correcoes_ia")
    .select("id, resposta_json")
    .eq("id", casoId)
    .eq("perfil_crianca_id", perfil.id)
    .eq("tipo", TIPO)
    .maybeSingle();
  if (!linha) throw new ErroDaLiga(404, "Caso não encontrado.");
  return {
    perfil,
    id: linha.id as string,
    caso: linha.resposta_json as Record<string, unknown>,
  };
}

async function salvarEstado(
  ctx: Contexto,
  id: string,
  caso: Record<string, unknown>,
  xp?: number,
) {
  await ctx.servico
    .from("correcoes_ia")
    .update({
      resposta_json: caso,
      ...(xp === undefined ? {} : { xp_sugerido: xp }),
    })
    .eq("id", id);
}

async function novoCaso(ctx: Contexto): Promise<Response> {
  const perfil = await carregarPerfil(ctx);
  await conferirLimiteDiario(
    ctx,
    perfil,
    TIPO,
    LIMITE_DIARIO,
    "Você já investigou muito hoje. Amanhã a Mila abre gavetas novas do arquivo!",
  );

  const modo = String(ctx.corpo.modo);
  if (!MODOS.includes(modo)) throw new ErroDaLiga(400, "Escolha um jogo.");
  const ano = perfil.ano_escolar;
  const [instrucoes, esquema] = modo === "caca_palavras"
    ? [instrucoesDoCacaPalavras(ano), ESQUEMA_DO_CACA_PALAVRAS]
    : modo === "linha_do_tempo"
    ? [instrucoesDaLinha(ano), ESQUEMA_DA_LINHA]
    : [instrucoesDoDocumento(ano), ESQUEMA_DO_DOCUMENTO];

  const { dados: caso, modelo } = await perguntarIA({
    instrucoes,
    entrada: "Crie a próxima partida.",
    nomeDoEsquema: `arquivo_mila_${modo}`,
    esquema,
  });

  const seConfundiu = () =>
    new ErroDaLiga(502, "As fichas da Mila se misturaram. Tente de novo.");
  const extras: Record<string, unknown> = {};
  let paraOApp: Record<string, unknown>;
  if (modo === "caca_palavras") {
    const { grade, colocadas } = montarGrade(
      caso.palavras as { palavra: string; fato: string }[],
      pequeno(ano) ? 8 : 10,
      !pequeno(ano),
    );
    if (colocadas.length < 4) throw seConfundiu();
    extras.palavras = colocadas;
    extras.grade = grade;
    paraOApp = {
      grade,
      palavras: colocadas.map(({ palavra, chave, fato }) => ({
        palavra,
        chave,
        fato,
      })),
    };
  } else if (modo === "documento") {
    const opcoes = caso.opcoes as string[];
    const correta = caso.correta as number;
    if (!Number.isInteger(correta) || correta < 0 || correta >= opcoes.length) {
      throw seConfundiu();
    }
    paraOApp = {
      fonte_tipo: caso.fonte_tipo,
      fonte: caso.fonte,
      origem_da_fonte: caso.origem_da_fonte,
      pergunta: caso.pergunta,
      opcoes,
    };
  } else {
    const eventos = caso.eventos as Evento[];
    const emOrdem = eventos.every(
      (e, i) => i === 0 || e.ano_numero > eventos[i - 1].ano_numero,
    );
    if (eventos.length !== EVENTOS_NA_LINHA || !emOrdem) throw seConfundiu();
    const embaralhado = embaralhar(eventos.length);
    extras.embaralhado = embaralhado;
    paraOApp = { eventos: embaralhado.map((e) => eventos[e].texto) };
  }

  const { data: linha, error } = await ctx.servico
    .from("correcoes_ia")
    .insert({
      perfil_crianca_id: perfil.id,
      tipo: TIPO,
      entrada_resumo: `${modo}: ${String(caso.titulo ?? "")}`.slice(0, 500),
      resposta_json: {
        ...caso,
        ...extras,
        modo,
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
    caso_id: linha.id,
    modo,
    titulo: caso.titulo,
    tema: caso.tema,
    introducao: caso.introducao,
    ...paraOApp,
    xp_possivel: XP_DE_PRIMEIRA,
  });
}

/// O que o app recebe quando o caso termina (acertou ou revelou). Na linha
/// do tempo, `ordem_correta` são as posições das fichas, da mais antiga à
/// mais recente, e `anos` é o ano de cada ficha na ordem em que aparecem.
function solucao(caso: Record<string, unknown>) {
  const base = {
    explicacao: caso.explicacao ?? [],
    curiosidade: caso.curiosidade,
  };
  if (caso.modo === "caca_palavras") {
    // A posição de cada palavra, na ordem da lista.
    const palavras = caso.palavras as PalavraNaGrade[];
    return { ...base, posicoes: palavras.map((p) => p.posicao) };
  }
  if (caso.modo === "documento") return { ...base, correta: caso.correta };
  const eventos = caso.eventos as Evento[];
  const embaralhado = caso.embaralhado as number[];
  return {
    ...base,
    ordem_correta: eventos.map((_, cronologico) =>
      embaralhado.indexOf(cronologico)
    ),
    anos: embaralhado.map((e) => eventos[e].ano),
  };
}

async function responder(ctx: Contexto): Promise<Response> {
  const { perfil, id, caso } = await carregarCaso(ctx);

  let acertou: boolean;
  let noLugar: number | null = null;
  let dica = String(caso.dica ?? "");
  if (caso.modo === "caca_palavras") {
    const encontradas = ctx.corpo.encontradas;
    if (!Array.isArray(encontradas)) {
      throw new ErroDaLiga(400, "Faltaram as palavras encontradas.");
    }
    const faltam = (caso.palavras as PalavraNaGrade[]).filter(
      (p) => !encontradas.includes(p.chave),
    ).length;
    acertou = faltam === 0;
    dica = faltam === 1 ? "Falta 1 palavra." : `Faltam ${faltam} palavras.`;
  } else if (caso.modo === "documento") {
    const escolha = ctx.corpo.escolha;
    if (!Number.isInteger(escolha)) {
      throw new ErroDaLiga(400, "Escolha uma resposta.");
    }
    acertou = escolha === caso.correta;
  } else {
    const embaralhado = caso.embaralhado as number[];
    const ordem = ctx.corpo.ordem;
    const valida = Array.isArray(ordem) &&
      ordem.length === embaralhado.length &&
      new Set(ordem).size === ordem.length &&
      ordem.every((p) => Number.isInteger(p) && p >= 0 && p < ordem.length);
    if (!valida) throw new ErroDaLiga(400, "Ponha todas as fichas em ordem.");
    noLugar = (ordem as number[]).filter((p, i) => embaralhado[p] === i).length;
    acertou = noLugar === embaralhado.length;
  }

  const tentativas = Number(caso.tentativas ?? 0);
  let xp = 0;
  if (acertou && !caso.resolvido && !caso.revelado) {
    xp = tentativas === 0 || caso.modo === "caca_palavras"
      ? XP_DE_PRIMEIRA
      : XP_DEPOIS_DE_ERRAR;
  }
  await salvarEstado(
    ctx,
    id,
    {
      ...caso,
      tentativas: tentativas + 1,
      resolvido: Boolean(caso.resolvido) || acertou,
    },
    acertou ? xp : undefined,
  );

  const progresso = await concederXp(ctx, perfil, xp, TIPO, id);

  return resposta(200, {
    acertou,
    dica: acertou ? "" : dica,
    no_lugar: noLugar,
    ...(acertou ? solucao(caso) : { explicacao: [], curiosidade: "" }),
    xp: progresso ? xp : 0,
    progresso,
  });
}

async function revelar(ctx: Contexto): Promise<Response> {
  const { id, caso } = await carregarCaso(ctx);
  if (!caso.revelado) {
    await salvarEstado(ctx, id, { ...caso, revelado: true });
  }
  return resposta(200, solucao(caso));
}

servir("o Arquivo da Mila", (ctx) => {
  switch (ctx.corpo.acao) {
    case "novo_caso":
      return novoCaso(ctx);
    case "responder":
      return responder(ctx);
    case "revelar":
      return revelar(ctx);
    default:
      throw new ErroDaLiga(400, "Ação desconhecida.");
  }
});
