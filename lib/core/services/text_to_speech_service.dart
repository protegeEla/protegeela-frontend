import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'text_to_speech_service_stub.dart'
    if (dart.library.html) 'text_to_speech_service_web.dart';

final textToSpeechServiceProvider = Provider<TextToSpeechService>((ref) {
  final service = createTextToSpeechService();
  ref.onDispose(service.stop);
  return service;
});

abstract class TextToSpeechService {
  bool get supported;
  Future<void> speak(String text);
  void stop();
}
