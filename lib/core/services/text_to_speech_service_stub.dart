import 'text_to_speech_service.dart';

TextToSpeechService createTextToSpeechService() =>
    _UnsupportedTextToSpeechService();

class _UnsupportedTextToSpeechService implements TextToSpeechService {
  @override
  bool get supported => false;

  @override
  Future<void> speak(String text) async {}

  @override
  void stop() {}
}
