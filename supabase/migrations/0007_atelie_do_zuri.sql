-- Liga do Saber - Ateliê do Zuri (criatividade, projetos e mapas mentais).
-- Execute depois do 0006_arquivo_da_mila.sql no Supabase SQL Editor (a
-- ordem entre 0006 e 0007 não importa: uma não depende da outra).
--
-- A Edge Function `atelie-zuri` dá XP pela public.conceder_xp (migration
-- 0003) com duas origens: 'atelie' (minijogos) e
-- 'projeto' (mapa mental do projeto da criança). Aqui entram a missão do dia
-- e as medalhas dessas origens.

insert into public.missoes (codigo, titulo, descricao, tipo, materia_id, xp_base, icone, ordem)
values
  ('atelie_zuri', 'Jogar no Ateliê do Zuri',
   'Vença um minijogo (caça-palavras, mapa mental ou quebra-cabeça) no Ateliê do Zuri.',
   'atelie', null, 20, 'lightbulb', 7)
on conflict (codigo) do nothing;

insert into public.badges (id, nome, descricao, icone, criterio)
values
  ('inventor', 'Inventor da Liga', 'Venceu 10 jogos no Ateliê do Zuri.',
   'lightbulb', '{"origem":"atelie","quantidade":10}'),
  ('arquiteto_de_ideias', 'Arquiteto de Ideias',
   'Montou 3 mapas mentais de projetos com o Zuri.',
   'hub', '{"origem":"projeto","quantidade":3}')
on conflict (id) do nothing;
