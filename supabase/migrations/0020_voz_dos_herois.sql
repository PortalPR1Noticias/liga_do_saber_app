-- Liga do Saber - voz dos heróis (out/2026).
-- Execute depois da 0019 (e da 0018, se já existir) no Supabase SQL Editor.
--
-- A Edge Function voz-heroi transforma as explicações dos heróis em áudio
-- (text-to-speech da OpenAI). Cada áudio reserva uma vaga aqui antes de
-- chamar a OpenAI, como a reservar_uso_ia da 0016, mas numa conta separada:
-- ouvir explicações não gasta a cota diária da IA de texto da família.
-- Só a service role (Edge Functions) mexe nesta tabela. Não guarda o texto
-- nem o áudio, só quem pediu e quando.

create table if not exists public.uso_voz (
  id bigint generated always as identity primary key,
  perfil_crianca_id uuid not null references public.perfis_criancas(id) on delete cascade,
  responsavel_id uuid not null references public.responsaveis(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists uso_voz_perfil_data_idx
  on public.uso_voz (perfil_crianca_id, created_at);
create index if not exists uso_voz_responsavel_data_idx
  on public.uso_voz (responsavel_id, created_at);
create index if not exists uso_voz_data_idx
  on public.uso_voz (created_at);

alter table public.uso_voz enable row level security;
revoke all on public.uso_voz from anon, authenticated;

-- Reserva um áudio. Devolve 'ok' ou qual limite estourou: 'perfil',
-- 'familia' ou 'global'. Trava a linha do responsável, então pedidos ao
-- mesmo tempo da mesma família entram em fila e não furam o limite.
create or replace function public.reservar_uso_voz(
  p_perfil uuid,
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

  -- Reservas velhas não servem mais para nada (de ninguém).
  delete from public.uso_voz where created_at < now() - interval '2 days';

  if (select count(*) from public.uso_voz
      where perfil_crianca_id = p_perfil
        and created_at >= v_desde) >= p_limite_perfil then
    return 'perfil';
  end if;
  if (select count(*) from public.uso_voz
      where responsavel_id = v_responsavel
        and created_at >= v_desde) >= p_limite_familia then
    return 'familia';
  end if;
  if (select count(*) from public.uso_voz
      where created_at >= v_desde) >= p_limite_global then
    return 'global';
  end if;

  insert into public.uso_voz (perfil_crianca_id, responsavel_id)
  values (p_perfil, v_responsavel);
  return 'ok';
end;
$$;

revoke all on function public.reservar_uso_voz(uuid, int, int, int)
  from public, anon, authenticated;
grant execute on function public.reservar_uso_voz(uuid, int, int, int)
  to service_role;
