import 'dart:io';

/// Run from the repository root: dart run scripts/audit_frontend.dart
void main() {
  final root = Directory.current.uri;
  final lib = root.resolve('lib/');
  final files = Directory.fromUri(lib)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
  final counts = {
    for (final file in files) file: file.readAsLinesSync().length
  };
  final ranked = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  String relative(File file) =>
      file.uri.toString().substring(root.toString().length);
  stdout.writeln('Largest Dart files (including blank lines):');
  for (final entry in ranked.take(12)) {
    stdout.writeln(
        '${entry.value.toString().padLeft(4)}  ${relative(entry.key)}');
  }
  final oversized = counts.entries.where((entry) => entry.value > 800).toList();
  stdout.writeln('Files above 800 lines: ${oversized.length}');

  final pending = <Uri>[
    lib.resolve('main.dart'),
    ...[
      Directory('test/core'),
      Directory('test/features'),
    ]
        .where((directory) => directory.existsSync())
        .expand((directory) => directory.listSync(recursive: true))
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.absolute.uri),
  ];
  final visited = <Uri>{};
  final directive = RegExp(
    r'''^\s*(?:import|export|part)\s+([^;]+);''',
    multiLine: true,
  );
  final referencedUri = RegExp(r'''['"]([^'"]+)['"]''');
  while (pending.isNotEmpty) {
    final uri = pending.removeLast().normalizePath();
    if (!visited.add(uri)) continue;
    final file = File.fromUri(uri);
    if (!file.existsSync()) continue;
    for (final match in directive.allMatches(file.readAsStringSync())) {
      for (final uriMatch in referencedUri.allMatches(match.group(1)!)) {
        final target = uriMatch.group(1)!;
        if (target.startsWith('package:protegeela/')) {
          pending.add(
            lib.resolve(target.substring('package:protegeela/'.length)),
          );
        } else if (!target.contains(':')) {
          pending.add(uri.resolve(target));
        }
      }
    }
  }
  final unreachable = files
      .where((file) => !visited.contains(file.absolute.uri.normalizePath()))
      .toList();
  stdout.writeln('Unreachable from main.dart and frontend tests:');
  if (unreachable.isEmpty) {
    stdout.writeln('None.');
  } else {
    for (final file in unreachable) {
      stdout.writeln(relative(file));
    }
  }

  if (oversized.isNotEmpty || unreachable.isNotEmpty) exitCode = 1;
}
