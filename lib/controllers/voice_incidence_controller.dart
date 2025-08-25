// lib/controllers/voice_incidence_controller.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:app_atencion_ciudadana/data/voice_questions.dart';
import 'package:app_atencion_ciudadana/utils/voice_utils.dart';
import 'package:app_atencion_ciudadana/widgets/alert_helper.dart';
import 'package:app_atencion_ciudadana/screens/voice_review_screen.dart';

class VoiceIncidenceController extends ChangeNotifier {
  // Services
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  // State variables
  bool _isListening = false;
  bool _isSpeaking = false;
  String _transcribedText = '';
  final Map<String, dynamic> _formData = {};
  int _currentQuestion = 0;

  // Questions data
  List<Map<String, dynamic>> _questions = [];

  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get transcribedText => _transcribedText;
  Map<String, dynamic> get formData => _formData;
  int get currentQuestion => _currentQuestion;
  List<Map<String, dynamic>> get questions => _questions;

  // Animation controllers (passed from UI)
  AnimationController? _pulseController;
  AnimationController? _waveController;
  AnimationController? _slideController;
  AnimationController? _fadeController;

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
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' && _isListening) {
          _isListening = false;
          notifyListeners();
          _stopAnimations();
          _processAnswer();
        }
      },
      onError: (error) {
        // Puedes loggear más detalles si hace falta
        // print('Speech Error: $error');
        _isListening = false;
        notifyListeners();
        _stopAnimations();
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
      _isSpeaking = true;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
      if (_currentQuestion < _questions.length) {
        startListening();
      }
    });

    _tts.setErrorHandler((message) {
      _isSpeaking = false;
      notifyListeners();
      // print('TTS Error: $message');
    });

    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void startInterview() {
    _slideController?.forward();
    speak(_questions[_currentQuestion]['question']);
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _tts.speak(text);
    }
  }

  Future<void> startListening() async {
    if (_isSpeaking) return;

    _isListening = true;
    _transcribedText = '';
    notifyListeners();

    _startAnimations();

    try {
      await _speech.listen(
        onResult: (result) {
          _transcribedText = result.recognizedWords.toUpperCase();
          notifyListeners();
          if (_transcribedText.isNotEmpty) {
            _fadeController?.forward();
          }
        },
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 6),
        localeId: "es_ES",
      );
    } catch (e) {
      _isListening = false;
      notifyListeners();
      _stopAnimations();
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    notifyListeners();
    _stopAnimations();
    await _speech.stop();
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

  // ===== Helpers para validar si la pregunta actual ya fue respondida =====
  bool _hasAnswerFor(String field) {
    final v = _formData[field];
    return v != null && v.toString().trim().isNotEmpty;
  }

  bool hasAnsweredCurrentQuestion() {
    if (_currentQuestion < 0 || _currentQuestion >= _questions.length) return true;
    final field = _questions[_currentQuestion]['field'] as String;
    return _hasAnswerFor(field);
  }

  void _processAnswer() {
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
        notifyListeners();
        _nextQuestion();
        break;

      case VoiceProcessStatus.skipped:
        // Si se omite CURP, luego la lógica condicional pregunta "nombre"
        _nextQuestion();
        break;

      case VoiceProcessStatus.error:
        speak('${result.errorMessage}. Por favor, intente nuevamente.');
        break;

      case VoiceProcessStatus.empty:
        _nextQuestion();
        break;
    }
  }

  void _nextQuestion() {
    _transcribedText = '';
    _fadeController?.reset();
    _slideController?.reset();

    final nextIndex =
        VoiceQuestions.getNextQuestionIndex(_questions, _currentQuestion, _formData);

    if (nextIndex < _questions.length) {
      _currentQuestion = nextIndex;
      notifyListeners();
      _slideController?.forward();
      speak(_questions[_currentQuestion]['question']);
    } else {
      // Ya no hay más preguntas (esto se alcanza DESPUÉS de responder la última).
      notifyListeners();
    }
  }

  bool canGoToReview() {
    return VoiceQuestions.validateIdentification(_formData) == null;
  }

  String? getIdentificationError() {
    return VoiceQuestions.validateIdentification(_formData);
  }

  void restartInterview() {
    _currentQuestion = 0;
    _transcribedText = '';
    _formData.clear();
    _fadeController?.reset();
    _slideController?.reset();
    notifyListeners();

    _slideController?.forward();
    speak(_questions[_currentQuestion]['question']);
  }

  void repeatQuestion() {
    speak(_questions[_currentQuestion]['question']);
  }

  // Progress calculation methods
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

  /// Ahora solo es “completa” si no hay siguiente pregunta **y** la actual ya fue respondida
  bool isInterviewComplete() {
    final nextIndex = VoiceQuestions.getNextQuestionIndex(
      _questions,
      _currentQuestion,
      _formData,
    );
    return nextIndex >= _questions.length && hasAnsweredCurrentQuestion();
  }

  void navigateToReview(BuildContext context) {
    // Validación de identificación
    final identificationError = getIdentificationError();
    if (identificationError != null) {
      speak(identificationError);
      AlertHelper.showAlert(
        identificationError,
        type: AlertType.error,
      );
      return;
    }

    // Seguridad extra: evita navegar si aún no se respondió la última pregunta
    if (!isInterviewComplete()) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => VoiceReviewScreen(
          formData: _formData,
          onReturnToVoice: restartInterview,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _speech.stop();
    await _tts.stop();
  }
}
