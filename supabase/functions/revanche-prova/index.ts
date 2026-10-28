// Liga do Saber - Edge Function "revanche-prova" (Revanche da prova).
//
// acao "enviar" (Área dos responsáveis): recebe até 10 fotos e/ou um PDF de
//   uma prova ou tarefa que a criança já fez. A OpenAI lê e cria questões de
//   treino de múltipla escolha: as da própria prova e outras parecidas,
//   começando pelas que a criança errou. Tudo fica em `provas_treino`
//   (migration 0009). Fotos e PDF não são guardados e só vão para a OpenAI com
//   a autorização do responsável (responsaveis.autoriza_ia).
// acao "abrir": devolve as questões sem a resposta certa.
// acao "responder": confere uma questão. Acertar de primeira vale 10 XP;
//   depois de errar, 5 XP. No segundo erro o herói explica e a questão volta
//   no fim da fila, sem XP. Quando a criança acerta todas, a prova está
//   vencida: +30 XP e estrelas pelos acertos de primeira.
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
  type Progresso,
} from "../_shared/liga.ts";

/// Quantas provas cada criança pode receber por dia (protege o custo da IA).
const LIMITE_DIARIO = Number(Deno.env.get("LIMITE_PROVAS_POR_DIA") ?? "10");

const MAXIMO_DE_FOTOS = 10;

/// Base64 de uma imagem de ~4,5 MB. O app já reduz as fotos antes de enviar.
const TAMANHO_MAXIMO_BASE64 = 6_000_000;
/// Base64 de um PDF de ~6 MB.
const TAMANHO_MAXIMO_PDF = 8_200_000;
const TAMANHO_MAXIMO_TOTAL = 16_000_000;

/// Cada página do PDF vira texto e imagem para a IA: o mesmo teto das fotos
/// protege o custo.
const MAXIMO_DE_PAGINAS_PDF = 10;

const TIPOS_DE_IMAGEM = ["image/jpeg", "image/png", "image/webp"];

const XP_DE_PRIMEIRA = 10;
const XP_DEPOIS_DE_ERRAR = 5;
const XP_PROVA_VENCIDA = 30;

/// Erros antes de o herói explicar a questão.
const ERROS_ATE_EXPLICAR = 2;

/// Cada matéria é guiada por um personagem oficial da Liga.
const PERSONAGEM_DA_MATERIA: Record<string, keyof typeof VOZES> = {
  matematica: "nico",
  portugues: "luma",
  ciencias: "teo",
  geografia: "teo",
  historia: "mila",
  ingles: "luma",
  artes: "zuri",
  outra: "zuri",
};

const ESQUEMA_DA_PROVA = {
  type: "object",
  additionalProperties: false,
  required: [
    "legivel",
    "titulo",
    "materia",
    "conteudos",
    "resumo_responsavel",
    "questoes",
  ],
  properties: {
    legivel: {
      type: "boolean",
      description:
        "false se as fotos ou o PDF não mostram uma prova ou tarefa escolar, ou não dá para ler.",
    },
    titulo: {
      type: "string",
      description: "Nome curto, como \"Prova de frações\".",
    },
    materia: { type: "string", enum: Object.keys(PERSONAGEM_DA_MATERIA) },
    conteudos: {
      type: "array",
      items: { type: "string" },
      description: "Os conteúdos que caíram, em poucas palavras cada.",
    },
    resumo_responsavel: {
      type: "string",
      description:
        "2 a 4 frases para o adulto: o que caiu, o que a criança errou (se der para ver) e o que vale reforçar.",
    },
    questoes: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: [
          "conteudo",
          "origem",
          "errou_na_prova",
          "enunciado",
          "opcoes",
          "correta",
          "dica",
          "explicacao",
        ],
        properties: {
          conteudo: { type: "string" },
          origem: { type: "string", enum: ["da_prova", "parecida"] },
          errou_na_prova: {
            type: "boolean",
            description:
              "true se a questão (ou a original dela) aparece errada ou em branco na prova.",
          },
          enunciado: { type: "string" },
          opcoes: { type: "array", items: { type: "string" } },
          correta: {
            type: "integer",
            description: "Índice (a partir de 0) da opção certa.",
          },
          dica: {
            type: "string",
            description: "Pista para quem errou, sem entregar a resposta.",
          },
          explicacao: {
            type: "array",
            items: { type: "string" },
            description: "2 a 4 passos curtos ensinando o raciocínio; o último diz a resposta.",
          },
        },
      },
    },
  },
};

function instrucoes(anoEscolar: number, material: string): string {
  const nome = material === "tarefa" ? "tarefa" : "prova";
  return `Você é a equipe de tutores do app Liga do Saber. O responsável de uma criança do ${anoEscolar}º ano do ensino fundamental mandou fotos ou um PDF de uma ${nome} que ela já fez na escola, para ela treinar na "Revanche da prova".

Seu trabalho:
1. Ler as fotos e o PDF (o que vier), descobrir a matéria e os conteúdos que caíram.
2. Criar de 6 a 10 questões de treino de múltipla escolha:
   - Primeiro, as questões da própria ${nome} (origem "da_prova"), reescritas como múltipla escolha quando forem abertas. Se der para ver correção do professor, resposta errada ou em branco, marque errou_na_prova=true.
   - Depois, questões parecidas (origem "parecida"), com os mesmos conteúdos e outros números ou exemplos, para a criança treinar de verdade. Faça mais questões parecidas para os conteúdos que ela errou.
   - Cada questão tem 3 ou 4 opções curtas, só uma certa; as erradas são enganos comuns. Varie a posição da certa.
   - Se a questão depender de uma figura, descreva no enunciado o que a criança precisa saber.
3. Para cada questão: "dica" (pista sem a resposta) e "explicacao" (2 a 4 passos curtos ensinando o raciocínio, com a voz do personagem da matéria; o último passo diz a resposta).
4. "resumo_responsavel": recado curto e objetivo para o adulto.

Vozes dos personagens, por matéria:
- matematica: ${VOZES.nico}
- portugues e ingles: ${VOZES.luma}
- ciencias e geografia: ${VOZES.teo}
- historia: ${VOZES.mila}
- artes ou outra: ${VOZES.zuri}

Resolva cada questão com cuidado e confira duas vezes: a opção marcada como certa precisa estar correta.

Se as fotos ou o PDF não mostrarem uma prova ou tarefa escolar, estiverem ilegíveis ou tiverem conteúdo impróprio para crianças, use legivel=false e questoes vazio, e explique o motivo em resumo_responsavel.

Não copie nomes de pessoas, escola, turma, professor ou outros dados pessoais que apareçam nas fotos ou no PDF.

${REGRAS_DE_SEGURANCA}`;
}

type Questao = {
  id: string;
  conteudo: string;
  origem: string;
  errou_na_prova: boolean;
  enunciado: string;
  opcoes: string[];
  correta: number;
  dica: string;
  explicacao: string[];
  tentativas: number;
  acertou: boolean;
  explicada: boolean;
};

type Prova = {
  id: string;
  questoes: Questao[];
  vencida_em: string | null;
};

/// Questão como vai para o app: sem a resposta, a dica e a explicação.
function questaoParaApp(q: Questao) {
  return {
    id: q.id,
    conteudo: q.conteudo,
    origem: q.origem,
    errou_na_prova: q.errou_na_prova,
    enunciado: q.enunciado,
    opcoes: q.opcoes,
    tentativas: q.tentativas,
    acertou: q.acertou,
    explicada: q.explicada,
  };
}

/// Estrelas pelos acertos de primeira: medem o que a criança sabe, não a
/// rapidez.
function estrelas(questoes: Questao[]): number {
  const dePrimeira = questoes.filter((q) => q.acertou && q.tentativas === 1)
    .length;
  const taxa = dePrimeira / questoes.length;
  if (taxa >= 0.9) return 3;
  if (taxa >= 0.6) return 2;
  return 1;
}

/// Junta o progresso da questão com o do bônus da prova vencida.
function somarProgresso(
  a: Progresso | null,
  b: Progresso | null,
): Progresso | null {
  if (!a || !b) return a ?? b;
  return {
    ...b,
    xp_ganho: Number(a.xp_ganho ?? 0) + Number(b.xp_ganho ?? 0),
    subiu_nivel: Boolean(a.subiu_nivel) || Boolean(b.subiu_nivel),
    missao_concluida: a.missao_concluida ?? b.missao_concluida,
    medalhas_novas: [
      ...((a.medalhas_novas as unknown[]) ?? []),
      ...((b.medalhas_novas as unknown[]) ?? []),
    ],
  };
}

async function enviar(ctx: Contexto): Promise<Response> {
  // Quem manda as provas é o responsável; a criança só treina.
  const perfil = await carregarPerfil(ctx, {
    somenteResponsavel: true,
    exigirAutorizacaoIA:
      "Ligue a autorização de IA na Área dos responsáveis para enviar provas.",
  });

  const material = ctx.corpo.material === "tarefa" ? "tarefa" : "prova";
  const observacao = typeof ctx.corpo.observacao === "string"
    ? ctx.corpo.observacao.trim().slice(0, 300)
    : "";
  const imagens = Array.isArray(ctx.corpo.imagens) ? ctx.corpo.imagens : [];
  const pdf = lerPdf(ctx.corpo.pdf);
  if (imagens.length === 0 && !pdf) {
    throw new ErroDaLiga(400, "Mande pelo menos uma foto ou um PDF.");
  }
  if (imagens.length > MAXIMO_DE_FOTOS) {
    throw new ErroDaLiga(400, `Mande no máximo ${MAXIMO_DE_FOTOS} fotos.`);
  }
  let total = 0;
  for (const imagem of imagens) {
    if (
      typeof imagem?.base64 !== "string" ||
      !TIPOS_DE_IMAGEM.includes(imagem?.tipo)
    ) {
      throw new ErroDaLiga(400, "Envie as fotos em JPG, PNG ou WEBP.");
    }
    if (imagem.base64.length > TAMANHO_MAXIMO_BASE64) {
      throw new ErroDaLiga(413, "Uma das fotos ficou grande demais.");
    }
    total += imagem.base64.length;
  }
  total += pdf?.base64.length ?? 0;
  if (total > TAMANHO_MAXIMO_TOTAL) {
    throw new ErroDaLiga(413, "Os arquivos ficaram grandes demais. Mande menos fotos.");
  }

  await conferirLimiteDiario(
    ctx,
    perfil,
    "revanche_envio",
    LIMITE_DIARIO,
    "Hoje já foram enviadas muitas provas. Tente amanhã.",
  );

  const pedido = observacao
    ? `Recado do responsável: ${observacao}`
    : `Monte a Revanche desta ${material}.`;
  const { dados, modelo } = await perguntarIA({
    instrucoes: instrucoes(perfil.ano_escolar, material),
    entrada: [
      {
        role: "user",
        content: [
          ...imagens.map((imagem: { base64: string; tipo: string }) => ({
            type: "input_image" as const,
            image_url: `data:${imagem.tipo};base64,${imagem.base64}`,
            detail: "high" as const,
          })),
          ...(pdf
            ? [{
              type: "input_file" as const,
              filename: "prova.pdf",
              file_data: `data:application/pdf;base64,${pdf.base64}`,
            }]
            : []),
          { type: "input_text" as const, text: pedido },
        ],
      },
    ],
    nomeDoEsquema: "revanche_da_prova",
    esquema: ESQUEMA_DA_PROVA,
  });

  const questoes: Questao[] = (dados.questoes as Omit<
    Questao,
    "id" | "tentativas" | "acertou" | "explicada"
  >[])
    .filter((q) =>
      q.opcoes.length >= 2 &&
      q.opcoes.length <= 5 &&
      Number.isInteger(q.correta) &&
      q.correta >= 0 &&
      q.correta < q.opcoes.length
    )
    .slice(0, 12)
    // As que a criança errou na prova vêm primeiro: é a revanche.
    .sort((a, b) => Number(b.errou_na_prova) - Number(a.errou_na_prova))
    .map((q) => ({
      ...q,
      id: crypto.randomUUID(),
      tentativas: 0,
      acertou: false,
      explicada: false,
    }));

  if (!dados.legivel || questoes.length < 3) {
    const motivo = String(dados.resumo_responsavel ?? "").trim();
    throw new ErroDaLiga(
      422,
      `Não consegui montar o treino com esses arquivos. ${
        motivo || "Tente fotos mais nítidas, com a folha inteira e boa luz."
      }`,
    );
  }

  const materia = String(dados.materia);
  const { data: linha, error } = await ctx.servico
    .from("provas_treino")
    .insert({
      perfil_crianca_id: perfil.id,
      tipo: material,
      titulo: String(dados.titulo).slice(0, 120),
      materia,
      personagem: PERSONAGEM_DA_MATERIA[materia] ?? "zuri",
      conteudos: (dados.conteudos as string[]).slice(0, 8),
      resumo_responsavel: String(dados.resumo_responsavel ?? ""),
      observacao: observacao || null,
      questoes,
      total_questoes: questoes.length,
      modelo_usado: modelo,
    })
    .select(
      "id, tipo, titulo, materia, personagem, conteudos, resumo_responsavel, total_questoes, questoes_acertadas, estrelas, vencida_em, created_at",
    )
    .single();
  if (error) throw error;

  return resposta(200, linha);
}

/// Confere o PDF (opcional): tamanho, assinatura e número de páginas.
function lerPdf(valor: unknown): { base64: string } | null {
  if (valor === undefined || valor === null) return null;
  const base64 = (valor as { base64?: unknown })?.base64;
  if (typeof base64 !== "string" || base64.length === 0) {
    throw new ErroDaLiga(400, "Não consegui ler o PDF.");
  }
  if (base64.length > TAMANHO_MAXIMO_PDF) {
    throw new ErroDaLiga(413, "O PDF ficou grande demais (até 6 MB).");
  }
  let conteudo: string;
  try {
    conteudo = atob(base64);
  } catch {
    throw new ErroDaLiga(400, "Não consegui ler o PDF.");
  }
  if (!conteudo.startsWith("%PDF-")) {
    throw new ErroDaLiga(400, "Esse arquivo não é um PDF.");
  }
  if (contarPaginas(conteudo) > MAXIMO_DE_PAGINAS_PDF) {
    throw new ErroDaLiga(
      413,
      `Mande um PDF de até ${MAXIMO_DE_PAGINAS_PDF} páginas, só com a prova.`,
    );
  }
  return { base64 };
}

/// Conta as páginas pelo maior "/Count" da árvore de páginas ou, se não
/// achar, pelos objetos "/Type /Page". Em PDFs compactados pode não achar
/// nenhum: aí vale só o limite de tamanho.
function contarPaginas(conteudo: string): number {
  let maior = 0;
  for (const m of conteudo.matchAll(/\/Type\s*\/Pages\b[^>]*?\/Count\s+(\d+)/g)) {
    maior = Math.max(maior, Number(m[1]));
  }
  for (const m of conteudo.matchAll(/\/Count\s+(\d+)[^>]*?\/Type\s*\/Pages\b/g)) {
    maior = Math.max(maior, Number(m[1]));
  }
  if (maior > 0) return maior;
  return [...conteudo.matchAll(/\/Type\s*\/Page(?![a-zA-Z])/g)].length;
}

async function carregarProva(ctx: Contexto) {
  const perfil = await carregarPerfil(ctx);
  const provaId = ctx.corpo.prova_id;
  if (typeof provaId !== "string") {
    throw new ErroDaLiga(400, "Faltou a prova.");
  }
  const { data: linha } = await ctx.servico
    .from("provas_treino")
    .select("id, questoes, vencida_em")
    .eq("id", provaId)
    .eq("perfil_crianca_id", perfil.id)
    .maybeSingle();
  if (!linha) throw new ErroDaLiga(404, "Essa prova não existe mais.");
  return { perfil, prova: linha as Prova };
}

async function abrir(ctx: Contexto): Promise<Response> {
  const { prova } = await carregarProva(ctx);
  return resposta(200, {
    prova_id: prova.id,
    questoes: prova.questoes.map(questaoParaApp),
    vencida: prova.vencida_em !== null,
  });
}

async function responder(ctx: Contexto): Promise<Response> {
  const { perfil, prova } = await carregarProva(ctx);
  const escolha = ctx.corpo.escolha;
  if (!Number.isInteger(escolha)) {
    throw new ErroDaLiga(400, "Escolha uma resposta.");
  }
  const questao = prova.questoes.find((q) => q.id === ctx.corpo.questao_id);
  if (!questao) throw new ErroDaLiga(404, "Questão não encontrada.");

  const jaAcertou = questao.acertou;
  const acertou = escolha === questao.correta;
  let xp = 0;
  if (!jaAcertou) {
    if (acertou && !questao.explicada) {
      xp = questao.tentativas === 0 ? XP_DE_PRIMEIRA : XP_DEPOIS_DE_ERRAR;
    }
    questao.tentativas += 1;
    questao.acertou = acertou;
  }
  // No segundo erro o herói para e explica; a questão volta no fim da fila.
  const explicarAgora = !jaAcertou && !acertou && !questao.explicada &&
    questao.tentativas >= ERROS_ATE_EXPLICAR;
  if (explicarAgora) questao.explicada = true;

  const acertadas = prova.questoes.filter((q) => q.acertou).length;
  const venceuAgora = acertadas === prova.questoes.length &&
    prova.vencida_em === null;
  const nota = venceuAgora ? estrelas(prova.questoes) : 0;

  await ctx.servico
    .from("provas_treino")
    .update({
      questoes: prova.questoes,
      questoes_acertadas: acertadas,
      ...(venceuAgora
        ? { estrelas: nota, vencida_em: new Date().toISOString() }
        : {}),
    })
    .eq("id", prova.id);

  const progressoDaQuestao = await concederXp(
    ctx,
    perfil,
    xp,
    "revanche",
    questao.id,
  );
  const progressoDaProva = venceuAgora
    ? await concederXp(
      ctx,
      perfil,
      XP_PROVA_VENCIDA,
      "revanche_vencida",
      prova.id,
    )
    : null;

  const mostrarResposta = acertou || explicarAgora;
  return resposta(200, {
    acertou,
    dica: acertou || explicarAgora ? "" : questao.dica,
    explicacao: mostrarResposta ? questao.explicacao : [],
    correta: mostrarResposta ? questao.correta : null,
    explicada: explicarAgora,
    acertadas,
    vencida: venceuAgora || prova.vencida_em !== null,
    estrelas: nota,
    xp: (progressoDaQuestao ? xp : 0) +
      (progressoDaProva ? XP_PROVA_VENCIDA : 0),
    progresso: somarProgresso(progressoDaQuestao, progressoDaProva),
  });
}

servir("a Revanche da prova", (ctx) => {
  switch (ctx.corpo.acao) {
    case "enviar":
      return enviar(ctx);
    case "abrir":
      return abrir(ctx);
    case "responder":
      return responder(ctx);
    default:
      throw new ErroDaLiga(400, "Ação desconhecida.");
  }
});
