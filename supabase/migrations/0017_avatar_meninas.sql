-- Liga do Saber: mais opções de avatar para meninas (e para quem quiser).
--
-- Cabelos longos, franja, chanel, rabo alto, coque duplo e trança; cílios;
-- vestidos, saias, leggings, sapatilhas, laços, tiaras e asas. Nenhuma peça
-- é separada por gênero: toda criança pode escolher qualquer uma.
-- nivel = nível da criança que libera; nulo = peça da Loja.

insert into public.pecas_avatar (id, categoria, nivel) values
  ('cabelo_ondulado', 'cabelo', 1),
  ('cabelo_longo_franja', 'cabelo', 1),
  ('cabelo_chanel', 'cabelo', 1),
  ('cabelo_rabo_alto', 'cabelo', 1),
  ('cabelo_coque_duplo', 'cabelo', 1),
  ('cabelo_tranca_lateral', 'cabelo', 1),
  ('cor_castanho_claro', 'cor_cabelo', 1),
  ('cor_loiro_claro', 'cor_cabelo', 1),
  ('cor_lilas', 'cor_cabelo', 2),
  ('olhos_cilios', 'olhos', 1),
  ('olhos_cilios_grandes', 'olhos', 1),
  ('olhos_piscadinha', 'olhos', 1),
  ('boca_doce', 'boca', 1),
  ('boca_brilho', 'boca', 1),
  ('camiseta_lilas', 'camisa', 1),
  ('blusa_coracao', 'camisa', 1),
  ('blusa_babado', 'camisa', 1),
  ('vestido_rosa', 'camisa', 1),
  ('vestido_floral', 'camisa', 1),
  ('vestido_amarelo', 'camisa', 1),
  ('moletom_rosa', 'camisa', 2),
  ('vestido_estrelas', 'camisa', 3),
  ('vestido_princesa', 'camisa', null),
  ('saia_jeans', 'calca', 1),
  ('legging_rosa', 'calca', 1),
  ('legging_lilas', 'calca', 1),
  ('shorts_jeans', 'calca', 1),
  ('saia_xadrez', 'calca', 2),
  ('saia_tule', 'calca', 4),
  ('sapatilha_rosa', 'tenis', 1),
  ('sapatilha_dourada', 'tenis', 1),
  ('tenis_rosa', 'tenis', 1),
  ('tenis_lilas', 'tenis', 1),
  ('tenis_brilho', 'tenis', 3),
  ('botas_cano_alto', 'tenis', null),
  ('laco_rosa', 'chapeu', 1),
  ('laco_vermelho', 'chapeu', 1),
  ('tiara_rosa', 'chapeu', 1),
  ('presilhas_estrela', 'chapeu', 1),
  ('tiara_flores', 'chapeu', 2),
  ('coroa_flores', 'chapeu', 5),
  ('orelhas_coelho', 'chapeu', null),
  ('oculos_gatinho', 'oculos', 1),
  ('oculos_coracao', 'oculos', 4),
  ('bolsa_transversal', 'costas', 1),
  ('capa_estrelas', 'costas', 6),
  ('asas_borboleta', 'costas', null)
on conflict (id) do update
  set categoria = excluded.categoria,
      nivel = excluded.nivel;

insert into public.catalogo_visuais (id, slot, preco, nivel_temporada) values
  ('vestido_princesa', 'roupa', 100, null),
  ('botas_cano_alto', 'roupa', 70, null),
  ('orelhas_coelho', 'roupa', 70, null),
  ('asas_borboleta', 'roupa', 130, null)
on conflict (id) do update
  set slot = excluded.slot,
      preco = excluded.preco,
      nivel_temporada = excluded.nivel_temporada;
