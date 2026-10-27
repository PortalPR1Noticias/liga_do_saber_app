-- Liga do Saber - XP, níveis, sequência de dias, missões do dia e medalhas.
-- Execute depois do 0002_seguranca_e_ajustes.sql no Supabase SQL Editor.
--
-- Todo XP passa pela função public.conceder_xp, chamada só pelas Edge
-- Functions (service role). O app lê o progresso, mas não consegue mais
-- escrever XP, nível ou missões diretamente.

-- 1) Níveis: o nível n começa em 50 * n * (n - 1) XP
--    (nível 2 = 100 XP, 3 = 300, 4 = 600, 5 = 1.000, 10 = 4.500).
--    O app usa a mesma conta em ChildProfile.
create or replace function public.nivel_do_xp(p_xp int)
returns int
language sql
immutable
set search_path = ''
as $$
  select least(99, greatest(1,
    floor((1 + sqrt(1 + 0.08 * greatest(p_xp, 0))) / 2)::int
  ));
$$;

-- 2) Histórico de XP. A referência (caso, desafio, texto, foto) impede que a
--    mesma atividade dê XP duas vezes.
create table if not exists public.eventos_xp (
  id uuid primary key default gen_random_uuid(),
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  origem text not null,
  referencia_id uuid,
  xp int not null check (xp > 0),
  created_at timestamptz not null default now()
);

create unique index if not exists eventos_xp_referencia_unica
  on public.eventos_xp (perfil_crianca_id, origem, referencia_id);
create index if not exists eventos_xp_perfil_origem_idx
  on public.eventos_xp (perfil_crianca_id, origem);

alter table public.eventos_xp enable row level security;

drop policy if exists "eventos_xp_owner_select" on public.eventos_xp;
create policy "eventos_xp_owner_select"
on public.eventos_xp for select
to authenticated
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = eventos_xp.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

-- 3) Missões do dia: cada missão pode ser concluída uma vez por dia
--    (horário de Brasília). `tipo` é a origem do XP que conclui a missão.
alter table public.missoes add column if not exists codigo text;
create unique index if not exists missoes_codigo_unico on public.missoes (codigo);
alter table public.missoes add column if not exists icone text;
alter table public.missoes add column if not exists ordem int not null default 0;

alter table public.progresso_missoes
  add column if not exists dia date not null
  default (now() at time zone 'America/Sao_Paulo')::date;
alter table public.progresso_missoes
  drop constraint if exists progresso_missoes_perfil_crianca_id_missao_id_key;
create unique index if not exists progresso_missoes_dia_unico
  on public.progresso_missoes (perfil_crianca_id, missao_id, dia);

insert into public.missoes (codigo, titulo, descricao, tipo, materia_id, xp_base, icone, ordem)
values
  ('caso_leitura', 'Resolver um caso de leitura',
   'Abra um caso no Detetive da Leitura e acerte pelo menos uma pergunta.',
   'leitura', 'portugues', 25, 'search', 1),
  ('reescrever_texto', 'Reescrever um texto',
   'Use o feedback da Luma para melhorar um texto na Oficina.',
   'texto_reescrita', 'portugues', 35, 'edit', 2),
  ('desafio_matematica', 'Vencer um desafio do Nico',
   'Acerte um desafio na Arena Matemática.',
   'matematica', 'matematica', 20, 'calculate', 3),
  ('foto_tarefa', 'Enviar foto da tarefa',
   'Mande a foto de uma lição e entenda o passo a passo.',
   'foto', null, 15, 'camera', 4)
on conflict (codigo) do nothing;

-- 4) Medalhas com critério que a função entende:
--    {"origem": "...", "quantidade": n}, {"sequencia_dias": n} ou
--    {"missoes_concluidas": n}.
update public.badges set criterio = '{"missoes_concluidas":1}'
where id = 'primeiro_passo';
update public.badges set criterio = '{"origem":"leitura","quantidade":5}'
where id = 'detetive_leitura';
update public.badges set criterio = '{"origem":"texto_reescrita","quantidade":3}'
where id = 'texto_melhorado';
update public.badges set criterio = '{"origem":"matematica","quantidade":10}'
where id = 'estrategista';

insert into public.badges (id, nome, descricao, icone, criterio)
values
  ('sequencia_fogo', 'Sequência de Fogo', 'Estudou 7 dias seguidos.',
   'fire', '{"sequencia_dias":7}'),
  ('olho_de_aguia', 'Olho de Águia', 'Mandou 5 fotos de lição.',
   'camera', '{"origem":"foto","quantidade":5}'),
  ('escritor_criativo', 'Escritor Criativo', 'Escreveu 3 textos na Oficina.',
   'edit', '{"origem":"texto","quantidade":3}')
on conflict (id) do nothing;

-- 5) A função que dá XP. Atualiza XP, nível e sequência de dias, conclui a
--    missão do dia daquele tipo (com o bônus dela) e entrega medalhas novas.
--    Devolve um JSON que as Edge Functions repassam ao app.
create or replace function public.conceder_xp(
  p_perfil uuid,
  p_xp int,
  p_origem text,
  p_referencia uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_hoje date := (now() at time zone 'America/Sao_Paulo')::date;
  v_perfil public.perfis_criancas%rowtype;
  v_ultimo_dia date;
  v_sequencia int;
  v_missao public.missoes%rowtype;
  v_bonus int := 0;
  v_missao_json jsonb := null;
  v_total int;
  v_nivel int;
  v_medalhas jsonb := '[]'::jsonb;
  v_badge public.badges%rowtype;
  v_conquistou boolean;
begin
  if p_xp is null or p_xp <= 0 then
    raise exception 'XP precisa ser positivo';
  end if;

  select * into v_perfil
  from public.perfis_criancas
  where id = p_perfil
  for update;
  if not found then
    raise exception 'Perfil não encontrado';
  end if;

  insert into public.eventos_xp (perfil_crianca_id, origem, referencia_id, xp)
  values (p_perfil, p_origem, p_referencia, p_xp)
  on conflict (perfil_crianca_id, origem, referencia_id) do nothing;
  if not found then
    -- Essa atividade já tinha dado XP.
    return jsonb_build_object(
      'xp_ganho', 0,
      'xp_total', v_perfil.xp_total,
      'nivel', v_perfil.nivel,
      'subiu_nivel', false,
      'sequencia_dias', v_perfil.sequencia_dias,
      'missao_concluida', null,
      'medalhas_novas', '[]'::jsonb
    );
  end if;

  select * into v_missao
  from public.missoes
  where tipo = p_origem and ativa
  order by ordem
  limit 1;
  if found then
    insert into public.progresso_missoes (
      perfil_crianca_id, missao_id, dia, status, tentativas, xp_recebido,
      concluida_em
    )
    values (p_perfil, v_missao.id, v_hoje, 'concluida', 1, v_missao.xp_base, now())
    on conflict (perfil_crianca_id, missao_id, dia) do nothing;
    if found then
      v_bonus := v_missao.xp_base;
      v_missao_json := jsonb_build_object(
        'titulo', v_missao.titulo,
        'xp', v_missao.xp_base
      );
      insert into public.eventos_xp (perfil_crianca_id, origem, referencia_id, xp)
      values (p_perfil, 'missao', gen_random_uuid(), v_missao.xp_base);
    end if;
  end if;

  v_ultimo_dia := (v_perfil.ultima_atividade_em at time zone 'America/Sao_Paulo')::date;
  v_sequencia := case
    when v_ultimo_dia = v_hoje then greatest(v_perfil.sequencia_dias, 1)
    when v_ultimo_dia = v_hoje - 1 then v_perfil.sequencia_dias + 1
    else 1
  end;

  v_total := v_perfil.xp_total + p_xp + v_bonus;
  v_nivel := public.nivel_do_xp(v_total);

  update public.perfis_criancas
  set xp_total = v_total,
      nivel = v_nivel,
      sequencia_dias = v_sequencia,
      ultima_atividade_em = now()
  where id = p_perfil;

  for v_badge in
    select b.* from public.badges b
    where b.ativa
      and not exists (
        select 1 from public.badges_criancas bc
        where bc.perfil_crianca_id = p_perfil and bc.badge_id = b.id
      )
  loop
    v_conquistou := case
      when v_badge.criterio ? 'sequencia_dias' then
        v_sequencia >= (v_badge.criterio->>'sequencia_dias')::int
      when v_badge.criterio ? 'missoes_concluidas' then
        (select count(*) from public.progresso_missoes pm
         where pm.perfil_crianca_id = p_perfil and pm.status = 'concluida')
        >= (v_badge.criterio->>'missoes_concluidas')::int
      when v_badge.criterio ? 'origem' then
        (select count(*) from public.eventos_xp e
         where e.perfil_crianca_id = p_perfil
           and e.origem = v_badge.criterio->>'origem')
        >= (v_badge.criterio->>'quantidade')::int
      else false
    end;
    if v_conquistou then
      insert into public.badges_criancas (perfil_crianca_id, badge_id)
      values (p_perfil, v_badge.id)
      on conflict do nothing;
      v_medalhas := v_medalhas || jsonb_build_object(
        'id', v_badge.id,
        'nome', v_badge.nome,
        'icone', v_badge.icone
      );
    end if;
  end loop;

  return jsonb_build_object(
    'xp_ganho', p_xp + v_bonus,
    'xp_total', v_total,
    'nivel', v_nivel,
    'subiu_nivel', v_nivel > v_perfil.nivel,
    'sequencia_dias', v_sequencia,
    'missao_concluida', v_missao_json,
    'medalhas_novas', v_medalhas
  );
end;
$$;

revoke all on function public.conceder_xp(uuid, int, text, uuid) from public, anon, authenticated;
grant execute on function public.conceder_xp(uuid, int, text, uuid) to service_role;

-- 6) O app não escreve mais XP, nível, sequência, missões nem textos
--    corrigidos: isso fica com as Edge Functions. O responsável continua
--    podendo criar e editar o perfil (apelido, ano, avatar, áreas de foco).
revoke insert, update on public.perfis_criancas from anon, authenticated;
grant insert (responsavel_id, apelido, ano_escolar, avatar_id, areas_foco)
  on public.perfis_criancas to authenticated;
grant update (apelido, ano_escolar, avatar_id, areas_foco)
  on public.perfis_criancas to authenticated;

drop policy if exists "progresso_owner_all" on public.progresso_missoes;
drop policy if exists "progresso_owner_select" on public.progresso_missoes;
create policy "progresso_owner_select"
on public.progresso_missoes for select
to authenticated
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = progresso_missoes.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

drop policy if exists "producoes_textuais_owner_all" on public.producoes_textuais;
drop policy if exists "producoes_textuais_owner_select" on public.producoes_textuais;
create policy "producoes_textuais_owner_select"
on public.producoes_textuais for select
to authenticated
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = producoes_textuais.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

-- 7) Índices para os limites diários das Edge Functions.
create index if not exists correcoes_ia_perfil_tipo_data_idx
  on public.correcoes_ia (perfil_crianca_id, tipo, created_at);
