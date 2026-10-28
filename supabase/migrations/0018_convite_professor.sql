-- Liga do Saber - professor entra pelo código de convite.
-- Execute depois da 0017 no Supabase SQL Editor. Pode rodar mais de uma vez.
--
-- Até a 0017 o professor via a criança se o e-mail confirmado dele fosse o
-- mesmo que o responsável cadastrou. Sem a confirmação de e-mail (desligada
-- no Supabase para o cadastro não mandar e-mail), qualquer um se passaria
-- pelo professor criando conta com o e-mail dele. Agora cada liberação tem
-- um código de 6 letras: o responsável manda o código ao professor, que
-- digita no painel dele. Quem tem o código é quem o responsável escolheu.

-- Código sem letras e números que se confundem (0/O, 1/I/L).
create or replace function public.gerar_codigo_professor()
returns text
language sql
volatile
set search_path = ''
as $$
  select string_agg(
    substr('ABCDEFGHJKMNPQRSTUVWXYZ23456789', 1 + floor(random() * 31)::int, 1),
    ''
  )
  from generate_series(1, 6);
$$;

alter table public.professores_criancas
  add column if not exists codigo text,
  add column if not exists professor_auth_user_id uuid
    references auth.users(id) on delete set null,
  add column if not exists conectado_em timestamptz;

update public.professores_criancas
set codigo = public.gerar_codigo_professor()
where codigo is null;

alter table public.professores_criancas
  alter column codigo set default public.gerar_codigo_professor(),
  alter column codigo set not null;

create unique index if not exists professores_criancas_codigo_idx
  on public.professores_criancas (codigo);

create index if not exists professores_criancas_professor_idx
  on public.professores_criancas (professor_auth_user_id);

-- Professores que já entraram com e-mail confirmado (antes de desligar a
-- confirmação) continuam vendo os alunos sem precisar do código. Conta
-- confirmada no mesmo instante em que foi criada é confirmação automática
-- (chave já desligada), e essa não vale.
update public.professores_criancas pc
set professor_auth_user_id = pr.auth_user_id,
    conectado_em = coalesce(pc.conectado_em, now())
from public.professores pr
join auth.users u on u.id = pr.auth_user_id
where pc.professor_auth_user_id is null
  and pc.email_professor = lower(u.email)
  and u.email_confirmed_at is not null
  and u.email_confirmed_at > u.created_at + interval '5 seconds';

-- O professor logado digita o código e passa a ver a criança. Devolve o
-- nome com que a criança aparece para ele.
create or replace function public.usar_codigo_professor(p_codigo text)
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_codigo text := upper(regexp_replace(coalesce(p_codigo, ''), '[^A-Za-z0-9]', '', 'g'));
  v_vinculo public.professores_criancas%rowtype;
begin
  if not exists (
    select 1 from public.professores where auth_user_id = auth.uid()
  ) then
    raise exception 'Só professores usam o código.';
  end if;

  select * into v_vinculo
  from public.professores_criancas
  where codigo = v_codigo
  for update;

  if not found
     or (v_vinculo.professor_auth_user_id is not null
         and v_vinculo.professor_auth_user_id <> auth.uid()) then
    raise exception 'Código inválido ou já usado. Confira com o responsável.';
  end if;

  update public.professores_criancas
  set professor_auth_user_id = auth.uid(),
      conectado_em = coalesce(conectado_em, now())
  where id = v_vinculo.id;

  return v_vinculo.nome_crianca;
end;
$$;

revoke all on function public.usar_codigo_professor(text) from public, anon;
grant execute on function public.usar_codigo_professor(text) to authenticated;

-- Desempenho: o professor agora é reconhecido pelo vínculo do código, não
-- pelo e-mail. O resto da função é igual ao da 0014.
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
      and pc.professor_auth_user_id = auth.uid()
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

-- Painel do professor: as crianças cujos códigos ele usou.
create or replace function public.painel_professor(p_dias int default 30)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
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
    where pc.professor_auth_user_id = auth.uid()
      and exists (
        select 1 from public.professores pr where pr.auth_user_id = auth.uid()
      )
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.painel_professor(int) from public, anon;
grant execute on function public.painel_professor(int) to authenticated;

-- O e-mail não serve mais de prova: ninguém usa esta função.
drop function if exists public.email_do_professor_logado();
