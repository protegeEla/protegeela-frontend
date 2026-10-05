# ProtegeEla Frontend

[![CI](https://github.com/protegeEla/protegeela-frontend/actions/workflows/ci.yml/badge.svg)](https://github.com/protegeEla/protegeela-frontend/actions/workflows/ci.yml)

Aplicação web responsiva em Flutter, conectada ao backend Java/PostgreSQL.

> Versão demonstrativa. Não substitui serviços oficiais nem deve ser usada em
> uma emergência real. Criar um alerta não envia SMS, WhatsApp ou push.

## Funcionalidades

- Cadastro, login, edição de perfil e modo discreto.
- Rede de apoio com criação, edição e remoção de contatos.
- Convites temporários com aceite/recusa e canal preferido por contato.
- Alertas com localização opcional, acompanhamento e encerramento.
- Modo “Cheguei bem”, com prazo no backend e trajeto compartilhável por link privado.
- Mapa de alertas aproximados e pontos de apoio do OpenStreetMap.
- Atualização do mapa por WebSocket, com recuperação por HTTP.
- Orientações pesquisáveis, categorias, favoritos, leitura em voz alta e PWA instalável.

Recuperação de senha, confirmação de e-mail e envio automático de notificações
ainda não estão disponíveis. O link do trajeto pode ser enviado manualmente por
WhatsApp ou copiado para outro canal.

## Executar localmente

Requisitos: Flutter 3.47.5, Edge ou Chrome e backend em execução.
Siga o [README do backend](../protegeela-backend/README.md) para iniciar
PostgreSQL, Redis e Java. Na pasta do frontend:

```powershell
flutter pub get
flutter run -d edge --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080/api
```

Para usar Chrome, substitua `-d edge` por `-d chrome`.
Se a porta 3000 estiver ocupada, encerre sua execução anterior ou escolha outra
com `--web-port` e inclua essa origem em `FRONTEND_ORIGINS` no backend.

Como alternativa aos argumentos individuais, copie a configuração de exemplo:

```powershell
Copy-Item .env.example .env
flutter run -d edge --web-port 3000 --dart-define-from-file=.env
```

`API_BASE_URL` deve incluir `/api`. O arquivo `.env` é ignorado pelo Git e
contém apenas configurações públicas; nunca coloque senhas ou tokens nele.
Os valores são incorporados ao build por `--dart-define-from-file`.

## Integração e privacidade

O token de sessão fica apenas em memória, exceto quando “Lembrar de mim” é marcado.
Contatos e alertas pertencem à conta autenticada. O mapa exibe somente alertas
compartilhados explicitamente, com localização aproximada. Alertas silenciosos
são privados; a posição exata é removida do banco ativo ao encerrar o alerta.

O WebSocket deriva sua URL de `API_BASE_URL` e autentica sem token na URL.
Redis compartilha cache e eventos entre backends. Catálogos podem ser preenchidos
pelas rotas administrativas; a busca de locais usa OpenStreetMap sem chave.

- [Endpoints da API](../protegeela-backend/API.md)
- [Busca de pontos de apoio](../protegeela-backend/OPENSTREETMAP.md)
- [Redis e WebSocket sem Docker](../protegeela-backend/REDIS_WEBSOCKET.md)
- [Revisão de segurança e pendências](../protegeela-backend/SECURITY_REVIEW.md)

A PWA não consegue atualizar o GPS continuamente com o navegador fechado. Nesse
caso, o mapa mantém a última posição, mas o prazo do “Cheguei bem” continua no
backend. A saída rápida
não apaga o histórico nem encerra a sessão. Dados pendentes locais não são
armazenamento secreto: são descartados após 24 horas na leitura ou no logout.
Os resultados do OpenStreetMap não são verificados pelo ProtegeEla.

## Estrutura

```text
lib/app/       # aplicação, rotas e tema
lib/core/      # configuração, serviços e widgets compartilhados
lib/features/  # apresentação e acesso a dados por funcionalidade
lib/shared/    # modelos compartilhados
assets/        # ilustrações
web/           # página inicial, manifesto e ícones da PWA
scripts/       # auditoria de referências e tamanho dos arquivos
```

Riverpod gerencia estado e dependências; GoRouter controla a navegação.
A autorização e as regras de acesso a dados são aplicadas pelo backend.

## Verificar e compilar

```powershell
dart format --output=none --set-exit-if-changed lib scripts
dart run scripts/audit_frontend.dart
flutter analyze --no-pub
flutter build web --release --no-pub
```

A CI executa essas verificações em pull requests e pushes para `main`.
O Dependabot acompanha dependências Dart e GitHub Actions.

## Publicar

Na Netlify, `build.sh` instala a versão configurada do Flutter e gera `build/web`.
Defina `API_BASE_URL` com a URL HTTPS pública da API no ambiente de build.
Configure `FRONTEND_ORIGINS` no backend e inclua as origens HTTPS/WSS da API em
`connect-src` no arquivo `netlify.toml`. O proxy deve aceitar upgrade WebSocket.
Não publique um build apontando para `localhost`.

## Contribuir

Preserve acessibilidade, privacidade e linguagem acolhedora. Execute as
verificações e descreva o impacto das alterações. Não inclua dados pessoais,
coordenadas reais, senhas ou tokens no código, logs ou relatos.

Relate vulnerabilidades pelo
[canal privado do GitHub](https://github.com/protegeEla/protegeela-frontend/security/advisories/new).

## Licença e créditos

Licença MIT: [LICENSE](LICENSE).
Projeto idealizado e desenvolvido por **ConderTech — A desenvolvedora**.
