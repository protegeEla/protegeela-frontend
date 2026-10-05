// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'text_to_speech_service.dart';

TextToSpeechService createTextToSpeechService() => _WebTextToSpeechService();

class _WebTextToSpeechService implements TextToSpeechService {
  Completer<void>? _completion;

  @override
  bool get supported => html.window.speechSynthesis != null;

  @override
  Future<void> speak(String text) async {
    final synthesis = html.window.speechSynthesis;
    if (synthesis == null) return;
    stop();

    final completion = Completer<void>();
    _completion = completion;
    final utterance = html.SpeechSynthesisUtterance(text)
      ..lang = 'pt-BR'
      ..rate = 0.92;

    utterance.onEnd.first.then((_) => _finish(completion));
    utterance.onError.first.then((_) => _finish(completion));
    synthesis.speak(utterance);
    await completion.future;
  }

  @override
  void stop() {
    html.window.speechSynthesis?.cancel();
    final completion = _completion;
    _completion = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
  }

  void _finish(Completer<void> completion) {
    if (identical(_completion, completion)) {
      _completion = null;
    }
    if (!completion.isCompleted) {
      completion.complete();
    }
  }
}
