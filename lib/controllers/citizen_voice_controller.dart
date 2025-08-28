// lib/controllers/citizen_voice_controller.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:app_atencion_ciudadana/data/citizen_questions.dart';
import 'package:app_atencion_ciudadana/utils/citizen_voice_utils.dart';
import 'package:app_atencion_ciudadana/widgets/alert_helper.dart';
import 'package:app_atencion_ciudadana/screens/citizen_review_screen.dart';

class CitizenVoiceController extends ChangeNotifier {
  //* Services
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  //* State variables
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isComplete = false;
  bool _disposed = false;
  bool _processingAnswer = false;
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

  //* Auto-advance silence timer
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
    _questions = CitizenQuestions.getQuestions();
    await _initializeSpeech();
    await _initializeTts();
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) async {
        if (_disposed) return;
        if (status == 'done' && _isListening) {
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
      startRegistration();
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

  void startRegistration() {
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
    _processingAnswer = false;
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

          _kickSilenceTimer();

          if (result.finalResult == true) {
            await _finalizeListeningAndProcess();
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 10),
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

    //* Regla especial para CURP si quedó corta
    if (!_isComplete &&
        _currentQuestion < _questions.length &&
        (_questions[_currentQuestion]['field'] as String) == 'curp_ciudadano') {
      final clean = _transcribedText.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
      if (clean != 'OMITIR' && clean.length < 18) {
        _processingAnswer = false;
        await startListening(append: true);
        return;
      }
    }

    //* Regla especial para código postal (5 dígitos)
    if (!_isComplete &&
        _currentQuestion < _questions.length &&
        (_questions[_currentQuestion]['field'] as String) == 'codigo_postal') {
      final numbers = _transcribedText.replaceAll(RegExp(r'[^0-9]'), '');
      if (numbers.length < 5 && !_transcribedText.toUpperCase().contains('OMITIR')) {
        _processingAnswer = false;
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

  //? ===== Procesamiento de respuestas =====

  void _processAnswer() {
    if (_disposed || _isComplete) return;

    if (_transcribedText.isEmpty) {
      _nextQuestion();
      return;
    }

    final currentQ = _questions[_currentQuestion];
    final result = CitizenVoiceUtils.processVoiceInput(
      transcribedText: _transcribedText,
      fieldType: currentQ['field'],
      options: currentQ['options'],
      allowSkip: currentQ['skipOption'] ?? false,
      validator: currentQ['validator'],
    );

    switch (result.status) {
      case CitizenVoiceProcessStatus.success:
        _formData[currentQ['field']] = result.value!;
        _safeNotify();
        _nextQuestion();
        break;

      case CitizenVoiceProcessStatus.skipped:
        //* FIX: marca explícitamente el campo como omitido para que getNextQuestionIndex() avance
        _formData[currentQ['field']] = 'OMITIR';
        _safeNotify();
        _nextQuestion();
        break;

      case CitizenVoiceProcessStatus.error:
        speak('${result.errorMessage}. Por favor, intente nuevamente.');
        break;

      case CitizenVoiceProcessStatus.empty:
        _nextQuestion();
        break;
    }
  }

  void _nextQuestion() {
    if (_disposed || _isComplete) return;

    _transcribedText = '';
    _fadeController?.reset();
    _slideController?.reset();

    final nextIndex = CitizenQuestions.getNextQuestionIndex(
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
      _completeRegistration();
    }
  }

  void _completeRegistration() {
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
    return CitizenQuestions.validateRequiredFields(_formData) == null;
  }

  String? getValidationError() {
    return CitizenQuestions.validateRequiredFields(_formData);
  }

  void restartRegistration() {
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

  //* Progress tracking
  int getTotalValidQuestions() {
    return CitizenQuestions.getTotalValidQuestions(_questions, _formData);
  }

  int getCurrentValidQuestionIndex() {
    return CitizenQuestions.getCurrentValidQuestionIndex(
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
    return CitizenQuestions.getFieldLabels()[field] ?? '';
  }

  bool isRegistrationComplete() => _isComplete;

  void navigateToReview(BuildContext context) async {
    if (_disposed) return;

    final validationError = getValidationError();
    if (validationError != null) {
      speak(validationError);
      AlertHelper.showAlert(validationError, type: AlertType.error);
      return;
    }
    if (!isRegistrationComplete()) return;

    await silence();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CitizenReviewScreen(
              formData: _formData,
              onReturnToVoice: restartRegistration,
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
