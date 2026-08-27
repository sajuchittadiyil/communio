String? communityResponsibilityLabel(String? code) {
  final normalized = code?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;
  return switch (normalized) {
    'superior' || 'community_superior' => 'Community Superior',
    'accountant' ||
    'community_accountant' ||
    'bursar' ||
    'community_bursar' => 'Community Accountant',
    'member' || 'community_member' => 'Member',
    _ => null,
  };
}
