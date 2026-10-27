-- Liga do Saber - Trilha do Teo (Ciências e Geografia).
-- Execute depois do 0004_lgpd.sql no Supabase SQL Editor.
--
-- A Edge Function `expedicao-teo` dá XP com a origem 'expedicao' pela
-- public.conceder_xp (migration 0003). Aqui entram a missão do dia e a
-- medalha dessa origem.

insert into public.missoes (codigo, titulo, descricao, tipo, materia_id, xp_base, icone, ordem)
values
  ('expedicao_teo', 'Desvendar uma expedição do Teo',
   'Resolva uma investigação de Ciências ou Geografia na Trilha do Teo.',
   'expedicao', null, 20, 'explore', 5)
on conflict (codigo) do nothing;

insert into public.badges (id, nome, descricao, icone, criterio)
values
  ('explorador', 'Explorador da Liga', 'Desvendou 10 expedições com o Teo.',
   'explore', '{"origem":"expedicao","quantidade":10}')
on conflict (id) do nothing;
