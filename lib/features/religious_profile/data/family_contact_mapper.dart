import '../models/religious_profile.dart';

class FamilyContactMapper {
  const FamilyContactMapper._();

  static List<FamilyContact> fromRows(Iterable<Map<String, dynamic>> rows) {
    final contacts = <String, FamilyContact>{};
    for (final row in rows) {
      final name = _text(row, ['name']);
      if (name == null) continue;
      final relationship = _label(_text(row, ['relationship']));
      final key = '${name.toLowerCase()}|${relationship?.toLowerCase() ?? ''}';
      final previous = contacts[key];
      contacts[key] = FamilyContact(
        name: name,
        relationship: relationship ?? previous?.relationship,
        lifeStatus:
            _lifeStatus(row) ??
            previous?.lifeStatus ??
            FamilyLifeStatus.unknown,
        dateOfBirth:
            _date(row, ['date_of_birth', 'birth_date', 'dob']) ??
            previous?.dateOfBirth,
        dateOfDeath:
            _date(row, ['date_of_death', 'death_date']) ??
            previous?.dateOfDeath,
        deathYear:
            _integer(row, ['year_of_death', 'death_year']) ??
            previous?.deathYear,
        phone: _text(row, ['phone']) ?? previous?.phone,
        whatsApp: _text(row, ['whatsapp']) ?? previous?.whatsApp,
        email: _text(row, ['email']) ?? previous?.email,
        notes: _text(row, ['notes', 'remarks']) ?? previous?.notes,
        isPrimary:
            (previous?.isPrimary ?? false) || _boolean(row, ['is_primary']),
        isNextOfKin:
            (previous?.isNextOfKin ?? false) ||
            _boolean(row, ['is_next_of_kin']),
        isEmergency:
            (previous?.isEmergency ?? false) ||
            _boolean(row, ['is_emergency_contact']),
      );
    }
    final result = contacts.values.toList(growable: false);
    result.sort((a, b) {
      final relationship = _relationshipRank(a).compareTo(_relationshipRank(b));
      if (relationship != 0) return relationship;
      if (a.isEmergency != b.isEmergency) return a.isEmergency ? -1 : 1;
      if (a.isNextOfKin != b.isNextOfKin) return a.isNextOfKin ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  static int _relationshipRank(FamilyContact contact) =>
      switch (contact.relationship?.toLowerCase()) {
        'father' => 0,
        'mother' => 1,
        _ => 2,
      };

  static FamilyLifeStatus? _lifeStatus(Map<String, dynamic> row) {
    final value = _text(row, [
      'life_status',
      'life_status_code',
      'living_status',
      'status',
    ])?.toLowerCase();
    if (value == null) return null;
    if (value == 'deceased' || value == 'dead' || value == 'late') {
      return FamilyLifeStatus.deceased;
    }
    if (value == 'living' || value == 'alive') {
      return FamilyLifeStatus.living;
    }
    return FamilyLifeStatus.unknown;
  }

  static DateTime? _date(Map<String, dynamic> row, List<String> keys) =>
      DateTime.tryParse(_text(row, keys) ?? '');

  static int? _integer(Map<String, dynamic> row, List<String> keys) =>
      int.tryParse(_text(row, keys) ?? '');

  static String? _text(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static bool _boolean(Map<String, dynamic> row, List<String> keys) {
    final value = _text(row, keys)?.toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  static String? _label(String? value) {
    if (value == null || value.isEmpty) return null;
    return value
        .toLowerCase()
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
