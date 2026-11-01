# Publicar a Liga do Saber na App Store (iPhone e iPad)

Este guia é para quem **não tem Mac**. Toda a parte que precisa de Mac roda num Mac da nuvem do GitHub (workflow `.github/workflows/ios.yml`). Você só usa o navegador.

## O que já está pronto no projeto

| Item | Situação |
| --- | --- |
| ID do app (Bundle ID) | `br.com.gplabs.ligaDoSaberApp` (não muda depois da 1ª publicação) |
| Nome no iPhone | "Liga do Saber" |
| Versão | `1.0.0` do `pubspec.yaml`; o número do build sobe sozinho a cada envio |
| iOS mínimo | iOS 15 (iPhone 6s em diante) |
| Ícone | Emblema oficial em todos os tamanhos, sem transparência |
| Permissões | Câmera e galeria, com texto em português |
| Criptografia | Declarada como "não usa criptografia própria", o TestFlight não pergunta mais |
| Exclusão de conta | Dentro do app (Área dos responsáveis > Excluir conta e dados) e na página pública |
| Política de privacidade | https://portalpr1noticias.github.io/liga_do_saber_app/ |
| Compilação | A cada PR e merge, o GitHub compila o app para iPhone e testa |

## Passo 1. Criar a conta Apple Developer (US$ 99 por ano)

1. Ative a verificação em duas etapas no seu ID Apple (em https://account.apple.com, "Segurança"). A Apple exige.
2. Entre em https://developer.apple.com/programs/enroll/ e clique em **Start Your Enrollment**.
3. Escolha o tipo de conta:
   - **Pessoa física (Individual):** mais rápido, sai em 1 ou 2 dias. Na loja aparece seu nome como vendedor.
   - **Empresa (Organization):** aparece "GPLABS". Precisa de CNPJ e de um número **D-U-N-S** (gratuito, pedido em https://developer.apple.com/enroll/duns-lookup/, leva de 5 a 14 dias).
4. Pague os US$ 99 com cartão internacional. A aprovação chega por e-mail.

> Dica: se quiser "GPLABS" na loja, peça o D-U-N-S primeiro. Dá para começar como pessoa física e migrar depois, mas a migração também passa pelo suporte.

## Passo 2. Registrar o ID do app

1. Entre em https://developer.apple.com/account/resources/identifiers/list
2. Clique no **+**, escolha **App IDs** > **App** > Continue.
3. Descrição: `Liga do Saber`. Bundle ID: **Explicit**, `br.com.gplabs.ligaDoSaberApp`.
4. Não precisa marcar nenhuma capacidade extra. Continue > Register.

## Passo 3. Criar o app no App Store Connect

1. Entre em https://appstoreconnect.apple.com > **Apps** > **+** > **Novo app**.
2. Plataforma iOS, nome `Liga do Saber` (se estiver ocupado, use `Liga do Saber - Reforço`), idioma Português (Brasil), Bundle ID o do passo 2, SKU `liga-do-saber`.

## Passo 4. Criar a chave de API (é ela que deixa o GitHub assinar e enviar o app)

1. No App Store Connect, vá em **Usuários e acesso** > aba **Integrações** > **App Store Connect API** > **Chaves da equipe**.
2. Clique em **Gerar chave de API** (na primeira vez, pede para solicitar acesso; aceite).
3. Nome `GitHub`, acesso **Admin** (precisa ser Admin para o GitHub criar o certificado de distribuição sozinho).
4. Anote o **ID do emissor** (Issuer ID, aparece no topo) e o **ID da chave** (Key ID).
5. Baixe o arquivo `AuthKey_XXXX.p8`. **Só dá para baixar uma vez.** Guarde no mesmo lugar seguro da chave do Android.
6. Pegue o **Team ID**: em https://developer.apple.com/account, role até "Detalhes da associação" (Membership details). São 10 letras e números.

## Passo 5. Colocar os segredos no GitHub

1. Abra https://github.com/PortalPR1Noticias/liga_do_saber_app/settings/secrets/actions
2. Clique em **New repository secret** e crie os quatro:

| Nome | Valor |
| --- | --- |
| `APPLE_TEAM_ID` | O Team ID do passo 4.6 |
| `ASC_KEY_ID` | O ID da chave |
| `ASC_ISSUER_ID` | O ID do emissor |
| `ASC_KEY_P8` | Abra o `.p8` no Bloco de Notas e cole **todo** o texto, inclusive as linhas `-----BEGIN PRIVATE KEY-----` e `-----END PRIVATE KEY-----` |

Os segredos ficam escondidos mesmo com o repositório público: ninguém consegue ler, nem em PRs de terceiros.

## Passo 6. Enviar um build para o TestFlight

1. Abra https://github.com/PortalPR1Noticias/liga_do_saber_app/actions/workflows/ios.yml
2. Clique em **Run workflow**, deixe a branch `main`, marque **Enviar para o TestFlight** e confirme.
3. Leva uns 15 a 25 minutos. Fica verde quando o envio terminar.
4. No App Store Connect > seu app > **TestFlight**, o build aparece "Processando" e, depois de uns 10 a 30 minutos, fica pronto.

Se ficar vermelho, abra a execução e veja o passo que falhou. Os erros mais comuns: segredo colado faltando uma linha do `.p8`, chave sem acesso Admin, ou app ainda não criado no passo 3.

## Passo 7. Testar no seu iPhone (TestFlight)

1. No App Store Connect > TestFlight > **Testes internos**, crie um grupo (por exemplo "Família") e adicione seu e-mail. Testadores internos (até 100, precisam estar em "Usuários e acesso") recebem o build na hora, sem revisão da Apple.
2. No iPhone, instale o app **TestFlight** da App Store e aceite o convite que chega por e-mail.
3. Para pessoas de fora (pais e professores parceiros), use **Testes externos**: o primeiro build passa por uma revisão rápida da Apple (cerca de 1 dia) e depois você manda um link público.

> Sem conta paga ainda? Cada execução do workflow gera também o arquivo `LigaDoSaber-sem-assinatura.ipa` (Actions > execução > Artifacts). Com o programa **Sideloadly** no Windows e um ID Apple gratuito, dá para instalar esse arquivo no seu iPhone por cabo. O app expira em 7 dias e precisa ser reinstalado. Serve só para você ver o app rodando.

## Passo 8. Mandar para a App Store

No App Store Connect, na página do app (aba **Distribuição**):

1. **Capturas de tela** (obrigatórias): iPhone 6,9" (1320 × 2868) e, como o app roda no iPad, iPad 13" (2064 × 2752). Dá para tirar no TestFlight com um iPhone e iPad de verdade, ou pedir que eu gere as imagens.
2. **Textos**: dá para reaproveitar a ficha da Play Store (`docs/play-store/ficha-da-loja.md`). Subtítulo até 30 caracteres, palavras-chave até 100.
3. **URL da política de privacidade**: https://portalpr1noticias.github.io/liga_do_saber_app/privacidade.html.
4. **Privacidade do app** ("rótulos nutricionais"): declare e-mail e nome (responsável), dados de uso e conteúdo enviado pelo usuário (fotos das lições e provas, que vão para a OpenAI para gerar a explicação). Nada é usado para rastreamento ou publicidade.
5. **Classificação etária**: responda o questionário; o app deve sair como 4+.
6. **Categoria**: Educação. **Não** marque "Feito para crianças" (Kids Category) por enquanto: essa categoria proíbe mandar dados para terceiros, e a Foto + IA envia a foto para a OpenAI. Como a conta é criada pelo responsável, a categoria Educação com classificação 4+ é o caminho mais seguro.
7. **Informações para a revisão**: crie uma conta de responsável de teste com uma criança e coloque e-mail e senha aqui. Explique em uma frase que a conta é criada pelo responsável e que a Área dos responsáveis fica atrás de uma pergunta de multiplicação.
8. Escolha o build enviado pelo TestFlight, clique em **Adicionar para revisão** e envie. A primeira revisão costuma levar de 1 a 3 dias.

## Regras da Apple que o app já cumpre

- **Exclusão de conta dentro do app** (regra 5.1.1(v)): Área dos responsáveis > Excluir conta e dados.
- **Política de privacidade** pública e dentro do app.
- **Login sem Google ou Facebook**, então não precisa do "Entrar com a Apple".
- **Conteúdo de IA com denúncia**: a bandeira "Avisar um problema" nas telas com IA.
- **Área dos pais com barreira** (pergunta de multiplicação), o que a Apple pede em apps usados por crianças.

## Atualizações depois

1. Suba a versão no `pubspec.yaml` (por exemplo `1.0.1+1`; o número depois do `+` é ignorado no iPhone, o workflow numera sozinho).
2. Faça o merge na `main` e rode o workflow com **Enviar para o TestFlight** marcado.
3. No App Store Connect, crie a nova versão, escolha o build e envie para revisão.
