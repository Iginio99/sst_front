import 'package:flutter/material.dart';
import '../models/module.dart';
import '../models/quiz.dart';
import '../services/training_service.dart';
import '../utils/colors.dart';
import '../services/session_service.dart';

class QuizScreen extends StatefulWidget {
  final Module module;

  const QuizScreen({Key? key, required this.module}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _trainingService = TrainingService();
  QuizData? _quiz;
  QuizResult? _result;
  bool _loading = true;
  bool _submitting = false;
  int _currentIndex = 0;
  final Map<int, int> _answers = {}; // questionId -> optionId

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final data = await _trainingService.fetchQuiz(
      widget.module.id,
      onError: _showApiError,
    );
    setState(() {
      _quiz = data;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!SessionManager.instance.hasPermission('training.quiz')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes permiso para enviar evaluaciones')),
      );
      return;
    }
    if (_quiz == null) return;
    setState(() => _submitting = true);
    final answersPayload = _answers.entries
        .map((e) => QuizAnswerPayload(questionId: e.key, optionId: e.value))
        .toList();
    final result = await _trainingService.submitQuiz(widget.module.id, answersPayload);
    setState(() {
      _submitting = false;
      _result = result;
    });
    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el quiz. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF6FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_quiz == null) {
      return const Center(child: Text('No hay quiz configurado para este modulo.'));
    }
    if (_result != null) {
      return _buildResult();
    }

    final question = _quiz!.questions[_currentIndex];
    final selected = _answers[question.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackButton(),
        const SizedBox(height: 16),
        _buildHeader(),
        const SizedBox(height: 24),
        _buildProgress(questionIndex: _currentIndex, total: _quiz!.questions.length),
        const SizedBox(height: 24),
        Text(
          question.prompt,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textGray900,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        ...question.options.map((opt) => _buildOption(opt, selected == opt.id)).toList(),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selected == null || _submitting ? null : _nextOrSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              disabledBackgroundColor: AppColors.bgGray100,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: selected != null ? 4 : 0,
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _currentIndex == _quiz!.questions.length - 1 ? 'Enviar' : 'Continuar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.arrow_back, color: AppColors.primaryBlue, size: 20),
            SizedBox(width: 8),
            Text(
              'Volver',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF59E0B),
                Color(0xFFEA580C),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.moduleAmber.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Evaluacion del Modulo',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textGray900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.module.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textGray600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgress({required int questionIndex, required int total}) {
    final progress = (questionIndex + 1) / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pregunta ${questionIndex + 1} de $total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray600,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.moduleOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: AppColors.bgGray100,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(QuizOption option, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          final qId = _quiz!.questions[_currentIndex].id;
          setState(() {
            _answers[qId] = option.id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected ? AppColors.bgBlue50 : Colors.white,
            border: Border.all(
              color: selected ? AppColors.primaryBlue : AppColors.borderGray200,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primaryBlue : AppColors.borderGray200,
                    width: 2,
                  ),
                  color: selected ? AppColors.primaryBlue : Colors.transparent,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppColors.primaryBlue : AppColors.textGray800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final passed = _result?.passed == true;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.error,
          size: 96,
          color: passed ? AppColors.statusGreen : AppColors.statusRed,
        ),
        const SizedBox(height: 16),
        Text(
          passed ? 'Aprobado' : 'Reprobado',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textGray900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Puntaje: ${_result?.score ?? 0}%',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textGray700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Respuestas correctas: ${_result?.correctAnswers ?? 0}/${_result?.totalQuestions ?? 0}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textGray600,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Volver',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _nextOrSubmit() {
    if (_quiz == null) return;
    final isLast = _currentIndex == _quiz!.questions.length - 1;
    if (isLast) {
      _submit();
    } else {
      setState(() => _currentIndex += 1);
    }
  }

  void _showApiError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ocurrio un fallo al cargar la API'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
