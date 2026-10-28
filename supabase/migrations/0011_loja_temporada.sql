-- Etapa 3 do modo jogo: moedas, loja de visuais e temporada.
--
-- Regra "quem aprende é quem avança": as moedas não são compradas, vêm só do
-- XP das respostas certas (1 moeda a cada 10 XP). A loja vende apenas visuais
-- (molduras, auras, pedestais e títulos), nunca vantagem nas atividades.
-- A temporada é mensal: o XP do mês sobe a trilha de 30 níveis e alguns
-- níveis liberam visuais exclusivos, que a criança guarda para sempre.

-- 1) Catálogo. Cada item tem preço em moedas OU nível da temporada.
--    Os nomes e cores ficam no app (lib/shared/models/visuals.dart).
create table if not exists public.catalogo_visuais (
  id text primary key,
  slot text not null check (slot in ('moldura', 'aura', 'pedestal', 'titulo')),
  preco int check (preco > 0),
  nivel_temporada int check (nivel_temporada between 1 and 30),
  check ((preco is null) <> (nivel_temporada is null))
);

insert into public.catalogo_visuais (id, slot, preco, nivel_temporada) values
  ('moldura_ouro', 'moldura', 40, null),
  ('moldura_neon', 'moldura', 60, null),
  ('moldura_arco_iris', 'moldura', 90, null),
  ('moldura_cometa', 'moldura', null, 20),
  ('aura_glacial', 'aura', 50, null),
  ('aura_fogo', 'aura', 80, null),
  ('aura_estelar', 'aura', 120, null),
  ('aura_relampago', 'aura', null, 10),
  ('aura_lendaria', 'aura', null, 30),
  ('pedestal_pedra', 'pedestal', 30, null),
  ('pedestal_cristal', 'pedestal', 70, null),
  ('pedestal_lava', 'pedestal', 100, null),
  ('pedestal_nuvem', 'pedestal', null, 15),
  ('titulo_curioso', 'titulo', 20, null),
  ('titulo_mestre_contas', 'titulo', 60, null),
  ('titulo_detetive', 'titulo', 60, null),
  ('titulo_explorador', 'titulo', 60, null),
  ('titulo_estreante', 'titulo', null, 5),
  ('titulo_campeao', 'titulo', null, 25)
on conflict (id) do update
  set slot = excluded.slot,
      preco = excluded.preco,
      nivel_temporada = excluded.nivel_temporada;

alter table public.catalogo_visuais enable row level security;

drop policy if exists "catalogo_visuais_select" on public.catalogo_visuais;
create policy "catalogo_visuais_select"
on public.catalogo_visuais for select
to authenticated
using (true);

revoke insert, update, delete on public.catalogo_visuais from anon, authenticated;

-- 2) Visuais da criança (comprados ou ganhos na temporada) e os equipados.
create table if not exists public.compras_visuais (
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  item_id text not null references public.catalogo_visuais(id),
  -- 0 quando veio da temporada.
  preco int not null default 0 check (preco >= 0),
  comprado_em timestamptz not null default now(),
  primary key (perfil_crianca_id, item_id)
);

create table if not exists public.visuais_equipados (
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  slot text not null check (slot in ('moldura', 'aura', 'pedestal', 'titulo')),
  item_id text not null references public.catalogo_visuais(id),
  primary key (perfil_crianca_id, slot)
);

alter table public.compras_visuais enable row level security;
alter table public.visuais_equipados enable row level security;

drop policy if exists "compras_visuais_owner_select" on public.compras_visuais;
create policy "compras_visuais_owner_select"
on public.compras_visuais for select
to authenticated
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = compras_visuais.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

drop policy if exists "visuais_equipados_owner_select" on public.visuais_equipados;
create policy "visuais_equipados_owner_select"
on public.visuais_equipados for select
to authenticated
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = visuais_equipados.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

-- Só as funções abaixo gravam: o app não escreve direto nas tabelas.
revoke insert, update, delete on public.compras_visuais from anon, authenticated;
revoke insert, update, delete on public.visuais_equipados from anon, authenticated;

-- 3) Estado da loja: saldo, itens, equipados e temporada do mês.
--    Interna (sem conferir o dono); as funções públicas conferem antes.
create or replace function public.estado_loja_interno(p_perfil uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ganhas int;
  v_gastas int;
  v_inicio timestamptz;
  v_xp_mes int;
begin
  select coalesce(p.xp_total, 0) / 10 into v_ganhas
  from public.perfis_criancas p
  where p.id = p_perfil;

  select coalesce(sum(c.preco), 0) into v_gastas
  from public.compras_visuais c
  where c.perfil_crianca_id = p_perfil;

  -- Temporada = mês corrente no horário de Brasília.
  v_inicio := date_trunc('month', now() at time zone 'America/Sao_Paulo')
    at time zone 'America/Sao_Paulo';
  select coalesce(sum(e.xp), 0) into v_xp_mes
  from public.eventos_xp e
  where e.perfil_crianca_id = p_perfil
    and e.created_at >= v_inicio;

  return jsonb_build_object(
    'moedas', greatest(coalesce(v_ganhas, 0) - v_gastas, 0),
    'itens', coalesce((
      select jsonb_agg(c.item_id order by c.comprado_em)
      from public.compras_visuais c
      where c.perfil_crianca_id = p_perfil
    ), '[]'::jsonb),
    'equipados', coalesce((
      select jsonb_object_agg(v.slot, v.item_id)
      from public.visuais_equipados v
      where v.perfil_crianca_id = p_perfil
    ), '{}'::jsonb),
    'temporada', jsonb_build_object(
      'id', to_char(now() at time zone 'America/Sao_Paulo', 'YYYY-MM'),
      'xp', v_xp_mes,
      'termina_em', (v_inicio + interval '1 month')
    )
  );
end;
$$;

revoke all on function public.estado_loja_interno(uuid) from public, anon, authenticated;

-- Confere que o perfil é da conta logada e trava a linha do perfil, para
-- duas compras ao mesmo tempo não gastarem o mesmo saldo.
create or replace function public.travar_perfil_do_dono(p_perfil uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform 1
  from public.perfis_criancas p
  join public.responsaveis r on r.id = p.responsavel_id
  where p.id = p_perfil
    and r.auth_user_id = auth.uid()
  for update of p;
  if not found then
    raise exception 'Perfil não encontrado';
  end if;
end;
$$;

revoke all on function public.travar_perfil_do_dono(uuid) from public, anon, authenticated;

create or replace function public.estado_loja(p_perfil uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.travar_perfil_do_dono(p_perfil);
  return public.estado_loja_interno(p_perfil);
end;
$$;

-- 4) Compra com moedas.
create or replace function public.comprar_visual(p_perfil uuid, p_item text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_item public.catalogo_visuais;
  v_estado jsonb;
begin
  perform public.travar_perfil_do_dono(p_perfil);

  select * into v_item from public.catalogo_visuais where id = p_item;
  if not found or v_item.preco is null then
    raise exception 'Esse visual não está à venda.';
  end if;
  if exists (
    select 1 from public.compras_visuais
    where perfil_crianca_id = p_perfil and item_id = p_item
  ) then
    return public.estado_loja_interno(p_perfil);
  end if;

  v_estado := public.estado_loja_interno(p_perfil);
  if (v_estado ->> 'moedas')::int < v_item.preco then
    raise exception 'Moedas insuficientes. Acerte mais desafios para ganhar moedas!';
  end if;

  insert into public.compras_visuais (perfil_crianca_id, item_id, preco)
  values (p_perfil, p_item, v_item.preco);

  return public.estado_loja_interno(p_perfil);
end;
$$;

-- 5) Prêmio da temporada: liberado quando o XP do mês alcança o nível.
--    50 XP por nível (mesma conta de SeasonState em lib/shared/models/shop.dart).
create or replace function public.resgatar_temporada(p_perfil uuid, p_item text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_item public.catalogo_visuais;
  v_nivel int;
begin
  perform public.travar_perfil_do_dono(p_perfil);

  select * into v_item from public.catalogo_visuais where id = p_item;
  if not found or v_item.nivel_temporada is null then
    raise exception 'Esse prêmio não é da temporada.';
  end if;

  v_nivel := least(
    30,
    (public.estado_loja_interno(p_perfil) -> 'temporada' ->> 'xp')::int / 50
  );
  if v_nivel < v_item.nivel_temporada then
    raise exception 'Chegue ao nível % da temporada para ganhar esse prêmio.',
      v_item.nivel_temporada;
  end if;

  insert into public.compras_visuais (perfil_crianca_id, item_id, preco)
  values (p_perfil, p_item, 0)
  on conflict do nothing;

  return public.estado_loja_interno(p_perfil);
end;
$$;

-- 6) Equipar (ou tirar, com p_item nulo) um visual que a criança já tem.
create or replace function public.equipar_visual(
  p_perfil uuid,
  p_slot text,
  p_item text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.travar_perfil_do_dono(p_perfil);

  if p_item is null then
    delete from public.visuais_equipados
    where perfil_crianca_id = p_perfil and slot = p_slot;
    return public.estado_loja_interno(p_perfil);
  end if;

  if not exists (
    select 1
    from public.compras_visuais c
    join public.catalogo_visuais v on v.id = c.item_id
    where c.perfil_crianca_id = p_perfil
      and c.item_id = p_item
      and v.slot = p_slot
  ) then
    raise exception 'Ganhe esse visual antes de usar.';
  end if;

  insert into public.visuais_equipados (perfil_crianca_id, slot, item_id)
  values (p_perfil, p_slot, p_item)
  on conflict (perfil_crianca_id, slot) do update set item_id = excluded.item_id;

  return public.estado_loja_interno(p_perfil);
end;
$$;

revoke all on function public.estado_loja(uuid) from public, anon;
revoke all on function public.comprar_visual(uuid, text) from public, anon;
revoke all on function public.resgatar_temporada(uuid, text) from public, anon;
revoke all on function public.equipar_visual(uuid, text, text) from public, anon;
grant execute on function public.estado_loja(uuid) to authenticated;
grant execute on function public.comprar_visual(uuid, text) to authenticated;
grant execute on function public.resgatar_temporada(uuid, text) to authenticated;
grant execute on function public.equipar_visual(uuid, text, text) to authenticated;

-- 7) LGPD: a exportação inclui os visuais da criança.
create or replace function public.exportar_meus_dados()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'gerado_em', now(),
    'responsavel', (
      select to_jsonb(r) - 'auth_user_id'
      from public.responsaveis r
      where r.auth_user_id = auth.uid()
    ),
    'consentimentos', coalesce((
      select jsonb_agg(to_jsonb(c) order by c.created_at)
      from public.consentimentos c
    ), '[]'::jsonb),
    'perfis_criancas', coalesce((
      select jsonb_agg(
        to_jsonb(p) || jsonb_build_object(
          'progresso_missoes', coalesce((
            select jsonb_agg(to_jsonb(x)) from public.progresso_missoes x
            where x.perfil_crianca_id = p.id
          ), '[]'::jsonb),
          'correcoes_ia', coalesce((
            select jsonb_agg(to_jsonb(x)) from public.correcoes_ia x
            where x.perfil_crianca_id = p.id
          ), '[]'::jsonb),
          'producoes_textuais', coalesce((
            select jsonb_agg(to_jsonb(x)) from public.producoes_textuais x
            where x.perfil_crianca_id = p.id
          ), '[]'::jsonb),
          'provas_treino', coalesce((
            select jsonb_agg(to_jsonb(x) order by x.created_at)
            from public.provas_treino x
            where x.perfil_crianca_id = p.id
          ), '[]'::jsonb),
          'chefoes_vencidos', coalesce((
            select jsonb_agg(to_jsonb(x)) from public.chefoes_vencidos x
            where x.perfil_crianca_id = p.id
          ), '[]'::jsonb),
          'compras_visuais', coalesce((
            select jsonb_agg(to_jsonb(x) order by x.comprado_em)
            from public.compras_visuais x
            where x.perfil_crianca_id = p.id
          ), '[]'::jsonb),
          'visuais_equipados', coalesce((
            select jsonb_agg(to_jsonb(x)) from public.visuais_equipados x
            where x.perfil_crianca_id = p.id
          ), '[]'::jsonb),
          'badges', coalesce((
            select jsonb_agg(to_jsonb(x)) from public.badges_criancas x
            where x.perfil_crianca_id = p.id
          ), '[]'::jsonb)
        )
        order by p.created_at
      )
      from public.perfis_criancas p
    ), '[]'::jsonb)
  );
$$;

revoke all on function public.exportar_meus_dados() from public, anon;
grant execute on function public.exportar_meus_dados() to authenticated;
