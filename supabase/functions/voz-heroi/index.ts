// Liga do Saber - Edge Function "voz-heroi" (heróis falando).
//
// Recebe o texto de uma explicação que o app já mostra na tela (Foto + IA,
// chefões, Revanche da prova e os módulos) e devolve o áudio em MP3 com a
// voz do herói, gerado pela OpenAI (text-to-speech). Cada herói tem uma voz
// e um jeito de falar.
//
// Só vai para a OpenAI o texto da explicação, que a própria IA ou o app
// escreveram: nada de foto, nome ou dado da criança. O áudio não é guardado.
// Cada áudio reserva uma vaga em public.reservar_uso_voz (migration 0021),
// separada dos limites da IA de texto para a voz não gastar a cota deles.
//
// Deploy: veja supabase/functions/README.md.

import OpenAI from "npm:openai@7.43.0";
import {
  carregarPerfil,
  ErroDaLiga,
  resposta,
  servir,
  type Contexto,
} from "../_shared/liga.ts";

/// Troque pelo secret OPENAI_TTS_MODEL.
const MODELO_DE_VOZ = Deno.env.get("OPENAI_TTS_MODEL") ?? "gpt-4o-mini-tts";

/// Áudios por criança, por família e no app todo, a cada 24 horas.
const LIMITE_CRIANCA = Number(Deno.env.get("LIMITE_VOZ_POR_DIA") ?? "60");
const LIMITE_FAMILIA = Number(
  Deno.env.get("LIMITE_VOZ_FAMILIA_POR_DIA") ?? "200",
);
const LIMITE_GLOBAL = Number(
  Deno.env.get("LIMITE_VOZ_GLOBAL_POR_DIA") ?? "5000",
);

/// Uma explicação de 4 passos cabe folgada; mais que isso fica caro e longo.
const MAXIMO_DE_CARACTERES = 1200;

/// Voz da OpenAI e jeito de falar de cada herói.
const VOZES_DOS_HEROIS: Record<string, { voz: string; jeito: string }> = {
  nico: {
    voz: "echo",
    jeito:
      "Nico, O Estrategista: menino animado e confiante, fala com clareza e calma, como quem mostra um plano passo a passo, e encoraja no fim.",
  },
  luma: {
    voz: "coral",
    jeito:
      "Luma, A Guardiã das Palavras: menina acolhedora e carinhosa, fala com doçura e boa dicção, valorizando cada palavra.",
  },
  teo: {
    voz: "verse",
    jeito:
      "Teo, O Explorador: menino aventureiro e curioso, fala com empolgação de quem acabou de descobrir algo, sem correr.",
  },
  mila: {
    voz: "sage",
    jeito:
      "Mila, A Investigadora: menina atenta e confiante, fala como uma detetive que junta pistas, com pausas curtas de suspense.",
  },
  zuri: {
    voz: "fable",
    jeito:
      "Zuri, O Criador: menino enérgico, inventivo e divertido, fala com alegria e ritmo, celebrando as ideias.",
  },
};

function instrucoesDeVoz(jeito: string): string {
  return `Você dá voz a um herói de um jogo educativo para crianças do ensino fundamental.
${jeito}
Fale em português do Brasil, com sotaque brasileiro natural, devagar o bastante para uma criança acompanhar o texto na tela. Leia números e contas por extenso de um jeito fácil de entender (por exemplo, "3/4" como "três quartos"). Tom gentil e positivo, nunca assustador.`;
}

async function reservarVaga(ctx: Contexto, perfilId: string): Promise<void> {
  const { data, error } = await ctx.servico.rpc("reservar_uso_voz", {
    p_perfil: perfilId,
    p_limite_perfil: LIMITE_CRIANCA,
    p_limite_familia: LIMITE_FAMILIA,
    p_limite_global: LIMITE_GLOBAL,
  });
  if (error) {
    // Sem a migration 0021 a voz fica desligada; o texto continua na tela.
    console.error("Falha ao reservar a voz", error.message);
    throw new ErroDaLiga(503, "A voz dos heróis ainda está sendo preparada.");
  }
  if (data === "perfil" || data === "familia") {
    throw new ErroDaLiga(
      429,
      "Os heróis já falaram muito hoje. Leia a explicação na tela!",
    );
  }
  if (data === "global") {
    throw new ErroDaLiga(503, "A Liga está muito movimentada. Leia na tela!");
  }
}

function paraBase64(bytes: Uint8Array): string {
  let binario = "";
  const bloco = 0x8000;
  for (let i = 0; i < bytes.length; i += bloco) {
    binario += String.fromCharCode(...bytes.subarray(i, i + bloco));
  }
  return btoa(binario);
}

servir("a voz dos heróis", async (ctx) => {
  const perfil = await carregarPerfil(ctx);

  const heroi = VOZES_DOS_HEROIS[String(ctx.corpo.personagem)];
  if (!heroi) throw new ErroDaLiga(400, "Herói desconhecido.");
  const texto = typeof ctx.corpo.texto === "string"
    ? ctx.corpo.texto.replace(/\s+/g, " ").trim()
    : "";
  if (!texto) throw new ErroDaLiga(400, "Faltou o texto.");
  if (texto.length > MAXIMO_DE_CARACTERES) {
    throw new ErroDaLiga(413, "Explicação longa demais para ouvir.");
  }

  const chave = Deno.env.get("OPENAI_API_KEY");
  if (!chave) {
    console.error("Secret OPENAI_API_KEY não configurado.");
    throw new ErroDaLiga(503, "A voz dos heróis ainda está sendo preparada.");
  }

  await reservarVaga(ctx, perfil.id);

  const openai = new OpenAI({ apiKey: chave });
  let audio: Uint8Array;
  try {
    const saida = await openai.audio.speech.create({
      model: MODELO_DE_VOZ,
      voice: heroi.voz,
      input: texto,
      instructions: instrucoesDeVoz(heroi.jeito),
      response_format: "mp3",
    });
    audio = new Uint8Array(await saida.arrayBuffer());
  } catch (falha) {
    if (falha instanceof OpenAI.RateLimitError) {
      throw new ErroDaLiga(503, "A voz está ocupada agora. Tente de novo.");
    }
    if (falha instanceof OpenAI.APIError) {
      console.error("Erro da API de voz da OpenAI", falha.status, falha.message);
    } else {
      console.error("Falha ao gerar a voz", falha);
    }
    throw new ErroDaLiga(502, "Não consegui gerar a voz agora. Tente de novo.");
  }

  return resposta(200, { audio: paraBase64(audio), tipo: "audio/mpeg" });
});
