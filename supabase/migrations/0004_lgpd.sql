-- Liga do Saber - LGPD (Lei 13.709/2018), com foco no art. 14 (dados de
-- crianças e adolescentes). Execute depois das migrations 0001 a 0003.
--
-- O que este arquivo faz:
--   1) guarda o consentimento do responsável (termos/política e uso da IA);
--   2) registra cada mudança de consentimento num histórico (prova do art. 8);
--   3) dá ao responsável a cópia dos dados e a exclusão da conta (art. 18);
--   4) apaga dados antigos automaticamente (retenção, art. 15 e 16).

-- 1) Consentimento do responsável.
alter table public.responsaveis
  add column if not exists termos_versao text,
  add column if not exists termos_aceitos_em timestamptz,
  add column if not exists autoriza_ia boolean not null default false,
  add column if not exists autoriza_ia_em timestamptz;

-- 2) Histórico de consentimentos. Só o gatilho abaixo escreve aqui; o
-- responsável pode ler o próprio histórico.
create table if not exists public.consentimentos (
  id uuid primary key default gen_random_uuid(),
  responsavel_id uuid not null references public.responsaveis(id) on delete cascade,
  tipo text not null check (tipo in ('termos_e_privacidade', 'ia')),
  versao text,
  concedido boolean not null,
  created_at timestamptz not null default now()
);

create index if not exists consentimentos_responsavel_id_idx
  on public.consentimentos (responsavel_id);

alter table public.consentimentos enable row level security;

drop policy if exists "consentimentos_select_own" on public.consentimentos;
create policy "consentimentos_select_own"
on public.consentimentos for select
using (
  exists (
    select 1 from public.responsaveis r
    where r.id = consentimentos.responsavel_id
      and r.auth_user_id = auth.uid()
  )
);

-- Antes de gravar: carimba as datas de aceite.
create or replace function public.carimbar_consentimento()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.termos_versao is not null and (
    tg_op = 'INSERT' or new.termos_versao is distinct from old.termos_versao
  ) then
    new.termos_aceitos_em = now();
  end if;
  if (tg_op = 'INSERT' and new.autoriza_ia)
    or (tg_op = 'UPDATE' and new.autoriza_ia is distinct from old.autoriza_ia)
  then
    new.autoriza_ia_em = now();
  end if;
  return new;
end;
$$;

-- Depois de gravar: escreve no histórico (precisa do responsável já salvo
-- por causa da chave estrangeira).
create or replace function public.registrar_consentimento()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.termos_versao is not null and (
    tg_op = 'INSERT' or new.termos_versao is distinct from old.termos_versao
  ) then
    insert into public.consentimentos (responsavel_id, tipo, versao, concedido)
    values (new.id, 'termos_e_privacidade', new.termos_versao, true);
  end if;
  if (tg_op = 'INSERT' and new.autoriza_ia)
    or (tg_op = 'UPDATE' and new.autoriza_ia is distinct from old.autoriza_ia)
  then
    insert into public.consentimentos (responsavel_id, tipo, versao, concedido)
    values (new.id, 'ia', new.termos_versao, new.autoriza_ia);
  end if;
  return null;
end;
$$;

drop trigger if exists carimbar_consentimento on public.responsaveis;
create trigger carimbar_consentimento
before insert or update of termos_versao, autoriza_ia on public.responsaveis
for each row execute function public.carimbar_consentimento();

drop trigger if exists registrar_consentimento on public.responsaveis;
create trigger registrar_consentimento
after insert or update of termos_versao, autoriza_ia on public.responsaveis
for each row execute function public.registrar_consentimento();

-- 3a) O responsável pode apagar o histórico de correções da IA da criança
-- (antes só podia ler).
drop policy if exists "correcoes_ia_owner_delete" on public.correcoes_ia;
create policy "correcoes_ia_owner_delete"
on public.correcoes_ia for delete
using (
  exists (
    select 1
    from public.perfis_criancas p
    join public.responsaveis r on r.id = p.responsavel_id
    where p.id = correcoes_ia.perfil_crianca_id
      and r.auth_user_id = auth.uid()
  )
);

-- 3b) Cópia de todos os dados da conta, em JSON. Roda com as permissões de
-- quem chama, então o RLS garante que só vêm os dados do próprio responsável.
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

-- 3c) Exclusão definitiva da conta. Apagar o usuário do Auth leva junto, em
-- cascata, o responsável, os perfis das crianças e tudo ligado a eles.
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
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.excluir_minha_conta() from public, anon;
grant execute on function public.excluir_minha_conta() to authenticated;

-- 4) Retenção. Os prazos estão na Política de Privacidade
-- (assets/legal/politica_de_privacidade.md); mude os dois juntos.
--   - explicações da Foto + IA: 12 meses;
--   - contas sem nenhum login há 24 meses: excluídas por inteiro.
create or replace function public.aplicar_retencao()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.correcoes_ia
  where created_at < now() - interval '12 months';

  delete from auth.users u
  where coalesce(u.last_sign_in_at, u.created_at) < now() - interval '24 months'
    and exists (select 1 from public.responsaveis r where r.auth_user_id = u.id);
end;
$$;

revoke all on function public.aplicar_retencao() from public, anon, authenticated;

-- Agenda a retenção todo dia às 3h (UTC) com o pg_cron do Supabase. Se o
-- pg_cron não estiver disponível, ative em Database > Extensions e rode de
-- novo só este bloco.
do $$
begin
  create extension if not exists pg_cron;
  perform cron.unschedule('liga_retencao_lgpd')
  where exists (select 1 from cron.job where jobname = 'liga_retencao_lgpd');
  perform cron.schedule(
    'liga_retencao_lgpd',
    '0 3 * * *',
    'select public.aplicar_retencao()'
  );
exception when others then
  raise notice 'pg_cron indisponível (%). Agende public.aplicar_retencao() depois.', sqlerrm;
end;
$$;
