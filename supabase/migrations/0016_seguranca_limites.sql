-- Liga do Saber - revisão de segurança (out/2026).
-- Execute depois da 0015_avatar_perfil_ranking.sql no Supabase SQL Editor.
--
-- O que este arquivo faz:
--   1) limite de uso da IA sem brecha: cada chamada à OpenAI reserva uma
--      vaga antes (por criança, por família e no app todo). Antes as Edge
--      Functions só contavam e gravavam depois, então vários pedidos ao
--      mesmo tempo passavam do limite;
--   2) no máximo 10 perfis de criança por responsável (sem isso, criar
--      perfis multiplicava o limite diário da IA);
--   3) o login da criança não vira responsável nem professor;
--   4) a retenção (0004/0009) também apaga contas de professor paradas há
--      24 meses.

-- 1) Reservas de uso da IA. Só a service role (Edge Functions) mexe aqui.
create table if not exists public.uso_ia (
  id bigint generated always as identity primary key,
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  responsavel_id uuid not null references public.responsaveis(id) on delete cascade,
  tipo text not null check (char_length(tipo) <= 40),
  created_at timestamptz not null default now()
);

create index if not exists uso_ia_perfil_tipo_data_idx
  on public.uso_ia (perfil_crianca_id, tipo, created_at);
create index if not exists uso_ia_responsavel_data_idx
  on public.uso_ia (responsavel_id, created_at);
create index if not exists uso_ia_data_idx
  on public.uso_ia (created_at);

alter table public.uso_ia enable row level security;
revoke all on public.uso_ia from anon, authenticated;

-- Reserva uma chamada à IA. Trava a linha do responsável, então pedidos ao
-- mesmo tempo da mesma família entram em fila e não furam o limite.
-- Devolve 'ok' ou qual limite estourou: 'perfil', 'familia' ou 'global'.
create or replace function public.reservar_uso_ia(
  p_perfil uuid,
  p_tipo text,
  p_limite_perfil int,
  p_limite_familia int,
  p_limite_global int
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_responsavel uuid;
  v_desde timestamptz := now() - interval '24 hours';
begin
  select responsavel_id into v_responsavel
  from public.perfis_criancas
  where id = p_perfil;
  if not found then
    raise exception 'Perfil não encontrado';
  end if;

  perform 1 from public.responsaveis where id = v_responsavel for update;

  -- Reservas velhas não servem mais para nada.
  delete from public.uso_ia
  where responsavel_id = v_responsavel and created_at < now() - interval '2 days';

  if (select count(*) from public.uso_ia
      where perfil_crianca_id = p_perfil and tipo = p_tipo
        and created_at >= v_desde) >= p_limite_perfil then
    return 'perfil';
  end if;
  if (select count(*) from public.uso_ia
      where responsavel_id = v_responsavel
        and created_at >= v_desde) >= p_limite_familia then
    return 'familia';
  end if;
  if (select count(*) from public.uso_ia
      where created_at >= v_desde) >= p_limite_global then
    return 'global';
  end if;

  insert into public.uso_ia (perfil_crianca_id, responsavel_id, tipo)
  values (p_perfil, v_responsavel, p_tipo);
  return 'ok';
end;
$$;

revoke all on function public.reservar_uso_ia(uuid, text, int, int, int)
  from public, anon, authenticated;
grant execute on function public.reservar_uso_ia(uuid, text, int, int, int)
  to service_role;

-- 2) Até 10 crianças por responsável.
create or replace function public.limitar_perfis_por_responsavel()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform 1 from public.responsaveis where id = new.responsavel_id for update;
  if (select count(*) from public.perfis_criancas
      where responsavel_id = new.responsavel_id) >= 10 then
    raise exception 'Cada conta pode ter até 10 crianças.' using errcode = '23514';
  end if;
  return new;
end;
$$;

revoke all on function public.limitar_perfis_por_responsavel() from public, anon, authenticated;

drop trigger if exists limitar_perfis_por_responsavel on public.perfis_criancas;
create trigger limitar_perfis_por_responsavel
before insert on public.perfis_criancas
for each row execute function public.limitar_perfis_por_responsavel();

-- 3) A criança logada não cria cadastro de responsável nem de professor
--    (políticas da 0001 e da 0014, agora com a trava).
drop policy if exists "responsaveis_insert_own" on public.responsaveis;
create policy "responsaveis_insert_own"
on public.responsaveis for insert
with check (
  auth.uid() = auth_user_id
  and public.perfil_da_crianca_logada() is null
);

drop policy if exists "professores_insert_own" on public.professores;
create policy "professores_insert_own"
on public.professores for insert
to authenticated
with check (
  auth_user_id = auth.uid()
  and public.perfil_da_crianca_logada() is null
);

-- 4) Retenção. Mesmo corpo da 0009, agora com os professores.
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

  delete from public.uso_ia
  where created_at < now() - interval '2 days';

  delete from auth.users u
  where coalesce(u.last_sign_in_at, u.created_at) < now() - interval '24 months'
    and (
      exists (select 1 from public.responsaveis r where r.auth_user_id = u.id)
      or exists (select 1 from public.professores p where p.auth_user_id = u.id)
    );
end;
$$;

revoke all on function public.aplicar_retencao() from public, anon, authenticated;

-- 5) Função de gatilho da 0004 sem execução direta pela API (não fazia
--    nada fora do gatilho, mas fica fechada como as outras).
revoke all on function public.registrar_consentimento() from public, anon, authenticated;
