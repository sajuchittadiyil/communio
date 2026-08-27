enum MemberCelebrationType {
  birthday,
  feastDay,
  firstProfession,
  perpetualProfession,
  ordination,
}

class MemberCelebration {
  const MemberCelebration({
    required this.memberId,
    required this.religiousId,
    required this.displayName,
    required this.type,
    required this.date,
    this.photoUrl,
    this.sourceYear,
  });

  final String memberId;
  final String religiousId;
  final String displayName;
  final String? photoUrl;
  final MemberCelebrationType type;
  final DateTime date;
  final int? sourceYear;

  String get typeLabel => switch (type) {
    MemberCelebrationType.birthday => 'Birthday',
    MemberCelebrationType.feastDay => 'Feast Day',
    MemberCelebrationType.firstProfession => 'First Profession Anniversary',
    MemberCelebrationType.perpetualProfession =>
      'Perpetual Profession Anniversary',
    MemberCelebrationType.ordination => 'Ordination Anniversary',
  };
}
