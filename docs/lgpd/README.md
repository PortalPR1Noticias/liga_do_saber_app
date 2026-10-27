# LGPD e Google Play: o que já está no app e o que falta fazer

Este guia acompanha a migration `supabase/migrations/0004_lgpd.sql` e os textos em `assets/legal/`.

## O que o app já faz

| Exigência | Onde está |
| --- | --- |
| Consentimento específico e em destaque do responsável (LGPD art. 14, § 1º) | Caixa obrigatória no cadastro (`auth_screen.dart`), gravada em `responsaveis.termos_versao` |
| Prova do consentimento (art. 8º, § 2º) | Tabela `consentimentos`, preenchida por gatilho a cada aceite ou mudança |
| Autorização separada para mandar dados da criança à IA (arts. 14 e 33) | Chave "Permitir a Foto + IA" na Área dos responsáveis; conferida no app e na Edge Function `explicar-foto` |
| Política de Privacidade e Termos de Uso em português | `assets/legal/*.md`, abertos no cadastro e na Área dos responsáveis |
| Acesso e portabilidade (art. 18, II e V) | "Baixar cópia dos dados" chama `exportar_meus_dados()` |
| Exclusão (art. 18, VI) e exclusão de conta exigida pelo Google Play | "Excluir conta e dados" chama `excluir_minha_conta()`, que apaga tudo em cascata |
| Retenção limitada (art. 15) | `aplicar_retencao()` no pg_cron, todo dia: explicações da IA com mais de 12 meses e contas sem login há 24 meses |
| Minimização (art. 14, § 4º) | Só apelido e ano escolar da criança; o campo pede apelido em vez de nome completo |
| Área dos responsáveis protegida da criança | Pergunta de multiplicação antes de entrar |
| Sem ID de publicidade | `AndroidManifest.xml` remove a permissão `AD_ID` |

## O que o Giovany precisa fazer

1. **Preencher os dados da empresa** nos dois arquivos de `assets/legal/`: razão social, CNPJ, endereço, nome e e-mail do encarregado (DPO). Os lugares estão marcados com colchetes, por exemplo `[CNPJ]`.
2. **Rodar a migration 0004** no SQL Editor do Supabase (depois da 0003). Se aparecer o aviso de pg_cron indisponível, ligue a extensão em Database > Extensions e rode de novo o último bloco do arquivo.
3. **Publicar a Política de Privacidade numa página pública** (o Google Play exige um link). Já está pronta: o workflow `.github/workflows/site.yml` publica o texto de `assets/legal/politica_de_privacidade.md` no GitHub Pages (passos em `docs/play-store/README.md`).
4. **Publicar uma página para pedir exclusão de conta pela web** (o Google Play exige isso além do botão no app). Já está pronta em `site/excluir_conta.md`, publicada junto com a política.
5. **OpenAI**: na conta da OpenAI, aceitar o Data Processing Addendum (DPA) e conferir que os dados da API não são usados para treinar modelos (é o padrão da API).
6. **Supabase**: aceitar o DPA do Supabase no painel (Settings > Legal). Anotar a região do projeto, porque ela entra na política (transferência internacional).

## Respostas para o Google Play Console

**Público-alvo e conteúdo**: faixas etárias de 6 a 8, 9 a 12 e 13 a 15 anos (ajuste se o público for outro). Como inclui crianças, o app entra na política Famílias: sem anúncios, sem SDKs de publicidade ou analytics que não sejam certificados para Famílias, e conteúdo adequado.

**Recursos com IA**: declarar que o app tem conteúdo gerado por IA (explicações da Foto + IA). A Edge Function já instrui a IA a recusar conteúdo impróprio.

**Segurança dos dados** (Data safety):

| Pergunta | Resposta |
| --- | --- |
| Coleta ou compartilha dados? | Sim, coleta |
| Dados criptografados em trânsito? | Sim |
| O usuário pode pedir a exclusão? | Sim (no app e na página web do item 4) |
| Informações pessoais: nome, e-mail | Coletados, obrigatórios, para funcionalidade do app e gerenciamento da conta |
| Fotos | Coletadas, opcionais, para funcionalidade do app; processadas de forma temporária, sem armazenamento |
| Atividade no app (progresso, textos escritos) | Coletados, obrigatórios, para funcionalidade do app |
| Compartilhamento com terceiros | Não. Supabase e OpenAI são prestadores de serviço agindo em nome do app, o que o Google não conta como compartilhamento |
| Localização, contatos, IDs de publicidade, dados financeiros | Não coletados |

## Quando mudar os textos legais

Altere os dois arquivos de `assets/legal/` e troque `LegalDocument.version` em `lib/features/legal/presentation/legal_document_screen.dart`. Contas novas gravam a versão nova. Para pedir um novo aceite das contas antigas, falta uma tela que compare `responsaveis.termos_versao` com a versão atual no login (ainda não existe).
