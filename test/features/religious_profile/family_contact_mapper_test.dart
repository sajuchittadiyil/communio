import 'package:communio/features/religious_profile/data/family_contact_mapper.dart';
import 'package:communio/features/religious_profile/models/religious_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merges home-contact details into family identity rows', () {
    final contacts = FamilyContactMapper.fromRows(const [
      {
        'name': 'Vimal Mishra',
        'relationship': 'Brother',
        'phone': '+91 80000 00037',
        'whatsapp': '+91 80000 00037',
        'email': null,
        'is_primary': true,
        'is_next_of_kin': true,
        'is_emergency_contact': true,
      },
      {
        'name': 'Mary Mishra',
        'relationship': 'Mother',
        'phone': '+91 81000 00037',
        'whatsapp': '+91 81000 00037',
        'is_emergency_contact': true,
      },
      {'name': 'Vimal Mishra', 'relationship': 'Brother'},
      {'name': 'Roshan Mishra', 'relationship': 'Father'},
      {'name': 'Mary Mishra', 'relationship': 'Mother'},
    ]);

    expect(contacts, hasLength(3));
    final vimal = contacts.firstWhere(
      (contact) => contact.name == 'Vimal Mishra',
    );
    expect(vimal.phone, '+91 80000 00037');
    expect(vimal.whatsApp, '+91 80000 00037');
    expect(vimal.email, isNull);
    expect(vimal.isPrimary, isTrue);
    expect(vimal.isNextOfKin, isTrue);
    expect(vimal.isEmergency, isTrue);

    final roshan = contacts.firstWhere(
      (contact) => contact.name == 'Roshan Mishra',
    );
    expect(roshan.phone, isNull);
    expect(roshan.whatsApp, isNull);
    expect(roshan.isNextOfKin, isFalse);
    expect(roshan.isEmergency, isFalse);
    expect(contacts.map((contact) => contact.relationship), [
      'Father',
      'Mother',
      'Brother',
    ]);
  });

  test('maps parent life status, dates, notes, and unknown values', () {
    final contacts = FamilyContactMapper.fromRows(const [
      {
        'name': 'Joseph Mathew',
        'relationship': 'father',
        'life_status': 'deceased',
        'date_of_death': '2018-03-12',
        'date_of_birth': '1940-04-02',
        'notes': 'Remembered with gratitude',
      },
      {
        'name': 'Mary Mathew',
        'relationship': 'mother',
        'life_status': 'living',
      },
      {
        'name': 'Thomas Mathew',
        'relationship': 'brother',
        'life_status': 'not_recorded',
      },
    ]);

    final father = contacts[0];
    expect(father.lifeStatus, FamilyLifeStatus.deceased);
    expect(father.displayName, 'Late Joseph Mathew');
    expect(father.dateOfDeath, DateTime(2018, 3, 12));
    expect(father.dateOfBirth, DateTime(1940, 4, 2));
    expect(father.notes, 'Remembered with gratitude');
    expect(contacts[1].lifeStatus, FamilyLifeStatus.living);
    expect(contacts[2].lifeStatus, FamilyLifeStatus.unknown);
  });

  test('preserves a year-only death value', () {
    final contact = FamilyContactMapper.fromRows(const [
      {
        'name': 'Anna Thomas',
        'relationship': 'mother',
        'life_status_code': 'deceased',
        'death_year': 2012,
      },
    ]).single;

    expect(contact.dateOfDeath, isNull);
    expect(contact.deathYear, 2012);
  });

  test('supports all requested parent life-status combinations', () {
    List<FamilyLifeStatus> statuses(
      String father,
      String mother,
    ) => FamilyContactMapper.fromRows([
      {'name': 'Father Name', 'relationship': 'father', 'life_status': father},
      {'name': 'Mother Name', 'relationship': 'mother', 'life_status': mother},
    ]).map((contact) => contact.lifeStatus).toList();

    expect(statuses('living', 'living'), [
      FamilyLifeStatus.living,
      FamilyLifeStatus.living,
    ]);
    expect(statuses('deceased', 'living'), [
      FamilyLifeStatus.deceased,
      FamilyLifeStatus.living,
    ]);
    expect(statuses('living', 'deceased'), [
      FamilyLifeStatus.living,
      FamilyLifeStatus.deceased,
    ]);
    expect(statuses('deceased', 'deceased'), [
      FamilyLifeStatus.deceased,
      FamilyLifeStatus.deceased,
    ]);
  });
}
