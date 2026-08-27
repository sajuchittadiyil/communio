import 'package:flutter/foundation.dart';

import '../data/member_directory_repository.dart';
import '../models/member_directory_entry.dart';

enum MemberDirectoryStatus { loading, ready, error }

class MemberDirectoryController extends ChangeNotifier {
  MemberDirectoryController(this._repository);

  final MemberDirectoryRepository _repository;
  MemberDirectoryStatus status = MemberDirectoryStatus.loading;
  MemberDirectoryFailureKind? failureKind;
  List<MemberDirectoryEntry> _members = const [];
  String search = '';
  MemberDirectoryFilters filters = const MemberDirectoryFilters();
  MemberDirectorySort sort = MemberDirectorySort.nameAscending;

  int get totalCount => _members.length;
  bool get isFiltered => search.trim().isNotEmpty || filters.activeCount > 0;

  Future<void> load() async {
    status = MemberDirectoryStatus.loading;
    failureKind = null;
    notifyListeners();
    try {
      _members = await _repository.fetchMembers();
      status = MemberDirectoryStatus.ready;
    } on MemberDirectoryException catch (error) {
      failureKind = error.kind;
      status = MemberDirectoryStatus.error;
    } catch (_) {
      failureKind = MemberDirectoryFailureKind.unexpected;
      status = MemberDirectoryStatus.error;
    }
    notifyListeners();
  }

  List<MemberDirectoryEntry> get visibleMembers {
    final needle = search.trim().toLowerCase();
    final result = _members.where((member) {
      bool matches(String? value, String? filter) =>
          filter == null ||
          filter.isEmpty ||
          value?.toLowerCase() == filter.toLowerCase();
      final haystack = [
        member.displayName,
        member.religiousId,
        member.community,
        member.communityRole,
        member.ministry,
        member.ministryRole,
        member.nativeState,
        member.memberStatus,
        member.canonicalStatus,
        member.directoryStatus,
      ].whereType<String>().join(' ').toLowerCase();
      return (needle.isEmpty || haystack.contains(needle)) &&
          matches(member.memberStatus, filters.memberStatus) &&
          matches(member.canonicalStatus, filters.canonicalStatus) &&
          matches(member.community, filters.community) &&
          matches(member.nativeState, filters.state) &&
          matches(member.ministryAssignment, filters.ministry);
    }).toList();
    int compare(MemberDirectoryEntry a, MemberDirectoryEntry b) {
      if (sort == MemberDirectorySort.nameAscending &&
          a.isDeceased != b.isDeceased) {
        return a.isDeceased ? 1 : -1;
      }
      final left = switch (sort) {
        MemberDirectorySort.nameAscending ||
        MemberDirectorySort.nameDescending => a.displayName,
        MemberDirectorySort.community => a.community ?? '',
        MemberDirectorySort.memberStatus => a.memberStatus,
      };
      final right = switch (sort) {
        MemberDirectorySort.nameAscending ||
        MemberDirectorySort.nameDescending => b.displayName,
        MemberDirectorySort.community => b.community ?? '',
        MemberDirectorySort.memberStatus => b.memberStatus,
      };
      final comparison = left.toLowerCase().compareTo(right.toLowerCase());
      return sort == MemberDirectorySort.nameDescending
          ? -comparison
          : comparison;
    }

    result.sort(compare);
    return result;
  }

  List<String> options(String Function(MemberDirectoryEntry) selector) =>
      _members
          .map(selector)
          .where((value) => value.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  void setSort(MemberDirectorySort value) {
    sort = value;
    notifyListeners();
  }

  void setFilters(MemberDirectoryFilters value) {
    filters = value;
    notifyListeners();
  }

  void clearFilters() {
    filters = const MemberDirectoryFilters();
    notifyListeners();
  }
}
