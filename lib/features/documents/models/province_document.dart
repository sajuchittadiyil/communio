enum DocumentCategory {
  provincialAdministration(
    'provincial_administration',
    'Provincial Administration',
  ),
  governance('governance_chapter', 'Governance & Chapter'),
  community('community', 'Community'),
  ministry('ministry', 'Ministry'),
  formation('formation', 'Formation'),
  finance('finance', 'Finance'),
  personnel('personnel', 'Personnel'),
  meetings('meetings', 'Meetings'),
  policies('policies', 'Policies'),
  propertyCompliance('property_compliance', 'Property & Compliance'),
  strategy('strategy', 'Strategy');

  const DocumentCategory(this.code, this.label);
  final String code;
  final String label;
}

class ProvinceDocument {
  const ProvinceDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.documentType,
    required this.documentDate,
    required this.description,
    required this.visibility,
    required this.createdAt,
    this.documentCode,
    this.relatedEntityType,
    this.relatedEntityId,
    this.relatedEntityName,
    this.fileName,
    this.assetPath,
    this.storagePath,
    this.fileExtension = 'pdf',
    this.fileSizeBytes,
    this.uploadedBy,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? documentCode;
  final DocumentCategory category;
  final String documentType;
  final DateTime documentDate;
  final String description;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final String? relatedEntityName;
  final String visibility;
  final String? fileName;
  final String? assetPath;
  final String? storagePath;
  final String fileExtension;
  final int? fileSizeBytes;
  final String? uploadedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get hasFile => assetPath != null || storagePath != null;
  DateTime get recentDate => documentDate;
}
