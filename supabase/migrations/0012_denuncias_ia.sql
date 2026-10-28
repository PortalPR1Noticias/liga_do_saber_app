-- Liga do Saber - Denúncia de conteúdo da IA.
-- Execute depois das migrations anteriores no Supabase SQL Editor.
-- (0010 e 0011 são do modo jogo; esta não depende delas.)
--
-- A política de conteúdo gerado por IA do Google Play pede que o usuário
-- possa sinalizar, dentro do app, uma resposta imprópria. O botão
-- "Avisar um problema" (bandeira no topo das telas com IA) grava aqui.
--
-- Para ver as denúncias no painel:
--   select * from public.denuncias_ia order by created_at desc;

create table if not exists public.denuncias_ia (
  id uuid primary key default gen_random_uuid(),
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  -- Tela de onde veio: foto, leitura, texto, matematica, expedicao,
  -- arquivo, atelie, minijogo, revanche.
  modulo text not null check (char_length(modulo) <= 40),
  motivo text not null check (motivo in ('improprio', 'errado', 'outro')),
  comentario text check (char_length(comentario) <= 500),
  -- Id do conteúdo (caso, desafio, prova...), quando a tela tem um.
  referencia text check (char_length(referencia) <= 100),
  resolvida boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists denuncias_ia_data_idx
  on public.denuncias_ia (created_at desc);

alter table public.denuncias_ia enable row level security;

-- O responsável grava e vê só as denúncias dos próprios perfis. Mudar o
-- status (resolvida) fica para o painel, com a chave de serviço.
drop policy if exists "denuncias_ia_owner_insert" on public.denuncias_ia;
create policy "denuncias_ia_owner_insert"
on public.denuncias_ia for insert
to authenticated
with check (
  resolvida = false
  and exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = denuncias_ia.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

drop policy if exists "denuncias_ia_owner_select" on public.denuncias_ia;
create policy "denuncias_ia_owner_select"
on public.denuncias_ia for select
to authenticated
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = denuncias_ia.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

grant select, insert on public.denuncias_ia to authenticated;
