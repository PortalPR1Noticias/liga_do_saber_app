// Liga do Saber - Edge Function "expedicao-teo" (Teo, Trilha do Teo).
//
// acao "nova_expedicao": a IA cria uma investigação de Ciências ou
//   Geografia para o ano escolar da criança: uma cena com pistas e uma
//   pergunta de múltipla escolha. A resposta, a explicação e a curiosidade
//   ficam guardadas em `correcoes_ia` e não vão ao app.
// acao "responder": confere a escolha. Acertar de primeira vale 20 XP;
//   depois de errar, 10 XP; depois de ver a explicação, não vale XP.
// acao "revelar": mostra a descoberta do Teo.
//
// Só o ano escolar e a matéria vão para a OpenAI (nada escrito pela
// criança), então, como a Arena Matemática, não depende de
// `responsaveis.autoriza_ia`.
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

const TIPO = "expedicao";
const LIMITE_DIARIO = Number(Deno.env.get("LIMITE_EXPEDICOES_POR_DIA") ?? "40");
const XP_DE_PRIMEIRA = 20;
const XP_DEPOIS_DE_ERRAR = 10;

const MATERIAS: Record<string, string> = {
  ciencias:
    "Ciências (por exemplo: seres vivos, corpo humano e saúde, plantas, animais e ecossistemas, água, ar e solo, materiais e misturas, energia, Terra e Universo)",
  geografia:
    "Geografia (por exemplo: mapas e orientação, paisagens, relevo, rios, clima e tempo, regiões e biomas do Brasil, campo e cidade, trabalho, cuidado com o ambiente)",
};

const ESQUEMA_DA_EXPEDICAO = {
  type: "object",
  additionalProperties: false,
  required: [
    "titulo",
    "tema",
    "cena",
    "pistas",
    "pergunta",
    "opcoes",
    "correta",
    "descoberta",
    "dica",
    "curiosidade",
  ],
  properties: {
    titulo: { type: "string" },
    tema: {
      type: "string",
      description: "Assunto da BNCC, em 2 a 4 palavras.",
    },
    cena: { type: "string" },
    pistas: { type: "array", items: { type: "string" } },
    pergunta: { type: "string" },
    opcoes: { type: "array", items: { type: "string" } },
    correta: {
      type: "integer",
      description: "Índice (a partir de 0) da opção certa.",
    },
    descoberta: { type: "array", items: { type: "string" } },
    dica: {
      type: "string",
      description: "Dica para quem errou, sem entregar a resposta.",
    },
    curiosidade: { type: "string" },
  },
};

function instrucoes(anoEscolar: number, materia: string): string {
  return `Você é ${VOZES.teo} Você cria expedições da "Trilha do Teo" para uma criança do ${anoEscolar}º ano do ensino fundamental no Brasil. Siga a BNCC desse ano em ${materia}.

Cada expedição é uma pequena investigação: o Teo chega a um lugar, observa o que aconteceu e a criança descobre a explicação a partir das pistas.

Crie uma expedição nova e original:
- "titulo": nome curto e aventureiro.
- "tema": o assunto da BNCC trabalhado.
- "cena": 2 a 4 frases, na voz do Teo, contando onde ele está e o mistério que encontrou. Use lugares do Brasil quando fizer sentido.
- "pistas": 2 ou 3 observações curtas que ajudam a resolver (sem dar a resposta).
- "pergunta": a pergunta da investigação, em 1 frase.
- "opcoes": exatamente 4 respostas curtas. Só uma certa; as erradas devem ser ideias comuns das crianças sobre o tema. Varie a posição da certa.
- "correta": o índice da opção certa.
- "descoberta": 3 a 4 passos curtos, na voz do Teo, explicando o porquê com as pistas. O último passo diz a resposta.
- "dica": uma pista extra para quem errou, sem dar a resposta.
- "curiosidade": um fato curioso e verdadeiro sobre o tema, em 1 frase.

Use só informações científicas corretas e confira a resposta antes de responder. Nada de experimentos perigosos (fogo, eletricidade, produtos químicos, provar coisas): se sugerir observar algo, que seja seguro e com um adulto.

${REGRAS_DE_SEGURANCA}`;
}

async function carregarExpedicao(ctx: Contexto) {
  const perfil = await carregarPerfil(ctx);
  const expedicaoId = ctx.corpo.expedicao_id;
  if (typeof expedicaoId !== "string") {
    throw new ErroDaLiga(400, "Faltou a expedição.");
  }
  const { data: linha } = await ctx.servico
    .from("correcoes_ia")
    .select("id, resposta_json")
    .eq("id", expedicaoId)
    .eq("perfil_crianca_id", perfil.id)
    .eq("tipo", TIPO)
    .maybeSingle();
  if (!linha) throw new ErroDaLiga(404, "Expedição não encontrada.");
  return {
    perfil,
    id: linha.id as string,
    expedicao: linha.resposta_json as Record<string, unknown>,
  };
}

async function salvarEstado(
  ctx: Contexto,
  id: string,
  expedicao: Record<string, unknown>,
  xp?: number,
) {
  await ctx.servico
    .from("correcoes_ia")
    .update({
      resposta_json: expedicao,
      ...(xp === undefined ? {} : { xp_sugerido: xp }),
    })
    .eq("id", id);
}

async function novaExpedicao(ctx: Contexto): Promise<Response> {
  const perfil = await carregarPerfil(ctx);
  await conferirLimiteDiario(
    ctx,
    perfil,
    TIPO,
    LIMITE_DIARIO,
    "Você já explorou muito hoje. Amanhã o Teo abre trilhas novas!",
  );

  const chave = String(ctx.corpo.materia);
  const materia = MATERIAS[chave];
  if (!materia) throw new ErroDaLiga(400, "Escolha Ciências ou Geografia.");

  const { dados: expedicao, modelo } = await perguntarIA({
    instrucoes: instrucoes(perfil.ano_escolar, materia),
    entrada: "Crie a próxima expedição.",
    nomeDoEsquema: "expedicao_teo",
    esquema: ESQUEMA_DA_EXPEDICAO,
  });

  const opcoes = expedicao.opcoes as string[];
  const correta = expedicao.correta as number;
  if (!Number.isInteger(correta) || correta < 0 || correta >= opcoes.length) {
    throw new ErroDaLiga(502, "O Teo se perdeu nessa trilha. Tente de novo.");
  }

  const { data: linha, error } = await ctx.servico
    .from("correcoes_ia")
    .insert({
      perfil_crianca_id: perfil.id,
      tipo: TIPO,
      entrada_resumo: `${chave}: ${String(expedicao.pergunta ?? "")}`.slice(0, 500),
      resposta_json: {
        ...expedicao,
        materia: chave,
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
    expedicao_id: linha.id,
    materia: chave,
    titulo: expedicao.titulo,
    tema: expedicao.tema,
    cena: expedicao.cena,
    pistas: expedicao.pistas,
    pergunta: expedicao.pergunta,
    opcoes,
    xp_possivel: XP_DE_PRIMEIRA,
  });
}

/// O que o app recebe quando a expedição termina (acertou ou revelou).
function descoberta(expedicao: Record<string, unknown>) {
  return {
    descoberta: expedicao.descoberta,
    curiosidade: expedicao.curiosidade,
    correta: expedicao.correta,
  };
}

async function responder(ctx: Contexto): Promise<Response> {
  const { perfil, id, expedicao } = await carregarExpedicao(ctx);
  const escolha = ctx.corpo.escolha;
  if (!Number.isInteger(escolha)) {
    throw new ErroDaLiga(400, "Escolha uma resposta.");
  }

  const acertou = escolha === expedicao.correta;
  const tentativas = Number(expedicao.tentativas ?? 0);
  let xp = 0;
  if (acertou && !expedicao.resolvido && !expedicao.revelado) {
    xp = tentativas === 0 ? XP_DE_PRIMEIRA : XP_DEPOIS_DE_ERRAR;
  }
  await salvarEstado(
    ctx,
    id,
    {
      ...expedicao,
      tentativas: tentativas + 1,
      resolvido: Boolean(expedicao.resolvido) || acertou,
    },
    acertou ? xp : undefined,
  );

  const progresso = await concederXp(ctx, perfil, xp, TIPO, id);

  return resposta(200, {
    acertou,
    dica: acertou ? "" : expedicao.dica,
    ...(acertou
      ? descoberta(expedicao)
      : { descoberta: [], curiosidade: "", correta: null }),
    xp: progresso ? xp : 0,
    progresso,
  });
}

async function revelar(ctx: Contexto): Promise<Response> {
  const { id, expedicao } = await carregarExpedicao(ctx);
  if (!expedicao.revelado) {
    await salvarEstado(ctx, id, { ...expedicao, revelado: true });
  }
  return resposta(200, descoberta(expedicao));
}

servir("a Trilha do Teo", (ctx) => {
  switch (ctx.corpo.acao) {
    case "nova_expedicao":
      return novaExpedicao(ctx);
    case "responder":
      return responder(ctx);
    case "revelar":
      return revelar(ctx);
    default:
      throw new ErroDaLiga(400, "Ação desconhecida.");
  }
});
