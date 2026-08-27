import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/shell/provincial_app_shell.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/constants/assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../organization_identity/data/organization_identity_repository.dart';
import '../../organization_identity/data/supabase_organization_identity_repository.dart';
import '../../organization_identity/models/organization_identity_models.dart';
import '../../access/data/access_repository.dart';
import '../../access/models/app_access_context.dart';

class AuthenticatedShell extends StatefulWidget {
  const AuthenticatedShell({
    this.identityRepository,
    this.accessRepository,
    super.key,
  });

  final OrganizationIdentityRepository? identityRepository;
  final AccessRepository? accessRepository;

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<AuthenticatedShell> {
  OrganizationIdentitySnapshot? _identity;
  bool _showWelcome = true;
  Timer? _dismissTimer;
  late Future<AppAccessContext> _accessFuture;

  OrganizationIdentityRepository? get _repository =>
      widget.identityRepository ??
      (AppEnvironment.hasSupabaseConfiguration
          ? SupabaseOrganizationIdentityRepository(Supabase.instance.client)
          : null);

  @override
  void initState() {
    super.initState();
    final accessRepository =
        widget.accessRepository ??
        (AppEnvironment.hasSupabaseConfiguration
            ? SupabaseAccessRepository(Supabase.instance.client)
            : null);
    _accessFuture =
        accessRepository?.resolveCurrentAccess() ??
        Future.value(const AppAccessContext.provincial());
    _accessFuture.then((_) => _loadIdentity()).catchError((_) {
      if (mounted) setState(() => _showWelcome = false);
    });
  }

  Future<void> _loadIdentity() async {
    final repository = _repository;
    if (repository == null) {
      if (mounted) setState(() => _showWelcome = false);
      return;
    }
    await repository
        .fetchIdentity()
        .timeout(const Duration(seconds: 2))
        .then((identity) {
          if (!mounted) return;
          setState(() => _identity = identity);
          _dismissTimer = Timer(const Duration(milliseconds: 700), () {
            if (mounted) setState(() => _showWelcome = false);
          });
        })
        .catchError((_) {
          if (mounted) setState(() => _showWelcome = false);
        });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppAccessContext>(
    future: _accessFuture,
    builder: (context, accessSnapshot) {
      if (accessSnapshot.connectionState != ConnectionState.done) {
        return const ColoredBox(
          color: AppColors.background,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (!accessSnapshot.hasData) {
        return const Scaffold(
          body: Center(
            child: Text('Your Communio access has not been configured.'),
          ),
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          ProvincialAppShell(
            organizationIdentityRepository: _repository,
            access: accessSnapshot.requireData,
          ),
          if (_showWelcome)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.background,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: _WelcomeContent(identity: _identity),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({required this.identity});
  final OrganizationIdentitySnapshot? identity;

  @override
  Widget build(BuildContext context) {
    final styles = AppTypography.responsive(context);
    final congregation = identity?.congregation;
    final province = identity?.province;
    final imageUrl =
        congregation?.founderImageUrl ?? congregation?.patronSaintImageUrl;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppAssets.logo, width: 76, height: 76),
          const SizedBox(height: AppSpacing.lg),
          if (congregation == null)
            const CircularProgressIndicator(color: AppColors.secondaryDark)
          else ...[
            Text(
              congregation.name,
              textAlign: TextAlign.center,
              style: styles.displayTitle.copyWith(color: AppColors.primary),
            ),
            Text(
              province!.name,
              textAlign: TextAlign.center,
              style: styles.sectionTitle.copyWith(
                color: AppColors.secondaryDark,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.secondary.withValues(alpha: .12),
              foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
              child: imageUrl == null
                  ? const Icon(
                      Icons.auto_awesome_rounded,
                      size: 40,
                      color: AppColors.secondaryDark,
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (province.motto != null)
              Text(
                province.motto!,
                textAlign: TextAlign.center,
                style: styles.bodyPrimary.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Welcome to Communio',
              style: styles.titleLarge.copyWith(color: AppColors.primary),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'COMMUNIO',
            style: styles.labelMedium.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
