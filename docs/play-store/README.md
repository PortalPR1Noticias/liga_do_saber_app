# Publicar a Liga do Saber na Google Play

Passo a passo do que falta para mandar o app à loja. A ficha com os textos está em [ficha-da-loja.md](ficha-da-loja.md); as respostas de LGPD e Segurança dos dados estão em [../lgpd/README.md](../lgpd/README.md).

## O que já está pronto no projeto

| Item | Situação |
| --- | --- |
| ID do app | `br.com.gplabs.liga_do_saber_app` (não muda depois da 1ª publicação) |
| Nome no celular | "Liga do Saber" (`AndroidManifest.xml` e `Info.plist`) |
| Versão | `1.0.0+1` no `pubspec.yaml` (versionName 1.0.0, versionCode 1) |
| targetSdk / compileSdk | 36 (Android 16), o exigido para apps novos |
| Ícone | Emblema oficial em todas as densidades, com ícone adaptativo (Android 8+) |
| Assinatura de release | Lê `android/key.properties`; sem ele cai na chave de debug (a loja recusa) |
| Permissões | Só `INTERNET`. A câmera e a galeria usam o seletor do sistema, sem permissão extra. `AD_ID` removida |
| Backup | Desligado (`allowBackup=false`), para a sessão do responsável não sair do aparelho |
| Páginas públicas | Privacidade, Termos e Exclusão de conta geradas de `assets/legal` e `site/` e publicadas pelo workflow `.github/workflows/site.yml` |
| Imagens da loja | `docs/play-store/imagens/` (ícone 512 e gráfico 1024 × 500) |

## 1. Criar a chave de upload (uma vez só)

No PC, no PowerShell (o `keytool` vem com o Android Studio, em `C:\Program Files\Android\Android Studio\jbr\bin`):

```
mkdir C:\projetos\chaves
keytool -genkey -v -keystore C:\projetos\chaves\liga-do-saber-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Depois copie `android/key.properties.example` para `android/key.properties` e preencha as senhas. Esse arquivo e o `.jks` nunca vão para o GitHub (estão no `.gitignore`).

Guarde o `.jks` e as senhas num lugar seguro fora do PC (gerenciador de senhas ou pendrive). Com a Assinatura de apps do Google Play ligada (padrão), perder essa chave tem conserto pelo suporte, mas dá trabalho.

## 2. Gerar o pacote (.aab)

```
cd C:\projetos\liga_do_saber_app
flutter clean
flutter build appbundle --release
```

O arquivo sai em `build\app\outputs\bundle\release\app-release.aab`. A URL e a chave publishable do Supabase já estão como padrão em `lib/app/supabase_config.dart`; para outro projeto, passe `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`.

A cada nova versão enviada, aumente o número depois do `+` no `pubspec.yaml` (1.0.0+2, 1.0.1+3...). A loja recusa um versionCode repetido.

## 3. Ligar as páginas públicas

1. No GitHub: Settings > Pages > Build and deployment > Source: **GitHub Actions**.
2. Depois do merge na main, o workflow "Site público" publica em `https://portalpr1noticias.github.io/liga_do_saber_app/`.
3. Endereços para o Play Console:
   - Política de Privacidade: `https://portalpr1noticias.github.io/liga_do_saber_app/privacidade.html`
   - Exclusão de conta: `https://portalpr1noticias.github.io/liga_do_saber_app/excluir-conta.html`

Para ver as páginas no PC antes: `python site/gerar_site.py` e abra `site/_publico/index.html`.

## 4. Checklist do Play Console

Conta de desenvolvedor:
- [ ] Criar a conta em play.google.com/console (taxa única de US$ 25). Como empresa (GPLABS) precisa de D-U-N-S; como pessoa física, de documento e verificação de endereço.
- [ ] Contas pessoais criadas depois de nov/2023: antes de publicar em produção, rodar um **teste fechado com pelo menos 12 testadores por 14 dias seguidos**. Junte familiares e amigos com conta Google.

Criar o app (Todos os apps > Criar app): nome "Liga do Saber", idioma Português (Brasil), App, Gratuito.

Configurar o app (Painel > Configurar o app):
- [ ] **Política de Privacidade**: link do item 3.
- [ ] **Acesso ao app**: "Todas ou algumas funcionalidades são restritas". Crie uma conta de teste (e-mail e senha de responsável, com um perfil de criança já criado) e informe aqui, junto com a resposta da pergunta da Área dos responsáveis ("é uma conta de multiplicação na tela").
- [ ] **Anúncios**: Não, o app não contém anúncios.
- [ ] **Classificação do conteúdo**: questionário IARC conforme a ficha.
- [ ] **Público-alvo e conteúdo**: 6 a 8, 9 a 12 e 13 a 15 anos; responder às perguntas da política Famílias.
- [ ] **Apps de notícias**: Não.
- [ ] **Segurança dos dados**: tabela em `docs/lgpd/README.md`. Também marcar "dados criptografados em trânsito" e informar o link de exclusão de conta do item 3.
- [ ] **Exclusão de conta**: link de `excluir-conta.html`.
- [ ] **Apps governamentais / Recursos financeiros / Saúde**: Não.
- [ ] **Conteúdo gerado por IA**: declarar que o app gera conteúdo com IA (explicações, casos de leitura, desafios e devolutivas) e que o usuário denuncia respostas impróprias pela bandeira "Avisar um problema" no topo de cada tela com IA.
- [ ] **Categoria e contato**: Educação, e-mail de contato, site.
- [ ] **Página principal da loja**: textos e imagens da ficha, mais as capturas de tela.

Enviar:
- [ ] Testes > Teste interno: criar versão, enviar o `app-release.aab`, aceitar a Assinatura de apps do Google Play, testar no seu celular pelo link de teste.
- [ ] Teste fechado com os 12 testadores (se a conta for pessoal), 14 dias.
- [ ] Produção > Criar versão > enviar para revisão. A primeira revisão de app infantil costuma levar de alguns dias a uma semana.

## 5. Pendências antes de enviar

- [ ] Dados da GPLABS nos textos legais e na página de exclusão: `[RAZÃO SOCIAL]`, `[CNPJ]`, `[ENDEREÇO]`, `[NOME DO ENCARREGADO]`, `[E-MAIL DE PRIVACIDADE]`, `[E-MAIL DE CONTATO]` em `assets/legal/*.md`, `site/excluir_conta.md` e `site/index.md`.
- [ ] Migrations 0003, 0004 e 0005 aplicadas no Supabase e as Edge Functions publicadas com o secret `OPENAI_API_KEY` (ver `supabase/functions/README.md`). Sem isso a revisão do Google encontra telas com erro.
- [ ] **Denúncia de conteúdo da IA**: o botão já existe (bandeira "Avisar um problema" no topo das telas com IA) e grava em `denuncias_ia`. Falta rodar a migration `0012_denuncias_ia.sql` e olhar as denúncias de tempos em tempos: `select * from public.denuncias_ia order by created_at desc;`.
- [ ] Testar o `.aab` num celular real (cadastro, Foto + IA, exclusão de conta) antes de mandar para produção.
