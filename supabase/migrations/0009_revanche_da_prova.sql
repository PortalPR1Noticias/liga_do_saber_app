-- Liga do Saber - Revanche da prova.
-- Execute depois do 0008_minijogos.sql no Supabase SQL Editor.
--
-- O responsável manda fotos de uma prova ou tarefa que a criança já fez. A
-- Edge Function `revanche-prova` lê as fotos com a OpenAI (só com
-- responsaveis.autoriza_ia ligado), cria questões de treino parecidas e
-- grava tudo em `provas_treino`. As fotos não são guardadas.
--
-- XP pela public.conceder_xp (migration 0003): origem 'revanche' a cada
-- questão acertada e 'revanche_vencida' quando a criança acerta a prova
-- inteira.

-- 1) Provas e tarefas enviadas para treinar.
create table if not exists public.provas_treino (
  id uuid primary key default gen_random_uuid(),
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  tipo text not null check (tipo in ('prova', 'tarefa')),
  titulo text not null,
  materia text not null,
  personagem text not null,
  conteudos text[] not null default '{}',
  -- Recado da IA para o responsável: o que caiu e o que vale reforçar.
  resumo_responsavel text not null default '',
  observacao text,
  -- Questões com a resposta certa, a explicação e o estado de cada uma
  -- (tentativas, acertou, explicada). Só a Edge Function escreve aqui.
  questoes jsonb not null,
  total_questoes int not null,
  questoes_acertadas int not null default 0,
  estrelas int not null default 0 check (estrelas between 0 and 3),
  vencida_em timestamptz,
  modelo_usado text,
  created_at timestamptz not null default now()
);

create index if not exists provas_treino_perfil_data_idx
  on public.provas_treino (perfil_crianca_id, created_at desc);

alter table public.provas_treino enable row level security;

-- O responsável lê e apaga as provas das crianças dele. Criar e atualizar
-- fica só com a Edge Function (service role).
drop policy if exists "provas_treino_owner_select" on public.provas_treino;
create policy "provas_treino_owner_select"
on public.provas_treino for select
to authenticated
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = provas_treino.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

drop policy if exists "provas_treino_owner_delete" on public.provas_treino;
create policy "provas_treino_owner_delete"
on public.provas_treino for delete
to authenticated
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = provas_treino.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

-- 2) Missão do dia e medalha.
insert into public.missoes (codigo, titulo, descricao, tipo, materia_id, xp_base, icone, ordem)
values
  ('revanche_prova', 'Treinar na Revanche da prova',
   'Acerte uma questão de uma prova ou tarefa que o responsável enviou.',
   'revanche', null, 20, 'replay', 9)
on conflict (codigo) do nothing;

insert into public.badges (id, nome, descricao, icone, criterio)
values
  ('virada_de_jogo', 'Virada de Jogo', 'Venceu 3 Revanches da prova.',
   'replay', '{"origem":"revanche_vencida","quantidade":3}')
on conflict (id) do nothing;

-- 3) A cópia dos dados (LGPD art. 18) passa a levar as provas enviadas.
--    Mesmo corpo da 0004, com a chave 'provas_treino'.
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

-- 4) Retenção: as provas de treino seguem o prazo das explicações da IA
--    (12 meses). Mesmo corpo da 0004, com o delete de provas_treino.
create or replace function public.aplicar_retencao()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.correcoes_ia
  where created_at < now() - interval '12 months';

  delete from public.provas_treino
  where created_at < now() - interval '12 months';

  delete from auth.users u
  where coalesce(u.last_sign_in_at, u.created_at) < now() - interval '24 months'
    and exists (select 1 from public.responsaveis r where r.auth_user_id = u.id);
end;
$$;

revoke all on function public.aplicar_retencao() from public, anon, authenticated;
