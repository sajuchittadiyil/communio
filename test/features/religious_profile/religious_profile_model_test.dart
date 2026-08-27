import 'package:communio/features/religious_profile/models/religious_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('current leave uses authoritative timing status', () {
    const leave = LeaveRecord(type: 'Home Leave', timingStatus: 'CURRENT');

    expect(leave.isCurrent, isTrue);
  });

  test('historical leave does not appear current', () {
    final leave = LeaveRecord(
      type: 'Study Leave',
      fromDate: DateTime(2017, 7, 1),
      toDate: DateTime(2019, 5, 31),
    );

    expect(leave.isCurrent, isFalse);
  });

  test('structured qualification and office context remain queryable', () {
    const qualification = QualificationRecord(
      qualification: 'M.Ed.',
      category: 'Postgraduate',
      level: 'Masters',
      institution: 'St. Xavier College',
      universityBoard: 'St. Xavier University',
      specialization: 'Educational Leadership',
      country: 'India',
      year: 2018,
    );
    const office = OfficeAppointment(
      office: 'Principal',
      context: 'St. Antony School',
      contextKind: OfficeContextKind.ministry,
    );

    expect(qualification.category, 'Postgraduate');
    expect(qualification.universityBoard, 'St. Xavier University');
    expect(office.contextKind, OfficeContextKind.ministry);
    expect(office.context, 'St. Antony School');
  });
}
