# Auditoria e estabilização — 30/10/2026

Branch: `fix/protegeela-stabilization`, criada a partir de `main` em `89b0021`.
O workspace estava limpo. `git fetch origin` confirmou que a main local estava
atualizada. PR #10 está fechado e integrado em `89b0021`; `origin/beatriz`
aponta para `247060e`, ancestral da main. O commit `7d9318d` foi revisado.
Nenhum PR do Dependabot foi integrado e a main não foi alterada.

## Falhas e correções

| Evidência / causa | Correção |
| --- | --- |
| `flutter pub get` falhava ao ler `pubspec.lock`: chave `gtk`, mas descrição `hooks`. A última CI da main falhou em “Install dependencies”. | Corrigida a entrada e resolvido novamente o lockfile com o Pub. Não havia marcadores de conflito; a inconsistência era estrutural. |
| `intl ^0.20.3` conflita com `flutter_localizations` do Flutter 3.44.8 disponível, que fixa 0.20.2. | CI, Netlify e documentação fixados no SDK efetivamente validado, 3.44.8 / Dart 3.12.2; `intl ^0.20.2`. A versão anterior 3.47.5 existe no Git remoto: sua inexistência não foi a causa da falha. |
| `api_client.dart` importa `http`, ausente do manifesto direto. | Declarado `http ^1.6.0`, já usado e presente no lockfile. |
| A integração havia removido `test/` e `flutter_test`; `flutter test` falhava por ausência de diretório. | Adicionado `flutter_test` e suíte para a API Java, navegação e fluxos de segurança atuais. Testes antigos de Supabase não foram restaurados porque a arquitetura mudou. |
| A formatação existente reprova o comando da CI. | Executado o formatador do SDK fixado em `lib`, `scripts` e `test`. Grande parte dos arquivos modificados contém somente formatação. |
| Após formatar, o painel de alerta excedia 800 linhas e a saída rápida estava inacessível desde `main.dart`. | Extraído `AlertTrackingPanel` para arquivo próprio; botão existente reintegrado ao shell e à tela de alerta. Auditoria continua obrigatória. |
| Linhas de login e troca de formulário transbordavam em 390 px. Formulário desktop não tinha rolagem própria. | Restrições flexíveis e rolagem para o formulário desktop. Testes em celular e notebook. |
| Uma captura GPS assíncrona podia terminar depois de logout/troca de conta e enviar usando a nova sessão. | Revisão de sessão e verificação de conta, montagem, compartilhamento e primeiro plano antes do envio. Fluxo de criação de alerta também verifica a sessão iniciadora. |
| Estado/cache de check-in podia sobreviver à troca de conta. | Repositório invalidado em eventos de sessão; nenhuma consulta de check-in sem usuário. Restauração de sessão também ignora leitura antiga após troca de sessão. |
| CSP do Netlify tinha `connect-src 'self'`, bloqueando REST/WSS externos e requisições do mapa. | Geração de `_headers` com origens HTTPS/WSS derivadas da API validada, recursos locais do Flutter e origem explícita do mapa. Política de referência `no-referrer` reduz vazamento de links privados. |
| Fallback global `/*` também retornava HTML para JS/API inexistentes. | `_redirects` gerado apenas para rotas efetivamente declaradas; arquivos e `/api` não são capturados. |
| Build e CI não exigiam lockfile consistente e não executavam testes. | `--enforce-lockfile`, testes obrigatórios, build CSP sem CDN e validação/geração dos arquivos Netlify na CI. SDK tem cache por versão no build. |

## Dependências

- Mantidos Flutter Riverpod 2.6.1, flutter_map 7.0.2, go_router 18.0.1,
  geolocator 12.0.0, url_launcher 6.3.2, flutter_secure_storage 11.2.0 e lints 4.0.0.
- `intl`: 0.20.3 → 0.20.2, exigência do SDK validado.
- `http`: declarado diretamente, sem trocar a versão resolvida 1.6.0.
- `flutter_test`: adicionado como dependência de desenvolvimento do SDK.
- O Pub removeu `gotrue`, resíduo da implementação Supabase, e ajustou
  transitivas para o SDK/testes: clock, code_assets, cupertino_ui, hooks,
  material_ui, meta, objective_c, record_use, stack_trace e vector_math.
  Acrescentou transitivas de teste. Os hashes são os gerados pelo Pub.
- Requisitos declarados: Dart >=3.12.0 e Flutter >=3.44.0, coerentes com a
  árvore resolvida; execução reproduzível fixada em Flutter 3.44.8.

## Funcionalidades e segurança

Preservados cadastro/login via backend Java, perfil, contatos e convites,
alertas com idempotência, modo silencioso, fila local sem coordenadas, check-in,
trajeto por link privado, mapas, pontos de apoio, orientações e WebSocket.
Nenhuma implementação real foi substituída por mock; mocks existem só nos testes.

Revisados o cliente HTTP, repositório de autenticação, roteamento, armazenamento,
controller/repositório de emergência, GPS/check-in, WebSocket e links públicos.
O cliente já descarta respostas de sessões anteriores, remove a sessão em 401,
não envia bearer em chamadas públicas e não coloca tokens no endereço WebSocket.
Tokens permanecem em memória por padrão e usam secure storage somente com
“Lembrar de mim”. A saída rápida não promete apagar histórico nem encerrar sessão.

Busca por padrões de chave privada, tokens GitHub, AWS e Stripe nos arquivos
atuais não encontrou correspondências. Não é uma auditoria criptográfica nem
uma varredura completa de todo o histórico Git. Não foram impressos tokens ou
dados pessoais. O token usado nos testes é sintético, em domínio `.invalid`.

Os fluxos continuam explícitos sobre falta de confirmação e ausência de
notificação externa. Recuperação de senha e confirmação de e-mail permanecem
indisponíveis conforme contrato documentado; não foi simulado atendimento real.

## Validação local

Ambiente Windows, Flutter 3.44.8 stable, Dart 3.12.2.

| Verificação | Resultado |
| --- | --- |
| `flutter --version` | Executado; 3.44.8 / 3.12.2. |
| `flutter doctor -v` | Web disponível; SDK não está no PATH global e Android SDK ausente. Usado caminho absoluto, sem alterar PATH global. |
| `flutter pub get` e `--enforce-lockfile` | Aprovados após correções. |
| `dart format --output=none --set-exit-if-changed lib scripts test` | Aprovado, nenhum arquivo a reformatar. |
| `flutter analyze --no-pub` | Aprovado, “No issues found”. |
| `flutter test --no-pub` | 17 testes aprovados. |
| `dart run scripts/audit_frontend.dart` | Aprovado, nenhum arquivo >800 linhas, nenhum arquivo inacessível. |
| `flutter build web --release --csp --no-web-resources-cdn --dart-define=API_BASE_URL=https://api.example.invalid/api` | Build de release aprovado; também passou o dry run Wasm. |
| `bash build.sh` com SDK local da mesma versão e API sintética | Aprovado de ponta a ponta, incluindo lockfile obrigatório, build e geração de `_headers` / `_redirects`. A instalação do SDK em Linux será exercitada pela CI. |

Testes cobrem inicialização e navegação pública/protegida, cadastro e login sem
overflow em 390×844, 1440×900 e 1366×768; bearer e chamadas públicas; 401;
resposta atrasada de outra sessão; JSON inválido e erro de rede; persistência e
logout; GPS após troca de conta; privacidade e falha HTTP de alerta silencioso;
fila por usuário/expiração/corrupção; validação de endpoint, CSP e rotas Netlify.

O domínio `api.example.invalid` é deliberadamente não operacional: permite
validar compilação sem enviar dados reais e **não deve ser usado em produção**.

## Infraestrutura e limites

- Entrega remota: [PR #12, em rascunho para revisão](https://github.com/protegeEla/protegeela-frontend/pull/12),
  sem merge na main. A [lista completa de arquivos modificados](https://github.com/protegeEla/protegeela-frontend/pull/12/files)
  inclui os arquivos de formatação, implementação, testes e infraestrutura.

- GitHub API confirmou a falha em instalação de dependências na execução
  [41094880709](https://github.com/protegeEla/protegeela-frontend/actions/runs/41094880709).
  A configuração corrigida mantém todas as verificações e acrescenta testes.
- Netlify: não foram fornecidos logs completos, site ID ou acesso autenticado.
  A corrupção do lockfile é um bloqueio reproduzido localmente e compartilhado
  pela etapa de instalação; não é possível atribuir todo erro remoto “exit 2”
  somente a ela. CSP e rotas eram problemas adicionais de execução após build.
- Sem endpoint público/credenciais do backend: não foram validados login real,
  CORS, WebSocket remoto, permissões de produção ou entrega de notificações.
- Android/iOS: não há pastas de plataforma versionadas neste checkout. Não
  foram recriadas. Imports Web continuam condicionais; nenhuma mudança exige
  Web em plataformas nativas. Builds nativos não foram certificados: falta SDK
  Android e iOS requer macOS/Xcode e os projetos de plataforma.

## Para produção

1. Revisar e integrar o PR de correção, sem force push ou merge automático.
2. Configurar `API_BASE_URL=https://<host-real>/api` na Netlify e executar deploy.
3. Configurar `FRONTEND_ORIGINS` no backend, HTTPS válido e proxy WSS.
4. Confirmar log completo do deploy, deep links de convite/trajeto, assets, CSP,
   login/logout/401, GPS permitido/negado e perda de rede em ambiente integrado.
5. Validar os fluxos de alerta/check-in com contas de teste e somente afirmar
   entrega quando o serviço real de notificações estiver configurado e testado.
6. Disponibilizar projetos/SDKs nativos para certificar Android/iOS.
