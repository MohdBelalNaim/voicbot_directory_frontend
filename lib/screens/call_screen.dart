import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  bool _silenceHandled = false; // prevents onError + onStatus both triggering silence handler
  String _lastPartial = '';

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
      await _tts.setSpeechRate(0.85);
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
        debugPrint('[TTS] Completion. muted=$_muted');
        if (_disposed || !mounted) return;
        if (_muted) {
          setState(() => _state = _CallState.muted);
        } else {
          _startListening();
        }
      });

      _tts.setErrorHandler((msg) {
        debugPrint('[TTS] Error: $msg');
        if (_disposed || !mounted) return;
        if (msg == 'interrupted') return; // caused by our own stop() — ignore
        if (!_muted) _startListening();
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
          if (_disposed || !mounted || _state != _CallState.listening) return;
          if (e.errorMsg == 'no-speech' || e.errorMsg == 'audio-capture') {
            _handleSilence();
          } else {
            Future.delayed(const Duration(seconds: 1), _startListening);
          }
        },
        onStatus: (status) {
          debugPrint('[STT] Status: $status  state=$_state guard=$_listeningGuard');
          if (_disposed || !mounted) return;
          if ((status == 'done' || status == 'notListening') &&
              _state == _CallState.listening &&
              !_muted &&
              !_listeningGuard) {
            final words = _lastPartial.trim();
            if (words.isNotEmpty) {
              _lastPartial = '';
              _silenceHandled = false;
              debugPrint('[STT] Using last partial as final: "$words"');
              _sendToBot(words);
            } else {
              _handleSilence();
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

  Future<void> _playWelcome() async {
    if (_disposed || !mounted) return;
    _startTimer();
    setState(() => _state = _CallState.speaking);
    final text = 'Hello from ${widget.customer.name}';
    debugPrint('[TTS] Speaking welcome: "$text"');
    final result = await _tts.speak(text);
    debugPrint('[TTS] speak() returned: $result');
    // Completion handler fires when done → calls _startListening
  }

  // Called when STT times out with no speech detected.
  // Speaks a gentle prompt so the user knows the bot is still active,
  // then the TTS completion handler restarts listening automatically.
  void _handleSilence() {
    if (_disposed || !mounted || _muted || _silenceHandled) return;
    _silenceHandled = true; // guard: onError + onStatus can both fire for no-speech
    debugPrint('[CALL] Silence detected — speaking waiting prompt');
    setState(() => _state = _CallState.speaking);
    _tts.speak("I'm waiting for your response. Go ahead.");
    // TTS completion handler → _startListening, which resets _silenceHandled
  }

  Future<void> _startListening() async {
    debugPrint('[STT] _startListening  ready=$_sttReady muted=$_muted guard=$_listeningGuard');
    if (_disposed || !mounted || !_sttReady || _muted || _listeningGuard) return;
    _listeningGuard = true;
    try {
      if (_stt.isListening) {
        await _stt.stop();
        await Future.delayed(const Duration(milliseconds: 150));
      }
      if (_disposed || !mounted || _muted) return;
      setState(() {
        _state = _CallState.listening;
        _userCaption = '';
        _botCaption = '';
        _silenceHandled = false;
      });
      debugPrint('[STT] Calling listen()');
      await _stt.listen(
        onResult: _onSttResult,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 5),
        ),
      );
      debugPrint('[STT] listen() returned  isListening=${_stt.isListening}');
    } finally {
      _listeningGuard = false;
    }
  }

  void _onSttResult(SpeechRecognitionResult result) {
    debugPrint('[STT] Result: "${result.recognizedWords}"  final=${result.finalResult}');
    if (_disposed || !mounted) return;
    // Track latest partial so we can use it if Chrome ends without final=true
    _lastPartial = result.recognizedWords;
    setState(() => _userCaption = result.recognizedWords);
    if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
      _lastPartial = '';
      _sendToBot(result.recognizedWords.trim());
    }
  }

  Future<void> _sendToBot(String query) async {
    debugPrint('[BOT] Query: "$query"');
    if (_disposed || !mounted) return;
    setState(() {
      _state = _CallState.processing;
      _userCaption = query;
      _botCaption = '';
    });

    final buf = StringBuffer();
    try {
      // Stream the response and show it as captions in real time
      await for (final chunk in ApiService.streamChat(widget.customer.id, query)) {
        if (_disposed) return;
        buf.write(chunk);
        if (mounted) setState(() => _botCaption = buf.toString());
      }

      if (_disposed || !mounted) return;
      final reply = buf.toString().trim();
      debugPrint('[BOT] Reply (${reply.length} chars): '
          '"${reply.substring(0, reply.length.clamp(0, 80))}"');

      if (reply.isEmpty) {
        if (!_muted) _startListening();
        return;
      }

      // Speak the full response — completion handler goes back to listening
      setState(() => _state = _CallState.speaking);
      debugPrint('[TTS] Speaking reply...');
      final result = await _tts.speak(reply);
      debugPrint('[TTS] speak() returned: $result');
    } catch (e, st) {
      debugPrint('[BOT] Error: $e\n$st');
      if (!_disposed && mounted && !_muted) _startListening();
    }
  }

  // ── Controls ─────────────────────────────────────────────────────────────────

  Future<void> _toggleMute() async {
    if (_muted) {
      setState(() => _muted = false);
      if (_stt.isListening) await _stt.stop();
      _startListening();
    } else {
      if (_stt.isListening) await _stt.stop();
      if (_disposed || !mounted) return;
      setState(() {
        _muted = true;
        if (_state == _CallState.listening) _state = _CallState.muted;
      });
    }
  }

  Future<void> _endCall() async {
    _disposed = true;
    _callTimer?.cancel();
    await _stt.stop();
    await _tts.stop();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _disposed = true;
    _callTimer?.cancel();
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
                width: 88, height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.avatarFg.withValues(alpha: 0.05),
                ),
              ),
            ),
            Transform.scale(
              scale: _pulseAnim.value * 1.18,
              child: Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.avatarFg.withValues(alpha: 0.10),
                ),
              ),
            ),
          ],
          Container(
            width: 88, height: 88,
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
          width: 6, height: 6,
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
            width: size, height: size,
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
