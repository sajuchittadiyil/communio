import '../../demo_persona/models/demo_persona.dart';

enum AccessRole { provincial, communitySuperior, member }

class AppAccessContext {
  const AppAccessContext({
    required this.role,
    this.memberId,
    this.managedCommunityId,
    this.managedCommunityName,
    this.communityResponsibilityCode,
    this.persona = DemoPersona.standard,
  });

  const AppAccessContext.provincial({this.persona = DemoPersona.standard})
    : role = AccessRole.provincial,
      memberId = null,
      managedCommunityId = null,
      managedCommunityName = null,
      communityResponsibilityCode = null;

  final AccessRole role;
  final String? memberId;
  final String? managedCommunityId;
  final String? managedCommunityName;
  final String? communityResponsibilityCode;
  final DemoPersona persona;

  bool get isMember => role == AccessRole.member;
  bool get isCommunitySuperior => role == AccessRole.communitySuperior;
  bool get isMemberLike => isMember || isCommunitySuperior;
  bool get isProvincial => role == AccessRole.provincial;
}
