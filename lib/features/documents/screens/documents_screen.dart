import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../data/documents_repository.dart';
import '../models/province_document.dart';

enum DocumentQuickFilter { all, recent, communities, ministries, governance }

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({
    required this.repository,
    this.onOpenDocument,
    super.key,
  });

  final DocumentsRepository repository;
  final ValueChanged<ProvinceDocument>? onOpenDocument;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<List<ProvinceDocument>> _future;
  final _search = TextEditingController();
  DocumentQuickFilter _quickFilter = DocumentQuickFilter.all;
  DocumentCategory? _category;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = widget.repository.fetchDocuments();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.transparent,
    child: FutureBuilder<List<ProvinceDocument>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _DocumentsFailure(onRetry: () => setState(_load));
        }
        final documents = snapshot.data ?? const <ProvinceDocument>[];
        return _buildContent(documents);
      },
    ),
  );

  Widget _buildContent(List<ProvinceDocument> documents) {
    final filtered = filterDocuments(
      documents,
      query: _search.text,
      quickFilter: _quickFilter,
      category: _category,
    );
    return CustomScrollView(
      key: const Key('documents-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DOCUMENTS',
                    style: AppTypography.responsive(
                      context,
                    ).pageTitle.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${documents.length} Documents',
                    style: AppTypography.responsive(
                      context,
                    ).titleMedium.copyWith(color: AppColors.secondaryDark),
                  ),
                  Text(
                    'Institutional records and reports',
                    style: AppTypography.responsive(
                      context,
                    ).bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _DocumentMetrics(documents: documents),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search documents...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _FilterPanel(
                    quickFilter: _quickFilter,
                    category: _category,
                    onQuickFilter: (value) => setState(() {
                      _quickFilter = value;
                      _category = null;
                    }),
                    onCategory: (value) => setState(() {
                      _category = value;
                      if (value != null) {
                        _quickFilter = DocumentQuickFilter.all;
                      }
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (documents.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _DocumentsEmpty(message: 'No documents available'),
          )
        else if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _DocumentsEmpty(
              message: 'No matching documents',
              onClear: _clearFilters,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _DocumentCard(
                document: filtered[index],
                onTap: () => _open(filtered[index]),
              ),
            ),
          ),
      ],
    );
  }

  void _clearFilters() => setState(() {
    _search.clear();
    _quickFilter = DocumentQuickFilter.all;
    _category = null;
  });

  void _open(ProvinceDocument document) {
    if (widget.onOpenDocument case final callback?) {
      callback(document);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentDetailScreen(document: document),
      ),
    );
  }
}

List<ProvinceDocument> filterDocuments(
  List<ProvinceDocument> documents, {
  String query = '',
  DocumentQuickFilter quickFilter = DocumentQuickFilter.all,
  DocumentCategory? category,
}) {
  final normalized = query.trim().toLowerCase();
  final filtered = documents.where((document) {
    final searchText = [
      document.title,
      document.category.label,
      document.description,
      document.relatedEntityName,
      document.documentType,
    ].whereType<String>().join(' ').toLowerCase();
    if (normalized.isNotEmpty && !searchText.contains(normalized)) return false;
    if (category != null && document.category != category) return false;
    return switch (quickFilter) {
      DocumentQuickFilter.all || DocumentQuickFilter.recent => true,
      DocumentQuickFilter.communities =>
        document.category == DocumentCategory.community,
      DocumentQuickFilter.ministries =>
        document.category == DocumentCategory.ministry,
      DocumentQuickFilter.governance =>
        document.category == DocumentCategory.governance ||
            document.category == DocumentCategory.meetings,
    };
  }).toList()..sort((a, b) => b.recentDate.compareTo(a.recentDate));
  return quickFilter == DocumentQuickFilter.recent
      ? filtered.take(8).toList()
      : filtered;
}

class _DocumentMetrics extends StatelessWidget {
  const _DocumentMetrics({required this.documents});
  final List<ProvinceDocument> documents;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        'Documents',
        documents.length,
        Icons.folder_copy_outlined,
        AppColors.primary,
      ),
      (
        'Reports',
        documents
            .where((d) => d.documentType.toLowerCase().contains('report'))
            .length,
        Icons.description_outlined,
        AppColors.cyan,
      ),
      (
        'Policies',
        documents.where((d) => d.category == DocumentCategory.policies).length,
        Icons.policy_outlined,
        AppColors.purple,
      ),
      (
        'Meeting Records',
        documents.where((d) => d.category == DocumentCategory.meetings).length,
        Icons.groups_outlined,
        AppColors.secondaryDark,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics) _Metric(metric: metric, width: width),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.metric, required this.width});
  final (String, int, IconData, Color) metric;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: metric.$4.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: metric.$4.withValues(alpha: .14)),
    ),
    child: Row(
      children: [
        Icon(metric.$3, color: metric.$4, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            '${metric.$2} ${metric.$1}',
            style: AppTypography.responsive(context).labelMedium.copyWith(
              color: metric.$4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.quickFilter,
    required this.category,
    required this.onQuickFilter,
    required this.onCategory,
  });
  final DocumentQuickFilter quickFilter;
  final DocumentCategory? category;
  final ValueChanged<DocumentQuickFilter> onQuickFilter;
  final ValueChanged<DocumentCategory?> onCategory;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SingleChildScrollView(
        key: const Key('document-quick-filters'),
        scrollDirection: Axis.horizontal,
        primary: false,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Row(
          children: [
            for (final filter in DocumentQuickFilter.values) ...[
              ChoiceChip(
                label: Text(switch (filter) {
                  DocumentQuickFilter.all => 'All',
                  DocumentQuickFilter.recent => 'Recent',
                  DocumentQuickFilter.communities => 'Communities',
                  DocumentQuickFilter.ministries => 'Ministries',
                  DocumentQuickFilter.governance => 'Governance',
                }),
                selected: quickFilter == filter && category == null,
                onSelected: (_) => onQuickFilter(filter),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      DropdownButtonFormField<DocumentCategory?>(
        initialValue: category,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'More categories',
          prefixIcon: Icon(Icons.tune_rounded),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<DocumentCategory?>(
            value: null,
            child: Text('All categories'),
          ),
          for (final value in DocumentCategory.values)
            DropdownMenuItem(value: value, child: Text(value.label)),
        ],
        onChanged: onCategory,
      ),
    ],
  );
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document, required this.onTap});
  final ProvinceDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _categoryColor(document.category);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.picture_as_pdf_outlined, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          style: AppTypography.responsive(context).titleMedium
                              .copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${document.documentType} · ${_date(document.documentDate)}',
                          style: AppTypography.responsive(
                            context,
                          ).bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          document.category.label,
                          style: AppTypography.responsive(context).labelSmall
                              .copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                document.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.responsive(
                  context,
                ).bodySmall.copyWith(height: 1.45),
              ),
              if (document.relatedEntityName case final name?) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Related to: $name',
                  style: AppTypography.responsive(
                    context,
                  ).labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Tag(document.fileExtension.toUpperCase()),
                  _Tag(document.visibility),
                  Text(
                    document.hasFile ? 'View Document →' : 'View Details →',
                    style: AppTypography.responsive(context).labelMedium
                        .copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Text(
      text,
      style: AppTypography.responsive(
        context,
      ).labelSmall.copyWith(color: AppColors.primary),
    ),
  );
}

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({required this.document, super.key});
  final ProvinceDocument document;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Document Details')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: AppSpacing.massive,
            color: _categoryColor(document.category),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            document.title,
            textAlign: TextAlign.center,
            style: AppTypography.responsive(
              context,
            ).pageTitle.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${document.category.label} · ${_date(document.documentDate)}',
            textAlign: TextAlign.center,
            style: AppTypography.responsive(
              context,
            ).bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          if (document.relatedEntityName case final name?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text('Related to: $name', textAlign: TextAlign.center),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            document.description,
            style: AppTypography.responsive(
              context,
            ).bodyMedium.copyWith(height: 1.55),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (document.assetPath case final asset?)
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _PdfDocumentScreen(
                    title: document.title,
                    assetPath: asset,
                  ),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open Document'),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.secondaryDark,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Demo file unavailable',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Metadata is available, but no PDF has been attached to this demonstration record.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _PdfDocumentScreen extends StatelessWidget {
  const _PdfDocumentScreen({required this.title, required this.assetPath});
  final String title;
  final String assetPath;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: PdfViewer.asset(assetPath),
  );
}

class _DocumentsEmpty extends StatelessWidget {
  const _DocumentsEmpty({required this.message, this.onClear});
  final String message;
  final VoidCallback? onClear;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.folder_off_outlined,
            size: AppSpacing.massive,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTypography.responsive(context).titleMedium),
          if (onClear != null)
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
        ],
      ),
    ),
  );
}

class _DocumentsFailure extends StatelessWidget {
  const _DocumentsFailure({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error),
        const SizedBox(height: AppSpacing.sm),
        const Text('Documents could not be loaded'),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

Color _categoryColor(DocumentCategory category) => switch (category) {
  DocumentCategory.provincialAdministration ||
  DocumentCategory.strategy => AppColors.primary,
  DocumentCategory.governance ||
  DocumentCategory.policies ||
  DocumentCategory.formation => AppColors.purple,
  DocumentCategory.community || DocumentCategory.personnel => AppColors.cyan,
  DocumentCategory.ministry => AppColors.success,
  DocumentCategory.finance ||
  DocumentCategory.propertyCompliance => AppColors.secondaryDark,
  DocumentCategory.meetings => AppColors.info,
};

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';
