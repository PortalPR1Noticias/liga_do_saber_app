-- Liga do Saber - três logins: responsável, criança e professor.
-- Execute depois das migrations anteriores no Supabase SQL Editor.
--
-- O que este arquivo faz:
--   1) a criança ganha um login próprio (usuário e senha criados pelo
--      responsável na Edge Function `contas-liga`) e, logada, só lê os
--      próprios dados de jogo;
--   2) o professor tem conta própria (tabela `professores`);
--   3) o responsável escolhe, criança por criança, quais professores podem
--      acompanhar o desempenho (pelo e-mail do professor) e com que nome a
--      criança aparece para eles. É o consentimento específico do art. 14
--      da LGPD para compartilhar dados da criança;
--   4) `avaliacao_desempenho` resume o desempenho da criança para o painel
--      do responsável e do professor. O professor só vê esse resumo, nunca
--      textos, fotos ou provas.

-- 1) Login da criança. Só a Edge Function (service role) grava estas
-- colunas: os grants de coluna da migration 0003 não as liberam para o app.
alter table public.perfis_criancas
  add column if not exists auth_user_id uuid unique
    references auth.users(id) on delete set null,
  add column if not exists usuario text unique
    check (usuario ~ '^[a-z0-9][a-z0-9._]{2,23}$');

-- Perfil da criança logada (nulo para responsável e professor).
create or replace function public.perfil_da_crianca_logada()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.perfis_criancas where auth_user_id = auth.uid();
$$;

revoke all on function public.perfil_da_crianca_logada() from public, anon;
grant execute on function public.perfil_da_crianca_logada() to authenticated;

-- A criança logada lê o próprio perfil e o progresso dos jogos. Escrever
-- continua só com as Edge Functions; as políticas do responsável seguem
-- valendo (no Postgres, políticas do mesmo comando somam).
drop policy if exists "perfis_criancas_crianca_select" on public.perfis_criancas;
create policy "perfis_criancas_crianca_select"
on public.perfis_criancas for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "eventos_xp_crianca_select" on public.eventos_xp;
create policy "eventos_xp_crianca_select"
on public.eventos_xp for select
to authenticated
using (perfil_crianca_id = public.perfil_da_crianca_logada());

drop policy if exists "progresso_crianca_select" on public.progresso_missoes;
create policy "progresso_crianca_select"
on public.progresso_missoes for select
to authenticated
using (perfil_crianca_id = public.perfil_da_crianca_logada());

drop policy if exists "badges_criancas_crianca_select" on public.badges_criancas;
create policy "badges_criancas_crianca_select"
on public.badges_criancas for select
to authenticated
using (perfil_crianca_id = public.perfil_da_crianca_logada());

-- A criança joga a Revanche da prova (lê as provas), mas não apaga.
drop policy if exists "provas_treino_crianca_select" on public.provas_treino;
create policy "provas_treino_crianca_select"
on public.provas_treino for select
to authenticated
using (perfil_crianca_id = public.perfil_da_crianca_logada());

-- O que o app da criança precisa saber do responsável: só se a IA está
-- liberada (sem nome nem e-mail do adulto).
create or replace function public.minha_conta_crianca()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'perfil', to_jsonb(p) - 'auth_user_id' - 'responsavel_id',
    'autoriza_ia', r.autoriza_ia
  )
  from public.perfis_criancas p
  join public.responsaveis r on r.id = p.responsavel_id
  where p.auth_user_id = auth.uid();
$$;

revoke all on function public.minha_conta_crianca() from public, anon;
grant execute on function public.minha_conta_crianca() to authenticated;

-- Perfil apagado (pelo responsável ou com a conta inteira): o login da
-- criança some junto.
create or replace function public.apagar_login_da_crianca()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.auth_user_id is not null then
    delete from auth.users where id = old.auth_user_id;
  end if;
  return old;
end;
$$;

revoke all on function public.apagar_login_da_crianca() from public, anon, authenticated;

drop trigger if exists apagar_login_da_crianca on public.perfis_criancas;
create trigger apagar_login_da_crianca
after delete on public.perfis_criancas
for each row execute function public.apagar_login_da_crianca();

-- A criança não exclui a conta da família: só o responsável ou o professor
-- (cada um a própria conta).
create or replace function public.excluir_minha_conta()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Sessão inválida.' using errcode = '28000';
  end if;
  if public.perfil_da_crianca_logada() is not null then
    raise exception 'Só o responsável pode excluir a conta.' using errcode = '42501';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.excluir_minha_conta() from public, anon;
grant execute on function public.excluir_minha_conta() to authenticated;

-- 2) Professores.
create table if not exists public.professores (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique not null references auth.users(id) on delete cascade,
  nome text not null,
  email text not null,
  termos_versao text,
  created_at timestamptz not null default now()
);

alter table public.professores enable row level security;

drop policy if exists "professores_select_own" on public.professores;
create policy "professores_select_own"
on public.professores for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "professores_insert_own" on public.professores;
create policy "professores_insert_own"
on public.professores for insert
to authenticated
with check (auth_user_id = auth.uid());

drop policy if exists "professores_update_own" on public.professores;
create policy "professores_update_own"
on public.professores for update
to authenticated
using (auth_user_id = auth.uid())
with check (auth_user_id = auth.uid());

-- 3) Quais professores acompanham cada criança. O vínculo é pelo e-mail,
-- então o responsável pode cadastrar antes de o professor criar a conta.
create table if not exists public.professores_criancas (
  id uuid primary key default gen_random_uuid(),
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  email_professor text not null check (email_professor = lower(trim(email_professor))),
  -- Nome com que a criança aparece para o professor (o responsável escolhe).
  nome_crianca text not null check (length(trim(nome_crianca)) between 1 and 80),
  -- Momento em que o responsável autorizou o compartilhamento.
  autorizado_em timestamptz not null default now(),
  unique (perfil_crianca_id, email_professor)
);

create index if not exists professores_criancas_email_idx
  on public.professores_criancas (email_professor);

alter table public.professores_criancas enable row level security;

-- Só o responsável da criança vê, cria e remove os vínculos. O professor lê
-- pelo painel_professor, que mostra só o resumo.
drop policy if exists "professores_criancas_owner_all" on public.professores_criancas;
create policy "professores_criancas_owner_all"
on public.professores_criancas for all
to authenticated
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = professores_criancas.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = professores_criancas.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

-- E-mail confirmado do professor logado (nulo se não for professor ou se o
-- e-mail não foi confirmado: sem isso, qualquer um se passaria pelo
-- professor cadastrando o e-mail dele).
create or replace function public.email_do_professor_logado()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select lower(u.email)
  from auth.users u
  join public.professores pr on pr.auth_user_id = u.id
  where u.id = auth.uid()
    and u.email_confirmed_at is not null;
$$;

revoke all on function public.email_do_professor_logado() from public, anon, authenticated;

-- 4) Avaliação de desempenho dos últimos `p_dias` dias. As áreas juntam as
-- origens de XP (eventos_xp) e as atividades abertas (correcoes_ia, que têm
-- o mesmo nome de tipo). O aproveitamento é atividades que deram XP sobre
-- atividades abertas. A Revanche da prova entra pelas provas (acertos),
-- e a Foto da tarefa só conta o uso.
create or replace function public.avaliacao_desempenho(
  p_perfil uuid,
  p_dias int default 30
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_perfil public.perfis_criancas%rowtype;
  v_desde timestamptz := now() - make_interval(days => greatest(1, least(p_dias, 365)));
  v_semana timestamptz := now() - interval '7 days';
  v_areas jsonb;
  v_provas jsonb;
begin
  select * into v_perfil from public.perfis_criancas where id = p_perfil;
  if not found then
    raise exception 'Perfil não encontrado.' using errcode = '42501';
  end if;

  -- Responsável da criança ou professor autorizado por ele.
  if not exists (
    select 1 from public.responsaveis r
    where r.id = v_perfil.responsavel_id and r.auth_user_id = auth.uid()
  ) and not exists (
    select 1 from public.professores_criancas pc
    where pc.perfil_crianca_id = p_perfil
      and pc.email_professor = public.email_do_professor_logado()
  ) then
    raise exception 'Sem acesso a esta criança.' using errcode = '42501';
  end if;

  with areas(area, nome, origens) as (
    values
      ('portugues', 'Português', array['leitura', 'texto', 'texto_reescrita']),
      ('matematica', 'Matemática', array['matematica']),
      ('ciencias_geografia', 'Ciências e Geografia', array['expedicao']),
      ('historia', 'História', array['arquivo']),
      ('criatividade', 'Projetos e criatividade', array['atelie', 'projeto']),
      ('jogos', 'Jogos da Liga', array['minijogo']),
      ('foto', 'Foto da tarefa', array['foto'])
  ),
  xp as (
    select a.area,
      count(e.id) as concluidas,
      count(e.id) filter (where e.created_at >= v_semana) as concluidas_semana,
      coalesce(sum(e.xp), 0) as xp
    from areas a
    left join public.eventos_xp e
      on e.perfil_crianca_id = p_perfil
     and e.origem = any (a.origens)
     and e.created_at >= v_desde
    group by a.area
  ),
  abertas as (
    select a.area, count(c.id) as abertas
    from areas a
    left join public.correcoes_ia c
      on c.perfil_crianca_id = p_perfil
     and c.tipo = any (a.origens)
     and c.created_at >= v_desde
    group by a.area
  )
  select coalesce(jsonb_agg(jsonb_build_object(
      'area', a.area,
      'nome', a.nome,
      'concluidas', x.concluidas,
      'concluidas_semana', x.concluidas_semana,
      'abertas', greatest(ab.abertas, x.concluidas),
      'xp', x.xp
    ) order by x.concluidas desc, a.area), '[]'::jsonb)
  into v_areas
  from areas a
  join xp x on x.area = a.area
  join abertas ab on ab.area = a.area;

  -- Revanche: o resultado das provas reais que o responsável mandou.
  select coalesce(jsonb_agg(jsonb_build_object(
      'titulo', t.titulo,
      'materia', t.materia,
      'total_questoes', t.total_questoes,
      'questoes_acertadas', t.questoes_acertadas,
      'estrelas', t.estrelas,
      'vencida', t.vencida_em is not null,
      'enviada_em', t.created_at
    ) order by t.created_at desc), '[]'::jsonb)
  into v_provas
  from (
    select * from public.provas_treino
    where perfil_crianca_id = p_perfil and created_at >= v_desde
    order by created_at desc
    limit 10
  ) t;

  return jsonb_build_object(
    'periodo_dias', greatest(1, least(p_dias, 365)),
    'nivel', v_perfil.nivel,
    'xp_total', v_perfil.xp_total,
    'sequencia_dias', v_perfil.sequencia_dias,
    'ultima_atividade_em', v_perfil.ultima_atividade_em,
    'dias_ativos', (
      select count(distinct (e.created_at at time zone 'America/Sao_Paulo')::date)
      from public.eventos_xp e
      where e.perfil_crianca_id = p_perfil and e.created_at >= v_desde
    ),
    'dias_ativos_semana', (
      select count(distinct (e.created_at at time zone 'America/Sao_Paulo')::date)
      from public.eventos_xp e
      where e.perfil_crianca_id = p_perfil and e.created_at >= v_semana
    ),
    'xp_semana', (
      select coalesce(sum(e.xp), 0)
      from public.eventos_xp e
      where e.perfil_crianca_id = p_perfil and e.created_at >= v_semana
    ),
    'areas', v_areas,
    'provas', v_provas
  );
end;
$$;

revoke all on function public.avaliacao_desempenho(uuid, int) from public, anon;
grant execute on function public.avaliacao_desempenho(uuid, int) to authenticated;

-- Painel do professor: as crianças que os responsáveis autorizaram, com o
-- nome que eles escolheram e o resumo de desempenho de cada uma.
create or replace function public.painel_professor(p_dias int default 30)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_email text := public.email_do_professor_logado();
begin
  if v_email is null then
    return '[]'::jsonb;
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
        'vinculo_id', pc.id,
        'perfil_id', p.id,
        'nome', pc.nome_crianca,
        'ano_escolar', p.ano_escolar,
        'avatar_id', p.avatar_id,
        'desempenho', public.avaliacao_desempenho(p.id, p_dias)
      ) order by pc.nome_crianca)
    from public.professores_criancas pc
    join public.perfis_criancas p on p.id = pc.perfil_crianca_id
    where pc.email_professor = v_email
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.painel_professor(int) from public, anon;
grant execute on function public.painel_professor(int) to authenticated;
