-- Etapa 2 do modo jogo: os chefões no fim de cada ilha do Mundo da Liga.
--
-- A criança enfrenta o chefão depois de vencer as 9 fases da ilha (atividades
-- que deram XP nas origens daquela matéria). Cada resposta da batalha já passa
-- pelas Edge Functions de sempre; aqui fica só o registro da vitória, com as
-- estrelas (acerto, não rapidez) e um bônus de XP na primeira vez.

-- 1) Vitórias contra os chefões. Uma linha por ilha, com a melhor nota.
create table if not exists public.chefoes_vencidos (
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  ilha text not null check (ilha in ('nico', 'luma', 'teo', 'mila', 'zuri')),
  estrelas int not null check (estrelas between 1 and 3),
  vitorias int not null default 1,
  primeira_vitoria_em timestamptz not null default now(),
  ultima_vitoria_em timestamptz not null default now(),
  primary key (perfil_crianca_id, ilha)
);

alter table public.chefoes_vencidos enable row level security;

drop policy if exists "chefoes_vencidos_owner_select" on public.chefoes_vencidos;
create policy "chefoes_vencidos_owner_select"
on public.chefoes_vencidos for select
to authenticated
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = chefoes_vencidos.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

-- Só a função abaixo grava: o app não escreve direto na tabela.
revoke insert, update, delete on public.chefoes_vencidos from anon, authenticated;

-- 2) Registra a vitória. Confere que o perfil é da conta logada e que a
--    criança venceu as fases da ilha antes. O bônus de 50 XP sai uma vez por
--    ilha (a referência é fixa por perfil e ilha).
create or replace function public.registrar_chefao(
  p_perfil uuid,
  p_ilha text,
  p_estrelas int
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_origens text[];
  v_fases int;
  v_estrelas int;
  v_progresso jsonb;
begin
  if not exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = p_perfil
      and r.auth_user_id = auth.uid()
  ) then
    raise exception 'Perfil não encontrado';
  end if;

  -- Mesmas origens das ilhas em lib/features/world/world_islands.dart.
  v_origens := case p_ilha
    when 'nico' then array['matematica']
    when 'luma' then array['leitura', 'texto', 'texto_reescrita']
    when 'teo' then array['expedicao']
    when 'mila' then array['arquivo']
    when 'zuri' then array['atelie', 'projeto']
  end;
  if v_origens is null then
    raise exception 'Ilha desconhecida';
  end if;

  select count(*) into v_fases
  from public.eventos_xp
  where perfil_crianca_id = p_perfil
    and origem = any (v_origens);
  if v_fases < 9 then
    raise exception 'Vença as fases da ilha antes do chefão.';
  end if;

  v_estrelas := least(greatest(coalesce(p_estrelas, 1), 1), 3);

  insert into public.chefoes_vencidos (perfil_crianca_id, ilha, estrelas)
  values (p_perfil, p_ilha, v_estrelas)
  on conflict (perfil_crianca_id, ilha) do update
    set estrelas = greatest(public.chefoes_vencidos.estrelas, excluded.estrelas),
        vitorias = public.chefoes_vencidos.vitorias + 1,
        ultima_vitoria_em = now();

  v_progresso := public.conceder_xp(
    p_perfil,
    50,
    'chefao',
    md5(p_perfil::text || ':chefao:' || p_ilha)::uuid
  );

  return jsonb_build_object(
    'estrelas', (
      select estrelas from public.chefoes_vencidos
      where perfil_crianca_id = p_perfil and ilha = p_ilha
    ),
    'progresso', v_progresso
  );
end;
$$;

revoke all on function public.registrar_chefao(uuid, text, int) from public, anon;
grant execute on function public.registrar_chefao(uuid, text, int) to authenticated;

-- 3) A cópia dos dados (LGPD art. 18) passa a levar os chefões vencidos.
--    Mesmo corpo da 0009, com a chave 'chefoes_vencidos'.
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
