-- Liga do Saber - Jogos da Liga (caça-palavras, quebra-cabeça e Desafio
-- Relâmpago). Execute depois do 0005_trilha_do_teo.sql no Supabase SQL
-- Editor (a 0006 e a 0007 são dos módulos da Mila e do Zuri; esta não
-- depende delas).
--
-- A Edge Function `minijogo` dá XP com a origem 'minijogo' pela
-- public.conceder_xp (migration 0003). Aqui entram a missão do dia e a
-- medalha dessa origem.

insert into public.missoes (codigo, titulo, descricao, tipo, materia_id, xp_base, icone, ordem)
values
  ('jogar_minijogo', 'Vencer um Jogo da Liga',
   'Complete um caça-palavras, um quebra-cabeça ou um Desafio Relâmpago.',
   'minijogo', null, 15, 'extension', 8)
on conflict (codigo) do nothing;

insert into public.badges (id, nome, descricao, icone, criterio)
values
  ('mestre_dos_jogos', 'Mestre dos Jogos', 'Venceu 10 Jogos da Liga.',
   'extension', '{"origem":"minijogo","quantidade":10}')
on conflict (id) do nothing;
