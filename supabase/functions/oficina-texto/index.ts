// Liga do Saber - Edge Function "oficina-texto" (Luma, Oficina de Texto).
//
// acao "feedback": recebe o tema, o planejamento e a versão 1 do texto e
//   devolve o feedback da Luma (clareza, organização, pontuação e
//   criatividade). Grava em `producoes_textuais` e dá 15 XP.
// acao "reescrita": recebe a versão melhorada, compara com a primeira e dá
//   XP pela evolução (10 a 34 XP), uma vez por texto.
//
// O texto da criança vai para a OpenAI (`store: false`) e fica guardado em
// `producoes_textuais` para o responsável acompanhar.
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

const LIMITE_DIARIO = Number(Deno.env.get("LIMITE_TEXTOS_POR_DIA") ?? "20");
const XP_PRIMEIRA_VERSAO = 15;
const XP_REESCRITA_BASE = 10;
const XP_POR_PONTO_DE_EVOLUCAO = 8;
const TAMANHO_MAXIMO = 3000;
const MINIMO_DE_PALAVRAS = 15;

const CRITERIOS = ["clareza", "organizacao", "pontuacao", "criatividade"];

const ESQUEMA_DOS_CRITERIOS = {
  type: "array",
  items: {
    type: "object",
    additionalProperties: false,
    required: ["criterio", "estrelas", "comentario"],
    properties: {
      criterio: { type: "string", enum: CRITERIOS },
      estrelas: { type: "integer", description: "1 a 3." },
      comentario: { type: "string" },
    },
  },
};

const ESQUEMA_DO_FEEDBACK = {
  type: "object",
  additionalProperties: false,
  required: [
    "adequado",
    "criterios",
    "pontos_fortes",
    "sugestoes",
    "mensagem",
  ],
  properties: {
    adequado: {
      type: "boolean",
      description:
        "false se não for um texto de verdade ou tiver conteúdo impróprio.",
    },
    criterios: ESQUEMA_DOS_CRITERIOS,
    pontos_fortes: { type: "array", items: { type: "string" } },
    sugestoes: { type: "array", items: { type: "string" } },
    mensagem: { type: "string" },
  },
};

const ESQUEMA_DA_REESCRITA = {
  type: "object",
  additionalProperties: false,
  required: ["adequado", "evolucao", "criterios", "melhorias", "proximo_passo", "mensagem"],
  properties: {
    adequado: { type: "boolean" },
    evolucao: {
      type: "integer",
      description:
        "0 = não mudou, 1 = melhorou um pouco, 2 = melhorou bem, 3 = melhorou muito.",
    },
    criterios: ESQUEMA_DOS_CRITERIOS,
    melhorias: { type: "array", items: { type: "string" } },
    proximo_passo: { type: "string" },
    mensagem: { type: "string" },
  },
};

function instrucoes(anoEscolar: number, tarefa: string): string {
  return `Você é ${VOZES.luma} Você é a professora da "Oficina de Texto" e lê textos de uma criança do ${anoEscolar}º ano do ensino fundamental no Brasil.

${tarefa}

Como avaliar:
- Critérios: clareza, organizacao (começo, meio e fim), pontuacao (e ortografia) e criatividade. Dê 1, 2 ou 3 estrelas, de acordo com o esperado para o ${anoEscolar}º ano, com um comentário curto em cada.
- Seja gentil e específica. Ao sugerir, cite o trecho da criança e mostre um caminho, mas não reescreva o texto por ela.
- Fale com a criança em segunda pessoa ("você"), na voz da Luma.
- Se não for um texto de verdade (letras soltas, cópia de outra coisa) ou tiver conteúdo impróprio, use adequado=false, listas vazias e explique com carinho em "mensagem" o que fazer.

${REGRAS_DE_SEGURANCA}`;
}

function lerTexto(valor: unknown): string {
  if (typeof valor !== "string" || valor.trim().length === 0) {
    throw new ErroDaLiga(400, "Escreva o seu texto antes de enviar.");
  }
  const texto = valor.trim();
  if (texto.length > TAMANHO_MAXIMO) {
    throw new ErroDaLiga(413, "O texto ficou grande demais. Tente um texto mais curto.");
  }
  return texto;
}

function contarPalavras(texto: string): number {
  return texto.split(/\s+/).filter(Boolean).length;
}

async function feedback(ctx: Contexto): Promise<Response> {
  const perfil = await carregarPerfil(ctx);
  const texto = lerTexto(ctx.corpo.texto);
  const tema = String(ctx.corpo.tema ?? "").trim().slice(0, 120) || "tema livre";
  const plano = (ctx.corpo.planejamento ?? {}) as Record<string, unknown>;
  const planejamento = {
    comeco: String(plano.comeco ?? "").slice(0, 300),
    meio: String(plano.meio ?? "").slice(0, 300),
    fim: String(plano.fim ?? "").slice(0, 300),
  };
  await conferirLimiteDiario(
    ctx,
    perfil,
    "texto",
    LIMITE_DIARIO,
    "Você já escreveu muitos textos hoje. Amanhã a Luma lê mais!",
  );

  const { dados, modelo } = await perguntarIA({
    instrucoes: instrucoes(
      perfil.ano_escolar,
      "A criança escreveu a primeira versão de um texto. Dê o feedback: pontos fortes (1 ou 2), sugestões concretas para a reescrita (2 ou 3) e uma mensagem final animando a criança a reescrever.",
    ),
    entrada: `Tema: ${tema}
Planejamento da criança:
- Começo: ${planejamento.comeco || "(não preencheu)"}
- Meio: ${planejamento.meio || "(não preencheu)"}
- Final: ${planejamento.fim || "(não preencheu)"}

Texto (versão 1):
"""
${texto}
"""`,
    nomeDoEsquema: "feedback_do_texto",
    esquema: ESQUEMA_DO_FEEDBACK,
  });

  const { data: producao, error } = await ctx.servico
    .from("producoes_textuais")
    .insert({
      perfil_crianca_id: perfil.id,
      tema,
      planejamento,
      texto_original: texto,
      feedback_json: dados,
      status: dados.adequado ? "feedback" : "rascunho",
    })
    .select("id")
    .single();
  if (error) throw error;

  // Registro para o limite diário e o histórico de uso da IA.
  await ctx.servico.from("correcoes_ia").insert({
    perfil_crianca_id: perfil.id,
    tipo: "texto",
    entrada_resumo: tema,
    resposta_json: dados,
    modelo_usado: modelo,
  });

  const xp = dados.adequado && contarPalavras(texto) >= MINIMO_DE_PALAVRAS
    ? XP_PRIMEIRA_VERSAO
    : 0;
  const progresso = await concederXp(ctx, perfil, xp, "texto", producao.id);
  if (progresso) {
    await ctx.servico
      .from("producoes_textuais")
      .update({ xp_recebido: xp })
      .eq("id", producao.id);
  }

  return resposta(200, {
    producao_id: producao.id,
    ...dados,
    xp: progresso ? xp : 0,
    progresso,
  });
}

async function reescrita(ctx: Contexto): Promise<Response> {
  const perfil = await carregarPerfil(ctx);
  const texto = lerTexto(ctx.corpo.texto);
  const producaoId = ctx.corpo.producao_id;
  if (typeof producaoId !== "string") {
    throw new ErroDaLiga(400, "Faltou o texto original.");
  }
  const { data: producao } = await ctx.servico
    .from("producoes_textuais")
    .select("id, tema, texto_original, texto_reescrito, feedback_json, xp_recebido")
    .eq("id", producaoId)
    .eq("perfil_crianca_id", perfil.id)
    .maybeSingle();
  if (!producao) throw new ErroDaLiga(404, "Texto não encontrado.");
  if (producao.texto_reescrito) {
    throw new ErroDaLiga(409, "Você já reescreveu esse texto. Que tal começar um novo?");
  }
  await conferirLimiteDiario(
    ctx,
    perfil,
    "texto",
    LIMITE_DIARIO,
    "Você já escreveu muitos textos hoje. Amanhã a Luma lê mais!",
  );

  const { dados, modelo } = await perguntarIA({
    instrucoes: instrucoes(
      perfil.ano_escolar,
      "A criança reescreveu o texto usando o seu feedback. Compare as duas versões e avalie a evolução: o que melhorou (1 a 3 itens), as novas estrelas de cada critério, um próximo passo para o próximo texto e uma mensagem de comemoração. Valorize o esforço de reescrever.",
    ),
    entrada: `Tema: ${producao.tema}

Versão 1:
"""
${producao.texto_original}
"""

Seu feedback da versão 1:
${JSON.stringify(producao.feedback_json)}

Versão 2 (reescrita):
"""
${texto}
"""`,
    nomeDoEsquema: "evolucao_do_texto",
    esquema: ESQUEMA_DA_REESCRITA,
  });

  const evolucao = Math.max(0, Math.min(3, Number(dados.evolucao) || 0));
  const xp = dados.adequado && texto !== producao.texto_original
    ? XP_REESCRITA_BASE + XP_POR_PONTO_DE_EVOLUCAO * evolucao
    : 0;

  await ctx.servico.from("correcoes_ia").insert({
    perfil_crianca_id: perfil.id,
    tipo: "texto",
    entrada_resumo: `Reescrita: ${producao.tema}`,
    resposta_json: dados,
    xp_sugerido: xp,
    modelo_usado: modelo,
  });

  const progresso = await concederXp(ctx, perfil, xp, "texto_reescrita", producao.id);
  const { error } = await ctx.servico
    .from("producoes_textuais")
    .update({
      texto_reescrito: texto,
      feedback_json: { primeira_versao: producao.feedback_json, reescrita: dados },
      status: "reescrito",
      xp_recebido: (producao.xp_recebido ?? 0) + (progresso ? xp : 0),
    })
    .eq("id", producao.id);
  if (error) console.error("Falha ao gravar a reescrita", error.message);

  return resposta(200, {
    ...dados,
    evolucao,
    xp: progresso ? xp : 0,
    progresso,
  });
}

servir("a Oficina de Texto", (ctx) => {
  switch (ctx.corpo.acao) {
    case "feedback":
      return feedback(ctx);
    case "reescrita":
      return reescrita(ctx);
    default:
      throw new ErroDaLiga(400, "Ação desconhecida.");
  }
});
