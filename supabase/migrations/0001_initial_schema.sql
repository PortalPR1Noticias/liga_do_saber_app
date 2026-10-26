-- Liga do Saber - schema inicial do MVP
-- Execute este arquivo no Supabase SQL Editor quando o projeto Supabase estiver criado.

create extension if not exists "pgcrypto";

create table if not exists public.responsaveis (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique not null references auth.users(id) on delete cascade,
  nome text not null,
  email text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.perfis_criancas (
  id uuid primary key default gen_random_uuid(),
  responsavel_id uuid not null references public.responsaveis(id) on delete cascade,
  apelido text not null,
  ano_escolar int not null,
  avatar_id text not null default 'estrategista',
  areas_foco text[] not null default '{}',
  nivel int not null default 1,
  xp_total int not null default 0,
  sequencia_dias int not null default 0,
  ultima_atividade_em timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.materias (
  id text primary key,
  nome text not null,
  descricao text,
  personagem_id text,
  ordem int not null default 0,
  ativa boolean not null default true
);

create table if not exists public.habilidades (
  id text primary key,
  materia_id text not null references public.materias(id),
  nome text not null,
  descricao text,
  ano_escolar_min int,
  ano_escolar_max int,
  ativa boolean not null default true
);

create table if not exists public.missoes (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  descricao text,
  tipo text not null,
  materia_id text references public.materias(id),
  habilidade_id text references public.habilidades(id),
  dificuldade text not null default 'iniciante',
  xp_base int not null default 20,
  conteudo jsonb not null default '{}'::jsonb,
  ativa boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.progresso_missoes (
  id uuid primary key default gen_random_uuid(),
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  missao_id uuid not null references public.missoes(id) on delete cascade,
  status text not null default 'em_andamento',
  tentativas int not null default 0,
  xp_recebido int not null default 0,
  iniciada_em timestamptz not null default now(),
  concluida_em timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (perfil_crianca_id, missao_id)
);

create table if not exists public.atividades_foto (
  id uuid primary key default gen_random_uuid(),
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  storage_path text not null,
  materia_detectada text,
  tipo_atividade text,
  status text not null default 'enviada',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.correcoes_ia (
  id uuid primary key default gen_random_uuid(),
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  atividade_foto_id uuid references public.atividades_foto(id) on delete set null,
  missao_id uuid references public.missoes(id) on delete set null,
  tipo text not null,
  entrada_resumo text,
  resposta_json jsonb not null,
  xp_sugerido int not null default 0,
  modelo_usado text,
  created_at timestamptz not null default now()
);

create table if not exists public.producoes_textuais (
  id uuid primary key default gen_random_uuid(),
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  missao_id uuid references public.missoes(id) on delete set null,
  tema text not null,
  planejamento jsonb not null default '{}'::jsonb,
  texto_original text,
  texto_reescrito text,
  feedback_json jsonb,
  status text not null default 'rascunho',
  xp_recebido int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.badges (
  id text primary key,
  nome text not null,
  descricao text,
  icone text,
  criterio jsonb not null default '{}'::jsonb,
  ativa boolean not null default true
);

create table if not exists public.badges_criancas (
  id uuid primary key default gen_random_uuid(),
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  badge_id text not null references public.badges(id) on delete cascade,
  conquistado_em timestamptz not null default now(),
  unique (perfil_crianca_id, badge_id)
);

insert into public.materias (id, nome, descricao, personagem_id, ordem)
values
  ('portugues', 'Portugues', 'Leitura, interpretacao e producao textual.', 'luma', 1),
  ('matematica', 'Matematica', 'Calculo, logica e resolucao de problemas.', 'nico', 2),
  ('ciencias', 'Ciencias', 'Descobertas sobre natureza, corpo humano e ambiente.', 'teo', 3),
  ('historia', 'Historia', 'Tempo, fontes, imagens e acontecimentos.', 'mila', 4),
  ('geografia', 'Geografia', 'Mapas, lugares, paisagens e territorio.', 'teo', 5),
  ('criatividade', 'Criatividade', 'Projetos, ideias e desafios mistos.', 'zuri', 6)
on conflict (id) do nothing;

insert into public.habilidades (id, materia_id, nome, descricao, ano_escolar_min, ano_escolar_max)
values
  ('ideia_principal', 'portugues', 'Ideia principal', 'Identificar o assunto central de um texto.', 3, 7),
  ('inferencia', 'portugues', 'Inferencia', 'Concluir informacoes a partir de pistas no texto.', 3, 7),
  ('producao_paragrafo', 'portugues', 'Producao de paragrafo', 'Organizar ideias em um paragrafo claro.', 3, 7),
  ('operacoes_basicas', 'matematica', 'Operacoes basicas', 'Resolver adicao, subtracao, multiplicacao e divisao.', 3, 7),
  ('fracoes_simples', 'matematica', 'Fracoes simples', 'Compreender e resolver problemas com fracoes iniciais.', 4, 7)
on conflict (id) do nothing;

insert into public.badges (id, nome, descricao, icone, criterio)
values
  ('primeiro_passo', 'Primeiro Passo', 'Concluiu a primeira missao.', 'rocket', '{"missoes_concluidas":1}'),
  ('detetive_leitura', 'Detetive da Leitura', 'Concluiu 5 casos de leitura.', 'search', '{"casos_leitura":5}'),
  ('texto_melhorado', 'Texto Melhorado', 'Reescreveu 3 textos.', 'edit', '{"textos_reescritos":3}'),
  ('estrategista', 'Estrategista', 'Concluiu 10 desafios matematicos.', 'calculate', '{"desafios_matematica":10}')
on conflict (id) do nothing;

alter table public.responsaveis enable row level security;
alter table public.perfis_criancas enable row level security;
alter table public.progresso_missoes enable row level security;
alter table public.atividades_foto enable row level security;
alter table public.correcoes_ia enable row level security;
alter table public.producoes_textuais enable row level security;
alter table public.badges_criancas enable row level security;

create policy "responsaveis_select_own"
on public.responsaveis for select
using (auth.uid() = auth_user_id);

create policy "responsaveis_insert_own"
on public.responsaveis for insert
with check (auth.uid() = auth_user_id);

create policy "responsaveis_update_own"
on public.responsaveis for update
using (auth.uid() = auth_user_id)
with check (auth.uid() = auth_user_id);

create policy "perfis_criancas_owner_all"
on public.perfis_criancas for all
using (
  exists (
    select 1 from public.responsaveis r
    where r.id = perfis_criancas.responsavel_id
      and r.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.responsaveis r
    where r.id = perfis_criancas.responsavel_id
      and r.auth_user_id = auth.uid()
  )
);

create policy "progresso_owner_all"
on public.progresso_missoes for all
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = progresso_missoes.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = progresso_missoes.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

create policy "atividades_foto_owner_all"
on public.atividades_foto for all
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = atividades_foto.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = atividades_foto.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

create policy "correcoes_ia_owner_select"
on public.correcoes_ia for select
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = correcoes_ia.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

create policy "producoes_textuais_owner_all"
on public.producoes_textuais for all
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = producoes_textuais.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = producoes_textuais.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

create policy "badges_criancas_owner_select"
on public.badges_criancas for select
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = badges_criancas.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);
