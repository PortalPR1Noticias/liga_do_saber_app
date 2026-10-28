-- Avatar 3D, editor de perfil e ranking da Liga.
--
-- Avatar: o visual fica em perfis_criancas.avatar_visual (uma peça por
-- categoria). Pele, cabelo, olhos e boca são sempre livres; roupas e
-- acessórios liberam pelo nível da criança (pecas_avatar.nivel) ou vêm da
-- Loja/temporada (catalogo_visuais com slot 'roupa', comprados com as
-- moedas do XP, nunca com dinheiro).
--
-- Ranking: dia, semana, mês e geral pelo XP de acertos. Por privacidade
-- (LGPD e ECA Digital), a criança só aparece para as outras quando o
-- responsável liga ranking_publico (desligado por padrão), e o ranking
-- mostra só o nome da Liga (bicho + qualidade + número, montado de listas,
-- nunca texto livre), o nível e o avatar. Nada de nome, apelido, ano ou
-- escola.

-- 1) Nome da Liga. As mesmas listas estão em LeagueName
--    (lib/shared/models/avatar.dart).
create or replace function public.nome_liga_valido(p_nome text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(
    array_length(string_to_array(p_nome, ' '), 1) = 3
    and split_part(p_nome, ' ', 1) = any (array['Coruja', 'Tigre', 'Raposa', 'Dragão', 'Lobo', 'Falcão', 'Panda', 'Tubarão', 'Golfinho', 'Pinguim', 'Cometa', 'Foguete', 'Robô', 'Trovão', 'Fênix', 'Leão', 'Onça', 'Arara', 'Tucano', 'Capivara'])
    and split_part(p_nome, ' ', 2) = any (array['Veloz', 'Brilhante', 'Feliz', 'Valente', 'Sagaz', 'Incrível', 'Genial', 'Audaz', 'Estelar', 'Lunar', 'Solar', 'Radiante', 'Leal', 'Ágil', 'Gentil'])
    and split_part(p_nome, ' ', 3) ~ '^[1-9][0-9]?$',
    false
  );
$$;

create or replace function public.gerar_nome_liga()
returns text
language sql
volatile
set search_path = ''
as $$
  select (array['Coruja', 'Tigre', 'Raposa', 'Dragão', 'Lobo', 'Falcão', 'Panda', 'Tubarão', 'Golfinho', 'Pinguim', 'Cometa', 'Foguete', 'Robô', 'Trovão', 'Fênix', 'Leão', 'Onça', 'Arara', 'Tucano', 'Capivara'])[1 + floor(random() * 20)::int]
    || ' '
    || (array['Veloz', 'Brilhante', 'Feliz', 'Valente', 'Sagaz', 'Incrível', 'Genial', 'Audaz', 'Estelar', 'Lunar', 'Solar', 'Radiante', 'Leal', 'Ágil', 'Gentil'])[1 + floor(random() * 15)::int]
    || ' '
    || (1 + floor(random() * 99)::int)::text;
$$;

-- 2) Colunas novas do perfil. Cada perfil existente ganha um nome sorteado.
alter table public.perfis_criancas
  add column if not exists avatar_visual jsonb,
  add column if not exists nome_liga text not null
    default public.gerar_nome_liga(),
  add column if not exists ranking_publico boolean not null default false;

-- O responsável liga e desliga o ranking direto na tabela (a política de
-- dono de perfis_criancas vale; a criança não tem política de update). O
-- avatar e o nome da Liga só mudam pelas funções abaixo, que conferem tudo.
grant update (ranking_publico) on public.perfis_criancas to authenticated;

alter table public.perfis_criancas
  drop constraint if exists perfis_criancas_nome_liga_valido;
alter table public.perfis_criancas
  add constraint perfis_criancas_nome_liga_valido
  check (public.nome_liga_valido(nome_liga));

-- 3) Peças do avatar. nivel = nível da criança que libera (1 = livre);
--    nulo = peça da Loja ou da temporada (precisa estar em compras_visuais).
create table if not exists public.pecas_avatar (
  id text primary key,
  categoria text not null check (categoria in (
    'pele', 'cabelo', 'cor_cabelo', 'olhos', 'cor_olhos', 'boca',
    'camisa', 'calca', 'tenis', 'chapeu', 'oculos', 'costas'
  )),
  nivel int check (nivel between 1 and 100)
);

insert into public.pecas_avatar (id, categoria, nivel) values
  ('pele_1', 'pele', 1),
  ('pele_2', 'pele', 1),
  ('pele_3', 'pele', 1),
  ('pele_4', 'pele', 1),
  ('pele_5', 'pele', 1),
  ('pele_6', 'pele', 1),
  ('pele_7', 'pele', 1),
  ('pele_8', 'pele', 1),
  ('cabelo_curto', 'cabelo', 1),
  ('cabelo_franja', 'cabelo', 1),
  ('cabelo_espetado', 'cabelo', 1),
  ('cabelo_cacheado', 'cabelo', 1),
  ('cabelo_black', 'cabelo', 1),
  ('cabelo_longo', 'cabelo', 1),
  ('cabelo_rabo', 'cabelo', 1),
  ('cabelo_coque', 'cabelo', 1),
  ('cabelo_trancas', 'cabelo', 1),
  ('cabelo_chiquinha', 'cabelo', 1),
  ('cabelo_careca', 'cabelo', 1),
  ('cor_preto', 'cor_cabelo', 1),
  ('cor_castanho_escuro', 'cor_cabelo', 1),
  ('cor_castanho', 'cor_cabelo', 1),
  ('cor_loiro', 'cor_cabelo', 1),
  ('cor_ruivo', 'cor_cabelo', 1),
  ('cor_azul', 'cor_cabelo', 3),
  ('cor_rosa', 'cor_cabelo', 4),
  ('cor_roxo', 'cor_cabelo', 6),
  ('cor_verde', 'cor_cabelo', 8),
  ('olhos_redondos', 'olhos', 1),
  ('olhos_grandes', 'olhos', 1),
  ('olhos_felizes', 'olhos', 1),
  ('olhos_determinados', 'olhos', 1),
  ('iris_castanho', 'cor_olhos', 1),
  ('iris_preto', 'cor_olhos', 1),
  ('iris_mel', 'cor_olhos', 1),
  ('iris_verde', 'cor_olhos', 1),
  ('iris_azul', 'cor_olhos', 1),
  ('boca_sorriso', 'boca', 1),
  ('boca_sorrisao', 'boca', 1),
  ('boca_tranquila', 'boca', 1),
  ('boca_surpresa', 'boca', 1),
  ('camiseta_azul', 'camisa', 1),
  ('camiseta_vermelha', 'camisa', 1),
  ('camiseta_verde', 'camisa', 1),
  ('camiseta_amarela', 'camisa', 1),
  ('camiseta_rosa', 'camisa', 1),
  ('camiseta_liga', 'camisa', 2),
  ('camisa_listrada', 'camisa', 3),
  ('moletom_roxo', 'camisa', 4),
  ('jaqueta_explorador', 'camisa', 6),
  ('uniforme_heroi', 'camisa', 9),
  ('camisa_galaxia', 'camisa', null),
  ('jaqueta_neon', 'camisa', null),
  ('armadura_dourada', 'camisa', null),
  ('calca_jeans', 'calca', 1),
  ('calca_preta', 'calca', 1),
  ('shorts_vermelho', 'calca', 1),
  ('saia_rosa', 'calca', 1),
  ('bermuda_cargo', 'calca', 3),
  ('calca_esportiva', 'calca', 5),
  ('calca_espacial', 'calca', null),
  ('tenis_branco', 'tenis', 1),
  ('tenis_preto', 'tenis', 1),
  ('tenis_azul', 'tenis', 1),
  ('tenis_vermelho', 'tenis', 2),
  ('botas_explorador', 'tenis', 6),
  ('tenis_neon', 'tenis', null),
  ('tenis_dourado', 'tenis', null),
  ('bone_azul', 'chapeu', 2),
  ('gorro_listrado', 'chapeu', 4),
  ('chapeu_explorador', 'chapeu', 7),
  ('orelhas_gato', 'chapeu', null),
  ('fone_gamer', 'chapeu', null),
  ('coroa', 'chapeu', null),
  ('oculos_grau', 'oculos', 1),
  ('oculos_redondos', 'oculos', 1),
  ('oculos_escuros', 'oculos', 5),
  ('visor_futurista', 'oculos', null),
  ('mochila', 'costas', 3),
  ('capa_heroi', 'costas', 8),
  ('jetpack', 'costas', null),
  ('asas_luz', 'costas', null)
on conflict (id) do update
  set categoria = excluded.categoria,
      nivel = excluded.nivel;

alter table public.pecas_avatar enable row level security;

drop policy if exists "pecas_avatar_select" on public.pecas_avatar;
create policy "pecas_avatar_select"
on public.pecas_avatar for select
to authenticated
using (true);

revoke insert, update, delete on public.pecas_avatar from anon, authenticated;

-- 4) Roupas do avatar na Loja e na temporada (mesmas funções de compra da
--    migration 0011). Não são equipadas em visuais_equipados: a criança
--    veste no avatar.
alter table public.catalogo_visuais
  drop constraint if exists catalogo_visuais_slot_check;
alter table public.catalogo_visuais
  add constraint catalogo_visuais_slot_check
  check (slot in ('moldura', 'aura', 'pedestal', 'titulo', 'roupa'));

insert into public.catalogo_visuais (id, slot, preco, nivel_temporada) values
  ('camisa_galaxia', 'roupa', 80, null),
  ('jaqueta_neon', 'roupa', 120, null),
  ('armadura_dourada', 'roupa', null, 22),
  ('calca_espacial', 'roupa', 70, null),
  ('tenis_neon', 'roupa', 60, null),
  ('tenis_dourado', 'roupa', null, 12),
  ('orelhas_gato', 'roupa', 60, null),
  ('fone_gamer', 'roupa', 90, null),
  ('coroa', 'roupa', null, 18),
  ('visor_futurista', 'roupa', 100, null),
  ('jetpack', 'roupa', 150, null),
  ('asas_luz', 'roupa', null, 28)
on conflict (id) do update
  set slot = excluded.slot,
      preco = excluded.preco,
      nivel_temporada = excluded.nivel_temporada;

-- 5) Salvar o avatar: confere cada peça (nível ou compra) antes de gravar.
--    Funciona no login do responsável e no da criança.
create or replace function public.salvar_avatar(p_perfil uuid, p_visual jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_nivel int;
  v_chave text;
  v_valor text;
  v_peca public.pecas_avatar;
begin
  perform public.travar_perfil_do_dono(p_perfil);

  if p_visual is null or jsonb_typeof(p_visual) <> 'object' then
    raise exception 'Visual inválido.';
  end if;
  if exists (
    select 1
    from unnest(array[
      'pele', 'cabelo', 'cor_cabelo', 'olhos', 'cor_olhos', 'boca',
      'camisa', 'calca', 'tenis'
    ]) as c(categoria)
    where not (p_visual ? c.categoria)
  ) then
    raise exception 'Faltam peças no avatar.';
  end if;

  select nivel into v_nivel from public.perfis_criancas where id = p_perfil;

  for v_chave, v_valor in select key, value from jsonb_each_text(p_visual) loop
    select * into v_peca from public.pecas_avatar where id = v_valor;
    if not found or v_peca.categoria <> v_chave then
      raise exception 'Peça desconhecida.';
    end if;
    if v_peca.nivel is null then
      if not exists (
        select 1 from public.compras_visuais
        where perfil_crianca_id = p_perfil and item_id = v_valor
      ) then
        raise exception 'Ganhe essa peça na Loja da Liga antes de usar.';
      end if;
    elsif v_peca.nivel > v_nivel then
      raise exception 'Chegue ao nível % para usar essa peça.', v_peca.nivel;
    end if;
  end loop;

  update public.perfis_criancas
  set avatar_visual = p_visual,
      updated_at = now()
  where id = p_perfil;

  return (
    select to_jsonb(p) - 'auth_user_id' - 'responsavel_id'
    from public.perfis_criancas p
    where p.id = p_perfil
  );
end;
$$;

-- 6) Editor de perfil: apelido, herói parceiro e nome da Liga. A criança
--    não tem permissão de update direto em perfis_criancas, por isso a função.
create or replace function public.salvar_perfil_jogador(
  p_perfil uuid,
  p_apelido text,
  p_avatar_id text,
  p_nome_liga text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_apelido text := btrim(coalesce(p_apelido, ''));
begin
  perform public.travar_perfil_do_dono(p_perfil);

  if char_length(v_apelido) not between 2 and 20 then
    raise exception 'O apelido precisa ter de 2 a 20 letras.';
  end if;
  if p_avatar_id not in (
    'estrategista', 'guardia', 'explorador', 'investigadora', 'criadora'
  ) then
    raise exception 'Herói desconhecido.';
  end if;
  if not public.nome_liga_valido(p_nome_liga) then
    raise exception 'Escolha o nome da Liga na lista.';
  end if;

  update public.perfis_criancas
  set apelido = v_apelido,
      avatar_id = p_avatar_id,
      nome_liga = p_nome_liga,
      updated_at = now()
  where id = p_perfil;

  return (
    select to_jsonb(p) - 'auth_user_id' - 'responsavel_id'
    from public.perfis_criancas p
    where p.id = p_perfil
  );
end;
$$;

-- 7) Ranking. Entra quem o responsável liberou, mais a própria criança
--    (que sempre vê a posição dela, mesmo sem aparecer para os outros).
create index if not exists eventos_xp_data_idx
  on public.eventos_xp (created_at, perfil_crianca_id);

create or replace function public.ranking_liga(p_perfil uuid, p_periodo text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_agora timestamp := now() at time zone 'America/Sao_Paulo';
  v_inicio timestamptz;
  v_participa boolean;
  v_top jsonb;
  v_eu jsonb;
  v_total int;
begin
  select p.ranking_publico into v_participa
  from public.perfis_criancas p
  left join public.responsaveis r on r.id = p.responsavel_id
  where p.id = p_perfil
    and (r.auth_user_id = auth.uid() or p.auth_user_id = auth.uid());
  if not found then
    raise exception 'Perfil não encontrado';
  end if;

  if p_periodo = 'dia' then
    v_inicio := date_trunc('day', v_agora) at time zone 'America/Sao_Paulo';
  elsif p_periodo = 'semana' then
    v_inicio := date_trunc('week', v_agora) at time zone 'America/Sao_Paulo';
  elsif p_periodo = 'mes' then
    v_inicio := date_trunc('month', v_agora) at time zone 'America/Sao_Paulo';
  elsif p_periodo is distinct from 'geral' then
    raise exception 'Período inválido.';
  end if;

  with pontos as (
    select e.perfil_crianca_id, sum(e.xp)::int as xp
    from public.eventos_xp e
    where v_inicio is not null and e.created_at >= v_inicio
    group by e.perfil_crianca_id
  ),
  jogadores as (
    select
      p.id,
      p.nome_liga,
      p.avatar_visual,
      p.nivel,
      p.ranking_publico,
      case when v_inicio is null then p.xp_total else coalesce(x.xp, 0) end
        as xp
    from public.perfis_criancas p
    left join pontos x on x.perfil_crianca_id = p.id
    where p.ranking_publico or p.id = p_perfil
  ),
  colocados as (
    select j.*, rank() over (order by j.xp desc) as posicao
    from jogadores j
    where j.xp > 0 or j.id = p_perfil
  )
  select
    coalesce((
      select jsonb_agg(jsonb_build_object(
          'posicao', c.posicao,
          'nome_liga', c.nome_liga,
          'avatar_visual', c.avatar_visual,
          'nivel', c.nivel,
          'xp', c.xp,
          'eu', c.id = p_perfil
        ) order by c.posicao, c.nome_liga)
      from (
        select * from colocados
        where ranking_publico and xp > 0
        order by posicao, nome_liga
        limit 50
      ) c
    ), '[]'::jsonb),
    (
      select jsonb_build_object(
        'posicao', c.posicao,
        'nome_liga', c.nome_liga,
        'avatar_visual', c.avatar_visual,
        'nivel', c.nivel,
        'xp', c.xp,
        'eu', true
      )
      from colocados c
      where c.id = p_perfil
    ),
    (select count(*)::int from colocados where ranking_publico and xp > 0)
  into v_top, v_eu, v_total;

  return jsonb_build_object(
    'periodo', coalesce(p_periodo, 'geral'),
    'participa', v_participa,
    'participantes', v_total,
    'top', v_top,
    'eu', v_eu
  );
end;
$$;

revoke all on function public.salvar_avatar(uuid, jsonb) from public, anon;
revoke all on function public.salvar_perfil_jogador(uuid, text, text, text) from public, anon;
revoke all on function public.ranking_liga(uuid, text) from public, anon;
grant execute on function public.salvar_avatar(uuid, jsonb) to authenticated;
grant execute on function public.salvar_perfil_jogador(uuid, text, text, text) to authenticated;
grant execute on function public.ranking_liga(uuid, text) to authenticated;
