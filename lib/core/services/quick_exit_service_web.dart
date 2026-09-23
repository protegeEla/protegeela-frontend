import 'dart:js_interop';

const quickExitDestination = 'https://www.google.com/';

@JS('window.location')
external _BrowserLocation get _location;

@JS()
extension type _BrowserLocation._(JSObject _) implements JSObject {
  external void replace(JSString url);
}

Future<bool> leaveSensitiveContent() async {
  // `replace` prevents the current ProtegeEla page from being the immediate
  // destination of the browser back button.
  _location.replace(quickExitDestination.toJS);
  return true;
}
