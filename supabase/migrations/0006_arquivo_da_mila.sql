-- Liga do Saber - Arquivo da Mila (História).
-- Execute depois do 0005_trilha_do_teo.sql no Supabase SQL Editor.
--
-- A Edge Function `arquivo-mila` dá XP com a origem 'arquivo' pela
-- public.conceder_xp (migration 0003). Aqui entram a missão do dia e a
-- medalha dessa origem.

insert into public.missoes (codigo, titulo, descricao, tipo, materia_id, xp_base, icone, ordem)
values
  ('arquivo_mila', 'Resolver um caso do Arquivo da Mila',
   'Analise um documento histórico ou monte uma linha do tempo com a Mila.',
   'arquivo', null, 20, 'history_edu', 6)
on conflict (codigo) do nothing;

insert into public.badges (id, nome, descricao, icone, criterio)
values
  ('historiador', 'Historiador da Liga', 'Resolveu 10 casos com a Mila.',
   'history_edu', '{"origem":"arquivo","quantidade":10}')
on conflict (id) do nothing;
