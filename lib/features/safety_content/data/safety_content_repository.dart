import '../../../core/services/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/safety_content.dart';

final safetyContentRepositoryProvider =
    Provider<SafetyContentRepository>((ref) {
  return SafetyContentRepository(ref.watch(apiClientProvider));
});

final safetyContentsProvider = FutureProvider<List<SafetyContent>>((ref) async {
  final builtInContents = <SafetyContent>[
    SafetyContent(
      id: 'demo-safety-1',
      title: 'Monte um plano de segurança',
      summary:
          'Prepare caminhos, contatos e itens essenciais antes de uma crise.',
      content: 'Escolha dois lugares seguros para onde você possa ir.\n'
          'Combine uma palavra-código com pessoas de confiança para pedir ajuda sem explicar tudo.\n'
          'Mantenha documentos, remédios, chaves, algum dinheiro e carregador em local acessível.\n'
          'Planeje uma saída que evite cômodos com armas ou sem rota de fuga.\n'
          'Se houver crianças, ensine-as a chamar ajuda sem intervir na situação.',
      category: 'safety_plan',
      isPublished: true,
      sourceName: 'Ligue 180 e rede de atendimento',
      updatedAt: DateTime.utc(2026, 10, 5),
    ),
    SafetyContent(
      id: 'demo-safety-2',
      title: 'Fortaleça sua rede de apoio',
      summary: 'Defina quem pode ajudar e o que cada pessoa deve fazer.',
      content:
          'Escolha pessoas que respeitem suas decisões e mantenham discrição.\n'
          'Explique se elas devem ligar para 190, buscar você ou apenas acompanhar por telefone.\n'
          'Compartilhe endereços importantes e revise quem pode ver sua localização.\n'
          'Faça testes periódicos da palavra-código e dos meios de contato.',
      category: 'support_network',
      isPublished: true,
      sourceName: 'Ligue 180 e rede de atendimento',
      updatedAt: DateTime.utc(2026, 10, 5),
    ),
    SafetyContent(
      id: 'demo-safety-3',
      title: 'Proteja sua conta e seu celular',
      summary: 'Reduza o acesso indevido a mensagens, localização e histórico.',
      content:
          'Use uma senha que a outra pessoa não conheça e ative autenticação em dois fatores quando disponível.\n'
          'Revise aparelhos conectados às suas contas e encerre sessões desconhecidas.\n'
          'Desative a prévia de notificações sensíveis na tela bloqueada.\n'
          'Confira permissões de localização e compartilhamentos ativos.\n'
          'Se o aparelho for monitorado, procure ajuda usando um dispositivo seguro.',
      category: 'digital_security',
      isPublished: true,
      sourceName: 'Orientação de segurança digital',
      updatedAt: DateTime.utc(2026, 10, 5),
    ),
    SafetyContent(
      id: 'demo-safety-4',
      title: 'Preserve provas com segurança',
      summary: 'Organize registros sem aumentar o risco para você.',
      content:
          'Guarde mensagens, áudios, fotos e datas sem editar os arquivos originais.\n'
          'Anote uma linha do tempo com locais, testemunhas e números de protocolos.\n'
          'Mantenha uma cópia em conta segura ou com alguém de confiança.\n'
          'Não confronte o agressor para conseguir novas provas. Sua segurança vem primeiro.',
      category: 'evidence',
      isPublished: true,
      sourceName: 'Rede de atendimento à mulher',
      updatedAt: DateTime.utc(2026, 10, 5),
    ),
    SafetyContent(
      id: 'demo-safety-5',
      title: 'Procure atendimento de saúde',
      summary:
          'Cuidados médicos também podem registrar lesões e oferecer acolhimento.',
      content:
          'Procure atendimento quando houver lesões, dor, violência sexual ou sofrimento emocional.\n'
          'Conte à equipe apenas o que se sentir segura para relatar e peça registro no prontuário.\n'
          'Em violência sexual, busque atendimento o quanto antes para conhecer cuidados disponíveis.\n'
          'Você pode pedir apoio de uma pessoa de confiança durante o atendimento.',
      category: 'health',
      isPublished: true,
      sourceName: 'Rede pública de saúde',
      updatedAt: DateTime.utc(2026, 10, 5),
    ),
    SafetyContent(
      id: 'demo-safety-6',
      title: 'Entenda a medida protetiva',
      summary:
          'Saiba onde pedir proteção e o que fazer em caso de descumprimento.',
      content:
          'A medida protetiva pode ser solicitada em delegacia e também por outros serviços da rede, como Defensoria, Ministério Público, Juizado e Casa da Mulher Brasileira.\n'
          'Ela pode ser analisada a partir do relato da mulher e não depende necessariamente de boletim de ocorrência ou processo prévio.\n'
          'Guarde uma cópia da decisão e informe pessoas de confiança.\n'
          'Se houver descumprimento ou novo risco, procure a rede de atendimento e, em emergência, ligue 190.',
      category: 'rights',
      isPublished: true,
      sourceName: 'Ministério das Mulheres',
      sourceUrl:
          'https://www.gov.br/mulheres/pt-br/assuntos/lei-maria-da-penha',
      updatedAt: DateTime.utc(2026, 10, 5),
    ),
    SafetyContent(
      id: 'demo-safety-7',
      title: 'Use os canais certos',
      summary: '190 para emergência; 180 para orientação, rede e denúncias.',
      content:
          'Ligue 190 quando a violência estiver acontecendo ou houver risco imediato.\n'
          'O Ligue 180 funciona gratuitamente, 24 horas por dia, para orientar sobre direitos, localizar serviços e encaminhar denúncias.\n'
          'No Amazonas, o Disque 181 recebe denúncias anônimas de segurança pública.\n'
          'O ProtegeEla é uma ferramenta complementar e não substitui os serviços oficiais.',
      category: 'channels',
      isPublished: true,
      sourceName: 'Ligue 180',
      sourceUrl: 'https://www.gov.br/mulheres/pt-br/ligue180',
      updatedAt: DateTime.utc(2026, 10, 5),
    ),
  ];

  try {
    final published =
        await ref.watch(safetyContentRepositoryProvider).published();
    return published.isEmpty ? builtInContents : published;
  } catch (_) {
    return builtInContents;
  }
});

class SafetyContentRepository {
  const SafetyContentRepository(this._api);
  final ApiClient _api;

  Future<List<SafetyContent>> published() async =>
      (await _api.list('/safety-content')).map(SafetyContent.fromJson).toList();
}
