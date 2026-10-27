// Liga do Saber - Edge Function "desafio-matematica" (Nico, Arena Matemática).
//
// acao "novo_desafio": a IA cria um desafio de múltipla escolha para o ano
//   escolar da criança. A resposta e o passo a passo ficam guardados em
//   `correcoes_ia` e não vão ao app.
// acao "responder": confere a escolha. Acertar de primeira vale 20 XP;
//   depois de errar, 10 XP; depois de ver o passo a passo, não vale XP.
// acao "passo_a_passo": mostra a resolução do Nico.
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

const LIMITE_DIARIO = Number(Deno.env.get("LIMITE_DESAFIOS_POR_DIA") ?? "40");
const XP_DE_PRIMEIRA = 20;
const XP_DEPOIS_DE_ERRAR = 10;

const TEMAS: Record<string, string> = {
  operacoes: "operações (adição, subtração, multiplicação ou divisão)",
  fracoes: "frações simples",
  problemas: "problema com situação do dia a dia",
  logica: "lógica, sequências e padrões",
};

const ESQUEMA_DO_DESAFIO = {
  type: "object",
  additionalProperties: false,
  required: ["titulo", "enunciado", "opcoes", "correta", "passos", "dica"],
  properties: {
    titulo: { type: "string" },
    enunciado: { type: "string" },
    opcoes: { type: "array", items: { type: "string" } },
    correta: {
      type: "integer",
      description: "Índice (a partir de 0) da opção certa.",
    },
    passos: { type: "array", items: { type: "string" } },
    dica: {
      type: "string",
      description: "Dica para quem errou, sem entregar a resposta.",
    },
  },
};

function instrucoes(anoEscolar: number): string {
  return `Você é ${VOZES.nico} Você cria desafios da "Arena Matemática" para uma criança do ${anoEscolar}º ano do ensino fundamental no Brasil (siga a BNCC desse ano).

Crie um desafio novo e original:
- "titulo": nome curto e divertido.
- "enunciado": a pergunta, em 1 a 3 frases, com números adequados ao ano.
- "opcoes": exatamente 4 respostas curtas (só o número ou a fração, com unidade se precisar). Só uma certa; as erradas devem ser enganos comuns. Varie a posição da certa.
- "correta": o índice da opção certa.
- "passos": 3 a 5 passos curtos, na voz do Nico, ensinando a estratégia. O último passo diz a resposta.
- "dica": uma pista para quem errou, sem dar a resposta.

Resolva o desafio com cuidado antes de responder e confira a conta duas vezes: a opção certa precisa estar correta.

${REGRAS_DE_SEGURANCA}`;
}

async function carregarDesafio(ctx: Contexto) {
  const perfil = await carregarPerfil(ctx);
  const desafioId = ctx.corpo.desafio_id;
  if (typeof desafioId !== "string") {
    throw new ErroDaLiga(400, "Faltou o desafio.");
  }
  const { data: linha } = await ctx.servico
    .from("correcoes_ia")
    .select("id, resposta_json")
    .eq("id", desafioId)
    .eq("perfil_crianca_id", perfil.id)
    .eq("tipo", "matematica")
    .maybeSingle();
  if (!linha) throw new ErroDaLiga(404, "Desafio não encontrado.");
  return {
    perfil,
    id: linha.id as string,
    desafio: linha.resposta_json as Record<string, unknown>,
  };
}

async function salvarEstado(
  ctx: Contexto,
  id: string,
  desafio: Record<string, unknown>,
  xp?: number,
) {
  await ctx.servico
    .from("correcoes_ia")
    .update({
      resposta_json: desafio,
      ...(xp === undefined ? {} : { xp_sugerido: xp }),
    })
    .eq("id", id);
}

async function novoDesafio(ctx: Contexto): Promise<Response> {
  const perfil = await carregarPerfil(ctx);
  await conferirLimiteDiario(
    ctx,
    perfil,
    "matematica",
    LIMITE_DIARIO,
    "Você já enfrentou muitos desafios hoje. Amanhã o Nico traz mais!",
  );

  const tema = TEMAS[String(ctx.corpo.tema)] ?? "tema surpresa";
  const { dados: desafio, modelo } = await perguntarIA({
    instrucoes: instrucoes(perfil.ano_escolar),
    entrada: `Tema do desafio: ${tema}.`,
    nomeDoEsquema: "desafio_matematica",
    esquema: ESQUEMA_DO_DESAFIO,
  });

  const opcoes = desafio.opcoes as string[];
  const correta = desafio.correta as number;
  if (!Number.isInteger(correta) || correta < 0 || correta >= opcoes.length) {
    throw new ErroDaLiga(502, "O Nico se atrapalhou com esse desafio. Tente de novo.");
  }

  const { data: linha, error } = await ctx.servico
    .from("correcoes_ia")
    .insert({
      perfil_crianca_id: perfil.id,
      tipo: "matematica",
      entrada_resumo: String(desafio.enunciado ?? "").slice(0, 500),
      resposta_json: { ...desafio, tentativas: 0, revelado: false, resolvido: false },
      modelo_usado: modelo,
    })
    .select("id")
    .single();
  if (error) throw error;

  return resposta(200, {
    desafio_id: linha.id,
    titulo: desafio.titulo,
    enunciado: desafio.enunciado,
    opcoes,
    xp_possivel: XP_DE_PRIMEIRA,
  });
}

async function responder(ctx: Contexto): Promise<Response> {
  const { perfil, id, desafio } = await carregarDesafio(ctx);
  const escolha = ctx.corpo.escolha;
  if (!Number.isInteger(escolha)) {
    throw new ErroDaLiga(400, "Escolha uma resposta.");
  }

  const acertou = escolha === desafio.correta;
  const tentativas = Number(desafio.tentativas ?? 0);
  let xp = 0;
  if (acertou && !desafio.resolvido && !desafio.revelado) {
    xp = tentativas === 0 ? XP_DE_PRIMEIRA : XP_DEPOIS_DE_ERRAR;
  }
  await salvarEstado(
    ctx,
    id,
    {
      ...desafio,
      tentativas: tentativas + 1,
      resolvido: Boolean(desafio.resolvido) || acertou,
    },
    acertou ? xp : undefined,
  );

  const progresso = await concederXp(ctx, perfil, xp, "matematica", id);

  return resposta(200, {
    acertou,
    dica: acertou ? "" : desafio.dica,
    passos: acertou ? desafio.passos : [],
    correta: acertou ? desafio.correta : null,
    xp: progresso ? xp : 0,
    progresso,
  });
}

async function passoAPasso(ctx: Contexto): Promise<Response> {
  const { id, desafio } = await carregarDesafio(ctx);
  if (!desafio.revelado) await salvarEstado(ctx, id, { ...desafio, revelado: true });
  return resposta(200, {
    passos: desafio.passos,
    correta: desafio.correta,
  });
}

servir("a Arena Matemática", (ctx) => {
  switch (ctx.corpo.acao) {
    case "novo_desafio":
      return novoDesafio(ctx);
    case "responder":
      return responder(ctx);
    case "passo_a_passo":
      return passoAPasso(ctx);
    default:
      throw new ErroDaLiga(400, "Ação desconhecida.");
  }
});
