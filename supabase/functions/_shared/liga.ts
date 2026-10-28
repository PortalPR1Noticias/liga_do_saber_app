// Liga do Saber - código comum das Edge Functions dos módulos
// (oficina-texto, detetive-leitura, desafio-matematica, expedicao-teo,
// arquivo-mila, atelie-zuri, minijogo, revanche-prova).
//
// Cada função confere o login, acha o perfil da criança, aplica um limite
// diário, chama a OpenAI com saída estruturada e dá XP pela função SQL
// public.conceder_xp (migration 0003).

import OpenAI from "npm:openai@7.43.0";
import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2.118.0";

/// Troque pelo secret OPENAI_MODEL (por exemplo `gpt-6-luna`, mais barato).
export const MODELO = Deno.env.get("OPENAI_MODEL") ?? "gpt-6-sol";

export type Perfil = { id: string; ano_escolar: number };

/// Progresso devolvido por public.conceder_xp e repassado ao app.
export type Progresso = Record<string, unknown>;

export function resposta(status: number, corpo: unknown): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

export function erro(status: number, mensagem: string): Response {
  return resposta(status, { erro: mensagem });
}

/// Erro com resposta pronta: as funções lançam e o `servir` devolve.
export class ErroDaLiga extends Error {
  constructor(readonly status: number, mensagem: string) {
    super(mensagem);
  }
}

export type Contexto = {
  servico: SupabaseClient;
  usuarioId: string;
  corpo: Record<string, unknown>;
};

/// Recebe só POST com JSON, confere o login e trata os erros.
export function servir(
  nomeDoModulo: string,
  tratar: (ctx: Contexto) => Promise<Response>,
): void {
  Deno.serve(async (req) => {
    if (req.method !== "POST") return erro(405, "Use POST.");

    const token = req.headers.get("Authorization")?.replace(
      /^Bearer\s+/i,
      "",
    );
    if (!token) return erro(401, `Entre na sua conta para usar ${nomeDoModulo}.`);

    // A service role grava as tabelas de progresso (o app só lê). Por isso a
    // posse do perfil é conferida à mão em carregarPerfil.
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

    let corpo: Record<string, unknown>;
    try {
      corpo = await req.json();
    } catch {
      return erro(400, "Pedido inválido.");
    }
    if (typeof corpo !== "object" || corpo === null) {
      return erro(400, "Pedido inválido.");
    }

    try {
      return await tratar({ servico, usuarioId: usuario.user.id, corpo });
    } catch (falha) {
      if (falha instanceof ErroDaLiga) return erro(falha.status, falha.message);
      console.error(`Falha em ${nomeDoModulo}`, falha);
      return erro(500, "Algo deu errado. Tente de novo.");
    }
  });
}

/// Perfil da criança, só se quem chamou for o responsável dela ou a própria
/// criança, com o login dela (migration 0014). Com `somenteResponsavel`, a
/// ação é do adulto (como mandar fotos de provas) e a criança não pode.
/// Com `exigirAutorizacaoIA`, o módulo manda dados da criança (como o texto
/// que ela escreveu) para a OpenAI e precisa da autorização do responsável
/// (`responsaveis.autoriza_ia`, migration 0004, LGPD art. 14).
export async function carregarPerfil(
  ctx: Contexto,
  opcoes: { exigirAutorizacaoIA?: string; somenteResponsavel?: boolean } = {},
): Promise<Perfil> {
  const perfilId = ctx.corpo.perfil_id;
  if (typeof perfilId !== "string") {
    throw new ErroDaLiga(400, "Faltou o perfil da criança.");
  }
  const perfil = await buscarPerfilPermitido(ctx.servico, perfilId, ctx.usuarioId);
  if (!perfil) throw new ErroDaLiga(403, "Perfil da criança não encontrado.");
  if (opcoes.somenteResponsavel && !perfil.doResponsavel) {
    throw new ErroDaLiga(403, "Peça para um adulto fazer isso na conta dele.");
  }
  if (opcoes.exigirAutorizacaoIA && !perfil.autorizaIA) {
    throw new ErroDaLiga(403, opcoes.exigirAutorizacaoIA);
  }
  return { id: perfil.id, ano_escolar: perfil.ano_escolar };
}

/// Busca o perfil e diz se quem chamou é o responsável (`doResponsavel`) ou a
/// própria criança. Devolve nulo para qualquer outra pessoa.
export async function buscarPerfilPermitido(
  servico: SupabaseClient,
  perfilId: string,
  usuarioId: string,
): Promise<
  | (Perfil & { doResponsavel: boolean; autorizaIA: boolean })
  | null
> {
  const { data: perfil } = await servico
    .from("perfis_criancas")
    .select("id, ano_escolar, auth_user_id, responsaveis!inner(auth_user_id, autoriza_ia)")
    .eq("id", perfilId)
    .maybeSingle();
  if (!perfil) return null;
  const responsavel = perfil.responsaveis as unknown as {
    auth_user_id?: string;
    autoriza_ia?: boolean;
  };
  const doResponsavel = responsavel?.auth_user_id === usuarioId;
  if (!doResponsavel && perfil.auth_user_id !== usuarioId) return null;
  return {
    id: perfil.id,
    ano_escolar: perfil.ano_escolar,
    doResponsavel,
    autorizaIA: responsavel?.autoriza_ia === true,
  };
}

/// Limita quantas vezes por dia a criança usa a IA num módulo (protege o
/// custo). Conta os registros de `correcoes_ia` daquele tipo.
export async function conferirLimiteDiario(
  ctx: Contexto,
  perfil: Perfil,
  tipo: string,
  limite: number,
  mensagem: string,
): Promise<void> {
  const desde = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { count } = await ctx.servico
    .from("correcoes_ia")
    .select("id", { count: "exact", head: true })
    .eq("perfil_crianca_id", perfil.id)
    .eq("tipo", tipo)
    .gte("created_at", desde);
  if ((count ?? 0) >= limite) throw new ErroDaLiga(429, mensagem);
}

/// Pede à OpenAI uma resposta no formato do `esquema` e devolve o objeto.
/// A `entrada` pode ser só texto ou uma mensagem com imagens.
export async function perguntarIA(opcoes: {
  instrucoes: string;
  entrada: string | OpenAI.Responses.ResponseInput;
  nomeDoEsquema: string;
  esquema: Record<string, unknown>;
}): Promise<{ dados: Record<string, unknown>; modelo: string }> {
  const chave = Deno.env.get("OPENAI_API_KEY");
  if (!chave) {
    console.error("Secret OPENAI_API_KEY não configurado.");
    throw new ErroDaLiga(503, "A Liga ainda está sendo preparada. Tente mais tarde.");
  }
  const openai = new OpenAI({ apiKey: chave });
  let saida: OpenAI.Responses.Response;
  try {
    saida = await openai.responses.create({
      model: MODELO,
      instructions: opcoes.instrucoes,
      input: opcoes.entrada,
      text: {
        format: {
          type: "json_schema",
          name: opcoes.nomeDoEsquema,
          schema: opcoes.esquema,
          strict: true,
        },
      },
      // Não guarda a conversa na OpenAI além do necessário.
      store: false,
    });
  } catch (falha) {
    if (falha instanceof OpenAI.RateLimitError) {
      throw new ErroDaLiga(503, "A IA está ocupada agora. Tente de novo em instantes.");
    }
    if (falha instanceof OpenAI.APIError) {
      console.error("Erro da API da OpenAI", falha.status, falha.message);
    } else {
      console.error("Falha ao falar com a IA", falha);
    }
    throw new ErroDaLiga(502, "Não consegui falar com a IA agora. Tente de novo.");
  }

  const recusou = saida.output.some(
    (item) =>
      item.type === "message" &&
      item.content.some((parte) => parte.type === "refusal"),
  );
  if (recusou) {
    throw new ErroDaLiga(422, "Não consigo ajudar com isso. Peça ajuda a um adulto, combinado?");
  }
  try {
    return { dados: JSON.parse(saida.output_text), modelo: saida.model };
  } catch {
    console.error("Resposta fora do formato", saida.status);
    throw new ErroDaLiga(502, "Não consegui falar com a IA agora. Tente de novo.");
  }
}

/// Dá XP pela função SQL. Se der errado, a criança não perde a atividade:
/// só fica sem o XP daquela vez (e o erro vai para o log).
export async function concederXp(
  ctx: Contexto,
  perfil: Perfil,
  xp: number,
  origem: string,
  referencia: string,
): Promise<Progresso | null> {
  if (xp <= 0) return null;
  const { data, error } = await ctx.servico.rpc("conceder_xp", {
    p_perfil: perfil.id,
    p_xp: xp,
    p_origem: origem,
    p_referencia: referencia,
  });
  if (error) {
    console.error("Falha ao conceder XP", error.message);
    return null;
  }
  return data as Progresso;
}

/// Como cada personagem fala. Usado nas instruções da IA.
export const VOZES = {
  nico:
    "Nico, O Estrategista: objetivo, curioso e encorajador; adora estratégias e mostra o raciocínio.",
  luma:
    "Luma, A Guardiã das Palavras: acolhedora, criativa e precisa; elogia o esforço e aponta melhorias com carinho.",
  teo:
    "Teo, O Explorador: aventureiro e curioso; transforma o conteúdo em investigação, observa pistas e comemora cada descoberta.",
  zuri:
    "Zuri, O Criador: enérgico, inventivo e divertido; adora transformar ideias em projetos, organiza tudo em mapas mentais e celebra a criatividade.",
  mila:
    "Mila, A Investigadora: analítica, atenta e confiante; lê documentos e imagens como pistas, pergunta quem, quando e por quê, e ensina a desconfiar do que não tem prova.",
};

export const REGRAS_DE_SEGURANCA = `Regras de segurança:
- Quem lê é uma criança. Nada de violência, medo, romance, marcas, política ou outros temas impróprios.
- Nunca peça nem repita dados pessoais (nome completo, escola, endereço, telefone).
- Escreva em português do Brasil, com frases curtas e palavras simples.`;
