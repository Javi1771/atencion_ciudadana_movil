// lib/controllers/voice_incidence_controller.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:app_atencion_ciudadana/data/voice_questions.dart';
import 'package:app_atencion_ciudadana/utils/voice_utils.dart';
import 'package:app_atencion_ciudadana/widgets/alert_helper.dart';
import 'package:app_atencion_ciudadana/screens/voice_review_screen.dart';

class VoiceIncidenceController extends ChangeNotifier {
  //* Services
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  //* State variables
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isComplete = false;
  bool _disposed = false;
  bool _processingAnswer = false; //! evita procesar doble
  String _transcribedText = '';
  final Map<String, dynamic> _formData = {};
  int _currentQuestion = 0;

  //* Questions data
  List<Map<String, dynamic>> _questions = [];

  //* Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get transcribedText => _transcribedText;
  Map<String, dynamic> get formData => _formData;
  int get currentQuestion => _currentQuestion;
  List<Map<String, dynamic>> get questions => _questions;

  //* Animation controllers (passed from UI)
  AnimationController? _pulseController;
  AnimationController? _waveController;
  AnimationController? _slideController;
  AnimationController? _fadeController;

  //* Silencio: auto-finalización si no llegan más fragmentos
  static const Duration _autoAdvanceSilence = Duration(milliseconds: 1200);
  Timer? _silenceTimer;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void setAnimationControllers({
    required AnimationController pulseController,
    required AnimationController waveController,
    required AnimationController slideController,
    required AnimationController fadeController,
  }) {
    _pulseController = pulseController;
    _waveController = waveController;
    _slideController = slideController;
    _fadeController = fadeController;
  }

  Future<void> initialize() async {
    _questions = VoiceQuestions.getQuestions();
    await _initializeSpeech();
    await _initializeTts();
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) async {
        if (_disposed) return;
        if (status == 'done' && _isListening) {
          //* Finaliza por evento del plugin
          await _finalizeListeningAndProcess();
        }
      },
      onError: (error) async {
        if (_disposed) return;
        _isListening = false;
        _stopAnimations();
        _cancelSilenceTimer();
        _safeNotify();
      },
    );

    if (!available) {
      AlertHelper.showAlert(
        'El reconocimiento de voz no está disponible en este dispositivo',
        type: AlertType.error,
      );
    } else {
      startInterview();
    }
  }

  Future<void> _initializeTts() async {
    _tts.setStartHandler(() {
      if (_disposed) return;
      _isSpeaking = true;
      _safeNotify();
    });

    _tts.setCompletionHandler(() {
      if (_disposed) return;
      _isSpeaking = false;
      _safeNotify();

      //! No reanudar escucha si ya terminó
      if (_isComplete) return;
      if (_currentQuestion < _questions.length) {
        startListening();
      }
    });

    _tts.setErrorHandler((message) {
      if (_disposed) return;
      _isSpeaking = false;
      _safeNotify();
    });

    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}

    await _tts.setLanguage("es_MX");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void startInterview() {
    if (_disposed || _questions.isEmpty) return;
    _isComplete = false;
    _slideController?.forward();
    speak(_questions[_currentQuestion]['question']);
  }

  Future<void> speak(String text) async {
    if (_disposed || text.isEmpty || _isComplete) return;
    try {
      await _tts.stop();
    } catch (_) {}
    if (_disposed || _isComplete) return;
    await _tts.speak(text);
  }

  Future<void> startListening({bool append = false}) async {
    if (_disposed || _isSpeaking || _isComplete) return;

    _isListening = true;
    if (!append) _transcribedText = '';
    _processingAnswer = false; //* resetea lock por cada escucha
    _safeNotify();
    _startAnimations();
    _cancelSilenceTimer();

    try {
      await _speech.listen(
        onResult: (result) async {
          if (_disposed || _isComplete) return;
          final heard = result.recognizedWords.toUpperCase();

          _transcribedText = (append && _transcribedText.isNotEmpty)
              ? '$_transcribedText $heard'
              : heard;

          _safeNotify();
          if (_transcribedText.isNotEmpty) {
            _fadeController?.forward();
          }

          //! Reinicia el timer de silencio en cada fragmento
          _kickSilenceTimer();

          //* Si el motor marcó resultado final, procesa ya
          if (result.finalResult == true) {
            await _finalizeListeningAndProcess();
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 10), //* tolerancia entre palabras
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        localeId: "es_MX",
      );
    } catch (_) {
      _isListening = false;
      _stopAnimations();
      _cancelSilenceTimer();
      _safeNotify();
    }
  }

  Future<void> stopListening() async {
    if (_disposed) return;
    await _finalizeListeningAndProcess();
  }

  //? ============ Silencio / finalización ============

  void _kickSilenceTimer() {
    _cancelSilenceTimer();
    _silenceTimer = Timer(_autoAdvanceSilence, () async {
      if (_disposed || !_isListening || _processingAnswer) return;
      await _finalizeListeningAndProcess();
    });
  }

  void _cancelSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  Future<void> _finalizeListeningAndProcess() async {
    if (_disposed || _processingAnswer) return;
    _processingAnswer = true;

    _isListening = false;
    _stopAnimations();
    _cancelSilenceTimer();
    _safeNotify();

    try {
      await _speech.stop();
    } catch (_) {}

    //? Regla especial: extender CURP si quedó corta (y no dijo OMItir)
    if (!_isComplete &&
        _currentQuestion < _questions.length &&
        (_questions[_currentQuestion]['field'] as String) == 'curp') {
      final clean = _transcribedText.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
      if (clean != 'OMITIR' && clean.length < 18) {
        _processingAnswer = false; //* volvemos a escuchar
        await startListening(append: true);
        return;
      }
    }

    _processAnswer();
  }

  void _startAnimations() {
    _pulseController?.repeat(reverse: true);
    _waveController?.repeat();
  }

  void _stopAnimations() {
    _pulseController?.stop();
    _waveController?.stop();
  }

  ///* Calla todo: TTS, reconocimiento y animaciones.
  Future<void> silence() async {
    if (_disposed) return;
    try {
      _stopAnimations();
      _cancelSilenceTimer();
      _isListening = false;
      _isSpeaking = false;
      _safeNotify();
      try {
        await _speech.stop();
        await _speech.cancel();
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}
    } catch (_) {}
  }

  //? ===== Helpers/validación =====

  void _processAnswer() {
    if (_disposed || _isComplete) return;

    if (_transcribedText.isEmpty) {
      _nextQuestion();
      return;
    }

    final currentQ = _questions[_currentQuestion];
    final result = VoiceUtils.processVoiceInput(
      transcribedText: _transcribedText,
      fieldType: currentQ['field'],
      options: currentQ['options'],
      allowSkip: currentQ['skipOption'] ?? false,
      validator: currentQ['validator'],
    );

    switch (result.status) {
      case VoiceProcessStatus.success:
        _formData[currentQ['field']] = result.value!;
        _safeNotify();
        _nextQuestion();
        break;
      case VoiceProcessStatus.skipped:
        _nextQuestion();
        break;
      case VoiceProcessStatus.error:
        //! No avanza: repite instrucción y vuelve a escuchar esta misma pregunta
        speak('${result.errorMessage}. Por favor, intente nuevamente.');
        break;
      case VoiceProcessStatus.empty:
        _nextQuestion();
        break;
    }
  }

  void _nextQuestion() {
    if (_disposed || _isComplete) return;

    _transcribedText = '';
    _fadeController?.reset();
    _slideController?.reset();

    final nextIndex = VoiceQuestions.getNextQuestionIndex(
      _questions,
      _currentQuestion,
      _formData,
    );

    if (nextIndex < _questions.length) {
      _currentQuestion = nextIndex;
      _safeNotify();
      _slideController?.forward();
      speak(_questions[_currentQuestion]['question']);
    } else {
      _completeInterview();
    }
  }

  void _completeInterview() {
    if (_isComplete) return;
    _isComplete = true;
    _currentQuestion = _questions.length;

    _stopAnimations();
    _cancelSilenceTimer();
    try {
      _speech.stop();
      _speech.cancel();
    } catch (_) {}
    try {
      _tts.stop();
    } catch (_) {}

    _safeNotify();
  }

  bool canGoToReview() {
    return VoiceQuestions.validateIdentification(_formData) == null;
  }

  String? getIdentificationError() {
    return VoiceQuestions.validateIdentification(_formData);
  }

  void restartInterview() {
    if (_disposed) return;
    _isComplete = false;
    _currentQuestion = 0;
    _transcribedText = '';
    _formData.clear();
    _fadeController?.reset();
    _slideController?.reset();
    _cancelSilenceTimer();
    _safeNotify();

    if (_questions.isNotEmpty) {
      _slideController?.forward();
      speak(_questions[_currentQuestion]['question']);
    }
  }

  void repeatQuestion() {
    if (_disposed || _isComplete) return;
    if (_questions.isEmpty || _currentQuestion >= _questions.length) return;
    speak(_questions[_currentQuestion]['question']);
  }

  //* Progress
  int getTotalValidQuestions() {
    return VoiceQuestions.getTotalValidQuestions(_questions, _formData);
  }

  int getCurrentValidQuestionIndex() {
    return VoiceQuestions.getCurrentValidQuestionIndex(
      _questions,
      _currentQuestion,
      _formData,
    );
  }

  double getProgress() {
    final total = getTotalValidQuestions();
    final current = getCurrentValidQuestionIndex();
    return total > 0 ? current / total : 0.0;
  }

  String getFieldDescription() {
    if (_questions.isEmpty || _currentQuestion >= _questions.length) return '';
    final field = _questions[_currentQuestion]['field'];
    switch (field) {
      case 'curp':
        return 'Identificación (CURP opcional)';
      case 'nombre':
        return 'Identificación (Nombre)';
      default:
        return VoiceQuestions.getFieldLabels()[field] ?? '';
    }
  }

  bool isInterviewComplete() => _isComplete;

  void navigateToReview(BuildContext context) async {
    if (_disposed) return;

    final identificationError = getIdentificationError();
    if (identificationError != null) {
      speak(identificationError);
      AlertHelper.showAlert(identificationError, type: AlertType.error);
      return;
    }
    if (!isInterviewComplete()) return;

    await silence();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VoiceReviewScreen(
              formData: _formData,
              onReturnToVoice: restartInterview,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelSilenceTimer();
    try {
      _speech.stop();
      _speech.cancel();
    } catch (_) {}
    try {
      _tts.stop();
    } catch (_) {}
    _stopAnimations();
    super.dispose();
  }
}
