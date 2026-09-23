# ProtegeEla Frontend

[![CI](https://github.com/protegeEla/protegeela-frontend/actions/workflows/ci.yml/badge.svg)](https://github.com/protegeEla/protegeela-frontend/actions/workflows/ci.yml)

Frontend web responsivo do ProtegeEla, desenvolvido em Flutter para apoiar
mulheres em situações de risco com acesso rápido à rede de apoio, alertas,
orientações e pontos de atendimento.

> O ProtegeEla não substitui a polícia, serviços oficiais de emergência,
> atendimento médico, assistência jurídica ou acompanhamento profissional.
> Esta versão é demonstrativa e não deve ser usada em uma emergência real.

## Demonstração

Aplicação publicada:

```text
https://protegeela.netlify.app
```

Na tela de login, a opção **Entrar temporariamente** permite conhecer a
interface sem criar uma conta. Nesse modo:

- perfil, contatos, alertas e pontos de apoio são demonstrativos;
- nenhuma pessoa real é avisada;
- nenhuma emergência oficial é acionada;
- alterações ficam somente na experiência local de demonstração.

## Funcionalidades do frontend

- Onboarding com orientações de privacidade e localização contextual.
- Login, cadastro, confirmação de e-mail e recuperação de senha.
- Layout unificado para entrar e criar conta.
- Perfil editável e modo de notificações discretas.
- Rede de apoio com criação, edição, permissão de localização e remoção de
  contatos.
- Botão de ajuda com pressionamento de cinco segundos, progresso animado,
  confirmação e suporte a movimento reduzido.
- Tela de alerta ativo com mapa, status e ações de segurança.
- Mapa unificado com alertas aproximados e pontos de apoio.
- Busca e filtros de serviços por nome, endereço, cidade e categoria.
- Orientações de segurança, denúncia anônima e Delegacia da Mulher.
- Saída rápida para conteúdo externo neutro no navegador.
- Navegação lateral no desktop e barra inferior em telas menores.
- PWA instalável com identidade visual própria.

Algumas funcionalidades dependem de serviços externos e não representam uma
operação real nesta entrega. Por exemplo, o fallback interno de notificações não
envia push, SMS ou WhatsApp para contatos.

## Arquitetura

O frontend usa uma organização **feature-first**, com separação pragmática entre
apresentação e acesso a dados:

```text
lib/
  app/                         # aplicação, rotas e tema
  core/                        # configuração, serviços e widgets compartilhados
  features/
    admin/
    alerts_map/
    authentication/
    emergency/
    home/
    notifications/
    onboarding/
    profile/
    safety_content/
    support_points/
    trusted_contacts/
  shared/models/               # modelos usados por várias features
test/
  core/                        # testes da infraestrutura do cliente
  features/                    # testes de comportamento e widgets
web/                           # shell, manifesto e ícones da PWA
assets/                        # imagens e configurações públicas
scripts/                       # auditorias locais do frontend
```

Responsabilidades principais:

| Diretório | Responsabilidade |
| --- | --- |
| `lib/app` | Composição da aplicação, tema Material e rotas GoRouter |
| `lib/core` | Configuração, serviços e componentes reutilizáveis |
| `features/*/presentation` | Páginas, formulários, animações e estado visual |
| `features/*/presentation/widgets` | Componentes internos de cada funcionalidade |
| `features/*/data` | Providers e adaptadores usados pelo cliente Flutter |
| `features/emergency/domain` | Estado específico do fluxo de emergência |
| `lib/shared/models` | Objetos de dados compartilhados |

Riverpod fornece estado e injeção de dependências. GoRouter controla rotas e
redirecionamentos. Os arquivos `data` continuam sendo parte do frontend: eles
adaptam chamadas externas para modelos consumidos pela interface.

O projeto não implementa Clean Architecture completa. Novas abstrações devem ser
criadas somente quando reduzirem acoplamento ou duplicação de forma concreta.

## Organização e desempenho

O script `scripts/audit_frontend.dart` verifica arquivos Dart acima de 800
linhas e arquivos que não são alcançáveis por `main.dart` ou pelos testes do
frontend.

Estado atual da organização:

- nenhum arquivo Dart escrito manualmente passa de 800 linhas;
- páginas maiores foram divididas em widgets por responsabilidade;
- o cadastro reutiliza o mesmo layout da página de login;
- mapa e pontos de apoio compartilham a mesma experiência;
- diálogos de contatos foram separados da página principal;
- arquivos e dependências sem uso foram removidos.

Cuidados de desempenho aplicados:

- o mapa consulta apenas a área visível;
- movimentos do mapa usam debounce e não criam requisições concorrentes;
- atualizações periódicas pausam quando a aba perde foco;
- dados assíncronos não são buscados durante o método `build`;
- animações decorativas isolam repinturas;
- rotas principais não usam transições pesadas.

As ilustrações ainda representam parte relevante do download inicial. Uma futura
otimização deve preservar transparência e qualidade visual e ser validada com o
painel Performance do Chrome.

## Tecnologias

- Flutter Web 3.47.5.
- Dart com null safety.
- Material 3.
- Riverpod.
- GoRouter.
- Supabase Flutter como cliente de autenticação e dados.
- Flutter Map e OpenStreetMap.
- Geolocator.
- Shared Preferences.
- Netlify.

Este repositório está sendo tratado como frontend. Autorizações, regras de
negócio, migrations e funções executadas no servidor devem ser revisadas pela
equipe responsável pelo backend.

## Requisitos

- Flutter 3.47.5 ou compatível com o SDK definido em `pubspec.yaml`.
- Chrome para execução web local.
- Projeto externo configurado para autenticação e dados, quando não estiver no
  modo demonstrativo.

## Configuração

Crie o arquivo local de ambiente a partir do exemplo:

```bash
cp .env.example .env
```

No PowerShell:

```powershell
Copy-Item .env.example .env
```

Preencha apenas configurações públicas usadas pelo cliente:

```dotenv
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-publica
```

O arquivo `.env` é ignorado pelo Git. Nunca adicione credenciais administrativas,
tokens privados ou chaves de serviço ao frontend.

Para testar a recuperação de senha localmente, autorize a seguinte URL de
retorno no provedor de autenticação:

```text
http://localhost:3000/#/atualizar-senha
```

Cadastre também a rota equivalente do domínio de produção.

## Execução local

```bash
flutter pub get
flutter run -d chrome --web-port 3000
```

O modo padrão é `debug` e inclui instrumentação, verificações e suporte a hot
reload. Ele não deve ser usado como referência de velocidade.

Para avaliar a experiência otimizada:

```bash
flutter run -d chrome --release --web-port 3000
```

Para investigar renderização e interações no Chrome DevTools:

```bash
flutter run -d chrome --profile --web-port 3000
```

## Qualidade e testes

Execute antes de abrir um pull request:

```bash
dart format --output=none --set-exit-if-changed lib test/core test/features scripts
dart run scripts/audit_frontend.dart
flutter analyze --no-pub
flutter test --no-pub test/core test/features
flutter build web --release --no-pub
```

O workflow `.github/workflows/ci.yml` executa a mesma validação em pull requests
e em pushes para `main`. O Dependabot acompanha dependências Dart e GitHub
Actions.

## Build e deploy

Build web local:

```bash
flutter build web --release
```

O deploy da Netlify utiliza:

```bash
bash build.sh
```

O script fixa a versão do Flutter e gera o frontend com CSP e recursos web
locais. O service worker é gerado pelo próprio Flutter; não existe um segundo
worker manual disputando o mesmo escopo.

Arquivos web mantidos manualmente:

- `web/index.html`
- `web/manifest.json`
- `web/favicon.png`
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`

## Segurança no cliente

- Não registrar tokens, credenciais, coordenadas ou dados pessoais no console.
- Não incluir chaves privadas no bundle Flutter.
- Validar respostas externas antes de convertê-las em modelos.
- Não apresentar controles de segurança que não produzam proteção real.
- Evitar dados sensíveis em textos de notificação.
- Manter mensagens honestas sobre limitações do navegador e da PWA.

Vulnerabilidades não devem ser publicadas em issues abertas. Utilize o canal
privado do GitHub:

```text
https://github.com/protegeEla/protegeela-frontend/security/advisories/new
```

Não inclua dados pessoais reais, coordenadas, tokens ou credenciais no relato.

## Limitações conhecidas

- A PWA não garante execução contínua quando o navegador está fechado.
- Notificações push ainda dependem de integração externa.
- Ligações `tel:` podem não funcionar em computadores.
- Pontos de apoio demonstrativos não constituem uma base oficial verificada.
- O modo temporário não persiste dados no serviço remoto.
- Uso real exige validação técnica, operacional, jurídica e de privacidade.

## Contribuição e conduta

Contribuições devem preservar acessibilidade, privacidade e linguagem acolhedora.

Antes de enviar uma alteração:

1. Execute os comandos de qualidade e testes do frontend.
2. Não inclua chaves, tokens, dados pessoais ou coordenadas reais.
3. Adicione testes para comportamentos novos ou corrigidos.
4. Descreva impacto visual, de acessibilidade, privacidade e desempenho.
5. Mantenha mudanças fora do frontend em uma entrega e revisão separadas.

Não são aceitos assédio, discriminação, exposição de dados pessoais, incentivo a
confronto ou mudanças que reduzam a privacidade sem revisão explícita.

## Versão atual

`0.1.0+1` — versão inicial demonstrativa do frontend, com autenticação, perfil,
rede de apoio, emergência, mapa, orientações, modo temporário e PWA responsiva.

## Licença

Distribuído sob a licença MIT. Consulte o arquivo `LICENSE`.

## Créditos

Projeto idealizado e desenvolvido por **ConderTech — A desenvolvedora**.
