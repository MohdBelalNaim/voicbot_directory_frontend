import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

class VadController {
  void Function()? _onSpeech;
  web.MediaStream?  _stream;
  web.AudioContext? _context;

  void start({required void Function() onSpeech}) {
    _onSpeech = onSpeech;
    final constraints = web.MediaStreamConstraints(audio: true.toJS);
    web.window.navigator.mediaDevices
        .getUserMedia(constraints)
        .toDart
        .then(_setup)
        .catchError((Object e) {
          // ignore — mic denied
        });
  }

  void _setup(web.MediaStream stream) {
    _stream = stream;
    try {
      final ctx = web.AudioContext();
      _context = ctx;
      ctx.audioWorklet.addModule('vad_worklet.js').toDart.then((_) {
        try {
          final source = ctx.createMediaStreamSource(stream);
          final node   = web.AudioWorkletNode(ctx, 'vad-processor');
          node.port.onmessage = ((web.MessageEvent event) {
            final data = event.data as JSObject?;
            if (data == null) return;
            final type = data.getProperty<JSString?>('type'.toJS)?.toDart;
            if (type == 'speech') _onSpeech?.call();
          }).toJS;
          source.connect(node);
          node.connect(ctx.destination);
        } catch (_) { _teardown(); }
      }).catchError((Object _) { _teardown(); });
    } catch (_) { _teardown(); }
  }

  void stop() => _teardown();

  void _teardown() {
    try { _context?.close(); } catch (_) {}
    try {
      final tracks = _stream?.getTracks().toDart ?? [];
      for (final t in tracks) { t.stop(); }
    } catch (_) {}
    _context = null;
    _stream  = null;
  }
}
