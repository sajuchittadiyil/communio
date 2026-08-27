class CongregationProfile {
  const CongregationProfile({
    required this.id,
    required this.name,
    this.abbreviation,
    this.motto,
    this.charism,
    this.founder,
    this.founderImageUrl,
    this.patronSaintName,
    this.patronSaintImageUrl,
    this.foundedYear,
    this.generalateCity,
    this.generalateAddress,
    this.country,
    this.email,
    this.phone,
    this.website,
  });

  final String id;
  final String name;
  final String? abbreviation;
  final String? motto;
  final String? charism;
  final String? founder;
  final String? founderImageUrl;
  final String? patronSaintName;
  final String? patronSaintImageUrl;
  final int? foundedYear;
  final String? generalateCity;
  final String? generalateAddress;
  final String? country;
  final String? email;
  final String? phone;
  final String? website;
}

class CongregationLeader {
  const CongregationLeader({
    required this.id,
    required this.displayName,
    required this.roleName,
    required this.displayOrder,
    this.title,
    this.postNominal,
    this.countryOfOrigin,
    this.administrationCity,
    this.email,
    this.phone,
    this.photoUrl,
  });

  final String id;
  final String displayName;
  final String roleName;
  final int displayOrder;
  final String? title;
  final String? postNominal;
  final String? countryOfOrigin;
  final String? administrationCity;
  final String? email;
  final String? phone;
  final String? photoUrl;
}

class ProvinceProfile {
  const ProvinceProfile({
    required this.id,
    required this.congregationName,
    required this.name,
    required this.activeMembers,
    required this.activeCommunities,
    required this.activeMinistries,
    this.activeFormationMembers,
    this.currentProvincialOffices,
    this.motto,
    this.headquarters,
    this.address,
    this.country,
    this.email,
    this.phone,
    this.website,
    this.establishedDate,
  });

  final String id;
  final String congregationName;
  final String name;
  final String? motto;
  final String? headquarters;
  final String? address;
  final String? country;
  final String? email;
  final String? phone;
  final String? website;
  final DateTime? establishedDate;
  final int activeMembers;
  final int activeCommunities;
  final int activeMinistries;
  final int? activeFormationMembers;
  final int? currentProvincialOffices;
}

class ProvinceLeader {
  const ProvinceLeader({
    required this.memberId,
    required this.displayName,
    required this.roleCode,
    required this.roleName,
    this.fromDate,
    this.photoUrl,
    this.phone,
    this.whatsApp,
    this.email,
  });

  final String memberId;
  final String displayName;
  final String roleCode;
  final String roleName;
  final DateTime? fromDate;
  final String? photoUrl;
  final String? phone;
  final String? whatsApp;
  final String? email;
}

class OrganizationIdentitySnapshot {
  const OrganizationIdentitySnapshot({
    required this.congregation,
    required this.leaders,
    required this.province,
    this.provincialLeaders = const [],
  });

  final CongregationProfile congregation;
  final List<CongregationLeader> leaders;
  final ProvinceProfile province;
  final List<ProvinceLeader> provincialLeaders;
}
