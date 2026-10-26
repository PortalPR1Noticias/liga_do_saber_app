-- Liga do Saber - ajustes de segurança e manutenção sobre o 0001.
-- Execute depois do 0001_initial_schema.sql no Supabase SQL Editor.

-- 1) RLS nas tabelas de catálogo.
-- Sem RLS, qualquer pessoa com a chave anon do app consegue inserir,
-- alterar ou apagar matérias, habilidades, missões e badges pela API.
-- Agora usuários logados só podem ler; a escrita fica com a service role.
alter table public.materias enable row level security;
alter table public.habilidades enable row level security;
alter table public.missoes enable row level security;
alter table public.badges enable row level security;

drop policy if exists "materias_select_autenticados" on public.materias;
create policy "materias_select_autenticados"
on public.materias for select
to authenticated
using (ativa);

drop policy if exists "habilidades_select_autenticados" on public.habilidades;
create policy "habilidades_select_autenticados"
on public.habilidades for select
to authenticated
using (ativa);

drop policy if exists "missoes_select_autenticados" on public.missoes;
create policy "missoes_select_autenticados"
on public.missoes for select
to authenticated
using (ativa);

drop policy if exists "badges_select_autenticados" on public.badges;
create policy "badges_select_autenticados"
on public.badges for select
to authenticated
using (ativa);

-- 2) updated_at automático (as colunas existiam, mas nada as atualizava).
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'responsaveis',
    'perfis_criancas',
    'missoes',
    'progresso_missoes',
    'atividades_foto',
    'producoes_textuais'
  ]
  loop
    execute format('drop trigger if exists set_updated_at on public.%I', t);
    execute format(
      'create trigger set_updated_at before update on public.%I '
      'for each row execute function public.set_updated_at()',
      t
    );
  end loop;
end;
$$;

-- 3) Índices nas chaves estrangeiras usadas pelas políticas de RLS.
create index if not exists perfis_criancas_responsavel_id_idx
  on public.perfis_criancas (responsavel_id);
create index if not exists progresso_missoes_missao_id_idx
  on public.progresso_missoes (missao_id);
create index if not exists atividades_foto_perfil_crianca_id_idx
  on public.atividades_foto (perfil_crianca_id);
create index if not exists correcoes_ia_perfil_crianca_id_idx
  on public.correcoes_ia (perfil_crianca_id);
create index if not exists producoes_textuais_perfil_crianca_id_idx
  on public.producoes_textuais (perfil_crianca_id);
create index if not exists badges_criancas_badge_id_idx
  on public.badges_criancas (badge_id);
create index if not exists habilidades_materia_id_idx
  on public.habilidades (materia_id);

-- 4) Acentuação dos textos exibidos para as crianças.
update public.materias set nome = 'Português',
  descricao = 'Leitura, interpretação e produção textual.'
where id = 'portugues';
update public.materias set nome = 'Matemática',
  descricao = 'Cálculo, lógica e resolução de problemas.'
where id = 'matematica';
update public.materias set nome = 'Ciências' where id = 'ciencias';
update public.materias set nome = 'História' where id = 'historia';
update public.materias set descricao = 'Mapas, lugares, paisagens e território.'
where id = 'geografia';

update public.habilidades set nome = 'Inferência',
  descricao = 'Concluir informações a partir de pistas no texto.'
where id = 'inferencia';
update public.habilidades set nome = 'Produção de parágrafo'
where id = 'producao_paragrafo';
update public.habilidades set nome = 'Operações básicas',
  descricao = 'Resolver adição, subtração, multiplicação e divisão.'
where id = 'operacoes_basicas';
update public.habilidades set nome = 'Frações simples',
  descricao = 'Compreender e resolver problemas com frações iniciais.'
where id = 'fracoes_simples';

update public.badges set descricao = 'Concluiu a primeira missão.'
where id = 'primeiro_passo';
update public.badges set descricao = 'Concluiu 10 desafios matemáticos.'
where id = 'estrategista';
