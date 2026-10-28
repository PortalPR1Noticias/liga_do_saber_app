// Liga do Saber - Edge Function "contas-liga".
//
// O responsável cria (ou troca a senha d)o login da criança: um usuário e
// uma senha que a criança usa na tela "Sou criança". Por baixo, é um
// usuário do Supabase Auth com e-mail interno `<usuario>@crianca.gpmkt.art.br`
// (nunca recebe e-mail) e `app_metadata.papel = "crianca"`. Precisa da
// migration 0014. Só a service role cria usuários, por isso fica aqui.
//
// Ações (POST com JSON e o token do responsável):
//   { acao: "criar_login_crianca", perfil_id, usuario, senha }
//   { acao: "trocar_senha_crianca", perfil_id, senha }
//
// Deploy: veja supabase/functions/README.md.

import {
  buscarPerfilPermitido,
  type Contexto,
  ErroDaLiga,
  resposta,
  servir,
} from "../_shared/liga.ts";

export const DOMINIO_CRIANCA = "crianca.gpmkt.art.br";
const USUARIO_VALIDO = /^[a-z0-9][a-z0-9._]{2,23}$/;

servir("as contas da Liga", async (ctx) => {
  switch (ctx.corpo.acao) {
    case "criar_login_crianca":
      return await criarLogin(ctx);
    case "trocar_senha_crianca":
      return await trocarSenha(ctx);
    default:
      throw new ErroDaLiga(400, "Ação desconhecida.");
  }
});

/// Só o responsável da criança mexe no login dela.
async function perfilDoResponsavel(ctx: Contexto) {
  const perfilId = ctx.corpo.perfil_id;
  if (typeof perfilId !== "string") {
    throw new ErroDaLiga(400, "Faltou o perfil da criança.");
  }
  const perfil = await buscarPerfilPermitido(
    ctx.servico,
    perfilId,
    ctx.usuarioId,
  );
  if (!perfil?.doResponsavel) {
    throw new ErroDaLiga(403, "Só o responsável pode criar o login da criança.");
  }
  const { data } = await ctx.servico
    .from("perfis_criancas")
    .select("id, auth_user_id, usuario")
    .eq("id", perfil.id)
    .single();
  return data as { id: string; auth_user_id: string | null; usuario: string | null };
}

function senhaValida(ctx: Contexto): string {
  const senha = ctx.corpo.senha;
  if (typeof senha !== "string" || senha.length < 6 || senha.length > 72) {
    throw new ErroDaLiga(400, "A senha da criança precisa ter de 6 a 72 caracteres.");
  }
  return senha;
}

async function criarLogin(ctx: Contexto): Promise<Response> {
  const perfil = await perfilDoResponsavel(ctx);
  const senha = senhaValida(ctx);
  if (perfil.auth_user_id) {
    throw new ErroDaLiga(409, "Essa criança já tem login. Use Trocar senha.");
  }
  const usuario = String(ctx.corpo.usuario ?? "").trim().toLowerCase();
  if (!USUARIO_VALIDO.test(usuario)) {
    throw new ErroDaLiga(
      400,
      "O usuário precisa ter de 3 a 24 letras sem acento, números, ponto ou _.",
    );
  }
  const { data: emUso } = await ctx.servico
    .from("perfis_criancas")
    .select("id")
    .eq("usuario", usuario)
    .maybeSingle();
  if (emUso) throw new ErroDaLiga(409, "Esse usuário já existe. Escolha outro.");

  const { data: criado, error } = await ctx.servico.auth.admin.createUser({
    email: `${usuario}@${DOMINIO_CRIANCA}`,
    password: senha,
    email_confirm: true,
    app_metadata: { papel: "crianca", perfil_id: perfil.id },
  });
  if (error || !criado.user) {
    if (error?.code === "email_exists" || error?.status === 422) {
      throw new ErroDaLiga(409, "Esse usuário já existe. Escolha outro.");
    }
    if (error?.code === "weak_password") {
      throw new ErroDaLiga(400, "Senha fraca. Use pelo menos 6 caracteres.");
    }
    console.error("Falha ao criar o login da criança", error);
    throw new ErroDaLiga(500, "Não consegui criar o login agora. Tente de novo.");
  }

  const { error: erroAoLigar } = await ctx.servico
    .from("perfis_criancas")
    .update({ auth_user_id: criado.user.id, usuario })
    .eq("id", perfil.id);
  if (erroAoLigar) {
    // Não deixa um login solto, sem perfil.
    await ctx.servico.auth.admin.deleteUser(criado.user.id);
    console.error("Falha ao ligar o login ao perfil", erroAoLigar);
    throw new ErroDaLiga(500, "Não consegui criar o login agora. Tente de novo.");
  }
  return resposta(200, { usuario });
}

async function trocarSenha(ctx: Contexto): Promise<Response> {
  const perfil = await perfilDoResponsavel(ctx);
  const senha = senhaValida(ctx);
  if (!perfil.auth_user_id) {
    throw new ErroDaLiga(404, "Essa criança ainda não tem login.");
  }
  const { error } = await ctx.servico.auth.admin.updateUserById(
    perfil.auth_user_id,
    { password: senha },
  );
  if (error) {
    if (error.code === "weak_password") {
      throw new ErroDaLiga(400, "Senha fraca. Use pelo menos 6 caracteres.");
    }
    console.error("Falha ao trocar a senha da criança", error);
    throw new ErroDaLiga(500, "Não consegui trocar a senha agora. Tente de novo.");
  }
  return resposta(200, { usuario: perfil.usuario });
}
