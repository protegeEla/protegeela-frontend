import 'quick_exit_service_stub.dart'
    if (dart.library.js_interop) 'quick_exit_service_web.dart' as platform;

/// Leaves sensitive content immediately.
///
/// On the web this replaces the current history entry with an unrelated site.
/// Other platforms return `false` so the caller can show the local neutral page.
Future<bool> leaveSensitiveContent() => platform.leaveSensitiveContent();
