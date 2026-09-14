import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voicebot_directory/store/api_store.dart';

import '../models/customer.dart';
import '../services/api_service.dart';

enum _CallState { listening, processing, speaking, muted }

class CallScreen extends StatefulWidget {
  final Customer customer;
  final Color avatarBg;
  final Color avatarFg;

  const CallScreen({
    super.key,
    required this.customer,
    required this.avatarBg,
    required this.avatarFg,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  final _tts = FlutterTts();
  final _stt = SpeechToText();

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  _CallState _state = _CallState.speaking;
  bool _muted = false;
  bool _sttReady = false;
  bool _disposed = false;
  bool _listeningGuard = false;
  String _lastPartial = '';
  int _consecutiveSilences = 0;
  Timer? _ttsSafetyTimer; // Fallback if TTS completion handler never fires
  Timer? _chunkFlushTimer; // Forces pending text to TTS if no split point found

  Duration _elapsed = Duration.zero;
  Timer? _callTimer;

  String _userCaption = '';
  String _botCaption = '';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.26).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _setup();
  }

  // ── Setup ────────────────────────────────────────────────────────────────────

  Future<void> _setup() async {
    await _setupTts();
    await _setupStt();
  }

  Future<void> _setupTts() async {
    debugPrint('[TTS] Setting up...');
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      if (!kIsWeb && Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }

      _tts.setStartHandler(() => debugPrint('[TTS] Speaking started'));

      _tts.setCompletionHandler(() {
        debugPrint(
            '[TTS] Completion. muted=$_muted botBusy=$_botBusy queue=${_ttsQueue.length}');
        _ttsSafetyTimer?.cancel();
        _onTtsDone();
      });

      _tts.setErrorHandler((msg) {
        debugPrint('[TTS] Error: $msg');
        _ttsSafetyTimer?.cancel();
        if (_disposed || !mounted) return;
        if (msg == 'interrupted') return; // caused by our own stop() — ignore
        _onTtsDone();
      });

      debugPrint('[TTS] Setup complete');
    } catch (e, st) {
      debugPrint('[TTS] Setup FAILED: $e\n$st');
    }
  }

  Future<void> _setupStt() async {
    debugPrint('[STT] Initializing...');
    try {
      _sttReady = await _stt.initialize(
        onError: (e) {
          debugPrint('[STT] Error: ${e.errorMsg} permanent=${e.permanent}');
          if (_disposed ||
              !mounted ||
              _state != _CallState.listening ||
              _botBusy) {
            return;
          }
          Future.delayed(const Duration(seconds: 1), () {
            if (!_disposed &&
                mounted &&
                _state == _CallState.listening &&
                !_botBusy &&
                !_muted) {
              _startListening();
            }
          });
        },
        onStatus: (status) {
          debugPrint(
              '[STT] Status: $status  state=$_state guard=$_listeningGuard botBusy=$_botBusy');
          if (_disposed || !mounted) return;
          if ((status == 'done' || status == 'notListening') &&
              _state == _CallState.listening &&
              !_muted &&
              !_listeningGuard &&
              !_botBusy) {
            final words = _lastPartial.trim();
            _lastPartial = ''; // Clear immediately to avoid re-triggering
            if (words.isNotEmpty) {
              _consecutiveSilences = 0;
              debugPrint('[STT] Using recognized text: "$words"');
              _sendToBot(words);
            } else {
              // User delayed or didn't speak: don't immediately blast waiting prompt.
              // Smoothly restart listening, and only prompt after multiple silences.
              _consecutiveSilences++;
              if (_consecutiveSilences >= 3) {
                _consecutiveSilences = 0;
                _speakWaiting();
              } else {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (!_disposed &&
                      mounted &&
                      _state == _CallState.listening &&
                      !_botBusy &&
                      !_muted) {
                    _startListening();
                  }
                });
              }
            }
          }
        },
      );
      debugPrint('[STT] Ready: $_sttReady');
    } catch (e, st) {
      debugPrint('[STT] Init FAILED: $e\n$st');
    }

    if (!_disposed && mounted) {
      // Small delay lets the browser audio context fully settle before speaking
      await Future.delayed(const Duration(milliseconds: 400));
      await _playWelcome();
    }
  }

  // ── Timer ────────────────────────────────────────────────────────────────────

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || !mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
    debugPrint('[TIMER] Started');
  }

  // ── Voice flow ───────────────────────────────────────────────────────────────

  /// Central handler when TTS finishes (or errors out). Drives the state machine
  /// forward: drains queue → when done, transitions to listening.
  void _onTtsDone() {
    if (_disposed || !mounted) return;
    if (_muted) {
      setState(() => _state = _CallState.muted);
      return;
    }
    if (_botBusy || _ttsQueue.isNotEmpty) {
      _flushTtsQueue();
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_disposed && mounted && !_botBusy && !_muted) {
          _startListening();
        }
      });
    }
  }

  /// Starts TTS and arms a safety timer. If the completion handler never fires
  /// (known issue on Web), the safety timer will drive the state forward.
  void _speakWithSafety(String text) {
    setState(() => _state = _CallState.speaking);
    _ttsSafetyTimer?.cancel();
    // Estimate ~80ms per character + 3s buffer
    final estimatedMs = (text.length * 80) + 3000;
    _ttsSafetyTimer = Timer(Duration(milliseconds: estimatedMs), () {
      debugPrint('[TTS] Safety timer fired — completion handler did not fire for: "${text.substring(0, text.length.clamp(0, 40))}..."');
      if (!_disposed && mounted) {
        _onTtsDone();
      }
    });
    _tts.speak(text);
  }

  Future<void> _playWelcome() async {
    if (_disposed || !mounted) return;
    _startTimer();
    try {
      if (_stt.isListening) await _stt.stop();
    } catch (_) {}
    _lastPartial = '';
    final text = 'Hello from ${widget.customer.name}';
    debugPrint('[TTS] Speaking welcome: "$text"');
    _speakWithSafety(text);
  }

  Future<void> _speakWaiting() async {
    if (_disposed || !mounted || _muted || _botBusy) return;
    debugPrint('[TTS] Speaking waiting prompt');
    try {
      if (_stt.isListening) await _stt.stop();
    } catch (_) {}
    _lastPartial = '';
    _speakWithSafety("I'm waiting for your response. Please go ahead.");
  }

  Future<void> _startListening() async {
    debugPrint(
        '[STT] _startListening  ready=$_sttReady muted=$_muted guard=$_listeningGuard botBusy=$_botBusy');
    if (_disposed ||
        !mounted ||
        !_sttReady ||
        _muted ||
        _listeningGuard ||
        _botBusy) {
      return;
    }
    _listeningGuard = true;
    _lastPartial = '';
    try {
      if (_stt.isListening) {
        await _stt.stop();
        await Future.delayed(const Duration(milliseconds: 150));
      }
      if (_disposed || !mounted || _muted || _botBusy) {
        return;
      }
      setState(() {
        _state = _CallState.listening;
        _userCaption = '';
        _botCaption = '';
      });
      debugPrint('[STT] Calling listen()');
      await _stt.listen(
        onResult: _onSttResult,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 4),
          cancelOnError: false,
        ),
      );
      debugPrint('[STT] listen() returned  isListening=${_stt.isListening}');
    } finally {
      _listeningGuard = false;
    }
  }

  void _onSttResult(SpeechRecognitionResult result) {
    debugPrint(
        '[STT] Result: "${result.recognizedWords}"  final=${result.finalResult}');
    if (_disposed || !mounted || _state != _CallState.listening || _botBusy) {
      return;
    }
    _lastPartial = result.recognizedWords;
    setState(() => _userCaption = result.recognizedWords);
    if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
      final words = result.recognizedWords.trim();
      _lastPartial = '';
      _consecutiveSilences = 0;
      _sendToBot(words);
    }
  }

  bool _botBusy = false;
  bool _streamDone = false;
  final _ttsQueue = <String>[];
  String _pendingChunk = '';

  bool _initialized = false;
  late ApiService apiService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final apiStore = context.read<ApiStore>();
      apiService = ApiService(apiStore);

      _initialized = true;
    }
  }

  // Speaks the next queued sentence, or transitions back to listening when done.
  void _flushTtsQueue() {
    if (_disposed || !mounted || _muted) return;
    if (_ttsQueue.isNotEmpty) {
      final sentence = _ttsQueue.removeAt(0);
      debugPrint(
          '[TTS] Speaking queued sentence (${_ttsQueue.length} remaining): "$sentence"');
      _speakWithSafety(sentence);
    } else if (_streamDone) {
      debugPrint('[TTS] Queue empty, stream done — going to listening');
      _botBusy = false;
      if (!_muted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_disposed && mounted && !_botBusy && !_muted) {
            _startListening();
          }
        });
      }
    } else {
      // TTS caught up with the stream; _extractSentencesToQueue will resume us.
      setState(() => _state = _CallState.processing);
    }
  }

  // Pulls speakable fragments out of _pendingChunk into _ttsQueue.
  // Split points (in priority order):
  //   1. Sentence endings  →  .!? followed by whitespace or end
  //   2. Newlines
  //   3. Clause boundaries →  ,;: followed by a space (only when accumulated text > 40 chars)
  // A 1.5 s flush timer catches text that never hits a split point.
  void _extractSentencesToQueue() {
    _chunkFlushTimer?.cancel();
    bool added = false;

    while (true) {
      // 1. Sentence endings (.!?) followed by whitespace
      RegExpMatch? match = RegExp(r'[.!?]+\s+').firstMatch(_pendingChunk);

      // 2. Newlines
      match ??= RegExp(r'\n+').firstMatch(_pendingChunk);

      // 3. Clause boundaries when text is getting long
      if (match == null && _pendingChunk.length > 40) {
        match = RegExp(r'[,;:]\s+').firstMatch(_pendingChunk);
      }

      if (match == null) break;

      final sentence = _pendingChunk.substring(0, match.end).trim();
      _pendingChunk = _pendingChunk.substring(match.end);
      if (sentence.isNotEmpty) {
        _ttsQueue.add(sentence);
        added = true;
      }
    }

    if (added && _state != _CallState.speaking) {
      _flushTtsQueue();
    }

    // If text is accumulating without any split point, speak it after a delay
    if (_pendingChunk.trim().isNotEmpty) {
      _chunkFlushTimer = Timer(const Duration(milliseconds: 1500), () {
        _forceFlushPending();
      });
    }
  }

  // Speaks whatever has accumulated in _pendingChunk, regardless of punctuation.
  void _forceFlushPending() {
    if (_disposed || !mounted) return;
    final text = _pendingChunk.trim();
    if (text.isEmpty) return;
    debugPrint('[TTS] Force-flushing pending text (${text.length} chars)');
    _pendingChunk = '';
    _ttsQueue.add(text);
    if (_state != _CallState.speaking) {
      _flushTtsQueue();
    }
  }

  Future<void> _sendToBot(String query) async {
    debugPrint('[BOT] Query: "$query"');
    if (_disposed || !mounted || _botBusy) return;
    _botBusy = true;
    _streamDone = false;
    _ttsQueue.clear();
    _pendingChunk = '';
    _lastPartial = '';
    _consecutiveSilences = 0;
    _chunkFlushTimer?.cancel();

    // Immediately stop STT to prevent mic picking up TTS / room feedback
    try {
      if (_stt.isListening) {
        await _stt.stop();
      }
    } catch (e) {
      debugPrint('[STT] Stop error: $e');
    }

    setState(() {
      _state = _CallState.processing;
      _userCaption = query;
      _botCaption = '';
    });

    final buf = StringBuffer();
    try {
      await for (final chunk
          in apiService.streamChat(widget.customer.id, query)) {
        if (_disposed) return;
        buf.write(chunk);
        _pendingChunk += chunk;
        if (mounted) setState(() => _botCaption = buf.toString());
        // Speak each complete sentence as soon as it arrives
        _extractSentencesToQueue();
      }

      if (_disposed || !mounted) return;
      _chunkFlushTimer?.cancel();

      // Speak any remaining text that didn't end with punctuation
      final tail = _pendingChunk.trim();
      if (tail.isNotEmpty) {
        _ttsQueue.add(tail);
        _pendingChunk = '';
      }

      _streamDone = true;
      debugPrint(
          '[BOT] Stream done. queue=${_ttsQueue.length} speaking=${_state == _CallState.speaking}');

      if (buf.toString().trim().isEmpty) {
        _botBusy = false;
        if (!_muted) _startListening();
        return;
      }

      // If TTS isn't already running, kick it off now
      if (_state != _CallState.speaking) _flushTtsQueue();
    } catch (e, st) {
      debugPrint('[BOT] Error: $e\n$st');
      _streamDone = true;
      _ttsQueue.clear();
      _botBusy = false;
      if (!_disposed && mounted && !_muted) _startListening();
    }
  }

  // ── Controls ─────────────────────────────────────────────────────────────────

  Future<void> _toggleMute() async {
    if (_muted) {
      setState(() => _muted = false);
      if (_stt.isListening) await _stt.stop();
      _lastPartial = '';
      _startListening();
    } else {
      if (_stt.isListening) await _stt.stop();
      if (_disposed || !mounted) return;
      _lastPartial = '';
      setState(() {
        _muted = true;
        if (_state == _CallState.listening) _state = _CallState.muted;
      });
    }
  }

  Future<void> _endCall() async {
    _disposed = true;
    _callTimer?.cancel();
    _ttsSafetyTimer?.cancel();
    _chunkFlushTimer?.cancel();
    _lastPartial = '';
    _ttsQueue.clear();
    await _stt.stop();
    await _tts.stop();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _disposed = true;
    _callTimer?.cancel();
    _ttsSafetyTimer?.cancel();
    _chunkFlushTimer?.cancel();
    _pulseCtrl.dispose();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String get _timerLabel {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _statusLabel => switch (_state) {
        _CallState.listening => 'Listening...',
        _CallState.processing => 'Thinking...',
        _CallState.speaking => 'Speaking...',
        _CallState.muted => 'Muted',
      };

  Color get _statusDot => switch (_state) {
        _CallState.listening => const Color(0xFF34D399),
        _CallState.processing => const Color(0xFFFBBF24),
        _CallState.speaking => const Color(0xFF60A5FA),
        _CallState.muted => const Color(0xFF6B7280),
      };

  bool get _isPulsing =>
      _state == _CallState.listening || _state == _CallState.speaking;

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const Spacer(),
            _buildAvatar(),
            const SizedBox(height: 22),
            _buildNameAndTimer(),
            const SizedBox(height: 10),
            _buildStatus(),
            const SizedBox(height: 20),
            _buildCaptions(),
            const Spacer(flex: 2),
            _buildControls(),
            const SizedBox(height: 52),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Text(
        'VOICE CALL',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.25),
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          if (_isPulsing) ...[
            Transform.scale(
              scale: _pulseAnim.value * 1.45,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.avatarFg.withValues(alpha: 0.05),
                ),
              ),
            ),
            Transform.scale(
              scale: _pulseAnim.value * 1.18,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.avatarFg.withValues(alpha: 0.10),
                ),
              ),
            ),
          ],
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: widget.avatarBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.customer.initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: widget.avatarFg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameAndTimer() {
    return Column(
      children: [
        Text(
          widget.customer.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _timerLabel,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.35),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: _statusDot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            _statusLabel,
            key: ValueKey(_state),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.45),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptions() {
    final hasContent = _userCaption.isNotEmpty || _botCaption.isNotEmpty;
    if (!hasContent) return const SizedBox(height: 60);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      constraints: const BoxConstraints(maxHeight: 130),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_userCaption.isNotEmpty) ...[
              Text('YOU',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  )),
              const SizedBox(height: 3),
              Text(_userCaption,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.45,
                  )),
            ],
            if (_botCaption.isNotEmpty) ...[
              if (_userCaption.isNotEmpty) const SizedBox(height: 10),
              Text(widget.customer.name.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  )),
              const SizedBox(height: 3),
              Text(_botCaption,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.45,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CallButton(
          icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: _muted ? 'Unmute' : 'Mute',
          bg: const Color(0xFF1C1C2E),
          iconColor: _muted
              ? const Color(0xFF6B7280)
              : Colors.white.withValues(alpha: 0.9),
          size: 58,
          onTap: _toggleMute,
        ),
        const SizedBox(width: 40),
        _CallButton(
          icon: Icons.call_end_rounded,
          label: 'End Call',
          bg: const Color(0xFFDC2626),
          iconColor: Colors.white,
          size: 66,
          onTap: _endCall,
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color iconColor;
  final double size;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.bg,
    required this.iconColor,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: size * 0.38),
          ),
          const SizedBox(height: 9),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.35),
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
