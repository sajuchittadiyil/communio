import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/module_background.dart';
import '../data/ask_communio_service.dart';
import '../models/ask_communio_models.dart';

class AskCommunioScreen extends StatefulWidget {
  const AskCommunioScreen({required this.service, this.onEntity, super.key});

  final AskCommunioService service;
  final ValueChanged<AskCommunioEntityReference>? onEntity;

  @override
  State<AskCommunioScreen> createState() => _AskCommunioScreenState();
}

class _AskCommunioScreenState extends State<AskCommunioScreen> {
  static const suggestions = [
    'Who are the current Community Superiors?',
    'Who made first profession in 1990?',
    'Who served at St. Joseph School?',
    'How many members are from Kerala?',
    'Who is currently on leave?',
    'What is our Province motto?',
  ];

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  AskCommunioResponse? _response;
  String? _error;
  String? _lastQuestion;
  bool _loading = false;
  AskCommunioContext? _context;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit([String? value]) async {
    final question = (value ?? _controller.text).trim();
    if (question.length < 3 || _loading) return;
    _controller.text = question;
    _focusNode.unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _response = null;
      _lastQuestion = question;
    });
    try {
      final response = await widget.service.ask(
        AskCommunioRequest(question: question, context: _context),
      );
      if (mounted) {
        setState(() {
          _response = response;
          if (response.context != null) _context = response.context;
        });
      }
    } on AskCommunioException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Ask Communio is temporarily unavailable.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.transparent,
    appBar: AppBar(title: const Text('Ask Communio')),
    body: ModuleBackground(
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Preserve the Past. Understand the Present.',
                      style: AppTypography.responsive(
                        context,
                      ).headlineSmall.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Connect people, places and history through authorized Communio records.',
                      style: AppTypography.responsive(
                        context,
                      ).bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _QuestionField(
                      controller: _controller,
                      focusNode: _focusNode,
                      loading: _loading,
                      onSubmitted: _submit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_loading) const _LoadingState(),
                    if (_error != null)
                      _ErrorState(
                        message: _error!,
                        onRetry: () => _submit(_lastQuestion),
                      )
                    else if (_response case final response?)
                      _Answer(response: response, onEntity: widget.onEntity)
                    else
                      _Suggestions(onSelected: _submit),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _QuestionField extends StatelessWidget {
  const _QuestionField({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final ValueChanged<String> onSubmitted;
  @override
  Widget build(BuildContext context) => TextField(
    key: const Key('ask-communio-question'),
    controller: controller,
    focusNode: focusNode,
    minLines: 1,
    maxLines: 4,
    textInputAction: TextInputAction.send,
    onSubmitted: loading ? null : onSubmitted,
    decoration: InputDecoration(
      hintText: 'Ask anything about your Province…',
      prefixIcon: const Icon(Icons.auto_awesome_rounded),
      suffixIcon: IconButton(
        tooltip: 'Ask Communio',
        onPressed: loading ? null : () => onSubmitted(controller.text),
        icon: const Icon(Icons.send_rounded),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
  );
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onSelected});
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Try asking', style: AppTypography.responsive(context).titleSmall),
      const SizedBox(height: AppSpacing.sm),
      for (final question in _AskCommunioScreenState.suggestions)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: OutlinedButton.icon(
            onPressed: () => onSelected(question),
            icon: const Icon(Icons.search_rounded),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(question),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
    ],
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.xl),
    child: Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: AppSpacing.md),
        Text('Checking Communio records…'),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _Panel(
    color: AppColors.error,
    child: Column(
      children: [
        Text(message),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

class _Answer extends StatefulWidget {
  const _Answer({required this.response, required this.onEntity});
  final AskCommunioResponse response;
  final ValueChanged<AskCommunioEntityReference>? onEntity;

  @override
  State<_Answer> createState() => _AnswerState();
}

class _AnswerState extends State<_Answer> {
  bool _showAllEntities = false;

  @override
  Widget build(BuildContext context) {
    final response = widget.response;
    final empty = response.items.isEmpty && response.entities.isEmpty;
    final visibleEntities = _showAllEntities
        ? response.entities
        : response.entities.take(10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          color: empty ? AppColors.warning : AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Communio answer',
                    style: AppTypography.responsive(context).titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SelectableText(
                response.answer,
                style: AppTypography.responsive(context).bodyLarge,
              ),
              if (response.warning case final warning?) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  warning,
                  style: AppTypography.responsive(
                    context,
                  ).bodySmall.copyWith(color: AppColors.secondaryDark),
                ),
              ],
              if (response.entities.isNotEmpty && widget.onEntity != null) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: visibleEntities
                      .where((entity) => entity.id.isNotEmpty)
                      .map(
                        (entity) => OutlinedButton.icon(
                          onPressed: () => widget.onEntity!(entity),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(entity.label),
                        ),
                      )
                      .toList(),
                ),
                if (response.entities.length > 10) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _showAllEntities = !_showAllEntities),
                    icon: Icon(
                      _showAllEntities
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                    label: Text(
                      _showAllEntities
                          ? 'Show fewer'
                          : 'Show all ${response.entities.length}',
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        if (response.sources.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Evidence from Communio',
            style: AppTypography.responsive(context).titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _Panel(
            color: AppColors.success,
            child: Column(
              children: response.sources
                  .map(
                    (source) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.verified_outlined),
                      title: Text(source.label),
                      subtitle: source.detail == null
                          ? Text(source.sourceType)
                          : Text(source.detail!),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.color, required this.child});
  final Color color;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: color.withValues(alpha: .22)),
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: child,
  );
}
