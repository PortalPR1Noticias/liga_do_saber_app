// Liga do Saber - Edge Function "detetive-leitura" (Luma).
//
// acao "novo_caso": a IA escreve um texto curto com três perguntas de
//   interpretação (ideia principal, inferência e localizar informação).
//   As respostas certas ficam guardadas em `correcoes_ia` e não vão ao app.
// acao "responder": confere as respostas, mostra as pistas e dá XP
//   (10 por acerto), uma vez por caso.
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

const LIMITE_DIARIO = Number(Deno.env.get("LIMITE_CASOS_POR_DIA") ?? "15");
const XP_POR_ACERTO = 10;

const HABILIDADES = ["ideia_principal", "inferencia", "localizar"] as const;

const ESQUEMA_DO_CASO = {
  type: "object",
  additionalProperties: false,
  required: ["titulo", "texto", "perguntas", "mensagem_inicial"],
  properties: {
    titulo: { type: "string" },
    texto: { type: "string" },
    perguntas: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: [
          "habilidade",
          "pergunta",
          "opcoes",
          "correta",
          "pista",
          "explicacao",
        ],
        properties: {
          habilidade: { type: "string", enum: HABILIDADES },
          pergunta: { type: "string" },
          opcoes: { type: "array", items: { type: "string" } },
          correta: {
            type: "integer",
            description: "Índice (a partir de 0) da opção certa.",
          },
          pista: {
            type: "string",
            description: "Trecho copiado do texto que prova a resposta.",
          },
          explicacao: { type: "string" },
        },
      },
    },
    mensagem_inicial: { type: "string" },
  },
};

function instrucoes(anoEscolar: number): string {
  return `Você é ${VOZES.luma} Você cria casos do "Detetive da Leitura" para uma criança do ${anoEscolar}º ano do ensino fundamental no Brasil.

Crie um caso novo e original:
- "titulo": nome divertido de mistério, como "O bilhete desaparecido".
- "texto": uma história ou texto informativo curto e completo (${anoEscolar <= 3 ? "60 a 100" : anoEscolar <= 5 ? "90 a 150" : "130 a 200"} palavras), adequado ao ano escolar, com pistas que permitam responder às perguntas.
- "perguntas": exatamente 3, nesta ordem de habilidade: ideia_principal, inferencia, localizar.
  - Cada uma com 3 opções curtas e plausíveis, só uma certa. Varie a posição da opção certa.
  - "pista": copie literalmente o trecho do texto que prova a resposta.
  - "explicacao": 1 ou 2 frases, na voz da Luma, mostrando como a pista leva à resposta.
- "mensagem_inicial": uma frase da Luma convidando a criança a investigar.

Antes de responder, confira se cada resposta certa está mesmo apoiada no texto.

${REGRAS_DE_SEGURANCA}`;
}

async function novoCaso(ctx: Contexto): Promise<Response> {
  const perfil = await carregarPerfil(ctx);
  await conferirLimiteDiario(
    ctx,
    perfil,
    "leitura",
    LIMITE_DIARIO,
    "Você já resolveu muitos casos hoje. Amanhã tem mais mistério!",
  );

  const tema = typeof ctx.corpo.tema === "string"
    ? ctx.corpo.tema.slice(0, 80)
    : "";
  const { dados: caso, modelo } = await perguntarIA({
    instrucoes: instrucoes(perfil.ano_escolar),
    entrada: tema
      ? `Quero um caso novo sobre: ${tema}`
      : "Quero um caso novo, com um tema surpresa.",
    nomeDoEsquema: "caso_de_leitura",
    esquema: ESQUEMA_DO_CASO,
  });

  const perguntas = (caso.perguntas as Record<string, unknown>[]).filter(
    (p) =>
      Array.isArray(p.opcoes) &&
      Number.isInteger(p.correta) &&
      (p.correta as number) >= 0 &&
      (p.correta as number) < (p.opcoes as unknown[]).length,
  );
  if (perguntas.length === 0) {
    throw new ErroDaLiga(502, "A Luma se atrapalhou com esse caso. Tente de novo.");
  }

  const { data: linha, error } = await ctx.servico
    .from("correcoes_ia")
    .insert({
      perfil_crianca_id: perfil.id,
      tipo: "leitura",
      entrada_resumo: String(caso.titulo ?? "").slice(0, 200),
      resposta_json: { ...caso, perguntas },
      modelo_usado: modelo,
    })
    .select("id")
    .single();
  if (error) throw error;

  return resposta(200, {
    caso_id: linha.id,
    titulo: caso.titulo,
    texto: caso.texto,
    mensagem_inicial: caso.mensagem_inicial,
    perguntas: perguntas.map((p) => ({
      habilidade: p.habilidade,
      pergunta: p.pergunta,
      opcoes: p.opcoes,
    })),
    xp_por_acerto: XP_POR_ACERTO,
  });
}

async function responder(ctx: Contexto): Promise<Response> {
  const perfil = await carregarPerfil(ctx);
  const { caso_id: casoId, respostas } = ctx.corpo;
  if (typeof casoId !== "string" || !Array.isArray(respostas)) {
    throw new ErroDaLiga(400, "Faltaram as respostas do caso.");
  }

  const { data: linha } = await ctx.servico
    .from("correcoes_ia")
    .select("id, resposta_json")
    .eq("id", casoId)
    .eq("perfil_crianca_id", perfil.id)
    .eq("tipo", "leitura")
    .maybeSingle();
  if (!linha) throw new ErroDaLiga(404, "Caso não encontrado.");

  const caso = linha.resposta_json as Record<string, unknown>;
  const perguntas = caso.perguntas as Record<string, unknown>[];
  const resultados = perguntas.map((p, i) => ({
    escolhida: Number.isInteger(respostas[i]) ? respostas[i] : -1,
    correta: p.correta,
    acertou: respostas[i] === p.correta,
    pista: p.pista,
    explicacao: p.explicacao,
  }));
  const acertos = resultados.filter((r) => r.acertou).length;
  const jaRespondido = caso.respostas !== undefined;
  const xp = jaRespondido ? 0 : acertos * XP_POR_ACERTO;

  if (!jaRespondido) {
    await ctx.servico
      .from("correcoes_ia")
      .update({
        resposta_json: { ...caso, respostas },
        xp_sugerido: xp,
      })
      .eq("id", linha.id);
  }

  const progresso = await concederXp(ctx, perfil, xp, "leitura", linha.id);

  return resposta(200, {
    resultados,
    acertos,
    total: perguntas.length,
    ja_respondido: jaRespondido,
    xp: progresso ? xp : 0,
    progresso,
  });
}

servir("o Detetive da Leitura", (ctx) => {
  switch (ctx.corpo.acao) {
    case "novo_caso":
      return novoCaso(ctx);
    case "responder":
      return responder(ctx);
    default:
      throw new ErroDaLiga(400, "Ação desconhecida.");
  }
});
