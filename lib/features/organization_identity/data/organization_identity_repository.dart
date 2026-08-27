import '../models/organization_identity_models.dart';

abstract interface class OrganizationIdentityRepository {
  Future<OrganizationIdentitySnapshot> fetchIdentity();
}

class OrganizationIdentityException implements Exception {
  const OrganizationIdentityException();
}
