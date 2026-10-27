// Liga do Saber - Edge Function "explicar-foto".
//
// Recebe a foto de uma atividade escolar, pede ao Claude uma explicação passo a
// passo no tom do personagem da matéria e grava o resultado em `correcoes_ia`.
// A chave da Anthropic fica só aqui no servidor (secret ANTHROPIC_API_KEY).
// A foto não é guardada: ela passa pela função e segue apenas para a IA.
//
// Deploy: veja supabase/functions/README.md.

import Anthropic from "npm:@anthropic-ai/sdk@1.3.0";
import { createClient } from "npm:@supabase/supabase-js@2.118.0";

const MODELO = Deno.env.get("CLAUDE_MODEL") ?? "claude-opus-5-5";

/// Quantas fotos cada criança pode enviar por dia (protege o custo da IA).
const LIMITE_DIARIO = Number(Deno.env.get("LIMITE_FOTOS_POR_DIA") ?? "30");

/// Base64 de uma imagem de ~4,5 MB. O app já reduz a foto antes de enviar.
const TAMANHO_MAXIMO_BASE64 = 6_000_000;

const TIPOS_DE_IMAGEM = ["image/jpeg", "image/png", "image/webp"] as const;
type TipoDeImagem = (typeof TIPOS_DE_IMAGEM)[number];

const XP_POR_FOTO = 20;

/// Cada matéria é guiada por um personagem oficial da Liga.
const PERSONAGEM_DA_MATERIA: Record<string, string> = {
  matematica: "nico",
  portugues: "luma",
  ciencias: "teo",
  geografia: "teo",
  historia: "mila",
  criatividade: "zuri",
  outra: "zuri",
};

const ESQUEMA_DA_RESPOSTA = {
  type: "object",
  additionalProperties: false,
  required: [
    "legivel",
    "materia",
    "titulo",
    "enunciado",
    "passos",
    "resposta_final",
    "dica",
    "mensagem_final",
  ],
  properties: {
    legivel: {
      type: "boolean",
      description:
        "false se a foto não mostra uma atividade escolar ou não dá para ler.",
    },
    materia: {
      type: "string",
      enum: Object.keys(PERSONAGEM_DA_MATERIA),
    },
    titulo: { type: "string" },
    enunciado: { type: "string" },
    passos: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["titulo", "explicacao"],
        properties: {
          titulo: { type: "string" },
          explicacao: { type: "string" },
        },
      },
    },
    resposta_final: { type: "string" },
    dica: { type: "string" },
    mensagem_final: { type: "string" },
  },
};

function instrucoes(anoEscolar: number): string {
  return `Você é a equipe de tutores do app Liga do Saber, que ajuda crianças brasileiras do ensino fundamental com a lição de casa. Quem lê é uma criança do ${anoEscolar}º ano. Escreva em português do Brasil, com frases curtas, palavras simples e tom caloroso.

A criança mandou a foto de uma atividade. Seu trabalho:
1. Descobrir a matéria e o que a atividade pede. Se houver várias questões, explique a primeira que ainda parece sem resposta (ou a primeira de todas) e diga no enunciado qual é.
2. Explicar como resolver em 2 a 6 passos curtos, ensinando o raciocínio. Se a criança já escreveu uma resposta, diga com carinho se está certa e, se não estiver, mostre onde revisar.
3. Colocar a resposta em "resposta_final" (o app só mostra quando a criança pedir).
4. Dar uma dica para atividades parecidas e terminar com uma mensagem de incentivo.

Fale com a voz do personagem da matéria, em primeira pessoa:
- matematica: Nico, O Estrategista. Objetivo, curioso e encorajador; adora estratégias.
- portugues: Luma, A Guardiã das Palavras. Acolhedora, criativa e precisa.
- ciencias e geografia: Teo, O Explorador. Aventureiro e curioso.
- historia: Mila, A Investigadora. Analítica, atenta e confiante; olha pistas e contexto.
- criatividade ou outra: Zuri, O Criador. Enérgico, inventivo e divertido.

Regras:
- Se a foto não mostrar uma atividade escolar, ou estiver ilegível, use legivel=false, passos vazio e resposta_final vazia, e peça com gentileza uma foto mais nítida da lição em mensagem_final.
- Não repita nomes de pessoas, escolas, endereços ou outros dados pessoais que apareçam na foto.
- Nunca peça dados pessoais à criança.
- Se a atividade tiver algo impróprio para crianças, não explique esse conteúdo: use legivel=false e sugira pedir ajuda a um adulto.`;
}

function resposta(status: number, corpo: unknown): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

function erro(status: number, mensagem: string): Response {
  return resposta(status, { erro: mensagem });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return erro(405, "Use POST.");

  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return erro(401, "Entre na sua conta para usar a Foto + IA.");

  const chaveAnthropic = Deno.env.get("ANTHROPIC_API_KEY");
  if (!chaveAnthropic) {
    console.error("Secret ANTHROPIC_API_KEY não configurado.");
    return erro(503, "A Foto + IA ainda está sendo preparada. Tente mais tarde.");
  }

  // A service role lê o perfil e grava em correcoes_ia (o app só tem leitura
  // nessa tabela). Por isso a posse do perfil é conferida aqui, à mão.
  const servico = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
  const { data: usuario, error: erroDeLogin } = await servico.auth.getUser(
    token,
  );
  if (erroDeLogin || !usuario.user) {
    return erro(401, "Sua sessão expirou. Entre de novo.");
  }

  let corpo: { perfil_id?: unknown; imagem_base64?: unknown; tipo?: unknown };
  try {
    corpo = await req.json();
  } catch {
    return erro(400, "Pedido inválido.");
  }
  const { perfil_id: perfilId, imagem_base64: imagem, tipo } = corpo;
  if (typeof perfilId !== "string" || typeof imagem !== "string") {
    return erro(400, "Faltou a foto ou o perfil da criança.");
  }
  if (!TIPOS_DE_IMAGEM.includes(tipo as TipoDeImagem)) {
    return erro(400, "Envie a foto em JPG, PNG ou WEBP.");
  }
  if (imagem.length > TAMANHO_MAXIMO_BASE64) {
    return erro(413, "A foto ficou grande demais. Tente de novo.");
  }

  const { data: perfil } = await servico
    .from("perfis_criancas")
    .select("id, ano_escolar, responsaveis!inner(auth_user_id)")
    .eq("id", perfilId)
    .eq("responsaveis.auth_user_id", usuario.user.id)
    .maybeSingle();
  if (!perfil) return erro(403, "Perfil da criança não encontrado.");

  const desde = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { count } = await servico
    .from("correcoes_ia")
    .select("id", { count: "exact", head: true })
    .eq("perfil_crianca_id", perfil.id)
    .eq("tipo", "foto")
    .gte("created_at", desde);
  if ((count ?? 0) >= LIMITE_DIARIO) {
    return erro(
      429,
      "Você já mandou muitas fotos hoje. Amanhã tem mais missão!",
    );
  }

  const anthropic = new Anthropic({ apiKey: chaveAnthropic });
  let mensagem: Anthropic.Beta.Messages.BetaMessage;
  try {
    mensagem = await anthropic.beta.messages.create({
      model: MODELO,
      max_tokens: 16000,
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      output_config: {
        effort: "medium",
        format: { type: "json_schema", schema: ESQUEMA_DA_RESPOSTA },
      },
      system: instrucoes(perfil.ano_escolar),
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: tipo as TipoDeImagem,
                data: imagem,
              },
            },
            { type: "text", text: "Me ajuda com essa atividade?" },
          ],
        },
      ],
    });
  } catch (falha) {
    if (falha instanceof Anthropic.RateLimitError) {
      return erro(503, "A IA está ocupada agora. Tente de novo em instantes.");
    }
    if (falha instanceof Anthropic.APIError) {
      console.error("Erro da API da Anthropic", falha.status, falha.message);
    } else {
      console.error("Falha ao falar com a IA", falha);
    }
    return erro(502, "Não consegui analisar a foto agora. Tente de novo.");
  }

  if (mensagem.stop_reason === "refusal") {
    return erro(
      422,
      "Não consigo ajudar com essa foto. Peça ajuda a um adulto, combinado?",
    );
  }
  const texto = mensagem.content.find((bloco) => bloco.type === "text");
  let explicacao: Record<string, unknown>;
  try {
    explicacao = JSON.parse(texto?.type === "text" ? texto.text : "");
  } catch {
    console.error("Resposta fora do formato", mensagem.stop_reason);
    return erro(502, "Não consegui analisar a foto agora. Tente de novo.");
  }

  const materia = String(explicacao.materia);
  const resultado = {
    ...explicacao,
    personagem: PERSONAGEM_DA_MATERIA[materia] ?? "zuri",
    xp: explicacao.legivel ? XP_POR_FOTO : 0,
  };

  const { error: erroAoSalvar } = await servico.from("correcoes_ia").insert({
    perfil_crianca_id: perfil.id,
    tipo: "foto",
    entrada_resumo: String(explicacao.enunciado ?? "").slice(0, 500),
    resposta_json: resultado,
    xp_sugerido: resultado.xp,
    modelo_usado: mensagem.model,
  });
  if (erroAoSalvar) {
    // A criança recebe a explicação mesmo assim; só fica sem histórico.
    console.error("Falha ao gravar correcoes_ia", erroAoSalvar.message);
  }

  return resposta(200, resultado);
});
